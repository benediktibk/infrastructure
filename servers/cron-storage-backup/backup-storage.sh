#!/bin/bash

echo "ensure that the mountpoint is clean"
umount /mnt/storage1 > /dev/null 2>&1

set -e

echo "mount storage"
mount.cifs -o username=system-cron-storage,domain=benediktschmidt.at,password=$DOMAINPASSWORD,rw //192.168.42.4/data /mnt/storage1

echo "create partial backup of storage"
rsync --recursive --delete-during --progress --exclude Multimedia/Filme --exclude Multimedia/Serien --exclude Software /mnt/storage1/ /mnt/storagebackup

echo "touch guard"
touch /mnt/storagebackup/guard

echo "umount storage"
umount /mnt/storage1