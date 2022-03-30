#!/bin/bash

echo "ensure that the mountpoint is clean"
umount /mnt/storage1 > /dev/null 2>&1

set -e

echo "mount storage"
mount /mnt/storage1

echo "create partial backup of storage"
/usr/bin/rsync --recursive --delete-during --progress --exclude Multimedia --exclude Software --exclude System --exclude Temp /mnt/storage1/ /mnt/storagebackup

echo "touch guard"
touch /mnt/storagebackup/guard

echo "umount storage"
umount /mnt/storage1