#!/bin/bash

echo "prepare rclone config"
cp /rclone.conf.template /rclone.conf

sed -i "s/##GOOGLEDRIVECLIENTSECRET##/$GOOGLEDRIVECLIENTSECRET/g" /rclone.conf
sed -i "s/##GOOGLEDRIVECLIENTID##/$GOOGLEDRIVECLIENTID/g" /rclone.conf

echo "execute cron in foreground"
exec cron -f