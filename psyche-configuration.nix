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
  };

  users.users.root.openssh.authorizedKeys.keys =
    let ssh-keys-for = (import ../keys/ssh-keys.nix { inherit lib; });
    in ssh-keys-for config.networking.hostName;

  services.nginx.enable = true;
  services.nginx.recommendedProxySettings = true;
  services.nginx.virtualHosts."psyche.${networking.domain}" = {
    addSSL = true;
    enableACME = true;
  };

  services.nginx.virtualHosts."leroy.${networking.domain}" = {
    enableACME = true;
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
  };

  services.jenkins = {
    enable = true;
  };

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  services.qemuGuest.enable = true;
  system.stateVersion = "20.09";
}
