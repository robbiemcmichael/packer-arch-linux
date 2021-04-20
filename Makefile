.PHONY: build
build: img/root.overlay.qcow2 img/home.overlay.qcow2

img/root.qcow2:
	packer build -on-error=ask build.json

img/root.overlay.qcow2: img/root.qcow2
	qemu-img create -f qcow2 -F qcow2 -b root.qcow2 "$@" 20G

img/home.qcow2:
	virt-make-fs --format=qcow2 --partition=gpt --type=ext4 --size=5G --label=HOME home "$@"

img/home.overlay.qcow2: img/home.qcow2
	qemu-img create -f qcow2 -F qcow2 -b home.qcow2 "$@"

.PHONY: run
run: img/root.overlay.qcow2 img/home.overlay.qcow2
	qemu-system-x86_64 \
		-name arch \
		-drive file=img/root.overlay.qcow2,if=virtio,cache=writeback,discard=ignore,format=qcow2 \
		-drive file=img/home.overlay.qcow2,if=virtio,cache=writeback,discard=ignore,format=qcow2 \
		-machine type=pc,accel=kvm \
		-smp cpus=2,sockets=2 \
		-m 2048M \
		-device virtio-net,netdev=user.0 \
		-netdev user,id=user.0,hostfwd=tcp::2222-:22 \
		-vga virtio \
		-display gtk,gl=on

.PHONY: clean
clean:
	rm -rf img/
