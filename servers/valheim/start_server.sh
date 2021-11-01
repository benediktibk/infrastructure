#!/bin/bash

export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970
exec ./valheim_server.x86_64 -name $VALHEIM_SERVER_NAME -port 2456 -world "Dedicated" -password $VALHEIM_SERVER_PASSWORD -public 1 -savedir /srv/valheim