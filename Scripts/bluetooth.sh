#!/usr/bin/env bash

# --- CONFIGURATION ---
ROFI_CMD=("rofi" "-dmenu" "-i" "-p" "Bluetooth" "-theme-str" "window {width: 25%;} listview {lines: 10;}")
# ---------------------

# 1. Check Power State
POWER_STATE=$(bluetoothctl show | grep "Powered: yes")

if [ -z "$POWER_STATE" ]; then
    TOGGLE="󰂯  Enable Bluetooth"
    CHOSEN=$(echo -e "$TOGGLE" | "${ROFI_CMD[@]}")
    
    if [[ "$CHOSEN" == "$TOGGLE" ]]; then
        rfkill unblock bluetooth
        bluetoothctl power on
        notify-send "Bluetooth" "Enabled"
    fi
    exit 0
fi

# 2. Get Devices
SCAN="󰂰  Scan for Devices"
TOGGLE="󰂲  Disable Bluetooth"

notify-send "Bluetooth" "Fetching devices..."

PAIRED=$(bluetoothctl devices | while read -r line; do
    MAC=$(echo "$line" | awk '{print $2}')
    NAME=$(echo "$line" | cut -d' ' -f3-)
    
    if bluetoothctl info "$MAC" | grep -q "Connected: yes"; then
        echo "󰄬 $NAME ($MAC)"
    else
        echo "󰂱 $NAME ($MAC)"
    fi
done)

# 3. Show Menu
CHOSEN=$(echo -e "$SCAN\n$TOGGLE\n$PAIRED" | "${ROFI_CMD[@]}")

[ -z "$CHOSEN" ] && exit 0

# 4. Handle Actions
if [[ "$CHOSEN" == "$TOGGLE" ]]; then
    bluetoothctl power off
    notify-send "Bluetooth" "Disabled"
    exit 0
elif [[ "$CHOSEN" == "$SCAN" ]]; then
    notify-send "Bluetooth" "Scanning for 10 seconds..."
    bluetoothctl --timeout 10 scan on >/dev/null 2>&1 &
    sleep 2
    exec "$0"
    exit 0
fi

# 5. Handle Device Interaction
MAC=$(echo "$CHOSEN" | grep -oE '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')
NAME=$(echo "$CHOSEN" | sed 's/^[󰄬󰂱 ]*//;s/ (.*)//')

if [ -z "$MAC" ]; then
    notify-send "Bluetooth" "Error: Could not extract MAC address" -u critical
    exit 1
fi

INFO=$(bluetoothctl info "$MAC")

if echo "$INFO" | grep -q "Connected: yes"; then
    notify-send "Bluetooth" "Disconnecting from $NAME..."
    if bluetoothctl disconnect "$MAC"; then
        notify-send "Bluetooth" "Disconnected"
    else
        notify-send "Bluetooth" "Failed to disconnect" -u critical
    fi
else
    if echo "$INFO" | grep -q "Paired: yes"; then
        notify-send "Bluetooth" "Connecting to $NAME..."
        if bluetoothctl connect "$MAC"; then
            notify-send "Bluetooth" "Connected to $NAME"
        else
            notify-send "Bluetooth" "Connection failed" -u critical
        fi
    else
        notify-send "Bluetooth" "Pairing with $NAME..."
        if bluetoothctl pair "$MAC" && bluetoothctl trust "$MAC" && bluetoothctl connect "$MAC"; then
            notify-send "Bluetooth" "Successfully paired and connected to $NAME"
        else
            notify-send "Bluetooth" "Pairing failed. Ensure device is in pairing mode." -u critical
        fi
    fi
fi
