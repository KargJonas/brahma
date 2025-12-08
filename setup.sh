#!/bin/bash
set -euo pipefail
msg() { printf '\n\033[33;1m  Sys Info\033[00m  %s\n\n' "$*"; }

# Go to the location of this script
cd "$(dirname "${BASH_SOURCE[0]}")"

# Misc packages
sudo pacman -Syu --needed --noconfirm \
    ly \
    sway \
    waybar \
    wmenu \
    i3status \
    nwg-displays \
    neovim \
    firefox \
    gimp \
    alacritty \
    brightnessctl \
    grim \
    slurp \
    wl-clipboard \
    wireplumber \
    power-profiles-daemon \
    stow \
    vlc

yay -S --needed --noconfirm \
    obsidian \
    drawio-desktop \
    signal-desktop

# Development packages
sudo pacman -Syu --needed --noconfirm \
    base-devel \
    git \
    wget \
    curl

# Docker installation
sudo pacman -Syu --needed --noconfirm docker
sudo systemctl enable --now docker.service
sudo usermod -aG docker "$USER"

# Virtualization stuff
yay -S --needed --noconfirm qemu-full virt-manager virt-viewer libguestfs libvirt edk2-ovmf swtpm
sudo systemctl enable --now libvirtd.service
sudo usermod -aG libvirt "$USER"

# Backup existing config files
find dotfiles -type f | while read -r file; do
  target="$HOME/${file#dotfiles/}"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "${target}.backup.$(date +%s)"
  fi
done

sudo chmod +x scripts/*
mkdir -p ~/bin ~/opt
stow -t ~ dotfiles

msg "Setup complete."
