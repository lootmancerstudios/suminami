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
    -theme-str 'card { width: 320px; }' \
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

        # Report whether Hyprland is really running our config. A Hyprland too
        # old for the Lua config writes itself a valid default and reports no
        # errors, so a plain "Reloaded" would be misleading.
        SUMMARY="Reloaded"
        BODY="Hyprland, Waybar, Dunst, and styles refreshed"
        # shellcheck source=../lib/hypr.sh
        if source "$SCRIPTS_DIR/../lib/hypr.sh" 2>/dev/null; then
            if ! hypr_version_ok; then
                SUMMARY="Hyprland too old"
                BODY="Hyprland $(hypr_version) cannot read a Lua config; $HYPR_MIN_VERSION or newer is needed"
            elif ! hypr_config_loaded; then
                SUMMARY="Config not loaded"
                BODY="Hyprland is running its own defaults, not SumiNami's config"
            elif ! waybar_version_ok; then
                SUMMARY="Waybar too old"
                BODY="Waybar $(waybar_version) cannot switch workspaces by click; update your system for $WAYBAR_MIN_VERSION or newer"
            fi
        fi

        gdbus call --session --dest org.freedesktop.Notifications \
            --object-path /org/freedesktop/Notifications \
            --method org.freedesktop.Notifications.Notify \
            "SumiNami" 0 "" "$SUMMARY" "$BODY" "[]" "{}" 3000 >/dev/null 2>&1
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
