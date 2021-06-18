# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, pkgs, config, ... }:
let
  unstable = pkgs.unstable;
in {
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "it87" "coretemp" "nct6683" "i2c-dev" ];
  boot.extraModprobeConfig = ''
  options nct6683 force=1
'';
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xffffffff" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.cleanTmpDir = true;
  boot.initrd.verbose = false;

  powerManagement.cpuFreqGovernor = "schedutil";
  boot.supportedFilesystems = [ "ntfs" ];
  boot.kernelPackages = pkgs.linuxPackagesOverride unstable.linuxPackages_5_12;

  networking.hostName = "navi";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp38s0.useDHCP = true;
  #networking.interfaces.wlp37s0.useDHCP = true;
  #networking.wireless.iwd.enable = true;
  networking.useNetworkd = true;

  services.emacs.package = pkgs.emacsPgtkGcc;
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

  systemd.packages = [ pkgs.hawck ];
  services.udev.packages = [ pkgs.hawck ];
  systemd.services."hawck-inputd" = {
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
  };
  users.groups = {
    hawck-input-share = {};
    hawck-input = {};
    uinput = {};
  };
  users.users.hawck-input = {
    home = "/var/lib/hawck-input";
    extraGroups = [ "uinput" "input" "hawck-input" "hawck-input-share" ];
    isSystemUser = true;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/hawck-input/ 770 hawck-input hawck-input-share"
    "d /var/lib/hawck-input/keys 750 hawck-input hawck-input-share"
  ];

  services.ratbagd.enable = true;
  programs.steam.enable = true;
  programs.steam.remotePlay.openFirewall = true;

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      rocm-opencl-icd
      rocm-opencl-runtime
    ];
  };

  # hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.unstable.firmwareLinuxNonfree ];
  hardware.bluetooth.enable = true;
  hardware.steam-hardware.enable = true;
  # hardware.pulseaudio.support32Bit = true;

  users.users.tny = {
     isNormalUser = true;
     extraGroups = [ "wheel" "hawck-input-share" ];
  };
  
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.contentAddressedByDefault = true;

  services.corefreq.enable = true;
  environment.systemPackages = with pkgs; [
    hawck
    rocminfo
    fahcontrol fahviewer
    manpages
    dmidecode efibootmgr
    firefox-wayland vim alacritty lm_sensors
    vulkan-tools
    openssl
    adoptopenjdk-bin git
    mullvad-vpn
  ];


  programs.adb.enable = true;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  networking.wireguard.enable = true;
  services.mullvad-vpn.enable = true;
  networking.iproute2.enable = lib.mkForce false;
  networking.firewall.checkReversePath = "loose";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;

  services.earlyoom.enable = true;

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 54875 54941 8080 27036 27037 ];
  networking.firewall.allowedUDPPorts = [ 54875 54941 27031 27036 ];

  documentation.man.enable = true;
  documentation.dev.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
}

