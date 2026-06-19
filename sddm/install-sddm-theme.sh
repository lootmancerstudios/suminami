#!/bin/bash
# SumiNami SDDM Theme Installer

set -e

THEME_DIR="/usr/share/sddm/themes/suminami"
SOURCE_DIR="$(dirname "$(readlink -f "$0")")/suminami"

echo "Installing SumiNami SDDM theme..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script needs root privileges to install the theme."
    echo "Running with sudo..."
    exec sudo "$0" "$@"
fi

# Copy theme files
if [ -d "$SOURCE_DIR" ]; then
    # Back up any existing theme before replacing it (matches the GRUB/Limine installers)
    if [ -d "$THEME_DIR" ]; then
        BACKUP="${THEME_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "Backing up existing theme to $BACKUP"
        cp -r "$THEME_DIR" "$BACKUP"
        rm -rf "$THEME_DIR"
    fi
    cp -r "$SOURCE_DIR" "$THEME_DIR"
    echo "Theme files installed to $THEME_DIR"
else
    echo "Error: Theme source not found at $SOURCE_DIR"
    exit 1
fi

# Configure SDDM to use the theme
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/suminami.conf << EOF
[Theme]
Current=suminami
EOF

echo "SDDM configured to use SumiNami theme"
echo ""
echo "Done! The theme will be active on next login."
echo "To preview, run: sddm-greeter-qt6 --test-mode --theme $THEME_DIR"
