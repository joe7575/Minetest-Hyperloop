--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

	Migrate from v1 to v2
	
]]--

-- for lazy programmers
local S = minetest.pos_to_string
local P = minetest.string_to_pos
local M = minetest.get_meta

local Tube = hyperloop.Tube
local Shaft = hyperloop.Shaft


--
-- Stations/Junctions
--

Tube:on_convert_tube(function(pos, name, param2)
	local dirs = {}
	for dir = 1, 6 do
		--local npos = Tube:primary_node(pos, dir)
		local npos, node = Tube:get_next_node(pos, dir)
		if node.name == "hyperloop:tube" or node.name == "hyperloop:tube1" or node.name == "hyperloop:tube2" then
			dirs[#dirs+1] = dir
		end
	end
	if #dirs == 1 then
		return dirs[1], nil, 1
	elseif #dirs == 2 then
		return dirs[1], dirs[2], 2
	else
		print("on_convert_tube", dump(dirs))
	end
end)

local function convert_tube_line(pos)
	-- check all positions
	for dir = 1, 6 do
		local npos, node = Tube:get_next_node(pos, dir)
		print("convert_tube_line", node.name)
		if node and node.name == "hyperloop:tube1" then
			Tube:convert_tube_line(pos, dir)
		end
	end
end

minetest.register_lbm({
	label = "[Hyperloop] Station update",
	name = "hyperloop:update_junction",
	nodenames = {"hyperloop:junction", "hyperloop:station"},
	run_at_every_load = true,
	action = function(pos, node)
		if hyperloop.debugging then
			print("Junction/Station loaded")
		end
		convert_tube_line(pos)  -- migration
		hyperloop.update_routes(pos)
		Tube:after_place_crossing_node(pos)
	end
})

--
-- Wifi nodes
--
function Tube:update_wifi_nodes(pos)
	local peer_pos = M(pos):get_string("wifi_peer")
	if peer_pos ~= "" then
		Tube:set_pairing(pos, peer_pos)
	end
end

-- Migration to v2
-- Lagacy nodes are replaced but the pairing has to be repeated.
minetest.register_lbm({
	label = "[Hyperloop] Wifi update",
	name = "hyperloop:update_wifi",
	nodenames = {"hyperloop:tube_wifi1"},
	run_at_every_load = true,
	action = function(pos, node)
		local tube_dir = Tube:get_primary_dir(pos)
		Tube:after_place_node(pos, tube_dir)
		Tube:update_wifi_nodes(pos)
	end
})


--
-- Elevator shafts
-- 
Shaft:on_convert_tube(function(pos, name, param2)
	if param2 < 30 then
		print("param2", param2)
		if name == "hyperloop:shaft2" then
			return 5, 6, 2
		elseif name == "hyperloop:shaft" then
			return 5, 6, 1
		end
	end
end)

local function convert_shaft_line(pos)
	-- check lower position
	if Shaft:primary_node(pos, 5) then
		Shaft:convert_tube_line(pos, 5)
	end
	-- check upper position
	pos.y = pos.y + 1
	if Shaft:primary_node(pos, 6) then
		Shaft:convert_tube_line(pos, 6)
	end
	pos.y = pos.y - 1
end


minetest.register_lbm({
	label = "[Hyperloop] Elevator update",
	name = "hyperloop:update_elevator",
	nodenames = {"hyperloop:elevator_bottom"},
	run_at_every_load = true,
	action = function(pos, node)
		convert_shaft_line(pos)
	end
})


--
-- Tubes
--
-- convert legacy tubes to current tubes
minetest.register_node("hyperloop:tube0", {
	description = "Hyperloop Legacy Tube",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
		'hyperloop_tube_closed.png',
		'hyperloop_tube_closed.png',
		'hyperloop_tube_open.png',
		'hyperloop_tube_open.png',
	},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local node = minetest.get_node(pos)
		node.name = "hyperloop:tube"
		minetest.swap_node(pos, node)
		if not Tube:after_place_tube(pos, placer, pointed_thing) then
			minetest.remove_node(pos)
			return true
		end
		return false
	end,

	paramtype2 = "facedir",
	node_placement_prediction = "hyperloop:tube",
	groups = {cracky=2, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})


local wpath = minetest.get_worldpath()

-- Convert legacy data
local function convert_station_list(tAllStations)
	local tRes = {}
	for key,item in pairs(tAllStations) do
		-- remove legacy data
		if item.version == hyperloop.version then
			tRes[key] = item
		end
	end
	return tRes
end

function hyperloop.file2table(filename)
	local f = io.open(wpath..DIR_DELIM..filename, "r")
	if f == nil then return {} end
	local t = f:read("*all")
	f:close()
	if t == "" or t == nil then return {} end
	return minetest.deserialize(t)
end

function hyperloop.table2file(filename, table)
	local f = io.open(wpath..DIR_DELIM..filename, "w")
	f:write(minetest.serialize(table))
	f:close()
end
-- Store and read the station list to / from a file
-- so that upcoming actions are remembered when the game
-- is restarted
function hyperloop.store_station_list()
	hyperloop.table2file("mod_hyperloop.data", hyperloop.data)
end

local data = hyperloop.file2table("mod_hyperloop.data")
if next(data) ~= nil then
	hyperloop.data = data
else
	hyperloop.data.tAllStations = hyperloop.file2table("hyperloop_station_list")
end	

-- convert to current format
hyperloop.data.tAllStations = convert_station_list(hyperloop.data.tAllStations)

minetest.register_on_shutdown(hyperloop.store_station_list)

-- store ring list once a day
minetest.after(60*60*24, hyperloop.store_station_list)
	