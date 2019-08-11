-----------------------------------------------------------------------------------------------------------------------
--                                                  RedFlat menu                                                     --
-----------------------------------------------------------------------------------------------------------------------
-- awful.menu modification
-- Custom widget support added
-- Auto hide option added
-- Right icon support added to default item constructor
-- Icon margin added to default item constructor

-- Horizontal mode support removed
-- Add to index and delete item functions removed
-- menu:clients function removed
-----------------------------------------------------------------------------------------------------------------------
-- Some code was taken from
------ awful.menu v3.5.2
------ (c) 2008, 2011 Damien Leone, Julien Danjou, dodo
-----------------------------------------------------------------------------------------------------------------------


-- Grab environment
-----------------------------------------------------------------------------------------------------------------------
local dumper = require("dumper")

local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local timer = require("gears.timer")

local setmetatable = setmetatable
local string = string
local ipairs = ipairs
local pcall = pcall
local print = print
local table = table
local type = type
local unpack = unpack or table.unpack

local redutil = require("redflat.util")
local svgbox = require("redflat.gauge.svgbox")

-- Initialize tables for module
-----------------------------------------------------------------------------------------------------------------------
local menu = { mt = {}, action = {} }

local _fake_context = { dpi = beautiful.xresources.get_dpi() } -- fix this

-- Generate default theme vars
-----------------------------------------------------------------------------------------------------------------------
local function default_theme()
	local style = {
		border_width = 2,
		screen_gap   = 0,
		submenu_icon = redutil.base.placeholder({ txt = "▶" }),
		height       = 20,
		width        = 200,
		font         = "Sans 12",
		icon_margin  = { 0, 0, 0, 0 }, -- left icon margin
		ricon_margin = { 0, 0, 0, 0 }, -- right icon margin
		nohide       = false,
		auto_expand  = true,
		svg_scale    = { false, false },
		hide_timeout = 0,
		select_first = false,
		color        = { border = "#575757", text = "#aaaaaa", highlight = "#eeeeee",
		                 main = "#b1222b", wibox = "#202020",
		                 submenu_icon = nil, right_icon = nil, left_icon = nil },
		shape        = nil
	}
	return redutil.table.merge(style, beautiful.menu or {})
end


-- Support functions
-----------------------------------------------------------------------------------------------------------------------

-- Get the elder parent of submenu
--------------------------------------------------------------------------------
function menu:get_root()
	return self.parent and menu.get_root(self.parent) or self
end

-- Setup case insensitive underline markup to given character in string
--------------------------------------------------------------------------------
local function make_u(text, key)
	local pos = key and string.find(string.lower(text), key) or nil

	if pos then
		local rkey = string.sub(text, pos, pos)
		return string.gsub(text, rkey, "<u>" .. rkey .. "</u>", 1)
	end

	return text
end

-- Function to set menu or submenu in position
-----------------------------------------------------------------------------------------------------------------------
local function set_coords(_menu, screen_idx, m_coords)
	local s_geometry = redutil.placement.add_gap(screen[screen_idx].workarea, _menu.theme.screen_gap)

	local screen_w = s_geometry.x + s_geometry.width
	local screen_h = s_geometry.y + s_geometry.height

	local x, y
	local b = _menu.wibox.border_width
	local w = _menu.wibox.width + 2 * _menu.wibox.border_width
	local h = _menu.wibox.height + 2 * _menu.wibox.border_width

	if _menu.parent then
		local pw = _menu.parent.wibox.width + 2 * _menu.parent.theme.border_width
		local piy = _menu.parent.wibox.y + _menu.position + _menu.parent.theme.border_width

		y = piy - b
		x = _menu.parent.wibox.x + pw

		if y + h > screen_h then y = screen_h - h end
		if x + w > screen_w then x = _menu.parent.wibox.x - w end
	else
		if m_coords == nil then
			m_coords = mouse.coords()
			m_coords.x = m_coords.x - 1
			m_coords.y = m_coords.y - 1
		end

		y = m_coords.y < s_geometry.y and s_geometry.y or m_coords.y
		x = m_coords.x < s_geometry.x and s_geometry.x or m_coords.x

		if y + h > screen_h then y = screen_h - h end
		if x + w > screen_w then x = screen_w - w end
	end

	_menu.wibox.x = x
	_menu.wibox.y = y
