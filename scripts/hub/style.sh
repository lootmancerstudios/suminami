#!/bin/bash
# Suminami Style Menu

SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"

OPTIONS="󰉼  Themes
󰸉  Wallpapers"

CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu \
    --hide-search \
    --width 320 \
    --lines 2 \
    --cache-file /dev/null \
    --columns 1)

case "$CHOICE" in
    *"Themes"*)
        "$SCRIPTS_DIR/themes.sh"
        ;;
    *"Wallpapers"*)
        "$SCRIPTS_DIR/wallpapers.sh"
        ;;
esac
