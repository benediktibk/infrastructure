#!/bin/bash

echo "create temporary config file"
cp /etc/rclone.conf /etc/rclone_temp.conf

echo "execute cron in foreground"
exec cron -f