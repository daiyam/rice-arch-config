local awful = require("awful")
local beautiful = require("beautiful")
local dumper = require("dumper")
local layout = require("awful.layout")
local redmenu = require("redflat.menu")
local redutil = require("redflat.util")
local svgbox = require("redflat.gauge.svgbox")
local wibox = require("wibox")

local function apply_style()
	local style = {
		icon       = { unknown = redutil.base.placeholder() },
		micon      = { blank = redutil.base.placeholder({ txt = " " }),
		               check = redutil.base.placeholder({ txt = "+" }) },
		menu       = { color = { right_icon = "#a0a0a0", left_icon = "#a0a0a0" } },
		color      = { icon = "#a0a0a0" }
	}
	return redutil.table.merge(style, redutil.table.check(beautiful, "widget.layoutbox") or {})
end

local style = apply_style()

return function(s)
	local menu = redmenu({ theme = style.menu })

	local widget = svgbox()
	widget:set_color(style.color.icon)
	
	local function update_menu()
		if s.selected_tag ~= nil then
			local selected_layout = layout.get(s)
			local items = {}
			
			for _, l in ipairs(s.selected_tag.layouts) do
				local name = layout.getname(l)
				local icon = l.icon or style.icon.unknown
				local text = l.label or name
				local mark = selected_layout == l and style.micon.check or style.micon.blank
				
				table.insert(items, { text, function() layout.set(l) end, icon, mark })
			end

			menu:replace_items(items)
		end
	end
	
	local function update_icon()
		local l = layout.get(s)
		
		widget:set_image(l.icon or style.icon.unknown)
		
		if menu.wibox.visible then
			update_menu()
		end
	end
	
	tag.connect_signal("property::selected", update_icon)
	tag.connect_signal("property::layout", update_icon)
	
	widget:connect_signal("mouse::leave", function()
		if menu.hidetimer and menu.wibox.visible then
			menu.hidetimer:start()
		end
	end)
	
	widget:connect_signal("button::press", function(_, lx, ly, button, mode, widget)
		if button == 1 then
			update_menu()
			
			menu:show({coords = {x = menu.wibox.x, y = menu.wibox.y}})
		end
	end)
	
	update_icon()
	
	return widget
end