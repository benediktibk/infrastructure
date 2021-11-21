#!/usr/bin/env sh

DOMAINS = me.benediktschmidt.at
#DOMAINS = benediktschmidt.at me.benediktschmidt.at downloads.benediktschmidt.at corona.benediktschmidt.at

function installCertificate()
{
    DOMAIN = $1
    DOMAINPATH = "/etc/letsencrypt/live/$DOMAIN"
    echo "installing certificate for domain $DOMAIN"
    cp $DOMAINPATH/privkey.pem /etc/nginx/certs/web_$DOMAIN.key
    cp $DOMAINPATH/fullchain.pem /etc/nginx/certs/web_$DOMAIN.crt
}

for DOMAIN in $DOMAINS;
do
    DOMAINPATH = "/etc/letsencrypt/live/$DOMAIN"
    if [! -d DOMAINPATH]; then
        echo "$DOMAINPATH does not yet exist, requesting new certificate for $DOMAIN"
        certbot certonly --staging --webroot --webroot-path=/var/www/html --email benediktibk@gmail.com --agree-tos --no-eff-email --domain $DOMAIN
        installCertificate $DOMAIN
    fi
done

while :
do
    sleep 1h &
    wait $!
    certbot renew --staging

    for DOMAIN in $DOMAINS;
    do
        installCertificate --webroot --webroot-path=/var/www/html --email benediktibk@gmail.com --agree-tos --no-eff-email --domain $DOMAIN
    done
done