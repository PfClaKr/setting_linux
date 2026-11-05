# extras.bash -- small bash settings that used to live in .zshrc.
# Sourced from ~/.bashrc by install.sh, after the distribution's defaults.

case $- in *i*) ;; *) return ;; esac

# History: keep a lot, skip duplicates and lines starting with a space,
# append instead of overwriting, and record when each command ran.
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T  '
shopt -s histappend cmdhist

export EDITOR=vim VISUAL=vim

alias c='clear'
alias sysupdate='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoclean && sudo apt-get autoremove -y'
alias ll='ls -alF'
alias grep='grep --color=auto'