end

-- Menu functions
--------------------------------------------------------------------------------
function menu.action.up(_menu, sel)
	local sel_new = sel - 1 < 1 and #_menu.items or sel - 1
	_menu:item_enter(sel_new)
end

function menu.action.down(_menu, sel)
	local sel_new = sel + 1 > #_menu.items and 1 or sel + 1
	_menu:item_enter(sel_new)
end

function menu.action.enter(_menu, sel)
	if sel > 0 and _menu.items[sel].child then _menu.items[sel].child:show() end
end

function menu.action.exec(_menu, sel)
	if sel > 0 then _menu:exec(sel, { exec = true }) end
end

function menu.action.back(_menu)
	_menu:hide()
end

function menu.action.close(_menu)
	menu.get_root(_menu):hide()
end

-- Execute menu item
-----------------------------------------------------------------------------------------------------------------------
function menu:exec(num)
	local item = self.items[num]

	if not item then return end

	local cmd = item.cmd

	if type(cmd) == "table" then
		item.child:show()
	elseif type(cmd) == "string" then
		if not item.theme.nohide then menu.get_root(self):hide() end
		awful.spawn(cmd)
	elseif type(cmd) == "function" then
		if not item.theme.nohide then menu.get_root(self):hide() end
		cmd()
	end
end

-- Menu item selection functions
-----------------------------------------------------------------------------------------------------------------------

-- Select item
--------------------------------------------------------------------------------
function menu:item_enter(num, opts)
	opts = opts or {}
	local item = self.items[num]

	if item and self.theme.auto_expand and opts.hover and item.child then
		self.items[num].child:show()
	end

	if num == nil or self.sel == num or not item then
		return
	elseif self.sel then
		self:item_leave(self.sel)
	end

	item._background:set_fg(item.theme.color.highlight)
	item._background:set_bg(item.theme.color.main)
	if item.icon and item.theme.color.left_icon then item.icon:set_color(item.theme.color.highlight) end
	if item.right_icon and
	   (item.child and item.theme.color.submenu_icon or not item.child and item.theme.color.right_icon) then
		item.right_icon:set_color(item.theme.color.highlight)
	end
	self.sel = num
end

-- Unselect item
--------------------------------------------------------------------------------
function menu:item_leave(num)
	if not num then return end

	local item = self.items[num]

	if item then
		item._background:set_fg(item.theme.color.text)
		item._background:set_bg(item.theme.color.wibox)
		if item.icon and item.theme.color.left_icon then item.icon:set_color(item.theme.color.left_icon) end
		if item.right_icon then
			if item.child and item.theme.color.submenu_icon then
				-- if there's a child menu, this is a submenu icon
				item.right_icon:set_color(item.theme.color.submenu_icon)
			elseif item.theme.color.right_icon then
				item.right_icon:set_color(item.theme.color.right_icon)
			end
		end
		if item.child then item.child:hide() end
	end
	
	self.sel = nil
end

-- Menu show/hide functions
-----------------------------------------------------------------------------------------------------------------------

-- Show a menu popup.
-- @param args.coords Menu position defaulting to mouse.coords()
--------------------------------------------------------------------------------
function menu:show(args)
	args = args or {}
	local screen_index = mouse.screen
	set_coords(self, screen_index, args.coords)
	if self.wibox.visible then return end

	-- show menu
	self.wibox.visible = true
	-- if self.theme.select_first or self.parent then self:item_enter(1) end

	-- check hidetimer
	if self.hidetimer and self.hidetimer.started then self.hidetimer:stop() end
end

-- Hide a menu popup.
--------------------------------------------------------------------------------
function menu:hide()
	if not self.wibox.visible then return end

	self:item_leave(self.sel)

	if self.sel and self.items[self.sel].child then self.items[self.sel].child:hide() end

	self.sel = nil

	if self.hidetimer and self.hidetimer.started then self.hidetimer:stop() end

	self.wibox.visible = false
