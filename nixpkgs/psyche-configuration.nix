{ pkgs, config, modulesPath, ... }:
let unstable = pkgs.unstable; in {
      imports = [
        ("${modulesPath}/profiles/qemu-guest.nix")
      ];
      networking.hostName = "psyche";
      networking.domain = "tny.town";

      services.openssh = {
        enable = true;
        passwordAuthentication = false;
      };

      users.users.root.openssh.authorizedKeys.keys = [
        ''ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCS/DKxeOOpS6em6KriJLB2yTw/EWYtLFof8vmBoSxqSZz0Ub9/YfOf9itZXa6vlqt1dhYOK0au202PXKwmpC6Yb/nNQRopvshk2ZmV7ktEm5d+jFlV9Px+cqjH3fNYN4X0GEJG+UWdXknx6vg9I5LJZIf2NQioP3ST6zAzgavQx8JZ22Q1xqjBKAodtKrkaWYABp/yaPS0EIzQsbVEmMnOBLvCwvHPLt2jG+Pw/yoqVM40v5m/KSCUq9YDzhvdlQcR/aClXGg0LelUbF1Sc2lBwNoR+QDchPJAQB6j5OcqtsRjToBPKIQr/INeu7WWEJto/WIClsVph4zyo3zPoNqjvBNHvWSzEIR2Pu5b+KBhrqgnGm9IBz0w07r+1NIzS7vG8CGAuvrsPyA3o9airU4Ug1ex9fxUy0vdIinFPu9CNPiE4jYniQzn57MzkmMM4LxE8p+8RRTimLWSuhX3LqLfE1zoTITMWP1jDvPyfcpbp/Dv/51jsZRoHZbf1pmJCTcmFlISWuwfbRT6nA9f2est/m537bWDXnlZJc/14ZIX7IiUHXBPhN1UWtBkIxjQaK7p8d/PG9R2iIb+hik/J6f5TlukxBF8s72uLuvWQYOcaUioQWMPgzvOt8NVNuRFuFuiY2FHAm1dwlKGlAXKgqzrgqkiJ6uvNBH3HUu6LUVlw== tny@navi
''
      ];

      services.qemuGuest.enable = true;
      system.stateVersion = "20.09";
}
