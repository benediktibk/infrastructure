#!/usr/bin/env sh

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; nginx -s stop; exit 0;" QUIT HUP INT TERM

if [ "$(ls -A /etc/nginx/certs)" ]; then
    echo "it seems like there are already certificates available"
else
    echo "no certificates are available yet, using self signed ones"
    cp /etc/nginx/certs-temp/* /etc/nginx/certs/
fi

set -eu

envsubst '${WEBFQDN} ${TARGETCORONA} ${TARGETME} ${TARGETDOWNLOADS} ${TARGETMONITORING} ${TARGETCLOUD} ${TARGETAPTREPO}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

nginx -g 'daemon on;'

while :
do
    sleep 1h &
    wait $!
    nginx -s reload
done