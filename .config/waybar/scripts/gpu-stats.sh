#!/bin/bash

GPU_FREQ=$(cat /sys/class/drm/card1/gt_cur_freq_mhz 2>/dev/null)
GPU_MAX=$(cat /sys/class/drm/card1/gt_max_freq_mhz 2>/dev/null)

if [[ -n "$GPU_FREQ" && -n "$GPU_MAX" ]]; then
    pct=$(awk "BEGIN { printf \"%.0f\", $GPU_FREQ * 100 / $GPU_MAX }" 2>/dev/null)
    TOOLTIP="󰢮 Intel GPU\n󰻠 ${GPU_FREQ}/${GPU_MAX} MHz (${pct}%)"
    printf '{"text":"󰢮","tooltip":"%s","class":""}\n' "$TOOLTIP"
else
    printf '{"text":"󰢮","tooltip":"GPU stats unavailable","class":""}\n'
fi
