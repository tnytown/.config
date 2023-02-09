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
        statusCommand = "sh ${../../libexec/swaystatus.sh}";
        fonts = {
          names = [ "monospace" ];
          size = 10.0;
        };
      }];
      keybindings = {
        "${mod}+Shift+j" = "focus left";
        "${mod}+Shift+k" = "focus right";
        "${mod}+Shift+h" = "resize shrink width 10px";
        "${mod}+Shift+l" = "resize grow width 10px";
        "${mod}+Return" = "exec ${pb "alacritty"}";
        "Mod4+q" = "kill";
        "Mod4+l" = "exec loginctl lock-session";

        "Ctrl+Mod4+Shift+4" = "exec ${
        pkgs.writeScript "screenshot.sh" ''
              slurp | grim -g - - | wl-copy -t 'image/png'
            ''
      }";
        "Mod4+Space" = ''
          exec 'pgrep bemenu || \
               ${pb "j4-dmenu-desktop"} \
               --dmenu="${pb "bemenu"} -i" \
               --term="${pb "alacritty"}"'
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
        "DP-3" = {
          position = "0 0";
          mode = "2560x1440@119.998Hz";
          enable = "";
        };
        # R
        "DP-1" = {
          position = "2560 0";
          mode = "3840x2160@59.997Hz";
	  scale = "1.5";
          enable = "";
        };
        # headset
        "HDMI-A-1" = { disable = ""; };

        # global
        "*" = { bg = "~/Pictures/bg_gw_city_snow_night.jpg fill"; };
      };

      input = {
        "1386:770:Wacom_Intuos_PT_S_Pen" = {
          map_to_output = "DP-1";
          map_from_region = "0.0x0.0 0.203x0.267";
        };
      };

      assigns = {
        "1: web" = [{ app_id = "^firefox$"; }];
        "2: dev" = [{ app_id = "^Alacritty$"; } { app_id = "^emacs$"; }];
        "5: chat" = [{ class = "^discord$"; }];
      };

      workspaceOutputAssign = [
        { workspace = "1: web"; output = "DP-3"; }
        { workspace = "2: dev"; output = "DP-3"; }
        { workspace = "3"; output = "DP-3"; }
        { workspace = "4"; output = "DP-3"; }
        { workspace = "5: chat"; output = "DP-1"; }
      ];

      startup =
        map (x: { command = x; }) [ "firefox" "emacsclient -c" "alacritty" /*"Discord"*/ ];

      gaps.inner = 30;
      gaps.outer = 0;
    };

    extraConfig =
      let lockCmd = "swaylock -f -F -i ~/Pictures/bg_gw_city_snow_night.jpg";
      in ''
        for_window [class=".*"] inhibit_idle fullscreen
        # weird hack: assignment for firefox doesn't name it correctly
        # also: rename command is invalid in config ??
        # exec swaymsg rename workspace 1 to "1: web"
        exec swayidle -w \
            timeout 300 'loginctl lock-session' \
            timeout 360 'swaymsg "output * dpms off"' \
            resume 'swaymsg "output * dpms on"' \
            lock '${lockCmd}' \
            unlock 'pkill -9 swaylock' \
            before-sleep 'loginctl lock-session'
      '';
    systemdIntegration = true;
  };
in
{
  wayland.windowManager.sway = wl-config;

  services.gammastep.provider = "geoclue2";

  services.gammastep.enable = true;
  services.gammastep.settings = {
    general = {
      adjustment-method = "wayland";
    };
  };

  home.packages = with pkgs; [
    qt5ct

    breeze-qt5
    breeze-icons
  ];

  /*home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };*/

  qt = {
    enable = true;
    # platformTheme = "breeze";
    style = {
      name = "Breeze-Dark";
      package = pkgs.libsForQt5.breeze-qt5;
    };
  };

  gtk.enable = pkgs.hostPlatform.isLinux;

  gtk.theme = {
    package = pkgs.libsForQt5.breeze-gtk;
    name = "Breeze-Dark"; # org.gnome.desktop.interface.gtk-theme
  };

  gtk.iconTheme = {
    name = "Breeze-Dark";
    package = pkgs.libsForQt5.breeze-gtk;
  };

  gtk.gtk3.extraConfig = {
    gtk-application-prefer-dark-theme = 1;
  };

  dconf.settings = lib.mkIf pkgs.hostPlatform.isLinux {
    "org/gnome/desktop/wm/preferences" = { theme = "Breeze-Dark"; };
    "org/gnome/shell/extensions/user-theme" = { name = "Breeze-Dark"; };
  };

  /*
    xdg.configFile."kdeglobals".text = lib.generators.toINI {} {
    KDE = {
      WidgetStyle = "Breeze";
    };
    General = {
      ColorScheme = "BreezeDark";
    };
    };
    xdg.dataFile."kstyle/themes/breezedark.themerc".text = lib.generators.toINI {} {
    Misc.Name = "BreezeDark";
    KDE = {
      WidgetStyle = "Breeze";
    };
    General = {
      ColorScheme = "BreezeDark";
    };
    };
    xdg.configFile."Trolltech.conf".text = ''
    [Qt]
    style=BreezeDark
  '';*/
}
