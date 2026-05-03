#!/bin/bash

CACHE="/tmp/network_speed.cache"
INTERFACE=$(ip route get 1 | awk '{print $5; exit}')

rx_now=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes 2>/dev/null)
tx_now=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes 2>/dev/null)

if [[ -z "$rx_now" || -z "$tx_now" ]]; then
    printf '{"text":"󰇚","tooltip":"Network unavailable","class":""}\n'
    exit 0
fi

if [[ -f "$CACHE" ]]; then
    read -r rx_old tx_old time_old < "$CACHE"
    elapsed=$(( $(date +%s%N) - time_old ))
    if (( elapsed > 0 )); then
        rx_speed=$(( (rx_now - rx_old) * 1000000000 / elapsed ))
        tx_speed=$(( (tx_now - tx_old) * 1000000000 / elapsed ))
    else
        rx_speed=0
        tx_speed=0
    fi
else
    rx_speed=0
    tx_speed=0
fi

echo "$rx_now $tx_now $(date +%s%N)" > "$CACHE"

fmt() {
    local val=$1
    if (( val >= 1000000 )); then
        printf "%.1f MB/s" "$(awk "BEGIN { printf \"%.1f\", $val / 1000000 }" 2>/dev/null)"
    elif (( val >= 1000 )); then
        printf "%.0f KB/s" "$(awk "BEGIN { printf \"%.0f\", $val / 1000 }" 2>/dev/null)"
    else
        printf "%d B/s" "$val"
    fi
}

down=$(fmt "$rx_speed")
up=$(fmt "$tx_speed")

TOOLTIP="󰇚 Download: $down\n󰗐 Upload: $up\n󰖟 Interface: $INTERFACE"
printf '{"text":"󰇚","tooltip":"%s","class":""}\n' "$TOOLTIP"
