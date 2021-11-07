#!/usr/bin/env sh

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; exit 0;" SIGHUP SIGINT SIGTERM

echo "host IP: $HOSTIP"
echo "host VPN IP: $HOSTVPNIP"

nft 'add chain ip filter INPUT { type filter hook input priority 0; policy accept; }'
nft add rule filter INPUT iifname "lo" accept
nft add rule filter INPUT ip daddr $HOSTVPNIP tcp dport 22 counter
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 1194 counter

#nft 'add chain ip filter INPUT { type filter hook input priority 0; policy drop; }'

while :
do
    sleep 1h &
    wait $!
done