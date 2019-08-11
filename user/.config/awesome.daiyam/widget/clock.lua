local wibox = require("wibox")
local dpi = require("beautiful").xresources.apply_dpi

local widget = wibox.widget {
	layout  = wibox.layout.align.horizontal,
	expand	= 'none',
	nil,
	wibox.widget.textclock("<span font=\"Roboto Mono bold 8\">%H:%M</span>"),
	nil
}

return wibox.container.margin(widget, 0, 0, dpi(8), dpi(8))