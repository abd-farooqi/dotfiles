#!/bin/bash

# Extracts a frame from the current live wallpaper for Hyprlock
# Hyprlock will apply its own blur_passes on top

FILE="$1"
OUTPUT="/tmp/live-wallpaper-lock.png"

if [[ ! -f "$FILE" ]]; then
    exit 1
fi

# Extract first frame, scale to FHD, crop to fill screen
ffmpeg -y -i "$FILE" -vframes 1 \
    -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080" \
    "$OUTPUT" 2>/dev/null

# Also symlink for the Omarchy background path so other tools can find it
ln -sf "$OUTPUT" /tmp/live-wallpaper-omarchy-bg 2>/dev/null || true
