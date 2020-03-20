local awful = require("awful")
local beautiful = require("beautiful")
local dumper = require("dumper")
local gears = require("gears")
local naughty = require("naughty")
local redutil  = require("redflat.util")
local wibox = require("wibox")

require("awful.autofocus")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({ preset = naughty.config.presets.critical,
					 title = "Oops, there were errors during startup!",
					 text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function(error)
		-- Make sure we don't go into an endless error loop
		if in_error then return end
		in_error = true

		naughty.notify({ preset = naughty.config.presets.critical,
						 title = "Oops, an error happened!",
						 text = tostring(error) })
		in_error = false
	end)
end
-- }}}

-- Themes define colours, icons, font and wallpapers.
beautiful.init(awful.util.get_configuration_dir() .. "theme/init.lua")

local apps = {
	fm			= "dolphin",
	terminal	= "kitty"
}

-- Default modkey.
-- local modkey = "Ctrl"
local modkey = "Mod4"

-- {{{ Layouts
require("module.layouts")()
-- }}}

-- {{{ Screens
local function set_wallpaper(s)
	if beautiful.wallpaper then
		local wallpaper = beautiful.wallpaper
		
		-- If wallpaper is a function, call it with the screen
		if type(wallpaper) == "function" then
			wallpaper = wallpaper(s)
		end
		
		gears.wallpaper.maximized(wallpaper, s, true)
	end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- setup
awful.screen.connect_for_each_screen(function(s)
	-- wallpaper
	set_wallpaper(s)
	
	-- Each screen has its own tag table.
	require("module.tags")(s)
	
	require("wibar.left")(s)
end)
-- }}}

-- {{{ Key bindings
local hotkeys = require("module.keys")(modkey, apps)
-- }}}

-- {{{ Rules
require("module.rules")(hotkeys)
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
	-- startup placement
	if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
		-- Prevent clients from being unreachable after screen count changes.
		awful.placement.no_offscreen(c)
	end
	
	-- put new floating windows to the center of screen
	if c.floating and not (c.maximized or c.fullscreen) then
		redutil.placement.centered(c, nil, mouse.screen.workarea)
	end
end)

-- add missing borders to windows that get unmaximized
client.connect_signal("property::maximized", function(c)
	if not c.maximized then
		c.border_width = beautiful.border_width
	end
end)

-- don't allow maximized windows move/resize themselves
client.connect_signal("request::geometry", function(c, context)
	if c.maximized and context ~= "fullscreen" then
		c:geometry({
			x = c.screen.workarea.x,
			y = c.screen.workarea.y,
			height = c.screen.workarea.height - 2 * c.border_width,
			width = c.screen.workarea.width - 2 * c.border_width
		})
	end
end)
-- }}}

-- {{{ Global Widgets
require("widget.alttab")("Mod1")

require("widget.exitscreen")

require("widget.winmenu")(apps)
-- }}}

-- {{{ Autostart
require("module.autostart")()
-- }}}