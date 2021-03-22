{
  description = "{system, home} configuration flake";

  inputs = {
    # Track an arbitrary unstable revision that I like.
    unstable.url = "nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "nixpkgs/4e0d3868c679da20108db402785f924daa1a7fb5";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-20.09";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Cargo culted.
  # https://github.com/nix-community/home-manager/issues/1538#issuecomment-706627100
  outputs = inputs@{ self, nixpkgs, unstable, darwin, home-manager }:
    let lib = (import inputs.nixpkgs { system = "x86_64-linux"; }).lib;
        nixConf = {
          # Pin flake versions for use with nix shell.
          nix.registry = {
            nixpkgs.flake = nixpkgs;
            unstable.flake = unstable;
            s.flake = nixpkgs;
            u.flake = unstable;
          };
          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 14d";
          };
        };
    in rec {
    overlays = [
      (final: prev: rec {
        # overlay unstable into our stable nixpkgs set.
        unstable = import inputs.unstable {
          system = final.system;

          config.allowUnfree = true;
        };
      })

      (import ./overlays/overlays.nix)
    ];

    # this is factored out to account for the disparate home directory locations that I deal with, namely macOS's /Users vs traditionally Linux's /home.
    homeConfiguration = { system, config, homeDirectory, username ? "tny" }:
      home-manager.lib.homeManagerConfiguration {
        inherit system homeDirectory username;
        configuration = {
          nixpkgs.overlays = overlays;
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
              nixConf

              { nixpkgs.overlays = self.overlays; }

              ./configuration.nix
            ];
        };

        home = homeConfiguration {
          inherit system config;

          homeDirectory = "/home/tny/";
        };
      };
      venus = rec {
        system = "x86_64-darwin";

        config = darwin.lib.darwinSystem {
          modules = [
            nixConf
            ./darwin-configuration.nix
          ];
        };

        home = homeConfiguration {
          inherit system config;

          homeDirectory = "/Users/apan/";
        };
      };
    };

    
    darwinConfigurations = (builtins.mapAttrs (k: v: v.config)
      (lib.filterAttrs (k: v: lib.hasSuffix "darwin" v.system) machines));
    nixosConfigurations = (builtins.mapAttrs (k: v: v.config)
      (lib.filterAttrs (k: v: lib.hasSuffix "linux" v.system) machines));
    homeConfigurations = builtins.mapAttrs (k: v: v.home) machines;
  };
}
