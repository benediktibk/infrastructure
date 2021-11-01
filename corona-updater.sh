#!/bin/bash

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; exit 0;" SIGHUP SIGINT SIGTERM

while :
do
    echo "waiting 1h for next update"
    sleep 1h &
    wait $!
    echo "executing updater"
    dotnet Updater.dll
done