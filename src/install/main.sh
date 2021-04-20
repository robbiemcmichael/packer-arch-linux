#!/usr/bin/env bash

set -e
set -u
set -o pipefail
set -x

dir=$(dirname "$0")

# Create partitions
parted /dev/vda mklabel gpt
parted /dev/vda mkpart bios fat32 1MiB     2MiB
parted /dev/vda mkpart esp  fat32 2MiB   262MiB
parted /dev/vda mkpart root ext4  262MiB   100%
parted /dev/vda set 1 bios_grub on
parted /dev/vda set 2 esp on
parted /dev/vda print all

# Format partitions
mkfs.vfat -F 32 -n ESP /dev/vda2
mkfs.ext4 -L ROOT /dev/vda3

# Mount the root filesystem
mount /dev/vda3 /mnt

# Mount the EFI system partition
mkdir /mnt/efi
mount /dev/vda2 /mnt/efi

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

if [ -n "$PACKER_PACMAN_PORT" ]; then
    # Use a caching proxy on the host machine when fetching packages
    systemctl stop reflector.service
    echo "Server = http://$PACKER_HTTP_IP:$PACKER_PACMAN_PORT/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
fi

# Install Arch Linux on the root filesystem
t0=$(date +%s)
pacstrap /mnt base linux linux-firmware
t1=$(date +%s)
echo "pacstrap took $(( t1 - t0 )) seconds"

# Generate /etc/fstab from currently mounted filesystems
genfstab -U /mnt >> /mnt/etc/fstab

# Create symlink for /etc/resolv.conf as it is not possible inside arch-chroot
ln -sf /run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
