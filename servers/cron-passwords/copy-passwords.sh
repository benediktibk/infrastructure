#!/bin/bash

smbclient -U system-cron-password@benediktschmidt.at%$DOMAINPASSWORD //192.168.42.4/data --directory User/benedikt/Documents/Passwoerter -c 'get passwords.kdbx'
smbclient -N //192.168.39.8/data -c 'put passwords.kdbx'