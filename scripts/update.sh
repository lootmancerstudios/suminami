#!/bin/bash
# Suminami Update Script
# Pulls latest changes and reloads all components

SUMINAMI_DIR="$HOME/.config/suminami"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Suminami Update${NC}"
echo ""

# Pull latest changes (stash local modifications that conflict)
echo -e "${BLUE}[*]${NC} Pulling latest changes..."
cd "$SUMINAMI_DIR"
if ! git pull 2>/dev/null; then
    echo -e "${YELLOW}[!]${NC} Local changes detected, stashing before pull..."
    git stash
    if ! git pull; then
        echo -e "${RED}[!]${NC} Pull failed"
        git stash pop 2>/dev/null
        echo -e "Press Enter to close..."
        read
        exit 1
    fi
    git stash pop 2>/dev/null || echo -e "${YELLOW}[!]${NC} Some local changes conflicted with the update and were dropped"
fi

echo ""

# Regenerate theme
echo -e "${BLUE}[*]${NC} Regenerating theme..."
"$SUMINAMI_DIR/scripts/generate-theme.sh" > /dev/null

# Reload wallpaper
echo -e "${BLUE}[*]${NC} Reloading wallpaper..."
if command -v swww &>/dev/null; then
    pgrep -x swww-daemon &>/dev/null || setsid swww-daemon &>/dev/null &
    sleep 0.5
    local_wp=$(cat "$SUMINAMI_DIR/current-wallpaper" 2>/dev/null)
    [ -f "$local_wp" ] && swww img "$local_wp" --transition-type fade --transition-fps 60 --transition-duration 1
fi
killall hyprpaper 2>/dev/null || true

# Reload Hyprland
echo -e "${BLUE}[*]${NC} Reloading Hyprland..."
hyprctl reload > /dev/null 2>&1

# Reload Waybar
echo -e "${BLUE}[*]${NC} Reloading Waybar..."
pkill waybar 2>/dev/null || true
sleep 0.5
setsid waybar &>/dev/null &

# Reload Dunst
echo -e "${BLUE}[*]${NC} Reloading Dunst..."
systemctl --user restart dunst 2>/dev/null || true

echo ""
echo -e "${GREEN}[+] Update complete!${NC}"
echo ""
echo -e "Press Enter to close..."
read
