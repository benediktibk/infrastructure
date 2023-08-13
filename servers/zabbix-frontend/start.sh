#!/usr/bin/env sh

set -eu

echo "prepare zabbix config"
sed -i "s/##DBPASSWORD##/$POSTGRES_PASSWORD/g" /zabbix.conf.php.template
cp /zabbix.conf.php.template /etc/zabbix/web/zabbix.conf.php

echo "start php"
php-fpm8.2 --daemonize --fpm-config /etc/php/8.2/fpm/php-fpm.conf

echo "start nginx"
nginx -g 'daemon on;'

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; nginx -s stop; kill -9 $(cat /tmp/php-fpm.pid); exit 0;" QUIT HUP INT TERM

echo "wait for signal to stop"
while :
do
    sleep 1h &
    wait $!
    nginx -s reload
done