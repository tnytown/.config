{ pkgs, config, ... }:
let unstable = pkgs.unstable; in {

      networking.hostName = "psyche";
      networking.domain = "tny.town";
}
