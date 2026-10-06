# Shared helpers for the eww scripts. Load with:
#   source "${BASH_SOURCE%/*}/lib.sh"

# Show a rofi menu using ~/.config/rofi/<theme>/theme.rasi.
# Reads the options from stdin, one per line, and prints the chosen one
# (nothing if the menu was dismissed).
rofi_menu() {
    rofi -theme "$HOME/.config/rofi/$1/theme.rasi" -dmenu -hover-select \
        -me-select-entry '' -me-accept-entry MousePrimary
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
