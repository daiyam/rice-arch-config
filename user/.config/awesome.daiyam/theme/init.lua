local awful = require("awful")
local dpi = require("beautiful.xresources").apply_dpi

local theme = {}

theme.path = awful.util.get_configuration_dir() .. "theme"
theme.base = awful.util.get_configuration_dir() .. "theme"

-- Fonts
------------------------------------------------------------
theme.fonts = {
	main     = "Roboto 13",      -- main font
	menu     = "Roboto 13",      -- main menu font
	tooltip  = "Roboto 13",      -- tooltip font
	notify   = "Play bold 14",   -- redflat notify popup font
	clock    = "Play bold 12",   -- textclock widget font
	qlaunch  = "Play bold 14",   -- quick launch key label font
	keychain = "Play bold 16",   -- key sequence tip font
	title    = "Roboto bold 13", -- widget titles font
	tiny     = "Roboto bold 10", -- smallest font for widgets
	titlebar = "Roboto bold 13", -- client titlebar font
	hotkeys  = {
		main  = "Roboto 14",             -- hotkeys helper main font
		key   = "Iosevka Term Light 14", -- hotkeys helper key font (use monospace for align)
		title = "Roboto bold 16",        -- hotkeys helper group title font
	},
	player   = {
		main = "Play bold 13", -- player widget main font
		time = "Play bold 15", -- player widget current time font
	},
}

theme.color = {
	-- main colors
	main      = "#02606D",
	gray      = "#575757",
	bg        = "#161616",
	bg_second = "#181818",
	wibox     = "#202020",
	icon      = "#a0a0a0",
	text      = "#aaaaaa",
	urgent    = "#B25500",
	highlight = "#e0e0e0",
	border    = "#404040",

	-- secondary colors
	shadow1   = "#141414",
	shadow2   = "#313131",
	shadow3   = "#1c1c1c",
	shadow4   = "#767676",

	button    = "#575757",
	pressed   = "#404040",

	desktop_gray = "#404040",
	desktop_icon = "#606060",
}

theme.color.main   = "#064E71"
theme.color.urgent = "#B32601"

theme.font			= "Noto Sans 11"

theme.bg_normal		= "#161616F2"
theme.bg_focus		= "#535d6c"
theme.bg_urgent		= "#ff0000"
theme.bg_minimize	= "#444444"
theme.bg_systray	= theme.bg_normal

theme.fg_normal		= "#aaaaaa"
theme.fg_focus		= "#ffffff"
theme.fg_urgent		= "#ffffff"
theme.fg_minimize	= "#ffffff"

theme.useless_gap	= dpi(0)
theme.border_width	= dpi(3)
theme.border_normal	= "#161616F2"
theme.border_focus	= "#161616F2"
theme.border_marked	= "#161616F2"

theme.wallpaper		= "~/Wallpapers/flowers-20-302.png"

theme.icon = {
	check    = theme.path .. "/common/check.svg",
	blank    = theme.path .. "/common/blank.svg",
	submenu  = theme.path .. "/common/submenu.svg",
	warning  = theme.path .. "/common/warning.svg",
	awesome  = theme.path .. "/common/awesome.svg",
	system   = theme.path .. "/common/system.svg",
	unknown  = theme.path .. "/common/unknown.svg",
}

-- {{{ Menu config
theme.menu = {
	border_width = 4, -- menu border width
	screen_gap   = theme.useless_gap + theme.border_width, -- minimal space from screen edge on placement
	height       = 32,  -- menu item height
	width        = 250, -- menu item width
	icon_margin  = { 4, 7, 7, 8 }, -- space around left icon in menu item
	ricon_margin = { 9, 9, 9, 9 }, -- space around right icon in menu item
	nohide       = false, -- do not hide menu after item activation
	auto_expand  = true,  -- show submenu on item selection (without item activation)
	auto_hotkey  = false, -- automatically set hotkeys for all menu items
	select_first = false,  -- auto select first item when menu shown
	hide_timeout = 1,     -- auto hide timeout (auto hide disables if this set to 0)
	font         = theme.fonts.menu,   -- menu font
	submenu_icon = theme.icon.submenu, -- icon for submenu items
	keytip       = { geometry = { width = 400 } }, -- hotkeys helper settings
	shape        = nil, -- wibox shape
	svg_scale    = { false, false }, -- use vector scaling for left, right icons in menu item
}

theme.menu.color = {
	border       = theme.color.wibox,     -- menu border color
	text         = theme.color.text,      -- menu text color
	highlight    = theme.color.highlight, -- menu text and icons color for selected item
	main         = theme.color.main,      -- menu selection color
	wibox        = theme.color.wibox,     -- menu background color
	submenu_icon = theme.color.icon,      -- submenu icon color
	right_icon   = nil,                  -- right icon color in menu item
	left_icon    = nil,                  -- left icon color in menu item
}
-- }}}

