#!/usr/bin/env bash

# Prints {"wifi": ..., "wifi_icon": ..., "vpn": ..., "vpn_icon": ...} for eww:
# labels and icons for the active Wi-Fi (or wired) connection and VPN, now and
# again whenever NetworkManager reports a change.
source "${BASH_SOURCE%/*}/lib.sh"

# Nerd Font icons
connected_icon=$'\U000F05A9'
wired_icon=$'\U000F0200'
offline_icon=$'\U000F05AA'
vpn_on_icon=$'\U000F099D'
vpn_off_icon=$'\U000F099E'

render() {
    local wifi wifi_icon vpn vpn_icon
    if wifi=$(nm_connections 802-11-wireless --active | head -n1) && [[ -n $wifi ]]; then
        wifi_icon=$connected_icon
    elif [[ -n $(nm_connections 802-3-ethernet --active) ]]; then
        wifi=Wired wifi_icon=$wired_icon
    else
        wifi=Offline wifi_icon=$offline_icon
    fi
    vpn=$({ nm_connections wireguard --active; nm_connections vpn --active; } | head -n1)
    if [[ -n $vpn ]]; then vpn_icon=$vpn_on_icon; else vpn="No VPN" vpn_icon=$vpn_off_icon; fi
    emit "$(jq -nc --arg wifi "$wifi" --arg wifi_icon "$wifi_icon" \
                   --arg vpn "$vpn" --arg vpn_icon "$vpn_icon" '{$wifi, $wifi_icon, $vpn, $vpn_icon}')"
}

render
nmcli monitor | while read -r _; do
    drain_burst
    render
done
