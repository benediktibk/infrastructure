#!/usr/bin/env sh

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; exit 0;" SIGHUP SIGINT SIGTERM

echo "host IP: $HOSTIP"
echo "host VPN IP: $HOSTVPNIP"

echo "setup chain filter INPUT"
nft delete chain ip filter INPUT
nft 'add chain ip filter INPUT { type filter hook input priority 0; policy accept; }'

echo "allow traffic on loopback device"
nft add rule filter INPUT iifname "lo" accept

echo "allow already established connections"
nft add rule filter INPUT ct state established accept

echo "allow specific services from VPN"
nft add rule filter INPUT ip daddr $HOSTVPNIP tcp dport 22 accept

echo "allow specific services from external"
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 1194 accept
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 80 accept
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 443 accept

echo "allow ICMP requests"
nft add rule filter INPUT icmp type echo-request accept

echo "log dropped packets"
nft add rule filter INPUT log prefix "nft.ip.filter.input.drop "

echo "set chain filter INPUT default policy to drop"
nft 'add chain ip filter INPUT { type filter hook input priority 0; policy drop; }'

while :
do
    sleep 1h &
    wait $!
done