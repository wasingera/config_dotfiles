#!/usr/bin/env bash
# fzf in the colour scheme's colours, for tmux's popups: the session picker and
# extrakto (its @extrakto_fzf_tool). Takes fzf's arguments, which override these.
#
# tmux holds the active scheme in its @thm_* and @accent options. Where no
# scheme is active those are ANSI names, and fzf keeps its own colours.
read -r text subtext surface0 surface1 overlay1 accent < <(tmux display-message -p \
    '#{@thm_text} #{@thm_subtext0} #{@thm_surface0} #{@thm_surface1} #{@thm_overlay1} #{@accent}')
colours=()
if [[ $text == \#* ]]; then
    colours=(--color "fg:$subtext,bg:-1,hl:$accent:bold,fg+:$text,bg+:$surface0,hl+:$accent:bold"
        --color "query:$text,prompt:$accent,pointer:$accent,marker:$accent,spinner:$accent"
        --color "info:$overlay1,header:$overlay1,separator:$surface0,scrollbar:$surface1,border:$surface1")
fi
exec fzf "${colours[@]}" --gutter ' ' --highlight-line "$@"
