

.PHONY: enter iso test

all: iso

.edit.timestamp: ubuntu.iso
	mkdir -p mnt
	mount -o loop ubuntu.iso mnt

	unsquashfs mnt/casper/filesystem.squashfs
	mv squashfs-root edit

	mkdir -p extract-cd
	rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd

	umount mnt
	rmdir mnt
	touch .edit.timestamp



enter: .edit.timestamp
	cp /etc/resolv.conf edit/etc/
	cp /etc/hosts edit/etc/
	cp chroot.sh edit/
	mount --bind /dev/ edit/dev
	chroot edit /chroot.sh
	umount edit/dev
	touch .enter.timestamp

.enter.timestamp:
	touch .enter.timestamp

extract-cd/casper/filesystem.manifest-desktop: .edit.timestamp .enter.timestamp
	chmod +w extract-cd/casper/filesystem.manifest
	chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest
	cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
	sed -i '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop
	sed -i '/casper/d' extract-cd/casper/filesystem.manifest-desktop

extract-cd/casper/filesystem.squashfs: extract-cd/casper/filesystem.manifest-desktop
	- rm extract-cd/casper/filesystem.squashfs
	# not working; mksquashfs edit extract-cd/casper/filesystem.squashfs -nolzma
	mksquashfs edit extract-cd/casper/filesystem.squashfs

extract-cd/casper/filesystem.size: extract-cd/casper/filesystem.squashfs
	printf $(sudo du -sx --block-size=1 edit | cut -f1) > extract-cd/casper/filesystem.size


extract-cd/README.diskdefines: extract-cd/casper/filesystem.squashfs
	echo "Custom LiveCD" > extract-cd/README.diskdefines

extract-cd/md5sum.txt: extract-cd/casper/filesystem.squashfs
	cd extract-cd; rm md5sum.txt; find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat > md5sum.txt


ubuntu-custom.iso: extract-cd/md5sum.txt
	cd extract-cd; mkisofs -D -r -V "$IMAGE_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../ubuntu-custom.iso .

iso: ubuntu-custom.iso

test:
	qemu -cdrom ubuntu-custom.iso -boot d -m 2048

dist-clean:
	rm -Rf edit extract-cd .edit.timestamp .enter.timestamp
