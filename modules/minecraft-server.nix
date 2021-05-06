{ lib, pkgs, config, ... }:
let unstable = pkgs.unstable;
in {
  services.minecraft-server = {
    enable = true;
    eula = true;
    package = (unstable.papermc.override { jre = pkgs.jdk11; });
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
}
