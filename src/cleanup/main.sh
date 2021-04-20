#!/usr/bin/env bash

set -e
set -u
set -o pipefail
set -x

dir=$(dirname "$0")

# Restore the original pacman mirrror list
cp /etc/pacman.d/mirrorlist.backup /mnt/etc/pacman.d/mirrorlist

# Clean up the pacman cache
rm -rf /mnt/var/cache/pacman/pkg

# Unmount filesystems
umount /mnt/efi
umount /mnt
