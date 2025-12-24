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
    hyprpaper
    waybar
    kitty
    wofi
    dunst
    grim
    slurp
    wl-clipboard
    brightnessctl
    playerctl
    pamixer
    libnotify
    ttf-jetbrains-mono-nerd
    jq
    socat
    qt6-declarative
    qt6-svg
    imagemagick
    btop
    python-pipx
    papirus-icon-theme
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

# Remove KDE bloat if Dolphin is installed
cleanup_kde_bloat() {
    if pacman -Qq dolphin &> /dev/null; then
        print_status "Removing Dolphin and KDE dependencies (replacing with Thunar)..."
        sudo pacman -Rns --noconfirm dolphin 2>/dev/null || true
    fi

    # Remove other KDE theming bloat if present
    local kde_bloat=(kvantum qt5ct qt6ct breeze kdecoration frameworkintegration)
    local to_remove=()

    for pkg in "${kde_bloat[@]}"; do
        if pacman -Qq "$pkg" &> /dev/null; then
            to_remove+=("$pkg")
        fi
    done

    if [ ${#to_remove[@]} -gt 0 ]; then
        print_status "Removing unnecessary Qt/KDE theming packages..."
        sudo pacman -Rns --noconfirm "${to_remove[@]}" 2>/dev/null || true
    fi
}

# Install packages
install_packages() {
    local aur_helper
    aur_helper=$(get_aur_helper)

    # Clean up KDE bloat first
    cleanup_kde_bloat

    print_status "Updating system..."
    sudo pacman -Syu --noconfirm

    # Re-check AUR helper after system update (libalpm might have changed)
    if ! "$aur_helper" --version &> /dev/null; then
        print_warning "AUR helper broke after system update, rebuilding..."
        rebuild_aur_helper "$aur_helper"
    fi

    print_status "Installing core dependencies..."
    sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}"

    # Only install AUR packages if there are any
    if [ ${#AUR_DEPS[@]} -gt 0 ]; then
        print_status "Installing AUR packages (this may take a few minutes)..."
        "$aur_helper" -S --needed --noconfirm "${AUR_DEPS[@]}"
    fi

    print_success "All dependencies installed"
}

# Backup existing configs
backup_configs() {
    local backup_dir="$HOME/.config/suminami-backup-$(date +%Y%m%d-%H%M%S)"
    local configs_to_backup=(hypr waybar wofi dunst swaylock kitty)
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
    local configs=(waybar wofi dunst btop)

    print_status "Creating config symlinks..."

    for config in "${configs[@]}"; do
        if [ -d "$suminami_dir/config/$config" ]; then
            rm -rf "$HOME/.config/$config" 2>/dev/null || true
            ln -sfn "$suminami_dir/config/$config" "$HOME/.config/$config"
            print_success "  $config -> suminami/config/$config"
        fi
    done
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

    # Check if SDDM is installed
    if ! command -v sddm &> /dev/null; then
        print_warning "SDDM not detected, skipping login theme"
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
install_screen_locker() {
    # Check for existing screen lockers
    local screen_lockers=(hyprlock swaylock swaylock-effects gtklock waylock i3lock)
    local has_locker=false
    local existing_locker=""

    for locker in "${screen_lockers[@]}"; do
        if command -v "$locker" &> /dev/null || pacman -Qq "$locker" &> /dev/null 2>&1; then
            has_locker=true
            existing_locker="$locker"
            break
        fi
    done

    # Check for existing idle managers
    local idle_managers=(hypridle swayidle)
    local has_idle=false
    local existing_idle=""

    for idle in "${idle_managers[@]}"; do
        if command -v "$idle" &> /dev/null || pacman -Qq "$idle" &> /dev/null 2>&1; then
            has_idle=true
            existing_idle="$idle"
            break
        fi
    done

    # If both exist, skip
    if [ "$has_locker" = true ] && [ "$has_idle" = true ]; then
        print_status "Screen locker ($existing_locker) and idle manager ($existing_idle) already installed"
        return 0
    fi

    # Prompt for installation
    echo ""
    echo -e "${BLUE}Screen Lock & Idle Management${NC}"
    if [ "$has_locker" = true ]; then
        echo "  Screen locker: $existing_locker (installed)"
    else
        echo "  Screen locker: hyprlock (native Hyprland locker)"
    fi
    if [ "$has_idle" = true ]; then
        echo "  Idle manager: $existing_idle (installed)"
    else
        echo "  Idle manager: hypridle (auto-lock, DPMS timeout)"
    fi
    echo ""
    read -p "Install screen lock & idle management? [Y/n] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_status "Skipping screen locker/idle manager"
        return 0
    fi

    # Install hyprlock if no locker
    if [ "$has_locker" = false ]; then
        print_status "Installing hyprlock..."
        sudo pacman -S --needed --noconfirm hyprlock
        print_success "hyprlock installed"

        # Create hyprlock config if it doesn't exist
        local hyprlock_config="$HOME/.config/hypr/hyprlock.conf"
        if [ ! -f "$hyprlock_config" ]; then
            print_status "Creating hyprlock config..."
            cat > "$hyprlock_config" << 'EOF'
# SumiNami hyprlock config
# Kanagawa palette

general {
    hide_cursor = true
    grace = 0
    no_fade_in = false
    no_fade_out = false
}

background {
    monitor =
    path = screenshot
    blur_passes = 3
    blur_size = 8
    noise = 0.02
    contrast = 0.9
    brightness = 0.6
    vibrancy = 0.2
}

# Clock - top right
label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%H:%M")"
    color = rgba(220, 215, 186, 1.0)
    font_size = 48
    font_family = JetBrainsMono Nerd Font Bold
    position = -32, -32
    halign = right
    valign = top
}

# Date
label {
    monitor =
    text = cmd[update:60000] echo "$(date +"%A, %B %d")"
    color = rgba(114, 113, 105, 1.0)
    font_size = 14
    font_family = JetBrainsMono Nerd Font
    position = -32, -100
    halign = right
    valign = top
}

# Password input
input-field {
    monitor =
    size = 280, 48
    outline_thickness = 1
    dots_size = 0.25
    dots_spacing = 0.3
    dots_center = true
    outer_color = rgba(54, 54, 70, 1.0)
    inner_color = rgba(31, 31, 40, 1.0)
    font_color = rgba(220, 215, 186, 1.0)
    fade_on_empty = false
    placeholder_text = <span foreground="##727169">Password</span>
    hide_input = false
    rounding = 0
    check_color = rgba(210, 126, 153, 1.0)
    fail_color = rgba(228, 104, 118, 1.0)
    fail_text = <span foreground="##E46876">$FAIL</span>
    position = 0, 0
    halign = center
    valign = center
}

# Lock icon
label {
    monitor =
    text = 󰌾
    color = rgba(210, 126, 153, 1.0)
    font_size = 32
    font_family = JetBrainsMono Nerd Font
    position = 0, 60
    halign = center
    valign = center
}
EOF
            print_success "hyprlock config created"
        fi
    fi

    # Install hypridle if no idle manager
    if [ "$has_idle" = false ]; then
        print_status "Installing hypridle..."
        sudo pacman -S --needed --noconfirm hypridle
        print_success "hypridle installed"

        # Create hypridle config if it doesn't exist
        local hypridle_config="$HOME/.config/hypr/hypridle.conf"
        if [ ! -f "$hypridle_config" ]; then
            print_status "Creating hypridle config..."
            cat > "$hypridle_config" << 'EOF'
# SumiNami hypridle config

general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

# Dim screen after 10 minutes
listener {
    timeout = 600
    on-timeout = brightnessctl -s set 10%
    on-resume = brightnessctl -r
}

# Lock screen after 20 minutes
listener {
    timeout = 1200
    on-timeout = loginctl lock-session
}

# Turn off display after 40 minutes
listener {
    timeout = 2400
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

# Suspend after 60 minutes
listener {
    timeout = 3600
    on-timeout = systemctl suspend
}
EOF
            print_success "hypridle config created"
        fi

        # Add hypridle to Hyprland autostart if not already there
        local env_conf="$HOME/.config/hypr/env.conf"
        if [ -f "$env_conf" ]; then
            if ! grep -q "exec-once = hypridle" "$env_conf"; then
                print_status "Adding hypridle to Hyprland autostart..."
                echo "exec-once = hypridle" >> "$env_conf"
                print_success "hypridle added to autostart"
            fi
        fi
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
            source_line="source \"$shell_config\""
            ;;
        zsh)
            rc_file="$HOME/.zshrc"
            shell_config="$suminami_dir/config/shell/zoxide.zsh"
            source_line="source \"$shell_config\""
            ;;
        fish)
            rc_file="$HOME/.config/fish/config.fish"
            shell_config="$suminami_dir/config/shell/zoxide.fish"
            source_line="source \"$shell_config\""
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
    install_gtk_themes

    # Generate initial theme
    print_status "Generating default theme..."
    "$HOME/.config/suminami/scripts/generate-theme.sh"

    # Set initial wallpaper
    set_initial_wallpaper

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

    # Optional: Install TUI enhancements
    install_tui_enhancements

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

main "$@"
