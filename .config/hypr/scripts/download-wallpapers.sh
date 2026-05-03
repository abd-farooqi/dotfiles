#!/bin/bash
DIR="$HOME/.config/omarchy/current/theme/backgrounds"
mkdir -p "$DIR"

echo "Downloading animated wallpapers..."
curl -sfL "https://raw.githubusercontent.com/dharmx/walls/main/animated/moon.gif" -o "$DIR/moon.gif" &
curl -sfL "https://raw.githubusercontent.com/dharmx/walls/main/animated/city.gif" -o "$DIR/city.gif" &
curl -sfL "https://raw.githubusercontent.com/dharmx/walls/main/animated/box.gif" -o "$DIR/box.gif" &
curl -sfL "https://raw.githubusercontent.com/dharmx/walls/main/animated/fireplace.gif" -o "$DIR/fireplace.gif" &
wait
echo "Done"
