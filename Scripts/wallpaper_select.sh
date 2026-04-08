#!/usr/bin/env bash

# --- CONFIGURATION ---
WALL_DIR="$HOME/shared/walls/"
# Use the dedicated theme file for a beautiful and consistent look
ROFI_CMD=("rofi" "-dmenu" "-i" "-p" "Wallpaper" "-theme" "$HOME/.config/rofi/config-themes.rasi")

# --- LOGIC ---

# 1. Check dependencies
if ! command -v awww &>/dev/null; then
  notify-send "Error" "awww is not installed."
  exit 1
fi

if ! pgrep -x "awww-daemon" &>/dev/null; then
  awww-daemon &
  sleep 1
fi

# 2. Get the list of images and format them for Rofi
SELECTED=$(find "$WALL_DIR" -maxdepth 1 -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | sort | while read -r img; do
  filename=$(basename "$img")
  echo -en "$filename\0icon\x1f$img\n"
done | "${ROFI_CMD[@]}")

# 3. Exit if the user cancelled
[ -z "$SELECTED" ] && exit 0

FULL_PATH="$WALL_DIR/$SELECTED"

# 4. Apply the changes
if [ -f "$FULL_PATH" ]; then
  notify-send "Theme" "Applying $SELECTED..."

  # Apply Wallpaper
  awww img "$FULL_PATH" --transition-type wave --transition-fps 60 --transition-pos top-right --transition-duration 3

  # Generate Colors
  if command -v matugen &>/dev/null; then
    matugen --old-json-output --source-color-index 0 image "$FULL_PATH"
    ~/.config/waybar/Scripts/reload.sh &
    disown
  fi

  # Send Notification
  notify-send "Theme Changed" "New Wallpaper: $SELECTED"
else
  notify-send "Error" "Could not find wallpaper at $FULL_PATH" -u critical
fi
