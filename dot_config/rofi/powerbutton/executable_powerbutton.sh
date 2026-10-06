#!/bin/bash

if [[ "$@" == "  Shutdown" ]]; then
    sudo poweroff
    exit 0;
elif [[ "$@" == "  Restart" ]]; then
    sudo reboot
    exit 0;
elif [[ "$@" == " Lock" ]]; then
    hyprlock
    # exec betterlockscreen -l
    # betterlockscreen -l
    # exec lock.sh
fi

echo "  Shutdown"
echo "  Restart"
echo "  Lock"
