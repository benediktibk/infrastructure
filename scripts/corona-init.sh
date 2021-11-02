#!/bin/bash

SQLCMD=/opt/mssql-tools/bin/sqlcmd

if [ -z "$SA_PASSWORD" ]
then
    echo "SA_PASSWORD is not set"
    exit 1
fi

if [ -z "$DBNAME" ]
then
    echo "DBNAME is not set"
    exit 1
fi

if [ -z "$DBUSER" ]
then
    echo "DBUSER is not set"
    exit 1
fi

if [ -z "$DBPASSWORD" ]
then
    echo "DBPASSWORD is not set"
    exit 1
fi

if [ -z "$DBHOST" ]
then
    echo "DBHOST is not set"
    exit 1
fi

echo "using host $DBHOST, database $DBNAME and user $DBUSER"

executeSqlCommand() {
    $SQLCMD -S $DBHOST -U sa -P $SA_PASSWORD -Q "$1"

    if [ $? -eq 0 ] 
    then 
        echo "successfully execute SQL command" 
    else 
        echo "failed to execute SQL command" >&2
        exit 1
    fi
}

echo "waiting for database to finish startup"
sleep 10s

echo "create database Corona und login"
executeSqlCommand "CREATE DATABASE $DBNAME;"
executeSqlCommand "CREATE LOGIN $DBUSER WITH PASSWORD = \"$DBPASSWORD\", CHECK_EXPIRATION = OFF, CHECK_POLICY = OFF;"
executeSqlCommand "ALTER AUTHORIZATION ON DATABASE::$DBNAME TO $DBUSER;"

echo "fill database"
exec dotnet Updater.dll