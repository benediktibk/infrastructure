#!/bin/bash

echo "prepare DNS settings"
cp /etc/resolv_prepared.conf /etc/resolv.conf

echo "start samba"
/usr/sbin/samba --foreground --debuglevel=3 --debug-stderr