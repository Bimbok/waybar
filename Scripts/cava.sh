#!/bin/bash

# Wait for the audio server to initialize on boot
sleep 2

# Create a temporary config file for cava
CAVA_CONFIG="/tmp/waybar_cava_config"
echo "
[general]
framerate = 60
bars = 18
sleep_timer = 0
autosens = 1

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 8

[smoothing]
# These parameters are the secret sauce for visual smoothness
integral = 77
" >"$CAVA_CONFIG"

# Kill any existing cava process
pkill -f "cava -p $CAVA_CONFIG"

# Run cava and use awk to handle output
# It will output an empty string (hiding the module) when silent
cava -p "$CAVA_CONFIG" | awk -F ';' '{
    # Check if all bars are zero
    total = 0
    for (i=1; i<NF; i++) total += $i

    if (total == 0) {
        print ""
    } else {
        res = ""
        for (i=1; i<NF; i++) {
            v = $i
            if (v == 0) res = res " "
            else if (v == 1) res = res "▂"
            else if (v == 2) res = res "▃"
            else if (v == 3) res = res "▄"
            else if (v == 4) res = res "▅"
            else if (v == 5) res = res "▆"
            else if (v == 6) res = res "▇"
            else res = res "█"
        }
        print res
    }
    fflush()
}'
