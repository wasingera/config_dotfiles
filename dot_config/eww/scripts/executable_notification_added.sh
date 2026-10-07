#!/usr/bin/env bash

# Run by dunst (a script rule in dunstrc) for a notification that goes
# straight into the history: wakes notifications.sh, which otherwise hears
# of it only if the history's length changes, and not once it's full.
# Opened read-write, so this can't block if it isn't running.
fifo=${XDG_RUNTIME_DIR:-/tmp}/eww-notifications.fifo
[[ -p $fifo ]] && echo added 1<> "$fifo"
exit 0
