#!/usr/bin/env bash

source "${BASH_SOURCE%/*}/lib.sh"

shutdown=" Shutdown"
restart=" Restart"
lock=" Lock"
logout="󰍃 Logout"

chosen=$(printf '%s\n' "$shutdown" "$restart" "$lock" "$logout" | rofi_menu powerbutton)

case "$chosen" in
    "$shutdown") systemctl poweroff ;;
    "$restart")  systemctl reboot ;;
    "$lock")     hyprlock ;;
    "$logout")   loginctl terminate-user "$USER" ;;
esac
