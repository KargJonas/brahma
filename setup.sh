#!/bin/bash
set -euo pipefail
msg() { printf '\n\033[33;1m  Info\033[00m  %s\n\n' "$*"; }

sudo -v
cd "$(dirname "${BASH_SOURCE[0]}")"

# Git identity is kept out of the public repo, in ~/.gitconfig.local
if [ -f ~/.gitconfig.local ]; then
  msg 'Git identity already configured'
else
  msg 'Configuring git identity (~/.gitconfig.local)'
  read -rp 'Git name: ' git_name
  read -rp 'Git email (GitHub noreply recommended): ' git_email
  git config -f ~/.gitconfig.local user.name "$git_name"
  git config -f ~/.gitconfig.local user.email "$git_email"
fi

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
    fuzzel \
    mako \
    batsignal \
    nwg-displays \
    gammastep \
    neovim \
    firefox \
    gimp \
    alacritty \
    brightnessctl \
    ddcutil \
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
    github-cli \
    timeshift

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

# Built from the fork (pkg/i3status), replacing Arch's i3status; --ask=4
# answers yes to removing it, which --noconfirm alone declines
msg 'Building i3status (KargJonas fork)'
(
  cd pkg/i3status
  makepkg -srf --noconfirm
  sudo pacman -U --needed --noconfirm --ask=4 "$(makepkg --packagelist)"
)

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

# External monitor brightness via DDC/CI (ddcutil). The package auto-loads
# i2c-dev on boot; modprobe makes it work in the current session too.
sudo modprobe i2c-dev
if groups | grep -q '\bi2c\b'; then
  msg 'Already in i2c group'
else
  sudo usermod -aG i2c "$USER"
  msg 'Added to i2c group for external monitor brightness (re-login required)'
fi

msg 'Configuring firewall'
sudo firewall-cmd --zone=public --add-port=53317/tcp --permanent # LocalSend
sudo firewall-cmd --zone=public --add-port=53317/udp --permanent # LocalSend
sudo firewall-cmd --reload

msg 'Backing up existing files'
BRAHMA_DIR="$(pwd)"
BACKUP_DIR=".backups/$(date +%Y%m%d_%H%M%S)"
NEEDS_BACKUP=false

while read -r file; do
  target="$HOME/${file#home/}"
  [ ! -e "$target" ] && continue
  [ -L "$target" ] && continue
  [[ "$(realpath "$target" 2>/dev/null || echo "$target")" == "$BRAHMA_DIR/home/"* ]] && continue

  [ "$NEEDS_BACKUP" = false ] && mkdir -p "$BACKUP_DIR" && NEEDS_BACKUP=true

  backup="$BACKUP_DIR/${target#$HOME/}"
  mkdir -p "$(dirname "$backup")"
  mv "$target" "$backup"
  msg "Backed up ${target#$HOME/}"
done < <(find home -type f)

msg 'Setting up scripts'
chmod +x scripts/*

msg 'Creating directories'
mkdir -p ~/bin ~/opt

msg 'Creating symlinks'
stow -t ~ --restow home

msg 'Setup complete'
