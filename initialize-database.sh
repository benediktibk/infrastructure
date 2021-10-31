#!/bin/bash

SAPASSWORD=$(cat build/secrets/passwords/db_sa)
export DBPASSWORD=$(cat build/secrets/passwords/db_corona)
export DBUSER="Corona"
export DBHOST="localhost"
export DBNAME="Corona"
export LOCALTEMPPATH="/tmp/corona/data"
SQLCMD=/opt/mssql-tools/bin/sqlcmd

executeSqlCommand() {
    $SQLCMD -S localhost -U sa -P $SAPASSWORD -Q "$1"

    if [ $? -eq 0 ] 
    then 
        echo "successfully execute SQL command" 
    else 
        echo "failed to execute SQL command" >&2
        exit 1
    fi
}

echo "startup database"
CONTAINERID=$(docker run -d --mount "type=volume,source=sqldata,target=/var/opt/mssql/data" --env-file build/sql.env -p 1433:1433 benediktschmidt.at/database-server)
echo "database has container id $CONTAINERID"

echo "waiting for database to finish startup"
sleep 10s

echo "create database Corona und login"
executeSqlCommand "CREATE DATABASE $DBNAME;"
executeSqlCommand "CREATE LOGIN $DBUSER WITH PASSWORD = \"$DBPASSWORD\", CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;"
executeSqlCommand "ALTER AUTHORIZATION ON DATABASE::$DBNAME TO $DBUSER;"

echo "execute database initialization of corona updater"
mkdir -p /tmp/corona/
dotnet servers/corona/Corona/Updater/bin/Release/netcoreapp5.0/publish/Updater.dll

echo "stop database container"
docker stop $CONTAINERID
