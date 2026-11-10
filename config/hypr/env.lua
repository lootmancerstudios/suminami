-- Programs, environment variables and autostart.

-- Programs that the keybinds launch. Change these to swap defaults; keybinds.lua
-- reads them back from the table this module returns.
local programs = {
    terminal     = "kitty",
    file_manager = "thunar",
    menu         = "~/.config/waybar/scripts/launcher",
    browser      = "firefox",
}

-- See https://wiki.hypr.land/configuring/core/environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Autostart. Subscribing to hyprland.start runs these once when the compositor
-- comes up, rather than again on every config reload -- the Lua equivalent of
-- exec-once. Commands are handed to /bin/sh -c, so "~" and shell operators
-- behave as they would in a terminal.
hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/waybar/scripts/generate-style && waybar")

    -- Restore the wallpaper that was last set. awww is preferred and swww is
    -- the fallback; with neither installed this is a no-op.
    hl.exec_cmd([==[wp=$(cat ~/.config/suminami/current-wallpaper 2>/dev/null || echo ~/.config/suminami/wallpapers/kanagawa.jpg); if command -v awww-daemon >/dev/null; then awww-daemon && awww img "$wp"; elif command -v swww-daemon >/dev/null; then swww-daemon && swww img "$wp"; fi]==])

    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Secret Service provider (org.freedesktop.secrets). Hyprland has no session
    -- manager to start one, and kwallet ships no D-Bus activation file for that
    -- name, so apps using libsecret/qtkeychain (Nextcloud client) cannot persist
    -- credentials without this.
    hl.exec_cmd("/usr/bin/ksecretd")

    -- Web apps: starts a tray agent for each installed one. Definitions that were
    -- never installed are skipped, so this is a no-op for users who want none.
    hl.exec_cmd("~/.config/suminami/scripts/webapp-autostart")

    -- Reports a setup the rice cannot work properly on, such as a Waybar too old
    -- to drive this config. Silent when everything is in order.
    hl.exec_cmd("~/.config/suminami/scripts/session-check")

    -- Optional extras that install.sh offers -- hypridle, clipboard persistence
    -- -- are written to conf.d/10-autostart-extras.lua instead of here, so this
    -- tracked file is never edited and never has to be stashed on an update.
end)

return programs
