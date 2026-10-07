#!/usr/bin/env bash

# Prints a short name for the main keyboard's active layout for eww: its xkb
# variant, or the layout code for the basic variant (e.g. "us" or "intl"),
# now and again whenever Hyprland reports a layout switch.
source "${BASH_SOURCE%/*}/lib.sh"

render() {
    emit "$(hyprctl devices -j | jq -r '
        .keyboards | (first(.[] | select(.main)) // .[0]) // {} |
        (.active_layout_index // 0) as $i |
        ((.layout // "") / ",")[$i] as $layout |
        ((.variant // "") / ",")[$i] as $variant |
        if $variant == null or $variant == "" or $variant == "basic"
        then $layout // "?" else $variant end')"
}

render
hypr_events | while read -r line; do
    if [[ ${line%%>>*} == activelayout ]]; then
        drain_burst
        render
    fi
done
