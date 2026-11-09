-- SumiNami Hyprland configuration.
--
-- Hyprland 0.57 removed the hyprlang (.conf) config format and reads only
-- hyprland.lua. Hyprland 0.55 and 0.56 look for hyprland.lua first and fall
-- back to hyprland.conf, so this one tree covers 0.55 through 0.57 and later.
--
-- Settings live in the modules required below; edit those rather than this
-- file. See https://wiki.hypr.land/configuring/
--
-- Modules are required by explicit path rather than by module name. A plain
-- name goes through Lua's own module search, which rewrites dots into directory
-- separators and would look for a nested folder; an explicit path is resolved
-- as the literal file.

local HOME = os.getenv("HOME") or ""

-- Directory holding this file, used to build the paths below. Falls back to the
-- default location if the path cannot be read, so the fallback stays absolute:
-- require() resolves relative names against the config directory while
-- io.open() would resolve them against the working directory.
local CONFIG_DIR = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
if CONFIG_DIR:sub(1, 1) ~= "/" then
    CONFIG_DIR = HOME .. "/.config/hypr/"
end

-- Requires a file only when it is present. The machine-specific files are
-- git-ignored and may legitimately be absent -- cloning the repo without
-- running install.sh still has to produce a working session, and require() has
-- no "load if present" form: a missing file is a hard config error.
--
-- Errors raised *inside* a file that does exist are left to propagate. A typo
-- in monitors.lua should be reported, not silently swallowed.
local function require_optional(path)
    local file = io.open(path, "r")
    if not file then
        return false
    end
    file:close()
    require(path)
    return true
end

-- Monitor setup: committed safe default first, then the per-machine override.
-- Copy monitors.lua.example to monitors.lua and edit it for your displays;
-- monitors.lua is git-ignored so updates never clobber it. Loading the default
-- first means a fresh clone still gets a working monitor before the override.
require("./monitors-default.lua")
require_optional(CONFIG_DIR .. "monitors.lua")

require("./env.lua")
require("./input.lua")
require("./visuals.lua")
require("./layout.lua")
require("./keybinds.lua")
require("./rules.lua")

-- Hardware-specific drop-in, written by install.sh outside this repo so it
-- survives updates instead of showing up as a local change to a tracked file.
require_optional(HOME .. "/.config/hypr-local/nvidia.lua")

-- Drop-ins (generated web-app rules, your own fragments), loaded in sorted
-- order. The glob has to match at least one file or Hyprland reports a config
-- error, which is what conf.d/00-placeholder.lua is for.
require("./conf.d/*.lua")

-- Machine-specific overrides, loaded last so they win.
require_optional(CONFIG_DIR .. "local.lua")
