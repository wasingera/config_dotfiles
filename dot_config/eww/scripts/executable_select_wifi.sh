#!/usr/bin/env bash

# Pick a Wi-Fi network in range to join, or disconnect, rescan, or turn the
# radio off. New secured networks get a password prompt.
source "${BASH_SOURCE%/*}/lib.sh"

# Nerd Font signal bars: 1-4 bars, then the same with a lock
bars=($'\U000F091F' $'\U000F0922' $'\U000F0925' $'\U000F0928')
locked_bars=($'\U000F0920' $'\U000F0923' $'\U000F0926' $'\U000F0929')
disconnect_row=$'\U000F0156  Disconnect'
rescan_row=$'\U000F0450  Rescan'
off_row=$'\U000F0425  Turn Wi-Fi off'
on_row=$'\U000F05A9  Turn Wi-Fi on'

# Fills signal[ssid] and security[ssid] from the last scan, strongest access
# point per SSID, and active_ssid. --rescan no: a rescan takes ~8s.
declare -A signal security
active_ssid=
read_scan() {
    local inuse sig sec ssid
    # SSID last, so a ':' inside it (escaped by nmcli as '\:') stays in it
    while IFS=: read -r inuse sig sec ssid; do
        ssid=${ssid//\\:/:}
        [[ -z $ssid ]] && continue # hidden network
        [[ $inuse == '*' ]] && active_ssid=$ssid
        if (( sig > ${signal[$ssid]:--1} )); then
            signal[$ssid]=$sig
            security[$ssid]=$sec
        fi
    done < <(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan no)
}

# One menu row: signal bars (locked if secured), then the SSID
row() {
    local level=$(( ${signal[$1]} >= 75 ? 3 : ${signal[$1]} >= 50 ? 2 : ${signal[$1]} >= 25 ? 1 : 0 ))
    if [[ -n ${security[$1]} ]]; then
        printf '%s  %s\n' "${locked_bars[level]}" "$1"
    else
        printf '%s  %s\n' "${bars[level]}" "$1"
    fi
}

# The UUID of the saved profile for an SSID, if there is one
saved_profile() {
    local uuid
    while read -r uuid; do
        if [[ $(nmcli -g 802-11-wireless.ssid connection show "$uuid") == "$1" ]]; then
            printf '%s\n' "$uuid"
            return
        fi
    done < <(nmcli -t -f TYPE,UUID connection show | sed -n 's/^802-11-wireless://p')
}

# Ask for the password of SSID and bring up profile UUID with it. nmcli reads
# it from a file descriptor rather than its arguments, so it never shows up
# in the process list.
connect_with_password() {
    local uuid=$1 ssid=$2 password
    password=$(rofi_menu wifi_password -password -p "Password for $ssid" </dev/null)
    [[ -z $password ]] && return 1
    nm_run "Connecting to $ssid" "Connected to $ssid" \
        nmcli connection up "$uuid" passwd-file \
        <(printf '802-11-wireless-security.psk:%s\n' "$password")
}

connect() {
    local ssid=$1 sec=${security[$1]} uuid key_mgmt
    uuid=$(saved_profile "$ssid")

    if [[ -n $uuid ]]; then
        nm_run "Connecting to $ssid" "Connected to $ssid" nmcli connection up "$uuid" && return
        # The saved password is missing or wrong
        if [[ $nm_error == *[Ss]ecrets* && -n $sec ]]; then
            connect_with_password "$uuid" "$ssid"
        fi
        return
    fi

    case $sec in
        "")
            nm_run "Connecting to $ssid" "Connected to $ssid" nmcli dev wifi connect "$ssid"
            return
            ;;
        *802.1X* | *WEP*)
            notify-send -u critical "Can't join $ssid from here" \
                "$sec networks need setting up with nmtui"
            return 1
            ;;
        *WPA1* | *WPA2*) key_mgmt=wpa-psk ;;
        *WPA3*) key_mgmt=sae ;;
        *) key_mgmt=wpa-psk ;;
    esac

    uuid=$(nmcli connection add type wifi con-name "$ssid" \
        ssid "$ssid" wifi-sec.key-mgmt "$key_mgmt") || return 1
    uuid=$(grep -oE '[0-9a-f-]{36}' <<<"$uuid")
    # Don't leave a profile with no (or a wrong) password behind
    connect_with_password "$uuid" "$ssid" || nmcli connection delete "$uuid" >/dev/null
}

if [[ $(nmcli radio wifi) != enabled ]]; then
    chosen=$(printf '%s\n' "$on_row" | rofi_menu select_wifi)
    if [[ $chosen == "$on_row" ]]; then
        nm_run "Turning Wi-Fi on" "Wi-Fi on" nmcli radio wifi on
    fi
    exit
fi

read_scan

# The 10 strongest, strongest first, but the connected network on top, marked
# and selected
mapfile -t ssids < <(
    for s in "${!signal[@]}"; do printf '%s\t%s\n' "${signal[$s]}" "$s"; done |
        sort -t $'\t' -k1,1nr | cut -f2- | grep -vxF -- "$active_ssid"
)
args=()
if [[ -n $active_ssid ]]; then
    ssids=("$active_ssid" "${ssids[@]}")
    args=(-a 0 -selected-row 0)
fi
ssids=("${ssids[@]:0:10}")

footer=()
[[ -n $active_ssid ]] && footer+=("$disconnect_row")
footer+=("$rescan_row" "$off_row")

i=$({ for s in "${ssids[@]}"; do row "$s"; done; printf '%s\n' "${footer[@]}"; } |
    rofi_menu select_wifi -format i "${args[@]}")
[[ -z $i ]] && exit 0

if (( i < ${#ssids[@]} )); then
    [[ ${ssids[i]} == "$active_ssid" ]] && exit 0
    connect "${ssids[i]}"
    exit
fi

case ${footer[i - ${#ssids[@]}]} in
    "$disconnect_row")
        active=$(nm_connections 802-11-wireless --active | head -n1)
        nm_run "Disconnecting from $active_ssid" "Disconnected from $active_ssid" \
            nmcli connection down "$active"
        ;;
    "$rescan_row")
        nm_run "Scanning for networks" "Scan finished" \
            nmcli dev wifi list --rescan yes
        exec "$0"
        ;;
    "$off_row")
        nm_run "Turning Wi-Fi off" "Wi-Fi off" nmcli radio wifi off
        ;;
esac
