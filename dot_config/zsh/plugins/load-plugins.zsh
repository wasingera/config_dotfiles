#!/bin/zsh

for file in $ZDOTDIR/plugins/*/*.(plugin.zsh|zsh-theme)(#qN); do
    source $file
done
unset file
