#!/bin/bash

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; exit 0;" SIGHUP SIGINT SIGTERM

export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970
./valheim_server.x86_64 -name $VALHEIM_SERVER_NAME -port 2456 -world "Dedicated" -password $VALHEIM_SERVER_PASSWORD -public 1 -savedir /srv/valheim &
wait $!

echo "valheim process stopped unexpected"
exit 1