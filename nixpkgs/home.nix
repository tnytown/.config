{ config, pkgs, ... }:

let upkgs = pkgs.unstable;
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.03";

  nixpkgs.config.allowUnfree = true;
  home.packages = [
    pkgs.zsh pkgs.neofetch pkgs.htop pkgs.tectonic

    pkgs.direnv

    upkgs.just
    pkgs.git-credential-keepassxc
    pkgs.rust-analyzer

    pkgs.file
    pkgs.binutils
    pkgs.jq
    pkgs.ripgrep
    # pkgs.openrgb
    pkgs.zip pkgs.unzip
    upkgs.osu-lazer

    pkgs.ffmpeg pkgs.exiftool
    upkgs.python3Packages.binwalk
  ] ++ (if pkgs.stdenv.isLinux then [
    pkgs.rnnoise-plugin
    
    pkgs.multimc
    upkgs.steam

    pkgs.gnome3.gnome-shell-extensions
    pkgs.nordic
    upkgs.openrgb
    pkgs.pavucontrol
    pkgs.keepassxc
    pkgs.emacs
    upkgs.spotify
    pkgs.slack
    pkgs.discord
    pkgs.ppsspp
    pkgs.zoom-us
    pkgs.chromium
    pkgs.mpv
    pkgs.lutris
    pkgs.slic3r-prusa3d
    pkgs.openscad
    pkgs.obs-studio
    pkgs.shotcut
    pkgs.qjackctl
    pkgs.jalv
    pkgs.lilv
    pkgs.xsel
    pkgs.cntr

    pkgs.flashrom
    pkgs.libbde
    pkgs.dnsutils
  ] else []);

  systemd.user.services = pkgs.lib.mkIf pkgs.hostPlatform.isLinux {
    # rnnoise-plugin
    rnnoise = {
      Unit = {
        Description = "RNNoise LV2 plugin for JACK";
      };

      Service = {
        Type = "simple";
        ExecStart = (pkgs.writeScript "start.sh" ''
#!${pkgs.bash}/bin/bash

set -euf -o pipefail

export LV2_PATH=${pkgs.rnnoise-plugin}/lib/lv2/
pw='${pkgs.unstable.pipewire}/bin'
pwjack=$pw'/pw-jack'
pwcli=$pw'/pw-cli'
pwdump=$pw'/pw-dump'
jalv='${pkgs.jalv}/bin/jalv'
pactl='${pkgs.pulseaudio}/bin/pactl'

MODNUM=-1
function cleanup() {
  $pwcli destroy $MODNUM
}

#function pwdump() {
#  "$pw/pw-dump" $?
#}

# find mic and related info
mic=$($pwdump | jq -re '.[] | select(.info.props."device.product.name" == "HD Webcam C615" and .info.props."media.class" == "Audio/Device")')

micid=$(echo $mic | jq -re '.id')
micportid=$(echo $mic | jq -re '.info.params.Route[0].index')

echo "found mic @ $micid with output @ $micportid"

# w-dump | jq -re '.[] | select(.info.props."node.name" == "Noise Suppression (RnNoise)")'
#MODNUM=$($pactl load-module module-null-sink object.linger=1 media.class=Audio/Duplex sink_name=boom channel_map=mono)
#echo "loaded sink @ $MODNUM"
trap cleanup SIGTERM

$pwjack $jalv -i 'https://github.com/werman/noise-suppression-for-voice' &

wait

'') + "";
      };
    };
  };

  services.syncthing.enable = pkgs.hostPlatform.isLinux;
  
  home.sessionVariables = {
    EDITOR = "emacsclient";
  };
  programs.bash.enable = true;
  programs.bash.initExtra = ''[[ ! "$0" = "bash" ]] && exec fish'';
  programs.fish.enable = true;
  programs.fish.interactiveShellInit = ''
function __fish_command_not_found_handler --on-event fish_command_not_found
    # ${pkgs.nix-index}/bin/nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$argv[1]"
    echo "$argv[1] not found. try"(set_color green) "nix search"(set_color reset)"."
end
'';

  programs.direnv.enable = true;
  programs.direnv.enableNixDirenvIntegration = true;
  programs.htop.showCpuFrequency = true;

  programs.git = {
    enable = true;
    userName = "Andrew Pan";
    userEmail = "known@unown.me";
    
    extraConfig = {
      credential.helper = "${pkgs.git-credential-keepassxc}/bin/git-credential-keepassxc";
      core.excludesFile = (pkgs.writeText ".gitignore" ''
# Emacs
*~
\#*\#

# Nix
.direnv/

# clangd
.clangd/

# CMake stuff
build/
'').outPath;
    };
  };

  programs.alacritty.enable = true;
  #programs.alacritty.settings = ''
#
#'';


  
  gtk.enable = pkgs.hostPlatform.isLinux;
  gtk.theme.name = "Nordic";
  dconf.settings = pkgs.lib.mkIf pkgs.hostPlatform.isLinux {
    "org/gnome/desktop/wm/preferences" =  {
      theme = "Nordic";
    };
    "org/gnome/shell/extensions/user-theme" = {
      name = "Nordic";
    };
  };
}
