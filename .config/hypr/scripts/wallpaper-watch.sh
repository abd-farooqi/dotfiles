#!/bin/bash

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -U - "UNIX-CONNECT:$SOCKET" 2>/dev/null | while read -r event; do
  case "$event" in
    monitoradded\>\>*|monitoraddedv2\>\>*)
      sleep 0.5
      awww restore 2>/dev/null || true
      ;;
  esac
done
