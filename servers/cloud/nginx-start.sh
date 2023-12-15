#!/usr/bin/env sh

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; nginx -s stop; exit 0;" QUIT HUP INT TERM

set -eu

envsubst '${SECRET} ${DBPASSWORD}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

nginx -g 'daemon on;'

while :
do
    sleep 1h &
    wait $!
    nginx -s reload
done