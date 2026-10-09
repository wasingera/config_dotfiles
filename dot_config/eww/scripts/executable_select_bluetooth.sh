#!/usr/bin/env bash

# Pick a Bluetooth device: a connected one to disconnect, a paired one to
# connect, or a new one found by a scan to pair with. Or scan, or turn
# Bluetooth off (or on).
#
# BlueZ is driven with busctl, and pairing goes through bt_pair.py, which
# brings the agent pairing needs. bluetoothctl is used only to scan:
# discovery lasts as long as the client that started it.
source "${BASH_SOURCE%/*}/lib.sh"
menu_anchor

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
stop_scan_row=$(icon_row $'\U000F04DB' 'Stop scanning')
off_row=$(icon_row $'\U000F0425' 'Turn Bluetooth off')
on_row=$(icon_row $'\U000F00AF' 'Turn Bluetooth on')

# On exit: remove the file of devices found by a scan, and un-mark the icon
found= busy=
cleanup() {
    [[ -n $found ]] && command rm -f "$found"
    [[ -n $busy ]] && eww update bluetooth_busy=false
}
trap cleanup EXIT

# Rather than notifications while connecting, pairing etc., mark the bar's
# Bluetooth icon busy until the script exits: it blinks, in a different
# colour from a scan.
mark_busy() {
    [[ -n $busy ]] && return
    busy=1
    eww update bluetooth_busy=true
}

# Run a command with the icon marked busy, and a critical notification with
# busctl's error (the part after its "...: ") if it fails
bt_run() {
    local doing=$1 error; shift
    mark_busy
    error=$("$@" 2>&1 >/dev/null) && return
    notify-send -u critical "${tag[@]}" "$doing failed" "${error##*: }"
    return 1
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
    bt_run "Connecting to $2" \
        busctl --system --timeout=30 call org.bluez "$1" org.bluez.Device1 Connect
}

