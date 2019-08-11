local dumper = require("dumper")
local gears = require("gears")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local widget = wibox.widget {
	widget			= wibox.widget.progressbar,
	max_value		= 100,
	value			= 33,
	shape			= gears.shape.rounded_bar,
	ticks_size		= 1,
	forced_width	= 44,
	forced_height	= 4,
	border_width	= 0,
	background_color	= "#404040",
	color				= "#a0a0a0"
}


watch(
	[[bash -c "free -m | grep Mem | awk '{printf(\"%.1f\n\", ($2-$7)/$2 * 100)}'"]],
	1,
	function(widget, stdout)
		local percent = stdout:match("([0-9.]+)")
		
		widget:set_value(0 + percent)
	end,
	widget
)

return wibox.container.margin(widget, 3, 3, 4, 0)