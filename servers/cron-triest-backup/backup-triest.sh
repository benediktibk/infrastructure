#!/bin/bash

FILENAME=triest_$(date +%Y-%m-%d_%H-%M-%S).tar.gz

echo "ensure that the mountpoint is clean"
umount /mnt/storage1 > /dev/null 2>&1

set -e
echo "mount storage"
mount.cifs -o username=system-cron-triest,domain=benediktschmidt.at,password=$DOMAINPASSWORD,rw //192.168.42.4/data /mnt/storage1

echo "cleanup temporary directory"
rm -fR /tmp/backup/*

echo "create backup of googledrivetriest"
cp -R /mnt/googledrivetriest /tmp/backup/
tar -czvf /tmp/backup/$FILENAME /tmp/backup/googledrivetriest

echo "copy backup to storage"
cp /tmp/backup/$FILENAME /mnt/storage1/User/laura/google_drive_backup

echo "delete too old backups"
find /mnt/storage1/User/laura/google_drive_backup/* -mtime +31 -exec rm {} \;

echo "unmount storage"
umount /mnt/storage1