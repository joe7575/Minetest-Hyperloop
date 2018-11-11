--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017-2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

-- for lazy programmers
local S = minetest.pos_to_string
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("hyperloop")
local I, NS = dofile(MP.."/intllib.lua")

-- To store elevator floors and formspecs
local Cache = {}

local kPLAYER_OVER_GROUND = 0.5

-------------------------------------------------------------------------------
-- Elevator Shaft
-------------------------------------------------------------------------------

local Shaft = tubelib2.Tube:new({
	--dirs_to_check = {5,6},  -- vertical only
	dirs_to_check = {1,2,3,4,5,6},
	max_tube_length = 1000, 
	show_infotext = true,
	primary_node_names = {"hyperloop:shaft", "hyperloop:shaft2", "hyperloop:shaftA", "hyperloop:shaftA2"}, 
	secondary_node_names = {"hyperloop:elevator_bottom", "hyperloop:elevator_top"},
	after_place_tube = function(pos, param2, tube_type, num_tubes)
		if tube_type == "S" then
			if num_tubes == 2 then
				minetest.set_node(pos, {name = "hyperloop:shaft2", param2 = param2})
			else
				minetest.set_node(pos, {name = "hyperloop:shaft", param2 = param2})
			end
		else
			if num_tubes == 2 then
				minetest.set_node(pos, {name = "hyperloop:shaftA2", param2 = param2})
			else
				minetest.set_node(pos, {name = "hyperloop:shaftA", param2 = param2})
			end
		end
	end,
})

hyperloop.Shaft = Shaft

minetest.register_node("hyperloop:shaft", {
	description = I("Hyperloop Elevator Shaft"),
	inventory_image = 'hyperloop_shaft_inv.png',
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png",
		"hyperloop_tube_locked.png",
		'hyperloop_tube_open.png',
		'hyperloop_tube_open.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-8/16, -8/16, -8/16, -7/16,  8/16,  8/16},
			{ 7/16, -8/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16,  7/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16, -8/16, -8/16,  8/16, -7/16,  8/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -8/16,  8/16, 8/16, 8/16},
	},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if not Shaft:after_place_tube(pos, placer, pointed_thing) then
			minetest.remove_node(pos)
			return true
		end
		return false
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Shaft:after_dig_tube(pos, oldnode, oldmetadata)
	end,
	
	climbable = true,
	paramtype2 = "facedir", -- important!
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	light_source = 2,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 1},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("hyperloop:shaftA", {
	description = I("Hyperloop Elevator Shaft"),
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_locked.png^[transformR90]",
		'hyperloop_tube_open.png',
		"hyperloop_tube_locked.png",
		"hyperloop_tube_locked.png",
		"hyperloop_tube_locked.png",
		'hyperloop_tube_open.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-8/16, -8/16, -8/16, -7/16,  8/16,  8/16},
			{ 7/16, -8/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16,  7/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16, -8/16,  7/16,  8/16,  8/16,  8/16},
			{-8/16, -8/16, -8/16,  8/16, -7/16, -7/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -8/16,  8/16, 8/16, 8/16},
	},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if not Shaft:after_place_tube(pos, placer, pointed_thing) then
			minetest.remove_node(pos)
			return true
		end
		return false
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Shaft:after_dig_tube(pos, oldnode, oldmetadata)
	end,
	
	climbable = true,
	paramtype2 = "facedir", -- important!
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	light_source = 2,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 1, not_in_creative_inventory=1},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("hyperloop:shaft2", {
	description = I("Hyperloop Elevator Shaft"),
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png",
		"hyperloop_tube_locked.png",
		'hyperloop_tube_open.png',
		'hyperloop_tube_open.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-8/16, -8/16, -8/16, -7/16,  8/16,  8/16},
			{ 7/16, -8/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16,  7/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16, -8/16, -8/16,  8/16, -7/16,  8/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -8/16,  8/16, 8/16, 8/16},
	},

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Shaft:after_dig_tube(pos, oldnode, oldmetadata)
	end,
	
	climbable = true,
	paramtype2 = "facedir", -- important!
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	light_source = 2,
	sunlight_propagates = true,
	is_ground_content = false,
	diggable = false,
	groups = {cracky = 1, not_in_creative_inventory=1},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("hyperloop:shaftA2", {
	description = I("Hyperloop Elevator Shaft"),
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_locked.png^[transformR90]",
		'hyperloop_tube_open.png',
		"hyperloop_tube_locked.png",
		"hyperloop_tube_locked.png",
		"hyperloop_tube_locked.png",
		'hyperloop_tube_open.png',
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-8/16, -8/16, -8/16, -7/16,  8/16,  8/16},
			{ 7/16, -8/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16,  7/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16, -8/16,  7/16,  8/16,  8/16,  8/16},
			{-8/16, -8/16, -8/16,  8/16, -7/16, -7/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -8/16,  8/16, 8/16, 8/16},
	},

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Shaft:after_dig_tube(pos, oldnode, oldmetadata)
	end,
	
	climbable = true,
	paramtype2 = "facedir", -- important!
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	light_source = 2,
	sunlight_propagates = true,
	is_ground_content = false,
	diggable = false,
	groups = {cracky = 1, not_in_creative_inventory=1},
	sounds = default.node_sound_metal_defaults(),
})

