local awful = require("awful")
local beautiful = require("beautiful")
local dumper = require("dumper")
local redmenu = require("redflat.menu")
local redutil = require("redflat.util")
local svgbox = require("redflat.gauge.svgbox")
local wibox = require("wibox")

local function apply_style()
	local style = {
		icon       = { unknown = redutil.base.placeholder() },
		micon      = { blank = redutil.base.placeholder({ txt = " " }),
		               check = redutil.base.placeholder({ txt = "+" }) },
		name_alias = {},
		menu       = { color = { right_icon = "#a0a0a0", left_icon = "#a0a0a0" } },
		color      = { icon = "#a0a0a0" }
	}
	return redutil.table.merge(style, redutil.table.check(beautiful, "widget.tagbox") or {})
end

local style = apply_style()

local function build_menu(screen)
	local items = {}
	
	for _, t in ipairs(root.tags()) do
		local name = t.name
		local icon = t.icon or style.icon.unknown
		local text = style.name_alias[name] or name
		table.insert(items, { text, function() t:view_only() end, icon, style.micon.blank })
	end

	return redmenu({ theme = style.menu, items = items })
end

local function update_menu(menu, selected_tag)
	for i, t in ipairs(root.tags()) do
		local mark = selected_tag == t and style.micon.check or style.micon.blank
		if menu.items[i].right_icon then
			menu.items[i].right_icon:set_image(mark)
		end
	end
end

return function(screen)
	local widget = svgbox()
	widget:set_color(style.color.icon)
	
	local menu = build_menu(screen)
	
	local function update()
		if screen.selected_tag ~= nil then
			widget:set_image(screen.selected_tag.icon or style.icon.unknown)
		end
		
		update_menu(menu, screen.selected_tag)
	end
	
	tag.connect_signal("property::selected", update)
	
	widget:connect_signal("mouse::leave", function()
		if menu.hidetimer and menu.wibox.visible then
			menu.hidetimer:start()
		end
	end)
	
	widget:connect_signal("button::press", function(_, lx, ly, button, mode, widget)
		if button == 1 then
			menu:show({coords = {x = menu.wibox.x, y = menu.wibox.y}})
		end
	end)
	
	update()
	
	return widget
end