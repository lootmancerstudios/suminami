#!/bin/bash
# Suminami Help Menu

show_keybinds() {
    KEYBINDS_FILE="$HOME/.config/hypr/keybinds.conf"

    if [ ! -f "$KEYBINDS_FILE" ]; then
        notify-send "Keybinds" "keybinds.conf not found"
        return
    fi

    # Parse keybinds.conf and format for display
    # Format: bind = MODS, KEY, action, args -> "MODS + KEY  →  action args"
    keybinds=$(grep -E "^bind[elm]*\s*=" "$KEYBINDS_FILE" | while read -r line; do
        # Extract parts: bind = MODS, KEY, action, args
        # Remove 'bind = ' or 'bindel = ' etc
        clean=$(echo "$line" | sed 's/^bind[elm]*\s*=\s*//')

        # Split by comma
        mods=$(echo "$clean" | cut -d',' -f1 | sed 's/\$mainMod/Super/g' | xargs)
        key=$(echo "$clean" | cut -d',' -f2 | xargs)
        action=$(echo "$clean" | cut -d',' -f3 | xargs)
        args=$(echo "$clean" | cut -d',' -f4- | xargs)

        # Format modifiers nicely
        if [ -n "$mods" ] && [ "$mods" != "" ]; then
            combo="$mods + $key"
        else
            combo="$key"
        fi

        # Clean up action display
        if [ "$action" = "exec" ]; then
            # Show the command being executed (basename only)
            cmd=$(basename "$(echo "$args" | awk '{print $1}')")
            printf "%-28s  →  %s\n" "$combo" "$cmd"
        else
            printf "%-28s  →  %s %s\n" "$combo" "$action" "$args"
        fi
    done | sort -u)

    # Show in rofi (no search, just browse with cycling)
    echo "$keybinds" | rofi -dmenu -cycle \
        -theme-str 'inputbar { enabled: false; }' \
        -theme-str 'window { width: 550px; height: 500px; }'
}

OPTIONS="󰌌  Keybinds
󰖟  Hyprland Wiki
󰈙  Suminami Docs"

CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -cycle \
    -theme-str 'inputbar { enabled: false; }' \
    -theme-str 'window { width: 320px; }' \
    -theme-str 'listview { lines: 3; }')

case "$CHOICE" in
    *"Keybinds"*)
        show_keybinds
        ;;
    *"Hyprland Wiki"*)
        xdg-open "https://wiki.hyprland.org"
        ;;
    *"Suminami Docs"*)
        xdg-open "https://github.com/lootmancerstudios/suminami"
        ;;
esac
