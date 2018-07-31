--[[ TODO:
clean up user settings
--]]
local load_time_start = minetest.get_us_time()

-- TODO eliminate this
smart_pickup = {path=minetest.get_modpath("smart_pickup")}
dofile(smart_pickup.path..DIR_DELIM..helper.lua)

-- BUILD USER SET VARIABLES FROM "settingtypes.txt"
populate_from_settingtypes(_ENV)

---------------- the following Built in Values may be changed ------------------
local player_collect_height = 1 --added to player pos y value, not recommended for change
local velocity_gain = 0.1 --a multiplier, not sure if this makes much difference
--------------------------------------------------------------------------------

--TODO wtf local pickup_particle = pickup_particle ~= false
local automode = mode == "Auto" or mode == "Both"
local keymode = mode == "KeyPress" or mode == "Both"
local players = {}
minetest.register_on_joinplayer(function(player)
	if minetest.get_player_privs(player:get_player_name()).interact then
		table.insert(players, player)
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

-- adds the item to the inventory and removes the object
-- borrowed from tacotexmex @ https://github.com/minetest-mods/item_drop
-- and from https://github.com/Aurailus/WCILA
local function collect_item(ent, pos, player)
	local item = ItemStack(ent.itemstring)
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

local function flyt(object)
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

--[[
-- borrowed from tacotexmex @ https://github.com/minetest-mods/item_drop
local function pickup_step()
	local got_item
	--local players = minetest.get_connected_players()
	for i = 1,#players do
		got_item = got_item or pickupfunc(players[i])
	end
	-- lower step if takeable item(s) were found
	local time
	if got_item then
		time = 0.02
	else
		time = 0.2
	end
	minetest.after(time, pickup_step)
end
minetest.after(3.0, pickup_step)
--]]

local timer = 0
local flyt_list = {}
minetest.register_globalstep(function(dtime)
--[[
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
			--[[
			local v, pos2 = {}, object:getpos()
			for _, axis in ipairs{'x','y','z'} do
				v[axis] = pos[axis]-pos2[axis]+cv[axis]*velocity_gain
			end
			--]]

			if ent and not object:is_player() then
				if ent.name == "__builtin:item"
				and ent.dropped_by ~= name
				and ent.itemstring ~= ""then
---[[
					if vector.length(v) <= pickup_radius then
						if automode
						or has_keys_pressed(player)
						and pickup_timer <= 0.02*16 then
							--object:setvelocity({x = 0,y = 0,z = 0})
							minetest.after(pickup_timer, collect_item, ent, pos, player)
							pickup_timer = pickup_timer + 0.02
						end
--]]
					else --if vector.length(v) > pickup_radius then
						if mode == "Auto"
						or keymode and has_keys_pressed(player) then
							--if object is in 'flyt_list' and going fast then ignore it
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
						end
					end
				end
			end
		end
	end
end)

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

---[[
-- borrowed from tacotexmex @ https://github.com/minetest-mods/item_drop
if not minetest.settings:get_bool("creative_mode") then
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

				math.randomseed( os.time() )
				local r = function() return math.random()*math.random()*3.4-1.7 end
				obj:setvelocity({x=r(), y=r()+.7, z=r()})
			end
		end
	end
end
--]]


local time = (minetest.get_us_time() - load_time_start) / 1000000
local msg = "[smart_pickup] loaded after ca. " .. time .. " seconds."
if time > 0.01 then
	print(msg)
else
	minetest.log("info", msg)
end
