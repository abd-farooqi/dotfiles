#!/bin/bash

WALLPAPER="$HOME/.config/omarchy/current/background"

# Kill swaybg if running (started by Omarchy default)
pkill -x swaybg 2>/dev/null

# Start awww-daemon if not already running
if ! awww query &>/dev/null; then
    setsid awww-daemon &>/dev/null & disown
    sleep 0.3
fi

# Set the wallpaper via Omarchy symlink
if [[ -L "$WALLPAPER" ]]; then
    TARGET=$(readlink "$WALLPAPER")
    awww img "$TARGET" 2>/dev/null || true
else
    # Fallback to first GIF in backgrounds dir
    FIRST=$(find "$HOME/.config/omarchy/current/theme/backgrounds" -maxdepth 1 -name '*.gif' -print -quit 2>/dev/null)
    [[ -n "$FIRST" ]] && awww img "$FIRST" 2>/dev/null || true
fi
