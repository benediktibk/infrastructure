#!/usr/bin/env sh

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; exit 0;" SIGHUP SIGINT SIGTERM

echo "host IP: $HOSTIP"
echo "host VPN IP: $HOSTVPNIP"

nft delete chain ip filter INPUT
nft 'add chain ip filter INPUT { type filter hook input priority 0; policy accept; }'
nft add rule filter INPUT iifname "lo" accept
nft add rule filter INPUT ct state established accept
nft add rule filter INPUT ip daddr $HOSTVPNIP tcp dport 22 accept
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 1194 accept
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 80 accept
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 443 accept
nft add rule filter INPUT icmp type echo-request accept

nft add rule filter INPUT log prefix "nft.ip.filter.input.drop "
nft 'add chain ip filter INPUT { type filter hook input priority 0; policy drop; }'

while :
do
    sleep 1h &
    wait $!
done