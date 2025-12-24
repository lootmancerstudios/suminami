# Suminami

A polished Hyprland desktop rice with rich theming, custom modals, and cohesive design.

## Overview

Suminami is a complete desktop experience built around the Kanagawa color palette (with additional theme options). Every component is designed to work together seamlessly.

## Components

| Component | Description |
|-----------|-------------|
| Hyprland | Window manager configuration |
| Waybar | Status bar with rich tooltips |
| Rofi | Application launcher and custom menus |
| Notifications | Styled notification system |
| Lock Screen | Themed lock screen |
| And more... | Terminal, GTK theming, etc. |

## Structure

```
suminami/
├── config/           # Application configs (symlinked to ~/.config/)
│   ├── hypr/
│   ├── waybar/
│   ├── rofi/
│   └── ...
├── themes/           # Master theme definitions
│   └── kanagawa/
├── scripts/          # Rice-wide scripts
├── wallpapers/       # Matching wallpapers
└── install.sh        # Installer
```

## Installation

```bash
bash <(curl -s https://raw.githubusercontent.com/lootmancerstudios/suminami/main/install.sh)
```

## Theme System

Themes are defined centrally in `themes/` and applied across all components. Changing your theme updates everything at once.

## Development

This rice is under active development. See [suminami-bar](https://github.com/lootmancerstudios/suminami-bar) for the standalone waybar theme.

## Credits

### Inspiration
*The Great Wave off Kanagawa* by Katsushika Hokusai

### Color Schemes
- [Kanagawa](https://github.com/rebelot/kanagawa.nvim) by rebelot
- [Catppuccin](https://github.com/catppuccin/catppuccin) by Catppuccin Org
- [Gruvbox](https://github.com/morhetz/gruvbox) by morhetz

### Wallpapers
Theme wallpapers by [Refiend](https://www.deviantart.com/refiend) on DeviantArt.

## License

MIT License - See [LICENSE](LICENSE) for details.
