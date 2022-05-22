#!/bin/bash

echo "synching google drive"
/usr/bin/rclone sync --progress --config /etc/rclone_temp.conf google_drive_triest: /mnt/googledrivetriest