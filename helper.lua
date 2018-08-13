--------------------------------------------------------------------------------
-- helper.lua
-- by Shnikety(jbgroff)
-- with help from Linuxdirk @ https://forum.minetest.net/viewtopic.php?p=285505#

-- This file uses "settingtypes.txt" to build Lua variables for a MineTest mod.
-- All variables defined MUST be of the form "mymod.variable"
-- where mymod is returned as a global table if not already defined as such.

-- see also https://dev.minetest.net/settingtypes.txt
--------------------------------------------------------------------------------


if not minetest then
	minetest = {}
	minetest.is_yes = function (value)
		if value == "true" then return true else return false end
	end
	minetest.settings = {}
	minetest.settings.get_bool = function (_,value)
		return minetest.is_yes
	end
	minetest.get_current_modname = function() return "smart_pickup" end
	minetest.get_modpath = function() return "." end
	DIR_DELIM = "/"
end
--if not minetest.settings

-- add variables to the local environment
populate_from_settingtypes = function (pointer, flags)

	flags = flags or {}
	--local modname = minetest.get_current_modname()
	--pointer.path = pointer.path
	--pointer.defaults = {}
	--pointer.settings = {}
	local path = pointer.path or minetest.get_modpath(modname)
	local filename = path..DIR_DELIM..'settingtypes.txt'
	local file = io.open(filename, 'rb')

	if file ~= nil then
		local lines = {}
		for line in file:lines() do
			if line:match('^[a-zA-Z]') then --Hmm, why not '^%a' ?
				local name = line:match('%S+') --matches any non space characters
				local prefix = name:match('(%S+)%.') --capture any non space characters preceding a dot
				if flags.keep_prefix then pointer = pointer[prefix] end
				--TODO: Does it mater if modname and prefix are not the same?
				local key = name:gsub(prefix..'%.','') --remove prefix(or prefixes) if any
				--TODO: What happens if there are several prefixes/dots in a name, is this possible???
				local desc = line:match('%((.-)%)') --capture everything in quotes
				local mt_type = line:match('%b() (%S+)') --capture input after quotes
				local default = line:match('%b() %S+ (%S+)') --capture second input after quotes
				if mt_type == "bool" then
					pointer[key] = minetest.settings:get_bool(name) or minetest.is_yes(default)
				elseif mt_type == "float" or mt_type == "int" then
					pointer[key] = tonumber(minetest.settings:get(name) or default)
				elseif mt_type == "enum" or mt_type == "string" then
					pointer[key] = minetest.settings:get(name) or default
				--elseif mt_type == "path" or mt_type == "filepath" then
				--elseif mt_type == "flags" then
				--elseif mt_type == "noise_params_2d" or mt_type = "noise_params_3d" then
				--elseif mt_type == "pos" or mt_type == "v3f" then
				--elseif mt_type == "key" then
				end
			end
		end
	end

	for key, value in pairs(pointer) do
		--print(type(value), key, value)
		pointer[key] = value
	end
end
