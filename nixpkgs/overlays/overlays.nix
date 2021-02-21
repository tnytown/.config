(final: prev: {
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
})
