#!/usr/bin/env bash

# Pick the default audio output. PipeWire moves playing streams to it.
source "${BASH_SOURCE%/*}/lib.sh"

# Nerd Font icons by the sink's active port: HDMI/DisplayPort, headphones,
# anything else
hdmi_icon=$'\U000F0379'
headphones_icon=$'\U000F02CB'
speaker_icon=$'\U000F04C3'

default=$(pactl get-default-sink)
# One "name<TAB>port type<TAB>label" line per sink
mapfile -t sinks < <(pactl -f json list sinks | jq -r '.[] |
    (.active_port as $p | first(.ports[] | select(.name == $p)).type // "") as $type |
    [.name, $type, .properties["node.nick"] // .description] | @tsv')

args=()
rows=()
names=()
for i in "${!sinks[@]}"; do
    IFS=$'\t' read -r name type label <<< "${sinks[i]}"
    names+=("$name")
    case $type in
        HDMI)       icon=$hdmi_icon ;;
        Headphones) icon=$headphones_icon ;;
        *)          icon=$speaker_icon ;;
    esac
    rows+=("$(icon_row "$icon" "$label")")
    [[ $name == "$default" ]] && args=(-a "$i" -selected-row "$i")
done

i=$(printf '%s\n' "${rows[@]}" | rofi_menu select_output -markup-rows -format i "${args[@]}")
[[ -z $i || ${names[i]} == "$default" ]] && exit 0
pactl set-default-sink "${names[i]}"
