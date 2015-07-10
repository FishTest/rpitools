#!/bin/sh
echo "Step 1: install system required"
sudo apt-get install dosfstools dump parted kpartx
echo "Step 2: generate blank image file"
sudo dd if=/dev/zero of=raspberrypi.img bs=1MB count=3800
echo "Step 3: part image file"
sudo parted raspberrypi.img --script -- mklabel msdos
sudo parted raspberrypi.img --script -- mkpart primary fat32 8192s 122879s
sudo parted raspberrypi.img --script -- mkpart primary ext4 122880s -1
echo "Step 4: generate loop device"
loopdevice=`sudo losetup -f --show raspberrypi.img`
device=`sudo kpartx -va $loopdevice | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
device="/dev/mapper/${device}"
partBoot="${device}p1"
partRoot="${device}p2"
echo "Step 5: format loopdevice"
sudo mkfs.vfat $partBoot
sudo mkfs.ext4 $partRoot
echo "Step 6: begin backup"
echo "Backup boot fs"
sudo mkdir /media/backup
sudo mount -t vfat $partBoot /media/backup
sudo cp -rfp /boot/* /media/backup/
sudo umount /media/backup
echo "Backup rootfs"
sudo mount -t ext4 $partRoot /media/backup
cd /media/backup
sudo dump -0uaf - / |  sudo restore -rf -
cd ~
echo "Step 6: finish..."
sudo umount /media/backup
sudo kpartx -d $loopdevice
sudo losetup -d $loopdevice
