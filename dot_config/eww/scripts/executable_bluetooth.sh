#!/usr/bin/env bash

# Prints {"icon": ..., "scanning": ...} for eww: a Nerd Font icon for
# Bluetooth off (or no adapter, or bluetoothd not running), on, or connected
# to a device, and whether an adapter is scanning for devices; now and again
# whenever BlueZ reports a change.
source "${BASH_SOURCE%/*}/lib.sh"

# Nerd Font icons
off_icon=$'\U000F00B2'
on_icon=$'\U000F00AF'
connected_icon=$'\U000F00B1'

render() {
    emit "$(bluez_objects | jq -c --arg off "$off_icon" --arg on "$on_icon" \
        --arg connected "$connected_icon" '
        {icon: (if any(.[]; .["org.bluez.Adapter1"].Powered) | not then $off
                elif any(.[]; .["org.bluez.Device1"].Connected) then $connected
                else $on end),
         scanning: any(.[]; .["org.bluez.Adapter1"].Discovering)}')"
}

render
# Only signals that can change the output: power, connections, scans starting
# or stopping, adapters and devices appearing or going, and bluetoothd
# starting or stopping; not the stream of signal strength updates during a
# scan. (dbus-monitor would need root to watch the system bus.)
gdbus monitor --system --dest org.bluez | while read -r line; do
    case $line in
        *"'Powered'"* | *"'Connected'"* | *"'Discovering'"* | \
            *.InterfacesAdded* | *.InterfacesRemoved* | "The name "*)
            drain_burst
            render
            ;;
    esac
done
