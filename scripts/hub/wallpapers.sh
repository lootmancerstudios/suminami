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

# Detect wallpaper backend
if pgrep -x hyprpaper >/dev/null; then
    BACKEND="hyprpaper"
    # Get current wallpaper from hyprpaper
    ORIGINAL_WALLPAPER=$(hyprctl hyprpaper listactive 2>/dev/null | head -1 | cut -d'=' -f2 | xargs)
else
    BACKEND="swaybg"
    ORIGINAL_WALLPAPER=$(cat "$CURRENT_FILE" 2>/dev/null)
fi

# Function to set wallpaper
set_wallpaper() {
    local path="$1"
    if [ "$BACKEND" = "hyprpaper" ]; then
        hyprctl hyprpaper preload "$path" >/dev/null 2>&1
        hyprctl hyprpaper wallpaper ",${path}" >/dev/null 2>&1
    else
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
    CHOICE=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) -printf "%f\n" | sort | wofi --dmenu \
        --prompt "Select wallpaper" \
        --width 400 \
        --lines 8 \
        --cache-file /dev/null \
        --columns 1)

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
    CONFIRM=$(echo -e "  Keep this wallpaper\n  Try another" | wofi --dmenu \
        --prompt "$CHOICE" \
        --width 320 \
        --lines 2 \
        --cache-file /dev/null \
        --columns 1)

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
