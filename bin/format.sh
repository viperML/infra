#!/usr/bin/env bash
set -eux -o pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root for mount permissions!"
    exit 0
fi

MYDISK="/dev/sda"
zpool export -a
umount -R /mnt || :

sgdisk --zap-all "${MYDISK}"
sgdisk -a1 -n1:2048:4095 -t1:EF02 "${MYDISK}"
sgdisk -a1 -n2:0:300M    -t2:8300 "${MYDISK}"
sgdisk     -n3:0:0       -t3:8300 "${MYDISK}"

partprobe "${MYDISK}"
wipefs -a "${MYDISK}1"
wipefs -a "${MYDISK}2"

mkfs.ext4 -F -L BOOT "${MYDISK}2"

zpool create \
    -o ashift=12 \
    -o autotrim=on \
    -O acltype=posixacl \
    -O compression=zstd \
    -O dnodesize=auto \
    -O normalization=formD \
    -O relatime=on \
    -O atime=off \
    -O xattr=sa \
    -O mountpoint=none \
    -R /mnt \
    -f zroot "${MYDISK}3"

zfs create -o mountpoint=legacy zroot/rootfs
zfs create -o mountpoint=legacy zroot/nix

mkdir -p /mnt
mount -t zfs zroot/rootfs   /mnt
mkdir -p /mnt/{boot,nix}
mount "${MYDISK}2" /mnt/boot
mount -t zfs zroot/nix      /mnt/nix
