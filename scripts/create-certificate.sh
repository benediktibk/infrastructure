#!/bin/bash

echo $1
echo $2

if [ ! -n "$1" ]; then echo "certificate name is not specified"; exit 1; fi
if [ ! -n "$2" ]; then echo "common name is not specified"; exit 1; fi

KEYFILE=build/secrets/ca/$1.key
CSRFILE=build/secrets/ca/$1.csr
CERTFILE=build/secrets/ca/$1.crt
ROOTCACERTFILE=build/secrets/ca/root_ca.crt
ROOTCAKEYFILE=build/secrets/ca/root_ca.key

openssl genrsa -out $KEYFILE 4096
openssl req -new -sha512 -key $KEYFILE -subj "/C=AT/O=benediktschmidt.at/CN=$2" -out $CSRFILE
openssl x509 -req -in $CSRFILE -CA $ROOTCACERTFILE -CAkey $ROOTCAKEYFILE -CAcreateserial -out ${CERTFILE}_temp -days 1825 -sha512
cat ${CERTFILE}_temp $ROOTCACERTFILE > $CERTFILE
rm ${CERTFILE}_temp