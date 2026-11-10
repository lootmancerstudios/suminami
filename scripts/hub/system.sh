#!/bin/bash
# Suminami System Menu

OPTIONS="󰌾  Lock
󰤄  Sleep
󰗽  Log Out
󰜉  Restart
󰐥  Shutdown"

CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -cycle \
    -theme-str 'inputbar { enabled: false; }' \
    -theme-str 'card { width: 320px; }' \
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
        # Lua dispatch first. A session still running on the pre-Lua config
        # rejects it, and logging out is exactly how that session finishes the
        # update, so fall back to the old dispatcher name.
        [ "$(hyprctl dispatch 'hl.dsp.exit()' 2>/dev/null)" = "ok" ] \
            || hyprctl dispatch exit
        ;;
esac
