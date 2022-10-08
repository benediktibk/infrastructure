#!/bin/bash

echo "prepare shinobi server configs"
cp /conf.json.template /???/conf.json
cp /super.json.template /???/super.json

sed -i "s/##DBPASSWORD##/$MARIADB_PASSWORD/g" /???/conf.json
sed -i "s/##SHINOBIADMINPASSWORD##/$SHINOBIADMINPASSWORD/g" /???/super.json

echo "execute shinobi in foreground"
pm2 start camera.js
pm2 start cron.js
exec pm2 logs