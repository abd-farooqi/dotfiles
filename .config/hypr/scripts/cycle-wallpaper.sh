#!/bin/bash

DIR="$HOME/.config/omarchy/current/theme/backgrounds"
CURRENT_LINK="$HOME/.config/omarchy/current/background"

# Find all GIF and PNG/JPG files in backgrounds dir
mapfile -d '' WALLPAPERS < <(find "$DIR" -maxdepth 1 -type f \( -iname '*.gif' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print0 2>/dev/null | sort -z)

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    notify-send "Wallpaper" "No wallpapers found" -t 2000
    exit 1
fi

if [[ -L "$CURRENT_LINK" ]]; then
    CURRENT=$(readlink "$CURRENT_LINK")
else
    CURRENT="${WALLPAPERS[0]}"
fi

for i in "${!WALLPAPERS[@]}"; do
    if [[ "${WALLPAPERS[$i]}" == "$CURRENT" ]]; then
        NEXT=$(( (i + 1) % ${#WALLPAPERS[@]} ))
        ln -nsf "${WALLPAPERS[$NEXT]}" "$CURRENT_LINK"
        awww img "${WALLPAPERS[$NEXT]}" 2>/dev/null
        BASENAME=$(basename "${WALLPAPERS[$NEXT]}")
        notify-send "Wallpaper" "Switched to $BASENAME" -t 1500
        exit 0
    fi
done

ln -nsf "${WALLPAPERS[0]}" "$CURRENT_LINK"
awww img "${WALLPAPERS[0]}" 2>/dev/null
notify-send "Wallpaper" "Switched to $(basename "${WALLPAPERS[0]}")" -t 1500
