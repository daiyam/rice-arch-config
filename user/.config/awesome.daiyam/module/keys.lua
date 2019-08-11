local awful = require("awful")
local dumper = require("dumper")
local lyaml = require("lyaml")
local redflat = require("redflat")
local stringy = require("stringy")

-- alt = Mod1
-- ctrl = Ctrl
-- meta = Mod4
local function key_mod(data, masterKey)
	local modifiers = {}
	
	for _, key in pairs(stringy.split(data.key, "+")) do
		if key == "master" then
			table.insert(modifiers, masterKey)
		elseif key == "alt" then
			table.insert(modifiers, "Mod1")
		elseif key == "ctrl" then
			table.insert(modifiers, "Control")
		end
	end
	
	return modifiers
end

local function key_key(data)
	for _, key in pairs(stringy.split(data.key, "+")) do
		if not(key == "alt" or key == "ctrl" or key == "master") then
			return key
		end
	end
end

local function key_action_global(data, apps)
	if data.action ~= nil then
		local f = loadstring("return function(awesome, awful, apps) return function() " .. data.action .. " end end")
		
		return f()(awesome, awful, apps)
	elseif data.cmd ~= nil then
		local f = loadstring("return function(awful) return function() awful.spawn.with_shell(\"" .. data.cmd  .. "\") end end")
		
		return f()(awful)
	else
		return nil
	end
end

local function key_action_client(data, apps)
	local f = loadstring("return function(awesome, awful, apps) return function(client) " .. data.action .. " end end")
	
	return f()(awesome, awful, apps)
end

local function key_data(data, group)
	return {
		description = data.description,
		group = group
	}
end

local function load(masterKey, apps)
	local file = io.open(awful.util.get_configuration_dir() .. "conf/keys.yaml")
	local data = lyaml.load(file:read("*all"))
	file:close()
	
	local config = {
		global = {},
		client = {}
	}
	
	for _, group in pairs(data.global) do
		for _, data in pairs(group.shortcuts) do
			table.insert(config.global, {
				key_mod(data, masterKey),
				key_key(data),
				key_action_global(data, apps),
				key_data(data, group)
			})
		end
	end
	
	for _, group in pairs(data.client) do
		for _, data in pairs(group.shortcuts) do
			table.insert(config.client, {
				key_mod(data, masterKey),
				key_key(data),
				key_action_client(data, apps),
				key_data(data, group)
			})
		end
	end
	
	return config
end

return function(masterKey, apps)
	local config = load(masterKey, apps)
	
	local keys = {
		global = redflat.util.key.build(config.global),
		client = redflat.util.key.build(config.client)
	}
	
	root.keys(keys.global)
	
	return keys
end