# Pair with a device found by a scan ("just works" pairing, see bt_pair.py;
# a phone asks to confirm on its own screen), trust it so it can connect by
# itself later, then connect.
pair() {
    local path=$1 name=$2 error
    # A device from a scan expires
    if ! device_property "$path" Address >/dev/null; then
        notify-send -u critical "${tag[@]}" "$name is out of range" \
            "Scan again with it in pairing mode"
        return 1
    fi
    mark_busy
    if ! error=$("${BASH_SOURCE%/*}/bt_pair.py" "$path" 2>&1); then
        notify-send -u critical "${tag[@]}" "Pairing with $name failed" "$error"
        return 1
    fi
    busctl --system set-property org.bluez "$path" org.bluez.Device1 Trusted b true
    [[ $(device_property "$path" Connected) == true ]] || connect "$path" "$name"
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

# Choosing Scan starts a scan and shows the menu again at once (exec "$0"),
# with devices added as they're found. The scan goes on while that menu is
# shown, so devices in range keep their signal strength (BlueZ drops it when
# discovery stops) and don't expire before one is picked, and stops once it
# closes. Exported, for the menu after exec "$0".
stop_scan() {
    [[ -n $BT_SCAN_PID ]] && kill "$BT_SCAN_PID" 2>/dev/null
    unset BT_SCAN_PID
}

# BlueZ's devices on the adapter as "path<TAB>state<TAB>icon<TAB>name<TAB>
# battery %" lines, state being connected, paired or new. Pass "known" for
# connected devices then the other paired ones, or "new" for new ones with a
# name (found by a scan), strongest first. The battery level is last, as it
# may be empty: read would merge two tabs.
device_lines() {
    bluez_objects | jq -r --arg adapter "$adapter" --arg want "$1" '
        [to_entries[] | .key as $path |
         .value["org.bluez.Battery1"].Percentage as $battery |
         .value["org.bluez.Device1"] // empty | select(.Adapter == $adapter) |
         {$path, $battery, icon: (.Icon // "none"), name: .Alias, named: (.Name != null),
          rssi: (.RSSI // -999),
          state: (if .Connected then "connected" elif .Paired then "paired" else "new" end)}] |
        if $want == "known" then
            map(select(.state != "new")) | sort_by(.state != "connected", (.name | ascii_downcase))
        else
            map(select(.state == "new" and .named)) | sort_by(-.rssi)
        end |
        .[] | [.path, .state, .icon, .name, (.battery // "" | tostring)] | @tsv'
}

# Print the menu row for a device_lines line
device_row() {
    local path state icon name battery
    IFS=$'\t' read -r path state icon name battery <<<"$1"
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
    icon_row "$icon" "$name${battery:+  $battery%}"
}

# During a scan, for the menu: print a row for each new device with a name,
# the ones BlueZ already has, then each one as it's found (or gets a name),
# and append its device_lines line to FILE, to look up the row picked. Runs
# until killed, or the scan's 60s are up.
found_rows() {
    local file=$1 fd line
    local -A shown
    exec {fd}< <(exec timeout 60 gdbus monitor --system --dest org.bluez)
    # Double quotes: the monitor's pid now, as $! changes below
    trap "kill $! 2>/dev/null; exit" TERM
    show_new() {
        while IFS= read -r line; do
            [[ -n ${shown[${line%%$'\t'*}]} ]] && continue
            shown[${line%%$'\t'*}]=1
            printf '%s\n' "$line" >>"$file"
            device_row "$line"
        done < <(device_lines new)
    }
    show_new
    while read -r line <&"$fd"; do
        case $line in
            *.InterfacesAdded* | *"'Name'"*)
                drain_burst <&"$fd"
                show_new
                ;;
        esac
    done
}

adapter=$(bluez_objects |
    jq -r 'first(to_entries[] | select(.value["org.bluez.Adapter1"]) | .key) // empty')
if [[ -z $adapter ]]; then
    notify-send -u critical "${tag[@]}" "No Bluetooth adapter" "Or bluetoothd isn't running"
    exit 1
fi

if [[ $(busctl --system get-property org.bluez "$adapter" org.bluez.Adapter1 Powered) != 'b true' ]]; then
    chosen=$(printf '%s\n' "$on_row" | rofi_menu select_bluetooth -markup-rows)
    if [[ $chosen == "$on_row" ]]; then
        bt_run "Turning Bluetooth on" power_on
    fi
    exit
fi

mapfile -t devices < <(device_lines known)
rows=()
active=()
for i in "${!devices[@]}"; do
    rows+=("$(device_row "${devices[i]}")")
    [[ ${devices[i]} == *$'\t'connected$'\t'* ]] && active+=("$i")
done
# The scan row is last, so the devices a scan finds come in under it
if [[ -n $BT_SCAN_PID ]]; then
    footer=("$off_row" "$stop_scan_row")
else
    footer=("$off_row" "$scan_row")
fi

# Connected devices are marked
args=()
if (( ${#active[@]} )); then
    args=(-a "$(IFS=,; printf '%s' "${active[*]}")")
fi

# While scanning, found devices come in under the rest: room for a few
lines=$(( ${#rows[@]} + ${#footer[@]} ))
[[ -n $BT_SCAN_PID ]] && (( lines += 6 ))
found=$(mktemp)
i=$(rofi_menu_streamed select_bluetooth "$lines" -markup-rows -format i "${args[@]}" \
        < <(printf '%s\n' "${rows[@]}" "${footer[@]}"
            if [[ -n $BT_SCAN_PID ]]; then found_rows "$found"; fi)
    kill $! 2>/dev/null)
stop_scan
[[ -z $i ]] && exit 0

if (( i < ${#devices[@]} )); then
    IFS=$'\t' read -r path state _ name _ <<<"${devices[i]}"
    case $state in
        connected)
            bt_run "Disconnecting from $name" \
                busctl --system call org.bluez "$path" org.bluez.Device1 Disconnect
            ;;
        paired) connect "$path" "$name" ;;
    esac
    exit
fi

(( i -= ${#devices[@]} ))
if (( i >= ${#footer[@]} )); then
    IFS=$'\t' read -r path _ _ name _ < <(sed -n "$(( i - ${#footer[@]} + 1 ))p" "$found")
    pair "$path" "$name"
    exit
fi

case ${footer[i]} in
    "$scan_row")
        bluetoothctl --timeout 60 scan on </dev/null >/dev/null 2>&1 &
        export BT_SCAN_PID=$!
        command rm -f "$found" # exec skips the EXIT trap
        exec "$0"
        ;;
    "$stop_scan_row")
        command rm -f "$found"
        exec "$0"
        ;;
    "$off_row")
        bt_run "Turning Bluetooth off" \
            busctl --system set-property org.bluez "$adapter" org.bluez.Adapter1 Powered b false
        ;;
esac
