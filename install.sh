#!/bin/bash
# Suminami Rice Installer
# https://github.com/lootmancerstudios/suminami
#
# Error handling: Critical operations (package install, git clone) check exit codes
# explicitly. Non-critical operations (file cleanup, optional tools) may fail silently.

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

# Show help message
show_help() {
    echo "Suminami Rice Installer"
    echo "https://github.com/lootmancerstudios/suminami"
    echo ""
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message and exit"
    echo ""
    echo "Run without options for interactive installation."
    echo ""
    echo "The installer will:"
    echo "  - Install Hyprland and required packages"
    echo "  - Clone/update the suminami repository"
    echo "  - Create symlinks for configs"
    echo "  - Optionally install: screen locker, clipboard manager, SDDM theme"
    echo ""
}

# Check if running as root (should not)
check_not_root() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Do not run this script as root or with sudo."
        print_error "The script will ask for sudo when needed."
        exit 1
    fi
}

# Check if running on Arch-based system
check_arch() {
    if ! command -v pacman &> /dev/null; then
        print_error "This installer requires an Arch-based distribution."
        exit 1
    fi
}

# Check for required base tools
check_base_tools() {
    local missing=()

    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi

    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi

    # Check for base-devel (needed for AUR)
    if ! pacman -Qq base-devel &> /dev/null 2>&1; then
        missing+=("base-devel")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        print_status "Installing required base tools: ${missing[*]}"
        sudo pacman -S --needed --noconfirm "${missing[@]}"
    fi
}

# Check internet connectivity (uses HTTP, not ICMP which may be blocked)
check_internet() {
    print_status "Checking internet connectivity..."
    if ! curl -s --head --max-time 5 https://archlinux.org >/dev/null 2>&1; then
        if ! curl -s --head --max-time 5 https://github.com >/dev/null 2>&1; then
            print_error "No internet connection detected."
            print_error "Please connect to the internet and try again."
            exit 1
        fi
    fi
    print_success "Internet connection OK"
}

# Show summary and confirm before installing
confirm_install() {
    echo ""
    echo -e "${BLUE}The following will be installed/configured:${NC}"
    echo ""
    echo "  Core: Hyprland, Waybar, Rofi, Kitty, Dunst"
    echo "  Apps: Firefox, Thunar, Yazi, btop"
    echo "  Tools: Screenshots, notifications, media controls"
    echo "  Theme: GTK themes, Papirus icons, Bibata cursor"
    echo ""
    echo "  Optional prompts will follow for:"
    echo "    - Screen locker & idle management"
    echo "    - Clipboard persistence"
    echo "    - SDDM login theme"
    echo "    - TUI enhancements"
    echo ""
    read -p "Proceed with installation? [Y/n] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_status "Installation cancelled."
        exit 0
    fi
}

# Detect and configure GPU (NVIDIA specifically)
configure_gpu() {
    local has_nvidia_hw=false
    local has_nvidia_drv=false

    print_status "Detecting GPU..."

    # Detect NVIDIA hardware
    if lspci | grep -iq nvidia; then
        has_nvidia_hw=true
    fi

    # Check if NVIDIA proprietary driver is loaded
    if lsmod | grep -q "^nvidia"; then
        has_nvidia_drv=true
    fi

    # Handle NVIDIA
    if [ "$has_nvidia_hw" = true ]; then
        if [ "$has_nvidia_drv" = true ]; then
            echo ""
            echo -e "${BLUE}NVIDIA GPU Detected${NC}"
            echo "  Proprietary driver is loaded"
            echo "  Recommended: Apply NVIDIA-specific environment variables"
            echo "  This fixes common issues (flickering, cursor, performance)"
            echo ""
            read -p "Apply NVIDIA configuration? [Y/n] " -n 1 -r
            echo ""

            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                create_nvidia_config
            else
                print_status "Skipping NVIDIA configuration"
            fi
        else
            echo ""
            print_warning "NVIDIA hardware detected but proprietary driver not loaded"
            print_warning "You appear to be using nouveau (open-source driver)"
            print_warning "For best Hyprland experience, consider installing nvidia or nvidia-dkms"
            echo ""
        fi
    else
        print_success "GPU detected (Intel/AMD) - no special configuration needed"
    fi
}

