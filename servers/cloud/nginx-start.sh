#!/usr/bin/env sh

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; nginx -s stop; exit 0;" QUIT HUP INT TERM

echo "start php"
php-fpm8.2 --daemonize --fpm-config /etc/php/8.2/fpm/php-fpm.conf

set -eu

envsubst '${SECRET} ${DBPASSWORD}' < /srv/cloud-web/config/config.php.template > /srv/cloud-web/config/config.php

nginx -g 'daemon on;'

while :
do
    sleep 1h &
    wait $!
    nginx -s reload
done