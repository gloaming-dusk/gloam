-- Gloam Settings: the desktop's appearance and input. It is drawn the way the
-- shell is (shady-shell --app) and saves to ~/.config/shady/settings.lua, which
-- Tide reads between its own values and the user's config. Changes apply at
-- once, through the compositor's Lua runtime.

local TIDE = shell.data_dir .. "/../rices/tide"
shell.fonts(TIDE .. "/fonts")

local a = shell.alpha
local home = os.getenv("HOME") or ""
local base = os.getenv("XDG_CONFIG_HOME")
if not base or base == "" then base = home .. "/.config" end
local DIR = base .. "/shady"
local PATH = DIR .. "/settings.lua"

local saved = {}
do
    local ok, value = pcall(dofile, PATH)
    if ok and type(value) == "table" then saved = value end
end

local S = dofile(TIDE .. "/style.lua")({ accent = saved.accent, accent_2 = saved.accent_2 })
local P, font, text = S.P, S.font, S.text

-- Tide's own values, shown for what has not been changed.
local DEFAULTS = {
    accent = "#B4A0FF", accent_2 = "#7CB7FF", wallpaper = "",
    layout_gap = 10, window_corner_radius = 12,
    xkb_layout = "", xkb_options = "", repeat_delay = 300, repeat_rate = 30,
    touchpad_tap = true, touchpad_natural_scroll = true, gesture_fingers = 3,
}
local function get(key)
    if saved[key] ~= nil then return saved[key] end
    return DEFAULTS[key]
end

local function literal(value)
    if type(value) == "string" then return string.format("%q", value) end
    return tostring(value)
end

