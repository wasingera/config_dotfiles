# Shared helpers for the eww scripts. Load with:
#   source "${BASH_SOURCE%/*}/lib.sh"

# Show a rofi menu using ~/.config/rofi/<theme>/theme.rasi.
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
    printf '%s' "$options" |
        rofi -theme "$HOME/.config/rofi/$theme/theme.rasi" \
            -theme-str "listview { lines: $(printf '%s' "$options" | wc -l); }" \
            -dmenu -hover-select -me-select-entry '' -me-accept-entry MousePrimary \
            -kb-cancel 'Escape,Control+g,Control+bracketleft,MousePrimary' "$@"
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
