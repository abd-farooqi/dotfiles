#!/bin/bash

pkill -x mpvpaper 2>/dev/null
pkill -x mpvpaper-holder 2>/dev/null
rm -f /tmp/live-wallpaper-current

# Restore Omarchy swaybg background
if [[ -L "$HOME/.config/omarchy/current/background" ]]; then
    setsid uwsm-app -- swaybg -i "$HOME/.config/omarchy/current/background" -m fill >/dev/null 2>&1 &
    disown
fi

notify-send "Wallpaper" "Live wallpaper stopped" -t 1500
