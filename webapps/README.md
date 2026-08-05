# Web apps

A web app is a site that behaves like an installed application: its own window,
launcher entry and tray icon with an unread badge. Each runs in a dedicated
Firefox profile, so its login is independent of normal browsing.

Add one by dropping a `<name>.conf` file in this directory and running:

```sh
~/.config/suminami/scripts/webapp-install <name>
```

No Hyprland config edit is needed — autostart, the close-to-tray behaviour and
the tray agent are all driven from these definitions.

## Fields

| Field | Required | Meaning |
|---|---|---|
| `class` | yes | Window class. Firefox is launched with `--name <class>`, and Hyprland rules match on it. Must be unique. |
| `url` | yes | Page the app opens. |
| `icon` | yes | Base name of the SVG in `assets/webapps/`, without extension. |
| `name` | no | Display name for the launcher and tray menu. Defaults to the file name. |
| `color` | no | Brand colour applied to the icon glyph. Defaults to black. |
| `unread_pattern` | no | Regex matched against the window title; capture group 1 is the unread count. Omit for apps with no unread state. |
| `app_chrome` | no | `true` hides the tab strip and navigation toolbar so the window reads as an app. |
| `key` | no | Hyprland bind that jumps to this app, without the dispatcher — e.g. `SUPER SHIFT, W`. Generated only when the app is installed, so declining leaves no dead keybind. |

Whole-line `#` comments only — values legitimately contain `#`, since colours
are hex and patterns are regexes.

## Removing one

Autostart skips any web app that has no Firefox profile, so deleting the profile
is the off switch:

```sh
rm -rf ~/.mozilla/firefox/<name>
```

That stops it launching at login and removes its tray icon. The generated icons
and launcher entry are left behind — a few KB, inert. Delete them too if you
want it gone completely:

```sh
rm -f ~/.local/share/applications/suminami-webapp-<name>.desktop
rm -f ~/.local/share/icons/hicolor/scalable/apps/suminami-<icon>*.svg
```

Note that deleting the profile also deletes that app's login, so you will scan
the QR code again if you reinstall it.

## The icon asset

`assets/webapps/<icon>.svg` holds the brand glyph with **no `fill` attribute**;
`color` from the definition is applied at install time. The installer composes
it with a count badge into one icon per unread value, so the tray shows a real
number by switching icon names rather than rendering anything at runtime.

## Behaviour

- **Left-click tray** — jump to the window, or hide it if it is already in front.
  A window on a normal workspace stays put and you are switched to it. A hidden
  window returns to the workspace it was hidden from, or comes to your current
  one if it has no history yet.
- **Right-click tray** — menu: unread status, Show, Hide to tray, Quit.
- **Super+Q on the window** — hides to tray rather than closing, since Firefox
  has no hide-to-tray of its own and quitting would take the tray icon with it.
- **Quit from the menu** — closes the window and removes the tray icon.

Hidden windows are parked on the special workspace `special:<class>-hidden`.
That workspace is never shown as an overlay — showing the app puts its window on
a normal workspace, where it tiles like anything else.

The workspace a window was hidden from is remembered in `$XDG_RUNTIME_DIR`, so
it goes back there rather than following you around. That state is runtime-only
and resets on reboot, at which point a freshly started app comes to whichever
workspace you show it from.

## Unread counts

Zero unread shows the plain glyph with no badge. Counts `1`–`9` are drawn as
themselves; anything higher shows `9+`, so an install is a fixed 11 icons per
app however busy a chat gets.

The count is read from the window title, which is the only unread signal a
browser exposes to the outside. An app that does not put a count in its title
cannot show a badge — leave `unread_pattern` unset for those. Desktop
notifications are separate and work regardless, handled by Firefox and dunst.
