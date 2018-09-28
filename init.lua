--[[ To Do List
explore programing refinements in 'helper.lua'
replace 'player_collect_height' with a more sophisticated system
create a mod formspec
!!!need to be able to add groups to the blacklist
add an option to Player Settings that adds a list of default items
!!!research and developement on player data management
perhaps create a formspec for editing settings from within game
organization is becomeing more important
perhaps change over to a modpack
record a history of items that the player has encountered

CURRENT:
adjusting blacklist mechanics and chat commands to function with a bit
	more finesse

BUGS:
possibly something going on in helper.lua
--]]
local load_time_start = minetest.get_us_time()

smart_pickup = {
	path = minetest.get_modpath("smart_pickup"),
	players = {}
}

dofile(smart_pickup.path..DIR_DELIM.."helper.lua")

-- mod storage handleing
-- https://dev.minetest.net/Storing_Data
local mod_storage = minetest.get_mod_storage()
local blacklist = {}
local MOD_DELIM = ", " --this keeps load and save functions cooperating together
local mod_storage_read
local record
do
--error(dump(mod_storage))

	-- write to mod storage
	function record(name)
		local item_list = blacklist[name]
		local item_list_string = ""
		for item, val in pairs(item_list) do
			if val then item_list_string = item..MOD_DELIM..item_list_string end
		end
		mod_storage:set_string(name, item_list_string)
		minetest.log("action", name.." record: "..item_list_string)
	end
	-- read from mod storage
	function mod_storage_read(name)
			local item_list = {}
			local item_list_string = mod_storage:get_string(name)
			--if item_list_string and not item_list_string == "" then
				item_list = extract(item_list_string, MOD_DELIM)
				--error(unpack(item_list))
				for _, item in pairs(item_list) do
					blacklist[name][item] = true
				end
			--[[ a default ignore list
			else
				item_list = {
					["default:leaves"]=true,
					["default:bush_leaves"]=true,
					["default:acacia_bush_leaves"]=true,
					["default:jungleleaves"]=true,
					["default:acacia_leaves"]=true,
					["default:aspen_leaves"]=true,
					["default:pine_needles"]=true,
				}
				record(name)

			end --]]

			return item_list
	end
end

-- BUILD USER SET VARIABLES FROM "settingtypes.txt"
-- FIXME: this currently creates warnings for all the imported variables
populate_from_settingtypes(getfenv(1))
--error(dump(getfenv(1)))

---------------- the following Built in Values may be changed ------------------
local player_collect_height = 1 --added to player pos y value, not recommended for change
local velocity_gain = 0.1 --a multiplier, not sure if this makes much difference
--------------------------------------------------------------------------------
local automode = mode == "Auto" or mode == "Both"
local keymode = mode == "KeyPress" or mode == "Both"
--strip ending: digits, spaces & underscores
function string:strip () return string.gsub(self,'[ _%d]([ _%d])','') end

 -- a unique form of get_connected_players with better filtering
local players = smart_pickup.players
do
	minetest.register_on_joinplayer(function(player)
		local name = player:get_player_name()
		if minetest.get_player_privs(name).interact then
			table.insert(players, player)
			blacklist[name] = {}
			mod_storage_read(name)
		end
	end)
	minetest.register_on_respawnplayer(function(player)
		--if minetest.get_player_privs(player:get_player_name()).interact then
			table.insert(players, player)
		--end
	end)
	minetest.register_on_leaveplayer(function(player)
		if players[player] then
			table.remove(players, player)
		end
	end)
	minetest.register_on_dieplayer(function(player)
		if players[player] then
			table.remove(players, player)
		end
	end)
end
-- this was added with the intention of recording a history of items encountered
smart_pickup.encounter = function (name, itemstring)
	local item_list = blacklist[name]
	itemstring = itemstring:strip()
	if not item_list[itemstring] then
		item_list[itemstring] = false
		-- write to mod storage
		record(name)
	end
end

