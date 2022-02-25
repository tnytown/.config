{ nixpkgs, system ? builtins.currentSystem, useCA ? false }:
let
  pkgs = import nixpkgs { inherit system; config.contentAddressedByDefault = useCA; };
  drv = { lib, bash, coreutils }: pkgs.stdenvNoCC.mkDerivation {
    inherit system;
    name = "nixpkgs-flake-channel";
    builder = "${bash}/bin/bash";
    args = [ "-c" ''
mkdir -p $out
ln -s ${pkgs.hiPrio nixpkgs} $out/nixpkgs
'' ];
    preferLocalBuild = true;
    PATH = "${lib.makeBinPath [ coreutils ]}";

    # priority = 4;
    meta = {
      priority = "-10";
    };
  };
in (pkgs.callPackage) drv {}
