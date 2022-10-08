#!/bin/bash

echo "prepare shinobi server configs"
cp /conf.json.template /opt/shinobi/conf.json
cp /super.json.template /opt/shinobi/super.json

sed -i "s/##DBPASSWORD##/$MARIADB_PASSWORD/g" /opt/shinobi/conf.json
sed -i "s/##SHINOBIADMINPASSWORD##/$SHINOBIADMINPASSWORD/g" /opt/shinobi/super.json

echo "execute shinobi in foreground"
cd /opt/shinobi/
pm2 start camera.js
pm2 start cron.js
exec pm2 logs