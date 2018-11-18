--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017-2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("hyperloop")
local I, NS = dofile(MP.."/intllib.lua")

local Tube = hyperloop.Tube
local Stations = hyperloop.Stations


minetest.register_node("hyperloop:junction", {
	description = I("Hyperloop Junction Block"),
	tiles = {
		"hyperloop_junction_top.png",
		"hyperloop_junction_top.png",
		"hyperloop_station_connection.png",
	},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		hyperloop.check_network_level(pos, placer)
		M(pos):set_string("infotext", I("Junction"))
		Stations:set(pos, "Junction", {
				owner = placer:get_player_name(), junction = true})
		Tube:after_place_node(pos, {1,2,3,4})
	end,

	tubelib2_on_update = function(pos, out_dir, peer_pos, peer_in_dir)
		print("tubelib2_on_update", S(pos), S(peer_pos))
		if out_dir <= 4 then
			Stations:update_connections(pos, out_dir, peer_pos)
			local s = hyperloop.get_connection_string(pos)
			M(pos):set_string("infotext", I("Junction connected with ")..s)
		end
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Tube:after_dig_node(pos, {1,2,3,4})
		Stations:delete(pos)
	end,
	
	paramtype2 = "facedir",
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
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
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2, stone = 2},
	sounds = default.node_sound_metal_defaults(),
})
