#!/usr/bin/env bash

# https://github.com/FabricMC/fabric-installer/blob/8d3d533b049ca6139539f1bbf4bba4c062db55d0/src/main/java/net/fabricmc/installer/server/ServerInstaller.java

mkdir work
pushd work
for x in $fabricLibs; do
    svcs=$(unzip -Z1 $x | egrep '^META-INF/services/.+')
    for y in $svcs; do
        [[ $(realpath -m "$y") = $PWD/* ]] || exit 2 # paranoia
        mkdir -p $(dirname "$y")
        echo -e "$(unzip -qqc "$x" "$y")\n" >>"$y"
    done
    unzip -nq "$x"
done

echo "launch.mainClass=$fabricMainClass" >fabric-server-launch.properties

cat <<EOF >META-INF/MANIFEST.MF
Manifest-Version: 1.0
Main-Class: net.fabricmc.loader.launch.server.FabricServerLauncher
EOF

zip -qr fabric-server-launch.jar .

popd
