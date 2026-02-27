#!/bin/bash

# --- CONFIGURATION ---
# Your wallpaper directory (from your previous script)
WALL_DIR="$HOME/arch/walls"

# --- LOGIC ---
# 1. Get the list of images and format them for Rofi
# The magic syntax is: "Filename\0icon\x1f/path/to/image"
# This tells Rofi to display the image file itself as the icon.
SELECTED=$(find "$WALL_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | sort | while read -r img; do
  filename=$(basename "$img")
  echo -en "$filename\0icon\x1f$img\n"
done | rofi -dmenu -i -p "Wallpaper" \
  -show-icons \
  -theme-str 'window { width: 800px; }' \
  -theme-str 'listview { columns: 4; lines: 3; }' \
  -theme-str 'element { orientation: vertical; padding: 10px; }' \
  -theme-str 'element-icon { size: 120px; }' \
  -theme-str 'element-text { vertical-align: 0.5; horizontal-align: 0.5; }')

# 2. Exit if the user cancelled (pressed Esc)
if [ -z "$SELECTED" ]; then
  exit 0
fi

# 3. Apply the changes (Using your exact Matugen/SWWW logic)
FULL_PATH="$WALL_DIR/$SELECTED"

# Apply Wallpaper
swww img "$FULL_PATH" --transition-type grow --transition-fps 60

# Generate Colors
matugen image "$FULL_PATH"

# Send Notification
notify-send "Theme Changed" "Applied: $SELECTED"
