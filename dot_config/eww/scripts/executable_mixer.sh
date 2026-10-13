#!/usr/bin/env bash

# Prints the volume mixer's state for eww, now and again whenever it changes:
#   {"outputs": [{"name", "label", "icon", "default"}],
#    "apps": [{"id", "name", "detail", "icon", "volume", "muted", "glyph"}],
#    "app_glyph": ...}
# outputs are the sinks, apps the streams playing into them (sink inputs).
# An app's icon is the path of its icon file, or "" when it has none, for
# which the popup shows app_glyph instead; its glyph is the speaker icon for its
# volume, as on the bar.
source "${BASH_SOURCE%/*}/lib.sh"

# Nerd Font icons by the sink's active port: HDMI/DisplayPort, headphones,
# anything else
hdmi_icon=$'\U000F0379'
headphones_icon=$'\U000F02CB'
speaker_icon=$'\U000F04C3'
# An app without an icon: a music note
app_icon=$'\U000F075A'
# An app's volume, as volume.sh: muted or 0, then low, medium, high
off_icon=$'\U000F0581'
low_icon=$'\U000F057F'
medium_icon=$'\U000F0580'
high_icon=$'\U000F057E'

# Set REPLY to the file of the icon named $1: Papirus's (as dunst uses), else
# hicolor's or a pixmap. eww's GTK icon theme is Adwaita, which lacks most
# apps, so the popup shows icons by path. Remembered per name; "" if none.
# (A variable rather than output, so the memory survives: $(...) is a subshell.)
declare -A icon_files
icon_file() {
    local files f
    if [[ ! -v icon_files[$1] ]]; then
        files=(/usr/share/icons/Papirus/64x64/apps/"$1".svg
            /usr/share/icons/hicolor/{scalable,256x256,128x128,64x64,48x48}/apps/"$1".{svg,png}
            /usr/share/pixmaps/"$1".{svg,png})
        icon_files[$1]=
        for f in "${files[@]}"; do
            [[ -f $f ]] && { icon_files[$1]=$f; break; }
        done
    fi
    REPLY=${icon_files[$1]}
}

render() {
    local state paths=() name
    state=$(jq -cn --arg default "$(pactl get-default-sink)" \
        --arg hdmi "$hdmi_icon" --arg headphones "$headphones_icon" \
        --arg speaker "$speaker_icon" --arg app "$app_icon" \
        --arg off "$off_icon" --arg low "$low_icon" \
        --arg medium "$medium_icon" --arg high "$high_icon" \
        --argjson sinks "$(pactl -f json list sinks)" \
        --argjson inputs "$(pactl -f json list sink-inputs)" '
        def percent: first(.volume[]?.value_percent) // "0%" | rtrimstr("%") | tonumber;
        {outputs: [$sinks[] |
            (.active_port as $p | first(.ports[] | select(.name == $p)).type // "none") as $type |
            {name, default: (.name == $default),
             label: (.properties["node.nick"] // .description),
             icon: (if $type == "HDMI" then $hdmi
                    elif $type == "Headphones" then $headphones
                    else $speaker end)}],
         app_glyph: $app,
         apps: [$inputs[] | .properties as $p | percent as $volume |
            {id: .index, muted: .mute, $volume,
             glyph: (if .mute or $volume == 0 then $off
                     elif $volume < 34 then $low
                     elif $volume < 67 then $medium
                     else $high end),
             name: ($p["application.name"] // $p["node.name"] // "Unknown"),
             detail: ($p["media.name"] // ""),
             icon: ($p["application.icon_name"] // $p["application.process.binary"] // "")}]}')
    # Icon names to files; "" (the fallback glyph) for those with none
    while read -r name; do
        REPLY=
        [[ -n $name ]] && icon_file "$name"
        paths+=("$REPLY")
    done < <(jq -r '.apps[].icon' <<< "$state")
    emit "$(jq -c 'reduce range(.apps | length) as $i (.; .apps[$i].icon = $ARGS.positional[$i])' \
        --args "${paths[@]}" <<< "$state")"
}

render
# Only sink, sink-input and server events (default output changes are server
# events). pactl's own connections show up as client events, so reacting to
# those would re-render in an endless loop.
pactl subscribe | while read -r line; do
    case $line in
        *" on sink "* | *" on sink-input "* | *" on server "*)
            drain_burst
            render
            ;;
    esac
done
