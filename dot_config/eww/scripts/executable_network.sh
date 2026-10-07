#!/usr/bin/env bash

# Prints {"wifi_icon": ..., "vpn_icon": ...} for eww: icons for the active
# Wi-Fi (or wired) connection and VPN, now and again whenever NetworkManager
# reports a change.
source "${BASH_SOURCE%/*}/lib.sh"

# Nerd Font icons
connected_icon=$'\U000F05A9'
wired_icon=$'\U000F0200'
offline_icon=$'\U000F05AA'
vpn_on_icon=$'\U000F099D'
vpn_off_icon=$'\U000F099E'

render() {
    local wifi_icon vpn_icon
    if [[ -n $(nm_connections 802-11-wireless --active) ]]; then
        wifi_icon=$connected_icon
    elif [[ -n $(nm_connections 802-3-ethernet --active) ]]; then
        wifi_icon=$wired_icon
    else
        wifi_icon=$offline_icon
    fi
    if [[ -n $({ nm_connections wireguard --active; nm_connections vpn --active; }) ]]; then
        vpn_icon=$vpn_on_icon
    else
        vpn_icon=$vpn_off_icon
    fi
    emit "$(jq -nc --arg wifi_icon "$wifi_icon" --arg vpn_icon "$vpn_icon" '{$wifi_icon, $vpn_icon}')"
}

render
nmcli monitor | while read -r _; do
    drain_burst
    render
done
