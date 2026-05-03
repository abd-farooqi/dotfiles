# Live Wallpapers

Animated/live wallpaper system for Omarchy + Hyprland using `mpvpaper`.

## Requirements

- `mpvpaper` — video wallpaper daemon (install from AUR)
- `mpv` — video player backend
- `hyprctl` — monitor detection

## Wallpaper Locations

All wallpapers go in: `~/.config/live-wallpapers/`

Supported formats: `.mp4`, `.webm`, `.gif`, `.mkv`

### Adding Wallpapers

```bash
# Copy your own
cp ~/Downloads/my-wallpaper.mp4 ~/.config/live-wallpapers/

# Download from the web
curl -Lo ~/.config/live-wallpapers/example.mp4 "https://example.com/video.mp4"
```

Wallpapers are detected automatically — no config changes needed.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Super + Shift + W` | Random wallpaper |
| `Super + Ctrl + W` | Next wallpaper (in order) |
| `Super + Alt + W` | Stop live wallpaper |

## Scripts

| Script | Path | Purpose |
|--------|------|---------|
| `start-wallpaper.sh` | `~/.config/hypr/scripts/` | Auto-starts random wallpaper on login |
| `next-wallpaper.sh` | `~/.config/hypr/scripts/` | Cycle to next wallpaper |
| `random-wallpaper.sh` | `~/.config/hypr/scripts/` | Pick random wallpaper |
| `stop-wallpaper.sh` | `~/.config/hypr/scripts/` | Stop mpvpaper, restore swaybg |

## Manual Commands

```bash
# Start a specific wallpaper
mpvpaper -f -s -o "no-audio loop" eDP-1 ~/.config/live-wallpapers/example.mp4

# Stop all wallpapers
pkill mpvpaper

# Restart swaybg
uwsm-app -- swaybg -i ~/.config/omarchy/current/background -m fill &
```

## Disabling Autostart

Edit `~/.config/hypr/autostart.conf` and comment out or remove:

```
# exec-once = $HOME/.config/hypr/scripts/start-wallpaper.sh
```

## Performance Notes

For Intel UHD 620 graphics, mpvpaper runs with:
- `hwdec=vaapi` — hardware decoding
- `vo=gpu` — GPU-based video output
- `auto-stop` — pauses when covered by windows
- `no-audio` — no audio decoding needed

If you experience high CPU usage, try adding to `~/.config/mpv/mpv.conf`:

```
profile=gpu-hq
scale=bilinear
dscale=bilinear
cscale=bilinear
```

Or use lower resolution wallpapers (1080p instead of 4K).
