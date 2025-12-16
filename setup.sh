#!/bin/bash
set -euo pipefail
msg() { printf '\n\033[33;1m  Info\033[00m  %s\n\n' "$*"; }

cd "$(dirname "${BASH_SOURCE[0]}")"

msg 'Installing packages'
sudo pacman -Syu --needed --noconfirm \
    base-devel \
    git \
    wget \
    curl \
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
    vlc-plugin-ffmpeg \
    podman \
    distrobox \
    github-cli

# might switch to snap/flatpak someday
# because of AUR security concerns
yay -S --needed --noconfirm \
    obsidian \
    drawio-desktop \
    signal-desktop \
    visual-studio-code-bin \
    localsend-bin \
    ivpn ivpn-ui \
    spotify

msg 'Setting up virtualization'
yay -S --needed --noconfirm \
  qemu-full \
  virt-manager \
  virt-viewer \
  libguestfs \
  libvirt \
  edk2-ovmf \
  swtpm
sudo systemctl enable --now libvirtd.service

FONT_DIR="/usr/share/fonts/NerdFonts"
if [ -d "$FONT_DIR/UbuntuMono" ]; then
  msg 'Fonts already installed'
else
  msg 'Installing fonts'
  FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip"
  TEMP_DIR=$(mktemp -d)
  wget -q --show-progress "$FONT_URL" -O "$TEMP_DIR/UbuntuMono.zip"
  sudo mkdir -p "$FONT_DIR"
  sudo unzip -q "$TEMP_DIR/UbuntuMono.zip" -d "$FONT_DIR/UbuntuMono"
  rm -rf "$TEMP_DIR"
  sudo fc-cache -fv
fi

if groups | grep -q '\blibvirt\b'; then
  msg 'Already in libvirt group'
else
  sudo usermod -aG libvirt "$USER"
  msg 'Added to libvirt group (re-login required)'
fi

msg 'Configuring firewall'
sudo firewall-cmd --zone=public --add-port=53317/tcp --permanent # LocalSend
sudo firewall-cmd --zone=public --add-port=53317/udp --permanent # LocalSend
sudo firewall-cmd --reload

msg 'Backing up existing files'
mkdir -p .backups
BRAHMA_DIR="$(pwd)"
find home -type f | while read -r file; do
  target="$HOME/${file#home/}"
  [ ! -e "$target" ] && continue
  [ -L "$target" ] && continue
  realpath_target=$(realpath "$target" 2>/dev/null || echo "$target")
  [[ "$realpath_target" == "$BRAHMA_DIR/home/"* ]] && continue
  backup=".backups/$(basename "$target")"
  if [ ! -e "$backup" ]; then
    mv "$target" "$backup"
    msg "Backed up $(basename "$target")"
  fi
done

msg 'Setting up scripts'
chmod +x scripts/*

msg 'Creating directories'
mkdir -p ~/bin ~/opt

msg 'Creating symlinks'
stow -t ~ --restow home

msg 'Setup complete'
