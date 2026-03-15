#!/usr/bin/env python3

import os
import subprocess
import json
import urllib.request
import time
import sys
from pathlib import Path

# Paths
TMP_DIR = Path("/tmp/waybar-media")
TMP_DIR.mkdir(parents=True, exist_ok=True)

ART_FILES = [TMP_DIR / "art1.png", TMP_DIR / "art2.png"]
LAST_ART_URL = ""
LAST_STATUS = ""
LAST_TITLE = ""
CURRENT_INDEX = 0
LAST_CLASS = "v1"

def get_metadata():
    try:
        # Get status, art URL, title, and player name
        cmd = ["playerctl", "metadata", "--format", "{{status}}|{{mpris:artUrl}}|{{title}}|{{playerName}}"]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            return None, None, None, None
        
        parts = result.stdout.strip().split("|")
        if not parts or len(parts) < 1:
            return None, None, None, None
            
        status = parts[0]
        art_url = parts[1] if len(parts) > 1 else ""
        title = parts[2] if len(parts) > 2 else "Unknown"
        player = parts[3] if len(parts) > 3 else "Unknown"
        
        return status, art_url, title, player
    except Exception:
        return None, None, None, None

def download_art(url):
    global CURRENT_INDEX, LAST_ART_URL, LAST_CLASS
    if not url:
        return None
    
    # If URL is the same, don't re-download and don't swap class
    if url == LAST_ART_URL and os.path.exists(ART_FILES[1 - CURRENT_INDEX]):
        return LAST_CLASS

    target = ART_FILES[CURRENT_INDEX]
    try:
        url_clean = url.strip()
        
        if url_clean.startswith("file://"):
            src = url_clean[7:]
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
        
        LAST_CLASS = f"v{CURRENT_INDEX + 1}"
        CURRENT_INDEX = 1 - CURRENT_INDEX
        LAST_ART_URL = url
        return LAST_CLASS
    except Exception:
        return None

def print_output(status, url, title, player):
    global LAST_STATUS, LAST_TITLE, LAST_ART_URL
    
    # If no player or stopped, hide
    if not status or status.lower() == "stopped":
        if LAST_STATUS != "stopped":
            print(json.dumps({"text": "", "class": "hidden"}), flush=True)
            LAST_STATUS = "stopped"
            LAST_ART_URL = ""
        return

    # If no URL, hide
    if not url:
        if LAST_STATUS != "no_art":
            print(json.dumps({"text": "", "class": "hidden"}), flush=True)
            LAST_STATUS = "no_art"
            LAST_ART_URL = ""
        return

    # Download or get current class
    class_name = download_art(url)
    
    if class_name:
        # Only print if something meaningful changed to reduce Waybar overhead
        if status != LAST_STATUS or url != LAST_ART_URL or title != LAST_TITLE:
            output = {"text": " ", "class": class_name, "tooltip": f"{title} ({player}) [{status}]"}
            print(json.dumps(output), flush=True)
            LAST_STATUS = status
            LAST_TITLE = title
    else:
        if LAST_STATUS != "error":
            print(json.dumps({"text": "", "class": "hidden"}), flush=True)
            LAST_STATUS = "error"

def main():
    # Initial state
    status, url, title, player = get_metadata()
    print_output(status, url, title, player)

    while True:
        try:
            # We follow both metadata and status changes
            proc = subprocess.Popen(
                ["playerctl", "metadata", "--format", "{{status}}|{{mpris:artUrl}}|{{title}}|{{playerName}}", "--follow"],
                stdout=subprocess.PIPE,
                text=True
            )
            
            for line in proc.stdout:
                parts = line.strip().split("|")
                if len(parts) < 1:
                    continue
                
                status = parts[0]
                url = parts[1] if len(parts) > 1 else ""
                title = parts[2] if len(parts) > 2 else "Unknown"
                player = parts[3] if len(parts) > 3 else "Unknown"
                
                print_output(status, url, title, player)
            
            proc.wait()
        except Exception:
            print(json.dumps({"text": "", "class": "hidden"}), flush=True)
            time.sleep(2)
        
        time.sleep(1)

if __name__ == "__main__":
    main()
