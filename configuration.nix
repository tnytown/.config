# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:
{
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [
    "it87"
    "coretemp"
    "nct6683"
    "i2c-dev"

    # vfio: load kmods
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
    "vfio_virqfd"
  ];

  # TODO(tny):
  # https://github.com/torvalds/linux/blob/master/arch/x86/kvm/svm/svm.c#L203
  # https://patchwork.kernel.org/project/kvm/cover/20210513113710.1740398-1-vkuznets@redhat.com/
  boot.extraModprobeConfig = ''
    options nct6683 force=1
    options kvm_amd avic=1
  '';
 
  boot.initrd.kernelModules = [ "amdgpu" "i2c_algo_bit" "i2c_core" "i2c_designware_core" "i2c_designware_pci" ];
  boot.cleanTmpDir = true;
  boot.initrd.verbose = false;

  powerManagement.cpuFreqGovernor = "performance";
  boot.supportedFilesystems = [ "ntfs" "zfs" ];
  boot.kernelPatches = [
    /*{
      name = "nested_AVIC";
      patch = builtins.fetchurl {
        url = "https://patchwork.kernel.org/series/619279/mbox/";
        sha256 = "sha256:0di0ivpwdpmgzgxryd4kf3mf27g38d6x74qr1a5rxm7a19anw6gh";
      };
    }*/
  ];

  boot.kernelPackages = pkgs.linuxPackagesOverride pkgs.linuxKernel.packages.linux_6_1; #pkgs.linuxKernel.packages.latest;
  /*
    boot.kernelPackages = pkgs.linuxPackagesOverride (pkgs.linuxPackagesFor (pkgs.linux_testing.override {
    argsOverride = rec {
      src = pkgs.fetchurl {
        url = "https://git.kernel.org/torvalds/t/linux-5.14-rc7.tar.gz";
        sha256 = "sha256-zeHvEipSGZ3Db9oLoRJ9u7k2wWhwJO9iCdHwaN4mdOA=";
      };
      ignoreConfigErrors = true;
      version = "5.14-rc7";
      modDirVersion = "5.14.0-rc7";
    };
  }));*/

  networking.hostName = "navi";
  networking.hostId = "c6229378";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  # networking.interfaces.enp38s0.useDHCP = true;
  #networking.interfaces.wlp37s0.useDHCP = true;
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General.EnableNetworkConfiguration = false;
    };
  };
  networking.useNetworkd = true;

  systemd.network.networks."10-wlan0-selfmanaged" = {
    name = "wlan0";
    DHCP = "ipv4";
    networkConfig = {
      IPv6AcceptRA = "yes";
      LinkLocalAddressing = "yes";
    };
    # linkConfig.Unmanaged = "yes";
  };
  /*systemd.network.links."90-wlan0-selfmanaged" = {
    linkConfig.Unmanaged = "yes";
    matchConfig.Name = "wlan0";
  };*/

  services.resolved.dnssec = "false";

  services.emacs.package = pkgs.emacsPgtk;
  services.emacs.enable = true;
  services.hostapd = {
    enable = false;
    wpa = true;
    interface = "wlan0";
    countryCode = "US";
    hwMode = "a";
    channel = 36;
    extraConfig = ''
      wpa_pairwise=CCMP
      ieee80211n=1
      ieee80211ac=1
      require_ht=1
      require_vht=1
      #vht_oper_chwidth=1
      #vht_oper_centr_freq_seg0_idx=42
      logger_stdout=-1
      logger_stdout_level=0
    '';
    wpaPassphrase = "EEEEEEEEEE";
  };

  programs.dconf.enable = true;

  services.printing = {
    enable = true;
    drivers = [
      pkgs.canon-cups-ufr2
      /*(let stdenv = pkgs.pkgsi686Linux.stdenv;
           i686_NIX_GCC = pkgs.pkgsi686Linux.callPackage ({gcc}: gcc) {}; in
       pkgs.canon-cups-ufr2.overrideAttrs(_: {
        propagatedBuildInputs = (_.propagatedBuildInputs or []) ++ [ stdenv.cc.cc.lib ];
        buildInputs = (_.buildInputs or []) ++ [ stdenv.cc.cc.lib ];
        installPhase = _.installPhase + ''
        patchelf --set-rpath "${stdenv.cc.cc.lib}/lib" $out/lib32/libcaepcm.so.1.0
      '';
      }))*/
    ];
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # services.foldingathome.enable = true;
  services.foldingathome.enable = false;

  services.avahi = {
    # https://discourse.nixos.org/t/avahi-for-printer-discovery-editing-nsswitch-conf/3254/4
    publish.enable = true;
    publish.workstation = true;

    enable = true;
    nssmdns = true;
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # systemd.packages = [ pkgs.hawck ];
  # services.udev.packages = [ pkgs.hawck ];
  /*systemd.services."hawck-inputd" = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = [
        ""
        "${pkgs.hawck}/bin/hawck-inputd --no-fork --kbd-device /dev/input/by-id/usb-Apple_Inc._Magic_Keyboard_F0T018204AQJ1XLAF-if01-event-kbd"
      ];
    };

    path = with pkgs; [ bash sway libnotify jq ];
    };
    systemd.user.services."hawck-macrod" = {
    wantedBy = [ "graphical-session.target" ];
    path = with pkgs; [ bash sway libnotify jq ];
  };*/

  users.groups = {
    hawck-input-share = { };
    hawck-input = { };
    uinput = { };
  };

  users.users.hawck-input = {
    group = "hawck-input";
    home = "/var/lib/hawck-input";
    extraGroups = [ "uinput" "input" "hawck-input-share" ];
    isSystemUser = true;
  };
  virtualisation.libvirtd.enable = true;
  /*virtualisation.libvirtd.package =
    let
      libvirtd = pkgs.writeScriptBin "libvirtd" ''
    export PATH=$PATH:${pkgs.swtpm}/bin/swtpm
    exec ${pkgs.libvirt}/bin/libvirtd $@
    '';
    in pkgs.symlinkJoin {
      name = "libvirt";
      paths = [
        libvirtd
        pkgs.libvirt
      ];
    };*/

  systemd.services.libvirtd.path = [ pkgs.swtpm-tpm2 ];

  systemd.tmpfiles.rules = [
    "d /var/lib/hawck-input/ 770 hawck-input hawck-input-share"
    "d /var/lib/hawck-input/keys 750 hawck-input hawck-input-share"
    "d /var/lib/xilinx 770 tny wheel"
  ];

  services.hardware.bolt.enable = true;
  services.ratbagd.enable = true;
  programs.steam.enable = true;
  programs.steam.remotePlay.openFirewall = true;

  hardware.opengl = {
    enable = true;
    setLdLibraryPath = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      rocm-opencl-icd
      rocm-opencl-runtime
    ];
  };

  # hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.firmwareLinuxNonfree ];
  hardware.bluetooth.enable = true;
  hardware.steam-hardware.enable = true;
  # hardware.pulseaudio.support32Bit = true;

  users.users.tny = {
    isNormalUser = true;
    extraGroups = [ "dialout" "wheel" "hawck-input-share" "libvirtd" "hledger" "audio" ];
  };

  nixpkgs.config.allowUnfree = true;

  services.corefreq.enable = true;
  environment.systemPackages = with pkgs; [
    # hawck
    rocminfo
    # fahcontrol
    # fahviewer
    man-pages
    dmidecode
    efibootmgr
    firefox-wayland
    vim
    alacritty
    lm_sensors
    vulkan-tools
    openssl
    adoptopenjdk-bin
    git
    mullvad-vpn

    qemu
    OVMFFull
    swtpm-tpm2
    tpm2-tools
    virt-manager

    sbctl
  ];

  programs.adb.enable = true;
  programs.mtr.enable = true;
  networking.wireguard.enable = true;
  services.mullvad-vpn.enable = true;
  services.tailscale.enable = true;
  networking.iproute2.enable = lib.mkForce false;
  networking.firewall.checkReversePath = "loose";

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark-qt;
  };

  # Enable
  services.hledger-web = {
    enable = true;
    capabilities = {
      view = true;
      manage = true;
      add = true;
    };
  };


  location.provider = "geoclue2";
  services.geoclue2.enable = true;

  services.earlyoom.enable = true;
  # networking.
  documentation.man.enable = true;
  documentation.dev.enable = true;

  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  services.openssh.openFirewall = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}
