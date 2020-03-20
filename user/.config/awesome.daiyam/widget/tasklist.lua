local awful = require("awful")
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi
local dumper = require("dumper")
local gears = require("gears")
local layout = require("widget.layout")
local tag = require("awful.tag")
local wibox = require("wibox")

local widget_width = dpi(50)
local widget_height = dpi(39)

local menu = require("widget.taskmenu")()

local function filter_by_current_tag(c, screen)
	if c.screen ~= screen then return false end
	if c.sticky then return true end

	local tags = screen.tags

	for _, t in ipairs(tags) do
		if t.selected then
			local ctags = c:tags()

			for _, v in ipairs(ctags) do
				if v == t then return true end
			end
		end
	end

	return false
end

local function group_task(clients)
	local client_groups = {}
	local classes = {}

	for _, c in ipairs(clients) do
		local class = c.class or "Undefined"
		local index = awful.util.table.hasitem(classes, class)
		if index then
			table.insert(client_groups[index].clients, c)
			
			client_groups[index].start_time = math.min(client_groups[index].start_time, c.start_time)
		else
			table.insert(classes, class)
			table.insert(client_groups, {
				class = class,
				start_time = c.start_time,
				icon = gears.surface(c.icon),
				clients = { c }
			})
		end
	end

	return client_groups
end

local function list_visible_clients(filter, screen)
	local clients = {}

	for _, c in ipairs(client.get()) do
		local hidden = c.skip_taskbar or c.hidden or c.type == "splash" or c.type == "dock" or c.type == "desktop"

		if not hidden and filter(c, screen) then
			table.insert(clients, c)
		end
	end

	return clients
end

local function render_group(group)
	local widget = wibox.widget.base.make_widget()
	
	widget.fit = function(preview_widget, width, height)
		return widget_width, widget_height
	end
	
	widget.draw = function(preview_widget, preview_wbox, cr, width, height)
		if width ~= 0 and height ~= 0 then
			local tx = dpi(8)
			local ty = dpi(0)
			local sx = widget_height / group.icon.width
			local sy = widget_height  / group.icon.height

			cr:translate(tx, ty)
			cr:scale(sx, sy)
			cr:set_source_surface(group.icon, 0, 0)
			cr:paint()
			cr:scale(1/sx, 1/sy)
			cr:translate(-tx, -ty)
			
			if #group.clients > 0 then
				-- beautiful.fg_normal
				cr:set_source_rgba(0.66, 0.66, 0.66, 1)
				cr:arc(dpi(4), widget_height / 2, dpi(2), 0, math.pi*2)
				cr:fill()
			end
		end
	end
	
	widget:connect_signal(
		"button::press",
		function(_, lx, ly, button, mode, widget)
			if button == 1 then
				client.focus = group.clients[1]
				
				group.clients[1]:raise()
			else
				menu.show(group, widget)
			end
		end
	)
	
	return widget
end

local function get_margin_widget()
	local widget = wibox.widget.base.make_widget()
	
	widget:connect_signal(
		"button::press",
		function(_, lx, ly, button, mode, widget)
			if button == 3 then
				awful.widget.winmenu.toggle()
			end
		end
	)
	
	return widget
end

local function render(groups, layout)
	layout:reset()
	
	for _, group in ipairs(groups) do
		layout:add(render_group(group))
	end
end

local function update(tasklist, screen)
	local clients = list_visible_clients(filter_by_current_tag, screen)
	local client_groups = group_task(clients)
	
	table.sort(client_groups, function(a, b) return a.start_time < b.start_time end)
	
	render(client_groups, tasklist)
end

return function(screen)
	local tasklist = layout.center.vertical()
	
	tasklist:set_margin_widget(get_margin_widget())
	
	tasklist.spacing = dpi(5)
	
	-- Create timer to prevent multiply call
	--------------------------------------------------------------------------------
	tasklist.queue = gears.timer({ timeout = 0.1, autostart = true, call_now = true })
	tasklist.queue:connect_signal("timeout", function() update(tasklist, screen); tasklist.queue:stop() end)

	-- Signals setup
	--------------------------------------------------------------------------------
	local client_signals = {
		"property::urgent", "property::sticky", "property::minimized",
		"property::name", "  property::icon",   "property::skip_taskbar",
		"property::screen", "property::hidden",
		"tagged", "untagged", "list", "focus", "unfocus"
	}

	local tag_signals = { "property::selected", "property::activated" }

	for _, signal in ipairs(client_signals) do client.connect_signal(signal, function() tasklist.queue:again() end) end
	for _, signal in ipairs(tag_signals) do tag.attached_connect_signal(screen, signal, function() tasklist.queue:again() end) end
	
	client.connect_signal("manage", function(c) c.start_time = os.clock() end)
	
	return wibox.container.margin(tasklist, 0, 0, 5, 5)
end