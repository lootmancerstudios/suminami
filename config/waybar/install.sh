#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════╗
# ║                     SumiNami Bar Installer                        ║
# ╚═══════════════════════════════════════════════════════════════════╝

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/lootmancerstudios/suminami-bar.git"
INSTALL_DIR="$HOME/.config/waybar"
BACKUP_DIR="$HOME/.config/waybar-backups"

# ─────────────────────────────────────────────────────────────────────
# Helper functions
# ─────────────────────────────────────────────────────────────────────

print_header() {
    echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

confirm() {
    local prompt="$1"
    local default="${2:-y}"

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi

    read -rp "$prompt" response
    response="${response:-$default}"
    [[ "$response" =~ ^[Yy]$ ]]
}

# ─────────────────────────────────────────────────────────────────────
# Dependency checking
# ─────────────────────────────────────────────────────────────────────

check_command() {
    command -v "$1" &>/dev/null
}

check_package() {
    pacman -Qi "$1" &>/dev/null 2>&1
}

check_dependencies() {
    print_header "Checking Dependencies"

    local missing_required=()
    local missing_optional=()

    # Required
    check_command waybar || missing_required+=("waybar")
    check_command wofi || missing_required+=("wofi")

    # Check for nerd font (check common locations)
    if ! fc-list | grep -qi "jetbrainsmono.*nerd"; then
        missing_required+=("ttf-jetbrains-mono-nerd")
    fi

    # Optional but recommended
    check_command nmcli || missing_optional+=("networkmanager")
    check_command bluetoothctl || missing_optional+=("bluez bluez-utils")
    check_command brightnessctl || missing_optional+=("brightnessctl")
    check_command playerctl || missing_optional+=("playerctl")
    check_command sensors || missing_optional+=("lm_sensors")

    # Report status
    if [[ ${#missing_required[@]} -eq 0 ]]; then
        print_success "All required dependencies installed"
    else
        print_warning "Missing required: ${missing_required[*]}"
    fi

    if [[ ${#missing_optional[@]} -eq 0 ]]; then
        print_success "All optional dependencies installed"
    else
        print_warning "Missing optional: ${missing_optional[*]}"
    fi

    # Offer to install missing packages
    local all_missing=("${missing_required[@]}" "${missing_optional[@]}")

    if [[ ${#all_missing[@]} -gt 0 ]]; then
        echo ""
        if confirm "Install missing packages?"; then
            print_step "Installing packages..."
            sudo pacman -S --needed "${all_missing[@]}"
            print_success "Packages installed"
        elif [[ ${#missing_required[@]} -gt 0 ]]; then
            print_error "Required dependencies missing. Install them manually:"
            echo "  sudo pacman -S ${missing_required[*]}"
            exit 1
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────────
# Backup functions
# ─────────────────────────────────────────────────────────────────────

backup_existing() {
    if [[ -d "$INSTALL_DIR" ]]; then
        print_header "Backing Up Existing Config"

        mkdir -p "$BACKUP_DIR"
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_path="$BACKUP_DIR/waybar_$timestamp"

        print_step "Creating backup at: $backup_path"
        cp -r "$INSTALL_DIR" "$backup_path"
        print_success "Backup created"

        # Save backup path for potential restore
        echo "$backup_path" > "$BACKUP_DIR/.latest"

        print_step "Removing old config..."
        rm -rf "$INSTALL_DIR"
        print_success "Old config removed"
    fi
}

list_backups() {
    print_header "Available Backups"

    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_warning "No backups found"
        return 1
    fi

    local backups=($(ls -1d "$BACKUP_DIR"/waybar_* 2>/dev/null | sort -r))

    if [[ ${#backups[@]} -eq 0 ]]; then
        print_warning "No backups found"
        return 1
    fi

    echo ""
    local i=1
    for backup in "${backups[@]}"; do
        local name=$(basename "$backup")
        local date_part="${name#waybar_}"
        local formatted_date=$(echo "$date_part" | sed 's/_/ at /' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/')
        echo "  $i) $formatted_date"
        ((i++))
    done
    echo ""

    return 0
}

restore_backup() {
    print_header "Restore Previous Config"

    if ! list_backups; then
        return 1
    fi

    local backups=($(ls -1d "$BACKUP_DIR"/waybar_* 2>/dev/null | sort -r))

    read -rp "Select backup to restore (1-${#backups[@]}, or 'c' to cancel): " choice

    if [[ "$choice" == "c" || "$choice" == "C" ]]; then
        print_warning "Restore cancelled"
        return 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt ${#backups[@]} ]]; then
        print_error "Invalid selection"
        return 1
    fi

    local selected_backup="${backups[$((choice-1))]}"

    print_step "Restoring from: $(basename "$selected_backup")"

    # Backup current SumiNami install before restoring
    if [[ -d "$INSTALL_DIR" ]]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        mv "$INSTALL_DIR" "$BACKUP_DIR/suminami_$timestamp"
        print_step "Current config backed up as suminami_$timestamp"
    fi

    cp -r "$selected_backup" "$INSTALL_DIR"
    print_success "Config restored!"

    if confirm "Restart waybar now?"; then
        pkill waybar 2>/dev/null || true
        sleep 0.5
        waybar &
        disown
        print_success "Waybar restarted"
    fi
}

# ─────────────────────────────────────────────────────────────────────
# Installation
# ─────────────────────────────────────────────────────────────────────

install_suminami() {
    print_header "Installing SumiNami Bar"

    print_step "Cloning repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
    print_success "Repository cloned"

    print_step "Setting script permissions..."
    chmod +x "$INSTALL_DIR/scripts/"*
    print_success "Permissions set"

    print_step "Generating styles for your display..."
    cd "$INSTALL_DIR"
    ./scripts/generate-style
    print_success "Styles generated"
}

start_waybar() {
    print_header "Starting Waybar"

    # Kill existing waybar
    if pgrep -x waybar &>/dev/null; then
        print_step "Stopping existing waybar..."
        pkill waybar
        sleep 0.5
    fi

    print_step "Starting waybar..."
    waybar &
    disown
    print_success "Waybar started!"
}

# ─────────────────────────────────────────────────────────────────────
# Uninstall
# ─────────────────────────────────────────────────────────────────────

uninstall_suminami() {
    print_header "Uninstall SumiNami Bar"

    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_warning "SumiNami Bar is not installed"
        return 0
    fi

    if ! confirm "Remove SumiNami Bar?"; then
        print_warning "Uninstall cancelled"
        return 0
    fi

    print_step "Removing SumiNami Bar..."
    rm -rf "$INSTALL_DIR"
    print_success "SumiNami Bar removed"

    # Offer to restore backup
    if [[ -d "$BACKUP_DIR" ]] && ls -1d "$BACKUP_DIR"/waybar_* &>/dev/null; then
        echo ""
        if confirm "Restore a previous waybar config?"; then
            restore_backup
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────────
# Main menu
# ─────────────────────────────────────────────────────────────────────

show_menu() {
    echo -e "\n${CYAN}SumiNami Bar${NC} - What would you like to do?\n"
    echo "  1) Install SumiNami Bar"
    echo "  2) Restore previous config"
    echo "  3) Uninstall SumiNami Bar"
    echo "  4) Exit"
    echo ""
    read -rp "Select option (1-4): " choice

    case "$choice" in
        1)
            check_dependencies
            backup_existing
            install_suminami
            if confirm "Start waybar now?" "y"; then
                start_waybar
            fi
            print_header "Installation Complete!"
            echo -e "  Config file: ${CYAN}~/.config/waybar/suminami.conf${NC}"
            echo -e "  Change theme: Edit ${CYAN}color_scheme=${NC} and restart waybar"
            echo -e "  Restart cmd:  ${CYAN}pkill waybar && waybar${NC}"
            echo ""
            ;;
        2)
            restore_backup
            ;;
        3)
            uninstall_suminami
            ;;
        4)
            echo "Bye!"
            exit 0
            ;;
        *)
            print_error "Invalid option"
            show_menu
            ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────────────

main() {
    echo -e "${CYAN}"
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║         SumiNami Bar Installer        ║"
    echo "  ║   A themeable Waybar for Hyprland     ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo -e "${NC}"

    # Handle command line arguments
    case "${1:-}" in
        --install|-i)
            check_dependencies
            backup_existing
            install_suminami
            start_waybar
            ;;
        --restore|-r)
            restore_backup
            ;;
        --uninstall|-u)
            uninstall_suminami
            ;;
        --help|-h)
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  --install, -i     Install SumiNami Bar"
            echo "  --restore, -r     Restore previous waybar config"
            echo "  --uninstall, -u   Uninstall SumiNami Bar"
            echo "  --help, -h        Show this help"
            echo ""
            echo "Run without options for interactive menu."
            ;;
        "")
            show_menu
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

main "$@"
