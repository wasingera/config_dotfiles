#!/usr/bin/env bash

# Pick a saved Wi-Fi connection to switch to, or disconnect the active one.
source "${BASH_SOURCE%/*}/lib.sh"

active=$(nm_connections 802-11-wireless --active | head -n1)
chosen=$({ echo Disconnect; nm_connections 802-11-wireless | sort -u; } | rofi_menu select_wifi)

case "$chosen" in
    "")
        ;;
    Disconnect)
        if [[ -n $active ]]; then
            nmcli connection down "$active" || notify-send "Failed to disconnect from $active"
        fi
        ;;
    *)
        nmcli connection up "$chosen" || notify-send "Failed to connect to $chosen"
        ;;
esac
