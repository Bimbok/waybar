#!/usr/bin/env bash

# --- CONFIGURATION ---
# Using an array for the command to handle arguments and quoting correctly
ROFI_CMD=("rofi" "-dmenu" "-i" "-p" "Wi-Fi" "-theme-str" "window {width: 25%;} listview {lines: 10;}")
# ---------------------

# 1. Get current WiFi status
WIFI_STATUS=$(nmcli -fields WIFI g | grep -oE "enabled|disabled")

if [ "$WIFI_STATUS" = "enabled" ]; then
    TOGGLE="󰖪  Disable Wi-Fi"
else
    TOGGLE="󰖩  Enable Wi-Fi"
fi

# 2. Get the list of networks
RAW_LIST=$(nmcli --colors no -f "SSID,BARS,SECURITY,ACTIVE" device wifi list | sed 1d)

LIST=$(echo "$RAW_LIST" | while read -r line; do
    [[ -z "${line:0:32}" || "${line:0:32}" =~ ^\ *--\ *$ ]] && continue
    
    SSID=$(echo "${line:0:32}" | sed 's/ *$//')
    BARS=$(echo "${line:33:4}" | sed 's/ //g')
    SEC=$(echo "${line:38:15}" | sed 's/ *$//')
    ACTIVE=$(echo "${line:54:1}")
    
    if [ "$ACTIVE" = "*" ]; then
        echo "󰄬 $SSID  $BARS  [$SEC]"
    else
        echo "  $SSID  $BARS  [$SEC]"
    fi
done | sort -u)

# 3. Add extra options
OPTIONS="󰖂  Manual Entry\n󱚵  Disconnect\n$TOGGLE"
CHOSEN=$(echo -e "$OPTIONS\n$LIST" | "${ROFI_CMD[@]}")

# Exit if nothing selected
[ -z "$CHOSEN" ] && exit 0

# 4. Handle Actions
if [[ "$CHOSEN" == "󰖩  Enable Wi-Fi" ]]; then
    nmcli radio wifi on
    notify-send "Wi-Fi" "Enabled"
    exit 0
elif [[ "$CHOSEN" == "󰖪  Disable Wi-Fi" ]]; then
    nmcli radio wifi off
    notify-send "Wi-Fi" "Disabled"
    exit 0
elif [[ "$CHOSEN" == "󱚵  Disconnect" ]]; then
    ACTIVE_CONN=$(nmcli -t -f ACTIVE,NAME connection show | grep '^yes' | cut -d: -f2)
    if [ -n "$ACTIVE_CONN" ]; then
        nmcli connection down "$ACTIVE_CONN"
        notify-send "Wi-Fi" "Disconnected from $ACTIVE_CONN"
    else
        notify-send "Wi-Fi" "No active connection found"
    fi
    exit 0
elif [[ "$CHOSEN" == "󰖂  Manual Entry" ]]; then
    SSID=$(rofi -dmenu -p "Enter SSID: " -theme-str "window {width: 20%;}")
    [ -z "$SSID" ] && exit 0
    PASS=$(rofi -dmenu -password -p "Enter Password (leave empty if open): " -theme-str "window {width: 20%;}")
    
    notify-send "Wi-Fi" "Connecting to $SSID..."
    if [ -z "$PASS" ]; then
        nmcli device wifi connect "$SSID"
    else
        nmcli device wifi connect "$SSID" password "$PASS"
    fi
    exit 0
fi

# 5. Handle Network Selection
SSID=$(echo "$CHOSEN" | sed 's/^[󰄬 ]*//;s/  .*//')

if echo "$CHOSEN" | grep -q "󰄬"; then
    notify-send "Wi-Fi" "Already connected to $SSID"
    exit 0
fi

notify-send "Wi-Fi" "Connecting to $SSID..."

if nmcli device wifi connect "$SSID" > /dev/null 2>&1; then
    notify-send "Wi-Fi" "Successfully connected to $SSID"
else
    PASS=$(rofi -dmenu -password -p "Password for $SSID: " -theme-str "window {width: 20%;}")
    if [ -n "$PASS" ]; then
        if nmcli device wifi connect "$SSID" password "$PASS"; then
            notify-send "Wi-Fi" "Successfully connected to $SSID"
        else
            notify-send "Wi-Fi" "Failed to connect to $SSID" -u critical
        fi
    else
        notify-send "Wi-Fi" "Connection cancelled"
    fi
fi
