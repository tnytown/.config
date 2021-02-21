{ config, pkgs, ... }:


# let pkgs = { inherit pkgs; pkgs.config.allowUnfree = true; }; in
let
  upkgs = pkgs.unstable;
    ujust = upkgs.just.overrideAttrs(o: rec {
      version = "0.8.3";
      src = pkgs.fetchFromGitHub {
        owner = "casey";
        repo = o.pname;
        rev = "v${version}";
        sha256 = "19hlmm9bal1lgagzxgrgs9c6z6mrqfzffr8337hin71yhiazc7p0";
      };

      # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/4
      cargoDeps = o.cargoDeps.overrideAttrs(_: {
        inherit src;
        name = "just-${version}-vendor.tar.gz";
        outputHash = "1773gzr6yl0m1c2fx8cwd3zx2467qdmg7vnlykw82jlg2l6skqxq";
      });

      # disable testing
      doCheck = false;
    });
    git-credential-keepassxc = pkgs.rustPlatform.buildRustPackage rec {
      pname = "git-credential-keepassxc";
      version = "0.4.3";

      src = pkgs.fetchFromGitHub {
        owner = "Frederick888";
        repo = pname;
        rev = "v${version}";
        sha256 = "1kzq6mnffxfsh1q43c99aq2mgm60jp47cs389vg8qpd1cqh15nj0";
      };

      cargoSha256 = "1ghag2v6nsf7qnh0i2mjzm0hkij65i7mnbb297mdsprc6i8mn3xn";

      meta = with pkgs.stdenv.lib; {
        description = "Helper that allows Git (and shell scripts) to use KeePassXC as credential store";
        homepage = "https://github.com/Frederick888/git-credential-keepassxc";
        license = licenses.gpl3Only;
        maintainers = [ "tny" ];
      };

      doCheck = false;
    };

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
  home.packages = 
    let discord = 
          pkgs.discord.overrideAttrs(_: rec {
            version = "0.0.13";
            src = pkgs.fetchurl {
              url = "https://dl.discordapp.net/apps/linux/${version}/discord-${version}.tar.gz";
              sha256 = "0d5z6cbj9dg3hjw84pyg75f8dwdvi2mqxb9ic8dfqzk064ssiv7y";
            };
          });
    in [
      pkgs.fish pkgs.zsh pkgs.emacs pkgs.neofetch pkgs.htop pkgs.texlive.combined.scheme-full

         pkgs.multimc
         upkgs.steam
         pkgs.pavucontrol

         pkgs.syncthing
         pkgs.keepassxc

         pkgs.gnome3.gnome-shell-extensions
         pkgs.nordic
         upkgs.openrgb
         
         pkgs.spotify
         pkgs.slack
         discord
         pkgs.zoom-us
         
         pkgs.chromium
         pkgs.mpv
         pkgs.lutris

         pkgs.direnv
         git-credential-keepassxc
         ujust
         pkgs.cntr
         pkgs.rust-analyzer

         pkgs.flashrom

         pkgs.file
         pkgs.python3Packages.binwalk
         pkgs.binutils
         pkgs.jq
      pkgs.ripgrep
         # pkgs.openrgb
         pkgs.ppsspp

         pkgs.qjackctl
         pkgs.jalv
         pkgs.lilv
         pkgs.rnnoise-plugin

         pkgs.libbde

         pkgs.slic3r-prusa3d
         pkgs.openscad

         pkgs.obs-studio
         pkgs.shotcut
      pkgs.xsel
       ];

  systemd.user.services = {
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

  services.syncthing.enable = true;
  
  #home.sessionVariables = [];
  programs.bash.enable = true;
  programs.fish.enable = true;
  programs.direnv.enable = true;
  programs.direnv.enableNixDirenvIntegration = true;
  programs.htop.showCpuFrequency = true;

  programs.git = {
    enable = true;
    userName = "Andrew Pan";
    userEmail = "known@unown.me";
    
    extraConfig = {
      credential.helper = "${git-credential-keepassxc}/bin/git-credential-keepassxc";
      core.excludesFile = (pkgs.writeText ".gitignore" ''
# Emacs
*~
\#*\#

# Nix
.direnv/

'').outPath;
    };
  };

  programs.alacritty.enable = true;
  #programs.alacritty.settings = ''
#
#'';

  
  gtk.enable = true;
  gtk.theme.name = "Nordic";
  dconf.settings."org/gnome/desktop/wm/preferences" = {
    theme = "Nordic";
  };
  dconf.settings."org/gnome/shell/extensions/user-theme" = {
    name = "Nordic";
  };
  # dconf.settings."org/gnome/shell"
}