theme.widget = {}

-- {{{ Layoutbox
------------------------------------------------------------
theme.widget.layoutbox = {
	micon = theme.icon,  -- some common menu icons (used: 'blank', 'check')
	color = theme.color  -- colors (main used)
}

-- layout icons
theme.widget.layoutbox.icon = {
	unknown           = theme.icon.unknown,  -- this one used as fallback
}

-- redflat menu style (see theme.menu)
theme.widget.layoutbox.menu = {
	icon_margin  = { 8, 12, 8, 8 },
	width        = 260,
	nohide       = false,
	color        = { right_icon = theme.color.icon, left_icon = theme.color.icon }
}
-- }}}

-- {{{ Tasklist
theme.widget.tasklist = {}
-- }}}

-- {{{ Taskmenu
theme.widget.taskmenu = {
	micon          = theme.icon, -- some common menu icons
	titleline      = {
		font = theme.fonts.title, -- menu title height
		height = 25              -- menu title font
	},
	stateline      = { height = 30 },              -- height of menu item with state icons
	state_iconsize = { width = 18, height = 18 },  -- size for state icons
	layout_icon    = theme.widget.layoutbox.icon,   -- list of layout icons
	separator      = { marginh = { 3, 3, 5, 5 } },	-- redflat separator style
	color          = theme.color,                   -- colors (main used)

	-- main menu style (see theme.menu)
	menu = { width = 250, color = { right_icon = theme.color.icon }, ricon_margin = { 9, 9, 9, 9 } },

	-- tag action submenu style (see theme.menu)
	tagmenu = { width = 160, color = { right_icon = theme.color.icon, left_icon = theme.color.icon },
				icon_margin = { 9, 9, 9, 9 } },
}

-- menu icons
theme.widget.taskmenu.icon = {
	floating  = theme.base .. "/titlebar/floating.svg",
	sticky    = theme.base .. "/titlebar/pin.svg",
	ontop     = theme.base .. "/titlebar/ontop.svg",
	below     = theme.base .. "/titlebar/below.svg",
	close     = theme.base .. "/titlebar/close.svg",
	minimize  = theme.base .. "/titlebar/minimize.svg",
	maximized = theme.base .. "/titlebar/maximized.svg",
	focus	  = theme.base .. "/titlebar/focus.svg",

	unknown   = theme.icon.unknown, -- this one used as fallback
}
-- }}}

theme.tags = {}

theme.tags.icon = {
	unknown   = theme.icon.unknown
}

-- {{{ Tagbox
theme.widget.tagbox = {
	micon = theme.icon,  -- some common menu icons (used: 'blank', 'check')
	color = theme.color  -- colors (main used)
}

-- redflat menu style (see theme.menu)
theme.widget.tagbox.menu = {
	icon_margin  = { 8, 12, 8, 8 },
	width        = 260,
	nohide       = false,
	color        = { right_icon = theme.color.icon, left_icon = theme.color.icon }
}
-- }}}

-- {{{ Exitscreen
theme.widget.exitscreen = {
	bg		= "#000000dd",
	fg		= "#ffffffee",
	button	= {
		bg	= {
			normal	= nil,
			over	= '#55555555'
		}
	},
	icon	= {
		logout		= theme.base .. "/exitscreen/logout.svg",
		poweroff	= theme.base .. "/exitscreen/poweroff.svg",
		reboot		= theme.base .. "/exitscreen/reboot.svg",
		unknown		= theme.icon.unknown
	}
}
-- }}}

theme.gauge = { graph = {} }

theme.gauge.graph.dots = {
	column_num   = { 3, 5 },  -- amount of dot columns (min/max)
	row_num      = 3,         -- amount of dot rows
	dot_size     = 5,         -- dots size
	dot_gap_h    = 4,         -- horizontal gap between dot (with columns number it'll define widget width)
	color        = theme.color -- colors (main used)
}

return theme