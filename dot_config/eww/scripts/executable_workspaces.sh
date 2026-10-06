#!/usr/bin/env bash

# Prints JSON for eww: "icons" has one icon per workspace 1-10 (active,
# occupied, or empty); "special" is the special workspace's state
# (empty/occupied/open), used as a CSS class for the border.
source "${BASH_SOURCE%/*}/lib.sh"

render() {
    local active special_open
    active=$(hyprctl activeworkspace -j | jq '.id')
    special_open=$(hyprctl monitors -j | jq 'any(.[]; .specialWorkspace.name == "special:magic")')
    emit "$(hyprctl clients -j | jq -c --argjson a "$active" --argjson open "$special_open" '
        . as $clients
        | [.[].workspace.id] as $ids
        | [range(1; 11) as $i
            | if $i == $a then ""
              elif ($ids | any(. == $i)) then ""
              else "" end]
        | {
            icons: .,
            special: (if $open then "open"
                      elif any($clients[]; .workspace.name == "special:magic") then "occupied"
                      else "empty" end)
          }')"
}

render

hypr_events | while read -r line; do
    case "${line%%>>*}" in
        workspace|workspacev2|focusedmon|focusedmonv2|openwindow|closewindow|movewindow|movewindowv2|createworkspace|destroyworkspace|activespecial)
            drain_burst
            render
            ;;
    esac
done
