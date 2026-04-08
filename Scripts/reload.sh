#!/usr/bin/env bash

# ==========================================
# 1. TMUX
# ==========================================
# Define your tmux config path (adjust if yours is at ~/.config/tmux/tmux.conf)
TMUX_CONF="$HOME/.config/tmux/tmux.conf"

# 'has-session' silently returns 0 (true) if a server is running, 1 (false) if not
if tmux has-session 2>/dev/null; then
  tmux source-file "$TMUX_CONF"
fi

# ==========================================
# 2. SWAYOSD-SERVER
# ==========================================
# -q suppresses errors if the process isn't currently running
killall -q swayosd-server
# Give the socket/process a fraction of a second to fully close
sleep 0.2
# Restart in the background, redirecting output so it doesn't hang Matugen
swayosd-server >/dev/null 2>&1 &

# ==========================================
# 3. SNAPPY-SWITCHER
# ==========================================
killall -q snappy-switcher
sleep 0.2
snappy-switcher --daemon >/dev/null 2>&1 &

# ==========================================
# 4. CAVA
# ==========================================
# Sends a signal to smoothly reload the config without killing the terminal it runs in
killall -q -USR1 cava

exit 0
