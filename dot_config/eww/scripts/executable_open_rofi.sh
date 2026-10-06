#!/usr/bin/env bash

rofi_command="rofi -theme $HOME/.config/rofi/powerbutton/theme.rasi -dmenu -hover-select"

shutdown=" Shutdown"
restart=" Restart"
lock=" Lock"
logout="󰍃 Logout"

# betterlockscreen -l
options="$shutdown\n$restart\n$lock\n$logout"
chosen=`echo -e $options | $rofi_command -me-select-entry '' -me-accept-entry MousePrimary`

case "$chosen" in
    $shutdown)
        systemctl poweroff
        ;;
    $restart)
        systemctl reboot
        ;;
    $lock)
        hyprlock
        ;;
    $logout)
        loginctl terminate-user $(whoami)
        ;;
esac
# rofi -show power -modi power:$HOME/.config/rofi/powerbutton/powerbutton.sh \
#     -theme $HOME/.config/rofi/powerbutton/theme.rasi \
#     -hover-select -me-select-entry '' -me-accept-entry MousePrimary
