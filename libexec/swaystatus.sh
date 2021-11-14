#!/usr/bin/env bash

set -euo pipefail

function n() {
    ip -j -s link | jq -r 'reduce (.. | .bytes? | select(. != null)) as $i (0; . + $i)'
}

np=`n`
while true; do
    sleep 0.25;
    np_o="$np"
    np=`n`
    echo \
        'load:' $(uptime | sed -E 's/.*load average: ([^ ]+),.*/\1/')'x' '|' \
        'cpu:' $(sensors -j 'k10temp-pci-*' | jq '.. | .Tdie?.temp2_input | select(. != null) | floor')'C' '|' \
        'mem:' $(free -mh | awk 'NR == 2 {print $3}') '|' \
        'net:' "$(echo $(( $np - $np_o )) | numfmt --to=iec-i --padding=5)" '|' \
        $(date +'%Y-%m-%d %H:%M:%S');
done
