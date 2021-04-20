#!/usr/bin/env bash

set -e
set -u
set -o pipefail
set -x

dir=$(dirname "$0")

# Install packages
pacman --noconfirm -S \
    dmenu \
    i3-wm \
    i3status \
    noto-fonts \
    sudo \
    termite \
    vim

# Overlay the contents of tree on the root filesystem
mkdir -p "$dir/tree"
cp -RT "$dir/tree" /
