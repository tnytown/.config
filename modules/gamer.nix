{ lib, pkgs, config, ... }: {
  environment.systemPackages = with pkgs; [ qemu OVMF virt-manager ];
  virtualisation.libvirtd.enable = true;
}
