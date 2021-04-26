{ lib, pkgs, config, ... }:
with lib;
let cfg = config.services.de;
in {
  options.services.de = {
    enable = lib.mkEnableOption "desktop environment (sway)";
    #package = lib.mkOption {
    #  default = config.boot.kernelPackages.corefreq;
    #  type = lib.types.package;
    #};
  };

  # https://github.com/swaywm/sway/wiki/Systemd-integration
  config = mkIf cfg.enable {
    systemd.user.targets.sway-session = {
      description = "sway compositor session";
      documentation = "man:systemd.special(7)";
      wants = "graphical-session-pre.target";
      after = "graphical-session-pre.target";
      bindsTo = "graphical-session.target";
    };
    programs.sway.enable = true;
  };
}
