--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

--[[
	spos = <pos.x>:<pos.z>
	level = pos.y
	hyperloop.data.tAllElevators[spos].floors[level] = {
		pos = {x,y,z},	-- lower elevator block
		facedir = n,	-- for the door placement
		name = "...",	-- floor name
		up = true,		-- connetion flag
		down = true,	-- connetion flag
		busy = false,   -- travel flag
	}
]]--

-- return index of the table position matching pos or nil
local function pos_index(tbl, pos)
	for idx,v in ipairs(tbl) do
		if v.pos.x == pos.x and v.pos.y == pos.y and v.pos.z == pos.z then
			return idx
		end
	end
	return nil
end

-- remove invalid entries
local function remove_artifacts(floors)
	local tbl = {}
	for idx,floor in ipairs(floors) do
		if floor.pos ~= nil and floor.name ~= nil and floor.up ~= nil and floor.down ~= nil then
			table.insert(tbl, floor)
		end
	end
	return tbl
end


-- determine the elevator list
local function get_elevator_list(pos)
	local spos = tostring(pos.x)..":"..tostring(pos.z)
	if hyperloop.data.tAllElevators[spos] == nil then
		-- create the elevator
		hyperloop.data.tAllElevators[spos] = {}
	end
	if hyperloop.data.tAllElevators[spos].floors == nil then
		-- create the floor list
		hyperloop.data.tAllElevators[spos].floors = {}
	end
	-- remove invalid entries
	hyperloop.data.tAllElevators[spos].floors = remove_artifacts(hyperloop.data.tAllElevators[spos].floors)
	return hyperloop.data.tAllElevators[spos].floors
end

local function remove_elevator_list(pos)
	local spos = tostring(pos.x)..":"..tostring(pos.z)
	hyperloop.data.tAllElevators[spos] = nil
end

-- determine the elevator floor item or create one
local function get_floor_item(pos)
	local floors = get_elevator_list(pos)
	local idx = pos_index(floors, pos)
	if idx == nil then
		-- create the floor item
		table.insert(floors, {pos=pos})
		idx = #floors
	end
	return floors[idx]
end

-- Add the given arguments to the elevator table
local function add_to_elevator_list(pos, tArgs)
	local floor = get_floor_item(pos)
	for k,v in pairs(tArgs) do
		floor[k] = v
	end
end

local function dbg_out(label, pos)
	print(label..":")
	local floors = get_elevator_list(pos)
	for _,floor in ipairs(floors) do
		print("  pos="..floor.pos.x..","..floor.pos.y..","..floor.pos.z..
			  " facedir="..tostring(floor.facedir).." name="..tostring(floor.name)..
			  " up="..dump(floor.up).." down="..dump(floor.down))
	end
end

-- return a sorted list of connected floors
local function floor_list(pos)
	local floors = table.copy(get_elevator_list(pos))
	-- sort the list
	table.sort(floors, function(x,y) 
			return x.pos.y > y.pos.y
		end)
	-- check if elevator is complete
	for idx,floor in ipairs(floors) do
		if idx == 1 then
			if floor.down == false then
				return {}
			end
		elseif idx == #floors then
			if floor.up == false then
				return {}
			end
		elseif floor.up == false or floor.down == false then
			return {}
		end
	end
	return floors
end


-- store floor_pos (lower car block) as meta data
local function set_floor_pos(pos, floor_pos)
	local s = minetest.pos_to_string(floor_pos)
	minetest.get_meta(pos):set_string("floor_pos", s)
	return floor_pos
end

-- read floor_pos (upper car block) from meta data
local function get_floor_pos(pos)
	local s = minetest.get_meta(pos):get_string("floor_pos")
	if s == nil then
		return nil
	end
	return minetest.string_to_pos(s)
