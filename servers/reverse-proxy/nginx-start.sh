#!/usr/bin/env sh
set -eu

envsubst '${WEBFQDN} ${TARGETCORONA} ${TARGETME} ${TARGETDOWNLOADS}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'