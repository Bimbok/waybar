#!/usr/bin/env bash

# --- CONFIGURATION ---
WALL_DIR="$HOME/arch/walls"
ROFI_CMD=("rofi" "-dmenu" "-i" "-p" "Wallpaper" "-show-icons" "-theme-str" "window {width: 60%;} listview {columns: 4; lines: 3;} element {orientation: vertical; padding: 10px;} element-icon {size: 150px;} element-text {vertical-align: 0.5; horizontal-align: 0.5;}")

# --- LOGIC ---

# 1. Check dependencies
if ! command -v swww &>/dev/null; then
  notify-send "Error" "swww is not installed."
  exit 1
fi

if ! pgrep -x "swww-daemon" &>/dev/null; then
  swww-daemon &
  sleep 1
fi

# 2. Get the list of images and format them for Rofi
# We use find to get the full path, but show the filename to the user.
# The icon is set to the full path so Rofi can display it.
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
  swww img "$FULL_PATH" --transition-type grow --transition-fps 60 --transition-pos top-right --transition-duration 2

  # Generate Colors
  if command -v matugen &>/dev/null; then
    matugen --old-json-output --source-color-index 0 image "$FULL_PATH"
  fi

  # Send Notification
  notify-send "Theme Changed" "New Wallpaper: $SELECTED"
else
  notify-send "Error" "Could not find wallpaper at $FULL_PATH" -u critical
fi
