{ config, pkgs, lib, ... }:

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
  home.stateVersion = lib.mkForce "21.03"; # wtf?

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
    pkgs.jetbrains.idea-ultimate
    pkgs.rnnoise-plugin
    
    pkgs.multimc

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

    pkgs.slurp pkgs.grim pkgs.wl-clipboard
  ] else []);

  xdg.configFile = lib.mkIf pkgs.stdenv.isLinux {
    "obs-studio/plugins/wlrobs".source = "${pkgs.obs-wlrobs}/share/obs/obs-plugins/wlrobs";
  };

  systemd.user.services = lib.mkIf pkgs.stdenv.isLinux {
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
pwdump=$pw'/pw-dump -N'
jalv='${pkgs.jalv}/bin/jalv'
pactl='${pkgs.pulseaudio}/bin/pactl'

MODNUM=-1
function cleanup() {
  $pwcli destroy $MODNUM
}

# find mic and related info
mic=$($pwdump | jq -re '
.[] | select(.info.props."device.product.name" == "HD Webcam C615"
and .info.props."media.class" == "Audio/Device")')

micid=$(echo $mic | jq -re '.id')
micportid=$(echo $mic | jq -re '.info.params.Route[0].index')

echo "found mic @ $micid with output @ $micportid"

# w-dump | jq -re '.[] | select(.info.props."node.name" == "Noise Suppression (RnNoise)")'
MODNUM=$($pactl load-module module-null-sink object.linger=1 media.class=Audio/Duplex sink_name=boom channel_map=mono)
echo "loaded sink @ $MODNUM"
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
      credential.helper = "${pkgs.git-credential-keepassxc}/bin/git-credential-keepassxc --unlock 0";
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
  dconf.settings = lib.mkIf pkgs.hostPlatform.isLinux {
    "org/gnome/desktop/wm/preferences" =  {
      theme = "Nordic";
    };
    "org/gnome/shell/extensions/user-theme" = {
      name = "Nordic";
    };
  };

  wayland.windowManager.sway = let
    pb = pkg: "${pkgs.${pkg}}/bin/${pkg}";
    mod = "Mod1";
  in {
    enable = true;
    package = null;
    config = {
      modifier = mod;

      bars = [{
        mode = "dock";
        position = "top";
        #statusCommand = "${pkgs.sway}/bin/swaybar";
        statusCommand = (pkgs.writeScript "swaystatus" ''
set -euo pipefail
while true; do
      sleep 1;
      echo \
           'load:' $(uptime | sed -E 's/.*load average: ([^ ]+),.*/\1/')'x' '|' \
           'cpu:' $(sensors -j 'k10temp-pci-*' | jq '.. | .Tdie?.temp2_input | select(. != null) | floor')'C' '|' \
           'mem:' $(free -mh | awk 'NR == 2 {print $3}') '|' \
           $(date +'%Y-%m-%d %l:%M:%S %p');
done
'').outPath;
        fonts = [ "monospace 10" ];
      }];
      keybindings = {
        "${mod}+Shift+j" = "focus left";
        "${mod}+Shift+k" = "focus right";
	      "${mod}+Return" = "exec ${pb "alacritty"}";
        "Mod4+q" = "kill";
        "Mod4+l" = "exec swaylock -F -i ~/Pictures/bg_gw_city_snow_night.jpg";

        "Ctrl+Mod4+Shift+4" = "exec ${pkgs.writeScript "screenshot.sh" ''
slurp | grim -g - - | wl-copy -t 'image/png'
''}";
        "Mod4+Space" = ''
exec ${pb "j4-dmenu-desktop"} --dmenu="${pb "bemenu"} -i" --term="${pb "alacritty"}"
'';
        "Mod4+Shift+f" = "fullscreen toggle";
      } // builtins.listToAttrs (map (s:
let x = builtins.toString s; in
{ name = "Ctrl+${x}"; value = "workspace number ${x}"; }) (lib.range 1 5));

      output = {
        # L
        "DP-1" = {
          position = "0 0";
          mode = "2560x1440@119.998Hz";
        };
        # R
        "DP-2" = {
          position = "2560 0";
        };
        # headset
        "HDMI-A-1" = {
          disable = "";
        };

        # global
        "*" = {
          bg = "~/Pictures/bg_gw_city_snow_night.jpg fill";
        };
      };

      input = {
        "1386:770:Wacom_Intuos_PT_S_Pen" = {
            map_to_output = "DP-1";
            map_from_region = "0.0x0.0 0.203x0.267";
        };
      };
    };

    extraConfig = ''
exec gaps inner all set 30
exec gaps outer all set 0

exec swayidle -w \
    timeout 300 'swaylock -F -i ~/Pictures/bg_gw_city_snow_night.jpg' \
    timeout 315 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"' \
    before-sleep 'swaylock -F -i ~/Pictures/bg_gw_city_snow_night.jpg'
'';
    systemdIntegration = true;
  };
}
