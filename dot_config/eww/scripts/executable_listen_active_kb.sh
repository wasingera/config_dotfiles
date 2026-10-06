#!/bin/bash

echo $(./scripts/get_active_kb.sh)

socat -U - UNIX-CONNECT:${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock | while read -r line
do
    result=""

    event=$(awk -F '>>' '{print $1}' <<< $line)
    data=$(awk -F '>>' '{print $2}' <<< $line)

    if [[ "$event" != "activelayout" ]]; then
        continue
    fi

    echo $(./scripts/get_active_kb.sh)
done

