#!/usr/bin/env nix-shell
#!nix-shell -i bash -p pciutils swtpm

guest_is_on() {
    ! virsh dominfo trampoline | grep -i 'shut off' >/dev/null
}

configroot=`dirname $0`

# extract bdkey from sops
export SOPS_AGE_KEY_FILE="$configroot/../.config/sops/age/keys.txt"
bdkey=`sops -d --extract '["bdkey"]' $configroot/secrets.yaml`
[[ -z "$bdkey" ]] && exit 1

[[ $(id -u) -ne 0 ]] && {
    echo "run me as root"
    exit -1
}

$configroot/dmsetup.sh

echo "[-] dm device setup"

# https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Setting_up_the_guest_OS

for x in vfio_pci vfio vfio_iommu_type1 vfio_virqfd; do
    modprobe $x
done

gpudevs=$(lspci |
              grep 'AMD/ATI' | grep -v '^PCI bridge' |
              sed -E 's/^([^ ]+).*/\1/; s/^/pci_0000_/; s/:/_/g; s/\./_/g;')
echo $gpudevs

# point of no return
echo "[-] graphical linux shutdown"
systemctl isolate multi-user.target

# TODO(tny): may be necessary on other machines? uncomment if needed
#echo 0 > /sys/class/vtconsole/vtcon0/bind
#echo 0 > /sys/class/vtconsole/vtcon1/bind
#echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

# modprobe -r amdgpu
# modprobe -r snd_hda_intel

# TODO(tny): paranoia, these devices are in managed mode and should be detached auto
for x in $gpudevs; do virsh nodedev-detach $x; done

virsh start trampoline

# wait for bitlocker ...
sleep 10

if guest_is_on; then
    echo -n "$bdkey" | while read -n1 char; do
        virsh send-key trampoline "KEY_$char"
    done
    virsh send-key trampoline 'KEY_ENTER'
else
    echo 'was not able to type bitlocker key, shrug'
fi

while guest_is_on; do
    sleep 2
done

for x in $gpudevs; do virsh nodedev-reattach $x; done

# TODO(tny): amdgpu should already be up, otherwise modprobe amdgpu

systemctl isolate graphical.target

echo "[-] hello world!"
# and we're back up
