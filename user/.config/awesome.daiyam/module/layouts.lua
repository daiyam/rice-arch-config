local awful = require("awful")
local beautiful = require("beautiful")
local dumper = require("dumper")
local lyaml = require("lyaml")

local layouts = {}

awful.layout.resolve_one = function(name)
	return layouts[name]
end

awful.layout.resolve_many = function(names)
	local list = {}
	
	for _, name in ipairs(names) do
		table.insert(list, layouts[name])
	end
	
	return list
end

return function()
	local file = io.open(awful.util.get_configuration_dir() .. "conf/layouts.yaml")
	local data = lyaml.load(file:read("*all"))
	file:close()
	
	awful.layout.layouts = {}
	
	for i, d in pairs(data) do
		local l = loadstring("return function(awful) return " .. d.name .. " end")()(awful)
		
		if l ~= nil then
			layouts[d.name] = l
			
			l.label = d.label
			l.icon = beautiful.base .. "/" .. d.icon
			
			table.insert(awful.layout.layouts, l)
		end
	end
end