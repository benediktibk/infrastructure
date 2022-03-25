#!/bin/bash

smbclient --max-protocol=SMB2 -U system-cron-password@benediktschmidt.at%$DOMAINPASSWORD //192.168.42.4/data --directory User/benedikt/Documents/Passwoerter -c 'get passwords.kdbx'
smbclient --max-protocol=SMB2 -N //192.168.39.8/data -c 'put passwords.kdbx'