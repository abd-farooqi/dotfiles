#!/bin/bash

WALLPAPER_DIR="$HOME/.config/live-wallpapers"
STATE_FILE="/tmp/live-wallpaper-current"
MONITOR=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].name // "eDP-1"')

WALLPAPERS=()
while IFS= read -r f; do
    WALLPAPERS+=("$f")
done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.gif' -o -iname '*.mkv' \) 2>/dev/null | sort)

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    notify-send "Wallpaper" "No wallpapers found" -t 2000
    exit 1
fi

RANDOM_INDEX=$((RANDOM % ${#WALLPAPERS[@]}))
FILE="${WALLPAPERS[$RANDOM_INDEX]}"

pkill -x mpvpaper 2>/dev/null
pkill -x mpvpaper-holder 2>/dev/null
pkill -x swaybg 2>/dev/null
sleep 0.3

setsid mpvpaper -f -s -o "no-audio loop vo=gpu hwdec=vaapi" "$MONITOR" "$FILE" >/dev/null 2>&1 &
disown

echo "$FILE" > "$STATE_FILE"
BASENAME=$(basename "$FILE")
notify-send "Wallpaper" "Random: $BASENAME" -t 1500
