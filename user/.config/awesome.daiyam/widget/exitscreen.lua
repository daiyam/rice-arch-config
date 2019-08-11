local awful = require("awful")
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi
local dumper = require("dumper")
local gears = require("gears")
local redutil = require("redflat.util")
local svgbox = require("redflat.gauge.svgbox")
local wibox = require("wibox")

local function apply_style()
	local style = {
		bg		= beautiful.bg_normal,
		fg		= beautiful.fg_normal,
		icon	= { unknown = redutil.base.placeholder() },
	}
	return redutil.table.merge(style, redutil.table.check(beautiful, "widget.exitscreen") or {})
end

local style = apply_style()

local grabber = nil
local screens = nil

local icon_size = dpi(192)
local margin = dpi(32)
local padding = dpi(32)

local function build_button(icon, action)
	local button = wibox.widget {
		widget = wibox.container.margin,
		left = margin,
		right = margin,
		wibox.widget {
			widget = wibox.container.background,
			shape = gears.shape.circle,
			forced_width = icon_size,
			forced_height = icon_size,
			wibox.widget {
				widget = wibox.container.margin,
				top = padding,
				bottom = padding,
				left = padding,
				right = padding,
				wibox.widget {
					widget = svgbox,
					image = icon,
					color = style.fg
				}
			}
		}
	}
	
	button:connect_signal("button::press", action)
	
	button:connect_signal("mouse::enter", function()
		button.widget.bg = style.button.bg.over
		
		mouse.current_wibox.cursor = "hand1"
	end)
	
	button:connect_signal("mouse::leave", function()
		button.widget.bg = style.button.bg.normal
		
		mouse.current_wibox.cursor = "left_ptr"
	end)


	return button
end

local function hide_command()
	awful.keygrabber.stop(grabber)
	
	for _, s in ipairs(screens) do
		s.visible = false
	end
	
	screens = nil
end

local function logout_command()
	screens = nil
	
	awesome.quit()
end

local function poweroff_command()
	screens = nil

	awful.keygrabber.stop(grabber)

	awful.spawn.with_shell("poweroff")
end

local function reboot_command()
	screens = nil
	
	awful.keygrabber.stop(grabber)
	
	awful.spawn.with_shell("reboot")
end

local logout_button = build_button(style.icon.logout or style.icon.unknown, logout_command)
local poweroff_button = build_button(style.icon.poweroff or style.icon.unknown, poweroff_command)
local reboot_button = build_button(style.icon.reboot or style.icon.unknown, reboot_command)

local function show(s)
	local screen = wibox({
		screen = s,
		x = s.geometry.x,
		y = s.geometry.y,
		width = s.geometry.width,
		height = s.geometry.height,
		ontop = true,
		bg = style.bg,
		fg = style.fg,
		visible = true
	})
	
	screen:setup({
		layout = wibox.layout.align.vertical,
		expand = "none",
		nil,
		{
			layout = wibox.layout.align.horizontal,
			expand = "none",
			nil,
			{
				layout = wibox.layout.fixed.horizontal,
				logout_button,
				reboot_button,
				poweroff_button
			},
			nil
		},
		nil
	})
	
	return screen
end

local function show_all()
	screens = {}
	
	for s in screen do
		table.insert(screens, show(s))
	end
	
	grabber = awful.keygrabber.run(function(_, key, event)
		if event == "release" then
			return
		end
		
		if key == "l" then
			logout_command()
		elseif key == "p" then
			poweroff_command()
		elseif key == "r" then
			reboot_command()
		elseif key == "Escape" or key == "q" or key == "x" then
			hide_command()
		end
	end)
end

awful.widget.exitscreen = {
	show = show_all
}