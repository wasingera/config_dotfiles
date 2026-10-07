#!/usr/bin/env bash

# Prints {"label": ..., "keymap": ...} for eww: a short name for the main
# keyboard's active layout (its xkb variant, or the layout code for the basic
# variant, e.g. "us" or "intl") and the full keymap name, now and again
# whenever Hyprland reports a layout switch.
source "${BASH_SOURCE%/*}/lib.sh"

render() {
    emit "$(hyprctl devices -j | jq -c '
        .keyboards | (first(.[] | select(.main)) // .[0]) // {} |
        (.active_layout_index // 0) as $i |
        ((.layout // "") / ",")[$i] as $layout |
        ((.variant // "") / ",")[$i] as $variant |
        {label: (if $variant == null or $variant == "" or $variant == "basic"
                 then $layout // "?" else $variant end),
         keymap: (.active_keymap // "")}')"
}

render
hypr_events | while read -r line; do
    if [[ ${line%%>>*} == activelayout ]]; then
        drain_burst
        render
    fi
done
