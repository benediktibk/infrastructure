#!/usr/bin/env sh

#certbot certonly --webroot --webroot-path=/var/www/html --email benediktibk@gmail.com --agree-tos --no-eff-email -d me.benediktschmidt.at

while :
do
    sleep 1h &
    wait $!
done