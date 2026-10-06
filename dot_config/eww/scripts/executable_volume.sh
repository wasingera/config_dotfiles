#!/usr/bin/env bash

# Prints {"volume": N, "muted": bool} for eww, now and again whenever the
# default output changes (volume keys, mute, switching devices, ...).
source "${BASH_SOURCE%/*}/lib.sh"

render() {
    emit "$(jq -nc --argjson volume "$(pamixer --get-volume)" \
                   --argjson muted "$(pamixer --get-mute)" '{$volume, $muted}')"
}

render
# Only sink and server events. pamixer's own connections show up as client
# events, so reacting to those would re-render in an endless loop.
pactl subscribe | while read -r line; do
    case $line in
        *" on sink "* | *" on server "*)
            drain_burst
            render
            ;;
    esac
done
