#!/bin/bash
set -e

FILENAME=volumes_$(date +%Y-%m-%d_%H-%M-%S).tar.gz

mount.cifs -o username=system-cron-volume,domain=benediktschmidt.at,password=$DOMAINPASSWORD,rw //storage1.benediktschmidt.at/data /mnt/storage1
rm -fR /tmp/backup/*
cp -R /mnt/volumes /tmp/backup/
tar -czvf /tmp/backup/$FILENAME /tmp/backup/volumes
cp /tmp/backup/$FILENAME /mnt/storage1/System/backup/docker-volumes/
find /mnt/storage1/System/backup/docker-volumes/* -mtime +7 -exec rm {} \;
umount /mnt/storage1