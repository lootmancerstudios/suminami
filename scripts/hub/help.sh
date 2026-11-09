#!/bin/bash
# Suminami Help Menu

show_keybinds() {
    # Binds are read back from Hyprland rather than parsed out of the config.
    # The config is Lua, where a bind can be built in a loop or from a variable,
    # so the file is no longer something to read with sed -- and asking the
    # compositor also picks up the generated web-app binds, which live in a
    # drop-in and were never listed here before.
    local binds
    binds="$(hyprctl binds -j 2>/dev/null)"

    if ! command -v jq > /dev/null 2>&1; then
        notify-send "Keybinds" "jq is needed to list keybinds"
        return
    fi

    if [ -z "$binds" ]; then
        notify-send "Keybinds" "Could not read binds from Hyprland"
        return
    fi

    # modmask is an X modifier bitmask: Shift 1, Ctrl 4, Alt 8, Super 64.
    # Listed in a fixed order so the same combination always reads the same way,
    # whichever order it was written in.
    keybinds=$(printf '%s' "$binds" | jq -r '
        def bit($n): ((.modmask / $n) | floor) % 2 == 1;
        .[]
        | select((.key // "") != "")
        | [ (if bit(64) then "Super" else empty end),
            (if bit(4)  then "Ctrl"  else empty end),
            (if bit(8)  then "Alt"   else empty end),
            (if bit(1)  then "Shift" else empty end),
            .key ] as $combo
        | (if .has_description then .description
           else ((.dispatcher // "") + " " + (.arg // "")) end) as $label
        | "\($combo | join(" + "))\t\($label | gsub("^\\s+|\\s+$"; ""))"
    ' 2>/dev/null | awk -F'\t' '{ printf "%-28s  \xe2\x86\x92  %s\n", $1, $2 }' | sort -u)

    if [ -z "$keybinds" ]; then
        notify-send "Keybinds" "Hyprland reported no keybinds"
        return
    fi

    # Show in rofi (no search, just browse with cycling)
    echo "$keybinds" | rofi -dmenu -cycle \
        -theme-str 'inputbar { enabled: false; }' \
        -theme-str 'card { width: 550px; }' \
        -theme-str 'listview { lines: 14; }'
}

OPTIONS="󰌌  Keybinds
󰖟  Hyprland Wiki
󰈙  Suminami Docs"

CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -cycle \
    -theme-str 'inputbar { enabled: false; }' \
    -theme-str 'card { width: 320px; }' \
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
