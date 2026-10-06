#!/usr/bin/env bash

rofi_command="rofi -theme $HOME/.config/rofi/select_vpn/theme.rasi -dmenu -hover-select"

vpn_names="$(nmcli -t connection show | awk -F: '{if ($3 == "wireguard") printf "%s\\n", $1}' | sort -u)"

# betterlockscreen -l
options="Disconnect\n"
options+="${vpn_names}"

chosen=`echo -e $options | $rofi_command -me-select-entry '' -me-accept-entry MousePrimary`
active_vpn=$(nmcli -t connection show --active | awk -F: '/wireguard/ {print $1}')

case "$chosen" in
    Disconnect)
        # if active vpn not empty
        if [ -n "$active_vpn" ]; then
            nmcli connection down "$active_vpn"
            if [ $? -ne 0 ]; then
                notify-send "Failed to disconnect from $active_vpn"
            fi
        fi
        ;;
    *)
        # if chosen is empty, exit the script
        if [ -z "$chosen" ]; then
            exit 0
        fi

        # If already connected to a VPN, then disconnect
        if [ -n "$active_vpn" ]; then
            nmcli con down "$active_vpn"
        fi
        #
        # if chosen is not empty and not "Disconnect", connect to the chosen VPN
        nmcli connection up $chosen
        if [ $? -ne 0 ]; then
            notify-send "Failed to connect to $chosen"
        fi
        ;;

esac
