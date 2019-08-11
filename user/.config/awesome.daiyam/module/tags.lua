local awful = require("awful")
local beautiful = require("beautiful")
local dumper = require("dumper")
local lyaml = require("lyaml")
local redutil = require("redflat.util")

return function(screen)
	local file = io.open(awful.util.get_configuration_dir() .. "conf/tags.yaml")
	local tags = lyaml.load(file:read("*all"))
	file:close()
	
	for i, d in pairs(tags) do
		local layouts = d.layouts and awful.layout.resolve_many(d.layouts) or awful.layout.layouts
		
		local layout = d.default_layout and awful.layout.resolve_one(d.default_layout) or layouts[1]
		
		awful.tag.add(
			i,
			{
				name = d.name,
				icon = beautiful.base .. "/" .. d.icon,
				layout = layout,
				layouts = layouts,
				screen = screen,
				selected = i == 1
			}
		)
	end
end