do -- chat commands etc.
	local command = {}
	-- redefine unpack to handle non-indexed table
	local tmp = unpack
	function unpack(t)
		if type(t) ~= 'table' then
			local msg = string.format(
				"bad argument #%d to 'unpack' (table expected, got %s)",
				1, type(t)); error(msg, 2)
		end
		if #t > 0 then return tmp(t) end

		local s = ""
		for k,v in pairs(t) do
			s = s..tostring(k).."="..tostring(v).."\n"
		end
		return s
	end

	minetest.register_chatcommand("item", {
		privs = {
			interact = true
		},
		params = "<command> <ItemString>",
		description = "from mod smart_pickup",
		func = function(name, params)
			local args = extract(params)
			local case, itemstring = unpack(args)
			if not command[case] then return false, "what!*?" end

			-- handle itemstring input
			-- TODO some of this might be a bit patchy
			if case == "ignore" or case == "pickup" then
				if not itemstring then
					return false, case.." what item?"
				end
				local group = itemstring:match("group:(%S*)")
				if group then
					if minetest.registered_groups[group] then
						local s = ""
						--TODO is this registering aliases?
						--TODO does it matter that items like grass_1, grass_2 are being registered repeatedly
						for i, _ in pairs(minetest.registered_groups[group]) do
							command[case](name, i)
							--s = i..", "..s
						end
						return true, case.." "..itemstring.." successful!"..s
					else
						return false, string.format("%q is not a valid group.", group or "")
					end
				end
				itemstring = minetest.registered_aliases[itemstring] or itemstring
				if not (
				minetest.registered_items[itemstring] or
				minetest.registered_items[itemstring.."_1"]
				) then
					itemstring = "default:"..itemstring
					if not(
					minetest.registered_items[itemstring] or
					minetest.registered_items[itemstring.."_1"]
					) then
						return false, string.format("%q is not a registered item.", itemstring or "")
					end
				end
			end

			return command[case](name, itemstring)
		end
	})

	minetest.register_chatcommand("item ignore", {
		privs = {
			interact = true
		},
		params = "<ItemString>",
		description = "blacklist item so that it will be ignored and not be picked up."
	})
	command.ignore = function(name, itemstring)
		local item_list = blacklist[name]
		itemstring = itemstring:strip()
		if item_list[itemstring] == true then
			return false, string.format("%q is already registered.", itemstring)
		end
		item_list[itemstring] = true
		record(name)
		return true, string.format("%q added to blacklist.", itemstring)
	end

	minetest.register_chatcommand("item pickup", {
		privs = {
			interact = true
		},
		params = "<ItemString>",
		description = "remove item from blacklist so that it will be picked up."
	})
	command.pickup = function(name, itemstring)
		local item_list = blacklist[name]
		if item_list[itemstring] == nil then
			return false, unpack(item_list) or "[empty list]"
		end

		item_list[itemstring] = false
		record(name)
		return true, string.format("%q removed from blacklist.", itemstring)
	end

	minetest.register_chatcommand("item list", {
		privs = {
			interact = true
		},
		description = "list items that are ignored."
	})
	command.list = function(name)
		local item_list = blacklist[name]
		minetest.chat_send_player(name, unpack(item_list))
	end

	minetest.register_chatcommand("item clear", {
		privs = {
			interact = true
		},
		description = "clear list of items to be ignored."
	})
	command.clear = function(name)
		blacklist[name] = {}
		record(name)
		return true, "smart pickup's item  blacklist has been cleared!"
	end
end

