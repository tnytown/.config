{
  description = "{system, home} configuration flake";

  inputs = {
    # Track an arbitrary unstable revision that I like.
    unstable.url = "nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "nixpkgs/4e0d3868c679da20108db402785f924daa1a7fb5";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    rocm.url = "github:nixos-rocm/nixos-rocm";
    rocm.flake = false;

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Cargo culted.
  # https://github.com/nix-community/home-manager/issues/1538#issuecomment-706627100
  outputs = inputs@{ self, nixpkgs, unstable, darwin, rocm, home-manager, deploy-rs }:
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
      devShell."x86_64-linux" = let pkgs =
        nixpkgs.legacyPackages."x86_64-linux"; in pkgs.mkShell {
          buildInputs = with pkgs; [
            deploy-rs.defaultPackage."x86_64-linux"
          ];
        };
      overlays = {
        unstable = (final: prev: rec {
          # overlay unstable into our stable nixpkgs set.
          unstable = import inputs.unstable {
            system = final.system;

            config.allowUnfree = true;
          };
        });
        personal = (import ./overlays/overlays.nix);
      };

      overlaysList = lib.mapAttrsToList (s: t: t) self.overlays;

      # this is factored out to account for the disparate home directory locations that I deal with,
      # namely macOS's /Users vs traditionally Linux's /home.
      homeConfiguration = { system, config, homeDirectory, username ? "tny" }:
        home-manager.lib.homeManagerConfiguration {
          inherit system homeDirectory username;
          configuration = {
            nixpkgs.overlays = overlaysList;
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

                { nixpkgs.overlays = self.overlaysList ++ [(import rocm)]; }

                ./configuration.nix
              ];
            };

          home = homeConfiguration {
            inherit system config;

            homeDirectory = "/home/tny/";
          };
        };

        psyche = rec {
          #ignore = true;
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
                {
                  nixpkgs.overlays = self.overlaysList;
                }
                {
                  fileSystems."/" = {
                    device = "/dev/disk/by-label/root";
                    fsType = "btrfs";
                  };
                  boot.loader.grub.device = "/dev/vda";
                }

                ./psyche-configuration.nix
              ];
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
        (lib.filterAttrs (k: v: lib.hasSuffix "linux" v.system && !(v ? ignore)) machines));
      homeConfigurations = builtins.mapAttrs (k: v: v.home) machines;

      deploy.nodes.psyche = {
        sshUser = "root";
        hostname = "psyche.tny.town";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.machines.psyche.config;
        };
      };

      # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
