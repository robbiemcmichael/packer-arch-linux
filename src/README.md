## Stages

### `install`

- Partitions the disk
- Executes `pacstrap` to install Arch Linux

### `configure`

Executed within `arch-chroot`.

- Configures the system
- Installs a sensible set of packages for a minimal system
- Installs the GRUB boot loader for both BIOS and UEFI

### `common`

Executed within `arch-chroot`.

Put common configuration for all targets in this script.

### `target/<TARGET>`

Executed within `arch-chroot`.

Put configuration for a specific target in the corresponding script.

### `cleanup`

- Restores the original pacman mirror list
- Cleans up the cache
- Unmounts filesystems
