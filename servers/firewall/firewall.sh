#!/usr/bin/env sh

delete_forward_rule () {
    echo "deleting rule $1"
    RULEHANDLES=$(nft -n -a list table filter | sed -n "s/^.*$1 # handle \([0-9]*\).*/\1/p")
    for RULEHANDLE in $RULEHANDLES
    do
        nft delete rule filter FORWARD handle $RULEHANDLE
    done
}

add_forward_rule_from_vpn () {
    echo "allowing port $2 on protocol $1 from VPN"
    nft add rule filter FORWARD-DMZ-INTERNAL ip saddr 192.168.40.0/24 ip daddr 192.168.39.3 $1 dport $2 counter accept
    nft add rule filter FORWARD-DMZ-INTERNAL ip saddr 192.168.42.0/24 ip daddr 192.168.39.3 $1 dport $2 counter accept
    nft add rule filter FORWARD-DMZ-INTERNAL ip saddr 192.168.43.0/24 ip daddr 192.168.39.3 $1 dport $2 counter accept
}

echo "install trap for signals"
trap "echo 'got signal to stop, exiting'; exit 0;" QUIT HUP INT TERM

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
delete_forward_rule "jump FORWARD-LOGGING"
nft delete chain ip filter FORWARD-LOGGING
nft add chain ip filter FORWARD-LOGGING
nft add rule ip filter FORWARD jump FORWARD-LOGGING

echo "configure chain INPUT"
echo "    allow traffic on loopback device"
nft add rule filter INPUT iifname "lo" accept
echo "    allow already established connections"
nft add rule filter INPUT ct state established accept
echo "    allow specific services from VPN"
nft add rule filter INPUT ip daddr $HOSTVPNIP tcp dport 22 counter accept
echo "    allow specific services from external"
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 1194 counter accept
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 80 counter accept
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 443 counter accept
nft add rule filter INPUT ip daddr $HOSTIP tcp dport 2456-2458 counter accept
nft add rule filter INPUT ip daddr $HOSTIP udp dport 2456-2458 counter accept
nft add rule filter INPUT ip daddr $HOSTIP udp dport 22023 counter accept
echo "    allow ICMP requests"
nft add rule filter INPUT icmp type echo-request counter accept
echo "    log dropped packets"
nft add rule filter INPUT counter log prefix "nft.ip.filter.input.drop "
echo "    set chain filter INPUT default policy to drop"
nft 'add chain ip filter INPUT { type filter hook input priority 0; policy drop; }'

echo "configure chain FORWARD-DMZ-INTERNAL"
echo "    allow already established connections"
nft add rule filter FORWARD-DMZ-INTERNAL ct state established accept
echo "    allow access from DMZ to the outside"
nft add rule filter FORWARD-DMZ-INTERNAL ip saddr 192.168.38.0/24 counter accept
echo "    allow access from internal to the outside"
nft add rule filter FORWARD-DMZ-INTERNAL ip saddr 192.168.39.0/24 counter accept
echo "    allow access to database from corona-viewer"
nft add rule filter FORWARD-DMZ-INTERNAL ip saddr 192.168.38.4 ip daddr 192.168.39.2 tcp dport 1433 counter accept
nft add rule filter FORWARD-DMZ-INTERNAL ip saddr 192.168.38.254 ip daddr 192.168.39.2 tcp dport 1433 counter accept
echo "    allow access to database from zabbix-frontend"
nft add rule filter FORWARD-DMZ-INTERNAL ip saddr 192.168.38.8 ip daddr 192.168.39.6 tcp dport 5432 counter accept
echo "    allow access to zabbix-server from zabbix-frontend"
nft add rule filter FORWARD-DMZ-INTERNAL ip saddr 192.168.38.8 ip daddr 192.168.39.7 tcp dport 10051 counter accept
echo "    allow ICMP requests"
nft add rule filter FORWARD-DMZ-INTERNAL icmp type echo-request counter accept
echo "    allow WINS replication from VPN"
add_forward_rule_from_vpn tcp 42
echo "    allow DNS from VPN"
add_forward_rule_from_vpn udp 53
add_forward_rule_from_vpn tcp 53
echo "    allow Kerberos from VPN"
add_forward_rule_from_vpn udp 88
add_forward_rule_from_vpn tcp 88
echo "    allow NTP from VPN"
add_forward_rule_from_vpn udp 123
echo "    allow endpoint mapper from VPN"
add_forward_rule_from_vpn tcp 135
echo "    allow netbios from VPN"
add_forward_rule_from_vpn udp 137
add_forward_rule_from_vpn udp 138
add_forward_rule_from_vpn tcp 139
echo "    allow LDAP from VPN"
add_forward_rule_from_vpn udp 389
add_forward_rule_from_vpn tcp 389
echo "    allow SMB from VPN"
add_forward_rule_from_vpn tcp 445
echo "    allow Kerberos kpasswd from VPN"
add_forward_rule_from_vpn udp 464
add_forward_rule_from_vpn tcp 464
echo "    allow LDAPS from VPN"
add_forward_rule_from_vpn tcp 636
echo "    allow global catalog from VPN"
add_forward_rule_from_vpn tcp 3268
add_forward_rule_from_vpn tcp 3269
echo "    allow dynamic RPC ports from VPN"
add_forward_rule_from_vpn tcp 49152-65535
echo "    return to previous chain"
nft add rule filter FORWARD-DMZ-INTERNAL counter return

echo "configure chain FORWARD-LOGGING"
echo "    log dropped packets"
nft add rule filter FORWARD-LOGGING counter log prefix "nft.ip.filter.forward.drop "

while :
do
    sleep 1h &
    wait $!
done