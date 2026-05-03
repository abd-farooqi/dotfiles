#!/bin/bash

PROFILE=$(powerprofilesctl get 2>/dev/null)

case "$PROFILE" in
    performance) ICON="󰓅" ;;
    power-saver) ICON="󰾆" ;;
    balanced)    ICON="󰖣" ;;
    *)           ICON="󰖣" ; PROFILE="unknown" ;;
esac

AVAIL=$(powerprofilesctl list 2>/dev/null | awk '/:$/ { gsub(/^[* ]* */, ""); gsub(/:$/, ""); printf "%s ", $1 }' | xargs)

TOOLTIP="󰓅 Profile: ${PROFILE}\n󰋜 Available: ${AVAIL}"
printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$ICON" "$TOOLTIP" "$PROFILE"
