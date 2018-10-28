--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see tube.lua

]]--

-- for lazy programmers
local S = minetest.pos_to_string
local P = minetest.string_to_pos
local M = minetest.get_meta

local function station_name(pos)
	local key_str = hyperloop.get_key_str(pos)
	local dataSet = hyperloop.data.tAllStations[key_str]
	if dataSet then
		if dataSet.junction == true then
			return "Junction at "..minetest.pos_to_string(pos)
		elseif dataSet.station_name ~= nil then
			return "Station '"..dataSet.station_name.."' at "..minetest.pos_to_string(pos)
		else
			return "Station at "..minetest.pos_to_string(pos)
		end
	end
	return "Open end at "..minetest.pos_to_string(pos)
end

local function chat_send_player(name, dir, pos)
	if name then
		local sdir = tubelib2.dir_to_string(dir)
		minetest.chat_send_player(name, "To the "..sdir..": "..station_name(pos))
	end
end

function hyperloop.check_network_level(pos, player)
	if hyperloop.free_tube_placement_enabled then
		return
	end
	for key,item in pairs(hyperloop.data.tAllStations) do
		if pos.y == item.pos.y then
			return
		end
	end
	hyperloop.chat(player, "These is no station/junction on this level. "..
						   "Do you realy want to start a new network?!")
end

local Tube = tubelib2.Tube:new({
	                -- North, East, South, West, Down, Up
	--allowed_6d_dirs = {true, true, true, true, false, false},  -- horizontal only
	allowed_6d_dirs = {true, true, true, true, true, true},  -- horizontal only
	max_tube_length = 1000, 
	show_infotext = true,
	primary_node_names = {"hyperloop:tube", "hyperloop:tube2"}, 
	secondary_node_names = {"hyperloop:junction", "hyperloop:station"},
	after_place_tube = function(pos, param2, tube_type, num_tubes, tbl)
		if num_tubes == 2 then
			minetest.set_node(pos, {name = "hyperloop:tube2", param2 = param2})
		else
			minetest.set_node(pos, {name = "hyperloop:tube", param2 = param2})
		end
		if not tbl or tbl.convert then
			minetest.sound_play({
				name="default_place_node_metal"},{
				gain=1,
				max_hear_distance=5,
				loop=false})
		end
	end,
})

hyperloop.Tube = Tube

minetest.register_node("hyperloop:tube", {
	description = "Hyperloop Tube",
	inventory_image = minetest.inventorycube("hyperloop_tube_locked.png", 
		'hyperloop_tube_open.png', "hyperloop_tube_locked.png"),
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_closed.png^[transformR90]",
		"hyperloop_tube_closed.png^[transformR90]",
		'hyperloop_tube_closed.png',
		'hyperloop_tube_closed.png',
		'hyperloop_tube_open.png',
		'hyperloop_tube_open.png',
	},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if not Tube:after_place_tube(pos, placer, pointed_thing) then
			minetest.remove_node(pos)
			return true
		end
		return false
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Tube:after_dig_tube(pos, oldnode, oldmetadata)
	end,
	
	paramtype2 = "facedir", -- important!
	node_placement_prediction = "", -- important!
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 1},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("hyperloop:tube2", {
	description = "Hyperloop Tube",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png",
		"hyperloop_tube_locked.png",
		"hyperloop_tube_locked.png",
		"hyperloop_tube_locked.png",
	},

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Tube:after_dig_tube(pos, oldnode, oldmetadata)
	end,
	
	paramtype2 = "facedir", -- important!
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	diggable = false,
	groups = {cracky = 1, not_in_creative_inventory=1},
	sounds = default.node_sound_metal_defaults(),
})

-- for tube viaducts
minetest.register_node("hyperloop:pillar", {
	description = "Hyperloop Pillar",
	tiles = {"hyperloop_tube_locked.png^[transformR90]"},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -3/8, -4/8, -3/8,   3/8, 4/8, 3/8},
		},
	},
	is_ground_content = false,
	groups = {cracky = 2, stone = 2},
	sounds = default.node_sound_metal_defaults(),
})

-- Update local and all connected junctions/stations
function hyperloop.update_routes(pos, called_from_peer, player_name)
	local tRoutes = {}
	if player_name then
		minetest.chat_send_player(player_name, "[Hyperloop] "..S(pos))
	end
	for dir = 1,4 do -- check all 4 directions
		local npos = Tube:get_connected_node_pos(pos, dir)
		--print(S(pos), dir, S(npos), minetest.get_node(npos).name)
		if Tube:secondary_node(npos) then
			table.insert(tRoutes, {S(pos), S(npos)})
			if not called_from_peer then
				hyperloop.update_routes(npos, true)
				chat_send_player(player_name, dir, npos)
			end
		elseif not Tube:beside(pos, npos) then
			table.insert(tRoutes, {S(pos), S(npos)})
			if not called_from_peer then
				chat_send_player(player_name, dir, npos)
			end
		end
	end
	
	-- store list
	local key_str = hyperloop.get_key_str(pos)
	if hyperloop.data.tAllStations[key_str] ~= nil then
		hyperloop.data.tAllStations[key_str].routes = tRoutes
	end
	
	hyperloop.data.change_counter = hyperloop.data.change_counter + 1
end
