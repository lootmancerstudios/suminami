#!/bin/bash
# Suminami Themes Menu

SUMINAMI_DIR="$HOME/.config/suminami"
CURRENT_THEME=$(cat "$SUMINAMI_DIR/themes/current" 2>/dev/null || echo "kanagawa")

OPTIONS="󰉼  Kanagawa
󰉼  Kanagawa Lotus
󰉼  Kanagawa Dragon
󰉼  Kanagawa Blossom
󰉼  Catppuccin Mocha
󰉼  Catppuccin Macchiato
󰉼  Catppuccin Frappe
󰉼  Catppuccin Latte
󰉼  Gruvbox Dark"

CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -cycle \
    -theme-str 'inputbar { enabled: false; }' \
    -theme-str 'window { width: 320px; height: 360px; }')

case "$CHOICE" in
    *"Kanagawa Lotus"*)
        "$SUMINAMI_DIR/scripts/switch-theme.sh" kanagawa-lotus
        ;;
    *"Kanagawa Dragon"*)
        "$SUMINAMI_DIR/scripts/switch-theme.sh" kanagawa-dragon
        ;;
    *"Kanagawa Blossom"*)
        "$SUMINAMI_DIR/scripts/switch-theme.sh" kanagawa-blossom
        ;;
    *"Kanagawa"*)
        "$SUMINAMI_DIR/scripts/switch-theme.sh" kanagawa
        ;;
    *"Catppuccin Mocha"*)
        "$SUMINAMI_DIR/scripts/switch-theme.sh" catppuccin-mocha
        ;;
    *"Catppuccin Macchiato"*)
        "$SUMINAMI_DIR/scripts/switch-theme.sh" catppuccin-macchiato
        ;;
    *"Catppuccin Frappe"*)
        "$SUMINAMI_DIR/scripts/switch-theme.sh" catppuccin-frappe
        ;;
    *"Catppuccin Latte"*)
        "$SUMINAMI_DIR/scripts/switch-theme.sh" catppuccin-latte
        ;;
    *"Gruvbox Dark"*)
        "$SUMINAMI_DIR/scripts/switch-theme.sh" gruvbox-dark
        ;;
esac
