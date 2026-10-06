#!/usr/bin/env bash

rofi_command="rofi -theme $HOME/.config/rofi/select_wifi/theme.rasi -dmenu -hover-select"

wifi_names="$(nmcli -t connection show | awk -F: '{if ($3 ~ /wireless/) print $1}' | sort -u)"

options="Disconnect\n${wifi_names}"

chosen=`echo -e $options | $rofi_command -me-select-entry '' -me-accept-entry MousePrimary`
active_wifi=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

case "$chosen" in
    Disconnect)
        if [ -n "$active_wifi" ]; then
            nmcli connection down "$active_wifi"
            if [ $? -ne 0 ]; then
                notify-send "Failed to disconnect from ${active_wifi}"
            fi
        fi
        ;;
    *)
        if [ -z "$chosen" ]; then
            exit 0
        fi

        nmcli connection up "$chosen"

        if [ $? -ne 0 ]; then
            notify-send "Failed to connect to ${chosen}"
        fi
        ;;
esac
