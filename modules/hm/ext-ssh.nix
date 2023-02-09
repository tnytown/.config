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
      "*.acm" = {
        user = "pan00111";
        hostname = "%h.umn.edu";
      };
      "argo.acm" = {
        user = "andrew";
      };
      "*.cselabs" = {
        user = "pan00111";
        hostname = "csel-%h.umn.edu";
      };
    };
    controlMaster = "auto";
    controlPersist = "10m";
  };
}
