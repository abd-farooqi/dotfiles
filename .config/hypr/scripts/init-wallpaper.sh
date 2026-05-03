#!/bin/bash

WALLPAPER="$HOME/Pictures/wallpapers/animated-city.gif"

# Kill swaybg if running (started by Omarchy default)
pkill -x swaybg 2>/dev/null

# Start awww-daemon if not already running
if ! awww query &>/dev/null; then
    setsid awww-daemon &>/dev/null & disown
    sleep 0.3
fi

# Set the animated wallpaper
awww img "$WALLPAPER" 2>/dev/null || true
