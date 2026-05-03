#!/bin/bash

DIR="$HOME/Pictures/wallpapers"
mkdir -p "$DIR"

echo "Downloading animated wallpapers..."

# Original GIFs (small)
curl -sfL "https://raw.githubusercontent.com/dharmx/walls/main/animated/city.gif" -o "$DIR/animated-city.gif" &
curl -sfL "https://raw.githubusercontent.com/dharmx/walls/main/animated/moon.gif" -o "$DIR/animated-moon.gif" &
curl -sfL "https://raw.githubusercontent.com/dharmx/walls/main/animated/box.gif" -o "$DIR/animated-box.gif" &

# MP4-based wallpapers (download then convert)
download_and_convert() {
    local url="$1" name="$2"
    local tmp="/tmp/wall_$$.mp4"
    curl -sfL "$url" -o "$tmp" && \
    ffmpeg -y -i "$tmp" -vf "fps=8,scale=960:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=64:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" -loop 0 "$DIR/animated-${name}.gif" 2>/dev/null
    rm -f "$tmp"
}

download_and_convert "https://raw.githubusercontent.com/dharmx/walls/main/animated/breathe.mp4" "breathe" &
download_and_convert "https://raw.githubusercontent.com/dharmx/walls/main/animated/totoro-in-the-rain-moewalls-com.mp4" "totoro-rain" &

wait
echo "Done! $(ls $DIR/animated-*.gif 2>/dev/null | wc -l) wallpapers in $DIR"