# Create NVIDIA configuration file
# Writes to user-local directory (not inside suminami repo) to avoid git conflicts
create_nvidia_config() {
    local nvidia_dir="$HOME/.config/hypr-local"
    local nvidia_conf="$nvidia_dir/nvidia.conf"
    local hyprland_conf="$HOME/.config/hypr/hyprland.conf"

    print_status "Creating NVIDIA configuration..."

    # Create user-local hypr config directory (outside suminami repo)
    mkdir -p "$nvidia_dir"

    # Create nvidia.conf
    cat > "$nvidia_conf" << 'EOF'
# SumiNami NVIDIA Configuration
# See: https://wiki.hypr.land/Nvidia/

# Hardware acceleration
env = LIBVA_DRIVER_NAME,nvidia

# Required for XWayland apps
env = __GLX_VENDOR_LIBRARY_NAME,nvidia

# Enable VRR/G-Sync (if supported)
env = __GL_VRR_ALLOWED,1

# Use software cursor (fixes invisible/glitchy cursor)
cursor:no_hardware_cursors = true
EOF

    print_success "Created $nvidia_conf"

    # Add source line to hyprland.conf if not already present
    if [ -f "$hyprland_conf" ]; then
        if ! grep -q "source.*nvidia.conf" "$hyprland_conf"; then
            # Find the line with monitors.conf and add nvidia.conf after it
            if grep -q "source.*monitors.conf" "$hyprland_conf"; then
                sed -i '/source.*monitors.conf/a source = ~/.config/hypr-local/nvidia.conf' "$hyprland_conf"
                print_success "Added nvidia.conf to hyprland.conf"
            else
                # Fallback: append to end of file
                echo "" >> "$hyprland_conf"
                echo "# NVIDIA configuration (user-local)" >> "$hyprland_conf"
                echo "source = ~/.config/hypr-local/nvidia.conf" >> "$hyprland_conf"
                print_success "Appended nvidia.conf to hyprland.conf"
            fi
        else
            print_status "nvidia.conf already sourced in hyprland.conf"
        fi
    fi

    print_success "NVIDIA configuration applied"
    echo ""
    echo "  Note: If you experience issues, you may also need:"
    echo "    - nvidia_drm.modeset=1 in kernel parameters"
    echo "    - See: https://wiki.hypr.land/Nvidia/"
    echo ""
}

# Get or install AUR helper
# Handles the edge case where AUR helper breaks after system update
# Note: All status messages go to stderr to avoid polluting stdout return value
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
                print_warning "$h is installed but broken (likely libalpm mismatch)" >&2
                print_status "Rebuilding $h..." >&2
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
        print_status "No AUR helper found. Installing yay..." >&2
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

    # Cleanup on exit or error
    trap 'rm -rf "$tmp_dir"' EXIT

    cd "$tmp_dir"
    git clone "https://aur.archlinux.org/${helper}-bin.git" 2>/dev/null || \
        git clone "https://aur.archlinux.org/${helper}.git"
    cd "${helper}"* 2>/dev/null || cd "$helper"

    # Remove the broken package first
    sudo pacman -Rdd "$helper" --noconfirm 2>/dev/null || true

    makepkg -si --noconfirm
    cd /

    # Clear trap and cleanup
    trap - EXIT
    rm -rf "$tmp_dir"
}

# Install yay from scratch
install_yay() {
    local tmp_dir
    tmp_dir=$(mktemp -d)

    # Cleanup on exit or error
    trap 'rm -rf "$tmp_dir"' EXIT

    print_status "Building yay-bin from AUR..." >&2
    cd "$tmp_dir"

    if ! git clone https://aur.archlinux.org/yay-bin.git; then
        print_error "Failed to clone yay-bin from AUR" >&2
        exit 1
    fi

    cd yay-bin

    if ! makepkg -si --noconfirm; then
        print_error "Failed to build yay" >&2
        exit 1
    fi

    cd /

    # Clear trap and cleanup
    trap - EXIT
    rm -rf "$tmp_dir"
    print_success "yay installed successfully" >&2
}

# Core dependencies (from official repos)
PACMAN_DEPS=(
    hyprland
    awww
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    waybar
    kitty
    rofi-wayland
    dunst
    grim
    slurp
    hyprshot
    wl-clipboard
    brightnessctl
    playerctl
    pamixer
    hyprpicker
    gammastep
    wf-recorder
    pavucontrol
    libnotify
    ttf-jetbrains-mono-nerd
    firefox
    jq
    socat
    qt6-declarative
    qt6-svg
    imagemagick
    btop
    python-pipx
    papirus-icon-theme
    lm_sensors
    polkit-gnome
    # File managers
    thunar
    gvfs
    tumbler
    yazi
    # Yazi optional deps
    ffmpeg
    7zip
    poppler
    fd
    ripgrep
    fzf
    zoxide
)

