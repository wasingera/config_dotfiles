#!/usr/bin/env bash

# Prints {"wifi": ..., "vpn": ...} for eww: labels for the active Wi-Fi (or
# wired) connection and VPN, now and again whenever NetworkManager reports a
# change.
source "${BASH_SOURCE%/*}/lib.sh"

# Nerd Font icons
wifi_icon=$'\U000F05A9'
wired_icon=$'\U000F0200'
offline_icon=$'\U000F05AA'
vpn_icon=$'\U000F099D'
no_vpn_icon=$'\U000F099E'

render() {
    local name wifi vpn
    if name=$(nm_connections 802-11-wireless --active | head -n1) && [[ -n $name ]]; then
        wifi="$wifi_icon $name"
    elif name=$(nm_connections 802-3-ethernet --active | head -n1) && [[ -n $name ]]; then
        wifi="$wired_icon Wired"
    else
        wifi="$offline_icon Offline"
    fi
    name=$({ nm_connections wireguard --active; nm_connections vpn --active; } | head -n1)
    if [[ -n $name ]]; then vpn="$vpn_icon $name"; else vpn="$no_vpn_icon No VPN"; fi
    emit "$(jq -nc --arg wifi "$wifi" --arg vpn "$vpn" '{$wifi, $vpn}')"
}

render
nmcli monitor | while read -r _; do
    drain_burst
    render
done
