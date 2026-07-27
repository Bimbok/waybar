#!/usr/bin/env python3

import json
import os
import subprocess
import time
import urllib.parse
import urllib.request
from pathlib import Path

TMP_DIR = Path("/tmp/waybar-media")
TMP_DIR.mkdir(parents=True, exist_ok=True)

# Increased buffer pool to 5 to defeat GTK's aggressive CSS image caching
MAX_BUFFERS = 5
ART_FILES = [TMP_DIR / f"art{i}.png" for i in range(1, MAX_BUFFERS + 1)]

players = {}
last_emitted_url = ""
last_emitted_title = ""
last_emitted_status = ""
current_index = 0

def download_art(url):
    global current_index
    if not url:
        return None

    target = ART_FILES[current_index]
    try:
        url_clean = url.strip()
        
        if url_clean.startswith("file://"):
            # Decode URL characters (like %20 for spaces) sent by web browsers
            src = urllib.parse.unquote(url_clean[7:])
            subprocess.run(["cp", src, str(target)], check=True)
        elif url_clean.startswith("http"):
            req = urllib.request.Request(url_clean, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=5) as response, open(target, 'wb') as out_file:
                out_file.write(response.read())
        else:
            if os.path.exists(url_clean):
                subprocess.run(["cp", url_clean, str(target)], check=True)
            else:
                return None
        
        class_name = f"v{current_index + 1}"
        # Cycle index for the next download
        current_index = (current_index + 1) % MAX_BUFFERS
        return class_name
    except Exception:
        return None

def get_active_player():
    if not players:
        return None
    
    # Priority 1: Pick the most recently updated "Playing" media
    playing = [p for p in players.values() if p["status"].lower() == "playing"]
    if playing:
        return sorted(playing, key=lambda x: x["timestamp"], reverse=True)[0]
        
    # Priority 2: Fallback to "Paused" media
    paused = [p for p in players.values() if p["status"].lower() == "paused"]
    if paused:
        return sorted(paused, key=lambda x: x["timestamp"], reverse=True)[0]
        
    return None

def print_output():
    global last_emitted_url, last_emitted_title, last_emitted_status
    
    active = get_active_player()
    
    # Hide module if nothing is active or everything is stopped
    if not active or active["status"].lower() in ["stopped", ""]:
        if last_emitted_status != "stopped":
            print(json.dumps({"text": "", "class": "hidden"}), flush=True)
            last_emitted_status = "stopped"
            last_emitted_url = ""
        return

    status = active["status"]
    url = active["url"]
    title = active["title"]
    player_name = active["player_name"]

    if not url:
        if last_emitted_status != "no_art":
            print(json.dumps({"text": "", "class": "hidden"}), flush=True)
            last_emitted_status = "no_art"
            last_emitted_url = ""
        return

    # Trigger a download and UI refresh only if the URL actually changed
    if url != last_emitted_url:
        class_name = download_art(url)
        if class_name:
            output = {"text": " ", "class": class_name, "tooltip": f"{title} ({player_name}) [{status}]"}
            print(json.dumps(output), flush=True)
            last_emitted_status = status
            last_emitted_url = url
            last_emitted_title = title
        else:
            if last_emitted_status != "error":
                print(json.dumps({"text": "", "class": "hidden"}), flush=True)
                last_emitted_status = "error"
    else:
        # If the URL is identical but the title/status changed (e.g., pausing the track)
        if title != last_emitted_title or status != last_emitted_status:
            prev_index = (current_index - 1) % MAX_BUFFERS
            output = {"text": " ", "class": f"v{prev_index + 1}", "tooltip": f"{title} ({player_name}) [{status}]"}
            print(json.dumps(output), flush=True)
            last_emitted_status = status
            last_emitted_title = title

def main():
    # Initial state fetch
    # Using ;;; as a delimiter ensures song titles containing pipes (|) don't break the script
    cmd = ["playerctl", "metadata", "--format", "{{status}};;;{{mpris:artUrl}};;;{{title}};;;{{playerName}}"]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            parts = result.stdout.strip().split(";;;")
            if len(parts) >= 4:
                players[parts[3]] = {
                    "status": parts[0],
                    "url": urllib.parse.unquote(parts[1]),
                    "title": parts[2],
                    "player_name": parts[3],
                    "timestamp": time.time()
                }
    except Exception:
        pass
        
    print_output()

    # Continuous follow loop
    while True:
        try:
            proc = subprocess.Popen(
                ["playerctl", "metadata", "--format", "{{status}};;;{{mpris:artUrl}};;;{{title}};;;{{playerName}}", "--follow"],
                stdout=subprocess.PIPE,
                text=True
            )
            
            for line in proc.stdout:
                parts = line.strip().split(";;;")
                if len(parts) < 4:
                    continue
                    
                # Update the state tracker for whichever player emitted an event
                players[parts[3]] = {
                    "status": parts[0],
                    "url": urllib.parse.unquote(parts[1]),
                    "title": parts[2],
                    "player_name": parts[3],
                    "timestamp": time.time()
                }
                
                print_output()
            
            proc.wait()
        except Exception:
            print(json.dumps({"text": "", "class": "hidden"}), flush=True)
            time.sleep(2)

if __name__ == "__main__":
    main()
