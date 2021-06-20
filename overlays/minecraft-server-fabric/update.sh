#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq unzip zip curl

set -euf -o pipefail

function curl() {
    env curl -sf $@
}

# https://meta.fabricmc.net/v2/versions/loader/1.17/0.11.6/server/json
# https://meta.fabricmc.net/v2/versions/loader/$gamever/$loaderver/server/json

gamever=$(curl "https://meta.fabricmc.net/v2/versions/game" | jq -r 'first(.[] | select(.stable)).version')
loaderver=$(curl "https://meta.fabricmc.net/v2/versions/loader" | jq -r 'first(.[] | select(.stable)).version')

echo "game version $gamever, loader version $loaderver" >&2


libs_url="https://meta.fabricmc.net/v2/versions/loader/$gamever/$loaderver/server/json"

TEMPDIR=(mktemp -d)
mkdir -p "$TEMPDIR/libs"
libs_json=$(curl $libs_url)
# ($parts[0] | gsub("\\."; "/"))
main_class=$(echo $libs_json | jq '.mainClass')
# echo $libs_json | jq
echo $libs_json | jq -r '
.libraries[] |
(.name | match("([^:]+):([^:]+):([^:]+)")) as $matches |
$matches.captures as $parts |
($parts[0].string | gsub("\\."; "/")) as $fqdn |
"\($parts[1].string)-\($parts[2].string).jar" as $name |
["\(.url)\($fqdn)/\($parts[1].string)/\($parts[2].string)/", $name] | @csv | gsub("\""; "")' |
    while read -r data; do
        parts=(${data//,/ })
        url="${parts[0]}${parts[1]}"
        hashurl="$url.sha1"
        cat <<EOF
{
"url": "$url",
"hash": "$(curl $hashurl)"
}
EOF
    done |
    jq -nc "{\"libs\": [inputs], \"mainClass\": $main_class}" |
    nix-instantiate --eval -E 'with (import <nixpkgs> {}); (lib.importJSON "/dev/stdin")' >libs.nix

rm -rf $TEMPDIR