local function save()
    local keys = {}
    for key in pairs(saved) do keys[#keys + 1] = key end
    table.sort(keys)
    local lines = { "-- Written by Gloam Settings.", "return {" }
    for _, key in ipairs(keys) do
        lines[#lines + 1] = string.format("    %s = %s,", key, literal(saved[key]))
    end
    lines[#lines + 1] = "}\n"
    local temporary = PATH .. ".new"
    local file = io.open(temporary, "w")
    if not file then
        os.execute(string.format("mkdir -p %q", DIR))
        file = io.open(temporary, "w")
    end
    if not file then
        shell.log("settings: cannot write " .. PATH)
        return false
    end
    file:write(table.concat(lines, "\n"))
    file:close()
    return os.rename(temporary, PATH) ~= nil
end

-- Tide's shell draws itself again when this value changes.
local serial = 0
local function tell_the_shell()
    serial = serial + 1
    shell.compositor_lua(string.format('shady.publish("tide.settings", "%d.%d")', os.time(), serial))
end

local function apply(key, value)
    shell.compositor_lua(string.format("shady.set(%q, %s)", key, literal(value)))
end

local function set(key, value)
    saved[key] = value
    save()
    if key == "wallpaper" then tell_the_shell() else apply(key, value) end
    shell.redraw()
end

local function set_accent(accent, accent_2)
    saved.accent, saved.accent_2 = accent, accent_2
    P.accent, P.accent_2 = accent, accent_2
    save()
    apply("window_border_focus_color", accent)
    tell_the_shell()
    shell.redraw()
end

-- ---- text fields -------------------------------------------------------------

local editing -- { key =, text =, validate = }
local problem = {}

local function commit()
    if not editing then return end
    local key, value = editing.key, editing.text
    local complaint = editing.validate and editing.validate(value)
    problem[key] = complaint
    editing = nil
    if not complaint and value ~= get(key) then set(key, value) end
    shell.redraw()
end

local function field(ctx, key, placeholder, validate)
    local active = editing and editing.key == key
    local value = active and editing.text or get(key)
    local id = "field:" .. key
    return shell.row {
        id = id, width = 210, height = 34, radius = 10, padding = { 0, 12 }, gap = 1, align = "center",
        background = a(P.base, 0.7),
        border = problem[key] and a(P.danger, 0.7) or a(active and P.accent or P.text, active and 0.6 or 0.12),
        on_click = function()
            if active then return end
            commit()
            editing = { key = key, text = get(key), validate = validate }
            shell.redraw()
        end,
        value ~= "" and text(value, { font = font("Medium", 9.5), max_width = 184 })
            or (not active and text(placeholder, { font = font("Medium", 9.5), color = a(P.dim, 0.75) }) or false),
        active and shell.box { width = 2, height = 18, radius = 1, background = P.accent, caret = true } or false,
    }
end

-- ---- controls ----------------------------------------------------------------

local function toggle(ctx, key)
    local on = get(key)
    return shell.stack {
        id = "toggle:" .. key, width = 44, height = 24, radius = 12, animate = "snappy",
        background = on and shell.gradient("horizontal", P.accent, P.accent_2) or a(P.text, 0.14),
        on_click = function() set(key, not on) end,
        shell.box { key = "knob", left = on and 22 or 2, top = 2, width = 20, height = 20, radius = 10,
            animate = "snappy", background = on and P.base or P.text },
    }
end

local function choice(ctx, key, options)
    local current = get(key)
    local parts = {}
    for i, option in ipairs(options) do
        local id = "choice:" .. key .. ":" .. i
        local on = current == option[2]
        parts[#parts + 1] = shell.row {
            id = id, height = 28, radius = 8, padding = { 0, 11 }, justify = "center", animate = "snappy",
            background = on and a(P.accent, 0.26) or a(P.text, ctx.hovered == id and 0.08 or 0),
            on_click = function() set(key, option[2]) end,
            text(option[1], { font = font(on and "Bold" or "Medium", 9), color = on and P.text or a(P.text, 0.72) }),
        }
    end
    return shell.row { padding = 2, radius = 10, gap = 1, background = a(P.base, 0.7), parts }
end

local ACCENTS = {
    { "#B4A0FF", "#7CB7FF" }, { "#7CB7FF", "#8BE0E0" }, { "#8BD5A8", "#7CB7FF" },
    { "#F2C27B", "#FF9E64" }, { "#FF7A93", "#B4A0FF" },
}

local function accents(ctx)
    local parts = {}
    for i, pair in ipairs(ACCENTS) do
        local on = get("accent") == pair[1]
        parts[#parts + 1] = shell.row {
            id = "accent:" .. i, width = 30, height = 30, radius = 15, justify = "center", animate = "snappy",
            background = shell.gradient("diagonal", pair[1], pair[2]),
            border = on and P.text or a(P.text, ctx.hovered == "accent:" .. i and 0.4 or 0),
            on_click = function() set_accent(pair[1], pair[2]) end,
        }
    end
    return shell.row { gap = 8, parts }
end

local function setting(label, control, hint, complaint)
    return shell.row {
        align = "center", gap = 16, padding = { 11, 16 },
        shell.column { grow = 1, shrink = 1, align = "start", gap = 2,
            text(label, { font = font("SemiBold", 10) }),
            (complaint or hint) and text(complaint or hint, { font = font("Medium", 8.5),
                color = complaint and P.danger or P.dim, wrap = true, max_lines = 2 }) or false,
        },
        control,
    }
end

local function group(title, rows)
    return shell.column { align = "stretch", gap = 8,
        text(title, { font = font("Bold", 8.5), color = P.dim }),
        shell.column { align = "stretch", radius = 14, background = a(P.surface, 0.9),
            border = a(P.text, 0.07), rows },
    }
end

-- ---- pages -------------------------------------------------------------------

local function valid_wallpaper(path)
    if path == "" then return nil end
    local full = path:gsub("^~/", home .. "/")
    if not shell.stat then
        -- A shady-shell from before its wallpaper manager reads only PNG.
        if not full:lower():match("%.png$") then return "Only PNG pictures can be used" end
        local file = io.open(full, "rb")
        if not file then return "There is no such file" end
        file:close()
        return nil
    end
    local st = shell.stat(full)
    if not st then return "There is no such file or folder" end
    if st.dir then return nil end -- a slideshow
    if not shell.image_size(full) then return "Not a picture this shell can read" end
    return nil
end

local PAGES = {
    { title = "Appearance", icon = "sun", view = function(ctx) return {
        group("Colour", {
            setting("Accent", accents(ctx)),
        }),
        group("Desktop", {
            setting("Wallpaper", field(ctx, "wallpaper", "Night sea", valid_wallpaper),
                shell.stat and "A picture (PNG, JPEG, WebP) or a folder of them" or "A PNG file",
                problem.wallpaper),
        }),
        group("Windows", {
            setting("Corners", choice(ctx, "window_corner_radius",
                { { "Square", 0 }, { "Small", 6 }, { "Medium", 12 }, { "Large", 18 } })),
            setting("Gaps", choice(ctx, "layout_gap",
                { { "None", 0 }, { "Small", 5 }, { "Medium", 10 }, { "Large", 20 } })),
        }),
    } end },
    { title = "Input", icon = "grid", view = function(ctx) return {
        group("Keyboard", {
            setting("Layout", field(ctx, "xkb_layout", "us"), "us, kr, de,fr…"),
            setting("Options", field(ctx, "xkb_options", "None"), "caps:escape…"),
            setting("Repeat after", choice(ctx, "repeat_delay",
                { { "Short", 200 }, { "Medium", 300 }, { "Long", 600 } })),
            setting("Repeat speed", choice(ctx, "repeat_rate",
                { { "Slow", 15 }, { "Medium", 30 }, { "Fast", 50 } })),
        }),
        group("Touchpad", {
            setting("Tap to click", toggle(ctx, "touchpad_tap")),
            setting("Natural scrolling", toggle(ctx, "touchpad_natural_scroll")),
            setting("Swipe fingers", choice(ctx, "gesture_fingers",
                { { "3 fingers", 3 }, { "4 fingers", 4 }, { "Off", 0 } })),
        }),
    } end },
}

local page = 1

local function sidebar(ctx)
    local items = {
        shell.box { height = 6 },
        text("Settings", { font = font("ExtraBold", 13) }),
        shell.box { height = 12 },
    }
    for i, entry in ipairs(PAGES) do
        local id = "page:" .. i
        local on = i == page
        items[#items + 1] = shell.row {
            id = id, height = 36, radius = 10, padding = { 0, 10 }, gap = 10, align = "center", animate = "snappy",
            background = on and a(P.accent, 0.22) or a(P.text, ctx.hovered == id and 0.07 or 0),
            on_click = function() commit(); page = i; shell.redraw() end,
            shell.icon(entry.icon, { size = 14, color = on and P.accent or P.dim }),
            text(entry.title, { font = font(on and "Bold" or "Medium", 10) }),
        }
    end
    return shell.column { width = 176, align = "stretch", gap = 3, padding = 14,
        background = a(P.surface, 0.75), items }
end

shell.window {
    name = "settings",
    title = "Settings",
    app_id = "gloam-settings",
    width = 860,
    height = 620,
    text_input = true,
    view = function(ctx)
        local body = PAGES[page].view(ctx)
        return shell.row {
            width = ctx.width, height = ctx.height, align = "stretch", background = P.base,
            sidebar(ctx),
            shell.column { key = "page:" .. page, grow = 1, shrink = 1, align = "stretch", gap = 18, padding = 22,
                text(PAGES[page].title, { font = font("Bold", 15) }),
                body,
            },
        }
    end,
    on_key = function(key, typed)
        if not editing then return end
        if key == "Return" or key == "KP_Enter" then
            commit()
        elseif key == "Escape" then
            editing = nil
        elseif key == "BackSpace" then
            local cut = utf8.offset(editing.text, -1)
            if cut then editing.text = editing.text:sub(1, cut - 1) end
        elseif typed ~= "" and #editing.text + #typed <= 200 then
            editing.text = editing.text .. typed
        end
        shell.redraw()
    end,
}

shell.after(0, function() shell.open("settings") end)
