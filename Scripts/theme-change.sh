#!/usr/bin/env bash

# 1. Configuration
DIR="$HOME/arch/walls"

# 2. Check dependencies
if ! command -v swww &>/dev/null; then
  notify-send "Error" "swww is not installed."
  exit 1
fi

if ! pgrep -x "swww-daemon" &>/dev/null; then
  notify-send "Wallpaper" "Starting swww-daemon..."
  swww-daemon &
  sleep 1
fi

# 3. Find a random wallpaper
RANDOM_WALL=$(find "$DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) 2>/dev/null | shuf -n 1)

if [ -z "$RANDOM_WALL" ]; then
  notify-send "Error" "No wallpaper found in $DIR"
  exit 1
fi

# 4. Apply changes
notify-send "Theme" "Generating palette..."
swww img "$RANDOM_WALL" --transition-type grow --transition-fps 60 --transition-pos top-right --transition-duration 2

# Generate Colors (Matugen)
if command -v matugen &>/dev/null; then
  matugen image "$RANDOM_WALL"
else
  notify-send "Warning" "matugen not found, colors not updated."
fi

# 5. Success Notification
notify-send "Theme Changed" "New wallpaper: $(basename "$RANDOM_WALL")"
