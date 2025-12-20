#!/bin/bash
# Suminami Help Menu

OPTIONS="󰌌  Keybinds
󰖟  Hyprland Wiki
󰈙  Suminami Docs"

CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu \
    --hide-search \
    --width 320 \
    --lines 3 \
    --cache-file /dev/null \
    --columns 1)

case "$CHOICE" in
    *"Keybinds"*)
        # Show keybinds in a floating terminal
        kitty --class floating -e sh -c 'echo "=== Suminami Keybinds ===

Super + A        Hub Menu
Super + Enter    Terminal
Super + Q        Close Window
Super + 1-9      Switch Workspace
Super + Shift + 1-9  Move to Workspace

Super + H/J/K/L  Focus Window
Super + Shift + H/J/K/L  Move Window

Super + F        Fullscreen
Super + Space    Float Toggle

Press q to exit" | less'
        ;;
    *"Hyprland Wiki"*)
        xdg-open "https://wiki.hyprland.org"
        ;;
    *"Suminami Docs"*)
        xdg-open "https://github.com/lootmancerstudios/suminami"
        ;;
esac
