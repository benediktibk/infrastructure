#!/bin/bash

umount /mnt/storage1 > /dev/null 2>&1

set -e
mount.cifs -o username=system-cron-storage,domain=benediktschmidt.at,password=$DOMAINPASSWORD,rw //192.168.42.4/data /mnt/storage1
rsync --recursive --delete-during --exclude Multimedia/Filme --exclude Multimedia/Serien --exclude Software /mnt/storage1/ /mnt/storagebackup
umount /mnt/storage1