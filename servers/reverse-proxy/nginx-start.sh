#!/usr/bin/env sh


if [ "$(ls -A /etc/nginx/certs)" ]; then
    echo "it seems like there are already certificates available"
else
    echo "no certificates are available yet, using self signed ones"
    cp /etc/nginx/certs-temp/* /etc/nginx/certs/
fi

set -eu

envsubst '${WEBFQDN} ${TARGETCORONA} ${TARGETME} ${TARGETDOWNLOADS}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'