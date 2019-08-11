local awful = require("awful")
local cairo = require("lgi").cairo
local dpi = require("beautiful").xresources.apply_dpi
local dumper = require("dumper")
local gears = require("gears")
local wibox = require('wibox')

local client_width = 200
local client_padding = 10
local preview_padding = 20
local font = {"Sans", "normal", "normal"}
local font_size = 12
local icon_size = 24

local surface = cairo.ImageSurface(cairo.Format.RGB24, 20, 20)
local cr = cairo.Context(surface)

cr:select_font_face(unpack(font))
cr:set_font_face(cr:get_font_face())
cr:set_font_size(font_size)
local text_height = cr:text_extents("awesome").height
local max_columns = 0
local selected_client = 0

local previewBox = wibox({
	ontop = true,
	visible = false,
	shape = gears.shape.rounded_rect,
	bg = "#dddddd77"
})

local function get_clients()
	local clients = {}

	-- Get focus history for current tag
	local s = mouse.screen;
	local idx = 0
	local c = awful.client.focus.history.get(s, idx)

	while c do
		table.insert(clients, c)

		idx = idx + 1
		c = awful.client.focus.history.get(s, idx)
	end

	-- Minimized clients will not appear in the focus history
	-- Find them by cycling through all clients, and adding them to the list
	-- if not already there.
	-- This will preserve the history AND enable you to focus on minimized clients

	local t = s.selected_tag
	local all = client.get(s)

	for i = 1, #all do
		local c = all[i]
		local ctags = c:tags();

		-- check if the client is on the current tag
		local isCurrentTag = false
		for j = 1, #ctags do
			if t == ctags[j] then
				isCurrentTag = true
				break
			end
		end

		if isCurrentTag then
			-- check if client is already in the history
			-- if not, add it
			local addToTable = true
			for k = 1, #clients do
				if clients[k] == c then
					addToTable = false
					break
				end
			end


			if addToTable then
				table.insert(clients, c)
			end
		end
	end

	return clients
end

local function limit_text(text, width, cr)
	if cr:text_extents(text).width <= width then
		return text
	end
	
	local l = string.len(text) - 1
	local t = string.sub(text, 0, l) .. '...'
	
	while cr:text_extents(t).width > width do
		l = l - 1
		t = string.sub(text, 0, l) .. '...'
	end
	
	return t
end

local function update_preview()
	local clients = get_clients()
	local width = preview_padding + (#clients * client_width) + preview_padding
	
	local r = mouse.screen.workarea.height / mouse.screen.workarea.width
	local image_width = client_width - (2 * client_padding)
	local image_height = math.ceil(image_width * r)
	
	local client_height = client_padding + icon_size + client_padding + image_height + client_padding + text_height + client_padding
	
	local height = preview_padding + client_height + preview_padding
	
	local x = math.floor((mouse.screen.geometry.width - width) / 2)
	local y = math.floor((mouse.screen.geometry.height - height) / 2)
	
	previewBox:geometry({
		x = x,
		y = y,
		width = width,
		height = height
	})
	
	local layout = wibox.layout {
		layout = wibox.layout.manual
	}
	
	for i, client in ipairs(clients) do
		local widget = wibox.widget.base.make_widget()
		
		widget.fit = function(preview_widget, width, height)
			return client_width, client_height
		end
		
		widget.draw = function(preview_widget, preview_wbox, cr, width, height)
			if width ~= 0 and height ~= 0 then
				cr:select_font_face(unpack(font))
				cr:set_font_face(cr:get_font_face())
				cr:set_font_size(font_size)
				
				local sx, sy, tx, ty
				local x, y, text
				
				if selected_client == i then
					gears.shape.rounded_rect(cr, width, height)
					cr:clip()
					
					cr:set_source_rgba(0.87, 0.87, 0.87, 0.2)
					cr:paint()
				end
				
				-- {{{ Draw icon & name
				if client.icon == nil then
					text = limit_text(client.class, image_width, cr)
					tx = (client_width - cr:text_extents(text).width) / 2
					ty = client_padding + ((icon_size - text_height) / 2)

					cr:set_source_rgba(0, 0, 0, 1)
					cr:move_to(tx, ty)
					cr:show_text(text)
					cr:stroke()
				else
					local icon = gears.surface(client.icon)
					text = limit_text(client.class, image_width - icon_size - client_padding, cr)
					tx = (client_width - cr:text_extents(text).width - icon_size - client_padding) / 2
					ty = client_padding + ((icon_size - text_height) / 2)
					
					cr:set_source_rgba(0, 0, 0, 1)
					cr:move_to(tx + icon_size + client_padding, ty + text_height)
					cr:show_text(text)
					cr:stroke()
					
					ty = client_padding
					sx = icon_size / icon.width
					sy = icon_size  / icon.height

					cr:translate(tx, ty)
					cr:scale(sx, sy)
					cr:set_source_surface(icon, 0, 0)
					cr:paint()
					cr:scale(1/sx, 1/sy)
					cr:translate(-tx, -ty)
				end
				
				y = client_padding + icon_size + client_padding
				-- }}}
				
				-- {{{ Draw title
				text = limit_text(client.name, image_width, cr)
				tx = (client_width - cr:text_extents(text).width) / 2
				ty = y + image_height + client_padding + text_height
				
				cr:set_source_rgba(0, 0, 0, 1)
				cr:move_to(tx, ty)
				cr:show_text(text)
				cr:stroke()
				-- }}}
				
				-- {{{ Draw preview
				local cg = client:geometry()
				if cg.width > cg.height then
					sx = image_width / cg.width
					
					tx = client_padding
					ty = y + (image_height - (cg.height * sx)) / 2
				else
					sx = image_height / cg.height
					
					tx = (client_width - (cg.width * sx)) / 2
					ty = y
				end

				local tmp = gears.surface(client.content)
				cr:translate(tx, ty)
				cr:scale(sx, sx)
				cr:set_source_surface(tmp, 0, 0)
				cr:paint()
				tmp:finish()
				-- }}}
			end
		end
		
		widget.point = function(geo, args)
			return {
				x = preview_padding + ((i - 1) * client_width),
				y = preview_padding
			}
		end
		
		layout:add(widget)
	end
	
	previewBox:set_widget(layout)
end

local previewTimer = gears.timer({
	timeout = 1,
	callback = update_preview
})

local function select_next()
	local clients = get_clients()
	
	selected_client = selected_client + 1
	
	if selected_client > #clients then
		selected_client = 1
	end
	
	update_preview()
end

local function select_previous()
	selected_client = selected_client - 1
	
	if selected_client < 1 then
		local clients = get_clients()
		
		selected_client = #clients
	end
	
	update_preview()
end

local function start_tabbing()
	max_columns = math.floor(((mouse.screen.workarea.width - (2 * preview_padding)) / client_width) - 4)
	selected_client = 1
	
	update_preview()
	
	previewBox.visible = true
	
	previewTimer:start()
end

local function stop_tabbing()
	local clients = get_clients()
	
	client.focus = clients[selected_client]
	clients[selected_client]:raise()
	
	previewBox.visible = false
	
	previewTimer:stop()
end

return function(masterKey)
	awful.keygrabber {
		keybindings = {
			{{ masterKey }, "Tab", select_next},
			{{ masterKey, "Shift" }, "Tab", select_previous}
		},
		stop_key = masterKey,
		stop_event = "release",
		start_callback = start_tabbing,
		stop_callback= stop_tabbing,
		export_keybindings = true
	}
end