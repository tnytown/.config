{ stdenv, fetchurl, adoptopenjdk-hotspot-bin-16,
  minecraft-server, unzip, zip }:
let meta = (import ./libs.nix);
    mojang-server = minecraft-server.override { jre_headless = adoptopenjdk-hotspot-bin-16; };
    mojang-jar = "${mojang-server}/lib/minecraft/server.jar";
in
stdenv.mkDerivation rec {
  pname = "minecraft-server-fabric";
  version = "0.7.4";
  src = fetchurl {
    url = "https://maven.fabricmc.net/net/fabricmc/fabric-installer/${version}/fabric-installer-${version}.jar";
    hash = "sha256-GS1g+1RKRe3KWJpPc9nT35On97aKQHwEA+nhgC+vdmg=";
  };

  buildInputs = [
    mojang-server

    # jar mangler deps
    unzip
    zip
  ];

  fabricLibs = map (x: fetchurl {
    inherit (x) url;
    sha1 = x.hash;
  }) meta.libs;
  fabricMainClass = meta.mainClass;

  buildPhase = ''
  bash ${./build.sh}
LIB="$out/lib/minecraft"
mkdir -p $out/bin $LIB

# TODO: why do we also have to mess with fabric-server-launcher.properties?
ln -s ${mojang-jar} $LIB/server.jar

mv work/fabric-server-launch.jar $LIB

cat > $out/bin/minecraft-server << 'EOF'
#!/bin/sh

# hack: "make sure" we're running as the minecraft user (in home, which is /var/lib/minecraft), then drop the path to the Mojang jar in the chat.
[[ "$PWD" = "$HOME" ]] && (echo "serverJar=${mojang-jar}" >fabric-server-launcher.properties)

exec ${adoptopenjdk-hotspot-bin-16}/bin/java $@ -jar ${placeholder "out"}/lib/minecraft/fabric-server-launch.jar
EOF
chmod +x $out/bin/minecraft-server
'';

  phases = "buildPhase";

  passthru.mojang-jar = mojang-jar;
}
