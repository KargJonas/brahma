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

# Used for showing git information in the PS1
source ~/.git-prompt.sh

# All data displayed in the PS1 must be evaluated at when the PS1
# is being printed. This prevents showing old data.

# Checks if inside container and returns docker indicator for PS1
function __docker_ps1 () {
  if [ -f /.dockerenv ]; then echo -e '\033[01;32m[\033[01;36mdocker\033[01;32m] '; fi
}

function __container_ps1 () {
  if [ -n "$DISTROBOX_ENTER_PATH" ]; then
    echo -e '\033[01;32m[\033[01;36m'"${CONTAINER_ID:-distrobox}"'\033[01;32m] '
  elif [ -f /run/.toolboxenv ]; then
    local name=$(grep -oP '(?<=name=")[^"]+' /run/.containerenv 2>/dev/null || echo "toolbox")
    echo -e '\033[01;32m[\033[01;36m'"$name"'\033[01;32m] '
  fi
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
PS1='$(__root_ps1)$(__container_ps1)$(__docker_ps1)\[\033[01;32m\][\[\033[01;34m\]\w\[\033[01;32m\]]\[\033[01;33m\]$(__safe_git_ps1)\n \[\033[01;31m\]⇋\[\033[00m\] '

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
alias lln='ls -llt | head -n '

alias clip='wl-copy'
alias vim='nvim'
alias bashrl='source ~/.bashrc'
alias swayrl="swaymsg reload"
alias bashedit='vim ~/.bashrc'
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

alias dbe='distrobox enter'

# distro specific aliases
alias agi='sudo apt-get install'
alias agr='sudo apt-get remove'
alias agu='sudo apt-get update'
alias pmi='sudo pacman -S'
alias pmr='sudo pacman -R'

# path config
export PATH="$HOME/brahma/scripts:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/nvim-linux-x86_64/bin:$PATH"
export PATH="/snap/bin:$PATH"
export PATH="$HOME/opt/oss-cad-suite/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"

# Enable bash hashing
set -o hashall

[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
