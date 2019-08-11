local dumper = require("dumper")
local redutil = require("redflat.util")
local watch = require("awful.widget.watch")
local wibox = require("wibox")

local storage = {}

local function net_speed(stdout)
	local up, down = 0, 0
	local now = os.time()

	-- Get network info
	--------------------------------------------------------------------------------
	for line in stdout:gmatch("([^\n]*)\n?") do
		-- Match wmaster0 as well as rt0 (multiple leading spaces)
		local interface = string.match(line, "^[%s]?[%s]?[%s]?[%s]?([%w]+):")

		-- received bytes, first value after the name
		local recv = tonumber(string.match(line, ":[%s]*([%d]+)"))
		-- transmited bytes, 7 fields from end of the line
		local send = tonumber(string.match(line, "([%d]+)%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d$"))

		if not storage[interface] then
			-- default values on the first run
			storage[interface] = { recv = 0, send = 0 }
		else
			-- net stats are absolute, substract our last reading
			local interval = now - storage[interface].time
			if interval <= 0 then interval = 1 end

			down = down + ((recv - storage[interface].recv) / interval)
			up   = up + ((send - storage[interface].send) / interval)
		end

		-- store totals
		storage[interface].time = now
		storage[interface].recv = recv
		storage[interface].send = send
	end

	--------------------------------------------------------------------------------
	return down, up
end

local unit = {{  "B", 1 }, { "KB", 1024 }, { "MB", 1024^2 }, { "GB", 1024^3 }}

local down_textbox = wibox.widget.textbox()
local up_textbox = wibox.widget.textbox()
down_textbox.font = "Noto Sans 8"
up_textbox.font = "Noto Sans 8"

local widget = wibox.widget {
	layout = wibox.layout.fixed.vertical,
	down_textbox,
	up_textbox,
}

watch(
	[[bash -c "cat /proc/net/dev|tail -n +3"]],
	1,
	function(_, stdout)
		local down, up = net_speed(stdout)
	
		down = down / 1024
		if down < 1000 then
			down_textbox.text = string.format("↓%.1fKB", down)
		else
			down_textbox.text = string.format("↓%.2fMB", down / 1024)
		end

		up = up / 1024
		if up < 1000 then
			up_textbox.text = string.format("↑%.1fKB", up)
		else
			up_textbox.text = string.format("↑%.1fKB", up / 1024)
		end
		
	end
)

return wibox.container.margin(widget, 0, 0, 4, 0)