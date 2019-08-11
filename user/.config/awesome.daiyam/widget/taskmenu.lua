local awful = require("awful")
local beautiful = require("beautiful")
local dumper = require("dumper")
local redmenu = require("redflat.menu")
local redutil = require("redflat.util")
local separator = require("redflat.gauge.separator")
local svgbox = require("redflat.gauge.svgbox")
local wibox = require("wibox")

local function apply_style()
	local style = {
		icon           = { unknown = redutil.base.placeholder() },
		micon          = { blank = redutil.base.placeholder({ txt = " " }),
		                   check = redutil.base.placeholder({ txt = "+" }) },
		layout_icon    = { unknown = redutil.base.placeholder() },
		titleline      = { font = "Sans 16 bold", height = 35 },
		stateline      = { height = 35 },
		state_iconsize = { width = 20, height = 20 },
		separator      = { marginh = { 3, 3, 5, 5 } },
		tagmenu        = { icon_margin = { 2, 2, 2, 2 } },
		hide_action    = { min = true,
		                   move = true,
		                   max = false,
		                   add = false,
		                   floating = false,
		                   sticky = false,
		                   ontop = false,
		                   below = false,
		                   maximized = false },
		color          = { main = "#b1222b", icon = "#a0a0a0", gray = "#404040" },
		menu		   = {
			ricon_margin = { 2, 2, 2, 2 },
			hide_timeout = 1,
			-- color        = { submenu_icon = "#a0a0a0", right_icon = "#a0a0a0", left_icon = "#a0a0a0" },
			nohide       = true
		}
	}
	
	return redutil.table.merge(style, redutil.table.check(beautiful, "widget.taskmenu") or {})
end

local style = apply_style()
local menusep = { widget = separator.horizontal(style.separator) }

local function calculate_coords(menu, widget)
	local coords = {}

	coords.x = widget.x + widget.width + 5
	coords.y = widget.y
	
	return coords
end

-- Function to build item list for submenu
--------------------------------------------------------------------------------
local function tagmenu_items(client, action, style)
	local items = {}
	local client_tags = client:tags()
	
	for _, t in ipairs(client.screen.tags) do
		if not awful.tag.getproperty(t, "hide") then
			check_icon = awful.util.table.hasitem(client_tags, t) and style.micon.check or style.micon.blank
			
			table.insert(
				items,
				{ t.name, function() action(t) end, t.icon or style.micon.blank, check_icon }
			)
		end
	end
	
	return items
end


-- Function to construct menu line with state icons
--------------------------------------------------------------------------------
local function state_line_construct(client, layout, style)
	local stateboxes = {}
	local properties = { "floating", "sticky", "ontop", "below", "maximized" }

	for i, property in ipairs(properties) do
		-- create widget
		stateboxes[i] = svgbox(style.icon[property] or style.icon.unknown)
		stateboxes[i]:set_forced_width(style.state_iconsize.width)
		stateboxes[i]:set_forced_height(style.state_iconsize.height)

		-- set widget in line
		local l = wibox.layout.align.horizontal()
		l:set_expand("outside")
		l:set_second(stateboxes[i])
		layout:add(l)
		
		stateboxes[i]:set_color(client[property] and style.color.main or style.color.gray)
	end

	return stateboxes
end

