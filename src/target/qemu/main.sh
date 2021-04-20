#!/usr/bin/env bash

set -e
set -u
set -o pipefail
set -x

dir=$(dirname "$0")

# Install packages specific to this target
pacman --noconfirm -S \
    xorg-server \
    xorg-xinit \
    mesa

# Overlay the contents of tree on the root filesystem
mkdir -p "$dir/tree"
cp -RT "$dir/tree" /

# Append additional filesystems to fstab
cat "$dir/fstab.append" >> /etc/fstab
