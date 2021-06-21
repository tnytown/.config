{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.system.nix-flake-config;

  nixPkg = pkgs.nixUnstable;
  channel-shim = { nixpkgs }: with pkgs; let
    nixpkgs-flake-channel = import ../nixpkgs-flake-channel.nix { inherit nixpkgs; system = pkgs.stdenv.system; };
    in
    stdenv.mkDerivation rec {
    name = "nixpkgs-flake-channel-shim";
    # src = [ nixpkgs ];

    buildInputs = [ bash coreutils ];

    # XX: nix-env and the import above _should_ resolve to the same derivation ...
    buildPhase = ''
      mkdir -p $out
      ln -s ${../nixpkgs-flake-channel.nix} $out/default.nix
    '';

    passthru.flake-channel = nixpkgs-flake-channel;

    phases = "buildPhase";
  };
in {
  options.system.nix-flake-config = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
    nixpkgsFlake = mkOption {
      type = types.path;
    };
    systemFlake = mkOption {
      type = types.path;
    };
    useCA = mkOption {
      type = types.bool;
      default = false;
    };
  };

  # Pin flake versions for use with nix shell.
  config = mkIf cfg.enable {
    nix = {
      registry = {
        nixpkgs.flake = cfg.nixpkgsFlake;
        s.flake = cfg.systemFlake;
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      package = pkgs.nixUnstable;
      extraOptions = if cfg.useCA then ''
        experimental-features = nix-command flakes ca-references ca-derivations
        substituters = https://cache.nixos.org/ https://cache.ngi0.nixos.org/
        trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA=
      '' else ''
        experimental-features = nix-command flakes
      '';
      autoOptimiseStore = true;
    };

    # strap in for the smoke and mirrors
    system.activationScripts.channel-shim = let
      shim = channel-shim { nixpkgs = cfg.nixpkgsFlake; };
    in ''
      if ! grep -q "${shim.flake-channel}" /nix/var/nix/profiles/per-user/root/channels/manifest.nix; then
         echo "installing root channel from flake revision..."
         ${nixPkg}/bin/nix-env --profile /nix/var/nix/profiles/per-user/root/channels --file ${shim} \
                               --install ${shim.flake-channel}

         ${nixPkg}/bin/nix-env --profile /nix/var/nix/profiles/per-user/root/channels --delete-generations old
      fi
    '';

  };
}
