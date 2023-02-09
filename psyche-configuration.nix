{ config, lib, pkgs, modulesPath, ... }:
let unstable = pkgs.unstable;
in rec {
  imports = [
    ("${modulesPath}/profiles/qemu-guest.nix")
  ];
  networking.hostName = "psyche";
  networking.domain = "tny.town";

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    challengeResponseAuthentication = false;

    extraConfig = ''
      Match Group optum
        PasswordAuthentication yes
        ChrootDirectory /var/lib/www/
        ForceCommand internal-sftp
        AllowTcpForwarding no
        PermitTunnel no
        X11Forwarding no
      Match all
    '';
  };
  security.pam.services.sshd.unixAuth = pkgs.lib.mkForce true;


  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys =
    let ssh-keys-for = (import ./keys/ssh-keys.nix { inherit lib; });
    in ssh-keys-for config.networking.hostName;

  users.users.optum = {
    isNormalUser = true;
    group = "optum";
    hashedPassword = "$6$A532WAyvez3IWP3Z$j59soW5NBOTfeh2KklXTQ1x1sSkh4so9ENWsr.xtEMeA5aFoRetiXCg1wKqh2uezMTIGt.2AmPfpnW5pt9EPC/";
  };
  users.groups.optum = {};

  systemd.tmpfiles.rules = [
    "d  /var/lib/www/       751 root  nginx"
    "d  /var/lib/www/optum/ 770 optum nginx"
    "A /var/lib/www/optum/ -   -     -      - d:u:nginx:r-x,d:g:nginx:r-x"
  ];

  users.users.optum.home = "/var/lib/www/optum";

  services.nginx.enable = true;
  services.nginx.recommendedProxySettings = true;
  services.nginx.virtualHosts."psyche.${networking.domain}" = {
    default = true;
    sslCertificate = "/var/lib/acme/tny.town/fullchain.pem";
    sslCertificateKey = "/var/lib/acme/tny.town/key.pem";
    forceSSL = true;

    locations."/" = {
      alias = "/var/lib/www/";
      extraConfig = ''try_files /var/lib/www/index.html =404;'';
    };

    locations."/f/" = {
      alias = "/var/lib/www/files/";
      extraConfig = ''try_files $uri $uri/ =403;'';
    };

    locations."/ph0t0s2021/" = {
      alias = "/var/lib/www/content/";
      extraConfig = ''
                autoindex on;
                autoindex_format xml;
                xslt_string_param title $1;
                xslt_stylesheet ${pkgs.writeText "imgb.xslt" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
        <xsl:output method="html" encoding="utf-8" indent="yes" />
        <xsl:template match="/">
            <xsl:text disable-output-escaping='yes'>&lt;!DOCTYPE html&gt;</xsl:text>
            <html>
            <head>
                <title><xsl:value-of select="$title" /></title>
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                <style>
                img, video {
                    display: block;
                    max-width: 20cm;
                    max-height: 20cm;
                    margin: 2mm;
                    vertical-align: bottom;
                    image-orientation: from-image;
                }
                @media all and (max-width: 20.4cm) {
                    img {
                        max-width: calc(100% - 4mm);
                    }
                }
                body {
                    margin: 0;
                }
                </style>
            </head>
            <body>
                <xsl:for-each select="list/file">
                    <xsl:choose>
                        <xsl:when test="contains(' mp4 webm mkv avi wmv flv ogv ', concat(' ', substring-after(., '.'), ' '))">
                            <video controls="" src="{.}" alt="{.}" title="{.}"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <img src="{.}" alt="{.}" title="{.}"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </body>
            </html>
        </xsl:template>
        </xsl:stylesheet>
                ''};
                try_files $uri $uri/ =403;
      '';
    };
  };

  services.nginx.virtualHosts."optum.${networking.domain}" = {
    sslCertificate = "/var/lib/acme/tny.town/fullchain.pem";
    sslCertificateKey = "/var/lib/acme/tny.town/key.pem";
    forceSSL = true;

    root = "/var/lib/www/optum";
  };

  services.nginx.virtualHosts."leroy.${networking.domain}" = {
    sslCertificate = "/var/lib/acme/tny.town/fullchain.pem";
    sslCertificateKey = "/var/lib/acme/tny.town/key.pem";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_redirect http://localhost:8080 https://leroy.${networking.domain};
      '';
    };
  };

  security.acme = {
    email = "letsencrypt@unown.me";
    acceptTerms = true;

    certs."tny.town" = {
      domain = "*.tny.town";
      dnsProvider = "cloudflare";
      group = config.systemd.services.nginx.serviceConfig.Group;
      credentialsFile = config.sops.secrets.cf-tnytown.path;
    };
  };

  sops.secrets.cf-tnytown = {
    owner = config.systemd.services."acme-tny.town".serviceConfig.User;
  };

  services.jenkins = {
    enable = true;
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  services.qemuGuest.enable = true;
  system.stateVersion = "20.09";
}
