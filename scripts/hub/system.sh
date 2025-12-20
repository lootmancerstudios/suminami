#!/bin/bash
# Suminami System Menu

OPTIONS="󰌾  Lock
󰤄  Sleep
󰜉  Restart
󰐥  Shutdown
󰗽  Log Out"

CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu \
    --hide-search \
    --width 320 \
    --lines 5 \
    --cache-file /dev/null \
    --columns 1)

case "$CHOICE" in
    *"Lock"*)
        loginctl lock-session
        ;;
    *"Sleep"*)
        systemctl suspend
        ;;
    *"Restart"*)
        systemctl reboot
        ;;
    *"Shutdown"*)
        systemctl poweroff
        ;;
    *"Log Out"*)
        hyprctl dispatch exit
        ;;
esac
