(final: prev: rec {
  a52dec = prev.a52dec.overrideAttrs (o: rec {
    src = prev.fetchurl {
      url = "${meta.homepage}/files/${o.pname}-${o.version}.tar.gz";
      sha256 = "oh1ySrOzkzMwGUNTaH34LEdbXfuZdRPu9MJd5shl7DM=";
    };
    meta = o.meta // {
      homepage = "https://liba52.sourceforge.io/";
    };
  });

  SDL_image = prev.SDL_image.overrideAttrs (_: {
    patches = [
      (prev.fetchpatch {
        name = "CVE-2017-2887";
        url = "https://github.com/libsdl-org/SDL_image/commit/e7723676825cd2b2ffef3316ec1879d7726618f2.diff";
        sha256 = "sha256-Z0nyEtE1LNGsGsN9SFG8ZyPDdunmvg81tUnEkrJQk5w=";
        includes = [ "IMG_xcf.c" ];
      })
    ];
  });

  openjdk8 = with prev; prev.openjdk8.overrideAttrs (o: {
    srcs =
      let
        sr = d: h: d.overrideAttrs (o_: { outputHash = h; });
        sro = n: h: sr (builtins.elemAt o.srcs n) h;
        jdk = builtins.elemAt o.srcs 0;
        corba = builtins.elemAt o.srcs 3;
      in
      [
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

  SDL = with prev; prev.SDL.overrideAttrs (o: {
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

  mercurial = prev.mercurial.overrideAttrs (o: {
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
})
