#!/bin/bash

freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
max=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null)
gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)

if [[ -z "$freq" ]]; then
    printf '{"text":"󰻠","tooltip":"CPU freq unavailable","class":""}\n'
    exit 0
fi

freq_ghz=$(awk "BEGIN { printf \"%.2f\", $freq / 1000000 }" 2>/dev/null)
max_ghz=$(awk "BEGIN { printf \"%.2f\", $max / 1000000 }" 2>/dev/null)
pct=$(awk "BEGIN { printf \"%.0f\", $freq * 100 / $max }" 2>/dev/null)

TOOLTIP="󰻠 ${freq_ghz}GHz / ${max_ghz}GHz (${pct}%)\n󰒟 Governor: ${gov}"
printf '{"text":"󰻠","tooltip":"%s","class":""}\n' "$TOOLTIP"
