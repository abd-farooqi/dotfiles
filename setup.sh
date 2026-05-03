#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { printf "${GREEN}✓${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}⚠${NC} %s\n" "$1"; }
err()  { printf "${RED}✗${NC} %s\n" "$1"; }
info() { printf "${CYAN}→${NC} %s\n" "$1"; }

header() {
    printf "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${CYAN}  %s${NC}\n" "$1"
    printf "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"
}

detect_pkg_manager() {
    if command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
        PKG_INSTALL="sudo pacman -S --needed --noconfirm"
    elif command -v apt &>/dev/null; then
        PKG_MANAGER="apt"
        PKG_INSTALL="sudo apt install -y"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        PKG_INSTALL="sudo dnf install -y"
    elif command -v zypper &>/dev/null; then
        PKG_MANAGER="zypper"
        PKG_INSTALL="sudo zypper install -y"
    else
        PKG_MANAGER=""
        warn "No known package manager found. Install dependencies manually."
    fi
}

install_deps() {
    header "Installing Dependencies"

    local packages=()

    if ! command -v jq &>/dev/null; then packages+=(jq); fi
    if ! command -v curl &>/dev/null; then packages+=(curl); fi
    if ! command -v powerprofilesctl &>/dev/null; then
        case "$PKG_MANAGER" in
            pacman) packages+=(power-profiles-daemon) ;;
            apt)    packages+=(power-profiles-daemon) ;;
            dnf)    packages+=(power-profiles-daemon) ;;
            zypper) packages+=(power-profiles-daemon) ;;
        esac
    fi
    if ! ls /sys/class/drm/card*/gt_cur_freq_mhz &>/dev/null 2>&1; then
        case "$PKG_MANAGER" in
            pacman) packages+=(intel-gpu-tools) ;;
        esac
    fi

    if [[ ${#packages[@]} -gt 0 && -n "$PKG_MANAGER" ]]; then
        info "Installing: ${packages[*]}"
        $PKG_INSTALL "${packages[@]}" || warn "Some packages failed to install"
    else
        log "All dependencies already satisfied"
    fi
}

prompt_git_user() {
    header "Git Identity"

    if [[ -f "$DOTFILES_DIR/.config/git/config" ]]; then
        local has_name has_email
        has_name=$(grep -c '^\tname =' "$DOTFILES_DIR/.config/git/config" 2>/dev/null || true)
        has_email=$(grep -c '^\temail =' "$DOTFILES_DIR/.config/git/config" 2>/dev/null || true)
        if [[ "$has_name" -gt 0 || "$has_email" -gt 0 ]]; then
            log "Git identity already configured in repo"
            return
        fi
    fi

    printf "Enter your git name (leave blank to skip): "
    read -r git_name
    printf "Enter your git email (leave blank to skip): "
    read -r git_email

    if [[ -n "$git_name" || -n "$git_email" ]]; then
        {
            echo ""
            echo "[user]"
            [[ -n "$git_name" ]]  && echo "	name = $git_name"
            [[ -n "$git_email" ]] && echo "	email = $git_email"
        } >> "$DOTFILES_DIR/.config/git/config"
        log "Git identity saved to .config/git/config"
    else
        warn "Skipped git identity setup"
    fi
}

backup_existing() {
    header "Backing Up Existing Config"

    local dirs=()
    while IFS= read -r -d '' d; do
        dirs+=("$d")
    done < <(find "$DOTFILES_DIR/.config" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

    local has_backup=false
    for dir in "${dirs[@]}"; do
        local rel="${dir#$DOTFILES_DIR/}"
        local target="$HOME/$rel"
        if [[ -e "$target" && ! -L "$target" ]]; then
            mkdir -p "$BACKUP_DIR/$rel"
            cp -r "$target" "$BACKUP_DIR/${rel%/*}/" 2>/dev/null || true
            has_backup=true
        fi
    done

    if [[ -f "$HOME/.bashrc" ]]; then
        cp "$HOME/.bashrc" "$BACKUP_DIR/.bashrc" 2>/dev/null || true
        has_backup=true
    fi

    if $has_backup; then
        log "Backed up to: $BACKUP_DIR"
    else
        info "No existing config to back up"
    fi
}

symlink_config() {
    header "Symlinking Config Files"

    mkdir -p "$HOME/.config"

    while IFS= read -r -d '' f; do
        local rel="${f#$DOTFILES_DIR/}"
        local target="$HOME/$rel"
        mkdir -p "$(dirname "$target")"

        if [[ -L "$target" ]]; then
            rm "$target"
        elif [[ -e "$target" ]]; then
            warn "File exists at $rel — skipping (backed up above)"
            continue
        fi

        ln -sf "$f" "$target"
        log "Linked $rel"
    done < <(find "$DOTFILES_DIR/.config" -type f -print0 2>/dev/null)

    if [[ -f "$DOTFILES_DIR/.bashrc" ]]; then
        if [[ -L "$HOME/.bashrc" ]]; then
            rm "$HOME/.bashrc"
        elif [[ -e "$HOME/.bashrc" ]]; then
            warn "File exists at .bashrc — skipping"
        else
            ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
            log "Linked .bashrc"
        fi
    fi

    while IFS= read -r -d '' d; do
        local rel="${d#$DOTFILES_DIR/}"
        local target="$HOME/$rel"
        mkdir -p "$target"
        log "Created dir $rel"
    done < <(find "$DOTFILES_DIR/.config" -type d -empty -print0 2>/dev/null) || true
}

detect_hwmon() {
    for d in /sys/class/hwmon/hwmon*; do
        local name
        name=$(cat "$d/name" 2>/dev/null)
        if [[ "$name" == "coretemp" ]]; then
            echo "$d/temp1_input"
            return
        fi
    done
    echo ""
}

configure_machine_specific() {
    header "Machine-Specific Configuration"

    local hwmon
    hwmon=$(detect_hwmon)
    if [[ -n "$hwmon" ]]; then
        local waybar_config="$DOTFILES_DIR/.config/waybar/config.jsonc"
        if grep -q '"temperature"' "$waybar_config" && ! grep -q '"hwmon-path"' "$waybar_config"; then
            sed -i '/"temperature": {/,/},/{
                /"format": "󰔄",/a\
    "hwmon-path": "'"$hwmon"'",
            }' "$waybar_config"
            log "Detected coretemp at $hwmon — wrote to waybar config"
        fi
    else
        warn "No coretemp sensor found — temperature module may not display"
    fi

    local gpu_card=""
    for d in /sys/class/drm/card*; do
        if [[ -f "$d/gt_cur_freq_mhz" ]]; then
            gpu_card=$(basename "$d")
            break
        fi
    done
    if [[ -n "$gpu_card" ]]; then
        log "Detected GPU at $gpu_card"
    else
        warn "No Intel GPU found — GPU stats module may not display"
    fi
}

restart_waybar() {
    header "Finalizing"

    if command -v omarchy-restart-waybar &>/dev/null; then
        info "Restarting Waybar..."
        omarchy-restart-waybar 2>/dev/null || true
        log "Waybar restarted"
    elif command -v waybar &>/dev/null && pgrep -x waybar &>/dev/null; then
        info "Restarting Waybar..."
        killall -SIGUSR2 waybar 2>/dev/null || killall -q waybar 2>/dev/null || true
        sleep 0.5
        waybar &>/dev/null &
        disown
        log "Waybar restarted"
    else
        info "Waybar not running — start it manually or reboot"
    fi
}

main() {
    printf "\n"
    printf "${CYAN}  ╔═══════════════════════════════════════╗${NC}\n"
    printf "${CYAN}  ║        Dotfiles Setup Script          ║${NC}\n"
    printf "${CYAN}  ╚═══════════════════════════════════════╝${NC}\n\n"

    detect_pkg_manager
    install_deps
    prompt_git_user
    backup_existing
    symlink_config
    configure_machine_specific
    restart_waybar

    printf "\n${GREEN}  Done!${NC} Config files are symlinked to ${CYAN}%s${NC}\n" "$DOTFILES_DIR"
    printf "  Changes in ${CYAN}~/.config/${NC} are automatically tracked by git.\n"
    printf "  Backup of previous config: ${YELLOW}%s${NC}\n\n" "$BACKUP_DIR"
}

main "$@"
