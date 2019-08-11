local awful = require("awful")
local beautiful = require("beautiful")

local base_properties = {
	border_width     = beautiful.border_width,
	border_color     = beautiful.border_normal,
	focus            = awful.client.focus.filter,
	raise            = true,
	size_hints_honor = false,
	screen           = awful.screen.preferred,
}

local floating_any = {
	role = { "AlarmWindow", "pop-up" },
	type = { "dialog" }
}

local titlebar_exeptions = {
	class = { "Steam", "Qemu-system-x86_64" }
}

return function(hotkeys)
	base_properties.keys = hotkeys.client
	base_properties.buttons = awful.util.table.join(
		awful.button({}, 1, function (c) client.focus = c; c:raise() end)
	)

	local rules = {
		{
			rule       = {},
			properties = base_properties
		},
		{
			rule_any   = floating_any,
			properties = { floating = true, border_width = 0 }
		},
		{
			rule_any	= { name = { "Ulauncher Preferences", "Ulauncher window title" } },
			properties	= { floating = true, border_width = 0 }
		},
		{
			rule_any   = { type = { "normal", "dialog" }},
			except_any = titlebar_exeptions,
			properties = { titlebars_enabled = true }
		},
		{
			rule_any   = { type = { "normal" }},
			properties = { placement = awful.placement.no_overlap + awful.placement.no_offscreen }
		}
	}

	awful.rules.rules = rules
end