local function build_client_menu(c, hide)
	local function focus()
		client.focus = c
		
		c:raise()
		
		hide()
	end

	local function quit()
		c:kill()
		hide()
	end
	
	local function movemenu_action(t)
		c:move_to_tag(t)
		awful.layout.arrange(t.screen);
		hide()
	end

	local function addmenu_action(t)
		c:toggle_tag(t)
		awful.layout.arrange(t.screen)
		hide()
	end
	
	local function restore()
		c.minimized = false
		hide()
	end
	
	local function minimize()
		c.minimized = true
		hide()
	end
	
	local movemenu_items = tagmenu_items(c, movemenu_action, style)
	local addmenu_items = tagmenu_items(c, addmenu_action, style)
	
	local minimize_or_restore_item = nil
	if c.minimized then
		minimize_or_restore_item = { "Restore", restore, nil, style.icon.maximized or style.icon.unknown }
	else
		minimize_or_restore_item = { "Minimize", minimize, nil, style.icon.minimize or style.icon.unknown }
	end
	
	-- layouts
	local stateline_horizontal = wibox.layout.flex.horizontal()
	local stateline_vertical = wibox.layout.align.vertical()
	stateline_vertical:set_second(stateline_horizontal)
	stateline_vertical:set_expand("outside")
	local stateline = wibox.container.constraint(stateline_vertical, "exact", nil, style.stateline.height)

	-- set all state icons in line
	local stateboxes = state_line_construct(c, stateline_horizontal, style)
	
	stateboxes[1]:buttons(awful.util.table.join(awful.button({}, 1, function() c.floating = not c.floating; stateboxes[1]:set_color(c.floating and style.color.main or style.color.gray) end)))
	stateboxes[2]:buttons(awful.util.table.join(awful.button({}, 1, function() c.sticky = not c.sticky; stateboxes[2]:set_color(c.sticky and style.color.main or style.color.gray) end)))
	stateboxes[3]:buttons(awful.util.table.join(awful.button({}, 1, function() c.ontop = not c.ontop; stateboxes[3]:set_color(c.ontop and style.color.main or style.color.gray); stateboxes[4]:set_color(c.below and style.color.main or style.color.gray) end)))
	stateboxes[4]:buttons(awful.util.table.join(awful.button({}, 1, function() c.below = not c.below; stateboxes[3]:set_color(c.ontop and style.color.main or style.color.gray); stateboxes[4]:set_color(c.below and style.color.main or style.color.gray) end)))
	stateboxes[5]:buttons(awful.util.table.join(awful.button({}, 1, function() c.maximized = not c.maximized; stateboxes[5]:set_color(c.maximized and style.color.main or style.color.gray) end)))

	local items = {
		{ "Focus",       focus,    nil, style.icon.focus or style.icon.unknown },
		{ "Move to tag", { items = movemenu_items, theme = style.tagmenu } },
		{ "Add to tag",  { items = addmenu_items,  theme = style.tagmenu } },
		minimize_or_restore_item,
		{ "Quit",       quit,    nil, style.icon.close or style.icon.unknown },
		menusep,
		{ widget = stateline, focus = true }
	}
	
	return items
end

local function build_group_menu(group, classline, hide, quit_all)
	local items = {
		{ widget = classline },
		menusep
	}
	
	for index, c in ipairs(group.clients) do
		table.insert(items, { c.name, { items = build_client_menu(c, hide), theme = style.tagmenu } })
	end
	
	table.insert(items, menusep)
	table.insert(items, { "Quit All", quit_all, nil, style.icon.close or style.icon.unknown })
	
	return items
end

return function()
	local group = nil
	local menu = nil
	
	local function hide()
		menu:hide()
		
		group = nil
	end
	
	local function quit_all()
		for _, client in ipairs(group.clients) do
			client:kill()
		end
		
		hide()
	end
	
	--[[ local menusep = { widget = separator.horizontal(style.separator) } ]]
	
	local classbox = wibox.widget.textbox()
	classbox:set_font(style.titleline.font)
	classbox:set_align ("center")

	local classline = wibox.container.constraint(classbox, "exact", nil, style.titleline.height)
	
	--[[ menu = redmenu({
		theme = style.menu,
		items = {
			{ widget = classline },
			menusep,
			menusep,
			{ "Quit All", quit_all, nil, style.icon.close or style.icon.unknown },
		}
	}) ]]
	
	local function show(_group, widget)
		group = _group
		
		classbox:set_text(group.class)
		
		--[[ while #menu.layout.children > 4 do
			menu:remove(3)
		end
		
		for index, client in ipairs(group.clients) do
			menu:insert(index + 2, { client.name, nil, nil, nil })
		end
		
		menu.wibox.height = menu.add_size > 0 and menu.add_size or 1 ]]
		
		if #group.clients > 1 then
			table.sort(group.clients, function(a, b) return a.start_time < b.start_time end)
		end
		
		
		menu = redmenu({
			theme = style.menu,
			items = build_group_menu(group, classline, hide, quit_all)
		})
		
		menu:show({ coords = calculate_coords(menu, widget) })
	end
	
	return {
		hide = hide,
		show = show
	}
end