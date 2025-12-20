#!/bin/bash
# Suminami Rice Installer
# https://github.com/lootmancerstudios/suminami

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }

# Check if running on Arch-based system
check_arch() {
    if ! command -v pacman &> /dev/null; then
        print_error "This installer requires an Arch-based distribution."
        exit 1
    fi
}

# Get or install AUR helper
# Handles the edge case where AUR helper breaks after system update
get_aur_helper() {
    local helper=""

    # Check for existing AUR helpers
    for h in yay paru; do
        if command -v "$h" &> /dev/null; then
            # Test if it actually works (libalpm might be mismatched)
            if "$h" --version &> /dev/null; then
                helper="$h"
                break
            else
                print_warning "$h is installed but broken (likely libalpm mismatch)"
                print_status "Rebuilding $h..."
                rebuild_aur_helper "$h"
                if "$h" --version &> /dev/null; then
                    helper="$h"
                    break
                fi
            fi
        fi
    done

    # If no working AUR helper, install yay-bin
    if [ -z "$helper" ]; then
        print_status "No AUR helper found. Installing yay..."
        install_yay
        helper="yay"
    fi

    echo "$helper"
}

# Rebuild a broken AUR helper
rebuild_aur_helper() {
    local helper="$1"
    local tmp_dir
    tmp_dir=$(mktemp -d)

    cd "$tmp_dir"
    git clone "https://aur.archlinux.org/${helper}-bin.git" 2>/dev/null || \
        git clone "https://aur.archlinux.org/${helper}.git"
    cd "${helper}"* 2>/dev/null || cd "$helper"

    # Remove the broken package first
    sudo pacman -Rdd "$helper" --noconfirm 2>/dev/null || true

    makepkg -si --noconfirm
    cd /
    rm -rf "$tmp_dir"
}

# Install yay from scratch
install_yay() {
    local tmp_dir
    tmp_dir=$(mktemp -d)

    print_status "Building yay-bin from AUR..."
    cd "$tmp_dir"
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd /
    rm -rf "$tmp_dir"
    print_success "yay installed successfully"
}

# Core dependencies (from official repos)
PACMAN_DEPS=(
    hyprland
    waybar
    kitty
    wofi
    dunst
    swaylock-effects
    swaybg
    grim
    slurp
    wl-clipboard
    brightnessctl
    playerctl
    pamixer
    ttf-jetbrains-mono-nerd
    jq
    socat
)

# AUR dependencies
AUR_DEPS=(
    walker-bin
)

# Install packages
install_packages() {
    local aur_helper
    aur_helper=$(get_aur_helper)

    print_status "Updating system..."
    sudo pacman -Syu --noconfirm

    # Re-check AUR helper after system update (libalpm might have changed)
    if ! "$aur_helper" --version &> /dev/null; then
        print_warning "AUR helper broke after system update, rebuilding..."
        rebuild_aur_helper "$aur_helper"
    fi

    print_status "Installing core dependencies..."
    sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}"

    print_status "Installing AUR packages..."
    "$aur_helper" -S --needed --noconfirm "${AUR_DEPS[@]}"

    print_success "All dependencies installed"
}

# Backup existing configs
backup_configs() {
    local backup_dir="$HOME/.config/suminami-backup-$(date +%Y%m%d-%H%M%S)"
    local configs_to_backup=(hypr waybar wofi walker dunst swaylock kitty)
    local backed_up=false

    for config in "${configs_to_backup[@]}"; do
        if [ -e "$HOME/.config/$config" ] && [ ! -L "$HOME/.config/$config" ]; then
            if [ "$backed_up" = false ]; then
                mkdir -p "$backup_dir"
                print_status "Backing up existing configs to $backup_dir"
                backed_up=true
            fi
            mv "$HOME/.config/$config" "$backup_dir/"
        fi
    done

    if [ "$backed_up" = true ]; then
        print_success "Configs backed up"
    fi
}

# Clone and setup suminami
setup_suminami() {
    local suminami_dir="$HOME/.config/suminami"

    if [ -d "$suminami_dir" ]; then
        print_status "Updating existing suminami installation..."
        cd "$suminami_dir"
        git pull
    else
        print_status "Cloning suminami..."
        git clone https://github.com/lootmancerstudios/suminami.git "$suminami_dir"
    fi

    print_success "Suminami repository ready"
}

# Create symlinks
create_symlinks() {
    local suminami_dir="$HOME/.config/suminami"
    local configs=(waybar wofi walker)

    print_status "Creating config symlinks..."

    for config in "${configs[@]}"; do
        if [ -d "$suminami_dir/config/$config" ]; then
            rm -rf "$HOME/.config/$config" 2>/dev/null || true
            ln -sfn "$suminami_dir/config/$config" "$HOME/.config/$config"
            print_success "  $config -> suminami/config/$config"
        fi
    done
}

# Main
main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}       ${GREEN}Suminami Rice Installer${NC}        ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo ""

    check_arch
    backup_configs
    install_packages
    setup_suminami
    create_symlinks

    echo ""
    print_success "Suminami installation complete!"
    print_status "Please log out and back in, or reboot."
    echo ""
}

main "$@"
