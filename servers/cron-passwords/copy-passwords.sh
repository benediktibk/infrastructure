#!/bin/bash

echo "ensure that the mountpoint is clean"
umount /mnt/storage1 > /dev/null 2>&1

set -e

echo "mount storage"
mount /mnt/storage1

echo "download passwords file from storage"
cp /mnt/storage1/User/benedikt/Documents/Passwoerter/passwords.kdbx /mnt/downloads/passwords.kdbx

echo "umount storage"
umount /mnt/storage1