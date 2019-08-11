local awful = require("awful")
local lyaml = require("lyaml")

return function()
	local file = io.open(awful.util.get_configuration_dir() .. "conf/autostart.yaml")
	local config = lyaml.load(file:read("*all"))
	file:close()

	for k, program in pairs(config) do
		local cmd, bin
		
		if type(program) == 'string' then
			cmd = program
		else
			cmd = program.cmd
			bin = program.bin
		end
		
		if bin == nil then
			bin = string.match(string.match(cmd, "^%S*"), "[^/]-$")
		end
		
		if bin == nil then
			awful.spawn.with_shell(cmd)
		else
			-- don't launch if already running
			awful.spawn.with_shell(string.format('pgrep -u $USER -x %s > /dev/null || %s', bin, cmd))
		end
	end
end