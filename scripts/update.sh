#!/bin/bash
# Suminami Update Script
# Pulls latest changes and reloads all components

set -e

SUMINAMI_DIR="$HOME/.config/suminami"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Suminami Update${NC}"
echo ""

# Pull latest changes
echo -e "${BLUE}[*]${NC} Pulling latest changes..."
cd "$SUMINAMI_DIR"
git pull

echo ""

# Regenerate theme
echo -e "${BLUE}[*]${NC} Regenerating theme..."
"$SUMINAMI_DIR/scripts/generate-theme.sh" > /dev/null

# Reload Hyprland
echo -e "${BLUE}[*]${NC} Reloading Hyprland..."
hyprctl reload > /dev/null

# Reload Waybar
echo -e "${BLUE}[*]${NC} Reloading Waybar..."
pkill waybar 2>/dev/null || true
sleep 0.3
waybar &>/dev/null &

# Reload Dunst
echo -e "${BLUE}[*]${NC} Reloading Dunst..."
systemctl --user restart dunst 2>/dev/null || pkill dunst && dunst &

echo ""
echo -e "${GREEN}[+] Update complete!${NC}"
echo ""
echo -e "Press Enter to close..."
read
