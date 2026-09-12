#!/bin/bash

echo "starting valheim server $SERVER_NAME with password $SERVER_PASSWORD"

export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970
./valheim_server.x86_64 -name "$SERVER_NAME" -port $SERVER_PORT -world "Dedicated" -password "$SERVER_PASSWORD" -crossplay -public 1 -savedir /srv/valheim &
PROCESSID=$!

echo "install trap for signals"
trap "echo 'got signal to stop, sending SIGINT to $PROCESSID'; kill -s SIGINT $PROCESSID; echo 'waiting for $PROCESSID to finish'; wait $PROCESSID; echo 'everything stopped gracefully'; exit 0;" SIGHUP SIGINT SIGTERM

wait $PROCESSID

echo "valheim process stopped unexpected"
exit 1