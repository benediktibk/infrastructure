#!/bin/bash

smbclient -U system-cron-password@benediktschmidt.at%$DOMAINPASSWORD //storage1.benediktschmidt.at/data --directory User/benedikt/Documents/Passwoerter -c 'get passwords.kdbx'
smbclient -N //downloads-share.benediktschmidt.at/data -c 'put passwords.kdbx'