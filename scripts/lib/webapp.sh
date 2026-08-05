#!/bin/bash
# Shared helpers for SumiNami web apps. Sourced, not executed.
#
# A web app is a Firefox instance with its own profile and window class, given a
# tray icon and a launcher so it behaves like an installed application. Each one
# is described by a definition file in webapps/<name>.conf.
#
# Definitions are parsed, never sourced: they are plain data, and sourcing them
# would let a stray line in a config file run as shell.

WEBAPP_ROOT="${WEBAPP_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/suminami}"
WEBAPP_DEFS_DIR="$WEBAPP_ROOT/webapps"
WEBAPP_ASSETS_DIR="$WEBAPP_ROOT/assets/webapps"

# Fields a definition may set, and the variable each populates.
# Required: class, url, icon. Optional: name, color, unread_pattern, app_chrome.
webapp_reset() {
    WEBAPP_NAME=""
    WEBAPP_CLASS=""
    WEBAPP_URL=""
    WEBAPP_ICON=""
    WEBAPP_COLOR=""
    WEBAPP_UNREAD_PATTERN=""
    WEBAPP_APP_CHROME=""
    WEBAPP_KEY=""
}

# List the names of all defined web apps, one per line.
webapp_list() {
    [ -d "$WEBAPP_DEFS_DIR" ] || return 0
    local file base
    for file in "$WEBAPP_DEFS_DIR"/*.conf; do
        [ -e "$file" ] || continue
        base="${file##*/}"
        printf '%s\n' "${base%.conf}"
    done
}

# Populate WEBAPP_* from webapps/<name>.conf. Returns non-zero if the definition
# is missing or lacks a required field.
webapp_load() {
    local name="$1"
    local file="$WEBAPP_DEFS_DIR/${name}.conf"

    webapp_reset
    [ -n "$name" ] && [ -r "$file" ] || return 1

    local line key value trimmed
    while IFS= read -r line || [ -n "$line" ]; do
        # Whole-line comments only. Values legitimately contain '#' -- colours
        # are hex, and unread patterns are regexes -- so no inline stripping.
        # Trim first, then test the leading character: a glob like
        # [[:space:]]*'#'* matches any indented line that merely CONTAINS '#',
        # which silently drops real settings and disagrees with lib/webapp.py.
        trimmed="${line#"${line%%[![:space:]]*}"}"
        case "$trimmed" in
            ''|'#'*) continue ;;
            *'='*) ;;
            *) continue ;;
        esac

        key="${line%%=*}"
        value="${line#*=}"
        # Trim surrounding whitespace from both halves.
        key="${key#"${key%%[![:space:]]*}"}"; key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"; value="${value%"${value##*[![:space:]]}"}"

        case "$key" in
            name)           WEBAPP_NAME="$value" ;;
            class)          WEBAPP_CLASS="$value" ;;
            url)            WEBAPP_URL="$value" ;;
            icon)           WEBAPP_ICON="$value" ;;
            color)          WEBAPP_COLOR="$value" ;;
            unread_pattern) WEBAPP_UNREAD_PATTERN="$value" ;;
            app_chrome)     WEBAPP_APP_CHROME="$value" ;;
            key)            WEBAPP_KEY="$value" ;;
        esac
    done < "$file"

    [ -n "$WEBAPP_CLASS" ] && [ -n "$WEBAPP_URL" ] && [ -n "$WEBAPP_ICON" ] || return 1
    [ -n "$WEBAPP_NAME" ] || WEBAPP_NAME="$name"
    return 0
}

# Name of the web app owning a window class, or non-zero if none does.
webapp_by_class() {
    local wanted="$1" name
    [ -n "$wanted" ] || return 1
    while IFS= read -r name; do
        [ -n "$name" ] || continue
        if webapp_load "$name" && [ "$WEBAPP_CLASS" = "$wanted" ]; then
            printf '%s\n' "$name"
            return 0
        fi
    done < <(webapp_list)
    return 1
}

# Per-app paths. Kept here so every script agrees on where things live.
webapp_profile_dir() { printf '%s\n' "$HOME/.mozilla/firefox/$1"; }
webapp_stash_workspace() { printf '%s\n' "special:$1-hidden"; }
