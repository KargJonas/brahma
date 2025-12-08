#!/bin/bash

#                        __
#    ___ __ _____   ___ / /
#   (_-</ // (_-<_ (_-</ _ \
#  /___/\_, /___(_)___/_//_/
#      /___/
#

# Jonn 2025

msg() { printf '\n\033[33;1m  Sys Info\033[00m  %s\n\n' "$*"; }

sys_power() {
  case "$1" in
    poweroff | p) msg 'Powering off';   systemctl poweroff ;;
    reboot   | r) msg 'Rebooting';      systemctl reboot ;;
    suspend  | s) msg 'Sleeping';       systemctl suspend ;;
    lock     | l) msg 'Locking screen'; loginctl lock-session ;;
    exit     | e) 
      msg 'Logging out'
      loginctl terminate-session "$XDG_SESSION_ID"
      ;;
  esac
}

sys_brightness() {
  command -v brightnessctl >/dev/null || { msg 'Install brightnessctl'; return 1; }
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    local n=$1; (( n<10 )) && n=10; (( n>100 )) && n=100
    brightnessctl set "${n}%"
  else
    case "$1" in
      up   | u) brightnessctl set +10% ;;
      down | d) brightnessctl set 10%- ;;
      max  | h) brightnessctl set 100% ;;
      min  | l) brightnessctl set 10% ;;
    esac
  fi
  local p; p=$(brightnessctl -m | awk -F, '{print $4}')
  msg "Brightness ${p}"
}

sys_volume() {
  command -v wpctl >/dev/null || { msg 'Install wpctl (wireplumber)'; return 1; }
  local sink='@DEFAULT_AUDIO_SINK@'
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    wpctl set-volume "$sink" "$1%"
  else
    case "$1" in
      up     | u) wpctl set-volume "$sink" 10%+ ;;
      down   | d) wpctl set-volume "$sink" 10%- ;;
      mute   | m) wpctl set-mute   "$sink" 1 ;;
      toggle | t) wpctl set-mute   "$sink" toggle ;;
    esac
  fi
  local out frac pct; out=$(wpctl get-volume "$sink")
  frac=$(awk '{print $2}' <<<"$out"); pct=$(awk -v f="$frac" 'BEGIN{printf "%d%%", f*100+0.5}')
  [[ "$out" == *"[MUTED]"* ]] && msg "Volume ${pct} (muted)" || msg "Volume ${pct}"
}

sys_profile() {
  command -v powerprofilesctl >/dev/null || { msg 'Install power-profiles-daemon'; return 1; }
  case "$1" in
    performance | perf | p) powerprofilesctl set performance; msg 'Profile: performance' ;;
    balanced    | bal  | b) powerprofilesctl set balanced; msg 'Profile: balanced' ;;
    power-saver | saver| s) powerprofilesctl set power-saver; msg 'Profile: power-saver' ;;
    *) local cur; cur=$(powerprofilesctl get); msg "Profile: ${cur}" ;;
  esac
}

sys_screenshot() {
  command -v grim >/dev/null || { msg 'Install grim'; return 1; }
  command -v slurp >/dev/null || { msg 'Install slurp'; return 1; }
  command -v wl-copy >/dev/null || { msg 'Install wl-clipboard'; return 1; }
  local file=~/Pictures/screenshot-$(date +%Y-%m-%d_%H-%M-%S).png
  mkdir -p ~/Pictures
  grim -g "$(slurp)" - | tee "$file" | wl-copy
  msg "Screenshot saved: ${file}"
}

sys_monitor() {
  if [[ "$XDG_CURRENT_DESKTOP" == *"Hyprland"* ]] then
    command -v hyprmon >/dev/null || { msg 'Install hyprmon'; return 1; }
    setsid hyprmon >/dev/null 2>&1 &
  elif [[ "$XDG_CURRENT_DESKTOP" == *"sway"* ]] then
    command -v nwg-displays >/dev/null || { msg 'Install nwg-displays'; return 1; }
    nwg-displays &
  else
    msg 'Not running Hyprland or Sway'
    return 1
  fi
}

case "$1" in
  power      | p) sys_power "$2" ;;
  brightness | b) sys_brightness "$2" ;;
  volume     | v) sys_volume "$2" ;;
  profile    | f) sys_profile "$2" ;;
  screenshot | s) sys_screenshot ;;
  monitor    | m) sys_monitor ;;
esac
