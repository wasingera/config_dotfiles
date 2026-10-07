#!/usr/bin/env bash

# Prints {"icon": ..., "unseen": N, "newest": ID, "entries": [...]} for eww:
# dunst's notification history, newest first, and how many of those came in
# since the history popup was last opened; now and again whenever it changes.
# Each entry is {id, app, summary, body, time}, as plain text.
source "${BASH_SOURCE%/*}/lib.sh"

# Nerd Font icons: a bell, and a bell with a dot for unseen notifications
bell_icon=$'\U000F009A'
unseen_icon=$'\U000F116B'

# "ID OWNER": the newest notification seen in the popup, and dunst's D-Bus
# name then. Written by notification_history.sh. A restarted dunst has a new
# name and numbers its notifications from 1 again, so the ID is stale then.
seen_file=${XDG_STATE_HOME:-$HOME/.local/state}/eww/notifications-seen
# notification_history.sh writes a line here after marking everything seen
fifo=${XDG_RUNTIME_DIR:-/tmp}/eww-notifications.fifo

dunst_owner() {
    gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus \
        --method org.freedesktop.DBus.GetNameOwner org.freedesktop.Notifications 2>/dev/null
}

render() {
    local seen=0 seen_owner now uptime
    read -r seen seen_owner 2>/dev/null < "$seen_file"
    [[ $seen_owner == "$(dunst_owner)" ]] || seen=0
    # dunst's timestamps are CLOCK_MONOTONIC microseconds, which python can
    # read (/proc/uptime counts suspend too, so it would drift)
    read -r now uptime < <(python3 -c 'import time; print(int(time.time()), time.monotonic())')
    emit "$({ dunstctl history 2>/dev/null || echo '{"data": [[]]}'; } | jq -c \
        --argjson seen "${seen:-0}" --argjson now "$now" --argjson uptime "$uptime" \
        --arg bell "$bell_icon" --arg unseen_icon "$unseen_icon" '
        # dunst runs with markup = full: drop the tags, decode the entities
        def plain: gsub("<[^>]*>"; "") | gsub("&lt;"; "<") | gsub("&gt;"; ">")
            | gsub("&quot;"; "\"") | gsub("&apos;"; "'"'"'") | gsub("&amp;"; "&");
        [.data[0][] | map_values(.data) | {
            id, app: .appname, summary: (.summary | plain),
            body: (.body | plain | gsub("\\s+"; " ") | ltrimstr(" ")),
            time: ($now - $uptime + .timestamp / 1e6 | localtime | strftime("%H:%M"))
        }] | sort_by(-.id) as $entries |
        ([$entries[] | select(.id > $seen)] | length) as $unseen |
        {icon: (if $unseen > 0 then $unseen_icon else $bell end), $unseen,
         newest: ($entries[0].id // 0), $entries}')"
}

[[ -p $fifo ]] || { rm -f "$fifo"; mkfifo "$fifo"; }
render
# A notification enters the history as it leaves the screen
# (displayedLength), or goes when removed or cleared; "The name ..." is dunst
# starting or stopping. NotificationClosed isn't seen here: dunst sends it
# only to the app that sent the notification. The fifo is opened read-write
# so it never reaches end of file.
{ gdbus monitor --session --dest org.freedesktop.Notifications & cat <> "$fifo"; } |
    while read -r line; do
        case $line in
            *"'displayedLength'"* | *"'historyLength'"* | *.NotificationHistory* | \
                "The name "* | seen)
                drain_burst
                render
                ;;
        esac
    done
