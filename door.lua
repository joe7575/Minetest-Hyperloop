--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

-- for lazy programmers
local S = minetest.pos_to_string
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Open the door for an emergency
local function door_on_punch(pos, node, puncher, pointed_thing)
	local meta = minetest.get_meta(pos)
	local key_str = meta:get_string("key_str")
	if hyperloop.data.tAllStations[key_str] ~= nil then
		local station_name = hyperloop.data.tAllStations[key_str].station_name
		if station_name == nil then
			hyperloop.chat(puncher, "The Booking Machine for this station is missing!")
		elseif not hyperloop.is_blocked(station_name) then
			local tStation = hyperloop.get_station_data(key_str)
			hyperloop.open_pod_door(tStation)
		end
	end
end

-- Open/close/animate the pod door
-- door_pos1: position of the bottom door
-- cmnd: "close", "open", or "animate"
local function door_command(door_pos1, cmnd)
	-- one step up
	local door_pos2 = vector.add(door_pos1, {x=0, y=1, z=0})

	local node1 = minetest.get_node(door_pos1)
	local node2 = minetest.get_node(door_pos2)
	local meta = minetest.get_meta(door_pos1)
	local facedir = meta:get_int("facedir")
	if cmnd == "open" then
		minetest.sound_play("door", {
				pos = door_pos1,
				gain = 0.5,
				max_hear_distance = 10,
			})
		node1.name = "air"
		minetest.swap_node(door_pos1, node1)
		node2.name = "air"
		minetest.swap_node(door_pos2, node2)
	elseif cmnd == "close" then
		minetest.sound_play("door", {
				pos = door_pos1,
				gain = 0.5,
				max_hear_distance = 10,
			})
		node1.name = "hyperloop:doorBottom"
		node1.param2 = facedir
		minetest.swap_node(door_pos1, node1)
		node2.name = "hyperloop:doorTopPassive"
		node2.param2 = facedir
		minetest.swap_node(door_pos2, node2)
	elseif cmnd == "animate" then
		node2.name = "hyperloop:doorTopActive"
		node2.param2 = facedir
		minetest.swap_node(door_pos2, node2)
	end
end

-- door command based on the station data table
function hyperloop.open_pod_door(tStation)
	if tStation ~= nil then
		print(S(tStation.pos), tStation.facedir)
		local door_pos = hyperloop.new_pos(tStation.pos, tStation.facedir, "1F1L", 1)
		door_command(door_pos, "open")
	end
end

-- door command based on the station data table
function hyperloop.close_pod_door(tStation)
	if tStation ~= nil then
		local door_pos = hyperloop.new_pos(tStation.pos, tStation.facedir, "1F1L", 1)
		door_command(door_pos, "close")
	end
end

-- door command based on the station data table
function hyperloop.animate_pod_door(tStation)
	if tStation ~= nil then
		local door_pos = hyperloop.new_pos(tStation.pos, tStation.facedir, "1F1L", 1)
		door_command(door_pos, "animate")
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
	
	auto_place_node = function(pos, placer, facedir, key_str)
		local meta = minetest.get_meta(pos)
		meta:set_int("facedir", facedir)
		meta:set_string("key_str", key_str)
	end,
	
	paramtype = 'light',
	light_source = 1,
	paramtype2 = "facedir",
	drop = "",
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
	drop = "",
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
	
	auto_place_node = function(pos, placer, facedir, key_str)
		local meta = minetest.get_meta(pos)
		meta:set_int("facedir", facedir)
		meta:set_string("key_str", key_str)
	end,
	
	paramtype = 'light',
	light_source = 1,
	paramtype2 = "facedir",
	drop = "",
	sounds = default.node_sound_metal_defaults(),
	groups = {cracky=1, not_in_creative_inventory=1},
	is_ground_content = false,
})

