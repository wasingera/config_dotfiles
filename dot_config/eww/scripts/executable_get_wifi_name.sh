#!/bin/bash

# Get the name of the active Wi-Fi connection, otherwise print "Disconnected"
# --rescan no: without it nmcli triggers a Wi-Fi scan each call (~8s)
active_wifi=$(nmcli -t -f active,ssid dev wifi list --rescan no | grep '^yes' | cut -d: -f2)
if [ -z "$active_wifi" ]; then
    echo "Disconnected"
else
    echo "$active_wifi"
fi

