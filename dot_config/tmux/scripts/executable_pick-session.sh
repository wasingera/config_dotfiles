#!/usr/bin/env bash
# Switch to a tmux session, or to one in a directory zoxide knows, made if it
# doesn't exist yet. tmux.conf runs this in a popup on prefix f.
set -euo pipefail

# the client's session (#S in a popup is the server's default session, not the client's)
current=$(tmux display-message -p '#{client_session}')

# Each row is KIND<tab>VALUE; fzf shows only the value
list() {
    tmux list-sessions -F '#S' | while IFS= read -r name; do
        [[ $name == "$current" ]] || printf 's\t%s\n' "$name"
    done
    if command -v zoxide >/dev/null; then
        zoxide query --list | while IFS= read -r dir; do
            printf 'd\t%s\n' "${dir/#$HOME/\~}"
        done
    fi
}

# fzf in the colour scheme's colours, which tmux holds in its @thm_* options.
# Where no scheme is active those are ANSI names, so fzf keeps its own.
colours=()
read -r text subtext surface0 surface1 overlay1 accent < <(tmux display-message -p \
    '#{@thm_text} #{@thm_subtext0} #{@thm_surface0} #{@thm_surface1} #{@thm_overlay1} #{@accent}')
if [[ $text == \#* ]]; then
    colours=(--color "fg:$subtext,bg:-1,hl:$accent:bold,fg+:$text,bg+:$surface0,hl+:$accent:bold"
        --color "query:$text,prompt:$accent,pointer:$accent,marker:$accent,spinner:$accent"
        --color "info:$overlay1,separator:$surface0,scrollbar:$surface1,border:$surface1")
fi

choice=$(list | fzf "${colours[@]}" --delimiter '\t' --with-nth 2 --tiebreak index --reverse \
    --prompt 'session> ' --gutter ' ' --highlight-line) || exit 0
kind=${choice%%$'\t'*}
value=${choice#*$'\t'}

if [[ $kind == s ]]; then
    name=$value
else
    dir=${value/#\~/$HOME}
    # tmux doesn't allow . or : in a session name
    name=$(basename "$dir" | tr '.:' '__')
    tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$dir"
fi
tmux switch-client -t "=$name"
