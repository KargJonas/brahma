#!/bin/bash
# see /usr/share/doc/bash/examples/startup-files for more examples

#        __            __
#       / /  ___ ____ / /  ________
#    _ / _ \/ _ `(_-</ _ \/ __/ __/
#   (_)_.__/\_,_/___/_//_/_/  \__/
#

# Jonn 2021

# Dependencies:
# git, wget

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# don't put duplicate lines or lines starting with space in the history.
# HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

HISTSIZE=1000
HISTFILESIZE=50000

# check the window size after each command and, if necessary,
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# Prints clean info messages
function info () {
  echo -e '\n\033[33;1m  Info\033[00m  ' $1 '\n'
}

# Fetches and runs .git-prompt if git installed but .git-prompt not found.
function git_setup () {
  git --version &> /dev/null
  if [ $? -ne 0 ]; then return; fi

  # Download git-prompt if not found.
  if ! [ -f ~/.git-prompt.sh ]; then
    info 'File ".git-prompt.sh" not found. Fetching it.'
    wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -O ~/.git-prompt.sh
  fi

  # Run .git-prompt. This makes the __git_ps1 function available.
  source ~/.git-prompt.sh
}

# Automatically sets up sys manager if not found.
function sys_setup () {
  if [ -d ~/.sys/ ] && [ -f ~/.sys/sys.sh ]; then return; fi

  info 'File "sys.sh" not found. Fetching it.'

  local SYS_URL='https://gist.githubusercontent.com/KargJonas/34e08907e7b9695c40454e3edc34e4f1/raw/3c5cfe2baca219402344c1adf63bde887bc527a5/sys.sh'

  mkdir ~/.sys
  wget $SYS_URL -O ~/.sys/sys.sh
}

git_setup
sys_setup

# All data displayed in the PS1 must be evaluated at when the PS1
# is being printed. This prevents showing old data.

# Checks if inside container and returns docker indicator for PS1
function __docker_ps1 () {
  if [ -f /.dockerenv ]; then echo -e '\033[01;32m[\033[01;36mdocker\033[01;32m] '; fi
}

# Checks if user is root and returns root indicator for PS1
function __root_ps1 () {
  if [[ $(id -u) == 0 ]]; then echo -e '\033[01;32m[\033[01;35mroot\033[01;32m]'; fi
}

function __safe_git_ps1 () {
  git --version &> /dev/null
  if [ $? -ne 0 ]; then return; fi

  echo "$(__git_ps1) "
}

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# This is where the PS1 is stitched together.
# The completed string undergoes further decoding by the shell program
# before being displayed (e.g. \w escape character)
PS1='$(__root_ps1)$(__docker_ps1)\[\033[01;32m\][\[\033[01;34m\]\w\[\033[01;32m\]]\[\033[01;33m\]$(__safe_git_ps1)\n \[\033[01;31m\]⇋\[\033[00m\] '

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

function enter_docker_container () {
  docker exec -it $1 /bin/bash
}

function seeker() {
	find . -type f -name "*$1*"
}

# like ls -1 but only lists the first n elements.
function lsn() {
	n=${1:-5}
	ls -1t "${@:2}" | head -n $n
}

# Aliases
alias ls='ls --color=auto'
alias la='ls -a'
alias ll='ls -l'
alias lln='ls -ll | head -n '

alias sys='bash ~/.sys/sys.sh'
alias clip='wl-copy'
alias vim='nvim'
alias bashrl='source ~/.bashrc'
alias swayrl="swaymsg reload"
alias bashedit='vim ~/.bashrc'
alias hypredit='vim ~/.config/hypr/hyprland.conf'
alias swayedit='vim ~/.config/sway/config'
alias brl='source ~/.bashrc'
alias bed='vim ~/.bashrc'
alias cls='clear'
alias chx='sudo chmod +x'
alias gco='git checkout'
alias gpo='git push origin'

alias edc='enter_docker_container'
alias dcd='docker compose down'
alias dcu='docker compose up -d'
alias dcb='docker compose build'
alias dps='docker ps'
alias dcl='docker compose logs -f'
alias dcbu='docker compose up -d --build'
alias dcbul='docker compose up -d --build && docker compose logs -f'

# distro specific aliases
alias agi='sudo apt-get install'
alias agr='sudo apt-get remove'
alias agu='sudo apt-get update'
alias vaultperf='iperf3 -c 192.168.178.162 -p 2345'
alias vaultssh='ssh jonas@192.168.178.162 -p 42'
alias sherpaperf='iperf3 -c 192.168.178.99 -p 2345'
alias sherpassh='ssh root@192.168.178.99'
alias savantssh='ssh jonas@192.168.178.116'
alias savantperf='iperf3 -c 192.168.178.116 -p 2345'
alias savantwake='sudo etherwake -b 30:9C:23:82:BF:50 -i enx144fd7ca416e'

# path config
export PATH="/home/jonas/bin:$PATH"
export PATH="/home/jonas/.local/bin:$PATH"
export PATH="/opt/nvim-linux-x86_64/bin:$PATH"
export PATH="/snap/bin:$PATH"

# Enable bash hashing
set -o hashall

[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh
