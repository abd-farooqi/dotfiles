#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d -t omarchy-setup-test.XXXXXX)"
trap 'rm -rf -- "$test_dir"' EXIT
test_home="$test_dir/home with spaces"
test_omarchy="$test_dir/omarchy"
mkdir -p "$test_home/.config/omarchy" "$test_omarchy/shell/Ui" "$test_omarchy/config/omarchy"
cp "$repo_dir/tests/fixtures/shell.json" "$test_home/.config/omarchy/shell.json"
cp "$repo_dir/tests/fixtures/shell.json" "$test_omarchy/config/omarchy/shell.json"
cp "$repo_dir/tests/fixtures/shell.json" "$test_omarchy/shell/shell.qml"
cp "$repo_dir/tests/fixtures/shell.json" "$test_omarchy/shell/Ui/KeyboardPanel.qml"

run_setup() { HOME="$test_home" OMARCHY_PATH="$test_omarchy" bash "$repo_dir/setup.sh" --no-restart "$@"; }
config="$test_home/.config/omarchy/shell.json"

run_setup --dry-run
cmp "$config" "$repo_dir/tests/fixtures/shell.json"
[[ ! -e "$test_home/.local/state/dotfiles-backups" ]]
run_setup
jq -e '
  .bar.position == "bottom" and .bar.transparent == true and .idle.lock == 777 and
  .bar.layout.left[0].keep == 123 and .bar.layout.center[0].format == "HH:mm" and
  .plugins[0].id == "custom.service" and
  any(.bar.layout.right[]; .id == "petrzpav.slack" and .hideWhenRead == true) and
  any(.bar.layout.right[]; .id == "omarchy.power" and .showPercentage == true)
' "$config" >/dev/null
for id in abdullah.prayer-times abdullah.system-usage abdullah.desktop-status; do
  diff -r "$repo_dir/.config/omarchy/plugins/$id" "$test_home/.config/omarchy/plugins/$id"
done
backup="$(find "$test_home/.local/state/dotfiles-backups" -name shell.json -print -quit)"
cmp "$backup" "$repo_dir/tests/fixtures/shell.json"
cp "$config" "$test_dir/first-install.json"
run_setup
cmp "$config" "$test_dir/first-install.json"
jq -e '[.bar.layout | .left, .center, .right | .[] | select(.id | startswith("abdullah."))] | length == 3' "$config" >/dev/null
printf '%s\n' 'PASS: dry run, existing settings, installed sources, backup, repeated installation'

bad_home="$test_dir/malformed"
mkdir -p "$bad_home/.config/omarchy"
cp "$repo_dir/README.md" "$bad_home/.config/omarchy/shell.json"
if HOME="$bad_home" OMARCHY_PATH="$test_omarchy" bash "$repo_dir/setup.sh" --no-restart > "$test_dir/invalid.log" 2>&1; then
  printf '%s\n' 'FAIL: malformed config accepted' >&2; exit 1
fi
cmp "$bad_home/.config/omarchy/shell.json" "$repo_dir/README.md"
[[ ! -e "$bad_home/.config/omarchy/plugins" ]]
printf '%s\n' 'PASS: malformed config rejected before changes'

fresh_home="$test_dir/fresh"
mkdir -p "$fresh_home"
HOME="$fresh_home" OMARCHY_PATH="$test_omarchy" bash "$repo_dir/setup.sh" --no-restart
jq -e 'any(.bar.layout.center[]; .id == "abdullah.prayer-times")' "$fresh_home/.config/omarchy/shell.json" >/dev/null
printf '%s\n' 'PASS: fresh home uses stock shell configuration'

cp "$config" "$test_dir/before-override.json"
jq '(.bar.layout.center[] | select(.id == "abdullah.prayer-times")).customSetting = "keep"' "$config" > "$test_dir/override.json"
cp "$test_dir/override.json" "$config"
run_setup
jq -e 'any(.bar.layout.center[]; .id == "abdullah.prayer-times" and .customSetting == "keep")' "$config" >/dev/null
printf '%s\n' 'PASS: existing widget settings preserved'

mv "$config" "$test_dir/linked-shell.json"
cp "$test_dir/linked-shell.json" "$test_dir/linked-shell-before.json"
ln -s "$test_dir/linked-shell.json" "$config"
plugin="$test_home/.config/omarchy/plugins/abdullah.system-usage"
mv "$plugin" "$test_dir/linked-plugin"
ln -s "$test_dir/linked-plugin" "$plugin"
run_setup
[[ ! -L "$config" && ! -L "$plugin" ]]
cmp "$test_dir/linked-shell.json" "$test_dir/linked-shell-before.json"
diff -r "$repo_dir/.config/omarchy/plugins/abdullah.system-usage" "$test_dir/linked-plugin"
printf '%s\n' 'PASS: symlink targets remain untouched and local copies are installed'
