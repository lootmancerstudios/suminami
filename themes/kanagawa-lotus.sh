#!/bin/bash
# Suminami Theme: Kanagawa Lotus
# Light variant with soft, warm tones
# WCAG AA compliant module colors (4.5:1 min contrast against #f2ecbc)

THEME_NAME="kanagawa-lotus"
THEME_TYPE="light"

# Background colors (lotusWhite series)
BG_PRIMARY="#f2ecbc"      # sumiInk0 - Main background
BG_SECONDARY="#e5ddb0"    # sumiInk2 - Secondary/input background
BG_TERTIARY="#d5cea3"     # sumiInk4 - Hover states
BG_HIGHLIGHT="#c9cbd1"    # sumiInk5 - Borders, subtle highlights

# Foreground colors (dark text on light bg)
FG_PRIMARY="#545464"      # fujiWhite - Main text
FG_SECONDARY="#43436c"    # oldWhite - Secondary text
FG_MUTED="#716e61"        # fujiGray - Muted/placeholder text

# Accent colors (raw palette)
ACCENT_PRIMARY="#b35b79"  # sakuraPink - Primary accent
ACCENT_SECONDARY="#4d699b" # crystalBlue - Secondary accent
ACCENT_TERTIARY="#6f894e" # springGreen - Success/positive
ACCENT_WARNING="#7a5d20"  # WCAG compliant warning (not raw surimiOrange)
ACCENT_ERROR="#a02838"    # WCAG compliant error (not raw waveRed)

# Module-specific colors (WCAG AA compliant for light bg)
MODULE_LAUNCHER="#8a3d5c"
MODULE_WORKSPACE_ACTIVE="#8a3d5c"
MODULE_CLOCK="#8a3d5c"
MODULE_WORKSPACES="#4d699b"
MODULE_WINDOW="#43436c"
MODULE_MEDIA="#3d6030"
MODULE_VOLUME="#4a4590"
MODULE_BRIGHTNESS="#7a5d20"
MODULE_BATTERY="#3d6030"
MODULE_BATTERY_WARNING="#7a5d20"
MODULE_BATTERY_CRITICAL="#a02838"
MODULE_NETWORK="#523d70"
MODULE_BLUETOOTH="#4a4590"
MODULE_CPU="#a02838"
MODULE_MEMORY="#624c83"
MODULE_TEMP="#a02838"
MODULE_POWER="#a02838"

# Border/UI
BORDER_COLOR="#c9cbd1"
BORDER_RADIUS="8"
BORDER_WIDTH="1"

# Transparency (0-100)
BG_OPACITY="95"

# Raw palette colors (for waybar CSS compatibility)
RAW_SUMI_INK1="#e7dba0"
RAW_SUMI_INK3="#dcd5ac"
RAW_SUMI_INK6="#9A9890"
RAW_FUJI_GRAY="#716e61"
RAW_SAKURA_PINK="#b35b79"
RAW_ONI_VIOLET="#624c83"
RAW_CRYSTAL_BLUE="#4d699b"
RAW_SPRING_BLUE="#5d57a3"
RAW_LIGHT_BLUE="#9fb5c9"
RAW_SPRING_GREEN="#6f894e"
RAW_CARP_YELLOW="#77713f"
RAW_WAVE_RED="#c84053"
RAW_PEACH_RED="#d7474b"
RAW_SURIMI_ORANGE="#cc6d00"
RAW_WAVE_AQUA="#597b75"
RAW_KATANA_GRAY="#8a8980"
RAW_DRAGON_BLUE="#4e8ca2"

# WCAG compliant module colors
RAW_MODULE_MUTED="#727068"
RAW_MODULE_SYSTEM="#3d6030"
RAW_MODULE_WEATHER="#3d5580"