end
	
	
-- Form spec for the floor list
local function formspec(pos)
	local tRes = {"size[5,10]label[0.5,0; Wähle dein Ziel :: Select your destination]"}
	tRes[2] = "label[1,0.6;Destination]label[2.5,0.6;Floor]"
	local list = floor_list(pos)
	for idx,floor in ipairs(list) do
		if idx >= 12 then
			break
		end
		local ypos = 0.5 + idx*0.8
		local ypos2 = ypos - 0.2
		tRes[#tRes+1] = "button_exit[1,"..ypos2..";1,1;button;"..#list-idx.."]"
		if floor.pos.y ~= pos.y then
			tRes[#tRes+1] = "label[2.5,"..ypos..";"..floor.name.."]"
		else
			tRes[#tRes+1] = "label[2.5,"..ypos..";(current position)]"
		end
	end
	return table.concat(tRes)
end

local function update_formspec(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", formspec(pos))
end

local function remove_from_elevator_list(pos)
	local floors = get_elevator_list(pos)
	local idx = pos_index(floors, pos)
	if idx ~= nil then
		table.remove(floors, idx)
	end
	-- last car in the list?
	if not next(floors) then
		remove_elevator_list(pos)
	else
		-- update all other elevator cars 
		for _,floor in ipairs(get_elevator_list(pos)) do
			if floor.name ~= "<unknown>" then
				update_formspec(floor.pos)
			end
		end
	end
end

function hyperloop.update_elevator(pos)
	local up = false
	local down = false
	
	pos.y = pos.y - 1
	if string.find(minetest.get_node_or_nil(pos).name, "hyperloop:shaft") then
		down = true
	end
	
	pos.y = pos.y + 3
	if string.find(minetest.get_node_or_nil(pos).name, "hyperloop:shaft") then
		up = true
	end
	
	pos.y = pos.y - 2
	add_to_elevator_list(pos, {up=up, down=down})

	-- update all elevator cars which are already named
	for _,floor in ipairs(get_elevator_list(pos)) do
		if floor.name ~= "<unknown>" then
			update_formspec(floor.pos)
		end
	end
end


-- Open/close/darken the elevator door
-- floor_pos: position of elevator floor
-- cmnd: "close", "open", or "darken"
local function door_command(floor_pos, facedir, cmnd, sound)
	-- one step up
	local door_pos1 = hyperloop.new_pos(floor_pos, facedir, "1B", 0)
	local door_pos2 = hyperloop.new_pos(floor_pos, facedir, "1B", 1)
	local node1 = minetest.get_node(door_pos1)
	local node2 = minetest.get_node(door_pos2)
	
	if sound then
		minetest.sound_play("ele_door", {
				pos = floor_pos,
				gain = 0.8,
				max_hear_distance = 10,
			})
	end
	if cmnd == "open" then
		node1.name = "air"
		minetest.swap_node(door_pos1, node1)
		node2.name = "air"
		minetest.swap_node(door_pos2, node2)
	elseif cmnd == "close" then
		set_floor_pos(door_pos1, floor_pos)
		set_floor_pos(door_pos2, floor_pos)
		node1.name = "hyperloop:elevator_door"
		node1.param2 = facedir
		minetest.swap_node(door_pos1, node1)
		node2.name = "hyperloop:elevator_door_top"
		node2.param2 = facedir
		minetest.swap_node(door_pos2, node2)
	elseif cmnd == "darken" then
		node1.name = "hyperloop:elevator_door_dark"
		node1.param2 = facedir
		minetest.swap_node(door_pos1, node1)
		node2.name = "hyperloop:elevator_door_dark_top"
		node2.param2 = facedir
		minetest.swap_node(door_pos2, node2)
	end
end

local function on_final_close_door(tArrival)
	-- close the door and play sound if no player is around
	if hyperloop.is_player_around(tArrival.pos) then
		-- try again later
		minetest.after(3.0, on_final_close_door, tArrival)
	else
		door_command(tArrival.pos, tArrival.facedir, "close", true)
	end
end

local function on_open_door(tArrival)
	door_command(tArrival.pos, tArrival.facedir, "open", true)
	minetest.after(5.0, on_final_close_door, tArrival)
	tArrival.busy = false
end

local function on_arrival_floor(tDeparture, tArrival, player_name, snd)
	local player = minetest.get_player_by_name(player_name)
	door_command(tDeparture.pos, tDeparture.facedir, "close", false)
	door_command(tArrival.pos, tArrival.facedir, "close", false)
	tDeparture.busy = false
	if player ~= nil then
		local pos = table.copy(tArrival.pos)
		pos.y = pos.y - 0.5
		player:setpos(pos)
	end
	minetest.sound_stop(snd)
	minetest.after(1.0, on_open_door, tArrival)
end

local function on_travel(tDeparture, tArrival, player_name, seconds)
	door_command(tDeparture.pos, tDeparture.facedir, "darken", false)
	door_command(tArrival.pos, tArrival.facedir, "darken", false)
	local snd = minetest.sound_play("ele_norm", {
			pos = tDeparture.pos,
			gain = 0.5,
			max_hear_distance = 3,
			loop = true,
		})
	minetest.after(seconds, on_arrival_floor, tDeparture, tArrival, player_name, snd)
end

minetest.register_node("hyperloop:elevator_bottom", {
	description = "Hyperloop Elevator",
	tiles = {
		"hyperloop_elevator.png",
		"hyperloop_elevator.png",
		"hyperloop_elevator.png",
		"hyperloop_elevator.png",
		"hyperloop_elevator.png",
		"hyperloop_elevator.png",
	},
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16, -8/16, -8/16,  -7/16,  8/16, 8/16},
			{  7/16, -8/16, -8/16,   8/16,  8/16, 8/16},
			{ -7/16, -8/16,  7/16,   7/16,  8/16, 8/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -7/16,   8/16, 24/16, 8/16 },
	},
	inventory_image = "hyperloop_elevator_inventory.png",
	drawtype = "nodebox",
	paramtype = 'light',
	light_source = 4,
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {snappy = 3},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		-- store floor_pos (lower car block) as meta data
		set_floor_pos(pos, pos)
		local facedir = hyperloop.get_facedir(placer)
		add_to_elevator_list(pos, {name="<unknown>", up=false, down=false, facedir=facedir, pos=pos})
		hyperloop.update_elevator(pos)
		-- formspec
		local meta = minetest.get_meta(pos)
		local formspec = "size[6,4]"..
		"label[0,0;Please insert floor name]" ..
		"field[0.5,1.5;5,1;floor;Floor name;Base]" ..
		"button_exit[2,3.6;2,1;exit;Save]"
		meta:set_string("formspec", formspec)
		
		-- swap last shaft node
		pos.y = pos.y - 1
		if minetest.get_node_or_nil(pos).name == "hyperloop:shaft" then
			local node = minetest.get_node(pos)
			node.name = "hyperloop:shaft2"
			minetest.swap_node(pos, node)
		end
		pos.y = pos.y + 1
		
		-- add upper part of the car
		local floor_pos = table.copy(pos)
		pos.y = pos.y + 1
		minetest.add_node(pos, {name="hyperloop:elevator_top", param2=facedir})
		-- store floor_pos (lower car block) as meta data
		set_floor_pos(pos, floor_pos)
		pos.y = pos.y + 1
		if minetest.get_node_or_nil(pos).name == "hyperloop:shaft" then
			local node = minetest.get_node(pos)
			node.name = "hyperloop:shaft2"
			minetest.swap_node(pos, node)
		end
		pos.y = pos.y -2
	end,

	on_receive_fields = function(pos, formname, fields, player)
		-- floor name entered?
		if fields.floor ~= nil then
			local floor = string.trim(fields.floor)
			if floor == "" then
				return
			end
			-- store the floor name in the global elevator list
			local floor_pos = get_floor_pos(pos)
			if floor_pos ~= nil then
				add_to_elevator_list(floor_pos, {name=floor})
				hyperloop.update_elevator(floor_pos)
			end
		-- destination selected?
		elseif fields.button ~= nil then
			local floor = get_floor_item(get_floor_pos(pos))
			if floor then
				local idx = tonumber(fields.button)
				local list = floor_list(floor.pos)
				local dest = list[#list-idx]
				if dest and dest.pos and floor.pos then
					local dist = math.abs(dest.pos.y - floor.pos.y)
					
					if dist ~= 0 and floor.busy ~= true then
						-- due to the missing display, a trip needś 20 sec maximum
						local seconds = math.min(1 + math.floor(dist/30), 20)
						floor.busy = true
						door_command(floor.pos, floor.facedir, "close", true)
						door_command(dest.pos, dest.facedir, "close", true)
						minetest.after(1.0, on_travel, floor, dest, player:get_player_name(), seconds)
					end
				end
			end
		end
	end,

	on_punch = function(pos, node, puncher, pointed_thing)
		local floor_pos = get_floor_pos(pos)
		local floor = get_floor_item(floor_pos)
		if floor.busy ~= true then
			door_command(floor_pos, floor.facedir, "open", true)
		end
	end,

	on_destruct = function(pos)
		pos.y = pos.y - 1
		if minetest.get_node_or_nil(pos).name == "hyperloop:shaft2" then
			local node = minetest.get_node(pos)
			node.name = "hyperloop:shaft"
			minetest.swap_node(pos, node)
		end
		pos.y = pos.y + 2
		minetest.remove_node(pos)
		pos.y = pos.y - 1
		remove_from_elevator_list(pos)
		pos.y = pos.y + 2
		if minetest.get_node_or_nil(pos).name == "hyperloop:shaft2" then
			local node = minetest.get_node(pos)
			node.name = "hyperloop:shaft"
			minetest.swap_node(pos, node)
		end
	end,

})

minetest.register_node("hyperloop:elevator_top", {
	description = "Hyperloop Elevator",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_elevator.png",
		"hyperloop_elevator.png",
		"hyperloop_elevator_top.png",
		"hyperloop_elevator.png",
		"hyperloop_elevator.png",
		"hyperloop_elevator.png",
	},
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16, -8/16, -8/16,  -7/16,  8/16, 8/16},
			{  7/16, -8/16, -8/16,   8/16,  8/16, 8/16},
			{ -7/16, -8/16,  7/16,   7/16,  8/16, 8/16},
		},
	},
	
	drawtype = "nodebox",
	paramtype = 'light',
	light_source = 2,
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {snappy = 3, not_in_creative_inventory=1},
	drop = "hyperloop:elevator_bottom",
})

