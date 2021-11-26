#!/bin/bash

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; exit 0;" SIGHUP SIGINT SIGTERM

while :
do
    echo "waiting 10min for next update"
    sleep 10m &
    wait $!
    echo "executing updater"
    dotnet Updater.dll
done