#!/usr/bin/env sh

envsubst '${HOSTIP}' < /etc/openvpn/server/server.conf.template > /etc/openvpn/server/server.conf

exec openvpn --config /etc/openvpn/server/server.conf