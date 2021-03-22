# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, config, ... }:
let
  unstable = pkgs.unstable;
in {
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
    experimental-features = nix-command flakes
'';

    # nixPath = [ "nixpkgs=/home/tny/.config/nixpkgs" ];
  };

  fonts = {
    fonts = [
      pkgs.meslo-lg
      pkgs.noto-fonts-cjk
      pkgs.noto-fonts-emoji
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = pkgs.lib.mkForce [ "Meslo LG S" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
      };
    };
  };
  
  imports =
    [
      # Include the results of the hardware scan.
      ./machines/navi.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "it87" "coretemp" "nct6683" "i2c-dev" config.boot.kernelPackages.corefreq.moduleName ];
  boot.extraModulePackages = [ config.boot.kernelPackages.corefreq ];
  boot.extraModprobeConfig = ''
  options nct6683 force=1
'';

  powerManagement.cpuFreqGovernor = "schedutil";
  boot.supportedFilesystems = [ "ntfs" ];
  boot.kernelPackages = pkgs.linuxPackagesOverride unstable.linuxPackages_5_11;

  networking.hostName = "navi";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  #networking.interfaces.enp38s0.useDHCP = true;
  #networking.interfaces.wlp37s0.useDHCP = true;
  networking.wireless.iwd.enable = true;
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  programs.dconf.enable = true;

  services.printing = {
    enable = true;
    drivers = [
      #pkgs.canon-cups-ufr2      
      (let stdenv = pkgs.pkgsi686Linux.stdenv;
           i686_NIX_GCC = pkgs.pkgsi686Linux.callPackage ({gcc}: gcc) {}; in
       pkgs.canon-cups-ufr2.overrideAttrs(_: {
        propagatedBuildInputs = (_.propagatedBuildInputs or []) ++ [ stdenv.cc.cc.lib ];
        buildInputs = (_.buildInputs or []) ++ [ stdenv.cc.cc.lib ];
        installPhase = _.installPhase + ''
        patchelf --set-rpath "${stdenv.cc.cc.lib}/lib" $out/lib32/libcaepcm.so.1.0
'';
      }))
    ];
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

  services.avahi = {
    # https://discourse.nixos.org/t/avahi-for-printer-discovery-editing-nsswitch-conf/3254/4
    publish.enable = true;
    publish.workstation = true;
    
    enable = true;
    nssmdns = true;
  };

  services.minecraft-server = {
    enable = true;
    eula = true;
    package = unstable.papermc;
    declarative = true;

    jvmOpts = "-Xms4G -Xmx4G " +
	"-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true";
    
    openFirewall = true;
    serverProperties = {
	    motd = "speedy's omnipotent toilet";
      white-list = true;
	    difficulty = "normal";
      allow-flight = true;
    };

    whitelist = {
      ipatapus = "78b19f17-994a-4941-a3c4-e6c164dc2c5b";
      knownunown = "6357533f-0aa3-437f-bf2b-30847d6c8259";
      snuwy = "d84e9dff-8320-43d6-be21-edb556af51d0";
      ludicroussponge = "3dbc71a8-8c5f-46fd-8cda-6b23cc4188c2";
      arctyx = "288e3942-581b-4b22-9adb-295ec37eb78c";
      powersurge26 = "9928fe4e-4a0a-448d-9833-f7fb944837a3";
    };
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Enable the GNOME 3 Desktop Environment.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.wacom.enable = true;
  services.xserver.xrandrHeads = [
    "DFP-4"
    { output = "HDMI-0"; monitorConfig = ''Option "ignore" "true"''; }
  ];
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    package = pkgs.unstable.mesa.drivers;
    package32 = pkgs.unstable.pkgsi686Linux.mesa.drivers;
  };

  # hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.unstable.firmwareLinuxNonfree ];
  hardware.steam-hardware.enable = true;
  # hardware.pulseaudio.support32Bit = true;

  users.users.tny = {
     isNormalUser = true;
     extraGroups = [ "wheel" ];
  };
  
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    manpages
    dmidecode efibootmgr
    unstable.firefox vim alacritty lm_sensors
    vulkan-tools
    openssl
    config.boot.kernelPackages.corefreq
  ];

  systemd.services.corefreqd = {
    wantedBy = [ "multi-user.target" ];
    description = "CoreFreq Daemon";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${config.boot.kernelPackages.corefreq}/bin/corefreqd -q";
      KillSignal = "SIGQUIT";
      RemainAfterExit = false;
      SuccessExitStatus = [ "SIGQUIT" "SIGUSR1" "SIGTERM" ];
    };
  };

  #systemd.packages = [
  #config.boot.kernelPackages.corefreq
  #];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  networking.wireguard.enable = true;
  services.mullvad-vpn.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 54875 54941 8080 ];
  networking.firewall.allowedUDPPorts = [ 54875 54941 ];

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