end

-- Toggle menu visibility
--------------------------------------------------------------------------------
function menu:toggle(args)
	if self.wibox.visible then
		self:hide()
	else
		self:show(args)
	end
end

-- Clears all items from the menu
--------------------------------------------------------------------------------
function menu:clear()
	self.add_size = 0
	self.layout:reset()
	self.items = {}
	self.wibox.height = 1
end

-- Clears and then refills the menu with the given items
--------------------------------------------------------------------------------
function menu:replace_items(items)
	self:clear()
	for _, item in ipairs(items) do
		self:add(item)
	end
	self.wibox.height = self.add_size > 0 and self.add_size or 1
end

-- Add a new menu entry.
-- args.new (Default: redflat.menu.entry) The menu entry constructor.
-- args.theme (Optional) The menu entry theme.
-- args.* params needed for the menu entry constructor.
-- @param args The item params
-----------------------------------------------------------------------------------------------------------------------
function menu:add(args)
	if not args then return end

	-- If widget instead of text label recieved
	-- just add it to layer, don't try to create menu item
	------------------------------------------------------------
	if type(args[1]) ~= "string" and args.widget then
		local element = {}
		element.width, element.height = args.widget:fit(_fake_context, -1, -1)
		self.add_size = self.add_size + element.height
		self.layout:add(args.widget)

		if args.focus then
			args.widget:connect_signal(
				"mouse::enter",
				function()
					self:item_leave(self.sel)
					self.sel = nil
				end
			)
		end

		return
	end

	-- Set theme for currents item
	------------------------------------------------------------
	local theme = redutil.table.merge(self.theme, args.theme or {})
	args.theme = theme

	-- Generate menu item
	------------------------------------------------------------
	args.new = args.new or menu.entry
	local success, item = pcall(args.new, self, args)

	if not success then
		print("Error while creating menu entry: " .. item)
		return
	end

	if not item.widget then
		print("Error while checking menu entry: no property widget found.")
		return
	end

	item.parent = self
	item.theme = item.theme or theme
	item._background = wibox.container.background(item.widget)
	item._background:set_fg(item.theme.color.text)
	item._background:set_bg(item.theme.color.wibox)

	-- Add item widget to menu layout
	------------------------------------------------------------
	table.insert(self.items, item)
	self.layout:add(item._background)

	-- Create bindings
	------------------------------------------------------------
	local num = #self.items

	item._background:buttons(awful.util.table.join(
		awful.button({}, 3, function () self:hide() end),
		awful.button({}, 1, function ()
			self:item_enter(num)
			self:exec(num)
		end)
	))

	item.widget:connect_signal("mouse::enter", function() self:item_enter(num, { hover = true }) end)
	-- item.widget:connect_signal("mouse::leave", function() self:item_leave(num) end)

	-- Create submenu if needed
	------------------------------------------------------------
	if type(args[2]) == "table" then
		if not self.items[#self.items].child then
			self.items[#self.items].child = menu.new(args[2], self)
			self.items[#self.items].child.position = self.add_size
		end
	end

	------------------------------------------------------------
	self.add_size = self.add_size + item.theme.height

	return item
end

-- Default menu item constructor
-- @param parent The parent menu
-- @param args the item params
-- @return table with all the properties the user wants to change
-----------------------------------------------------------------------------------------------------------------------
function menu.entry(parent, args)
	args = args or {}
	args.text = args[1] or args.text or ""
	args.cmd  = args[2] or args.cmd
	args.icon = args[3] or args.icon
	args.right_icon = args[4] or args.right_icon
	
	-- Create the item label widget
	------------------------------------------------------------
	local label = wibox.widget.textbox()
	label:set_font(args.theme.font)
	
	local key
	local text = awful.util.escape(args.text)
	
	label:set_markup(make_u(text, key))

	-- Set left icon if needed
	------------------------------------------------------------
	local iconbox
	local margin = wibox.container.margin(label)

	if args.icon then
		iconbox = svgbox(args.icon, nil, args.theme.color.left_icon)
		iconbox:set_vector_resize(args.theme.svg_scale[1])
	else
		margin:set_left(args.theme.icon_margin[1])
	end
	
	-- Set right icon if needed
	------------------------------------------------------------
	local right_iconbox

	if type(args.cmd) == "table" then
		right_iconbox = svgbox(args.theme.submenu_icon, nil, args.theme.color.submenu_icon)
		right_iconbox:set_vector_resize(args.theme.svg_scale[2])
	elseif args.right_icon then
		right_iconbox = svgbox(args.right_icon, nil, args.theme.color.right_icon)
		right_iconbox:set_vector_resize(args.theme.svg_scale[2])
	end

	-- Construct item layouts
	------------------------------------------------------------
	local left = wibox.layout.fixed.horizontal()

	if iconbox ~= nil then
		left:add(wibox.container.margin(iconbox, unpack(args.theme.icon_margin)))
	end

	left:add(margin)

	local layout = wibox.layout.align.horizontal()
	layout:set_left(left)

	if right_iconbox ~= nil then
		layout:set_right(wibox.container.margin(right_iconbox, unpack(args.theme.ricon_margin)))
	end

	local layout_const = wibox.container.constraint(layout, "exact", args.theme.width, args.theme.height)

	------------------------------------------------------------
	return {
		label  = label,
		icon   = iconbox,
		widget = layout_const,
		cmd    = args.cmd,
		right_icon = right_iconbox
	}
end

-- Create new menu
-----------------------------------------------------------------------------------------------------------------------
function menu.new(args, parent)

	args = args or {}

	-- Initialize menu object
	------------------------------------------------------------
	local _menu = {
		item_enter    = menu.item_enter,
		item_leave    = menu.item_leave,
		get_root      = menu.get_root,
		toggle        = menu.toggle,
		hide          = menu.hide,
		show          = menu.show,
		exec          = menu.exec,
		add           = menu.add,
		-- insert        = menu.insert,
		-- remove        = menu.remove,
		clear         = menu.clear,
		replace_items = menu.replace_items,
		items         = {},
		parent        = parent,
		layout        = wibox.layout.fixed.vertical(),
		add_size      = 0,
		theme         = redutil.table.merge(parent and parent.theme or default_theme(), args.theme or {})
	}
	
	-- Create items
	------------------------------------------------------------
	for _, v in ipairs(args) do _menu:add(v) end

	if args.items then
		for _, v in ipairs(args.items) do _menu:add(v) end
	end

	-- create wibox
	------------------------------------------------------------
	_menu.wibox = wibox({
		type  = "popup_menu",
		ontop = true,
		fg    = _menu.theme.color.text,
		bg    = _menu.theme.color.wibox,
		border_color = _menu.theme.color.border,
		border_width = _menu.theme.border_width,
		shape = _menu.theme.shape
	})

	_menu.wibox.visible = false
	_menu.wibox:set_widget(_menu.layout)

	-- set size
	_menu.wibox.width = _menu.theme.width
	_menu.wibox.height = _menu.add_size > 0 and _menu.add_size or 1

	-- Set menu autohide timer
	------------------------------------------------------------
	if _menu.theme.hide_timeout > 0 then
		local root = _menu:get_root()

		-- timer only for root menu
		-- all submenus will be hidden automatically
		if root == _menu then
			_menu.hidetimer = timer({ timeout = _menu.theme.hide_timeout })
			_menu.hidetimer:connect_signal("timeout", function() _menu:hide() end)
		end

		-- enter/leave signals for all menu chain
		_menu.wibox:connect_signal("mouse::enter",
			function()
				if root.hidetimer.started then root.hidetimer:stop() end
			end)
		_menu.wibox:connect_signal("mouse::leave", function() root.hidetimer:start() end)
	end

	------------------------------------------------------------
	return _menu
end

-- Config metatable to call menu module as function
-----------------------------------------------------------------------------------------------------------------------
function menu.mt:__call(...)
	return menu.new(...)
end

return setmetatable(menu, menu.mt)
