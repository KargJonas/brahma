#!/bin/bash
set -euo pipefail
msg() { printf '\n\033[33;1m  Setup\033[00m  %s\n\n' "$*"; }

cd "$(dirname "${BASH_SOURCE[0]}")"

msg 'Installing packages'
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
    discord \
    qbittorrent \
    vlc-plugin-ffmpeg

yay -S --needed --noconfirm \
    obsidian \
    drawio-desktop \
    signal-desktop \
    visual-studio-code-bin \
    localsend-bin \
    ivpn ivpn-ui

sudo pacman -Syu --needed --noconfirm \
    base-devel \
    git \
    wget \
    curl

if fc-list | grep -qi "UbuntuMono Nerd Font"; then
  msg 'Fonts already installed'
else
  msg 'Installing fonts'
  FONT_DIR="/usr/share/fonts/NerdFonts"
  FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip"
  TEMP_DIR=$(mktemp -d)
  wget -q --show-progress "$FONT_URL" -O "$TEMP_DIR/UbuntuMono.zip"
  sudo mkdir -p "$FONT_DIR"
  sudo unzip -q "$TEMP_DIR/UbuntuMono.zip" -d "$FONT_DIR/UbuntuMono"
  rm -rf "$TEMP_DIR"
  sudo fc-cache -fv
fi

msg 'Configuring firewall'
sudo firewall-cmd --zone=public --add-port=53317/tcp --permanent
sudo firewall-cmd --zone=public --add-port=53317/udp --permanent
sudo firewall-cmd --reload

msg 'Setting up virtualization'
sudo pacman -S podman distrobox
yay -S --needed --noconfirm qemu-full virt-manager virt-viewer libguestfs libvirt edk2-ovmf swtpm
sudo systemctl enable --now libvirtd.service

if groups | grep -q '\blibvirt\b'; then
  msg 'Already in libvirt group'
else
  sudo usermod -aG libvirt "$USER"
  msg 'Added to libvirt group (re-login required)'
fi

msg 'Backing up existing files'
mkdir -p .backups
find home -type f | while read -r file; do
  target="$HOME/${file#home/}"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    backup=".backups/$(basename "$target")"
    if [ ! -e "$backup" ]; then
      mv "$target" "$backup"
      msg "Backed up $(basename "$target")"
    fi
  fi
done

msg 'Setting up scripts'
chmod +x scripts/*

msg 'Creating directories'
mkdir -p ~/bin ~/opt

msg 'Creating symlinks'
stow -t ~ --restow home

msg 'Setup complete'
