#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/lib.sh"

# Rows and their Nerd Font icons, in menu order
labels=(Shutdown Restart Lock Logout)
icons=($'\U000F0425' $'\U000F0709' $'\U000F033E' $'\U000F0343')

i=$(for j in "${!labels[@]}"; do icon_row "${icons[j]}" "${labels[j]}"; done |
    rofi_menu powerbutton -markup-rows -format i)
[[ -z $i ]] && exit 0

case ${labels[i]} in
    Shutdown) systemctl poweroff ;;
    Restart)  systemctl reboot ;;
    Lock)     hyprlock ;;
    # Same as SUPER+M: exit Hyprland only, not the user's other sessions
    Logout)   hyprctl dispatch 'hl.dsp.exit()' ;;
esac
