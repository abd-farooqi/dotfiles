#!/bin/bash

DIR="$HOME/Pictures/wallpapers"
WALLPAPERS=(
    "$DIR/animated-mountain.gif"
    "$DIR/animated-milkyway.gif"
    "$DIR/animated-moonforest.gif"
    "$DIR/animated-waterfall.gif"
    "$DIR/animated-hawthorn.gif"
    "$DIR/animated-road.gif"
    "$DIR/animated-motorcycle.gif"
    "$DIR/animated-cyberpunk.gif"
    "$DIR/animated-neon.gif"
    "$DIR/animated-city.gif"
    "$DIR/animated-moon.gif"
    "$DIR/animated-gaming.gif"
    "$DIR/animated-workspace.gif"
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

awww img "${WALLPAPERS[0]}" 2>/dev/null
notify-send "Wallpaper" "Switched to mountain" -t 1500
