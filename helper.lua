--------------------------------------------------------------------------------
-- helper.lua
-- by Shnikety(jbgroff)
-- built for MineTest
-- https://www.minetest.net/
--------------------------------------------------------------------------------

--[[
function minetest.log(level, msg)
	local _G = getfenv(0)
	local log_message = _G.minetest.log
	msg = string.format("[%s] %s", minetest.get_current_modname(), msg)
	log_message(level, msg)
end
--]]

-- turns a string into a Lua table, ie:
-- extract("a b c") --> {[1] = "a", [2] = "b", [3] = "c"}
-- extract("a:45; b:15; c:3", ";", ":") --> {[a] = "45", [b] = "15", [c] = "3"}
extract = function (...)
	local input, separator, assignment
	local getlocal = {...}

	local msg = ""
	local function send_msg()
		minetest.log("warning", msg)
		--print("WARNING: "..msg)
		msg = ""
	end

	for number = 1, #getlocal do
		local value = getlocal[number]
		local t = type(value)

		-- error handleing
		if value and t ~= "string" then
			local msg = string.format(
				"bad argument #%d to 'extract' (string expected, got %s)",
				number, t); error(msg, 2)
		end

		-- escape magic characters
		if value and number ~= 1 then value = value:gsub('([%(%)%.%%%+%-%*%?%[%^%$])', '%%%1') end

		-- check for blank strings
		if value and not value:match('%S+') then value = nil end

		debug.setlocal(1 ,number, value)
	end

	-- return a blank table if no input was given
	if not input then
		msg = "blank table returned: "..debug.traceback("",2); send_msg()
		return {}
	end
	-- default to useing space characters if no other separator is given
	if not separator then separator = "%s" end

	local t = {}
	local i = 1
	if assignment then
		local n = 1
		for line in input:gmatch('([^'..separator..']+)') do
			i = line:match('%s*(.-)'..assignment)
			val = line:match(assignment..'(.*)')
			if line:match(assignment) then
				if t[i] then
					msg = string.format(
						"input error at line #%d in 'extract' (double assignment of index %q)",
						n, i); send_msg()
				end

				t[i] = val
			else
				msg = string.format(
					"input error at line #%d in 'extract' (un-assigned value)",
					n); send_msg()
			end
			n = n + 1
		end
	else
		for val in input:gmatch('([^'..separator..']+)') do
			t[i] = val
			i = i + 1
		end
	end
	return t
end

-- add variables to the local environment
-- This file uses "settingtypes.txt" to build Lua variables for a MineTest mod.
-- see also https://dev.minetest.net/settingtypes.txt
-- w/ thanks to Linuxdirk @ https://forum.minetest.net/viewtopic.php?p=285505#
populate_from_settingtypes = function (pointer, flags)
	if type(pointer) ~= "table" then
		local msg = string.format(
			"bad argument #%d to 'extract' (table expected, got %s)",
			1, type(pointer)); error(msg, 2)
	end
	flags = flags or {}
	local setting = {}
	local modname = minetest.get_current_modname()
	local path = minetest.get_modpath(modname)
	local filepath = path..DIR_DELIM..'settingtypes.txt'
	local file = assert(io.open(filepath, 'rb'))

	if file ~= nil then
		local lines = {}
		for line in file:lines() do
			if line:match('^[a-zA-Z]') then --Hmm, why not '^%a' ?
				--local name, desc, mt_type, default, val1, val2 = unpack(line:split(" "))
				local name = line:match('%S+') --matches any non space characters
				local prefix = name:match('(%S+)%.') --capture any non space characters preceding a dot
				--if flags.keep_prefix then pointer = pointer[prefix] end
				--TODO: Does it mater if modname and prefix are not the same?
				local key = name:gsub(prefix..'%.','') --remove prefix(or prefixes) if any
				--TODO: What happens if there are several prefixes/dots in a name, is this possible???
				local desc = line:match('%((.-)%)') --capture everything in quotes
				local mt_type = line:match('%b() (%S+)') --capture input after quotes
				local default = line:match('%b() %S+ (%S+)') --capture second input after quotes
				if mt_type == "bool" then
					setting[key] = minetest.settings:get_bool(name) or minetest.is_yes(default)
				elseif mt_type == "float" or mt_type == "int" then
					setting[key] = tonumber(minetest.settings:get(name) or default)
				elseif mt_type == "enum" or mt_type == "string" then
					setting[key] = minetest.settings:get(name) or default
				--elseif mt_type == "path" or mt_type == "filepath" then
				--elseif mt_type == "flags" then
				--elseif mt_type == "noise_params_2d" or mt_type = "noise_params_3d" then
				--elseif mt_type == "pos" or mt_type == "v3f" then
				--elseif mt_type == "key" then
				end
			end
		end
	end

	--pointer = pointer or {}
	for key, value in pairs(setting) do
		--print(type(value), key, value)
		pointer[key] = value
	end
end

-- hmm, is this realy necessary? is there something in MT API for this?
minetest.registered_groups = {}
minetest.after(0, function() -- get groups after loading all mods
	local g = minetest.registered_groups
	for name, def in pairs(minetest.registered_items) do
		if name ~= "" then
			for group, val in pairs(def.groups) do
				g[group] = g[group] or {}
				g[group][name] = def
			end
		end
	end
end)