--[[ comments and research for futor development & some non-functional codeing
zcg.load_all = function()
	print("Loading all crafts, this may take some time...")
	local i = 0
	for name, item in pairs(minetest.registered_items) do
		if (name and name ~= "") then
			zcg.load_crafts(name)
		end
		i = i+1
	end
	table.sort(zcg.itemlist)
	zcg.need_load_all = false
	print("All crafts loaded !")
end

--https://rubenwardy.com/minetest_modding_book/en/inventories/inventories.html#player-inventories
minetest.create_detached_inventory("inventory_name", callbacks)
Detached inventory callbacks

{
    allow_move = func(inv, from_list, from_index, to_list, to_index, count, player),
--  ^ Called when a player wants to move items inside the inventory
--  ^ Return value: number of items allowed to move

    allow_put = func(inv, listname, index, stack, player),
--  ^ Called when a player wants to put something into the inventory
--  ^ Return value: number of items allowed to put
--  ^ Return value: -1: Allow and don't modify item count in inventory

    allow_take = func(inv, listname, index, stack, player),
--  ^ Called when a player wants to take something out of the inventory
--  ^ Return value: number of items allowed to take
--  ^ Return value: -1: Allow and don't modify item count in inventory

    on_move = func(inv, from_list, from_index, to_list, to_index, count, player),
    on_put = func(inv, listname, index, stack, player),
    on_take = func(inv, listname, index, stack, player),
--  ^ Called after the actual action has happened, according to what was
--  ^ allowed.
--  ^ No return value
}

--https://dev.minetest.net/MetaDataRef
local meta = minetest.get_meta(pos)
meta:set_string("formspec",
        "invsize[8,9;]"..
        "list[context;main;0,0;8,4;]"..
        "list[current_player;main;0,5;8,4;]")
meta:set_string("infotext", "Chest");
local inv = meta:get_inventory()
inv:set_size("main", 8)
print(dump(meta:to_table()))
meta:from_table({
    inventory = {
        main = {
[1] = "default:dirt",
[2] = "",
[3] = "",
[4] = "",
[5] = "",
[6] = "",
[7] = "",
[8] = ""}
    },
    fields = {
        formspec = "invsize[8,9;]list[context;main;0,0;8,4;]list[current_player;main;0,5;8,4;]",
        infotext = "Chest"
    }
})

local items_record -- a history of nodes that have been picked up
local smart_pickup.blacklist = {} -- detached inventory of nodes to be ignored

-- load mod storage
do
	local mod_storage = minetest.get_mod_storage()

	items_record = mod_storage:get_string("items_record") or {}
	smart_pickup.blacklist = mod_storage:get_string("blacklist") or
		minetest.create_detached_inventory(
			"blacklist", {
				allow_put = func(inv, listname, index, stack, player)
					return 1
				end
				--on_put = func(inv, listname, index, stack, player) end
		})
	smart_pickup.blacklist:set_size("main", 8*4)
end

local items_record = minetest.get_mod_storage() or {}

-- create detached inventory for viewing recorded items
local items_record_inv = minetest.create_detached_inventory(
	"item_record", {
		allow_take = func(inv, listname, index, stack, player)
			return -1
		end
})
items_record_inv:set_size("main", 8)

-- Show form when the /formspec command is used.
minetest.register_chatcommand("pickup", {
	func = function(name, param)
		minetest.show_formspec(name, "smart_pickup:main",
				"size[8,6]" ..
				"label[0,0;Hello, " .. name .. "]" ..
				"field[1,1.5;3,1;name;Name;]" ..
				"button_exit[1,2;2,1;exit;Save]")
	end
})

-- Register callback
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "smart_pickup:main" then
        -- Formname is not mymod:form,
        -- exit callback.
        return false
    end

    -- Send message to player.
    minetest.chat_send_player(player:get_player_name(), "You said: " .. fields.name .. "!")

    -- Return true to stop other minetest.register_on_player_receive_fields
    -- from receiving this submission.
    return true
end)
--]]

-- adds the item to the inventory and removes the object
-- borrowed from tacotexmex @ https://github.com/minetest-mods/item_drop
-- and from https://github.com/Aurailus/WCILA
local function collect_item(ent, pos, player)
	local item = ItemStack(ent.itemstring)
