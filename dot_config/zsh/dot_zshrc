## Enable Extended Globbing ##
setopt extended_glob

## Set History File and Max Entries ##
export HISTFILE="$HOME/.local/state/zsh/.zsh_history"
export SAVEHIST=10000
export HISTSIZE=10000

## Share Command History Across Shell Instances ##
setopt SHARE_HISTORY

## Load Plugins ##
fpath+=($ZDOTDIR/plugins/pure)
source $ZDOTDIR/plugins/load-plugins.zsh

## Prompt Setup ##
autoload -U promptinit; promptinit
prompt pure

## Aliases ##
alias ls="ls --color -h"
alias ll="ls -l"
alias rm="rm -v"
alias cp="cp -v"
alias mv="mv -v"
alias vim="nvim"
alias arduino="arduino-cli"
alias dc="docker container"
# alias gcc="gcc -Wall -Wconversion -Wextra -std=gnu99"
# alias g++="g++ -Wall -Wconversion -Wextra -Werror -Wshadow -std=c++11 -Weffc++ -m64"
alias g++="g++ -std=c++17"

## Functions ## 
function venv() {
    source "$HOME/venv/$1/bin/activate"
}

## Path Variables ##
export PATH="$HOME/.local/bin:$PATH"

## Bun (JS Package Manager) ##
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

## NVM Setup ##
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "/home/alex/.bun/_bun" ] && source "/home/alex/.bun/_bun"

# yazi: hide Hyprland from it so it uses its built-in chafa previews
# (its ueberzugpp mode puts the image mid-screen on this Hyprland)
function yazi() {
  env -u HYPRLAND_INSTANCE_SIGNATURE yazi "$@"
}

# yazi: cd into the last browsed directory on quit
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  command rm -f -- "$tmp"
}

# zoxide: z <dir>, zi for interactive picker (keep near end of file)
eval "$(zoxide init zsh)"
