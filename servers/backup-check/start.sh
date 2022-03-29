#!/bin/bash

echo "prepare fstab"
sed -i "s/##DOMAINPASSWORD##/$DOMAINPASSWORD/g" /etc/fstab

echo "execute zabbix agent in foreground"
exec /usr/sbin/zabbix_agentd --foreground --config /etc/zabbix/zabbix_agentd.conf