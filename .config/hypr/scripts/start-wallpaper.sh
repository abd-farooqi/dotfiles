#!/bin/bash

# Live Wallpaper Auto-Start Script
# Launches a random wallpaper on login via mpvpaper
# Integrated with Omarchy/Hyprland

WALLPAPER_DIR="$HOME/.config/live-wallpapers"
STATE_FILE="/tmp/live-wallpaper-current"
CACHE_FILE="/tmp/live-wallpaper-list"

# Detect primary monitor
MONITOR=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].name // "eDP-1"')

# Build list of wallpapers (supported formats)
find_wallpapers() {
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \( \
        -iname '*.mp4' -o \
        -iname '*.webm' -o \
        -iname '*.gif' -o \
        -iname '*.mkv' \) 2>/dev/null | sort
}

# Kill existing wallpaper processes
kill_existing() {
    pkill -x mpvpaper 2>/dev/null
    pkill -x mpvpaper-holder 2>/dev/null
    pkill -x swaybg 2>/dev/null
    sleep 0.3
}

# Launch wallpaper with mpvpaper
launch() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        notify-send "Wallpaper" "File not found: $file" -t 2000
        exit 1
    fi

    kill_existing

    # Intel UHD 620 optimization: vaapi hwdec, no-audio, loop
    # Use -s (auto-stop) to save CPU when windows cover wallpaper
    setsid mpvpaper -f -s -o "no-audio loop vo=gpu hwdec=vaapi" "$MONITOR" "$file" >/dev/null 2>&1 &
    disown

    echo "$file" > "$STATE_FILE"
    BASENAME=$(basename "$file")
    notify-send "Wallpaper" "Now playing: $BASENAME" -t 1500
}

# Main
WALLPAPERS=()
while IFS= read -r f; do
    WALLPAPERS+=("$f")
done < <(find_wallpapers)

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    notify-send "Wallpaper" "No wallpapers found in $WALLPAPER_DIR" -t 3000
    exit 1
fi

# Pick random wallpaper
RANDOM_INDEX=$((RANDOM % ${#WALLPAPERS[@]}))
launch "${WALLPAPERS[$RANDOM_INDEX]}"
