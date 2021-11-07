#!/usr/bin/env sh

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; exit 0;" SIGHUP SIGINT SIGTERM

while :
do
    sleep 1h &
    wait $!
done