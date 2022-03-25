#!/bin/bash

cp /rclone.conf.template /rclone.conf

sed -i "s/##GOOGLEDRIVECLIENTSECRET##/$GOOGLEDRIVECLIENTSECRET/g" /rclone.conf
sed -i "s/##GOOGLEDRIVECLIENTID##/$GOOGLEDRIVECLIENTID/g" /rclone.conf

cron -f