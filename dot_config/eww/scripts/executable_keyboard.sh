#!/usr/bin/env bash

# Prints the main keyboard's layout for eww ("us" or "intl"), now and again
# whenever Hyprland reports a layout switch.
source "${BASH_SOURCE%/*}/lib.sh"

render() {
    case $(hyprctl devices -j | jq -r '.keyboards[] | select(.main).active_keymap') in
        "English (US)") emit us ;;
        *)              emit intl ;;
    esac
}

render
hypr_events | while read -r line; do
    if [[ ${line%%>>*} == activelayout ]]; then
        drain_burst
        render
    fi
done
