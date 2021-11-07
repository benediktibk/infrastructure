#!/usr/bin/env sh

delete_forward_rule () {
    echo "deleting rule $1"
    RULEHANDLES=$(nft -n -a list table filter | sed -n "s/^.*$1 # handle \([0-9]*\).*/\1/p")
    for RULEHANDLE in $RULEHANDLES
    do
        nft delete rule filter FORWARD handle $RULEHANDLE
    done
}

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; exit 0;" SIGHUP SIGINT SIGTERM

echo "host IP: $HOSTIP"
echo "host VPN IP: $HOSTVPNIP"

echo "setup chain filter INPUT"
nft delete chain ip filter INPUT
nft 'add chain ip filter INPUT { type filter hook input priority 0; policy accept; }'

echo "setup chain filter FORWARD-DMZ-INTERNAL"
delete_forward_rule "jump FORWARD-DMZ-INTERNAL"
nft delete chain ip filter FORWARD-DMZ-INTERNAL
nft add chain ip filter FORWARD-DMZ-INTERNAL
nft insert rule ip filter FORWARD jump FORWARD-DMZ-INTERNAL

echo "setup chain filter FORWARD"
nft 'add chain ip filter FORWARD { type filter hook forward priority 0; policy accept; }'

echo "setup chain filter FORWARD-LOGGING"
nft delete chain ip filter FORWARD-LOGGING
nft 'add chain ip filter FORWARD-LOGGING { type filter hook forward priority -1; policy drop; }'

echo "configure chain INPUT"
echo "    allow traffic on loopback device"
nft add rule filter INPUT iifname "lo" accept
echo "    allow already established connections"
nft add rule filter INPUT ct state established accept
echo "    allow specific services from VPN"
nft add rule filter INPUT ip daddr $HOSTVPNIP tcp dport 22 accept
echo "    allow specific services from external"
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 1194 accept
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 80 accept
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 443 accept
echo "    allow ICMP requests"
nft add rule filter INPUT icmp type echo-request accept
echo "    log dropped packets"
nft add rule filter INPUT log prefix "nft.ip.filter.input.drop "
echo "    set chain filter INPUT default policy to drop"
nft 'add chain ip filter INPUT { type filter hook input priority 0; policy drop; }'

echo "configure chain FORWARD-DMZ-INTERNAL"
echo "    allow already established connections"
nft add rule filter FORWARD-DMZ-INTERNAL ct state established accept
echo "    allow access to database from corona-viewer"
nft add rule filter FORWARD-DMZ-INTERNAL ip saddr 192.168.38.4 ip daddr 192.168.39.2 tcp dport 1433 accept
nft add rule filter FORWARD-DMZ-INTERNAL ip saddr 192.168.38.254 ip daddr 192.168.39.2 tcp dport 1433 accept
echo "    allow ICMP requests"
nft add rule filter FORWARD-DMZ-INTERNAL icmp type echo-request accept

echo "configure chain FORWARD-LOGGING"
echo "    log dropped packets"
nft add rule filter FORWARD-LOGGING log prefix "nft.ip.filter.forward.drop "

while :
do
    sleep 1h &
    wait $!
done