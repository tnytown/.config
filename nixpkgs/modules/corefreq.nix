{ lib, pkgs, config, ... }:
let cfg = config.services.corefreq;
in {
  options.services.corefreq = {
    enable = lib.mkEnableOption "corefreqd";
    package = lib.mkOption {
      default = config.boot.kernelPackages.corefreq;
      type = lib.types.package;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.corefreqd = {
      wantedBy = [ "multi-user.target" ];
      description = "CoreFreq Daemon";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/corefreqd -q";
        KillSignal = "SIGQUIT";
        RemainAfterExit = false;
        SuccessExitStatus = [ "SIGQUIT" "SIGUSR1" "SIGTERM" ];
      };
    };

    boot.kernelModules = [ cfg.package.moduleName ];
    boot.extraModulePackages = [ cfg.package ];

    environment.systemPackages = [ cfg.package ];
  };
}
