#!/bin/bash
# SumiNami Limine Theme Installer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUMINAMI_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[*]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[x]${NC} $1"; }

# Find Limine config
find_limine_config() {
    local locations=(
        "/boot/limine/limine.conf"
        "/boot/limine.conf"
        "/boot/EFI/limine/limine.conf"
        "/boot/efi/limine/limine.conf"
        "/efi/limine/limine.conf"
    )

    for loc in "${locations[@]}"; do
        if [ -f "$loc" ]; then
            echo "$loc"
            return 0
        fi
    done
    return 1
}

# Find boot partition mount point
find_boot_mount() {
    local config_path="$1"
    local boot_dir=$(dirname "$config_path")

    # Walk up to find the mount point
    while [ "$boot_dir" != "/" ]; do
        if mountpoint -q "$boot_dir" 2>/dev/null; then
            echo "$boot_dir"
            return 0
        fi
        boot_dir=$(dirname "$boot_dir")
    done

    # Fallback: assume /boot or /boot/EFI
    if [[ "$config_path" == /boot/* ]]; then
        echo "/boot"
        return 0
    fi

    return 1
}

# Main installation
main() {
    echo ""
    echo "  SumiNami Limine Theme Installer"
    echo "  ================================"
    echo ""

    # Check for Limine
    LIMINE_CONF=$(find_limine_config) || {
        print_error "Limine config not found. Is Limine installed?"
        exit 1
    }

    print_status "Found Limine config: $LIMINE_CONF"

    BOOT_MOUNT=$(find_boot_mount "$LIMINE_CONF") || {
        print_error "Could not determine boot partition mount point"
        exit 1
    }

    print_status "Boot partition: $BOOT_MOUNT"

    # Confirm
    echo ""
    read -p "Install SumiNami theme to Limine? [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Cancelled"
        exit 0
    fi

    # Backup existing config
    BACKUP="${LIMINE_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    print_status "Backing up to $BACKUP"
    sudo cp "$LIMINE_CONF" "$BACKUP"

    # Create wallpaper directory on boot partition
    WALLPAPER_DIR="$BOOT_MOUNT/suminami"
    print_status "Creating wallpaper directory: $WALLPAPER_DIR"
    sudo mkdir -p "$WALLPAPER_DIR"

    # Copy and dim wallpaper (use kanagawa as default)
    WALLPAPER_SRC="$SUMINAMI_DIR/wallpapers/kanagawa.jpg"
    if [ -f "$WALLPAPER_SRC" ]; then
        print_status "Creating dimmed wallpaper..."
        # mktemp avoids a predictable /tmp path (symlink pre-placement attack
        # surface). This file is read back by `sudo cp`, so a symlink planted at
        # a fixed path would be followed as root.
        TMP_WP=$(mktemp --suffix=.jpg)
        if command -v magick &>/dev/null; then
            magick "$WALLPAPER_SRC" -fill "rgba(0,0,0,0.7)" -draw "rectangle 0,0 10000,10000" "$TMP_WP"
        elif command -v convert &>/dev/null; then
            convert "$WALLPAPER_SRC" -fill "rgba(0,0,0,0.7)" -draw "rectangle 0,0 10000,10000" "$TMP_WP"
        else
            print_warning "ImageMagick not found, copying undimmed wallpaper"
            cp "$WALLPAPER_SRC" "$TMP_WP"
        fi
        sudo cp "$TMP_WP" "$WALLPAPER_DIR/wallpaper.jpg"
        rm -f "$TMP_WP"
    else
        print_warning "Wallpaper not found at $WALLPAPER_SRC"
    fi

    # Check if theme already applied
    if grep -q "SumiNami Limine Theme" "$LIMINE_CONF" 2>/dev/null; then
        print_warning "Theme already present in config, updating..."
        # Remove the old theme block (everything between the start and end markers).
        # Guard: with the start marker present but the end marker missing, the sed
        # range would run to EOF and delete the real boot entries, leaving an
        # unbootable config. Refuse and let the user clean up from the backup.
        if ! grep -q '^# --- End SumiNami ---$' "$LIMINE_CONF"; then
            print_error "Found the SumiNami start marker but not the end marker."
            print_error "Auto-removing the old block could truncate $LIMINE_CONF."
            print_error "A backup was saved to $BACKUP. Remove the SumiNami section manually, then re-run."
            exit 1
        fi
        sudo sed -i '/# SumiNami Limine Theme/,/^# --- End SumiNami ---$/d' "$LIMINE_CONF"
    fi

    # Prepend theme to config
    print_status "Applying theme..."

    # Create temp file with theme + original config
    TEMP_CONF=$(mktemp)
    cat "$SCRIPT_DIR/theme.conf" > "$TEMP_CONF"
    echo "" >> "$TEMP_CONF"
    echo "# --- End SumiNami ---" >> "$TEMP_CONF"
    echo "" >> "$TEMP_CONF"
    cat "$LIMINE_CONF" >> "$TEMP_CONF"

    sudo cp "$TEMP_CONF" "$LIMINE_CONF"
    rm "$TEMP_CONF"

    echo ""
    print_status "Limine theme installed successfully!"
    print_status "Backup saved to: $BACKUP"
    echo ""
    echo "  Reboot to see the new boot screen."
    echo ""
}

main "$@"
