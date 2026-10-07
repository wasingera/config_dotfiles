#!/usr/bin/env bash

# Pick a Bluetooth device: a connected one to disconnect, a paired one to
# connect, or a new one found by a scan to pair with. Or scan, or turn
# Bluetooth off (or on).
#
# BlueZ is driven with busctl, except where bluetoothctl's live client is
# needed: discovery lasts only as long as the client that started it, and
# pairing needs an agent. bluetoothctl can hang on errors, so it runs under
# timeout and the outcome is read back from BlueZ.
source "${BASH_SOURCE%/*}/lib.sh"

tag=(-h string:x-dunst-stack-tag:bluetooth)

# Nerd Font icons by BlueZ's icon name for the device, then the other rows
headphones_icon=$'\U000F02CB'
speaker_icon=$'\U000F04C3'
keyboard_icon=$'\U000F030C'
mouse_icon=$'\U000F037D'
gamepad_icon=$'\U000F0297'
phone_icon=$'\U000F011C'
computer_icon=$'\U000F0322'
device_icon=$'\U000F00AF'
scan_row=$(icon_row $'\U000F0450' 'Scan for devices')
off_row=$(icon_row $'\U000F0425' 'Turn Bluetooth off')
on_row=$(icon_row $'\U000F00AF' 'Turn Bluetooth on')

# Run a command with notifications, like nm_run: DOING while it runs, then
# DONE, or a critical one with busctl's error (the part after its "...: ")
bt_run() {
    local doing=$1 done=$2 error; shift 2
    notify-send -u low "${tag[@]}" "$doing…"
    if error=$("$@" 2>&1 >/dev/null); then
        notify-send -u low "${tag[@]}" "$done"
    else
        notify-send -u critical "${tag[@]}" "$doing failed" "${error##*: }"
        return 1
    fi
}

