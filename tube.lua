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

local function station_name(pos)
	local dataSet = hyperloop.get_station(pos)
	if dataSet then
		if dataSet.junction == true then
			return "Junction at "..S(pos)
		elseif dataSet.name ~= nil then
			return "Station '"..dataSet.name.."' at "..S(pos)
		else
			return "Station at "..S(pos)
		end
	end
	return "Open end at "..minetest.pos_to_string(pos)
end

function hyperloop.check_network_level(pos, player)
	if hyperloop.free_tube_placement_enabled then
		return
	end
	for key,_ in pairs(hyperloop.tDatabase.tStations) do
		if pos.y == P(key).y then
			return
		end
	end
	hyperloop.chat(player, I("These is no station/junction on this level. ")..
		I("Do you realy want to start a new network?!"))
end

--                       North, East, South, West, Down, Up
local dirs_to_check = {1,2,3,4}  -- horizontal only
if hyperloop.free_tube_placement_enabled then
	dirs_to_check = {1,2,3,4,5,6}  -- all directions
end

local Tube = tubelib2.Tube:new({
	dirs_to_check = dirs_to_check,
	max_tube_length = 10000, 
	show_infotext = true,
	primary_node_names = {"hyperloop:tubeS", "hyperloop:tubeS2", "hyperloop:tubeA", "hyperloop:tubeA2"}, 
	secondary_node_names = {"hyperloop:junction", "hyperloop:station", "hyperloop:tube_wifi1"},
	after_place_tube = function(pos, param2, tube_type, num_tubes)
		if num_tubes == 2 then
			minetest.swap_node(pos, {name = "hyperloop:tube"..tube_type.."2", param2 = param2})
		else
			minetest.swap_node(pos, {name = "hyperloop:tube"..tube_type, param2 = param2})
		end
	end,
})

hyperloop.Tube = Tube

minetest.register_node("hyperloop:tubeS", {
	description = I("Hyperloop Tube"),
	inventory_image = minetest.inventorycube("hyperloop_tube_locked.png", 
		'hyperloop_tube_open.png', "hyperloop_tube_locked.png"),
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_closed.png^[transformR90]",
		"hyperloop_tube_closed.png^[transformR90]",
		'hyperloop_tube_closed.png',
		'hyperloop_tube_closed.png',
		{
			image = 'hyperloop_tube_open_active.png',
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 0.5,
			},
		},
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-8/16, -8/16, -8/16, -7/16,  8/16,  8/16},
			{ 7/16, -8/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16,  7/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16, -8/16, -8/16,  8/16, -7/16,  8/16},
			{-7/16, -7/16, -7/16,  7/16,  7/16,  7/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -8/16,  8/16, 8/16, 8/16},
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
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	light_source = 2,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 1},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("hyperloop:tubeS2", {
	description = "Hyperloop Tube",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_locked.png^hyperloop_logo.png^[transformR90]",
		"hyperloop_tube_locked.png^hyperloop_logo.png^[transformR90]",
		'hyperloop_tube_locked.png^hyperloop_logo.png',
		'hyperloop_tube_locked.png^hyperloop_logo.png',
		{
			image = 'hyperloop_tube_open_active.png',
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 0.5,
			},
		},
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-8/16, -8/16, -8/16, -7/16,  8/16,  8/16},
			{ 7/16, -8/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16,  7/16, -8/16,  8/16,  8/16,  8/16},
			{-8/16, -8/16, -8/16,  8/16, -7/16,  8/16},
			{-7/16, -7/16, -7/16,  7/16,  7/16,  7/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -8/16,  8/16, 8/16, 8/16},
	},

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Tube:after_dig_tube(pos, oldnode, oldmetadata)
	end,
	
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

minetest.register_node("hyperloop:tubeA", {
	description = "Hyperloop Tube",
	inventory_image = minetest.inventorycube("hyperloop_tube_locked.png", 
		'hyperloop_tube_open.png', "hyperloop_tube_locked.png"),
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_closed.png^[transformR90]",
		{
			image = 'hyperloop_tube_open_active.png',
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 0.5,
			},
		},
		'hyperloop_tube_closed.png',
		'hyperloop_tube_closed.png',
		"hyperloop_tube_closed.png^[transformR90]",
		{
			image = 'hyperloop_tube_open_active.png',
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 0.5,
			},
		},
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
			{-7/16, -7/16, -7/16,  7/16,  7/16,  7/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-8/16, -8/16, -8/16,  8/16, 8/16, 8/16},
	},

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Tube:after_dig_tube(pos, oldnode, oldmetadata)
	end,
	
	paramtype2 = "facedir", -- important!
	on_rotate = screwdriver.disallow, -- important!
	paramtype = "light",
	light_source = 2,
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 1, not_in_creative_inventory=1},
	drop = "hyperloop:shaft",
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("hyperloop:tubeA2", {
	description = "Hyperloop Tube",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_locked.png^hyperloop_logo.png^[transformR90]",
		"hyperloop_tube_locked.png^hyperloop_logo.png^[transformR90]",
		"hyperloop_tube_locked.png^hyperloop_logo.png",
		"hyperloop_tube_locked.png^hyperloop_logo.png",
		"hyperloop_tube_locked.png^hyperloop_logo.png",
		"hyperloop_tube_locked.png^hyperloop_logo.png",
	},

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Tube:after_dig_tube(pos, oldnode, oldmetadata)
	end,
	
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
