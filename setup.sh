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
    vlc \
    discord

yay -S --needed --noconfirm \
    obsidian \
    drawio-desktop \
    signal-desktop \
    visual-studio-code-bin

# Development packages
sudo pacman -Syu --needed --noconfirm \
    base-devel \
    git \
    wget \
    curl

# Ubuntu Mono Nerd Font installation (global)
FONT_DIR="/usr/share/fonts/NerdFonts"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip"
TEMP_DIR=$(mktemp -d)

msg "Installing Ubuntu Mono Nerd Font globally..."
wget -q --show-progress "$FONT_URL" -O "$TEMP_DIR/UbuntuMono.zip"
sudo mkdir -p "$FONT_DIR"
sudo unzip -q "$TEMP_DIR/UbuntuMono.zip" -d "$FONT_DIR/UbuntuMono"
rm -rf "$TEMP_DIR"
sudo fc-cache -fv
msg "Ubuntu Mono Nerd Font installed successfully."

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
