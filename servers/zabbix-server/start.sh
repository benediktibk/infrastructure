#!/bin/bash

echo "prepare zabbix server config"
cp /zabbix_server.conf.template /etc/zabbix/zabbix_server.conf

sed -i "s/##DBPASSWORD##/$POSTGRES_PASSWORD/g" /etc/zabbix/zabbix_server.conf

echo "execute zabbix server in foreground"
exec /usr/sbin/zabbix_server --foreground -c /etc/zabbix/zabbix_server.conf