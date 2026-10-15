# Omarchy dotfiles

Theme-matched widgets for the current **Omarchy Quickshell bar**:

- **Prayer times:** automatic city detection by public IP, Hanafi Asr, and a click-open timetable showing five prayers plus sunrise.
- **CPU and RAM:** icons with live percentages, detailed hover text, and click-to-open `btop`.
- **Notifications:** a bell opening recent history with a Do Not Disturb toggle.

Power profiles stay in the existing battery panel. An installed Slack status widget hides when empty.

## Install

Run in your Omarchy desktop session, **without sudo**:

```bash
sudo pacman -S --needed git jq curl btop
git clone https://github.com/abd-farooqi/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

Already cloned? Run `git pull --ff-only && ./setup.sh` from the repo.

The installer copies only these three plugins, merges their entries into your existing bar, backs up replaced files under `~/.local/state/dotfiles-backups/`, and restarts the shell. It preserves your theme, other widgets, shortcuts, and settings. Re-running it updates the widgets without duplicates. It does not install the other personal dotfiles in this repository.

## Use

| Widget | Action |
|---|---|
| Next prayer | Click for the full timetable; use Refresh to detect location again |
| CPU / memory icon | Hover for details; click for `btop` |
| Bell | Click for history; toggle Do Not Disturb inside |
| Battery | Existing power-profile controls |

Prayer location is checked every 15 minutes using [IPWhois](https://ipwhois.io/documentation); timings come from [AlAdhan](https://aladhan.com/prayer-times-api) using the Karachi method and Hanafi Asr. IP location is approximate and follows your VPN exit location. These are calculated prayer start times, not mosque jamaat times. Internet is required to load prayer times; network failures show a retry message.

CPU/RAM update every three seconds. RAM usage treats reclaimable cache as available. Notifications use Omarchy's existing local history; only notifications received by its daemon are available.

## Options and troubleshooting

```bash
./setup.sh --dry-run       # Validate without changing files
./setup.sh --no-restart    # Install, restart later
omarchy restart shell     # Reload widgets after changes
bash tests/setup.sh       # Test installation in temporary homes
node tests/models.cjs     # Optional: calculation tests (requires Node.js)
```

Requires the current Omarchy Quickshell shell with `qs.Ui.KeyboardPanel` and its bundled Nerd Font. Legacy Waybar installations are not supported by this installer. Prayer dates and next-prayer selection use the detected city's timezone.

If prayer times do not load, check access to `ipwho.is` and `api.aladhan.com`, then click Refresh. If icons look like boxes, restore your Omarchy Nerd Font.

Backups contain the previous `shell.json` and any replaced plugin directories. Restore the desired backup files into `~/.config/omarchy/`, then run `omarchy restart shell`.

Widget sources live in `.config/omarchy/plugins/abdullah.{prayer-times,system-usage,desktop-status}/`. The installer copies them, so later local changes are not automatically committed to this repo. Older application dotfiles and Waybar helper scripts remain available for manual use.
