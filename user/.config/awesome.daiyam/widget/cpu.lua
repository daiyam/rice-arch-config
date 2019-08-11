local watch = require("awful.widget.watch")
local wibox = require("wibox")

local widget = wibox.widget {
	widget = wibox.widget.graph,
	max_value = 100,
	background_color = "#00000000",
	forced_width = 48,
	step_width = 2,
	step_spacing = 1,
	color = "linear:0,0:0,22:0,#FF0000:0.3,#FFFF00:0.5,#74aeab"
}

local total_prev = 0
local idle_prev = 0

watch(
	[[bash -c "cat /proc/stat | grep '^cpu '"]],
	1,
	function(widget, stdout)
		local user, nice, system, idle, iowait, irq, softirq, steal, guest, guest_nice = stdout:match('(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s')

		local total = user + nice + system + idle + iowait + irq + softirq + steal

		local diff_idle = idle - idle_prev
		local diff_total = total - total_prev
		local diff_usage = (1000 * (diff_total - diff_idle) / diff_total + 5) / 10

		widget:add_value(diff_usage)

		total_prev = total
		idle_prev = idle
	end,
	widget
)

return wibox.container.margin(wibox.container.mirror(widget, { horizontal = true }), 1, 1, 4, 0)