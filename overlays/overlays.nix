(final: prev: rec {
  libtpms = prev.libtpms.overrideAttrs(o: rec {
    version = "0.8.6";
    src = prev.fetchFromGitHub {
      owner = "stefanberger";
      repo = "libtpms";
      rev = "v${version}";
      hash = "sha256-XvugcpoFQhdCBBg7hOgsUzSn4ad7RUuAEkvyiPLg4Lw=";
    };
  });
  OVMF = (prev.OVMF.override({ secureBoot = true; })).overrideAttrs (o: {
    buildFlags = o.buildFlags ++ [
      "-DTPM_ENABLE=TRUE"
      "-DTPM_CONFIG_ENABLE=TRUE"
    ];
  });

  swtpm = prev.swtpm.overrideAttrs(o: rec {
    version = "1860183c42a0d43b444cb8cf3aae71de4ed0b601";
    nativeBuildInputs = o.nativeBuildInputs ++ [ prev.python3 prev.makeWrapper ];
    patches = [ ./localstatedir.patch ];
    prePatch = "";
    configureFlags = o.configureFlags ++ [
      "--localstatedir=/var"
    ];

    buildInputs = o.buildInputs ++ [ prev.json-glib ];
    src = prev.fetchFromGitHub {
      owner = "stefanberger";
      repo = "swtpm";
      rev = version;
      hash = "sha256-lAXxuE7GSJdfznlU0lXQpvu/0cPMqwDG7c2ibgktMSE=";
    };

    postInstall = ''
      wrapProgram $out/share/swtpm/swtpm-localca --prefix PATH : ${prev.lib.makeBinPath [ prev.gnutls ]}
    '';
  });
  factorio = prev.factorio.overrideAttrs(o: rec {
    version = "1.1.36";
    name = "factorio-${version}";
    src = prev.fetchurl {
      url = "http://localhost";
      name = "factorio_alpha_x64_1.1.36.tar.xz";
      sha256 = "sha256-iPPHSYCGo4g1UY6pCgi+wEtIQF9sodcp5gqvbzYVKvU=";
    };
  });
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

  git-credential-keepassxc = prev.rustPlatform.buildRustPackage rec {
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

  swayidle = prev.swayidle.overrideAttrs(o: {
    pname = "swayidle";
    version = "1.8";
    src = prev.fetchFromGitHub {
      owner = "swaywm";
      repo = "swayidle";
      rev = "0467c1e03a5780ed8e3ba611f099a838822ab550";
      sha256 = "sha256-5hUBJhc2PWzMv5gXc6SayDTZJVAFrXAYAqNaWETRfoc=";
    };
  });

  linuxPackagesOverride = linuxPackages:
    linuxPackages.extend (lfinal: lprev: {
      corefreq =
      let kernel = lprev.kernel;
      in final.stdenv.mkDerivation rec {
        pname = "corefreq";
        version = "develop";

        passthru.moduleName = "corefreqk";

        nativeBuildInputs = [ kernel.moduleBuildDependencies ];

        makeFlags = [
          "KERNELDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
          "INSTALL_MOD_PATH=$(out)"
          "PREFIX=$(out)"
          "UI_TRANSPARENCY=1"
        ];

        src = final.fetchFromGitHub {
          owner = "cyring";
          repo = pname;
          rev = "8d81912c5bc63112dc321157f9d23301731086b7";
          hash = "sha256-HSFGBEmMhP5vUv8dnI14WXRjcfb8KhMcKp2sQXJNcp8=";
        };
      };
    });
})
