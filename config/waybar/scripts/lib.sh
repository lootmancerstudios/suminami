#!/bin/bash
# Shared helpers for SumiNami Waybar widgets. Sourced, not executed.

# Escape a value for safe use inside BOTH the Waybar JSON string and the Pango
# tooltip markup that widgets build by hand.
#
# Without this, ordinary external text breaks the module outright:
#   - a literal " terminates the JSON string, so Waybar drops the module
#   - & < > are Pango markup, so the tooltip fails to parse and renders empty
#   - a raw newline is invalid inside a JSON string
# Track titles, SSIDs, and device names all routinely contain these.
#
# Escape the backslash first so the later &-substitutions aren't doubled.
# Only apply this to *data*, never to a whole tooltip: the widgets' own <span>
# wrappers and \n separators are markup and must pass through unescaped.
esc() {
    printf '%s' "$1" \
        | tr '\n\r' '  ' \
        | sed 's/\\/\\\\/g; s/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}
