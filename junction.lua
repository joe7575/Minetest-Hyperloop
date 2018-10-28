--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see junction.lua

]]--

-- for lazy programmers
local S = minetest.pos_to_string
local P = minetest.string_to_pos
local M = minetest.get_meta

local Tube = hyperloop.Tube


local function store_junction(pos, placer)
	local key_str = hyperloop.get_key_str(pos)
	hyperloop.data.tAllStations[key_str] = {
		version = hyperloop.data.version,  -- for version checks
		pos = pos,  -- station/junction node position
		routes = {},  -- will be calculated later
		owner = placer:get_player_name(), 
		junction = true,
	}
	hyperloop.data.change_counter = hyperloop.data.change_counter + 1
end

local function delete_junction(pos)
	local key_str = hyperloop.get_key_str(pos)
	hyperloop.data.tAllStations[key_str] = nil
	hyperloop.data.change_counter = hyperloop.data.change_counter + 1
end


minetest.register_node("hyperloop:junction", {
	description = "Hyperloop Junction Block",
	tiles = {
		"hyperloop_junction_top.png",
		"hyperloop_junction_top.png",
		"hyperloop_station_connection.png",
	},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		hyperloop.check_network_level(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Position "..hyperloop.get_key_str(pos))
		Tube:after_place_node(pos)
		store_junction(pos, placer)
		hyperloop.update_routes(pos)
	end,

	on_punch = function(pos, node, puncher, pointed_thing)
		minetest.node_punch(pos, node, puncher, pointed_thing)
		hyperloop.update_routes(pos, nil, puncher:get_player_name())
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Tube:after_dig_node(pos)
	end,
	
	on_destruct = delete_junction,

	paramtype2 = "facedir",
	groups = {cracky = 1},
	is_ground_content = false,
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

minetest.register_lbm({
	label = "[Hyperloop] Station update",
	name = "hyperloop:update_junction",
	nodenames = {"hyperloop:junction", "hyperloop:station"},
	run_at_every_load = true,
	action = function(pos, node)
		hyperloop.update_routes(pos)
	end
})

