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


--
-- Wifi nodes
--
local tWifiNodes = {}

-- Wifi nodes don't know their counterpart.
-- But by means of the tube head nodes, two
-- Wifi nodes in one tube line can be determined.
local function determine_wifi_pairs(pos)
	-- determine 1. tube head node
	local pos1 = M(pos):get_string("peer")
	if pos1 == "" then return end
	-- determine 2. tube head node
	local pos2 = M(P(pos1)):get_string("peer")
	if pos2 == "" then return end
	for k,item in pairs(tWifiNodes) do
		-- entry already available
		if item[1] == pos2 and item[2] == pos1 then
			tWifiNodes[k] = nil
			-- start paring
			Tube:set_pairing(P(k), pos)
			return
		end
	end
	-- add single Wifi node to pairing table
	tWifiNodes[S(pos)] = {pos1, pos2}
end

local function next_node_on_the_way_to_a_wifi_node(pos)
	local dirs = {}
	for dir = 1, 6 do
		local npos, node = Tube:get_next_node(pos, dir)
		if node.name == "hyperloop:tube" or node.name == "hyperloop:tube1" or node.name == "hyperloop:tube2" then
			dirs[#dirs+1] = dir
		elseif node and node.name == "hyperloop:tube_wifi1" then
			determine_wifi_pairs(npos)
		end
	end
	if #dirs == 1 then
		return dirs[1], nil, 1
	elseif #dirs == 2 then
		return dirs[1], dirs[2], 2
	else
		print("on_convert_tube", dump(dirs))
	end
end

local function search_wifi_node(pos, dir)
	local convert_next_tube = function(pos, dir)
		local npos, node = Tube:get_next_node(pos, dir)
		local dir1, dir2, num = next_node_on_the_way_to_a_wifi_node(npos)
		if dir1 then
			if tubelib2.Turn180Deg[dir] == dir1 then
				return npos, dir2
			else
				return npos, dir1
			end
		end
	end
	
	local cnt = 0
	if not dir then	return pos, cnt end	
	while true do
		local new_pos, new_dir = convert_next_tube(pos, dir)
		if not new_dir then	break end
		pos, dir = new_pos, new_dir
		cnt = cnt + 1
	end
	return pos, dir, cnt
end	

local function search_wifi_node_in_all_dirs(pos)
	-- check all positions
	for dir = 1, 6 do
		local npos, node = Tube:get_next_node(pos, dir)
		if node and node.name == "hyperloop:tube1" then
			search_wifi_node(pos, dir)
		end
	end
end


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
		if node and node.name == "hyperloop:tube1" then
			local peer = Tube:convert_tube_line(pos, dir)
			--print("npos", FoundWifiNodes[S(npos)])
		end
	end
end


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


local function convert_station_data(tAllStations)
	for key,item in pairs(tAllStations) do
		if item.pos and Tube:secondary_node(item.pos) then
			hyperloop.data.tAllStations[key] = item
		end
	end
	-- First perform the Wifi node pairing
	-- before all tube node loose their meta data
	-- while converted.
	for key,item in pairs(tAllStations) do
		if item.pos and Tube:secondary_node(item.pos) then
			search_wifi_node_in_all_dirs(item.pos)
		end
	end
	-- Then convert all tube nodes
	for key,item in pairs(tAllStations) do
		if item.pos and Tube:secondary_node(item.pos) then
			convert_tube_line(item.pos)
			Tube:after_place_node(item.pos)
			hyperloop.update_routes(item.pos)
		end
	end
end

local function convert_elevator_data(tAllElevators)
	for key,item in pairs(tAllElevators) do
		if item.pos and Shaft:secondary_node(item.pos) then
			hyperloop.data.tAllElevators[key] = item
		end
	end
	for key,item in pairs(tAllElevators) do
		if item.pos and Shaft:secondary_node(item.pos) then
			convert_shaft_line(item.pos)
		end
	end
end

local wpath = minetest.get_worldpath()
function hyperloop.file2table(filename)
	local f = io.open(wpath..DIR_DELIM..filename, "r")
	if f == nil then return {} end
	local t = f:read("*all")
	f:close()
	if t == "" or t == nil then return nil end
	return minetest.deserialize(t)
end

local function migrate()
	local data = hyperloop.file2table("mod_hyperloop.data")
	if data then
		hyperloop.convert = true
		convert_station_data(data.tAllStations)
		convert_elevator_data(data.tAllElevators)
		minetest.safe_file_write(wpath..DIR_DELIM.."mod_hyperloop.data", "")
		hyperloop.convert = nil
	end
	
	print("NodesWithPeerMeta", dump(NodesWithPeerMeta))
	print("tWifiNodes", dump(tWifiNodes))
end

minetest.after(10, migrate)