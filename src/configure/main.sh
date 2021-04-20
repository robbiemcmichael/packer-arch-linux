#!/usr/bin/env bash

set -e
set -u
set -o pipefail
set -x

dir=$(dirname "$0")

hostname=${PACKER_HOSTNAME}
user=${PACKER_USER}
tmp_password=${PACKER_TMP_PASSWORD}
time_zone=${PACKER_TIME_ZONE}
lang=${PACKER_LANG}
locale=${PACKER_LOCALE}
keymap=${PACKER_KEYMAP}

# Set the hostname for the machine
echo "$hostname" > /etc/hostname

# Set a temporary password for the root user
echo "root:$tmp_password" | chpasswd

# Set the time zone and set the hardware clock to UTC
ln -sf "/usr/share/zoneinfo/$time_zone" /etc/localtime
hwclock --systohc

# Set the locale and generate locales
echo "LANG=$lang" > /etc/locale.conf
echo "$locale" > /etc/locale.gen
locale-gen

# Set the keymap for the virtual console
echo "KEYMAP=$keymap" > /etc/vconsole.conf

# Add entries for localhost to /etc/hosts
echo '127.0.0.1    localhost' >> /etc/hosts
echo '::1          localhost ip6-localhost ip6-loopback' >> /etc/hosts

# Sensible set of packages for a minimal installation
pacman --noconfirm -S \
    arch-install-scripts \
    efibootmgr \
    gptfdisk \
    grub \
    iwd \
    openssh \
    parted \
    patch \
    vi

# Overlay the contents of tree on the root filesystem
mkdir -p "$dir/tree"
cp -RT "$dir/tree" /

# Enable systemd units
systemctl enable iwd.service
systemctl enable sshd.service
systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service

# Declarative definition of users their group membership
mkdir -p /etc/sysusers.d
cat > /etc/sysusers.d/users.conf <<EOF
# Users
u $user 1000 - /home/$user /bin/bash

# Group membership
m $user users
m $user wheel
EOF

# Apply the configuration with systemd-sysusers
systemd-sysusers

# Set a temporary password for the new user
echo "$user:$tmp_password" | chpasswd

# Create a home directory in case a home partition isn't mounted
mkdir -p "/home/$user"
chown "$user:$user" "/home/$user"

# Allow messages to be printed to the console during boot
patch /etc/default/grub "$dir/grub.patch"

# Install GRUB to both the BIOS boot partition and EFI system partition
grub-install --target=i386-pc /dev/vda --recheck
grub-install --target=x86_64-efi --efi-directory=/efi --removable --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# This patch is required to allow booting on multiple systems each requiring
# different modules in early userspace
patch /etc/mkinitcpio.conf "$dir/mkinitcpio.conf.patch"
mkinitcpio -p linux
