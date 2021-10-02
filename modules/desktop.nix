{ lib, pkgs, config, ... }: {

  # window manager
  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      mako
      xdg_utils
    ];
    extraSessionCommands = ''
      # needs qt5.qtwayland in systemPackages
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      # Fix for some Java AWT applications (e.g. Android Studio),
      # use this if they aren't displayed properly:
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';
    wrapperFeatures = {
      base = true;
    };
  };

  # greeter
  users.users.greeter.group = "greeter";
  users.groups.greeter = { };
  services.greetd =
    let
      greetConfig = pkgs.writeText "greetd-config.toml" ''
        command = "sway"
        outputMode = "active"
        scale = 1

        [background]
        red = 0.09
        green = 0.13
        blue = 0.23
        opacity = 0.5

        [headline]
        red = 1.0
        green = 1.0
        blue = 1.0
        opacity = 1.0

        [prompt]
        red = 0.42
        green = 0.47
        blue = 0.55
        opacity = 1.0

        [promptErr]
        red = 1.0
        green = 0.6
        blue = 0.1
        opacity = 1.0

        [border]
        red = 0.09
        green = 0.13
        blue = 0.23
        opacity = 0.3
      '';
      swayConfig = pkgs.writeText "greeter-sway-config" ''
        output * background /etc/sway/control_room_lockscreen.jpg fill

        exec swaynag -m 'Authenticate to access the system.'
        exec "${pkgs.wlgreet}/bin/wlgreet --config ${greetConfig} --command sway; swaymsg exit"

        bindsym Mod4+Return exec ${pkgs.alacritty}/bin/alacritty
        bindsym Mod4+shift+e exec swaynag \
          -t warning \
          -m 'What do you want to do?' \
          -b 'Poweroff' 'systemctl poweroff' \
          -b 'Reboot' 'systemctl reboot'

        bindsym Ctrl+Mod4+Shift+4 exec ${
                    pkgs.writeShellScript "screenshot.sh" ''
                      ${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - >"$(mktemp -u).png"
                    ''
        }";

        include /etc/sway/config.d/*
      '';
    in
    {
      enable = true;
      restart = true;
      settings = {
        default_session = {
          command = pkgs.writeShellScript "greeter-sway" ''
            export PATH=${pkgs.sway}/bin:$PATH
            export LD_LIBRARY_PATH=${pkgs.wayland}/lib:${pkgs.libxkbcommon}/lib:$LD_LIBRARY_PATH
            exec ${pkgs.systemd}/bin/systemd-cat -t sway ${pkgs.sway}/bin/sway --config ${swayConfig}
          '';
        };
      };
    };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    gtkUsePortal = true;
  };

  environment.sessionVariables = {
    SDL_VIDEODRIVER = "wayland";
    XDG_CURRENT_DESKTOP = "sway";
  };


  boot.kernelParams = [
    "video=DP-2:2560x1440@120"
    "video=efifb:off"
    # disable secondary display until bootup
    # "video=DP-1:d"
  ];
  systemd.services.enable-display = {
    wantedBy = [ "multi-user.target" ];
    description = "Hotplug Display";
    restartIfChanged = false;

    serviceConfig = {
      type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "display-hotplug.sh" ''
        CARD="0"
        INPUT="DP-1"

        STATUS_PATH="/sys/class/drm/card$CARD-$INPUT/status"
        HOTPLUG_PATH="/sys/kernel/debug/dri/$CARD/$INPUT/trigger_hotplug"

        echo "$INPUT: status: $(cat $STATUS_PATH)"

        echo detect >"$STATUS_PATH"
        echo 1 >"$HOTPLUG_PATH"

        echo -e "$INPUT: paths:\n$(stat $STATUS_PATH)\n$(stat $HOTPLUG_PATH)"
      '';

      ExecStop = pkgs.writeShellScript "display-disable.sh" ''
        CARD="0"
        INPUT="DP-2"

        STATUS_PATH="/sys/class/drm/card$CARD-$INPUT/status"
        HOTPLUG_PATH="/sys/kernel/debug/dri/$CARD/$INPUT/trigger_hotplug"

        echo off >"$STATUS_PATH"
      '';
    };
  };

  # sane fonts
  fonts = {
    fonts = [
      pkgs.meslo-lg
      pkgs.noto-fonts-cjk
      pkgs.noto-fonts-emoji
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = lib.mkForce [ "Meslo LG S" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
      };
    };
  };
}
