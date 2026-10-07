# Shared helpers for the eww scripts. Load with:
#   source "${BASH_SOURCE%/*}/lib.sh"

# Show a rofi menu using ~/.config/rofi/<theme>/theme.rasi, hanging from the
# bar button that was clicked (see menu_anchor).
# Reads the options from stdin, one per line, and prints the chosen one
# (nothing if the menu was dismissed). Extra arguments go to rofi, e.g.
# -a 0 (mark row 0 active), -selected-row 0, -format i (print the index).
# The themes cover the screen with a transparent window (rofi/dropdown.rasi),
# so binding MousePrimary to cancel closes the menu on a click outside it;
# clicks on an entry are taken by me-accept-entry first.
rofi_menu() {
    local theme=$1 options nl=$'\n'; shift
    options=$(cat)
    # No options (a prompt) means no lines, rather than one empty one
    options=${options:+$options$nl}
    menu_anchor
    printf '%s' "$options" |
        rofi -theme "$HOME/.config/rofi/$theme/theme.rasi" \
            -theme-str "listview { lines: $(printf '%s' "$options" | wc -l); } $MENU_ANCHOR" \
            -dmenu -hover-select -me-select-entry '' -me-accept-entry MousePrimary \
            -kb-cancel 'Escape,Control+g,Control+bracketleft,MousePrimary' "$@"
}

# Set MENU_ANCHOR to rofi theme lines that put the menu under the bar button
# beneath the pointer, flush with its right edge (bar_anchor.py has the
# geometry). Found once per script and exported: later menus, e.g. a password
# prompt or the menu again after exec "$0", open in the same spot while the
# pointer is over the first one.
menu_anchor() {
    local right top
    [[ -n $MENU_ANCHOR ]] && return
    read -r right top < <("${BASH_SOURCE%/*}/bar_anchor.py") || return
    export MENU_ANCHOR="menu-row { padding: ${top}px ${right}px 0px 0px; }"
}

# Print a menu row: a Nerd Font icon, enlarged to match the text, then TEXT.
# The row is pango markup, so pass rofi_menu -markup-rows.
icon_row() {
    local text=$2
    text=${text//'&'/'&amp;'} text=${text//'<'/'&lt;'} text=${text//'>'/'&gt;'}
    printf '<span size="larger">%s</span>  %s\n' "$1" "$text"
}

# Run an nmcli command with notifications: DOING while it runs, then DONE, or
# a critical one with nmcli's error. They share a stack tag, so each replaces
# the last. Returns the command's status; the error is left in $nm_error.
#   nm_run "Connecting to X" "Connected to X" nmcli connection up X
nm_run() {
    local doing=$1 done=$2; shift 2
    local tag=(-h string:x-dunst-stack-tag:network)
    notify-send -u low "${tag[@]}" "$doing…"
    if nm_error=$("$@" 2>&1 >/dev/null); then
        notify-send -u low "${tag[@]}" "$done"
    else
        nm_error=${nm_error#Error: }
        nm_error=${nm_error%%$'\n'Hint:*}
        notify-send -u critical "${tag[@]}" "$doing failed" "$nm_error"
        return 1
    fi
}

# Print the names of NetworkManager connections of one type (e.g. wireguard,
# 802-11-wireless), one per line. Pass --active for connected ones only.
nm_connections() {
    local want=$1 type name; shift
    # NAME last, so a ':' inside a name (escaped by nmcli as '\:') stays in it
    nmcli -t -f TYPE,NAME connection show "$@" |
        while IFS=: read -r type name; do
            if [[ $type == "$want" ]]; then printf '%s\n' "${name//\\:/:}"; fi
        done
}

# Print BlueZ's objects as one JSON object, {path: {interface: {property:
# value}}}, or {} if bluetoothd isn't running. A plain D-Bus method call: it
# emits no signals, so a listener can make it on every event, and unlike
# bluetoothctl it can't hang.
bluez_objects() {
    busctl --system --json=short call org.bluez / \
        org.freedesktop.DBus.ObjectManager GetManagedObjects 2>/dev/null |
        jq -cn '(input? // {data: [{}]}).data[0] | map_values(map_values(map_values(.data)))'
}

# After an event line, skip the rest of its burst (until 50ms of quiet) so a
# listener re-renders once, on the final state rather than a half-applied one.
drain_burst() {
    while read -r -t 0.05 _; do :; done
}

# Print a widget's new state, unless it's the same as the last one printed.
emit() {
    [[ $1 == "$_last_emit" ]] && return
    _last_emit=$1
    printf '%s\n' "$1"
}

# Stream Hyprland's events, one "event>>data" line each.
hypr_events() {
    socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
}
