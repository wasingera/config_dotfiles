#!/usr/bin/env bash

# Prints {"wifi": ..., "vpn": ...} for eww: the active Wi-Fi and WireGuard
# connection names, now and again whenever NetworkManager reports a change.
source "${BASH_SOURCE%/*}/lib.sh"

render() {
    local wifi vpn
    wifi=$(nm_connections 802-11-wireless --active | head -n1)
    vpn=$(nm_connections wireguard --active | head -n1)
    emit "$(jq -nc --arg wifi "${wifi:-Disconnected}" --arg vpn "${vpn:-VPN Disconnected}" '{$wifi, $vpn}')"
}

render
nmcli monitor | while read -r _; do
    drain_burst
    render
done
