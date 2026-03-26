#!/bin/bash
# Suminami Wallpapers Menu - Live Preview

WALLPAPER_DIR="$HOME/.config/suminami/wallpapers"
CURRENT_FILE="$HOME/.config/suminami/current-wallpaper"

# Create directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"

# Check if wallpapers exist (jpg, jpeg, png, webp, gif)
if [ ! -d "$WALLPAPER_DIR" ] || [ -z "$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) 2>/dev/null)" ]; then
    gdbus call --session --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify \
        "SumiNami" 0 "" "No Wallpapers" "Add images to ~/.config/suminami/wallpapers/" "[]" "{}" 5000 >/dev/null 2>&1
    exit 0
fi

ORIGINAL_WALLPAPER=$(cat "$CURRENT_FILE" 2>/dev/null)

# Function to set wallpaper
set_wallpaper() {
    local path="$1"
    if command -v awww &>/dev/null && pgrep -x awww-daemon &>/dev/null; then
        awww img "$path" --transition-type fade --transition-fps 60 --transition-duration 1
    elif command -v swww &>/dev/null && pgrep -x swww-daemon &>/dev/null; then
        swww img "$path" --transition-type fade --transition-fps 60 --transition-duration 1
    elif command -v swaybg &>/dev/null; then
        pkill swaybg 2>/dev/null
        swaybg -i "$path" -m fill &
        disown
    fi
}

# Function to revert wallpaper
revert_wallpaper() {
    if [ -n "$ORIGINAL_WALLPAPER" ] && [ -f "$ORIGINAL_WALLPAPER" ]; then
        set_wallpaper "$ORIGINAL_WALLPAPER"
    fi
}

# Main preview loop
while true; do
    # Show wallpaper list (filter for common image types)
    CHOICE=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) -printf "%f\n" | sort | rofi -dmenu -cycle \
        -p "Select wallpaper" \
        -theme-str 'window { width: 400px; }' \
        -theme-str 'listview { lines: 8; }')

    # ESC pressed - revert and exit
    if [ -z "$CHOICE" ]; then
        revert_wallpaper
        exit 0
    fi

    PREVIEW_PATH="$WALLPAPER_DIR/$CHOICE"

    # Check file exists
    if [ ! -f "$PREVIEW_PATH" ]; then
        continue
    fi

    # Preview the selection (live on desktop)
    set_wallpaper "$PREVIEW_PATH"

    # Ask to confirm or try another
    CONFIRM=$(echo -e "  Keep this wallpaper\n  Try another" | rofi -dmenu -cycle \
        -p "$CHOICE" \
        -theme-str 'inputbar { enabled: false; }' \
        -theme-str 'window { width: 320px; }' \
        -theme-str 'listview { lines: 2; }')

    case "$CONFIRM" in
        *"Keep"*)
            # Save as current and exit
            echo "$PREVIEW_PATH" > "$CURRENT_FILE"
            gdbus call --session --dest org.freedesktop.Notifications \
                --object-path /org/freedesktop/Notifications \
                --method org.freedesktop.Notifications.Notify \
                "SumiNami" 0 "" "Wallpaper Set" "$CHOICE" "[]" "{}" 3000 >/dev/null 2>&1
            exit 0
            ;;
        *"Try another"*)
            # Loop back to selection
            continue
            ;;
        *)
            # ESC pressed on confirm - revert and exit
            revert_wallpaper
            exit 0
            ;;
    esac
done