-------------------------------------------------------------------------------
-- Elevator Car
-------------------------------------------------------------------------------

-- Form spec for the floor list
local function formspec(pos, lFloors)
	local tRes = {"size[5,10]label[0.5,0; "..I("Select your destination").."]"}
	tRes[2] = "label[1,0.6;"..I("Destination").."]label[2.5,0.6;"..I("Floor").."]"
	for idx,floor in ipairs(lFloors) do
		if idx >= 12 then
			break
		end
		local ypos = 0.5 + idx*0.8
		local ypos2 = ypos - 0.2
		tRes[#tRes+1] = "button_exit[1,"..ypos2..";1,1;button;"..(#lFloors-idx).."]"
		if vector.equals(floor.pos, pos) then
			tRes[#tRes+1] = "label[2.5,"..ypos..";"..I("(current position)").."]"
		else
			tRes[#tRes+1] = "label[2.5,"..ypos..";"..(floor.name or "<unknown>").."]"
		end
	end
	return table.concat(tRes)
end

local function update_formspec(pos)
	local sKey = S(pos)
	if not Cache[sKey] or hyperloop.tDatabase.elevator_chng_cnt ~= Cache[sKey].change_counter then
		local tFloors = hyperloop.get_elevator_table(pos)
		local lFloors = hyperloop.sort_based_on_level(tFloors)
		Cache[sKey] = {}
		Cache[sKey].lFloors = lFloors
		Cache[sKey].formspec = formspec(pos, lFloors)
		Cache[sKey].change_counter = hyperloop.tDatabase.elevator_chng_cnt
	end
	M(pos):set_string("formspec", Cache[sKey].formspec)
end

local function update_elevator(pos, out_dir, peer_pos, peer_in_dir)
	if out_dir == 6 then  -- to the top?
		-- switch to elevator_bottom node
		pos = Shaft:get_pos(pos, 5)
	else
		local _,node = Shaft:get_node(peer_pos)
		if node.name == "hyperloop:elevator_top" then
			peer_pos = Shaft:get_pos(peer_pos, 5)
		end
	end
	print("update_elevatorB", S(pos), out_dir, S(peer_pos), peer_in_dir)
	hyperloop.update_elevator_conn_table(pos, out_dir, peer_pos)
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
		M(door_pos1):set_string("floor_pos", S(floor_pos))
		M(door_pos2):set_string("floor_pos", S(floor_pos))
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
		tArrival.pos.y = tArrival.pos.y - kPLAYER_OVER_GROUND
		player:set_pos(tArrival.pos)
		tArrival.pos.y = tArrival.pos.y + kPLAYER_OVER_GROUND
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
	description = I("Hyperloop Elevator"),
	tiles = {
		"hyperloop_elevator_bottom.png",
		"hyperloop_elevator_bottom.png",
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
			{ -8/16, -8/16, -8/16,   8/16, -7/16, 8/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16,   8/16, 23/16, 8/16 },
	},
	inventory_image = "hyperloop_elevator_inventory.png",
	drawtype = "nodebox",
	paramtype = 'light',
	light_source = 6,
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {snappy = 3},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local facedir = hyperloop.get_facedir(placer)
		hyperloop.update_elevator(pos, "<unknown>", {facedir=facedir, busy=false})
		
		Shaft:after_place_node(pos, {5})
		
		-- formspec
		local meta = minetest.get_meta(pos)
		local formspec = "size[6,4]"..
		"label[0,0;"..I("Please insert floor name").."]" ..
		"field[0.5,1.5;5,1;floor;"..I("Floor name")..";"..I("Base").."]" ..
		"button_exit[2,3.6;2,1;exit;"..I("Save").."]"
		meta:set_string("formspec", formspec)
		
		-- add upper part of the car
		pos = Shaft:get_pos(pos, 6)
		minetest.add_node(pos, {name="hyperloop:elevator_top", param2=facedir})
		Shaft:after_place_node(pos, {6})
	end,

	on_receive_fields = function(pos, formname, fields, player)
		-- floor name entered?
		if fields.floor ~= nil then
			local floor = string.trim(fields.floor)
			if floor == "" then
				return
			end
			hyperloop.update_elevator(pos, floor, {})
			update_formspec(pos)
		elseif fields.button ~= nil then -- destination selected?
			update_formspec(pos)
			local floor = hyperloop.get_elevator(pos)
			if floor then
				local sKey = S(pos)
				local idx = tonumber(fields.button)
				local lFloors = Cache[sKey].lFloors
				local dest = lFloors[#lFloors-idx]
				if dest and dest.pos and floor.pos then
					local dist = hyperloop.distance(dest.pos, floor.pos)
					if dist ~= 0 and floor.busy ~= true then
						if player ~= nil then
							pos.y = pos.y - kPLAYER_OVER_GROUND
							player:set_pos(pos)
							pos.y = pos.y + kPLAYER_OVER_GROUND
						end
						-- due to the missing display, a trip needs 20 sec maximum
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
		update_formspec(pos)
		local floor = hyperloop.get_elevator(pos)
		--dbg()
		if floor and floor.busy ~= true then
			door_command(pos, floor.facedir, "open", true)
		end
	end,

	tubelib2_on_update = update_elevator,
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Shaft:after_dig_node(pos, {5})
		hyperloop.delete_elevator(pos)
		-- remove the bottom also
		pos = Shaft:get_pos(pos, 6)
		minetest.remove_node(pos)
		Shaft:after_dig_node(pos, {6})
	end,
})

minetest.register_node("hyperloop:elevator_top", {
	description = I("Hyperloop Elevator"),
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_elevator_bottom.png",
		"hyperloop_elevator_bottom.png",
		"hyperloop_elevator_top.png",
		"hyperloop_elevator.png",
		"hyperloop_elevator.png",
		"hyperloop_elevator.png",
	},
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16,  7/16, -8/16,   8/16,  8/16, 8/16},
			{ -8/16, -8/16, -8/16,  -7/16,  8/16, 8/16},
			{  7/16, -8/16, -8/16,   8/16,  8/16, 8/16},
			{ -7/16, -8/16,  7/16,   7/16,  8/16, 8/16},
		},
	},
	
	tubelib2_on_update = update_elevator,
	
	drawtype = "nodebox",
	paramtype = 'light',
	light_source = 6,
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
		local floor_pos = P(M(pos):get_string("floor_pos"))
		if floor_pos ~= nil then
			update_formspec(floor_pos)
			local floor = hyperloop.get_elevator(floor_pos)
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
