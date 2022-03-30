#!/bin/bash

FILENAME=volumes_$(date +%Y-%m-%d_%H-%M-%S).tar.gz

echo "ensure that the mountpoint is clean"
umount /mnt/storage1 > /dev/null 2>&1

set -e
echo "mount storage"
mount -a

echo "cleanup temporary directory"
rm -fR /tmp/backup/*

echo "create backup of volumes"
cp -R /mnt/volumes /tmp/backup/
tar -czvf /tmp/backup/$FILENAME /tmp/backup/volumes

echo "copy backup to storage"
cp /tmp/backup/$FILENAME /mnt/storage1/System/backup/docker-volumes/

echo "delete too old backups"
find /mnt/storage1/System/backup/docker-volumes/* -mtime +7 -exec rm {} \;

echo "touch guard"
touch /mnt/storage1/System/backup/docker-volumes/guard

echo "unmount storage"
umount /mnt/storage1