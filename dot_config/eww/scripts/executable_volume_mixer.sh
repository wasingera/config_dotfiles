#!/usr/bin/env bash

# Open the volume mixer popup under the bar button that was clicked, or close
# it if it's open.
source "${BASH_SOURCE%/*}/lib.sh"

if eww active-windows | grep -q '^volume_mixer:'; then
    eww close volume_mixer
    exit
fi

read -r right top < <(popup_anchor) || exit
eww open volume_mixer --arg top="$top" --arg right="$right"
