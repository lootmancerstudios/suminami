-- See https://wiki.hypr.land/configuring/core/rules/

-- Example window rule
-- hl.window_rule({ name = "float-kitty", match = { class = "^(kitty)$", title = "^(kitty)$" }, float = true })

-- Kitty opacity changes
-- hl.window_rule({ name = "kitty-opacity",         match = { class = "^(kitty)$" },              opacity = 0.91 })
-- hl.window_rule({ name = "kitty-opacity-focused", match = { class = "^(kitty)$", focus = true }, opacity = 0.94 })

-- Firefox opacity changes (same as kitty)
-- hl.window_rule({ name = "firefox-opacity",         match = { class = "^(firefox)$" },              opacity = 0.91 })
-- hl.window_rule({ name = "firefox-opacity-focused", match = { class = "^(firefox)$", focus = true }, opacity = 0.94 })

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})