# AUR dependencies
AUR_DEPS=(
    bibata-cursor-theme-bin
)

# Install packages
install_packages() {
    local aur_helper
    aur_helper=$(get_aur_helper)

    print_status "Updating system..."
    if ! sudo pacman -Syu --noconfirm; then
        print_error "System update failed"
        exit 1
    fi

    # Re-check AUR helper after system update (libalpm might have changed)
    if ! "$aur_helper" --version &> /dev/null; then
        print_warning "AUR helper broke after system update, rebuilding..."
        rebuild_aur_helper "$aur_helper"
    fi

    # Handle awww/swww rename: fall back to swww if awww isn't in repos
    if ! pacman -Si awww &>/dev/null; then
        if pacman -Si swww &>/dev/null; then
            print_warning "Package 'awww' not found, using 'swww' instead"
            PACMAN_DEPS=("${PACMAN_DEPS[@]/awww/swww}")
        else
            print_warning "Neither awww nor swww found in repos — wallpaper daemon will be unavailable"
            PACMAN_DEPS=("${PACMAN_DEPS[@]/awww/}")
        fi
    fi

    print_status "Installing core dependencies..."
    if ! sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}"; then
        print_error "Failed to install core dependencies"
        exit 1
    fi

    # Only install AUR packages if there are any
    if [ ${#AUR_DEPS[@]} -gt 0 ]; then
        print_status "Installing AUR packages (this may take a few minutes)..."
        if ! "$aur_helper" -S --needed --noconfirm "${AUR_DEPS[@]}"; then
            print_error "Failed to install AUR packages"
            exit 1
        fi
    fi

    print_success "All dependencies installed"
}

# Backup existing configs
backup_configs() {
    local backup_dir="$HOME/.config/suminami-backup-$(date +%Y%m%d-%H%M%S)"
    local configs_to_backup=(hypr waybar rofi dunst swaylock kitty)
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
        if ! git -C "$suminami_dir" pull; then
            print_error "Failed to update suminami repository"
            print_error "You may have local changes. Try: cd $suminami_dir && git status"
            exit 1
        fi
    else
        print_status "Cloning suminami..."
        if ! git clone https://github.com/lootmancerstudios/suminami.git "$suminami_dir"; then
            print_error "Failed to clone suminami repository"
            print_error "Check your internet connection and try again"
            exit 1
        fi
    fi

    print_success "Suminami repository ready"
}

# Create symlinks
create_symlinks() {
    local suminami_dir="$HOME/.config/suminami"
    local configs=(hypr waybar dunst btop kitty alacritty)

    print_status "Creating config symlinks..."

    for config in "${configs[@]}"; do
        if [ -d "$suminami_dir/config/$config" ]; then
            rm -rf "$HOME/.config/$config" 2>/dev/null || true
            ln -sfn "$suminami_dir/config/$config" "$HOME/.config/$config"
            print_success "  $config -> suminami/config/$config"
        fi
    done

    # Create monitors.conf from example if it doesn't exist
    local monitors_conf="$suminami_dir/config/hypr/monitors.conf"
    local monitors_example="$suminami_dir/config/hypr/monitors.conf.example"
    if [ ! -f "$monitors_conf" ] && [ -f "$monitors_example" ]; then
        cp "$monitors_example" "$monitors_conf"
        print_success "  Created monitors.conf from example"
    fi
}

# Install GTK themes (minimal set)
install_gtk_themes() {
    local suminami_dir="$HOME/.config/suminami"
    local themes_source="$suminami_dir/themes/gtk"
    local themes_dest="$HOME/.local/share/themes"

    if [ ! -d "$themes_source" ]; then
        print_warning "GTK themes not found in repo, skipping"
        return 0
    fi

    print_status "Installing GTK themes..."
    mkdir -p "$themes_dest"

    for theme in "$themes_source"/*; do
        if [ -d "$theme" ]; then
            local theme_name=$(basename "$theme")
            cp -r "$theme" "$themes_dest/"
            print_success "  Installed $theme_name"
        fi
    done
}

# Install SDDM theme
install_sddm_theme() {
    local suminami_dir="$HOME/.config/suminami"
    local theme_source="$suminami_dir/sddm/suminami"
    local theme_dest="/usr/share/sddm/themes/suminami"

    # Check if SDDM is installed - skip silently if not
    if ! command -v sddm &> /dev/null; then
        return 0
    fi

    echo ""
    read -p "Install SumiNami SDDM login theme? [y/N] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installing SDDM theme (requires sudo)..."

        if [ -d "$theme_source" ]; then
            sudo rm -rf "$theme_dest" 2>/dev/null || true
            sudo cp -r "$theme_source" "$theme_dest"

            # Copy wallpapers to theme folder for SDDM access
            local wallpaper_source="$suminami_dir/wallpapers"
            if [ -d "$wallpaper_source" ]; then
                print_status "Copying wallpapers to SDDM theme..."
                sudo mkdir -p "$theme_dest/wallpapers"
                sudo cp "$wallpaper_source"/*.{jpg,jpeg,png,webp} "$theme_dest/wallpapers/" 2>/dev/null || true
                sudo chmod 644 "$theme_dest/wallpapers/"* 2>/dev/null || true
            fi

            # Configure SDDM to use theme
            sudo mkdir -p /etc/sddm.conf.d
            echo -e "[Theme]\nCurrent=suminami" | sudo tee /etc/sddm.conf.d/suminami.conf > /dev/null

            print_success "SDDM theme installed"
        else
            print_error "SDDM theme not found at $theme_source"
        fi
    else
        print_status "Skipping SDDM theme"
    fi
}

# Set initial wallpaper
set_initial_wallpaper() {
    local suminami_dir="$HOME/.config/suminami"
    local wallpaper="$suminami_dir/wallpapers/kanagawa.jpg"

    if [ -f "$wallpaper" ]; then
        echo "$wallpaper" > "$suminami_dir/current-wallpaper"
        print_success "Default wallpaper set to kanagawa"
    fi
}

# Install Limine theme (optional, if Limine detected)
install_limine_theme() {
    local suminami_dir="$HOME/.config/suminami"
    local limine_installer="$suminami_dir/limine/install-limine-theme.sh"

    # Check if Limine is installed
    local limine_conf=""
    for loc in "/boot/limine/limine.conf" "/boot/limine.conf" "/boot/EFI/limine/limine.conf" "/boot/efi/limine/limine.conf"; do
        if [ -f "$loc" ]; then
            limine_conf="$loc"
            break
        fi
    done

    if [ -z "$limine_conf" ]; then
        # Limine not detected, skip silently
        return 0
    fi

    print_status "Limine bootloader detected at $limine_conf"
    echo ""
    read -p "Would you like to install the SumiNami Limine theme? [y/N] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -x "$limine_installer" ]; then
            "$limine_installer"
        else
            print_error "Limine installer not found at $limine_installer"
        fi
    else
        print_status "Skipping Limine theme"
    fi
}

# Install GRUB theme (optional, if GRUB detected)
install_grub_theme() {
    local suminami_dir="$HOME/.config/suminami"
    local grub_installer="$suminami_dir/grub/install-grub-theme.sh"

    # Check if GRUB is installed - skip silently if not
    if [ ! -f /etc/default/grub ]; then
        return 0
    fi

    print_status "GRUB bootloader detected"
    echo ""
    read -p "Would you like to install the SumiNami GRUB theme? [y/N] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -x "$grub_installer" ]; then
            "$grub_installer"
        else
            print_error "GRUB installer not found at $grub_installer"
        fi
    else
        print_status "Skipping GRUB theme"
    fi
}

# Install fetch tool (fastfetch or neofetch config)
install_fetch_tool() {
    local suminami_dir="$HOME/.config/suminami"

    # Check if neofetch is installed
    if command -v neofetch &> /dev/null; then
        print_status "Neofetch detected, linking SumiNami neofetch config..."
        if [ -d "$suminami_dir/config/neofetch" ]; then
            rm -rf "$HOME/.config/neofetch" 2>/dev/null || true
            ln -sfn "$suminami_dir/config/neofetch" "$HOME/.config/neofetch"
            print_success "neofetch config linked"
        fi
        return 0
    fi

    # No neofetch, install fastfetch
    print_status "Installing fastfetch..."
    sudo pacman -S --needed --noconfirm fastfetch

    # Create symlink for fastfetch config
    if [ -d "$suminami_dir/config/fastfetch" ]; then
        rm -rf "$HOME/.config/fastfetch" 2>/dev/null || true
        ln -sfn "$suminami_dir/config/fastfetch" "$HOME/.config/fastfetch"
        print_success "fastfetch config linked"
    fi
}

# Install basic apps (image viewer, text editor) if not present
install_basic_apps() {
    # Common image viewers to check for
    local image_viewers=(imv loupe feh sxiv nsxiv swayimg eog gpicview ristretto gwenview viewnior)
    local has_image_viewer=false

    for viewer in "${image_viewers[@]}"; do
        if command -v "$viewer" &> /dev/null || pacman -Qq "$viewer" &> /dev/null 2>&1; then
            has_image_viewer=true
            break
        fi
    done

    if [ "$has_image_viewer" = false ]; then
        print_status "Installing image viewer (imv)..."
        sudo pacman -S --needed --noconfirm imv
        # Set imv as default for common image types
        xdg-mime default imv.desktop image/png image/jpeg image/jpg image/gif image/webp image/bmp image/tiff image/svg+xml 2>/dev/null
        print_success "imv installed and set as default"
    else
        print_status "Image viewer already installed, skipping"
    fi

    # Common text editors to check for
    local text_editors=(mousepad gedit gnome-text-editor xed pluma kate geany leafpad featherpad code)
    local has_text_editor=false

    for editor in "${text_editors[@]}"; do
        if command -v "$editor" &> /dev/null || pacman -Qq "$editor" &> /dev/null 2>&1; then
            has_text_editor=true
            break
        fi
    done

    if [ "$has_text_editor" = false ]; then
        print_status "Installing text editor (mousepad)..."
        sudo pacman -S --needed --noconfirm mousepad
        print_success "mousepad installed"
    else
        print_status "Text editor already installed, skipping"
    fi
}

# Install screen locker and idle manager if not present
# Note: Configs are included in suminami/config/hypr/, this just installs packages
install_screen_locker() {
    # Check if already installed
    local has_locker=false
    local has_idle=false

    if command -v hyprlock &> /dev/null || pacman -Qq hyprlock &> /dev/null 2>&1; then
        has_locker=true
    fi

    if command -v hypridle &> /dev/null || pacman -Qq hypridle &> /dev/null 2>&1; then
        has_idle=true
    fi

    # If both exist, skip
    if [ "$has_locker" = true ] && [ "$has_idle" = true ]; then
        print_status "Screen locker and idle manager already installed"
        return 0
    fi

    # Prompt for installation
    echo ""
    echo -e "${BLUE}Screen Lock & Idle Management${NC}"
    echo "  hyprlock: Native Hyprland lock screen"
    echo "  hypridle: Auto-lock and DPMS timeout"
    echo "  (Configs included in suminami)"
    echo ""
    read -p "Install screen lock & idle management? [Y/n] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_status "Skipping screen locker/idle manager"
        return 0
    fi

    if [ "$has_locker" = false ]; then
        print_status "Installing hyprlock..."
        sudo pacman -S --needed --noconfirm hyprlock
        print_success "hyprlock installed"
    fi

    if [ "$has_idle" = false ]; then
        print_status "Installing hypridle..."
        sudo pacman -S --needed --noconfirm hypridle
        print_success "hypridle installed"
    fi

    # Add hypridle to autostart if not already present
    local env_conf="$HOME/.config/hypr/env.conf"
    if [ -f "$env_conf" ] && ! grep -q "^exec-once = hypridle" "$env_conf"; then
        printf "\nexec-once = hypridle\n" >> "$env_conf"
        print_success "hypridle added to Hyprland autostart"
    fi
}

# Install clipboard persistence (optional)
install_clipboard_persistence() {
    local aur_helper
    aur_helper=$(get_aur_helper)

    # Check for existing clipboard managers
    local clipboard_tools=(wl-clip-persist cliphist clipman copyq gpaste klipper parcellite)
    local has_clipboard=false
    local existing_tool=""

    for tool in "${clipboard_tools[@]}"; do
        if command -v "$tool" &> /dev/null || pacman -Qq "$tool" &> /dev/null 2>&1; then
            has_clipboard=true
            existing_tool="$tool"
            break
        fi
    done

    if [ "$has_clipboard" = true ]; then
        print_status "Clipboard manager ($existing_tool) already installed"
        return 0
    fi

    echo ""
    echo -e "${BLUE}Clipboard Persistence${NC}"
    echo "  Keeps clipboard contents when source app closes"
    echo "  (No UI, runs silently in background)"
    echo ""
    read -p "Install clipboard persistence? [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Skipping clipboard persistence"
        return 0
    fi

    print_status "Installing wl-clip-persist from AUR..."
    "$aur_helper" -S --needed --noconfirm wl-clip-persist
    print_success "wl-clip-persist installed"

    # Add to Hyprland autostart if not already there
    local env_conf="$HOME/.config/hypr/env.conf"
    if [ -f "$env_conf" ]; then
        if ! grep -q "wl-clip-persist" "$env_conf"; then
            print_status "Adding wl-clip-persist to autostart..."
            echo "exec-once = wl-clip-persist --clipboard both" >> "$env_conf"
            print_success "Clipboard persistence configured"
        fi
    fi
}

# Install optional TUI enhancements
install_tui_enhancements() {
    local suminami_dir="$HOME/.config/suminami"

    echo ""
    echo -e "${BLUE}Optional TUI Enhancements${NC}"
    echo "  - cava: Audio visualizer"
    echo "  - terminal-flow: ASCII art animations"
    echo "  - terminal-cosmos: Animated terminal scenes"
    echo ""
    read -p "Install TUI enhancements? [y/N] " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Skipping TUI enhancements"
        return 0
    fi

    # Install cava from official repos
    print_status "Installing cava..."
    sudo pacman -S --needed --noconfirm cava

    # Create cava symlink
    if [ -d "$suminami_dir/config/cava" ]; then
        rm -rf "$HOME/.config/cava" 2>/dev/null || true
        ln -sfn "$suminami_dir/config/cava" "$HOME/.config/cava"
        print_success "cava config linked"
    fi

    # Ensure pipx path is set
    export PATH="$HOME/.local/bin:$PATH"
    pipx ensurepath 2>/dev/null || true

    # Install terminal-flow
    print_status "Installing terminal-flow..."
    pipx install git+https://github.com/kestalkayden/terminal-flow.git 2>/dev/null || \
        pipx upgrade terminal-flow 2>/dev/null || \
        print_warning "terminal-flow installation failed"

    # Install terminal-cosmos
    print_status "Installing terminal-cosmos..."
    pipx install git+https://github.com/kestalkayden/terminal-cosmos.git 2>/dev/null || \
        pipx upgrade terminal-cosmos 2>/dev/null || \
        print_warning "terminal-cosmos installation failed"

    print_success "TUI enhancements installed"
    echo ""
    echo "  Usage:"
    echo "    cava              - Audio visualizer"
    echo "    terminal-flow     - ASCII animations"
    echo "    terminal-cosmos   - Terminal scenes"
    echo ""
}

# Configure TTY autostart as a fallback session launcher
_setup_tty_autostart() {
    local shell_name
    shell_name=$(basename "$SHELL")
    local rc_file=""

    case "$shell_name" in
        bash) rc_file="$HOME/.bashrc" ;;
        zsh)  rc_file="$HOME/.zshrc" ;;
        fish) rc_file="$HOME/.config/fish/config.fish" ;;
        *)
            print_warning "Shell '$shell_name' not supported for TTY autostart"
            print_status "Manually add Hyprland autostart to your shell rc"
            return 1
            ;;
    esac

    if grep -q "exec Hyprland" "$rc_file" 2>/dev/null; then
        print_status "Hyprland TTY autostart already configured"
        return 0
    fi

    print_status "Adding Hyprland TTY autostart to $rc_file..."

    local autostart_block
    if [ "$shell_name" = "fish" ]; then
        autostart_block='\n# SumiNami: start Hyprland on TTY1 login\nif test -z "$WAYLAND_DISPLAY" -a "$XDG_VTNR" = "1"\n    exec Hyprland\nend'
    else
        autostart_block='\n# SumiNami: start Hyprland on TTY1 login\nif [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then\n    exec Hyprland\nfi'
    fi

    printf "$autostart_block\n" >> "$rc_file"
    print_success "TTY autostart configured in $rc_file"
    print_warning "Log in on TTY1 after reboot and Hyprland will start automatically"
}

# Verify sddm-greeter works and fix if broken.
# A stale binary (e.g. Qt5 era) with missing shared libs crashes
# silently at boot causing a black screen with no recovery.
# Returns 0 if greeter is OK or fixed, 1 if it cannot be repaired.
_verify_sddm_greeter() {
    if [ ! -f /usr/bin/sddm-greeter ]; then
        print_warning "sddm-greeter not found"
        return 1
    fi

    if ! ldd /usr/bin/sddm-greeter 2>/dev/null | grep -q "not found"; then
        print_success "sddm-greeter OK"
        return 0
    fi

    print_warning "sddm-greeter has missing libraries (stale binary detected)"

    # Try Qt6 greeter if available
    if [ -f /usr/bin/sddm-greeter-qt6 ] && ! ldd /usr/bin/sddm-greeter-qt6 2>/dev/null | grep -q "not found"; then
        print_status "Replacing broken greeter with Qt6 version..."
        sudo mv /usr/bin/sddm-greeter /usr/bin/sddm-greeter.bak
        sudo ln -s /usr/bin/sddm-greeter-qt6 /usr/bin/sddm-greeter
        print_success "sddm-greeter replaced with Qt6 version"
        return 0
    fi

    # Try reinstalling sddm to get a clean binary
    print_status "No working greeter fallback found, reinstalling sddm..."
    sudo pacman -S --noconfirm sddm
    if ! ldd /usr/bin/sddm-greeter 2>/dev/null | grep -q "not found"; then
        print_success "sddm-greeter fixed via reinstall"
        return 0
    fi

    return 1
}

# Ensure a display manager or TTY autostart is configured
# Without this, a blank/black screen is seen after reboot
setup_display_manager() {
    # Check if any display manager is already enabled
    local enabled_dm=""
    for dm in sddm gdm lightdm lxdm greetd; do
        if systemctl is-enabled "$dm" &>/dev/null; then
            enabled_dm="$dm"
            break
        fi
    done

    if [ -n "$enabled_dm" ]; then
        print_success "Display manager already enabled ($enabled_dm)"
        return 0
    fi

    echo ""
    echo -e "${BLUE}Display Manager / Session Start${NC}"
    echo "  No display manager is currently enabled."
    echo "  Without one, you will see a blank screen after reboot."
    echo ""
    echo "  Options:"
    echo "    1) Enable SDDM (recommended - login screen)"
    echo "    2) TTY autostart (launch Hyprland from terminal login)"
    echo "    3) Skip (configure manually later)"
    echo ""
    read -p "Choose [1/2/3]: " -n 1 -r
    echo ""

    case "$REPLY" in
        1)
            # Pre-flight: check for known issues before installing anything
            local sddm_preflight_ok=true

            # Check if Qt6 deps are available in repos (required by current sddm)
            if ! pacman -Si qt6-declarative &>/dev/null; then
                print_warning "qt6-declarative not found in repos — SDDM may not work on this system."
                sddm_preflight_ok=false
            fi

            # Check for an existing stale/broken greeter from a previous install
            if [ -f /usr/bin/sddm-greeter ] && ldd /usr/bin/sddm-greeter 2>/dev/null | grep -q "not found"; then
                print_warning "Existing sddm-greeter has missing libraries (stale install detected)."
                if [ -f /usr/bin/sddm-greeter-qt6 ] && ! ldd /usr/bin/sddm-greeter-qt6 2>/dev/null | grep -q "not found"; then
                    print_status "Qt6 greeter is available and can replace the broken one."
                else
                    print_warning "No working greeter fallback found — a reinstall of sddm will be needed."
                fi
            fi

            if [ "$sddm_preflight_ok" = false ]; then
                echo ""
                print_error "SDDM pre-flight checks failed. Installing it may leave your system with a black screen."
                read -p "Proceed anyway? (not recommended) [y/N] " -n 1 -r
                echo ""
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    print_warning "Skipping SDDM. Falling back to TTY autostart instead..."
                    _setup_tty_autostart
                    return 0
                fi
            fi

            print_status "Installing and enabling SDDM..."
            sudo pacman -S --needed --noconfirm sddm
            sudo systemctl enable sddm

            if _verify_sddm_greeter; then
                # Write complete autologin config with both User and Session.
                # Without User=, SDDM falls back to the greeter — if it is
                # broken this results in a black screen on reboot.
                sudo mkdir -p /etc/sddm.conf.d
                printf "[Autologin]\nUser=%s\nSession=hyprland\n" "$(whoami)" \
                    | sudo tee /etc/sddm.conf.d/suminami-autologin.conf > /dev/null
                print_success "SDDM autologin configured for $(whoami)"
                print_success "SDDM enabled - will start on next boot"
            else
                print_error "Could not repair sddm-greeter. Disabling SDDM to prevent black screen."
                sudo systemctl disable sddm
                echo ""
                print_warning "To fix SDDM manually later:"
                echo "    sudo pacman -S sddm qt6-declarative"
                echo "    sudo systemctl enable sddm"
                echo ""
                print_warning "Falling back to TTY autostart instead..."
                _setup_tty_autostart
            fi
            ;;
        2)
            _setup_tty_autostart
            ;;
        *)
            print_warning "Skipping display manager setup"
            print_warning "You may see a blank screen after reboot - enable a DM manually"
            ;;
    esac
}

# Setup shell integration (zoxide smart cd)
setup_shell_integration() {
    local suminami_dir="$HOME/.config/suminami"
    local shell_name
    local rc_file
    local shell_config

    # Detect user's shell
    shell_name=$(basename "$SHELL")

    local source_line
    case "$shell_name" in
        bash)
            rc_file="$HOME/.bashrc"
            shell_config="$suminami_dir/config/shell/zoxide.bash"
            source_line="[ -f \"$shell_config\" ] && source \"$shell_config\""
            ;;
        zsh)
            rc_file="$HOME/.zshrc"
            shell_config="$suminami_dir/config/shell/zoxide.zsh"
            source_line="[[ -f \"$shell_config\" ]] && source \"$shell_config\""
            ;;
        fish)
            rc_file="$HOME/.config/fish/config.fish"
            shell_config="$suminami_dir/config/shell/zoxide.fish"
            source_line="test -f \"$shell_config\"; and source \"$shell_config\""
            mkdir -p "$HOME/.config/fish"
            ;;
        *)
            print_warning "Shell '$shell_name' not supported for auto-setup"
            print_status "Manually source the zoxide config for your shell"
            return 0
            ;;
    esac

    # Check if already configured
    if grep -qF "$shell_config" "$rc_file" 2>/dev/null; then
        print_status "Shell integration already configured"
        return 0
    fi

    # Add source line to rc file
    print_status "Adding shell integration to $rc_file..."
    echo "" >> "$rc_file"
    echo "# SumiNami shell integration" >> "$rc_file"
    echo "$source_line" >> "$rc_file"

    print_success "Shell integration configured (smart cd with zoxide)"
}

# Main
main() {
    # Re-attach stdin to the terminal so read prompts work when script is piped
    # e.g. curl ... | bash
    [ -t 0 ] || exec < /dev/tty

    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}       ${GREEN}Suminami Rice Installer${NC}        ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo ""

    # Pre-flight checks
    check_not_root
    check_arch
    check_internet
    check_base_tools

    # Confirm before proceeding
    confirm_install

    install_packages

    # Clone/update suminami BEFORE backup - if clone fails, user keeps their configs
    setup_suminami

    # Now safe to backup existing configs (suminami is ready)
    backup_configs

    # Configure GPU (NVIDIA detection)
    configure_gpu

    create_symlinks
    install_gtk_themes

    # Generate initial theme
    print_status "Generating default theme..."
    if ! "$HOME/.config/suminami/scripts/generate-theme.sh"; then
        print_warning "Theme generation failed - run ~/.config/suminami/scripts/generate-theme.sh manually after logging in"
    fi

    # Set initial wallpaper
    set_initial_wallpaper

    # Create Screenshots directory (hyprshot saves here by default)
    mkdir -p "$HOME/Pictures"

    # Install fetch tool (neofetch config or fastfetch)
    install_fetch_tool

    # Install basic apps (image viewer, text editor) if missing
    install_basic_apps

    # Install screen locker and idle manager
    install_screen_locker

    # Optional: Clipboard persistence
    install_clipboard_persistence

    # Optional: Install SDDM theme
    install_sddm_theme

    # Optional: Install Limine theme (if detected)
    install_limine_theme

    # Optional: Install GRUB theme (if detected)
    install_grub_theme

    # Optional: Install TUI enhancements
    install_tui_enhancements

    # Ensure a DM or TTY autostart is in place (prevents blank screen on reboot)
    setup_display_manager

    # Setup shell integration (zoxide)
    setup_shell_integration

    echo ""
    print_success "Suminami installation complete!"
    echo ""
    print_status "Next steps:"
    echo "  1. Log out and back in (or reboot)"
    echo "  2. Press Super+A to open the Hub Menu"
    echo "  3. Use Style > Themes to switch themes"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

main
exit 0
