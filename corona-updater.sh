#!/bin/bash

echo "install trap for signals"
trap "exit;" SIGHUP SIGINT SIGTERM

while :
do
    echo "waiting 1h for next update"
    sleep 1h
    echo "executing updater"
    dotnet Updater.dll
done