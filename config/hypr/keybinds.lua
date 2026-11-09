-- See https://wiki.hypr.land/configuring/core/binds/
--
-- Every bind carries a desc. The Hub's Help menu lists binds by asking
-- Hyprland for them rather than by reading this file, so the description is
-- what a user actually sees there.

local progs   = require("./env.lua")
local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Closes normally, except for web apps defined in webapps/, which hide to
-- the tray instead -- Firefox has no hide-to-tray of its own.
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("~/.config/suminami/scripts/smart-close"), { desc = "Close window (web apps hide to tray)" })
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(progs.file_manager), { desc = "File manager" })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { desc = "Toggle floating" })
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(progs.menu), { desc = "Hub menu" })
hl.bind(mainMod .. " + W", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { desc = "Toggle fullscreen" })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { desc = "Toggle pseudotiling" }) -- dwindle
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), { desc = "Toggle split orientation" }) -- dwindle
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(progs.browser), { desc = "Browser" })
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd(progs.browser .. " --private-window"), { desc = "Browser (private window)" })
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(progs.terminal), { desc = "Terminal" })

-- Power menu and lock
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("~/.config/suminami/scripts/hub/system.sh"), { desc = "Power menu" })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"), { desc = "Lock screen" })

-- Color picker (copies hex to clipboard)
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("hyprpicker -a"), { desc = "Pick a colour" })

-- Night light toggle (gammastep)
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("~/.config/suminami/scripts/night-light"), { desc = "Toggle night light" })

-- Screenshots (hyprshot)
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m output -o ~/Pictures"), { desc = "Screenshot: whole output" })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("hyprshot -m region -o ~/Pictures"), { desc = "Screenshot: region" })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m window -o ~/Pictures"), { desc = "Screenshot: window" })
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("hyprshot -m window -o ~/Pictures"), { desc = "Screenshot: window" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region -o ~/Pictures"), { desc = "Screenshot: region" })

-- Screen recording (wf-recorder with GPU auto-detection)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/suminami/scripts/screen-record"), { desc = "Record screen" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/suminami/scripts/screen-record region"), { desc = "Record a region" })

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }),  { desc = "Focus left" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { desc = "Focus right" })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }),    { desc = "Focus up" })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }),  { desc = "Focus down" })

-- Resize active window with Super + Shift + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -20, y = 0,   relative = true }), { desc = "Shrink horizontally" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 20,  y = 0,   relative = true }), { desc = "Grow horizontally" })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -20, relative = true }), { desc = "Shrink vertically" })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 20,  relative = true }), { desc = "Grow vertically" })

-- Move active window with Super + Alt + arrow keys
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.move({ direction = "left" }),  { desc = "Move window left" })
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.move({ direction = "right" }), { desc = "Move window right" })
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.move({ direction = "up" }),    { desc = "Move window up" })
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.move({ direction = "down" }),  { desc = "Move window down" })

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }),       { desc = "Workspace " .. i })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { desc = "Move window to workspace " .. i })
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { desc = "Next workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { desc = "Previous workspace" })

-- Navigate workspaces with Ctrl + Super + arrow keys
hl.bind("CTRL + " .. mainMod .. " + left",  hl.dsp.focus({ workspace = "-1" }), { desc = "Previous workspace" })
hl.bind("CTRL + " .. mainMod .. " + right", hl.dsp.focus({ workspace = "+1" }), { desc = "Next workspace" })

-- Move active window to prev/next workspace with Ctrl + Alt + Super + arrow keys
hl.bind("CTRL + ALT + " .. mainMod .. " + left",  hl.dsp.window.move({ workspace = "-1" }), { desc = "Move window to previous workspace" })
hl.bind("CTRL + ALT + " .. mainMod .. " + right", hl.dsp.window.move({ workspace = "+1" }), { desc = "Move window to next workspace" })

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, desc = "Drag to move window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, desc = "Drag to resize window" })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"),      { locked = true, repeating = true, desc = "Volume up" })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"),      { locked = true, repeating = true, desc = "Volume down" })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"),     { locked = true, repeating = true, desc = "Mute output" })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true, repeating = true, desc = "Mute microphone" })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -n2 set 10%+"),                    { locked = true, repeating = true, desc = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -n2 set 10%-"),                    { locked = true, repeating = true, desc = "Brightness down" })

-- Keyboard backlight
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight set 10%+"), { locked = true, repeating = true, desc = "Keyboard backlight up" })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d smc::kbd_backlight set 10%-"), { locked = true, repeating = true, desc = "Keyboard backlight down" })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true, desc = "Next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, desc = "Play/pause" })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, desc = "Play/pause" })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true, desc = "Previous track" })
