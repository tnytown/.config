{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.system.nix-flake-config;

  nixPkg = pkgs.nixUnstable;

  # Our "channel" requires an instance of Nixpkgs to be passed in.
  channel-shim = { nixpkgs }:
    with pkgs;
    let
      nixpkgs-flake-channel = import ../nixpkgs-flake-channel.nix {
        inherit nixpkgs;
        system = pkgs.stdenv.system;
      };
    in /*stdenv.mkDerivation rec {
      name = "nixpkgs-flake-channel-shim";
      # src = [ nixpkgs ];

      buildInputs = [ bash coreutils ];

      # XX: nix-env and the import above _should_ resolve to the same derivation ...
      buildPhase = ''
        ls ${nixpkgs-flake-channel}
        mkdir -p $out
        ln -s ${nixpkgs-flake-channel} $out/default.nix
        cat $out/default.nix
      '';

      passthru.flake-channel = nixpkgs-flake-channel;

      phases = "buildPhase";
    };*/ nixpkgs-flake-channel;
  shim = channel-shim { nixpkgs = cfg.nixpkgsFlake; };
  shim-script = ''
    PROFILE='/nix/var/nix/profiles/per-user/root/channels'
    MANIFEST="$PROFILE/manifest.nix"
    # if ! grep -q "${shim}" /nix/var/nix/profiles/per-user/root/channels/manifest.nix; then 
       ${nixPkg}/bin/nix-env --profile $PROFILE --install ${shim}

       ${nixPkg}/bin/nix-env --profile $PROFILE --delete-generations old
    # fi
  '';
in {
  options.system.nix-flake-config = {
    enable = mkOption {
      type = types.bool;
      default = true;
    };
    nixpkgsFlake = mkOption { type = types.path; };
    systemFlake = mkOption { type = types.path; };
    useCA = mkOption {
      type = types.bool;
      default = false;
    };
  };

  # Pin flake versions for use with nix shell.
  config = mkIf cfg.enable {
    nix = mkMerge [
      {
        registry = {
          nixpkgs.flake = cfg.nixpkgsFlake;
          s.flake = cfg.systemFlake;
        };

        gc = {
          automatic = true;
          options = "--delete-older-than 14d";
        };

        package = pkgs.nixUnstable;
	extraOptions = if cfg.useCA then ''
          builders-use-substitutes = true
          experimental-features = nix-command flakes ca-references ca-derivations
          substituters = https://cache.nixos.org/ https://cache.ngi0.nixos.org/
	  trusted-public-keys = cache.ngi0.nixos.org-1:KqH5CBLNSyX184S9BKZJo1LxrxJ9ltnY2uAs5c/f1MA= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= 
        '' else ''
          builders-use-substitutes = true
          experimental-features = nix-command flakes
        '';
      }
      (optionalAttrs pkgs.stdenv.isLinux {
        settings.auto-optimise-store = true;
        gc.dates = "weekly";
      })
    ];

    # strap in for the smoke and mirrors
    system.activationScripts.channel-shim = shim-script;
    # system.activationScripts.preActivation.text = shim-script;
  };
}
