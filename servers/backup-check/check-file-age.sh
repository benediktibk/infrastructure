#!/bin/bash

set -e

mount -a > /dev/null

if [ -f "$1" ]; then
    echo $(($(date +%s) - $(date +%s -r "$1")))
else
    echo "4294967295"
fi
