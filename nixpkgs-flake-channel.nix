{ nixpkgs, system ? builtins.currentSystem, useCA ? false }:
let
  pkgs = import nixpkgs { inherit system; config.contentAddressedByDefault = useCA; };
  drv = { lib, bash, coreutils }: derivation {
    inherit system;
    name = "nixpkgs-flake-channel";
    builder = "${bash}/bin/bash";
    args = [
      "-c"
      ''
        mkdir -p $out
        ln -s ${nixpkgs} $out/nixpkgs
      ''
    ];
    preferLocalBuild = true;
    PATH = "${lib.makeBinPath [ coreutils ]}";
  };
in
(pkgs.callPackage) drv { }
