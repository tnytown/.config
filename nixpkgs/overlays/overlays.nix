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

    cargoSha256 = "1ghag2v6nsf7qnh0i2mjzm0hkij65i7mnbb297mdsprc6i8mn3xn";

    meta = with prev.stdenv.lib; {
      description = "Helper that allows Git (and shell scripts) to use KeePassXC as credential store";
      homepage = "https://github.com/Frederick888/git-credential-keepassxc";
      license = licenses.gpl3Only;
      maintainers = [ "tny" ];
    };

    doCheck = false;
  };

  discord = prev.discord.overrideAttrs(_: rec {
    version = "0.0.13";
    src = prev.fetchurl {
      url = "https://dl.discordapp.net/apps/linux/${version}/discord-${version}.tar.gz";
      sha256 = "0d5z6cbj9dg3hjw84pyg75f8dwdvi2mqxb9ic8dfqzk064ssiv7y";
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
  mesa = prev.unstable.mesa;
})
