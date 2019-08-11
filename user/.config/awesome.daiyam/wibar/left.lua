local awful = require("awful")
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi
local wibox = require("wibox")

return function(s)
	local panel = awful.wibar({ position = "left", screen = s, width = dpi(50) })
	
	panel:setup({
		layout = wibox.layout.align.horizontal,
		{
			layout = wibox.layout.align.vertical,
			forced_width = width,
			{
				widget	= wibox.container.margin,
				left	= 3,
				right	= 3,
				top		= 5,
				{
					layout = wibox.layout.flex.vertical,
					{
						layout	= wibox.layout.flex.horizontal,
						spacing	= 4,
						require("widget.tagbox")(s),
						require("widget.layoutbox")(s),
					}
				}
			},
			require("widget.tasklist")(s),
			{
				layout = wibox.layout.fixed.vertical,
				require("widget.net"),
				require("widget.mem"),
				require("widget.cpu"),
				require("widget.minitray"),
				require("widget.clock"),
			}
		}
	})
	
	return panel
end