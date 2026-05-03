#!/bin/bash
DIR="$HOME/Pictures/wallpapers"
mkdir -p "$DIR"
echo "Downloading animated wallpapers..."
curl -sfL "https://raw.githubusercontent.com/dharmx/walls/main/animated/moon.gif" -o "$DIR/animated-moon.gif" &
curl -sfL "https://raw.githubusercontent.com/dharmx/walls/main/animated/city.gif" -o "$DIR/animated-city.gif" &
curl -sfL "https://raw.githubusercontent.com/dharmx/walls/main/animated/box.gif" -o "$DIR/animated-box.gif" &
wait
echo "Done"
