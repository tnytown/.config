{ config, lib, pkgs, ... }:
{
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
    pkgs.zsh
    pkgs.neofetch
    pkgs.htop
    pkgs.tectonic

    pkgs.direnv

    pkgs.just
    pkgs.git-credential-keepassxc
    pkgs.rust-analyzer

    pkgs.file
    pkgs.binutils
    pkgs.jq
    pkgs.ripgrep
    # pkgs.openrgb
    pkgs.zip
    pkgs.unzip

    pkgs.ffmpeg
    pkgs.exiftool
    pkgs.python3Packages.binwalk
  ] ++ (if pkgs.stdenv.isLinux then [
    # pkgs.jetbrains.idea-ultimate
    pkgs.osu-lazer
    pkgs.rnnoise-plugin

    ((pkgs.multimc.overrideAttrs(o: { postInstall = o.postInstall + ''
	wrapProgram $out/bin/multimc --prefix PATH : ${lib.makeBinPath [
    (pkgs.runCommandNoCC "java16-link" {} ''
mkdir -p $out/bin
ln -s ${pkgs.adoptopenjdk-hotspot-bin-16}/bin/java $out/bin/java16
'')
  ]}
''; })).override { })

    pkgs.gnome3.gnome-shell-extensions
    pkgs.nordic
    pkgs.openrgb
    pkgs.pavucontrol
    pkgs.keepassxc
    # pkgs.emacsPgtkGcc
    pkgs.spotify
    pkgs.slack
    pkgs.discord
    # pkgs.ppsspp
    pkgs.zoom-us
    pkgs.chromium
    pkgs.mpv
    pkgs.lutris
    # pkgs.slic3r-prusa3d
    pkgs.openscad
    #pkgs.obs-studio
    pkgs.shotcut
    pkgs.qjackctl
    pkgs.jalv
    pkgs.lilv
    pkgs.xsel
    pkgs.cntr

    pkgs.flashrom
    pkgs.libbde
    pkgs.dnsutils

    pkgs.slurp
    pkgs.grim
    pkgs.wl-clipboard
  ] else [ ]);

  xdg.configFile = lib.mkIf pkgs.stdenv.isLinux {
    /*"obs-studio/plugins/wlrobs".source =
      "${pkgs.obs-wlrobs}/share/obs/obs-plugins/wlrobs";*/
  };

  xdg.dataFile = lib.mkIf pkgs.stdenv.isLinux {
    "hawck/scripts/LLib".source = "${pkgs.hawck}/share/hawck/LLib";
  };

  systemd.user.services = lib.mkIf pkgs.stdenv.isLinux {
    # rnnoise-plugin
    rnnoise = {
      Unit = { Description = "RNNoise LV2 plugin for JACK"; };

      Service = {
        Type = "simple";
        ExecStart = (pkgs.writeScript "start1.sh" ''
          #!${pkgs.bash}/bin/bash

          set -euf -o pipefail

          export LV2_PATH=${pkgs.rnnoise-plugin}/lib/lv2/
          pw='${pkgs.pipewire}/bin'
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

  home.sessionVariables = { EDITOR = "emacsclient"; };
  programs.bash.enable = true;
  programs.bash.initExtra = ''[[ ! "$0" = "bash" ]] && exec fish'';
  programs.fish.enable = true;
  programs.fish.interactiveShellInit = ''
    function __fish_command_not_found_handler --on-event fish_command_not_found
        # ${pkgs.nix-index}/bin/nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$argv[1]"
        echo "$argv[1] not found. try"(set_color green) "nix search"(set_color reset)"."
    end
  '';

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    nix-direnv.enableFlakes = true;
  };

  programs.htop.showCpuFrequency = true;

  programs.git = {
    enable = true;
    userName = "Andrew Pan";
    userEmail = "known@unown.me";

    extraConfig = {
      init.defaultBranch = "main";
      credential.helper =
        "${pkgs.git-credential-keepassxc}/bin/git-credential-keepassxc --unlock 0";
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
    "org/gnome/desktop/wm/preferences" = { theme = "Nordic"; };
    "org/gnome/shell/extensions/user-theme" = { name = "Nordic"; };
  };

  imports = let
    # c = { inherit (pkgs.hostPlatform) isLinux isDarwin; };
    mod = path: cond: { inherit path cond; };
    mods = [
      (mod ./modules/hm/desktop.nix false)

    ];
  in builtins.filter (x: x.cond) mods;
}
