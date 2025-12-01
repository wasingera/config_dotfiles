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
alias ls="ls --color"
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

## Path Variables ##

## NVM Setup ##
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
