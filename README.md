# Dotfiles

Personal Linux configuration files for [Omarchy](https://omarchy.org/), an Arch Linux distribution built on Hyprland.

```text
┌─────────────────────────────────────────────────────┐
│   1 2 3 4 5         󰥔 󰅟 12:00 PM             │
│               󰇚 󰍛 󰻠 󰑭 󰔄 󰢮 󰖣 󰋊 73% 󰂅 │
└─────────────────────────────────────────────────────┘
```

## Prerequisites

- **Omarchy** (or any Arch/Hyprland setup — configs may still work with adaptation)
- **Git** — to clone the repo
- **sudo** access — for dependency installation

## Quick Start

```bash
git clone git@github.com:abd-farooqi/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The setup script will:

1. Install dependencies (`jq`, `curl`, `power-profiles-daemon`, `intel-gpu-tools`)
2. Prompt for your git name and email
3. Back up any existing config to `~/.dotfiles-backup-<timestamp>`
4. Symlink all files from the repo into `~/.config/`
5. Auto-detect machine-specific paths (CPU temperature sensor, GPU card)
6. Restart Waybar if running

## Directory Structure

```
dotfiles/
├── setup.sh                 # One-command install script
├── .bashrc                  # Shell configuration
├── .config/
│   ├── hypr/                # Hyprland window manager
│   │   ├── hyprland.conf    # Main compositor config
│   │   ├── bindings.conf    # Keybindings (Super + ...)
│   │   ├── monitors.conf    # Display layout
│   │   ├── input.conf       # Keyboard, mouse, touchpad
│   │   ├── looknfeel.conf   # Gaps, borders, animations
│   │   ├── autostart.conf   # Startup applications
│   │   ├── hypridle.conf    # Idle/suspend behavior
│   │   ├── hyprlock.conf    # Lock screen appearance
│   │   └── hyprsunset.conf  # Night light
│   ├── waybar/              # Status bar
│   │   ├── config.jsonc     # Bar layout & modules
│   │   ├── style.css        # Bar styling
│   │   └── scripts/         # Custom modules
│   │       ├── prayer.sh          # Islamic prayer times
│   │       ├── weather.sh         # Live weather
│   │       ├── network-speed.sh   # Download/upload speed
│   │       ├── cpu-freq.sh        # CPU clock frequency
│   │       ├── gpu-stats.sh       # Intel GPU frequency
│   │       └── power-profile.sh   # Power profile switcher
│   ├── walker/              # Application launcher
│   ├── mako/                # Notification daemon
│   ├── btop/                # System monitor
│   │   └── themes/          # Custom Catppuccin theme
│   ├── fastfetch/           # System info fetcher
│   ├── swayosd/             # On-screen display
│   ├── nvim/                # Neovim (LazyVim)
│   ├── lazygit/             # Git TUI
│   ├── git/
│   │   └── config           # Git configuration (run setup.sh)
│   └── starship.toml        # Shell prompt theme
```

## Waybar Modules

All right-side modules display **icons only** to save space on laptop screens. Hover for tooltips with full details.

| Position | Module | Icon | Tooltip | Click |
|----------|--------|------|---------|-------|
| Left | Omarchy menu |  | — | Opens menu |
| Left | Workspaces | 1 2 3 ... | — | Switch workspace |
| Center | Prayer times | 󰥔 | 5 prayer times + countdown | — |
| Center | Weather | 󰅟 | Temp, humidity, wind, UV | — |
| Center | Clock | 12:00 PM | Calendar | — |
| Right | Network speed | 󰇚 | Download/Upload | — |
| Right | CPU | 󰍛 | — | Opens btop |
| Right | CPU frequency | 󰻠 | GHz + governor | — |
| Right | Memory | 󰑭 | — | Opens btop |
| Right | Temperature | 󰔄 | — | Opens btop |
| Right | GPU stats | 󰢮 | Freq MHz | — |
| Right | Power profile | 󰖣 | Current + available | Cycles profile |
| Right | Disk | 󰋊 | Usage info | — |
| Right | Battery | 73% 󰂅 | Charge/discharge info | Power menu |

### Prayer Times

- Uses [AlAdhan API](https://aladhan.com/) with automatic location detection
- Shows Fajr, Dhuhr, Asr, Maghrib, Isha in tooltip
- Countdown to the next prayer
- Handles end-of-day correctly (after Isha → next Fajr)
- Caches API response for 1 hour

### Weather

- Uses [Open-Meteo API](https://open-meteo.com/) (free, no API key)
- Shows condition, temperature, humidity, wind, UV in tooltip
- Caches for 30 minutes

### Network Speed

- Reads `/proc/net/dev` deltas
- Shows live download/upload in tooltip
- Auto-detects active network interface

### GPU Stats

- Reads Intel GPU frequency from sysfs (`/sys/class/drm/card*/`)
- Auto-detects the correct DRM card — works with different hardware
- For GPU load percentage, install `intel-gpu-tools`:
  ```bash
  sudo pacman -S intel-gpu-tools
  ```

### Power Profile

- Uses `powerprofilesctl` (from `power-profiles-daemon`)
- Three states: `󰓅` performance / `󰖣` balanced / `󰾆` power-saver
- Click to cycle between profiles

## Machine-Specific Values

Some paths differ between machines. The `setup.sh` script auto-detects these:

- **CPU temperature**: Scans `/sys/class/hwmon/` for `coretemp` sensor and writes the path to Waybar config
- **GPU card**: Finds the first DRM card with Intel GPU frequency files

If you run `setup.sh` on a new machine and it misdetects, you can manually override:

```bash
# Find CPU temp sensor manually
for d in /sys/class/hwmon/hwmon*; do echo "$(cat $d/name) → $d"; done

# Find GPU card manually
ls /sys/class/drm/card*/gt_cur_freq_mhz 2>/dev/null
```

## Troubleshooting

### Prayer module shows `...` or `ERR`

| Cause | Fix |
|-------|-----|
| No internet | Check connection |
| `jq` not installed | `sudo pacman -S jq` |
| `curl` not installed | `sudo pacman -S curl` |
| API rate limited | Wait 1 minute — cache will serve stale data |
| Location blocked | Ensure `ipinfo.io` / `ipapi.co` is reachable |

### Weather module unavailable

Same as prayer — check `jq`, `curl`, and internet. Weather also needs `LOC` coordinates from `ipinfo.io/loc`.

### Temperature module blank

The setup script should auto-detect this, but verify:

```bash
# Check coretemp exists
cat /sys/class/hwmon/hwmon*/name | grep coretemp

# Check the Waybar config has the path
grep hwmon-path ~/.config/waybar/config.jsonc
```

If missing, manually add to `~/.config/waybar/config.jsonc` in the `temperature` block:

```jsonc
"temperature": {
    "interval": 5,
    "hwmon-path": "/sys/class/hwmon/hwmonX/temp1_input",  // ← replace X
    "format": "󰔄",
    "critical-threshold": 85,
    "on-click": "omarchy-launch-or-focus-tui btop",
},
```

### GPU stats unavailable

```bash
# Check if Intel GPU frequency files exist
ls /sys/class/drm/card*/gt_cur_freq_mhz
```

If no files, your GPU isn't Intel or uses a different driver. The module will show "unavailable" silently.

### Waybar not updating

```bash
# Restart Waybar
omarchy-restart-waybar

# Or kill and restart
killall waybar && waybar &
```

### Module doesn't appear

Check the Waybar config for typos:

```bash
# Verify module name in modules-left/center/right
# Verify module definition exists in the JSON
# Check bar height — compact mode needs enough room
```

Check Waybar logs:

```bash
journalctl --user -u waybar -n 50 --no-pager
```

### Config changes not applying

Waybar does **not** auto-reload on config changes. You must restart it:

```bash
omarchy-restart-waybar
```

### Scripts failing silently

Run any script directly to see errors:

```bash
bash -x ~/.config/waybar/scripts/prayer.sh
bash -x ~/.config/waybar/scripts/network-speed.sh
```

## Dependencies

| Package | Required by | Install |
|---------|------------|---------|
| `jq` | prayer.sh, weather.sh | `sudo pacman -S jq` |
| `curl` | prayer.sh, weather.sh | `sudo pacman -S curl` |
| `power-profiles-daemon` | power-profile.sh | `sudo pacman -S power-profiles-daemon` |
| `intel-gpu-tools` | GPU load % (optional) | `sudo pacman -S intel-gpu-tools` |
| `bc` | Some scripts (optional) | `sudo pacman -S bc` |

## Manual Installation

If you prefer not to use `setup.sh`:

```bash
# 1. Clone
git clone git@github.com:abd-farooqi/dotfiles.git ~/dotfiles

# 2. Back up existing config
mv ~/.config ~/.config.bak

# 3. Symlink
ln -sf ~/dotfiles/.config ~/.config
ln -sf ~/dotfiles/.bashrc ~/.bashrc

# 4. Configure git identity
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# 5. Detect CPU temp sensor
HWMON=$(for d in /sys/class/hwmon/hwmon*; do
    [[ "$(cat $d/name 2>/dev/null)" == "coretemp" ]] && echo "$d/temp1_input" && break
done)
if [[ -n "$HWMON" ]]; then
    echo "Coretemp at: $HWMON"
    # Add hwmon-path to waybar config manually
fi

# 6. Restart Waybar
killall waybar && waybar &
```

## How It Works

The repo uses **symlinks**, not copies. After `setup.sh`:

- `~/.config/waybar/` → `~/dotfiles/.config/waybar/`
- `~/.bashrc` → `~/dotfiles/.bashrc`

Any change you make to a file in `~/.config/` is automatically reflected in the repo. Just `git commit` and `git push` to save changes.

## Reverting

If something goes wrong, restore from backup:

```bash
# List backups
ls -d ~/.dotfiles-backup-*

# Restore
rm -rf ~/.config
cp -r ~/.dotfiles-backup-<timestamp>/.config ~/.config
```
