{ config, lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "shiny.unown.me".user = "root";
      "navi-ext" = {
        user = "tny";
        hostname = "navi.lan";
        proxyJump = "shiny.unown.me";
      };
    };
  };
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "navi-ext";
      maxJobs = 2;
    }
  ];
}
