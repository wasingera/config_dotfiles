#!/bin/bash

# Get the name of the active WireGuard VPN connection, otherwise print "VPN Disconnected"
active_vpn=$(nmcli -t connection show --active | awk -F: '/wireguard/ {print $1}')
if [ -z "$active_vpn" ]; then
    echo "VPN Disconnected"
else
    echo "$active_vpn"
fi
