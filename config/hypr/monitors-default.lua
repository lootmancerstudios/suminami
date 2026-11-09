-- Committed monitor fallback, loaded before the per-machine monitors.lua.
-- See https://wiki.hypr.land/configuring/core/monitors/
--
-- Auto-detect everything. Enough for a single display at its native mode, and
-- enough to keep a fresh clone usable before monitors.lua is written.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
