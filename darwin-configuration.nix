{ config, pkgs, ... }:

let
  inherit (pkgs) lorri;
  #appenv = import "/Users/apan/dev/appenv/" { };
in {

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball
      "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
      };
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.fish
    #      appenv
    lorri
    pkgs.neovim
    pkgs.curl
    pkgs.sshfs
    #    pkgs.nur.repos.mic92.frida-tools
  ];
  #  system.activationScripts.postUserActivation.text = ''
  #  launchctl setenv DYLD_INSERT_LIBRARIES ${appenv}/lib/libappenv.dylib
  #  '';

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  environment.etc."ssh/ssh_config".text = ''
    Host navi-ext
         User tny
         HostName navi.lan
         ProxyJump shiny.unown.me
    Host shiny.unown.me
         User root
  '';

  environment.etc."ssh/sshd_config".text = ''
    PasswordAuthentication no
    ChallengeResponseAuthentication no
    UsePAM yes
  '';
  # Create /etc/bashrc that loads the nix-darwin environment.
  # programs.bash.enable = true;
  programs.zsh.enable = true;
  programs.fish.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.maxJobs = 10;
  nix.buildCores = 10;

  # allow nix-darwin to manage build users
  users.nix.configureBuildUsers = true;
}