# Print one of a device's properties (true, an address, ...). Fails if
# BlueZ no longer has the device.
device_property() {
    local value
    value=$(busctl --system get-property org.bluez "$1" org.bluez.Device1 "$2" 2>/dev/null) ||
        return
    value=${value#* } # the type, e.g. "s "
    printf '%s\n' "${value//\"/}"
}

connect() {
    bt_run "Connecting to $2" "Connected to $2" \
        busctl --system --timeout=30 call org.bluez "$1" org.bluez.Device1 Connect
}

# Pair with a device found by a scan, trust it so it can connect by itself
# later, then connect. bluetoothctl's agent does the pairing; NoInputNoOutput
# makes it "just works" pairing, as there's nowhere to show a PIN (a phone
# asks to confirm on its own screen).
pair() {
    local path=$1 name=$2 address output error
    # A device from a scan expires; bluetoothctl would hang on it
    if ! address=$(device_property "$path" Address); then
        notify-send -u critical "${tag[@]}" "$name is out of range" \
            "Scan again with it in pairing mode"
        return 1
    fi
    notify-send -u low "${tag[@]}" "Pairing with $name…"
    output=$(timeout 30 bluetoothctl --agent NoInputNoOutput pair "$address" </dev/null 2>&1)
    if [[ $(device_property "$path" Paired) != true ]]; then
        error=$(grep -ao 'Failed to pair: [[:print:]]*' <<<"$output" | tail -n1)
        error=${error#Failed to pair: }
        notify-send -u critical "${tag[@]}" "Pairing with $name failed" \
            "${error:-No answer; is it in pairing mode?}"
        return 1
    fi
    busctl --system set-property org.bluez "$path" org.bluez.Device1 Trusted b true
    if [[ $(device_property "$path" Connected) == true ]]; then
        notify-send -u low "${tag[@]}" "Connected to $name"
    else
        connect "$path" "$name"
    fi
}

# Unblock the radio if it's soft-blocked (bluetoothd then powers the adapter
# on by itself; powering it on while blocked fails), else power it on
power_on() {
    if rfkill -n -o SOFT list bluetooth | grep -qx blocked; then
        rfkill unblock bluetooth || return
        for _ in {1..20}; do
            [[ $(busctl --system get-property org.bluez "$adapter" \
                org.bluez.Adapter1 Powered 2>/dev/null) == 'b true' ]] && return
            sleep 0.1
        done
    fi
    busctl --system set-property org.bluez "$adapter" org.bluez.Adapter1 Powered b true
}

# A scan started from the menu goes on while the menu is shown again, so
# devices in range keep their signal strength (BlueZ drops it when discovery
# stops) and don't expire before one is picked. It stops once that menu
# closes. Exported, as the menu comes back through exec "$0".
stop_scan() {
    [[ -n $BT_SCAN_PID ]] && kill "$BT_SCAN_PID" 2>/dev/null
    unset BT_SCAN_PID
}

objects=$(bluez_objects)
adapter=$(jq -r 'first(to_entries[] | select(.value["org.bluez.Adapter1"]) | .key) // empty' \
    <<<"$objects")
if [[ -z $adapter ]]; then
    notify-send -u critical "${tag[@]}" "No Bluetooth adapter" "Or bluetoothd isn't running"
    exit 1
fi

if [[ $(jq --arg a "$adapter" '.[$a]["org.bluez.Adapter1"].Powered' <<<"$objects") != true ]]; then
    chosen=$(printf '%s\n' "$on_row" | rofi_menu select_bluetooth -markup-rows)
    if [[ $chosen == "$on_row" ]]; then
        bt_run "Turning Bluetooth on" "Bluetooth on" power_on
    fi
    exit
fi

# One "path<TAB>state<TAB>icon<TAB>name<TAB>battery %" line per device, state
# being connected, paired or new: connected devices, the other paired ones,
# then the 10 strongest new ones with a name (from a scan), in that order.
# The battery level is last, as it may be empty: read would merge two tabs.
mapfile -t devices < <(jq -r --arg adapter "$adapter" '
    [to_entries[] | .key as $path |
     .value["org.bluez.Battery1"].Percentage as $battery |
     .value["org.bluez.Device1"] // empty | select(.Adapter == $adapter) |
     {$path, $battery, icon: (.Icon // "none"), name: .Alias, named: (.Name != null),
      rssi: (.RSSI // -999),
      state: (if .Connected then "connected" elif .Paired then "paired" else "new" end)}] |
    (map(select(.state != "new")) | sort_by(.state != "connected", (.name | ascii_downcase))) +
    (map(select(.state == "new" and .named)) | sort_by(-.rssi) | .[:10]) |
    .[] | [.path, .state, .icon, .name, (.battery // "" | tostring)] | @tsv' <<<"$objects")

rows=()
active=()
for i in "${!devices[@]}"; do
    IFS=$'\t' read -r path state icon name battery <<<"${devices[i]}"
    case $icon in
        audio-headset | audio-headphones) icon=$headphones_icon ;;
        audio-card)                       icon=$speaker_icon ;;
        input-keyboard)                   icon=$keyboard_icon ;;
        input-mouse)                      icon=$mouse_icon ;;
        input-gaming)                     icon=$gamepad_icon ;;
        phone)                            icon=$phone_icon ;;
        computer)                         icon=$computer_icon ;;
        *)                                icon=$device_icon ;;
    esac
    rows+=("$(icon_row "$icon" "$name${battery:+  $battery%}")")
    [[ $state == connected ]] && active+=("$i")
done
footer=("$scan_row" "$off_row")

# Connected devices are marked
args=()
if (( ${#active[@]} )); then
    args=(-a "$(IFS=,; printf '%s' "${active[*]}")")
fi

i=$(printf '%s\n' "${rows[@]}" "${footer[@]}" |
    rofi_menu select_bluetooth -markup-rows -format i "${args[@]}")
stop_scan
[[ -z $i ]] && exit 0

if (( i < ${#devices[@]} )); then
    IFS=$'\t' read -r path state _ name _ <<<"${devices[i]}"
    case $state in
        connected)
            bt_run "Disconnecting from $name" "Disconnected from $name" \
                busctl --system call org.bluez "$path" org.bluez.Device1 Disconnect
            ;;
        paired) connect "$path" "$name" ;;
        new) pair "$path" "$name" ;;
    esac
    exit
fi

case ${footer[i - ${#devices[@]}]} in
    "$scan_row")
        bluetoothctl --timeout 60 scan on </dev/null >/dev/null 2>&1 &
        export BT_SCAN_PID=$!
        bt_run "Scanning for devices" "Scan finished" sleep 10
        exec "$0"
        ;;
    "$off_row")
        bt_run "Turning Bluetooth off" "Bluetooth off" \
            busctl --system set-property org.bluez "$adapter" org.bluez.Adapter1 Powered b false
        ;;
esac
