#!/usr/bin/env sh

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; nginx -s stop; exit 0;" QUIT HUP INT TERM

set -eu

echo "prepare zabbix config"
sed -i "s/##DBPASSWORD##/$POSTGRES_PASSWORD/g" /zabbix.conf.php.template
cp /zabbix.conf.php.template /etc/zabbix/web/zabbix.conf.php

echo "start nginx"
nginx -g 'daemon on;'

echo "wait for signal to stop"
while :
do
    sleep 1h &
    wait $!
    nginx -s reload
done