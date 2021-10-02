{ config, lib, pkgs, ... }:
let
  pb = pkg: "${pkgs.${pkg}}/bin/${pkg}";
  mod = "Mod1";
  wl-config = {
    enable = true;
    package = null;
    config = {
      modifier = mod;

      bars = [{
        colors = {
          background = "#000000a0";
        };
        mode = "dock";
        position = "top";
        #statusCommand = "${pkgs.sway}/bin/swaybar";
        statusCommand = (pkgs.writeScript "swaystatus" ''
          set -euo pipefail

          function n() {
                ip -j -s link | jq -r 'reduce (.. | .bytes? | select(. != null)) as $i (0; . + $i)'
          }

          np=`n`
          while true; do
                sleep 1;
                np_o="$np"
                np=`n`
                echo \
                     'load:' $(uptime | sed -E 's/.*load average: ([^ ]+),.*/\1/')'x' '|' \
                     'cpu:' $(sensors -j 'k10temp-pci-*' | jq '.. | .Tdie?.temp2_input | select(. != null) | floor')'C' '|' \
                     'mem:' $(free -mh | awk 'NR == 2 {print $3}') '|' \
                     'net:' "$(echo $(( $np - $np_o )) | numfmt --to=iec-i --padding=5)" '|' \
                     $(date +'%Y-%m-%d %H:%M:%S');
          done
        '').outPath;
        fonts = [ "monospace 10" ];
      }];
      keybindings = {
        "${mod}+Shift+j" = "focus left";
        "${mod}+Shift+k" = "focus right";
        "${mod}+Shift+h" = "resize shrink width 10px";
        "${mod}+Shift+l" = "resize grow width 10px";
        "${mod}+Return" = "exec ${pb "alacritty"}";
        "Mod4+q" = "kill";
        "Mod4+l" = "exec swaylock -F -i ~/Pictures/bg_gw_city_snow_night.jpg";

        "Ctrl+Mod4+Shift+4" = "exec ${
        pkgs.writeScript "screenshot.sh" ''
              slurp | grim -g - - | wl-copy -t 'image/png'
            ''
      }";
        "Mod4+Space" = ''
          exec ${pb "j4-dmenu-desktop"} --dmenu="${pb "bemenu"} -i" --term="${
                                    pb "alacritty"
                                  }"
        '';
        "Mod4+Shift+f" = "fullscreen toggle";
        # --wrapper="${pkgs.systemd}/bin/systemd-run --user --scope "
      } // builtins.listToAttrs (builtins.concatLists (map
        (s:
          let x = builtins.toString s.fst;
          in [
            {
              name = "Ctrl+${x}";
              value = "workspace \"${x}: ${s.snd}\"";
            }
            {
              name = "Ctrl+Shift+${x}";
              value = "move to workspace \"${x}: ${s.snd}\"";
            }
          ])
        (lib.zipLists (lib.range 1 5) [ "web" "dev" "" "" "chat" ])));

      output = {
        # L
        "DP-2" = {
          position = "0 0";
          mode = "2560x1440@119.998Hz";
          enable = "";
        };
        # R
        "DP-1" = {
          position = "2560 0";
          mode = "1920x1200@59.950Hz";
          enable = "";
        };
        # headset
        "HDMI-A-1" = { disable = ""; };

        # global
        "*" = { bg = "~/Pictures/bg_gw_city_snow_night.jpg fill"; };
      };

      input = {
        "1386:770:Wacom_Intuos_PT_S_Pen" = {
          map_to_output = "DP-2";
          map_from_region = "0.0x0.0 0.203x0.267";
        };
      };

      assigns = {
        "1: web" = [{ app_id = "^firefox$"; }];
        "2: dev" = [{ app_id = "^Alacritty$"; } { app_id = "^emacs$"; }];
        "5: chat" = [{ class = "^discord$"; }];
      };

      workspaceOutputAssign = [
        { workspace = "1: web"; output = "DP-2"; }
        { workspace = "2: dev"; output = "DP-2"; }
        { workspace = "3"; output = "DP-2"; }
        { workspace = "4"; output = "DP-2"; }
        { workspace = "5: chat"; output = "DP-1"; }
      ];

      startup =
        map (x: { command = x; }) [ "firefox" "emacsclient -c" "alacritty" /*"Discord"*/ ];

      gaps.inner = 30;
      gaps.outer = 0;
    };

    extraConfig =
      let lockCmd = "pgrep swaylock || swaylock -F -i ~/Pictures/bg_gw_city_snow_night.jpg";
      in ''
        for_window [class=".*"] inhibit_idle fullscreen
        # weird hack: assignment for firefox doesn't name it correctly
        # also: rename command is invalid in config ??
        # exec swaymsg rename workspace 1 to "1: web"
        exec swayidle -w \
            timeout 300 '${lockCmd}' \
            timeout 315 'loginctl lock-session' resume 'swaymsg "output * dpms on"' \
            lock '${lockCmd}; swaymsg "output * dpms off"' \
            unlock 'pkill swaylock' \
            before-sleep 'loginctl lock-session'
      '';
    systemdIntegration = true;
  };
in
{
  wayland.windowManager.sway = wl-config;
}
