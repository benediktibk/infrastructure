#!/bin/bash

FILENAME=volumes_$(date +%Y-%m-%d_%H-%M-%S).tar.gz

echo "ensure that the mountpoint is clean"
umount /mnt/storage1 > /dev/null 2>&1

set -e
echo "mount storage"
mount.cifs -o username=system-cron-volume,domain=benediktschmidt.at,password=$DOMAINPASSWORD,rw //192.168.42.4/data /mnt/storage1

echo "cleanup temporary directory"
rm -fR /tmp/backup/*

echo "create backup of volumes"
cp -R /mnt/volumes /tmp/backup/
tar -czvf /tmp/backup/$FILENAME /tmp/backup/volumes

echo "copy backup to storage"
cp /tmp/backup/$FILENAME /mnt/storage1/System/backup/docker-volumes/

echo "delete too old backups"
find /mnt/storage1/System/backup/docker-volumes/* -mtime +7 -exec rm {} \;

echo "unmount storage"
umount /mnt/storage1