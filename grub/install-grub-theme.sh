#!/bin/bash
# SumiNami GRUB Theme Installer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUMINAMI_DIR="$(dirname "$SCRIPT_DIR")"
THEME_NAME="suminami"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }

# Check if GRUB is installed
check_grub() {
    if [ ! -f /etc/default/grub ]; then
        print_error "GRUB configuration not found at /etc/default/grub"
        print_error "Is GRUB installed?"
        return 1
    fi

    if ! command -v grub-mkconfig &>/dev/null; then
        print_error "grub-mkconfig not found"
        return 1
    fi

    return 0
}

# Find GRUB themes directory
find_themes_dir() {
    local dirs=(
        "/boot/grub/themes"
        "/boot/grub2/themes"
        "/usr/share/grub/themes"
    )

    for dir in "${dirs[@]}"; do
        if [ -d "$(dirname "$dir")" ]; then
            echo "$dir"
            return 0
        fi
    done

    # Default to /boot/grub/themes
    echo "/boot/grub/themes"
}

# Create dimmed background
create_background() {
    local wallpaper="$1"
    local output="$2"

    if [ ! -f "$wallpaper" ]; then
        print_warning "Wallpaper not found: $wallpaper"
        return 1
    fi

    print_status "Creating dimmed background..."

    if command -v magick &>/dev/null; then
        magick "$wallpaper" -fill "rgba(0,0,0,0.6)" -draw "rectangle 0,0 10000,10000" "$output"
    elif command -v convert &>/dev/null; then
        convert "$wallpaper" -fill "rgba(0,0,0,0.6)" -draw "rectangle 0,0 10000,10000" "$output"
    else
        print_warning "ImageMagick not found, copying undimmed wallpaper"
        cp "$wallpaper" "$output"
    fi

    return 0
}

# Main installation
main() {
    echo ""
    echo -e "${BLUE}SumiNami GRUB Theme Installer${NC}"
    echo ""

    # Check for GRUB
    if ! check_grub; then
        exit 1
    fi

    print_success "GRUB detected"

    # Find themes directory
    THEMES_DIR=$(find_themes_dir)
    THEME_DEST="$THEMES_DIR/$THEME_NAME"

    print_status "Theme will be installed to: $THEME_DEST"

    # Confirm
    echo ""
    read -p "Install SumiNami GRUB theme? [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Cancelled"
        exit 0
    fi

    # Backup existing GRUB config
    BACKUP="/etc/default/grub.backup.$(date +%Y%m%d_%H%M%S)"
    print_status "Backing up /etc/default/grub to $BACKUP"
    sudo cp /etc/default/grub "$BACKUP"

    # Create themes directory if needed
    print_status "Creating theme directory..."
    sudo mkdir -p "$THEME_DEST"

    # Copy theme files
    print_status "Copying theme files..."
    sudo cp "$SCRIPT_DIR/$THEME_NAME/theme.txt" "$THEME_DEST/"
    sudo cp "$SCRIPT_DIR/$THEME_NAME/select_"*.png "$THEME_DEST/"

    # Create background from wallpaper
    WALLPAPER="$SUMINAMI_DIR/wallpapers/kanagawa.jpg"
    TMP_BG="/tmp/suminami-grub-bg.png"

    if create_background "$WALLPAPER" "$TMP_BG"; then
        sudo cp "$TMP_BG" "$THEME_DEST/background.png"
        rm -f "$TMP_BG"
        print_success "Background created"
    else
        # Create a solid color fallback background
        print_status "Creating solid color background..."
        if command -v magick &>/dev/null; then
            magick -size 1920x1080 xc:'#1F1F28' "$TMP_BG"
        else
            convert -size 1920x1080 xc:'#1F1F28' "$TMP_BG"
        fi
        sudo cp "$TMP_BG" "$THEME_DEST/background.png"
        rm -f "$TMP_BG"
    fi

    # Set permissions
    sudo chmod -R 755 "$THEME_DEST"

    # Update GRUB config
    print_status "Updating GRUB configuration..."

    THEME_PATH="$THEME_DEST/theme.txt"

    # Check if GRUB_THEME is already set
    if grep -q "^GRUB_THEME=" /etc/default/grub; then
        # Replace existing GRUB_THEME line
        sudo sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$THEME_PATH\"|" /etc/default/grub
    elif grep -q "^#GRUB_THEME=" /etc/default/grub; then
        # Uncomment and set
        sudo sed -i "s|^#GRUB_THEME=.*|GRUB_THEME=\"$THEME_PATH\"|" /etc/default/grub
    else
        # Append
        echo "GRUB_THEME=\"$THEME_PATH\"" | sudo tee -a /etc/default/grub > /dev/null
    fi

    # Ensure GRUB_GFXMODE is set for graphical theme
    if ! grep -q "^GRUB_GFXMODE=" /etc/default/grub; then
        echo 'GRUB_GFXMODE=auto' | sudo tee -a /etc/default/grub > /dev/null
    fi

    # Regenerate GRUB config
    print_status "Regenerating GRUB configuration..."

    if [ -f /boot/grub/grub.cfg ]; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    elif [ -f /boot/grub2/grub.cfg ]; then
        sudo grub-mkconfig -o /boot/grub2/grub.cfg
    else
        print_warning "Could not find grub.cfg location"
        print_warning "You may need to run grub-mkconfig manually"
    fi

    echo ""
    print_success "GRUB theme installed successfully!"
    print_status "Backup saved to: $BACKUP"
    echo ""
    echo "  Reboot to see the new boot screen."
    echo ""
}

main "$@"
