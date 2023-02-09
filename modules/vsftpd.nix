{ config, pkgs, ... }:
let
  name = "vsftpd";
  user = "vsftpd";
  path = "/var/lib/vsftpd";
in
{
  systemd.tmpfiles.rules = [
    "d /var/lib/vsftpd/ 751 ${user} ${user}"
  ];

  services.vsftpd = {
    enable = true;
    #forceLocalLoginsSSL = true;
    #forceLocalDataSSL = true;
    userlistEnable = true;
    userlistDeny = false;
    localUsers = true;
    userlist = [ "optum" ];
    # rsaCertFile = "/var/lib/vsftpd/cert.pem";
    # rsaKeyFile = "/var/lib/vsftpd/key.pem";
    rsaCertFile = "/var/lib/acme/tny.town/fullchain.pem";
    rsaKeyFile = "/var/lib/acme/tny.town/key.pem";

    #ssl_tlsv1 = true;

    allowWriteableChroot = true;
    chrootlocalUser = true;
    writeEnable = true;

    extraConfig = ''
      ssl_ciphers=HIGH
      pasv_enable=YES
      pasv_min_port=51000
      pasv_max_port=51999
    '';
  };

  systemd.services."create-${name}-cert" = {
    description = "Create a certificate for ${name}";

    script = ''
      ${pkgs.libressl}/bin/openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes -subj '/CN=localhost'
      chmod 644 cert.pem
      chmod 640 key.pem
    '';

    wantedBy = [ "vsftpd.service" ];

    unitConfig = {
      Before = [ "vsftpd.service" ];
      ConditionPathExists = "!${path}/cert.pem";
    };

    serviceConfig = {
      User = user;
      Type = "oneshot";
      WorkingDirectory = path;
      RemainAfterExit = true;
    };
  };

  systemd.timers."create-${name}-cert" = {
    timerConfig = {
      OnCalendar = "yearly";
    };
    wantedBy = [ "timers.target" ];
  };

  networking.firewall.connectionTrackingModules = [ "ftp" ];
  networking.firewall.allowedTCPPorts = [ 21 990 ];
  networking.firewall.allowedTCPPortRanges = [{ from = 51000; to = 51999; }];
}