minetest.register_node("hyperloop:elevator_door_top", {
	description = "Hyperloop Elevator Door",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_elevator_door_top.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16, -8/16,  7/16,   8/16,  8/16, 8/16},
		},
	},
	
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		-- store floor_pos (lower car block) as meta data
		set_floor_pos(pos, pos)
	end,
	
	drop = "",
	paramtype = 'light',
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {snappy = 3, not_in_creative_inventory=1},
})

minetest.register_node("hyperloop:elevator_door", {
	description = "Hyperloop Elevator Door",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_elevator_door.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16, -8/16,  7/16,   8/16,  8/16, 8/16},
		},
	},
	
	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, 7/16,   8/16, 24/16, 8/16 },
	},
	
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local floor_pos = get_floor_pos(pos)
		if floor_pos ~= nil then
			local floor = get_floor_item(floor_pos)
			if floor.busy ~= true then
				door_command(floor.pos, floor.facedir, "open", true)
			end
		end
	end,
	
	drop = "",
	paramtype = 'light',
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {snappy = 3, not_in_creative_inventory=1},
})

minetest.register_node("hyperloop:elevator_door_dark_top", {
	description = "Hyperloop Elevator Door",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_elevator_dark_top.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16, -8/16,  7/16,   8/16,  8/16, 8/16},
		},
	},
	
	drop = "",
	paramtype = 'light',
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {snappy = 3, not_in_creative_inventory=1},
})

minetest.register_node("hyperloop:elevator_door_dark", {
	description = "Hyperloop Elevator Door",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_elevator_dark.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16, -8/16,  7/16,   8/16,  8/16, 8/16},
		},
	},
	
	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, 7/16,   8/16, 24/16, 8/16 },
	},
	
	drop = "",
	paramtype = 'light',
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {snappy = 3, not_in_creative_inventory=1},
})