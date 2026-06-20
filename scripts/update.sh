#!/bin/bash
# Suminami Update Script
# Pulls latest changes and reloads all components

set -uo pipefail

SUMINAMI_DIR="$HOME/.config/suminami"

# Network git wrapper: abort a dead/stalled transfer instead of hanging forever
# (does not kill a slow-but-progressing download).
git_net() {
    timeout 300 git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=20 "$@"
}

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Suminami Update${NC}"
echo ""

# Fetch + realign to upstream. The repo is meant to track origin, so on any
# non-fast-forward (e.g. upstream history was realigned) we reset to origin
# rather than failing with "divergent branches". Untracked / gitignored files
# such as monitors.conf are never touched.
echo -e "${BLUE}[*]${NC} Fetching latest changes..."
cd "$SUMINAMI_DIR" || { echo -e "${RED}[!]${NC} Cannot access $SUMINAMI_DIR"; exit 1; }

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)

if ! git_net fetch origin; then
    echo -e "${RED}[!]${NC} Could not fetch from origin (offline?). Skipping update."
    echo -e "Press Enter to close..."
    read
    exit 1
fi

# Preserve any local tracked edits so realigning can't silently discard them.
autostashed=false
if ! git diff --quiet HEAD 2>/dev/null; then
    echo -e "${YELLOW}[!]${NC} Local changes detected, stashing before update..."
    git stash push -m "suminami-update-autostash" >/dev/null 2>&1 && autostashed=true
fi

if git merge --ff-only "origin/$branch" >/dev/null 2>&1; then
    echo -e "${GREEN}[+]${NC} Updated to latest."
else
    echo -e "${YELLOW}[!]${NC} Upstream history changed — realigning to origin/$branch..."
    git reset --hard "origin/$branch"
fi

if [ "$autostashed" = true ]; then
    git stash pop >/dev/null 2>&1 \
        || echo -e "${YELLOW}[!]${NC} Some local changes conflicted with the update; they are kept in 'git stash'."
fi

echo ""

# Regenerate theme
echo -e "${BLUE}[*]${NC} Regenerating theme..."
"$SUMINAMI_DIR/scripts/generate-theme.sh" > /dev/null

# Reload wallpaper
echo -e "${BLUE}[*]${NC} Reloading wallpaper..."
local_wp=$(cat "$SUMINAMI_DIR/current-wallpaper" 2>/dev/null)
if command -v awww-daemon &>/dev/null; then
    pgrep -x awww-daemon &>/dev/null || setsid awww-daemon &>/dev/null &
    sleep 0.5
    [ -f "$local_wp" ] && awww img "$local_wp" --transition-type fade --transition-fps 60 --transition-duration 1
elif command -v swww-daemon &>/dev/null; then
    pgrep -x swww-daemon &>/dev/null || setsid swww-daemon &>/dev/null &
    sleep 0.5
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
