#!/bin/bash
# Suminami System Menu

OPTIONS="󰌾  Lock
󰤄  Sleep
󰗽  Log Out
󰜉  Restart
󰐥  Shutdown"

CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -cycle \
    -theme-str 'inputbar { enabled: false; }' \
    -theme-str 'window { width: 320px; }' \
    -theme-str 'listview { lines: 5; }')

case "$CHOICE" in
    *"Lock"*)
        hyprlock
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