-- record encounter into item history
smart_pickup.encounter(player:get_player_name(), ent.itemstring)
minetest.chat_send_player(player:get_player_name(), "picked up "..ent.itemstring)
	local inv = player:get_inventory()
	if not inv:room_for_item("main", item) then
		return
	end
	minetest.sound_play("item_drop_pickup", {
		pos = pos,
		gain = pickup_gain,
	})
	if pickup_particle then
		local item = minetest.registered_nodes[ent.itemstring:gsub("(.*)%s.*$","%1")]
		local image = ""
		if item and minetest.registered_items[item.name] and minetest.registered_items[item.name].tiles then
			if minetest.registered_items[item.name].tiles[1] then
					local dt = minetest.registered_items[item.name].drawtype
					if dt == "normal" or dt == "allfaces" or dt == "allfaces_optional"
					or dt == "glasslike" or dt =="glasslike_framed" or dt == "glasslike_framed_optional"
					or dt == "liquid" or dt == "flowingliquid" then
						local tiles = minetest.registered_items[item.name].tiles

						local top = tiles[1]
						if (type(top) == "table") then top = top.item end
						local left = tiles[3]
						if not left then left = top end
						if (type(left) == "table") then left = left.item end
						local right = tiles[5]
						if not right then right = left end
						if (type(right) == "table") then right = right.item end

						image = minetest.inventorycube(top, left, right)
					else
						image = minetest.registered_items[item.name].inventory_image
						if not image then image = minetest.registered_items[item.name].tiles[1] end
					end
			end
			minetest.add_particle({
				pos = {x = pos.x, y = pos.y + 1.5, z = pos.z},
				velocity = {x = 0, y = 1, z = 0},
				acceleration = {x = 0, y = -4, z = 0},
				expirationtime = 0.2,
				size = 3,--math.random() + 0.5,
				vertical = false,
				texture = image,
			})
		end
	end
	ent:on_punch(player)
end

local flyt_list = {} --a fast way of handling flying objects
local function flyt(object)--called from a minetest.after function in globalstep
	local vel = object:getvelocity()
	local ent = object:get_luaentity()
	if not (object and ent and ent.itemstring) then
		table.remove(flyt_list, i)
		--minetest.chat_send_all("object removed")
	else
		function equalize(n, step, zero)
			return (n<zero-step and n+step) or (n>zero+step and n-step) or zero
		end

		if vel.x == 0 and vel.z == 0 then
			table.remove(flyt_list, i)
		else
			vel.x = equalize(vel.x, vel.x*0.0002, 0)
			vel.y = equalize(vel.y, vel.y*0.00002, -1)
			vel.z = equalize(vel.z, vel.z*0.0002, 0)

			object:setvelocity(vel)
		end
	end
end

local timer = 0
minetest.register_globalstep(function(dtime)
--[[ for educational purposes, an alternate to flyt function
	timer = timer + dtime
	if timer >=1 then
		for i,object in pairs(flyt_list) do
			local vel = object:getvelocity()
			local ent = object:get_luaentity()
			if not (object and ent and ent.itemstring) then
				table.remove(flyt_list, i)
				--minetest.chat_send_all("object removed")
			else
				function equalize(n, step, zero)
					return (n<zero-step and n+step) or (n>zero+step and n-step) or zero
				end

				if vel.x == 0 and vel.z == 0 then
					table.remove(flyt_list, i)
				else
					vel.x = equalize(vel.x, vel.x*0.0002, 0)
					vel.y = equalize(vel.y, vel.y*0.00002, -1)
					vel.z = equalize(vel.z, vel.z*0.0002, 0)

					object:setvelocity(vel)
				end
			end
		end
		timer = 0
	end
--]]
	for i = 1,#players do
		local player = players[i]
		local pos = player:getpos()
		pos.y = pos.y+player_collect_height
		local name = player:get_player_name()
		local pickup_timer = 0 --allows items to be picked up one at a time

		--local items = {}
		local objlist = minetest.get_objects_inside_radius(pos, magnet_radius)
		for i = 1,#objlist do
			local object = objlist[i]
			local ent = object:get_luaentity()
			local cv = object:getvelocity() or {x=0,y=0,z=0}
			local v = vector.add(vector.subtract(pos, object:getpos()), vector.multiply(cv, velocity_gain))
			--[[ does the same as above but in a more elaborate way
			local v, pos2 = {}, object:getpos()
			for _, axis in ipairs{'x','y','z'} do
				v[axis] = pos[axis]-pos2[axis]+cv[axis]*velocity_gain
			end
			--]]

			if ent and not object:is_player() then
				if ent.name == "__builtin:item" and ent.itemstring ~= "" then
				local itemstring = ent.itemstring:strip()
				if not itemstring then error("DEBUG ME:"..ent.itemstring) end
------- this is the insertion point for any items that are to be ignored -------
				if ent.dropped_by ~= name --items dropped by current player
				and not blacklist[name][itemstring] --blacklisted
				then ---[[
					if vector.length(v) <= pickup_radius then
						if automode
						or has_keys_pressed(player)
						and pickup_timer <= 0.02*16 then
							--object:setvelocity({x = 0,y = 0,z = 0})
							minetest.after(pickup_timer, collect_item, ent, pos, player)
							pickup_timer = pickup_timer + 0.02
						end --]]
					else --if vector.length(v) > pickup_radius then
						if mode == "Auto"
						or keymode and has_keys_pressed(player) then
					-- if object is in 'flyt_list' and going fast then ignore it
							local ignore
							if vector.length(cv) > 1 then
								for i,flyt_obj in pairs(flyt_list) do
									if object == flyt_obj then
										ignore = true
										break
									end
								end
							end
							if not ignore then
								object:set_properties({
									physical = true,
								})
								v = vector.multiply(v, 2)
								--v.y = v.y*2
								object:setvelocity(v)
								table.insert(flyt_list, object)
								minetest.after(1/vector.length(v), flyt, object)
							end
						end -- mode selection conditionals
					end -- grabs nearby objects
				end
				end -- conditionals for ignored items
			end -- if ent and not object:is_player()
		end -- objects loop
	end -- players loop
end) -- global step

