#!/bin/bash

echo "prepare fstab"
sed -i "s/##DOMAINPASSWORD##/$DOMAINPASSWORD/g" /etc/fstab

echo "execute cron in foreground"
exec cron -f