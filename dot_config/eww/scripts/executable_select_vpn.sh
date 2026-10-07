#!/usr/bin/env bash

# Pick a VPN (WireGuard or a NetworkManager VPN plugin) to connect to, or
# disconnect the active one. Only one VPN is up at a time.
source "${BASH_SOURCE%/*}/lib.sh"

vpns() { nm_connections wireguard "$@"; nm_connections vpn "$@"; }

active=$(vpns --active | head -n1)
mapfile -t names < <(vpns | sort -u)

# The active VPN is marked and selected; Disconnect goes last, if there's
# anything to disconnect
args=()
for i in "${!names[@]}"; do
    [[ ${names[i]} == "$active" ]] && args=(-a "$i" -selected-row "$i")
done
options=("${names[@]}")
[[ -n $active ]] && options+=(Disconnect)

i=$(printf '%s\n' "${options[@]}" | rofi_menu select_vpn -format i "${args[@]}")
[[ -z $i ]] && exit 0
chosen=${options[i]}

[[ $chosen == "$active" ]] && exit 0

if [[ -n $active ]]; then
    nm_run "Disconnecting from $active" "Disconnected from $active" \
        nmcli connection down "$active" || exit 1
fi

if (( i < ${#names[@]} )); then
    nm_run "Connecting to $chosen" "Connected to $chosen" nmcli connection up "$chosen"
fi
