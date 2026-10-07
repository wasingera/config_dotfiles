#!/usr/bin/env bash

# Pick a VPN (WireGuard or a NetworkManager VPN plugin) to connect to, or
# disconnect the active one. Only one VPN is up at a time.
source "${BASH_SOURCE%/*}/lib.sh"

vpns() { nm_connections wireguard "$@"; nm_connections vpn "$@"; }

active=$(vpns --active | head -n1)
mapfile -t names < <(vpns | sort -u)

# Nerd Font icons: the active VPN, the others, Disconnect
connected_icon=$'\U000F099D'
vpn_icon=$'\U000F0499'
disconnect_icon=$'\U000F0156'

# The active VPN is marked and selected; Disconnect goes last, if there's
# anything to disconnect
args=()
rows=()
for i in "${!names[@]}"; do
    if [[ ${names[i]} == "$active" ]]; then
        args=(-a "$i" -selected-row "$i")
        rows+=("$(icon_row "$connected_icon" "${names[i]}")")
    else
        rows+=("$(icon_row "$vpn_icon" "${names[i]}")")
    fi
done
[[ -n $active ]] && rows+=("$(icon_row "$disconnect_icon" Disconnect)")

i=$(printf '%s\n' "${rows[@]}" | rofi_menu select_vpn -markup-rows -format i "${args[@]}")
[[ -z $i ]] && exit 0
chosen=${names[i]}

[[ $chosen == "$active" ]] && exit 0

if [[ -n $active ]]; then
    nm_run "Disconnecting from $active" nmcli connection down "$active" || exit 1
fi

if (( i < ${#names[@]} )); then
    nm_run "Connecting to $chosen" nmcli connection up "$chosen"
fi
