#!/bin/bash

export HOME=/root
export LC_ALL=C
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts
/bin/bash
apt-get clean
rm -rf /tmp/* ~/.bash_history
rm /etc/hosts
rm /etc/resolv.conf
rm /var/lib/dbus/machine-id
rm /sbin/initctl
rm /chroot.sh
dpkg-divert --rename --remove /sbin/initctl

umount /proc 2>dev/null || umount -lf /proc
umount /sys
umount /dev/pts

