#!/bin/bash
OUTPUT="$HOME/Pictures/wallpapers/awww_gradient.gif"
W=1600
H=900

# Colors for gradient transitions (pairs of dark aesthetic colors)
COLORS=(
    "#1a1b2e;#2d2b55"   # dark purple
    "#1a1b2e;#1e2a4a"   # dark blue
    "#1a1b2e;#2a2a3e"   # dark mauve
    "#1a1b2e;#1e3a3a"   # dark teal
    "#1a1b2e;#3a2a3e"   # dark plum
)

FRAMES=""
TEMP_DIR=$(mktemp -d)
for i in "${!COLORS[@]}"; do
    IFS=';' read -r c1 c2 <<< "${COLORS[$i]}"
    convert -size ${W}x${H} gradient:"$c1"-"$c2" "$TEMP_DIR/frame_$(printf "%02d" $i).png"
    FRAMES="$FRAMES $TEMP_DIR/frame_$(printf "%02d" $i).png"
done

# Also create reverse for smoother loop
for i in $(seq $((${#COLORS[@]}-2)) -1 1); do
    IFS=';' read -r c1 c2 <<< "${COLORS[$i]}"
    convert -size ${W}x${H} gradient:"$c1"-"$c2" "$TEMP_DIR/frame_$(printf "%02d" $((10-i))).png"
    FRAMES="$FRAMES $TEMP_DIR/frame_$(printf "%02d" $((10-i))).png"
done

convert -delay 200 -loop 0 $FRAMES "$OUTPUT"
rm -rf "$TEMP_DIR"
echo "Created: $OUTPUT"
