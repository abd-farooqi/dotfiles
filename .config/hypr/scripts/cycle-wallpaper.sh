#!/bin/bash

DIR="$HOME/Pictures/wallpapers"
WALLPAPERS=(
    "$DIR/animated-city.gif"
    "$DIR/animated-moon.gif"
    "$DIR/animated-box.gif"
    "$DIR/animated-breathe.gif"
    "$DIR/animated-bocchi.gif"
    "$DIR/animated-hawthorn.gif"
    "$DIR/animated-starwars.gif"
    "$DIR/animated-train-station.gif"
    "$DIR/animated-totoro.gif"
    "$DIR/animated-totoro-rain.gif"
    "$DIR/animated-totoro-starry.gif"
)

CURRENT=$(awww query 2>/dev/null | grep -oP 'image: \K.*' | head -1)

for i in "${!WALLPAPERS[@]}"; do
    if [[ "${WALLPAPERS[$i]}" == "$CURRENT" ]]; then
        NEXT=$(( (i + 1) % ${#WALLPAPERS[@]} ))
        awww img "${WALLPAPERS[$NEXT]}" 2>/dev/null
        BASENAME=$(basename "${WALLPAPERS[$NEXT]}" .gif | sed 's/animated-//')
        notify-send "Wallpaper" "Switched to $BASENAME" -t 1500
        exit 0
    fi
done

# Fallback: set first one
awww img "${WALLPAPERS[0]}" 2>/dev/null
notify-send "Wallpaper" "Switched to city" -t 1500
