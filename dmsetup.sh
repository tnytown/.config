#!/usr/bin/env bash

set -euf -o pipefail

sct() {
    echo $(( $1 / 512 ))
}

# cleanup previously mapped device if exists
dmname='trampoline'
[[ -e "/dev/mapper/$dmname" ]] && dmsetup remove $dmname

# YOLO
[[ -e /dev/loop0p1 ]] && losetup -d /dev/loop0
losetup /dev/loop1 && losetup -d /dev/loop1

# getting block devices in order
boot=$(losetup -P -f --show winboot.img)
win1=/dev/nvme0n1p3 # windows main part
win2=/dev/nvme0n1p4 # windows recovery
shdr=$(losetup -P -f --show winpart.img)

boot_sz=$(blockdev --getsz $boot)
win1_sz=$(blockdev --getsz $win1)
win2_sz=$(blockdev --getsz $win2)
shdr_sz=$(blockdev --getsz $shdr)

win2_of=$(( $boot_sz + $win1_sz ))

# logical_start_sector num_sectors linear destination_device start_sector

# example table:
# 0 $size1 linear $1 0
# $size1 $size2 linear $2 0

# TODO(tny): why is start_sector 0?
cat <<EOF | dmsetup create $dmname
0 $boot_sz linear $boot 0
$boot_sz $win1_sz linear $win1 0
$win2_of $win2_sz linear $win2 0
$(( $win2_of + $win2_sz )) $shdr_sz linear $shdr 0
EOF

echo "Total size:" $(( $boot_sz + $win1_sz + $win2_sz ))

offs=0
n=0
for part_sz in $boot_sz $win1_sz $win2_sz $shdr_sz; do
    echo -e "$n\t$offs +$part_sz"
    offs=$(( $offs + $part_sz ))
    n=$(( $n + 1 ))
done
