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

local Shaft = hyperloop.Shaft
local Tube = hyperloop.Tube

local function tube_crowbar_help(placer)
	minetest.chat_send_player(placer:get_player_name(), 
		"[Crowbar Help]\nFor tubes/shafts:\n"..
		"    left: remove node\n"..
		"    right: repair tube/shaft line\n"..
		"For Junctions/Stations:\n"..
		"    left: update node")
end	

local function repair_tubes(itemstack, placer, pointed_thing)
	if pointed_thing.type == "node" then
		local pos = pointed_thing.under
		local pos1, pos2, dir1, dir2, cnt1, cnt2 = Tube:tool_repair_tubes(pos)
		if pos1 and pos2 then
			minetest.chat_send_player(placer:get_player_name(), 
				"[Hyperloop]:\nTo the "..tubelib2.dir_to_string(dir1)..": "..cnt1.." tubes to pos "..S(pos1))
			minetest.chat_send_player(placer:get_player_name(), 
				"To the "..tubelib2.dir_to_string(dir2)..": "..cnt2.." tubes to pos "..S(pos2))
			return
		end
		pos1, pos2, dir1, dir2, cnt1, cnt2 = Shaft:tool_repair_tubes(pos)
		if pos1 and pos2 then
			minetest.chat_send_player(placer:get_player_name(), 
				"[Hyperloop]:\nTo the "..tubelib2.dir_to_string(dir1)..": "..cnt1.." shafts to pos "..S(pos1))
			minetest.chat_send_player(placer:get_player_name(), 
				"To the "..tubelib2.dir_to_string(dir2)..": "..cnt2.." shafts to pos "..S(pos2))
			return
		end
	else
		tube_crowbar_help(placer)
	end
end

local function remove_tube(itemstack, placer, pointed_thing)
	if pointed_thing.type == "node" then
		local pos = pointed_thing.under
		local node = minetest.get_node(pos)
		if node.name == "hyperloop:junction" or node.name == "hyperloop:station" then
			hyperloop.update_routes(pos, nil, placer:get_player_name())
		else
			Tube:tool_remove_tube(pos, "default_break_metal")
			Shaft:tool_remove_tube(pos, "default_break_metal")
		end
	else
		tube_crowbar_help(placer)
	end
end

local function route_list(lStationPositions, routes)
	local tRes = {}
	
	for _,route in ipairs(routes) do
		local spos = '('..string.sub(route[2], 2, -2)..')'
		if lStationPositions[spos] then
			tRes[#tRes + 1] = lStationPositions[spos]
			tRes[#tRes + 1] = ", "
		else
			tRes[#tRes + 1] = spos
			tRes[#tRes + 1] = ", "
		end
	end
	tRes[#tRes] = ""
	
	return table.concat(tRes)
end

local function dump_station_list(itemstack, placer, pointed_thing)
	local lStationPositions = {}
	local idx = 1
	for _,item in pairs(hyperloop.data.tAllStations) do
		local spos = S(item.pos)
		lStationPositions[spos] = idx
		idx = idx + 1
	end
	print("[Hyperloop] Station list")
	for _,item in pairs(hyperloop.data.tAllStations) do
		local spos = item.pos and S(item.pos) or "<unknown>"
		local version = item.version or 0
		local station_name = item.station_name or "<unknown>"
		local junction = item.junction or false
		local routes = route_list(lStationPositions, item.routes)
		print("pos = "..spos..", ver = "..version..", name = "..station_name..", junc = "..dump(junction)..", routes = "..routes)
	end
	print(dump(hyperloop.data))
end


-- Tool for tube workers to crack a protected tube line
minetest.register_node("hyperloop:tube_crowbar", {
	description = "Hyperloop Tube Crowbar",
	inventory_image = "hyperloop_tubecrowbar.png",
	wield_image = "hyperloop_tubecrowbar.png",
	use_texture_alpha = true,
	groups = {cracky=1, book=1},
	on_use = remove_tube,
	on_place = repair_tubes,
	on_secondary_use = dump_station_list,
	node_placement_prediction = "",
	stack_max = 1,
})
