#!/bin/bash
# Hyprland version and config-health helpers, shared by the updater and the hub.
#
# SumiNami's Hyprland config is Lua. Hyprland gained the Lua config in 0.55 and
# dropped the old hyprlang (.conf) format in 0.57, so 0.55 is the floor: on
# anything older the compositor looks for hyprland.conf, finds none of ours, and
# writes itself a default -- a stock desktop with none of the rice, and no error
# to explain why.

HYPR_MIN_VERSION="0.55.0"

# Installed Hyprland version as "major.minor.patch", empty if it cannot be read.
# Asks the running compositor first and the package manager second, so this also
# works from a TTY with no session up.
hypr_version() {
    local v
    v="$(hyprctl version -j 2>/dev/null \
        | sed -n 's/.*"tag"[[:space:]]*:[[:space:]]*"v\{0,1\}\([0-9][0-9.]*\).*/\1/p' \
        | head -1)"
    [ -z "$v" ] && v="$(pacman -Q hyprland 2>/dev/null | awk '{print $2}' | cut -d- -f1)"
    printf '%s\n' "$v"
}

# True when $1 (a dotted version) is greater than or equal to $2.
hypr_version_ge() {
    [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]
}

# True when the installed Hyprland can read this config tree.
hypr_version_ok() {
    local v
    v="$(hypr_version)"
    # An unreadable version is not treated as a failure: better to proceed than
    # to block an install because hyprctl and pacman were both unavailable.
    [ -z "$v" ] && return 0
    hypr_version_ge "$v" "$HYPR_MIN_VERSION"
}

# True when the running compositor is actually using our config.
#
# Checking for config errors is not enough to catch this. If Hyprland never
# found our config it generated its own, and a generated default is valid -- so
# "hyprctl configerrors" comes back clean while none of the rice is loaded.
# Instead ask for a value that SumiNami sets and Hyprland's default does not:
# "set" is true only when a config actually assigned it.
hypr_config_loaded() {
    hyprctl getoption misc:disable_hyprland_logo -j 2>/dev/null \
        | grep -q '"set"[[:space:]]*:[[:space:]]*true'
}

# Waybar's workspace buttons do not run a script of ours: Waybar itself sends
# Hyprland the dispatch. Before 0.16 it sends the pre-Lua dispatcher names,
# which a Hyprland running a Lua config rejects, so clicking a workspace does
# nothing. Nothing in the bar's config can change what Waybar sends.
WAYBAR_MIN_VERSION="0.16.0"

waybar_version() {
    local v
    v="$(waybar --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    [ -z "$v" ] && v="$(pacman -Q waybar 2>/dev/null | awk '{print $2}' | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')"
    printf '%s\n' "$v"
}

waybar_version_ok() {
    local v
    v="$(waybar_version)"
    [ -z "$v" ] && return 0
    hypr_version_ge "$v" "$WAYBAR_MIN_VERSION"
}
