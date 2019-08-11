local awful = require("awful")
local beautiful = require("beautiful")
local dotcount = require("redflat.gauge.graph.dots")
local dumper = require("dumper")
local redutil = require("redflat.util")
local wibox = require("wibox")

local function apply_style()
	local style = {
		dotcount     = { column_num = { 6, 6 }, row_num = 1 },
		geometry     = { height = 40 },
		set_position = nil,
		screen_gap   = 3,
		border_width = 0,
		color        = { wibox = "#202020", border = "#202020" },
		shape        = nil
	}
	return redutil.table.merge(style, redutil.table.check(beautiful, "widget.minitray") or {})
end

local style = apply_style()


local w = wibox({
	ontop        = true,
	bg           = style.color.wibox,
	border_width = style.border_width,
	border_color = style.color.border,
	shape        = style.shape
})

w:geometry(style.geometry)

-- Set tray
--------------------------------------------------------------------------------
local l = wibox.layout.align.horizontal()
local tray = wibox.widget.systray()
l:set_middle(tray)
w:set_widget(l)

-- update geometry if tray icons change
local function update_geometry()
	local items = awesome.systray()
	if items == 0 then items = 1 end

	w:geometry({ width = style.geometry.width or style.geometry.height * items })

	if style.set_position then
		style.set_position(w)
	else
		awful.placement.bottom_left(w)
	end

	redutil.placement.no_offscreen(w, style.screen_gap, mouse.screen.workarea)
end

tray:connect_signal('widget::redraw_needed', update_geometry)

local function toggle()
	if w.visible then
		w.visible = false
	else
		update_geometry()
		w.visible = true
	end
end

-- return widget
local widget = dotcount(style.dotcount)

function widget:update()
	local appcount = awesome.systray()
	self:set_num(appcount)
end

tray:connect_signal('widget::redraw_needed', function() widget:update() end)

widget:connect_signal("button::press", function(_, lx, ly, button, mode, widget)
	if button == 1 then
		toggle()
	end
end)

return wibox.container.margin(wibox.container.constraint(widget, 'exact', 50, 5), 0, 0, 4, 0)