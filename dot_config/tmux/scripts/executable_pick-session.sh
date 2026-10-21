#!/usr/bin/env bash
# Switch to a tmux session, or to one in a directory zoxide knows, made if it
# doesn't exist yet. tmux.conf runs this in a popup on prefix f. Ctrl+x twice
# kills the highlighted session; fzf's key bindings call this script back
# with the --options below.
set -euo pipefail

# the client's session (#S in a popup is the server's default session, not the client's)
current=$(tmux display-message -p '#{client_session}')

# Markers: a filled dot in the accent for a session, a hollow one dimmed for a
# directory. tmux holds the scheme's colours (hex); otherwise ANSI blue and grey.
read -r accent dim < <(tmux display-message -p '#{@accent} #{@thm_overlay1}')
fg() { # hex colour or ANSI fallback -> escape code
    if [[ $1 == \#?????? ]]; then
        printf '\e[38;2;%d;%d;%dm' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"
    else
        printf '\e[%sm' "$2"
    fi
}
session_mark="$(fg "$accent" 34)●"$'\e[0m'
dir_mark="$(fg "$dim" 90)○"$'\e[0m'

# Each row is KIND<tab>MARKER<tab>VALUE; fzf shows the marker and value, and
# searches only the value
list() {
    tmux list-sessions -F '#S' | while IFS= read -r name; do
        [[ $name == "$current" ]] || printf 's\t%s\t%s\n' "$session_mark" "$name"
    done
    if command -v zoxide >/dev/null; then
        zoxide query --list | while IFS= read -r dir; do
            printf 'd\t%s\t%s\n' "$dir_mark" "${dir/#$HOME/\~}"
        done
    fi
}

self=${BASH_SOURCE[0]}
prompt='session> '
case ${1-} in
    --list) list; exit 0 ;;
    # Ctrl+x on a session asks for a second Ctrl+x, which kills it. Prints fzf
    # actions; FZF_PROMPT shows whether the first press was on this session.
    --ctrl-x)
        [[ $2 == s ]] || exit 0
        if [[ ${FZF_PROMPT-} == "kill $3? ctrl-x again> " ]]; then
            printf 'execute-silent(%q --kill {3})+reload(%q --list)+change-prompt:%s' "$self" "$self" "$prompt"
        else
            printf 'change-prompt:kill %s? ctrl-x again> ' "$3"
        fi
        exit 0 ;;
    --kill) tmux kill-session -t "=$2"; exit 0 ;;
    # Escape cancels a first Ctrl+x, or else closes the picker
    --esc)
        if [[ ${FZF_PROMPT-} == "$prompt" ]]; then printf abort; else printf 'change-prompt:%s' "$prompt"; fi
        exit 0 ;;
esac

# fzf.sh beside this script is fzf in the colour scheme's colours. {1} and {3}
# are a row's KIND and VALUE. Typing or moving cancels a first Ctrl+x.
choice=$(list | "${BASH_SOURCE%/*}/fzf.sh" --ansi --delimiter '\t' --with-nth 2.. --nth 2 --tabstop 2 \
    --tiebreak index --reverse --prompt "$prompt" \
    --header "$session_mark session  $dir_mark directory  ctrl-x kill" \
    --bind "ctrl-x:transform('$self' --ctrl-x {1} {3})" --bind "esc:transform('$self' --esc)" \
    --bind "change:change-prompt:$prompt" --bind "focus:change-prompt:$prompt") || exit 0
kind=${choice%%$'\t'*}
value=${choice##*$'\t'}

if [[ $kind == s ]]; then
    name=$value
else
    dir=${value/#\~/$HOME}
    # tmux doesn't allow . or : in a session name
    name=$(basename "$dir" | tr '.:' '__')
    tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$dir"
fi
tmux switch-client -t "=$name"
