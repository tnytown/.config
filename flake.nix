{
  description = "{system, home} configuration flake";

  inputs = {
    # Track an arbitrary unstable revision that I like.
    unstable.url = "nixpkgs/nixpkgs-unstable";
    nixpkgs.follows = "unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    emacs.url = "github:nix-community/emacs-overlay";
    sops-nix.url = "github:knownunown/sops-nix/age-support";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    rocm.url = "github:nixos-rocm/nixos-rocm";
    rocm.flake = false;

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    cachix.url = "github:jonascarpay/declarative-cachix";
    cachix.flake = false;

    speedy.url = "/home/tny/dev/speedy/";
    speedy.inputs.nixpkgs.follows = "nixpkgs";
    fishcgi.url = "/home/tny/dev/fish-cgi/";
    binja.url = "/home/tny/re/";
    binja.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Cargo culted.
  # https://github.com/nix-community/home-manager/issues/1538#issuecomment-706627100
  outputs = inputs@{ self, nixpkgs, unstable, darwin, sops-nix, rocm
    , home-manager, deploy-rs, cachix, speedy, ... }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      flakePins = {
        system.nix-flake-config.systemFlake = self;
        system.nix-flake-config.nixpkgsFlake = nixpkgs;
      };
    in rec {

      devShell.${system} = let pkgs = nixpkgs.legacyPackages.${system};
      in pkgs.mkShell {
        sopsAgeKeyDirs = [ ./keys ];
        buildInputs = with pkgs; [
          deploy-rs.defaultPackage.${system}
          (pkgs.writeShellScriptBin "nrb"
            "sudo nixos-rebuild -L switch --flake .")
          (pkgs.writeShellScriptBin "hrb"
            "nix build --show-trace -L .#homeConfigurations.navi.activationPackage && result/activate")
          nixfmt

          (pkgs.callPackage sops-nix { }).sops-age-hook
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

      legacyPackages = let
        lpkgs = (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        });
      in { ${system} = (lpkgs // overlays.personal lpkgs lpkgs); };

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

          config = let
            mkModule = path:
              (args@{ config, lib, pkgs, ... }:
                import path ({
                  # is there a better way to do this?
                  pkgs = import inputs.unstable { inherit system; };
                } // removeAttrs args [ "pkgs" ]));
          in nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              ./modules/nix-flake-config.nix
              flakePins
              {
                # boom
                system.nix-flake-config.useCA = true;
              }

              (import cachix)
              {
                cachix = [
                  {
                    name = "nixos-rocm";
                    sha256 =
                      "1l2g8l55b6jzb84m2dcpf532rm7p2g4dl56j3pbrfm03j54sg0v0";
                  }
                  {
                    name = "nix-community";
                    sha256 =
                      "1r0dsyhypwqgw3i5c2rd5njay8gqw9hijiahbc2jvf0h52viyd9i";
                  }
                ];
              }
              # cachix
              {
                nixpkgs.overlays = self.overlaysList
                  ++ [ (import rocm) inputs.emacs.overlay ];
              }

              ./configuration.nix
              ./machines/navi.nix
              ./modules/security.nix
              ./modules/initrd-ssh-luks.nix
              ./modules/corefreq.nix
              ./modules/desktop.nix
              ./modules/jenkins-agent.nix
              ./modules/minecraft-server.nix
              sops-nix.nixosModules.sops
              {
                systemd.services.hawck-inputd.enable = false;
                # environment.systemPackages = [ inputs.binja.defaultPackage.${system} ];
              }
              inputs.fishcgi.nixosModule
              ({ config, ... }: {
                services.nginx.enable = true;
                services.fishcgi.enable = true;
                services.nginx.virtualHosts."localhost" = {
                  default = true;
                  root = "/var/lib/fishcgi/";
                  locations."/".index = "index.fish";
                  locations."~ .fish$" = {
                    extraConfig = ''
                      # try_files $uri =404;
                      fastcgi_pass unix:${config.services.fishcgi.socket};
                      fastcgi_index ${config.services.fishcgi.example};
                      include ${config.services.nginx.package}/conf/fastcgi_params;
                      include ${config.services.nginx.package}/conf/fastcgi.conf;
                    '';
                  };
                };
                networking.firewall.allowedTCPPorts = [ 80 ];
              })
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

          config = let
            mkModule = path:
              (args@{ config, lib, pkgs, ... }:
                import path ({
                  # is there a better way to do this?
                  pkgs = import inputs.unstable { inherit system; };
                } // removeAttrs args [ "pkgs" ]));
          in nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              ./modules/nix-flake-config.nix
              flakePins

              { nixpkgs.overlays = self.overlaysList; }
              {
                fileSystems."/" = {
                  device = "/dev/disk/by-label/root";
                  fsType = "btrfs";
                };
                boot.loader.grub.device = "/dev/vda";
              }
              speedy.nixosModule

              ./psyche-configuration.nix
            ];
          };
        };

        venus = rec {
          system = "x86_64-darwin";

          config = darwin.lib.darwinSystem {
            modules = [
              ./modules/nix-flake-config.nix
              flakePins
              ./darwin-configuration.nix
            ];
          };

          home = homeConfiguration {
            inherit system config;

            homeDirectory = "/Users/apan/";
          };
        };
      };

      # cachix = (import inputs.cachix);
      darwinConfigurations = (builtins.mapAttrs (k: v: v.config)
        (lib.filterAttrs (k: v: lib.hasSuffix "darwin" v.system) machines));
      nixosConfigurations = (builtins.mapAttrs (k: v: v.config)
        (lib.filterAttrs (k: v: lib.hasSuffix "linux" v.system && !(v ? ignore))
          machines));
      homeConfigurations = builtins.mapAttrs (k: v: v.home) machines;

      deploy.nodes.psyche = {
        sshUser = "root";
        hostname = "psyche.tny.town";
        profiles.system = {
          user = "root";
          path = builtins.trace (deploy-rs.lib.x86_64-linux.activate.nixos
            self.machines.psyche.config).outPath
            (deploy-rs.lib.x86_64-linux.activate.nixos
              self.machines.psyche.config);
        };
      };

      # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
