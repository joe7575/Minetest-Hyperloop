--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

-- Open the door for an emergency
local function door_on_punch(pos, node, puncher, pointed_thing)
	local meta = minetest.get_meta(pos)
	local station_name = meta:get_string("station_name")
	if not hyperloop.is_blocked(station_name) then
		hyperloop.open_pod_door(station_name)
	end
end

-- Open/close/animate the pod door
-- seat_pos: position of the seat
-- facedir: direction to the display
-- cmnd: "close", "open", or "animate"
function hyperloop.door_command(seat_pos, facedir, cmnd, station_name)
	-- one step forward
	local lcd_pos = vector.add(seat_pos, hyperloop.placedir_to_dir(facedir))
	-- one step left
	local door_pos1 = vector.add(lcd_pos, hyperloop.placedir_to_dir(facedir + 1))
	-- one step up
	local door_pos2 = vector.add(door_pos1, {x=0, y=1, z=0})

	local node1 = minetest.get_node(door_pos1)
	local node2 = minetest.get_node(door_pos2)

	-- switch from the radian following facedir to the silly original one
	local tbl = {[0]=0, [1]=3, [2]=2, [3]=1}
	facedir = (facedir + 3) % 4   -- first turn left
	facedir = tbl[facedir]

	if cmnd == "open" then
		minetest.sound_play("door", {
				pos = seat_pos,
				gain = 0.5,
				max_hear_distance = 10,
			})
		node1.name = "air"
		minetest.swap_node(door_pos1, node1)
		node2.name = "air"
		minetest.swap_node(door_pos2, node2)
	elseif cmnd == "close" then
		minetest.sound_play("door", {
				pos = seat_pos,
				gain = 0.5,
				max_hear_distance = 10,
			})
		node1.name = "hyperloop:doorBottom"
		node1.param2 = facedir
		minetest.swap_node(door_pos1, node1)
		if station_name ~= nil then
			local meta = minetest.get_meta(door_pos1)
			meta:set_string("station_name", station_name)
		end
		node2.name = "hyperloop:doorTopPassive"
		node2.param2 = facedir
		minetest.swap_node(door_pos2, node2)
		if station_name ~= nil then
			meta = minetest.get_meta(door_pos2)
			meta:set_string("station_name", station_name)
		end
	elseif cmnd == "animate" then
		node2.name = "hyperloop:doorTopActive"
		node2.param2 = facedir
		minetest.swap_node(door_pos2, node2)
	end
end

minetest.register_node("hyperloop:doorTopPassive", {
	description = "Hyperloop Door Top",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_skin_door.png",
		"hyperloop_skin_door.png",
		"hyperloop_skin_door.png",
		"hyperloop_skin_door.png",
		"hyperloop_door1OUT.png",
		"hyperloop_door1OUT.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -5/16, 8/16, 8/16, 5/16},
	},
	
	on_punch = door_on_punch,
	
	paramtype2 = "facedir",
	diggable = false,
	sounds = default.node_sound_metal_defaults(),
	groups = {cracky=1, not_in_creative_inventory=1},
	is_ground_content = false,
})

minetest.register_node("hyperloop:doorTopActive", {
	description = "Hyperloop Door Top",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_skin_door.png",
		"hyperloop_skin_door.png",
		"hyperloop_skin_door.png",
		"hyperloop_skin_door.png",
		{
			name = "hyperloop_door1IN.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 1.0,
			},
		},
		"hyperloop_door1OUT.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -5/16, 8/16, 8/16, 5/16},
	},
	paramtype2 = "facedir",
	diggable = false,
	light_source = 2,
	sounds = default.node_sound_metal_defaults(),
	groups = {cracky=1, not_in_creative_inventory=1},
	is_ground_content = false,
})

minetest.register_node("hyperloop:doorBottom", {
	description = "Hyperloop Door Bottom",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_skin_door.png",
		"hyperloop_skin_door.png",
		"hyperloop_skin_door.png",
		"hyperloop_skin_door.png",
		"hyperloop_door2IN.png",
		"hyperloop_door2OUT.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -5/16, 8/16, 8/16, 5/16},
	},
	
	on_punch = door_on_punch,
	
	paramtype2 = "facedir",
	diggable = false,
	sounds = default.node_sound_metal_defaults(),
	groups = {cracky=1, not_in_creative_inventory=1},
	is_ground_content = false,
})

