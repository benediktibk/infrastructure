#!/bin/bash

cp /rclone.conf.template /rclone.conf
cp /credentials.json.template /credentials.json

sed -i "s~##GOOGLEDRIVEPRIVATEKEY##~$GOOGLEDRIVEPRIVATEKEY~g" /credentials.json
sed -i "s/##GOOGLEDRIVECLIENTSECRET##/$GOOGLEDRIVECLIENTSECRET/g" /rclone.conf

cron -f