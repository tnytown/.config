{
  description = "{system, home} configuration flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    # Track an arbitrary unstable revision that I like.
    unstable.url = "nixpkgs/nixpkgs-unstable";
    nixpkgs.follows = "unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-overlay.url = "github:knownunown/nixpkgs-overlay-tny";
    nixpkgs-overlay.inputs.nixpkgs.follows = "nixpkgs";

    emacs.url = "github:nix-community/emacs-overlay";
    sops-nix.url = "github:tnytown/sops-nix/age-support";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    rocm.url = "github:nixos-rocm/nixos-rocm";
    rocm.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    cachix.url = "github:jonascarpay/declarative-cachix";
    cachix.flake = false;

    speedy.url = "/Users/tnytown/Documents/sw/flake-template";
    speedy.inputs.nixpkgs.follows = "nixpkgs";
    fishcgi.url = "/Users/tnytown/Documents/sw/flake-template";
    binja.url = "/Users/tnytown/Documents/sw/flake-template";
    binja.inputs.nixpkgs.follows = "nixpkgs";

    mhctf.url = "/Users/tnytown/Documents/sw/flake-template";
    mhctf.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs-format.url = "github:nix-community/nixpkgs-fmt";
    nixpkgs-format.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Cargo culted.
  # https://github.com/nix-community/home-manager/issues/1538#issuecomment-706627100
  outputs =
    inputs@{ self
    , flake-utils
    , nixpkgs
    , unstable
    , darwin
    , nixpkgs-overlay
    , sops-nix
    , rocm
    , home-manager
    , deploy-rs
    , nixpkgs-format
    , cachix
    , speedy
    , ...
    }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      flakePins = {
        system.nix-flake-config.systemFlake = self;
        system.nix-flake-config.nixpkgsFlake = nixpkgs;
      };
      overlays = {
        intree = (import ./overlays/overlays.nix);
        tny = nixpkgs-overlay.overlay;
      };
      overlaysList = lib.mapAttrsToList (s: t: t) overlays;
    in
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" ]
      (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        devShell = pkgs.mkShell {
          sopsAgeKeyDirs = [ ./keys ];
          buildInputs = with pkgs; [
            deploy-rs.defaultPackage.${system}
            (pkgs.writeShellScriptBin "nrb"
              "sudo nixos-rebuild $@ -L switch --flake .")

            (pkgs.writeShellScriptBin "hrb"
              "nix build $@ -L .#homeConfigurations.navi.activationPackage && result/activate")

            pre-commit
            nixpkgs-format.defaultPackage.${system}

            (pkgs.callPackage sops-nix { }).sops-age-hook
          ];
        };

        legacyPackages =
          let
            lpkgs = (import nixpkgs {
              inherit system;
              config.allowUnfree = true;
            });
          in
          builtins.foldl' (l: r: r legacyPackages l) lpkgs overlaysList;
          # (lpkgs // overlays.intree lpkgs lpkgs);
      }) // rec {
      inherit overlays;
      overlaysList = lib.mapAttrsToList (s: t: t) overlays;

      # this is factored out to account for the disparate home directory locations that I deal with,
      # namely macOS's /Users vs traditionally Linux's /home.
      homeConfiguration = { system, config, homeDirectory, username ? "tny", extraImports ? [ ] }:
        home-manager.lib.homeManagerConfiguration { 
	  pkgs = nixpkgs.legacyPackages.${system};
 	  modules = [
            ./home.nix
            {
              nixpkgs.config.allowUnfreePredicate = (pkg: true);
              nixpkgs.overlays = overlaysList;
              home = {
                inherit username homeDirectory;
              };
            }
          ] ++ extraImports;
          /*configuration = {
            nixpkgs.overlays = overlaysList;
            imports = [ ./home.nix ] ++ extraImports;
          };*/
        };

      machines = {
        navi = rec {
          system = "x86_64-linux";

          config = nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              ./modules/nix-flake-config.nix
              flakePins

              # cachix
              (import cachix)
              {
                cachix = [ 
                  {
                    name = "nix-community";
                    sha256 =
                      "sha256:1rgbl9hzmpi5x2xx9777sf6jamz5b9qg72hkdn1vnhyqcy008xwg";
                  }
                ];
              }
              {
                nixpkgs.overlays = [ inputs.emacs.overlay ] ++ self.overlaysList;
              }

              ./configuration.nix
              ./machines/navi.nix
              (inputs.lanzaboote.nixosModules.lanzaboote)
	      ({ config, lib, ... }: {
                         boot.loader.systemd-boot.enable = lib.mkForce false;

        boot.lanzaboote = {
          enable = true;
          pkiBundle = "/etc/secureboot";
        }; 
              })
              ./modules/security.nix
              ./modules/initrd-ssh-luks.nix
              ./modules/corefreq.nix
              ./modules/desktop.nix
              # ./modules/jenkins-agent.nix
              # ./modules/minecraft-server.nix
              sops-nix.nixosModules.sops

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
            extraImports = [ ./modules/hm/desktop.nix ];
          };
        };

        psyche = rec {
          #ignore = true;
          system = "x86_64-linux";

          config = nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              ./modules/nix-flake-config.nix
              flakePins

              { nixpkgs.overlays = overlaysList; }
              {
                fileSystems."/" = {
                  device = "/dev/disk/by-label/root";
                  fsType = "btrfs";
                };
                boot.loader.grub.device = "/dev/vda";
              }

              ./modules/security.nix
              ./modules/vsftpd.nix
              sops-nix.nixosModules.sops
              speedy.nixosModule
              inputs.mhctf.nixosModule

              ./psyche-configuration.nix
            ];
          };
        };

       leliel = rec {
            system = "aarch64-darwin";

            config = darwin.lib.darwinSystem {
              inherit system;
              modules = [
                ./modules/nix-flake-config.nix
                flakePins
                ./darwin-configuration.nix
              ];
            };

            home = homeConfiguration {
              inherit system config;

              homeDirectory = "/Users/tnytown/";
            };

          };
       zadkiel = rec {
            system = "aarch64-darwin";

            config = darwin.lib.darwinSystem {
              inherit system;
              modules = [
                ./modules/nix-flake-config.nix
                flakePins
                ./darwin-configuration.nix
              ];
            };

            home = homeConfiguration {
              inherit system config;

              homeDirectory = "/Users/tnytown/";
            };

          }; 
        };
        
        #};

      #};

      # cachix = (import inputs.cachix);
      darwinConfigurations = (builtins.mapAttrs (k: v: v.config)
        (lib.filterAttrs (k: v: lib.hasSuffix "darwin" v.system) machines));
      nixosConfigurations = (builtins.mapAttrs (k: v: v.config)
        (lib.filterAttrs
          (k: v: lib.hasSuffix "linux" v.system && !(v ? ignore))
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
