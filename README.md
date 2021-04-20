# packer-arch-linux

Uses Packer to build an Arch Linux image which can be used in QEMU or written
to a drive with `qemu-img dd`.

Key features:

- Reproducible image build for Arch Linux using Packer
- Allows customisations based on the target environment
- GRUB installation supports both BIOS and UEFI booting
- Image can be run with QEMU for testing purposes
- Guide for writing the image to a drive
- Guide for resizing the root filesystem

**WARNING:** The commands in this readme for writing the image to a drive will
overwrite the entire contents of that drive. This project is intended for
expert users; don't copy and paste the commands if you don't know what you're
doing.

## Usage

### Customisation

1. Edit the variables in [`build.json`](build.json)

2. Customise [`src/common`](src/common) to install your prefered packages

3. Add new targets and target specific configuration to
   [`src/target`](src/target)

4. If you plan to run the image with QEMU, you can add files to the home
   partition which is created from the contents of [`home`](home)

### Build and run

The following dependencies are required:

- packer
- qemu
- libguestfs

Build the image:

```
make build
```

Run the image in QEMU:

```
make run
```

### Write image to drive

#### Full image

The simplest way to use this project on a physical machine is to overwrite the
contents of an entire drive with the image.

Do **not** do this to a drive with any data you expect to keep (e.g. a drive
containing your home partition or another operating system).

```bash
qemu-img dd if=img/root.qcow2 of=TARGET_DEVICE bs=4M
```

#### Root partition only

For a permanent installation, you may want to leave other partitions untouched
and overwrite the root partition only.

```bash
loop_device=$(losetup -f)
losetup "$loop_device" -P img/root.qcow2
dd if="${loop_device}p3" of=TARGET_PARTITION bs=4M status=progress oflag=sync
losetup -d "$loop_device"
```

### Runtime customisation

The following steps should be performed after you have booted into the
installation.

#### Recommended

1. Change the password for the root user

2. Change the password for the user created during configuration

3. Run `mkinitcpio -p linux` after booting the image on the target environment
   and then reboot the machine

#### Optional

1. Resize the root filesystem (see below)

2. Mount any additional filesystems to the desired mount points

3. Run `genfstab -U / > /etc/fstab` to use UUIDs for all mounts

### Resizing the root filesystem

The root filesystem is small so that the image can be written to a USB drive.
If you want to use this project to create a permanent installation, it is
highly recommended that you resize the root filesystem to use up any free
space.

#### Simple approach

The easiest way for many users is to boot into another live USB installation of
Linux that has a user friendly tool like `gparted` and use that to resize the
filesystem.

#### Expert approach

If you know what you're doing and are aware of the risks of potentital data
loss, it's possible to resize a live filesystem. The example below resizes the
root filesystem for a QEMU installation where the root partition is
`/dev/vda3`.

```bash
sgdisk -e /dev/vda
sgdisk -d 3 /dev/vda
sgdisk -N 3 /dev/vda
sgdisk -c 3:root
partprobe /dev/vda
resize2fs /dev/vda3
```
