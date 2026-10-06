#!/bin/bash

# Prints JSON for eww: "icons" has one icon per workspace 1-10 (active,
# occupied, or empty); "special" is the special workspace's state
# (empty/occupied/open), used as a CSS class for the border.
render() {
    local active special_open
    active=$(hyprctl activeworkspace -j | jq '.id')
    special_open=$(hyprctl monitors -j | jq 'any(.[]; .specialWorkspace.name == "special:magic")')
    hyprctl clients -j | jq -c --argjson a "$active" --argjson open "$special_open" '
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
          }'
}

render

socat -U - UNIX-CONNECT:${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock | while read -r line
do
    case "${line%%>>*}" in
        workspace|workspacev2|focusedmon|focusedmonv2|openwindow|closewindow|movewindow|movewindowv2|createworkspace|destroyworkspace|activespecial)
            # One action fires a burst of events; wait for it to finish so we
            # render the final state, not a half-applied one.
            while read -r -t 0.05 line; do :; done
            render ;;
    esac
done
