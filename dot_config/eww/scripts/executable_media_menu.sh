#!/usr/bin/env bash

# Controls for the current media player, the one plain playerctl acts on:
# previous, play/pause, next, and switching to the next player when there
# are several (playerctld keeps them in order of last activity).
source "${BASH_SOURCE%/*}/lib.sh"
menu_anchor

# Nerd Font icons
previous_icon=$'\U000F04AE'
play_icon=$'\U000F040A'
pause_icon=$'\U000F03E4'
next_icon=$'\U000F04AD'
switch_icon=$'\U000F04E1'

# Rows and their icons, in menu order; the action is picked by row number
if [[ $(playerctl status 2>/dev/null) == Playing ]]; then
    labels=(Previous Pause Next)
    icons=("$previous_icon" "$pause_icon" "$next_icon")
else
    labels=(Previous Play Next)
    icons=("$previous_icon" "$play_icon" "$next_icon")
fi
# Current player first, so shift makes the second one current. Names are
# e.g. chromium.instance1234: show only the program.
mapfile -t players < <(playerctl -l 2>/dev/null)
if (( ${#players[@]} > 1 )); then
    labels+=("Switch to ${players[1]%%.*}")
    icons+=("$switch_icon")
fi

i=$(for j in "${!labels[@]}"; do icon_row "${icons[j]}" "${labels[j]}"; done |
    rofi_menu media -markup-rows -format i -selected-row 1)
case $i in
    0) playerctl previous ;;
    1) playerctl play-pause ;;
    2) playerctl next ;;
    3) playerctld shift ;;
esac
