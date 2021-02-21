{
  description = "{system, home} configuration flake";

  inputs = {
    # Track an arbitrary unstable revision that I like.
    unstable.url = "nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "nixpkgs/release-20.09";
    darwin.url = "github:lnl7/nix-darwin/master";

    home-manager.url = "github:nix-community/home-manager/release-20.09";
  };

  # Cargo culted.
  # https://github.com/nix-community/home-manager/issues/1538#issuecomment-706627100
  outputs = inputs@{ self, nixpkgs, unstable, darwin, home-manager }:
    rec {
    overlays = [
      (final: prev: {
        # overlay unstable into our stable nixpkgs set.
        unstable = import inputs.unstable {
          system = final.system;

          config.allowUnfree = true;
        };
      })

      ./overlays/overlays.nix
    ];

    homeConfiguration = { system, config, homeDirectory, username ? "tny" }:
      home-manager.lib.homeManagerConfiguration {
        inherit system homeDirectory username;
        configuration = {
          nixpkgs.overlays = self.overlays;
          imports = [ ./home.nix ];
        };
      };

    machines = {
      navi = rec {
        system = "x86_64-linux";

        config =
          let mkModule = path: (args@{ config, lib, pkgs, ... }:
                import path ({
                  # is there a better way to do this?
                  pkgs = import inputs.unstable {
                    inherit system;
                  };
                } // removeAttrs args ["pkgs"]));
          in nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              {
                # Pin flake versions for use with nix shell.
                nix.registry = {
                  nixpkgs.flake = nixpkgs;
                  unstable.flake = unstable;
                  s.flake = nixpkgs;
                  u.flake = unstable;
                };
              }

              # use unstable PipeWire module.
              (mkModule "${unstable}/nixos/modules/services/desktops/pipewire/pipewire.nix")
              (mkModule "${unstable}/nixos/modules/services/desktops/pipewire/pipewire-media-session.nix")

              # navi uses unstable for nvidia stuff.
              ./configuration.nix { nixpkgs.overlays = self.overlays; }
            ];
        };

        home = homeConfiguration {
          inherit system config;

          homeDirectory = "/home/tny/";
        };
      };
    };

    darwinConfigurations."venus" = darwin.lib.darwinSystem {
      modules = [
        ./darwin-configuration.nix
      ];
    };
    nixosConfigurations = builtins.mapAttrs (k: v: v.config) machines;
    homeConfigurations = builtins.mapAttrs (k: v: v.home) machines;
  };
}
