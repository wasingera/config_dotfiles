#!/usr/bin/env bash

# Open the notification history popup under the bar button that was clicked,
# or close it if it's open, and mark every notification in it seen.
seen_file=${XDG_STATE_HOME:-$HOME/.local/state}/eww/notifications-seen
fifo=${XDG_RUNTIME_DIR:-/tmp}/eww-notifications.fifo

if eww active-windows | grep -q '^notification_history:'; then
    eww close notification_history
    exit
fi

# Where the menus hang from the button: see bar_anchor.py
read -r right top < <("${BASH_SOURCE%/*}/bar_anchor.py") || exit
# The popup's window starts below the space the bar reserves (layer-shell
# keeps it out of other surfaces' exclusive zones), not at the monitor's top
top=$(( top - $(hyprctl -j monitors | jq '.[] | select(.id == 0).reserved[1]') ))

# The ID notifications.sh shows as newest, with dunst's D-Bus name, so it
# knows a restarted dunst's IDs aren't the ones seen
owner=$(gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus \
    --method org.freedesktop.DBus.GetNameOwner org.freedesktop.Notifications 2>/dev/null)
mkdir -p "${seen_file%/*}"
printf '%s %s\n' "$(eww get notifications | jq '.newest')" "$owner" > "$seen_file"
# Wake notifications.sh to clear the count. Opened read-write, so this can't
# block if it isn't running.
[[ -p $fifo ]] && echo seen 1<> "$fifo"

eww open notification_history --arg top="$top" --arg right="$right"
