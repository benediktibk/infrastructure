#!/usr/bin/env sh

DOMAINS="benediktschmidt.at me.benediktschmidt.at downloads.benediktschmidt.at corona.benediktschmidt.at"

installCertificate () {
    DOMAIN=$1
    DOMAINPATH="/etc/letsencrypt/live/$DOMAIN"
    echo "installing certificate for domain $DOMAIN"
    cp $DOMAINPATH/privkey.pem /etc/nginx/certs/web_$DOMAIN.key
    cp $DOMAINPATH/fullchain.pem /etc/nginx/certs/web_$DOMAIN.crt
}

echo "create necessary directories"
mkdir -p /etc/letsencrypt/archive

echo "wait for reverse proxy to be up and running"
sleep 1m

for DOMAIN in $DOMAINS;
do
    DOMAINPATH="/etc/letsencrypt/live/$DOMAIN"
    if [ ! -d DOMAINPATH ]; then
        echo "$DOMAINPATH does not yet exist, requesting new certificate for $DOMAIN"
        certbot certonly --webroot --webroot-path=/var/www/html --email benediktibk@gmail.com --agree-tos --no-eff-email --domain $DOMAIN
        installCertificate $DOMAIN
    fi
done

while :
do
    echo "waiting 12 hours"
    sleep 12h &
    wait $!

    echo "check if certificates should be renewed"
    certbot renew

    echo "install certificates"
    for DOMAIN in $DOMAINS;
    do
        installCertificate $DOMAIN
    done
done