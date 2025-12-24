#!/bin/bash
# Suminami Hub Menu

SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"

# Menu options with icons
OPTIONS="󰀻  Apps
󰃣  Style
󰑓  Reload
󰋗  Help
󰚰  Update
󰐥  System"

# Show menu (rofi with cycle enabled, no search bar)
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -cycle \
    -theme-str 'inputbar { enabled: false; }' \
    -theme-str 'window { width: 320px; }' \
    -theme-str 'listview { lines: 6; }')

# Handle selection
case "$CHOICE" in
    *"Apps"*)
        rofi -show drun
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
    *"Update"*)
        kitty -e "$HOME/.config/suminami/scripts/update.sh"
        ;;
    *"System"*)
        "$SCRIPTS_DIR/system.sh"
        ;;
esac
