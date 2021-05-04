{ pkgs, lib, config, ... }:
{
  sops.useAge = true;
  sops.sshKeyPaths = [];
  # sops.ageKeyFile = "";
  sops.gnupgHome = null;
  sops.defaultSopsFile = ../secrets.yaml;
}
