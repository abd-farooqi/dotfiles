#!/usr/bin/env bash
set -euo pipefail
umask 077

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
omarchy_path="${OMARCHY_PATH:-/usr/share/omarchy}"
config_root="$HOME/.config/omarchy"
plugin_ids=(abdullah.prayer-times abdullah.system-usage abdullah.desktop-status)
restart=true
dry_run=false

usage() {
  printf '%s\n' 'Usage: ./setup.sh [--dry-run] [--no-restart]' \
    'Install the prayer, CPU/RAM, and notification widgets into Omarchy Quickshell.' \
    'Existing layout/settings are preserved; replaced files are backed up.'
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --no-restart) restart=false ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; usage >&2; exit 1 ;;
  esac
done

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }

for dependency in jq curl; do
  command -v "$dependency" >/dev/null || fail "Missing $dependency. Run: sudo pacman -S --needed jq curl"
done
[[ -f "$omarchy_path/shell/shell.qml" && -f "$omarchy_path/shell/Ui/KeyboardPanel.qml" ]] \
  || fail 'This setup requires the current Omarchy Quickshell bar, not legacy Waybar.'
if $restart; then
  command -v omarchy >/dev/null || fail 'omarchy is not on PATH. Run inside your Omarchy desktop session.'
fi

input_config="$config_root/shell.json"
if [[ ! -e "$input_config" ]]; then
  [[ ! -L "$input_config" ]] || fail 'shell.json is a broken symlink.'
  input_config="$omarchy_path/config/omarchy/shell.json"
fi
[[ -f "$input_config" ]] || fail 'No existing or stock Omarchy shell.json found.'
jq -e '
  type == "object" and (.bar | type == "object") and
  (.bar.layout | type == "object") and
  all(.bar.layout | .left, .center, .right;
    . == null or (type == "array" and all(.[]; type == "object" and (.id | type == "string"))))
' "$input_config" >/dev/null || fail 'shell.json is invalid or uses an unsupported bar layout.'

for id in "${plugin_ids[@]}"; do
  source_dir="$repo_dir/.config/omarchy/plugins/$id"
  [[ -d "$source_dir" && -f "$source_dir/BarWidget.qml" ]] || fail "Missing bundled plugin: $id"
  jq -e --arg id "$id" '.id == $id and .schemaVersion == 1' "$source_dir/manifest.json" >/dev/null \
    || fail "Invalid manifest: $id"
  [[ ! -e "$config_root/plugins/$id" || -d "$config_root/plugins/$id" ]] \
    || fail "Plugin target is not a directory: $id"
done

if $dry_run; then
  printf '%s\n' 'Ready: prayer times, CPU/RAM icons, and notification history.' \
    "Target: $config_root" 'No files changed.'
  exit 0
fi

merged_config="$(mktemp -t omarchy-bar-setup.XXXXXX)"
trap 'rm -f -- "$merged_config"' EXIT
jq '
  def custom: . == "abdullah.prayer-times" or . == "abdullah.system-usage" or . == "abdullah.desktop-status";
  def entries: [.bar.layout | .left, .center, .right | (. // [])[]];
  def widget($id): (first(entries[] | select(.id == $id)) // {id: $id});
  widget("abdullah.prayer-times") as $prayer |
  widget("abdullah.system-usage") as $usage |
  widget("abdullah.desktop-status") as $notifications |
  .bar.layout |= with_entries(
    if (.key == "left" or .key == "center" or .key == "right") then
      .value = [(.value // [])[] | select(.id | custom | not)]
    else . end) |
  .bar.layout.center = ((.bar.layout.center // []) + [$prayer]) |
  .bar.layout.right = ([$usage, $notifications] + (.bar.layout.right // [])) |
  .bar.layout |= with_entries(
    if (.key == "left" or .key == "center" or .key == "right") then
      .value |= map(if .id == "petrzpav.slack" then .hideWhenRead = true else . end)
    else . end)
' "$input_config" > "$merged_config"

backup_root="$HOME/.local/state/dotfiles-backups"
mkdir -p -- "$backup_root"
backup_dir="$(mktemp -d "$backup_root/omarchy-bar-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
mkdir -p -- "$backup_dir/plugins" "$config_root/plugins"
if [[ -f "$config_root/shell.json" ]]; then
  cp -L -- "$config_root/shell.json" "$backup_dir/shell.json"
fi
for id in "${plugin_ids[@]}"; do
  target="$config_root/plugins/$id"
  if [[ -d "$target" ]]; then
    cp -aL -- "$target" "$backup_dir/plugins/$id"
  fi
  if [[ -L "$target" ]]; then
    unlink -- "$target"
  fi
  mkdir -p -- "$target"
  cp -R -- "$repo_dir/.config/omarchy/plugins/$id/." "$target/"
done
mv -f -- "$merged_config" "$config_root/shell.json"

printf 'Installed. Backup: %s\n' "$backup_dir"
if $restart; then
  if ! omarchy restart shell; then
    fail 'Files installed, but the bar could not restart. Run: omarchy restart shell'
  fi
else
  printf '%s\n' 'Restart when ready: omarchy restart shell'
fi
printf '%s\n' 'Prayer times detect your city by IP. CPU/RAM and the bell are on the right.'
