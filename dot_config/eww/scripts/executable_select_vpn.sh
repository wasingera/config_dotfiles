#!/usr/bin/env bash

# Pick a WireGuard VPN to connect to, or disconnect the active one.
source "${BASH_SOURCE%/*}/lib.sh"

active=$(nm_connections wireguard --active | head -n1)
chosen=$({ echo Disconnect; nm_connections wireguard | sort -u; } | rofi_menu select_vpn)

[[ -z $chosen ]] && exit 0

# Only one VPN at a time: drop the current one first
if [[ -n $active ]]; then
    nmcli connection down "$active" || notify-send "Failed to disconnect from $active"
fi

if [[ $chosen != Disconnect ]]; then
    nmcli connection up "$chosen" || notify-send "Failed to connect to $chosen"
fi
