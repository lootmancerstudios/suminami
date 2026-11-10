-- Carries an existing install across the move from hyprlang (.conf) to Lua.
--
-- Before this change the per-machine settings lived in .conf files that the
-- updater never touched. Hyprland no longer reads those, and nothing converts
-- them when an update lands, so without this an existing user would log back in
-- to the wrong monitor layout, no NVIDIA workarounds, and no idle lock.
--
-- Everything here is a fallback: each import applies only while the Lua file
-- that replaces it is missing. Once nobody is upgrading from a .conf install
-- this file and its three call sites in hyprland.lua can simply be deleted.

local M = {}

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Lines of a hyprlang file with comments and blank lines dropped, or nil when
-- the file does not exist.
local function conf_lines(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local lines = {}
    for raw in file:lines() do
        local line = trim(raw:gsub("#.*$", ""))
        if line ~= "" then
            lines[#lines + 1] = line
        end
    end
    file:close()
    return lines
end

-- Options that may follow the scale in a hyprlang monitor line, as key/value
-- pairs, mapped to how hl.monitor() wants them.
local MONITOR_EXTRAS = {
    transform = tonumber,
    bitdepth  = tonumber,
    vrr       = tonumber,
    mirror    = tostring,
    cm        = tostring,
}

-- Applies the "monitor = name, mode, position, scale" lines of a monitors.conf.
-- Used while monitors.lua does not exist, so a display setup written for the
-- old format keeps working untouched.
function M.import_monitors(path)
    for _, line in ipairs(conf_lines(path) or {}) do
        local rest = line:match("^monitor%s*=%s*(.*)$")
        if rest then
            local f = {}
            for field in (rest .. ","):gmatch("([^,]*),") do
                f[#f + 1] = trim(field)
            end

            if f[2] == "disable" then
                hl.monitor({ output = f[1] or "", disabled = true })
            elseif f[2] ~= "addreserved" then
                local spec = {
                    output   = f[1] or "",
                    mode     = (f[2] and f[2] ~= "") and f[2] or "preferred",
                    position = (f[3] and f[3] ~= "") and f[3] or "auto",
                    scale    = tonumber(f[4]) or ((f[4] and f[4] ~= "") and f[4] or "auto"),
                }
                for i = 5, #f - 1, 2 do
                    local convert = MONITOR_EXTRAS[f[i]]
                    if convert then
                        spec[f[i]] = convert(f[i + 1])
                    end
                end
                hl.monitor(spec)
            end
        end
    end
end

-- The installer used to write a fixed nvidia.conf. When that file is still the
-- only one present, apply the same settings it held.
function M.import_nvidia(path)
    if not conf_lines(path) then
        return
    end
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("__GL_VRR_ALLOWED", "1")
    hl.config({ cursor = { no_hardware_cursors = true } })
end

-- Autostarts the installer offered -- idle lock, clipboard persistence -- were
-- appended to env.conf, a tracked file. The update that removes env.conf leaves
-- the user's edited copy behind once, and the update after that deletes it. So
-- on first sight, copy those entries into the git-ignored drop-in the installer
-- uses now. Only the two commands the installer ever wrote are carried over.
--
-- This writes a file from the config, which is unusual; the alternative is a
-- screen that silently stops locking. It must run before conf.d is required,
-- so the drop-in it writes is picked up by the same load.
local INSTALLER_AUTOSTARTS = { "^hypridle$", "^wl%-clip%-persist " }

function M.migrate_autostarts(env_conf, dropin)
    local wanted = {}
    for _, line in ipairs(conf_lines(env_conf) or {}) do
        local cmd = line:match("^exec%-once%s*=%s*(.*)$")
        if cmd then
            for _, pattern in ipairs(INSTALLER_AUTOSTARTS) do
                if cmd:match(pattern) then
                    wanted[#wanted + 1] = cmd
                end
            end
        end
    end
    if #wanted == 0 then
        return
    end

    local existing = ""
    local current = io.open(dropin, "r")
    if current then
        existing = current:read("a") or ""
        current:close()
    end

    local out
    for _, cmd in ipairs(wanted) do
        if not existing:find(cmd, 1, true) then
            out = out or io.open(dropin, "a")
            if not out then
                return
            end
            if existing == "" then
                out:write("-- Optional autostarts added by install.sh. Git-ignored, so updates leave it\n")
                out:write("-- alone; delete a block to stop something starting with your session.\n")
                existing = " "
            end
            out:write(('\nhl.on("hyprland.start", function()\n    hl.exec_cmd(%q)\nend)\n'):format(cmd))
        end
    end
    if out then
        out:close()
    end
end

-- local.conf held arbitrary user config, which cannot be converted for them.
-- Say so once per session rather than letting their binds vanish unexplained.
-- A local.conf that was only ever the commented example stays silent.
function M.warn_unported(path)
    local lines = conf_lines(path)
    if not lines or #lines == 0 then
        return
    end
    hl.on("hyprland.start", function()
        hl.notification.create({
            text    = "SumiNami: local.conf is no longer read. Move your settings to local.lua (see local.lua.example).",
            timeout = 20000,
        })
    end)
end

return M
