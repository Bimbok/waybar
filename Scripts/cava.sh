#!/bin/bash

# Create a temporary config file for cava
CAVA_CONFIG="/tmp/waybar_cava_config"
echo "
[general]
bars = 8
sleep_timer = 0

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
" > "$CAVA_CONFIG"

# Kill any existing cava process
pkill -f "cava -p $CAVA_CONFIG"

# Run cava and translate its output into bars
cava -p "$CAVA_CONFIG" | while read -r line; do
    # Remove semicolons and replace the numeric output with bar characters
    # 0 -> ' ', 1 -> '▂', etc.
    echo "$line" | sed "s/;//g; s/0/ /g; s/1/▂/g; s/2/▃/g; s/3/▄/g; s/4/▅/g; s/5/▆/g; s/6/▇/g; s/7/█/g"
done
