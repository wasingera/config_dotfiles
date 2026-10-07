#!/usr/bin/env bash

# Prints {"usage": N, "temp": N} for eww: the NVIDIA GPU's utilisation (%) and
# temperature (°C). nvidia-smi samples every 2s itself, so this is one process
# rather than a poll; emit drops readings that didn't change.
source "${BASH_SOURCE%/*}/lib.sh"

nvidia-smi --query-gpu=utilization.gpu,temperature.gpu \
    --format=csv,noheader,nounits --loop=2 |
    while IFS=', ' read -r usage temp; do
        emit "$(jq -nc --argjson usage "$usage" --argjson temp "$temp" '{$usage, $temp}')"
    done
