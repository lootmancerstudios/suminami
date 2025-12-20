#!/bin/bash
# Suminami Theme Switcher
# Usage: switch-theme.sh <theme-name>

SUMINAMI_DIR="$HOME/.config/suminami"
THEMES_DIR="$SUMINAMI_DIR/themes"
SCRIPTS_DIR="$SUMINAMI_DIR/scripts"

THEME="$1"

if [ -z "$THEME" ]; then
    echo "Usage: $0 <theme-name>"
    echo "Available themes:"
    ls "$THEMES_DIR"/*.sh 2>/dev/null | xargs -n1 basename | sed 's/.sh$//'
    exit 1
fi

THEME_FILE="$THEMES_DIR/$THEME.sh"
if [ ! -f "$THEME_FILE" ]; then
    echo "Theme not found: $THEME"
    echo "Available themes:"
    ls "$THEMES_DIR"/*.sh 2>/dev/null | xargs -n1 basename | sed 's/.sh$//'
    exit 1
fi

# Update current theme
echo "$THEME" > "$THEMES_DIR/current"

# Generate all styles
"$SCRIPTS_DIR/generate-theme.sh"

# Reload waybar (small delay to ensure files are written)
sleep 0.2
pkill waybar
sleep 0.3
waybar &
disown

# Reload dunst to apply new colors
systemctl --user restart dunst 2>/dev/null

# Set theme wallpaper if it exists (check jpg and png)
WALLPAPER="$SUMINAMI_DIR/wallpapers/$THEME.jpg"
[ ! -f "$WALLPAPER" ] && WALLPAPER="$SUMINAMI_DIR/wallpapers/$THEME.png"
if [ -f "$WALLPAPER" ]; then
    if pgrep -x hyprpaper >/dev/null; then
        hyprctl hyprpaper preload "$WALLPAPER" >/dev/null 2>&1
        hyprctl hyprpaper wallpaper ",${WALLPAPER}" >/dev/null 2>&1
    elif pgrep -x swaybg >/dev/null; then
        pkill swaybg
        swaybg -i "$WALLPAPER" -m fill &
        disown
    fi
    echo "$WALLPAPER" > "$SUMINAMI_DIR/current-wallpaper"
fi

# Notify user via D-Bus
gdbus call --session --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify \
    "SumiNami" 0 "" "Theme Changed" "Switched to $THEME" "[]" "{}" 5000 >/dev/null 2>&1

echo "Switched to theme: $THEME"
