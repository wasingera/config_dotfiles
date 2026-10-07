#!/usr/bin/env bash

# Prints {"usage": N, "temp": N} for eww: the NVIDIA GPU's utilisation (%) and
# temperature (°C). nvidia-smi samples every 2s itself, so this is one process
# rather than a poll; emit drops readings that didn't change. A value it can't
# read ([N/A], or an error message) shows as "--".
source "${BASH_SOURCE%/*}/lib.sh"

# nvidia-smi exits when it can't reach the driver, e.g. after a driver upgrade
# until the next reboot. Show "--" meanwhile and retry every 30s. Readings come
# in through < <(...) rather than a pipe, so the loop runs in this shell and
# emit knows when the last one already showed "--".
while :; do
    while IFS=', ' read -r usage temp; do
        emit "$(jq -nc --arg usage "$usage" --arg temp "$temp" '
            {usage: ($usage | tonumber? // "--"), temp: ($temp | tonumber? // "--")}')"
    done < <(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu \
                 --format=csv,noheader,nounits --loop=2 2>/dev/null)
    emit '{"usage":"--","temp":"--"}'
    sleep 30
done
