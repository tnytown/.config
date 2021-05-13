(final: prev: let uprev = prev.unstable; in {
  flashrom = prev.flashrom.overrideAttrs(o: {
    version = "git";
    nativeBuildInputs = o.nativeBuildInputs ++ [ prev.git prev.cmocka ];
    # NB: getrevision.sh is excluded with gitattributes.
    # fetchGitHub seems to fetch the tarball, which respects this.
    src = prev.fetchgit {
      url = "https://github.com/flashrom/flashrom";
      rev = "32f4cb4ffa2854354f00e5facc9ccb8c9beafd61";
      sha256 = "sha256-C7LcZwZtzg4BEzwzcn/O6Dj8fss2/KGIQMfoH6ewhqw=";
    };
  });

  hawck = prev.stdenv.mkDerivation rec {
    pname = "hawck";
    version = "60aafac2d8e5a6ec314dd41383daa5f4658caca5";

    nativeBuildInputs = [ prev.meson prev.ninja prev.pkg-config prev.makeWrapper ];
    buildInputs = [ prev.lua5_3 prev.libnotify prev.catch2 prev.python3 ];

    mesonFlags = let etc = "${placeholder "out"}/etc";
                 in [ "-Dhawck_cfg_dir=${etc}" "-Dmodules_load_dir=${etc}/modules-load.d" "-Dudev_rules_dir=${etc}/udev/rules.d" ];
    src = prev.fetchFromGitHub {
      owner = "snyball";
      repo = "Hawck";
      rev = "${version}";
      sha256 = "sha256-lHTObTBG+RSN0y4rb22nwiY/wSYKRon6iTAdNLocj+M=";
    };

    patchPhase = ''
    substituteInPlace bin/meson.build --replace "systemd_prefix = '/usr/lib/systemd'" "systemd_prefix = '${placeholder "out"}/lib/systemd'"
    substituteInPlace src/Lua/Keymap.lua --replace '/usr/share/kbd/keymaps' '${prev.kbd}/share/keymaps'
    substituteInPlace bin/hawck-install.sh.in --replace "#!/bin/bash" "#!${prev.bash}/bin/bash"
    substituteInPlace src/scripts/hawck-add.sh --replace "lua5.3" "echo \$script_path; cat \$script_path; LUA_PATH=\$LUA_PATH';'\$(realpath \$HOME/.local/share/hawck/scripts/)'/?.lua' ${prev.lua5_3}/bin/lua"
    substituteInPlace src/Version.cpp --replace '-' ""
    substituteInPlace src/KBDDaemon.cpp --replace '(IN_CREATE | IN_MODIFY)' 'IN_ATTRIB'
'';
    postFixup = let luaPath = "$out/share/hawck/LLib/?.lua;$out/share/hawck/?.lua";
                in ''
    wrapProgram "$out/bin/hawck-add" --set LUA_PATH "${luaPath}"
    wrapProgram "$out/bin/hawck-macrod" --set LUA_PATH "${luaPath}" \
                                        --prefix PATH : "${prev.lib.makeBinPath [ prev.gzip ]}" \
                                        --prefix PATH : "$out/bin"
'';

    # DESTDIR = "${placeholder "out"}";
  };

  rnnoise-plugin = prev.rnnoise-plugin.overrideAttrs(o: {
    version = "e391a9b";
    src = prev.fetchFromGitHub {
      owner = "werman";
      repo = "noise-suppression-for-voice";
      rev = "e391a9b7e04505a628b455c9d194a3c7006e4ae9";
      sha256 = "sha256-OvJyJrUdnT4M/3iBELzzArIeiUVb+nJu+8sIsspOxkQ=";
    };
  });

  libbde = prev.stdenv.mkDerivation {
    pname = "libbde";
    version = "alpha-20200724";

    buildInputs = [ prev.fuse ];
    src = builtins.fetchTarball {
      url = "https://github.com/libyal/libbde/releases/download/20200724/libbde-alpha-20200724.tar.gz";
      sha256 = "1qh3m3f8jb53p9241v53ws0if2874v90fadjs86lm8fgba0zfaak";
    };
  };

  git-credential-keepassxc = let prev = final.unstable; in prev.rustPlatform.buildRustPackage rec {
    pname = "git-credential-keepassxc";
    version = "0.4.3";

    buildInputs = prev.lib.optionals (prev.targetPlatform.isDarwin) [ prev.darwin.apple_sdk.frameworks.IOKit ];
    src = prev.fetchFromGitHub {
      owner = "Frederick888";
      repo = pname;
      rev = "v${version}";
      sha256 = "1kzq6mnffxfsh1q43c99aq2mgm60jp47cs389vg8qpd1cqh15nj0";
    };

    cargoSha256 = "sha256-fglAwQB+UdOJeBcg9NForaxrel7ME9p8VP4k4Rj0jtU=";

    meta = with prev.stdenv.lib; {
      description = "Helper that allows Git (and shell scripts) to use KeePassXC as credential store";
      homepage = "https://github.com/Frederick888/git-credential-keepassxc";
      license = licenses.gpl3Only;
      maintainers = [ "tny" ];
    };

    doCheck = false;
  };

  discord = prev.discord.overrideAttrs(_: rec {
    version = "0.0.14";
    src = prev.fetchurl {
      url = "https://dl.discordapp.net/apps/linux/${version}/discord-${version}.tar.gz";
      hash = "sha256-wmUa70ssB4o9CXW4L9ORVx3sqmNuUjQ7tPEW2hxIBOc=";
    };
  });

  xdg-desktop-portal-wlr = prev.xdg-desktop-portal-wlr.overrideAttrs(_: rec {
    version = "9ba958c7d2a2ab11ac8014263e153c1236fb3014";
    nativeBuildInputs = _.nativeBuildInputs ++ [ prev.scdoc prev.iniparser ];
    buildInputs = _.buildInputs ++ [ prev.iniparser ];
    postPatch = ''
substituteInPlace meson.build --replace "join_paths(get_option('prefix'),get_option('libdir'))" "'${prev.iniparser}/lib'"
'';
    mesonFlags = [ "-Dman-pages=enabled" "-Dsystemd=enabled" "-Dsd-bus-provider=libsystemd" ];
    src = prev.fetchFromGitHub {
      owner = "emersion";
      repo = _.pname;
      rev = version;
      hash = "sha256-DGTdrMertxMWL1ilYs+HHNkiTOnbcIlwMIdOTjyzdD4=";
    };
  });

  ethminer = prev.ethminer.overrideAttrs(_: rec {
    buildInputs = with prev; [
      cli11 boost opencl-headers mesa ethash opencl-info
      ocl-icd openssl jsoncpp
    ];
    cmakeFlags = [
      "-DHUNTER_ENABLED=OFF"
      "-DETHASHCUDA=OFF"
      "-DAPICORE=ON"
      "-DETHDBUS=OFF"
      "-DCMAKE_BUILD_TYPE=Release"
    ];
  });

  obs-studio = prev.obs-studio.overrideAttrs(_: rec {
    version = "27.0.0-rc2";
    src = prev.fetchFromGitHub {
      owner = "obsproject";
      repo = "obs-studio";
      rev = version;
      sha256 = "sha256-obmTdR7Ip3gY6q2PMKArPisnschdPt6vsj7VC7EHRiw=";
      fetchSubmodules = true;
    };
  });

  wlgreet = prev.greetd.wlgreet.overrideAttrs(_: rec {
    version = "2366f870440fe9ab9dd5270edc47ec54ee24ff5d";
    src = prev.fetchFromSourcehut {
      owner = "~kennylevinsen";
      repo = _.pname;
      rev = version;
      sha256 = "sha256-cCoROsGhKOR8unMPFrtYIZZT1Wgq9Cn/BJzJnE2rwe8=";
    };
  });

  linuxPackagesOverride = linuxPackages:
    linuxPackages.extend (lfinal: lprev: {
      corefreq =
      let kernel = lprev.kernel;
      in final.stdenv.mkDerivation rec {
        pname = "corefreq";
        version = "1.84";

        passthru.moduleName = "corefreqk";

        nativeBuildInputs = [ kernel.moduleBuildDependencies ];

        makeFlags = [
          "KERNELDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
          "INSTALL_MOD_PATH=$(out)"
          "PREFIX=$(out)"
        ];

        src = final.fetchFromGitHub {
          owner = "cyring";
          repo = pname;
          rev = version;
          hash = "sha256-w6OSeNEBZ+3mX1nt8QvT+i/9ATM3rc6UETjFB5Lk22M=";
        };
      };
    });
})
