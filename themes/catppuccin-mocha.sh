#!/bin/bash
# Suminami Theme: Catppuccin Mocha
# Darkest variant with rich, vibrant pastels
# Uses WARMED mocha/coffee brown backgrounds (not standard catppuccin)

THEME_NAME="catppuccin-mocha"
THEME_TYPE="dark"

# Background colors (rich mocha/coffee brown - WARMED)
BG_PRIMARY="#181210"      # sumiInk0 - Main background (warmed)
BG_SECONDARY="#221c1a"    # sumiInk3 - Secondary/input background
BG_TERTIARY="#342e2c"     # sumiInk4 - Hover states
BG_HIGHLIGHT="#484240"    # sumiInk5 - Borders, subtle highlights

# Foreground colors
FG_PRIMARY="#cdd6f4"      # fujiWhite - Main text
FG_SECONDARY="#bac2de"    # oldWhite - Secondary text
FG_MUTED="#6c7086"        # fujiGray - Muted/placeholder text

# Accent colors
ACCENT_PRIMARY="#f5c2e7"  # sakuraPink - Primary accent
ACCENT_SECONDARY="#89b4fa" # crystalBlue - Secondary accent
ACCENT_TERTIARY="#a6e3a1" # springGreen - Success/positive
ACCENT_WARNING="#f9e2af"  # carpYellow - Warning
ACCENT_ERROR="#f38ba8"    # waveRed - Error/urgent

# Module-specific colors (warm mocha pastels)
MODULE_LAUNCHER="#f5e0dc"
MODULE_WORKSPACE_ACTIVE="#f5e0dc"
MODULE_CLOCK="#fab387"
MODULE_WORKSPACES="#89b4fa"
MODULE_WINDOW="#bac2de"
MODULE_MEDIA="#f9e2af"
MODULE_VOLUME="#74c7ec"
MODULE_BRIGHTNESS="#f9e2af"
MODULE_BATTERY="#a6e3a1"
MODULE_BATTERY_WARNING="#f9e2af"
MODULE_BATTERY_CRITICAL="#f38ba8"
MODULE_NETWORK="#eba0ac"
MODULE_BLUETOOTH="#f2cdcd"
MODULE_CPU="#f38ba8"
MODULE_MEMORY="#cba6f7"
MODULE_TEMP="#f38ba8"
MODULE_POWER="#f38ba8"

# Border/UI
BORDER_COLOR="#484240"
BORDER_RADIUS="8"
BORDER_WIDTH="1"

# Transparency (0-100)
BG_OPACITY="95"

# Raw palette colors (for waybar CSS compatibility)
RAW_SUMI_INK1="#1c1614"
RAW_SUMI_INK2="#221c1a"
RAW_SUMI_INK3="#221c1a"
RAW_SUMI_INK6="#746E6C"
RAW_FUJI_GRAY="#6c7086"
RAW_SAKURA_PINK="#f5c2e7"
RAW_ONI_VIOLET="#cba6f7"
RAW_CRYSTAL_BLUE="#89b4fa"
RAW_SPRING_BLUE="#74c7ec"
RAW_LIGHT_BLUE="#89dceb"
RAW_SPRING_GREEN="#a6e3a1"
RAW_CARP_YELLOW="#f9e2af"
RAW_WAVE_RED="#f38ba8"
RAW_PEACH_RED="#eba0ac"
RAW_SURIMI_ORANGE="#fab387"
RAW_WAVE_AQUA="#94e2d5"
RAW_KATANA_GRAY="#7f849c"
RAW_DRAGON_BLUE="#7dc4e4"

# Additional catppuccin colors
RAW_ROSEWATER="#f5e0dc"
RAW_FLAMINGO="#f2cdcd"

# Module colors from original
RAW_MODULE_MUTED="#84889E"
RAW_MODULE_SYSTEM="#f9e2af"
RAW_MODULE_WEATHER="#f2cdcd"
