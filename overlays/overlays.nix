(final: prev: let uprev = prev.unstable; in rec {
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

  minecraft-server-fabric = prev.callPackage ./minecraft-server-fabric {};
  # Begin CA hacks
  a52dec = prev.a52dec.overrideAttrs(o: rec {
    src = prev.fetchurl {
      url = "${meta.homepage}/files/${o.pname}-${o.version}.tar.gz";
      sha256 = "oh1ySrOzkzMwGUNTaH34LEdbXfuZdRPu9MJd5shl7DM=";
    };
    meta = o.meta // {
      homepage = "https://liba52.sourceforge.io/";
    };
  });

  SDL_image = prev.SDL_image.overrideAttrs(_: {
    patches = [
      (prev.fetchpatch {
        name = "CVE-2017-2887";
        url = "https://github.com/libsdl-org/SDL_image/commit/e7723676825cd2b2ffef3316ec1879d7726618f2.diff";
        sha256 = "sha256-SOPCmo6XHFs0gFj3YW1zMIpyQcvXyMpiHtqxu9j/8dM=";
      })
    ];
  });

  openjdk8 = with prev; prev.openjdk8.overrideAttrs(o: {
    srcs = let
      sr = d: h: d.overrideAttrs(o_: { outputHash = h; });
      sro =  n: h: sr (builtins.elemAt o.srcs n) h;
      jdk = builtins.elemAt o.srcs 0;
      corba = builtins.elemAt o.srcs 3;
    in [
      (sro 0 "sha256-ld5AdD4sd2IzfJPU647Hj724MEy9z2W1F50Uz60VC9s=")
      (sro 1 "sha256-A6uV2khiC4cDvFnFEOTCEcHiIb4Akzc3pOuEtcJnqIg=")
      (sro 2 "sha256-MluJ68kmoRxDEslkVACtoe//q1m8X6WyJoIFtL7Gwe8=")
      (sro 3 "sha256-z2AgHR7lOo33UBs2ghI3g3oAguSl2714E3I6L9xD0sk=")
      (sro 4 "sha256-5bOTdz6H3/9cJvkGk4vHD7iv0DVl+ibPVDzW9JHmeV4=")
      (sro 5 "sha256-9tWzJLoUiPxF3wswkHE+IDMX8f866YkpkvO9DXuPSV0=")
      (sro 6 "sha256-nFcgWJhdp2ZElM5XEREvMvy42dT+UsPnLM15Jf6u5mU=")
      (sro 7 "sha256-fQE0eg6J5qzUw5+zGCaetEfmTXJRkhnD7KLhi10t8Gg=")
    ];
  });

  java = openjdk8;

  SDL = with prev; prev.SDL.overrideAttrs(o: {
    patches = [
      # "${prev.pkgs}/pkgs/development/libraries/SDL/find-headers.patch"
      "${builtins.head o.patches}"

      # Fix window resizing issues, e.g. for xmonad
      # Ticket: http://bugzilla.libsdl.org/show_bug.cgi?id=1430
      (fetchpatch {
        name = "fix_window_resizing.diff";
        url = "https://bugs.debian.org/cgi-bin/bugreport.cgi?msg=10;filename=fix_window_resizing.diff;att=2;bug=665779";
        sha256 = "1z35azc73vvi19pzi6byck31132a8w1vzrghp1x3hy4a4f9z4gc6";
      })
      # Fix drops of keyboard events for SDL_EnableUNICODE
      (fetchpatch {
        url = "https://github.com/libsdl-org/SDL-1.2/commit/0332e2bb18dc68d6892c3b653b2547afe323854b.patch";
        sha256 = "sha256-5V6K0oTN56RRi48XLPQsjgLzt0a6GsjajDrda3ZEhTw=";
      })
      # Ignore insane joystick axis events
      (fetchpatch {
        url = "https://github.com/libsdl-org/SDL-1.2/commit/ab99cc82b0a898ad528d46fa128b649a220a94f4.patch";
        sha256 = "sha256-uussXT9Spsg8WUX5CNHZ6HthYy3HE381xi03Ygv3hwU=";
      })
      # https://bugzilla.libsdl.org/show_bug.cgi?id=1769
      (fetchpatch {
        url = "https://github.com/libsdl-org/SDL-1.2/commit/5d79977ec7a6b58afa6e4817035aaaba186f7e9f.patch";
        sha256 = "sha256-JvMP7+P/NmWLNsCGfElDLdlA99Nbggw+5jskD572fXU=";
      })
      # Workaround X11 bug to allow changing gamma
      # Ticket: https://bugs.freedesktop.org/show_bug.cgi?id=27222
      (fetchpatch {
        name = "SDL_SetGamma.patch";
        url = "https://src.fedoraproject.org/cgit/rpms/SDL.git/plain/SDL-1.2.15-x11-Bypass-SetGammaRamp-when-changing-gamma.patch?id=04a3a7b1bd88c2d5502292fad27e0e02d084698d";
        sha256 = "0x52s4328kilyq43i7psqkqg7chsfwh0aawr50j566nzd7j51dlv";
      })
      # Fix a build failure on OS X Mavericks
      # Ticket: https://bugzilla.libsdl.org/show_bug.cgi?id=2085
      (fetchpatch {
        url = "https://github.com/libsdl-org/SDL-1.2/commit/19039324be71738d8990e91b9ba341b2ea068445.patch";
        sha256 = "sha256-CPcLE+8JMKoiJEdIWNVphIMIgDOIJBmkSNO1zuM97B8=";
      })
      (fetchpatch {
        url = "https://github.com/libsdl-org/SDL-1.2/commit/7933032ad4d57c24f2230db29f67eb7d21bb5654.patch";
        sha256 = "sha256-6CdDVsrka8zlqFrZ2SCo62DuiSWiGJIfLi/rMX2v0W4=";
      })
    ];
  });

  mercurial = prev.mercurial.overrideAttrs(o: {
    patches = [
      (prev.fetchpatch {
        name = "D10638.diff";
        url = "https://phab.mercurial-scm.org/D10638?download=true";
        sha256 = "07bhprh5zwl37snn59jsvx0mnp6s0n3hi0zl8zwbb20nlbvfbvfz";
      })
      (prev.fetchpatch {
        name = "D10639.diff";
        url = "https://phab.mercurial-scm.org/D10639?download=true";
        sha256 = "1azj90r4xc4ygdli0bv1d4yi0nl5dx0vbiri3ihlfzaykhqgl3w9";
      })
    ];
  });
  # end CA hacks

  alex = prev.stdenv.mkDerivation rec {
    pname = "alex";
    version = "0.0.1";

    runtimeId = "linux-x64";

    src = prev.fetchFromGitHub {
      owner = "kennyvv";
      repo = "Alex";
      rev = "a080fe7373aa878a300af5831c6c7da9c9ca3e6d";
      sha256 = "sha256-hP6v1VsaU30QGLDnZPVyu5ysHIlEUyWPdbQ5M8cEsBY=";
      fetchSubmodules = true;
    };

    nativeBuildInputs = with prev; [
      dotnet-sdk_5
      dotnetPackages.Nuget
      makeWrapper
    ];

    propagatedBuildInputs = with prev; [
      dotnet-aspnetcore
      SDL2
    ];

    #nugetDeps = [ "submodules/MiNET" "submodules/RocketUI" ];
    #nugetDeps = prev.symlinkJoin { name = "alex-deps"; paths = [ "${src}/submodules/MiNET/src/MiNET" "${src}/submodules/RocketUI" ]; };
    nugetDeps = prev.linkFarmFromDrvs "${pname}-nuget-deps" (import ./nuget-deps.nix {
      fetchNuGet = { name, version, sha256 }: prev.fetchurl {
        name = "nuget-${name}-${version}.nupkg";
        url = "https://www.nuget.org/api/v2/package/${name}/${version}";
        inherit sha256;
      };
    });
    configurePhase = ''
    runHook preConfigure
    export HOME=$(mktemp -d)
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_NOLOGO=1
    dotnet nuget add source --name nixos "$PWD/nixos"
    nuget init "$nugetDeps" "$PWD/nixos"
    # FIXME: https://github.com/NuGet/Home/issues/4413
    mkdir -p $HOME/.nuget/NuGet
    cp $HOME/.config/NuGet/NuGet.Config $HOME/.nuget/NuGet
    runHook postConfigure
    '';

    buildPhase = ''
    runHook preBuild
    cd src
    dotnet nuget disable source "NuGet official package source"
    dotnet nuget disable source "nuget.org"
    dotnet publish Alex \
      --configuration Release \
      --runtime ${runtimeId} \
      --no-self-contained \
      --output $out/bin/alex
    runHook postBuild
    '';
    installPhase = ''
    runHook preInstall
    makeWrapper ${prev.dotnet-aspnetcore}/bin/dotnet $out/bin/alex \
      #--suffix LD_LIBRARY_PATH : "${prev.lib.makeLibraryPath []}" \
      #--add-flags "$out/opt/jellyfin/jellyfin.dll"
    runHook postInstall
  '';
  };

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

    meta = with prev.lib; {
      description = "Helper that allows Git (and shell scripts) to use KeePassXC as credential store";
      homepage = "https://github.com/Frederick888/git-credential-keepassxc";
      license = licenses.gpl3Only;
      maintainers = [ "tny" ];
    };

    doCheck = false;
  };

  discord = prev.discord.overrideAttrs(_: rec {
    version = "0.0.15";
    src = prev.fetchurl {
      url = "https://dl.discordapp.net/apps/linux/${version}/discord-${version}.tar.gz";
      hash = "sha256-re3pVOnGltluJUdZtTlSeiSrHULw1UjFxDCdGj/Dwl4=";
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
          hash = "sha256-8dROUO3umAuORmotmQVLPnz2wPTNf9/2gkJapytamP4=";
        };
      };
    });
})
