#!/usr/bin/env bash

# Prints {"active": bool, "playing": bool, "icon": ..., "text": ...} for eww:
# the current media player's state and "Artist – Title", now and again
# whenever it changes. The player is the one plain playerctl acts on, so the
# last active one while playerctld runs, like the media keys.
source "${BASH_SOURCE%/*}/lib.sh"

# Nerd Font icons: playing, paused
play_icon=$'\U000F040A'
pause_icon=$'\U000F03E4'

# Field separator: not whitespace, so read keeps an empty artist as a field
# rather than merging it into the next separator
sep=$'\x1f'

render() {
    local player status artist title
    IFS=$sep read -r player status artist title < <(playerctl metadata \
        --format "{{playerName}}$sep{{status}}$sep{{artist}}$sep{{title}}" 2>/dev/null)
    # jq builds the JSON: titles can contain quotes and backslashes
    emit "$(jq -cn --arg player "$player" --arg status "$status" \
        --arg artist "$artist" --arg title "$title" \
        --arg play "$play_icon" --arg pause "$pause_icon" '
        ($status == "Playing") as $playing |
        ([$artist, $title] | map(select(. != "")) | join(" – ")) as $text |
        {active: ($playing or $status == "Paused"), $playing,
         icon: (if $playing then $play else $pause end),
         text: (if $text == "" then $player else $text end)}')"
}

render
# Signals from any player or playerctld (properties, which player is active)
# and players appearing or quitting. Each signal is several lines; only the
# header line starts with "signal". playerctl only reads properties, so
# rendering sends no signals that would loop back here.
dbus-monitor --session \
    "type='signal',path='/org/mpris/MediaPlayer2'" \
    "type='signal',interface='org.freedesktop.DBus',member='NameOwnerChanged',arg0namespace='org.mpris.MediaPlayer2'" |
    while read -r line; do
        if [[ $line == signal* ]]; then
            drain_burst
            render
        fi
    done
