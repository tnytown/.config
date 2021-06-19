{ nixpkgs }:
let
  pkgs = (import nixpkgs {});
  system = builtins.currentSystem;
  drv = { lib, bash, coreutils }: derivation {
    inherit system;
    name = "nixpkgs-flake-channel";
    builder = "${bash}/bin/bash";
    args = [ "-c" ''
mkdir -p $out
ln -s ${nixpkgs} $out/nixpkgs
'' ];
    preferLocalBuild = true;
    PATH = "${lib.makeBinPath [ coreutils ]}";
  };
in (pkgs.callPackage) drv {}
