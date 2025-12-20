#!/bin/bash
# Suminami Hub Menu

SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"

# Menu options with icons
OPTIONS="󰀻  Apps
󰃣  Style
󰑓  Reload
󰋗  Help
󰐥  System"

# Show menu
CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu \
    --hide-search \
    --width 320 \
    --lines 5 \
    --cache-file /dev/null \
    --columns 1)

# Handle selection
case "$CHOICE" in
    *"Apps"*)
        wofi --show drun
        ;;
    *"Style"*)
        "$SCRIPTS_DIR/style.sh"
        ;;
    *"Reload"*)
        # Regenerate theme and reload components
        "$HOME/.config/suminami/scripts/generate-theme.sh"
        hyprctl reload
        pkill waybar; sleep 0.3; waybar &
        systemctl --user restart dunst
        gdbus call --session --dest org.freedesktop.Notifications \
            --object-path /org/freedesktop/Notifications \
            --method org.freedesktop.Notifications.Notify \
            "SumiNami" 0 "" "Reloaded" "Hyprland, Waybar, Dunst, and styles refreshed" "[]" "{}" 3000 >/dev/null 2>&1
        ;;
    *"Help"*)
        "$SCRIPTS_DIR/help.sh"
        ;;
    *"System"*)
        "$SCRIPTS_DIR/system.sh"
        ;;
esac
