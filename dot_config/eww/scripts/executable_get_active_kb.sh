#!/bin/bash

result=""

active_kb=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true).active_keymap')

if [[ "$active_kb" == "English (US)" ]]; then
    result="us"
else
    result="intl"
fi

echo $result
