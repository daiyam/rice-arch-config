local beautiful = require("beautiful")
local redflat = require("redflat")
local awful = require("awful")

local function build(apps)
	local icon_style = { custom_only = false, scalable_only = false }
	local separator = { widget = redflat.gauge.separator.horizontal() }
	
	local function micon(name)
		return redflat.service.dfparser.lookup_icon(name, icon_style)
	end
	
	-- Application submenu
	------------------------------------------------------------
	local appmenu = redflat.service.dfparser.menu({ icons = icon_style, wm_name = "awesome" })

	-- Places submenu
	------------------------------------------------------------
	local placesmenu = {
		{ "Documents",   apps.fm .. " Documents", micon("folder-documents") },
		{ "Downloads",   apps.fm .. " Downloads", micon("folder-download")  },
		{ "Music",       apps.fm .. " Music",     micon("folder-music")     },
		{ "Pictures",    apps.fm .. " Pictures",  micon("folder-pictures")  },
		{ "Videos",      apps.fm .. " Videos",    micon("folder-videos")    },
		separator,
		{ "Media",       apps.fm .. " /mnt/media",   micon("folder-bookmarks") },
		{ "Storage",     apps.fm .. " /mnt/storage", micon("folder-bookmarks") },
	}

	-- Exit submenu
	------------------------------------------------------------
	local exitmenu = {
		{ "Reboot",          "reboot",                    micon("gnome-session-reboot")  },
		{ "Shutdown",        "shutdown now",              micon("system-shutdown")       },
		separator,
		{ "Switch user",     "dm-tool switch-to-greeter", micon("gnome-session-switch")  },
		{ "Suspend",         "systemctl suspend" ,        micon("gnome-session-suspend") },
		{ "Log out",         awesome.quit,                micon("exit")                  },
	}

	-- Main menu
	------------------------------------------------------------
	return redflat.menu({ theme = theme,
		items = {
			{ "Applications",  appmenu,     micon("distributor-logo") },
			{ "Places",        placesmenu,  micon("folder_home"), key = "c" },
			separator,
			{ "Terminal",      apps.terminal, micon("terminal") },
			{ "File Manager",  apps.fm,       micon("folder"), key = "n" },
			separator,
			{ "Exit",          exitmenu,     micon("exit") },
		}
	})
end

return function(apps)
	local mainmenu = build(apps)
	
	root.buttons(awful.util.table.join(
		awful.button({}, 3, function() mainmenu:toggle() end)
	))
	
	awful.widget.winmenu = {
		toggle = function() mainmenu:toggle() end
	}
end