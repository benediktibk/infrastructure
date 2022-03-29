#!/bin/bash

set -e

mount -a > /dev/null
export BLOCKSIZE=1

if [ -d "$1" ]; then
    if [ "$(ls -A $1)" ]; then
        ls --size --sort=time $1 | grep --invert-match guard | head -n 2 | tail -n 1 | sed -r "s/\s*([0-9]*)\s*.*/\1/"
    else
        echo "0"
    fi
else
    echo "0"
fi
