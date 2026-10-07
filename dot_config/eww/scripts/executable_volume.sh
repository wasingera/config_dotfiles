#!/usr/bin/env bash

# Prints {"volume": N, "muted": bool, "icon": ..., "sink": ...} for eww: the
# default output's volume, a matching icon and the output's name, now and
# again whenever it changes (volume keys, mute, switching devices, ...).
source "${BASH_SOURCE%/*}/lib.sh"

# Nerd Font icons: muted or 0, then low, medium, high
off_icon=$'\U000F0581'
low_icon=$'\U000F057F'
medium_icon=$'\U000F0580'
high_icon=$'\U000F057E'

render() {
    emit "$(pactl -f json list sinks | jq -c --arg default "$(pactl get-default-sink)" \
        --arg off "$off_icon" --arg low "$low_icon" \
        --arg medium "$medium_icon" --arg high "$high_icon" '
        first(.[] | select(.name == $default)) // {} |
        (first(.volume[]?.value_percent) // "0%" | rtrimstr("%") | tonumber) as $volume |
        (.mute // false) as $muted |
        {$volume, $muted,
         icon: (if $muted or $volume == 0 then $off
                elif $volume < 34 then $low
                elif $volume < 67 then $medium
                else $high end),
         sink: (.description // "No output")}')"
}

render
# Only sink and server events (default output changes are server events).
# pactl's own connections show up as client events, so reacting to those
# would re-render in an endless loop.
pactl subscribe | while read -r line; do
    case $line in
        *" on sink "* | *" on server "*)
            drain_burst
            render
            ;;
    esac
done
