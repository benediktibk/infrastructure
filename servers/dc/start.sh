#!/bin/bash

cp /etc/resolv_prepared.conf /etc/resolv.conf

/usr/sbin/samba --foreground --debuglevel=3 --debug-stderr