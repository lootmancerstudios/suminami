#!/bin/bash
# Suminami Style Menu

SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"

OPTIONS="󰉼  Themes
󰸉  Wallpapers"

CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -cycle \
    -theme-str 'inputbar { enabled: false; }' \
    -theme-str 'window { width: 320px; }' \
    -theme-str 'listview { lines: 2; }')

case "$CHOICE" in
    *"Themes"*)
        "$SCRIPTS_DIR/themes.sh"
        ;;
    *"Wallpapers"*)
        "$SCRIPTS_DIR/wallpapers.sh"
        ;;
esac
