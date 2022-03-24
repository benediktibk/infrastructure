#!/bin/bash

FILENAME=volumes_$(date +%Y-%m-%d_%H-%M-%S).tar.gz

umount /mnt/storage1

set -e
mount.cifs -o username=system-cron-volume,domain=benediktschmidt.at,password=$DOMAINPASSWORD,rw //192.168.42.4/data /mnt/storage1
rm -fR /tmp/backup/*
cp -R /mnt/volumes /tmp/backup/
tar -czvf /tmp/backup/$FILENAME /tmp/backup/volumes
cp /tmp/backup/$FILENAME /mnt/storage1/System/backup/docker-volumes/
find /mnt/storage1/System/backup/docker-volumes/* -mtime +7 -exec rm {} \;
umount /mnt/storage1