--Throw items using player's velocity
-- borrowed from https://github.com/jordan4ibanez/drops
function minetest.item_drop(itemstack, dropper, pos)

	--if player then do modified item drop
	if dropper and minetest.get_player_information(dropper:get_player_name()) then
		local v = dropper:get_look_dir()
		local vel = dropper:get_player_velocity()
		local p = {x=pos.x, y=pos.y+player_collect_height, z=pos.z}
		local item = itemstack:to_string()
		local obj = core.add_item(p, item)
		if obj then
			v.x = (v.x*5)+vel.x
			v.y = ((v.y*5)+2)+vel.y
			v.z = (v.z*5)+vel.z
			obj:setvelocity(v)
			obj:get_luaentity().dropped_by = dropper:get_player_name()
			itemstack:clear()
			return itemstack
		end
	--machine
	else
		local v = dropper:get_look_dir()
		local item = itemstack:to_string()
		local obj = minetest.add_item({x=pos.x,y=pos.y+1.5,z=pos.z}, item) --{x=pos.x+v.x,y=pos.y+v.y+1.5,z=pos.z+v.z}
		if obj then
			v.x = (v.x*5)
			v.y = (v.y*5)
			v.z = (v.z*5)
			obj:setvelocity(v)
			obj:get_luaentity().dropped_by = nil
			itemstack:clear()
			return itemstack
		end
	end
end

---[[ borrowed from tacotexmex @ https://github.com/minetest-mods/item_drop
if not minetest.settings:get_bool("creative_mode") then --handle_node_drops
	function minetest.handle_node_drops(pos, drops)
		for i = 1,#drops do
			local item = drops[i]
			local count, name
			if type(item) == "string" then
				count = 1
				name = item
			else
				count = item:get_count()
				name = item:get_name()
			end

			if name == "" then
				-- Sometimes nothing should be dropped
				count = 0
			end

			for _ = 1,count do
				local obj = minetest.add_item(pos, name)
				if not obj then
					error("Couldn't spawn item " .. name .. ", drops: " .. dump(drops))
				end

-- entity controls for the direction and velocity of dropped items
math.randomseed( os.time() )
local r = function() return math.random()*math.random()*3.4-1.7 end
obj:setvelocity({x=r(), y=r()+.7, z=r()})
			end
		end
	end
end --]]


local time = (minetest.get_us_time() - load_time_start) / 1000000
local msg = "[smart_pickup] loaded after ca. " .. time .. " seconds."
if time > 0.01 then print(msg) else minetest.log("info", msg) end
