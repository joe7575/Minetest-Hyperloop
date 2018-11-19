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

local Elevators = hyperloop.Elevators
local Stations = hyperloop.Stations

local tLegacyNodeNames = {}

-- convert legacy tubes to current tubes
for idx = 0,2 do
	minetest.register_node("hyperloop:tube"..idx, {
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
			node.name = "hyperloop:tubeS"
			minetest.swap_node(pos, node)
			if not Tube:after_place_tube(pos, placer, pointed_thing) then
				minetest.remove_node(pos)
				return true
			end
			return false
		end,

		paramtype2 = "facedir",
		node_placement_prediction = "hyperloop:tubeS",
		groups = {cracky=2, not_in_creative_inventory=1},
		is_ground_content = false,
		sounds = default.node_sound_metal_defaults(),
	})
end

local function convert_legary_nodes(self, pos, dir)
	local convert_next_tube = function(self, pos, dir)
		local npos, node = self:get_node(pos, dir)
		print("convert_legary_nodes", S(npos), node.name)
		if tLegacyNodeNames[node.name]  then
			local dir1, dir2, num = self:determine_dir1_dir2_and_num_conn(npos)
			print("convert_legary_nodes", dir1, dir2, num)
			if dir1 then
				self.clbk_after_place_tube(self:tube_data_to_table(npos, dir1, 
					dir2 or tubelib2.Turn180Deg[dir1], num))
				if tubelib2.Turn180Deg[dir] == dir1 then
					return npos, dir2
				else
					return npos, dir1
				end
			end
		end
	end
	
	local cnt = 0
	if not dir then	return pos, dir, cnt end	
	while cnt <= 100000 do
		local new_pos, new_dir = convert_next_tube(self, pos, dir)
		if not new_dir then	break end
		pos, dir = new_pos, new_dir
		cnt = cnt + 1
	end
	return pos, dir, cnt
end	

local function convert_line(self, pos, dir)
	local fpos,fdir = convert_legary_nodes(self, pos, dir)
	print("convert_line", S(pos), dir, S(fpos), fdir)
	if not vector.equals(pos, fpos) then
		local npos,ndir = self:get_pos(pos, dir)
		self:add_meta(npos, fpos,fdir)
		self:add_meta(fpos, npos,ndir)
		self:update_secondary_node(npos,ndir, fpos,fdir)
		--self:update_secondary_node(fpos,fdir, npos,ndir)
	end
end


local tWifiNodes = {}  -- user for pairing
local lWifiNodes = {}  -- used for post processing

local function set_pairing(pos, peer_pos)
	print("set_pairing", S(pos), S(peer_pos))
	
	M(pos):set_int("tube_dir", Tube:get_primary_dir(pos))
	M(peer_pos):set_int("tube_dir", Tube:get_primary_dir(peer_pos))
	
	local tube_dir1 = Tube:store_teleport_data(pos, peer_pos)
	local tube_dir2 = Tube:store_teleport_data(peer_pos, pos)
end


local function wifi_post_processing()
	for _,pos in ipairs(lWifiNodes) do
		local dir = Tube:get_primary_dir(pos)
		local npos = Tube:get_pos(pos, dir)
		Tube:tool_repair_tube(npos)
	end
end

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
			set_pairing(P(k), pos)
			return
		end
	end
	-- add single Wifi node to pairing table
	tWifiNodes[S(pos)] = {pos1, pos2}
end

local function next_node_on_the_way_to_a_wifi_node(pos)
	local dirs = {}
	for dir = 1, 6 do
		local npos, node = Tube:get_node(pos, dir)
		if tLegacyNodeNames[node.name] then
			dirs[#dirs+1] = dir
		elseif node.name == "hyperloop:tube_wifi1" then
			lWifiNodes[#lWifiNodes+1] = npos
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
		local npos, node = Tube:get_node(pos, dir)
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
		local npos, node = Tube:get_node(pos, dir)
		if node and node.name == "hyperloop:tube1" then
			search_wifi_node(pos, dir)
		end
	end
end

local function convert_tube_line(pos)
	-- check all positions
	for dir = 1, 6 do
		local npos, node = Tube:get_node(pos, dir)
		if node and node.name == "hyperloop:tube1" then
			convert_line(Tube, pos, dir)
			--local peer = Tube:repair_tube_line(pos, dir)
			--print("npos", FoundWifiNodes[S(npos)])
		end
	end
end

local function convert_shaft_line(pos)
	-- check lower position
	convert_line(Shaft, pos, 5)
	-- check upper position
	pos.y = pos.y + 1
	convert_line(Shaft, pos, 6)
	pos.y = pos.y - 1
end

local function station_name(item)
	if item.junction == true then
		return "Junction"
	elseif item.station_name then
		return item.station_name
	else
		return "Station"
	end
end

local function add_to_table(tbl, tValues)
	local res = table.copy(tbl)
	for k,v in pairs(tValues) do
		tbl[k] = v
	end
	return res
end

local function convert_station_data(tAllStations)
	tLegacyNodeNames = {
		["hyperloop:tube0"] = true, 
		["hyperloop:tube1"] = true, 
		["hyperloop:tube2"] = true, 
	}
	
	local originNodeNames = add_to_table(Tube.primary_node_names, tLegacyNodeNames)
	
	for key,item in pairs(tAllStations) do
		if item.pos and Tube:secondary_node(item.pos) then
			Stations:set(item.pos, station_name(item), {
				owner = item.owner or "<unknown>",
				junction = item.junction,
				facedir = item.facedir,
				booking_info = item.booking_info,
				booking_pos = item.booking_pos,
			})
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
			--hyperloop.update_routes(item.pos)
		end
	end
	-- Repair the tube lines of wifi nodes
	wifi_post_processing()
	
	Tube.primary_node_names = originNodeNames
end

local function convert_elevator_data(tAllElevators)
	tLegacyNodeNames = {
		["hyperloop:shaft"] = true, 
		["hyperloop:shaft2"] = true,
	}
	local originNodeNames = add_to_table(Shaft.primary_node_names, tLegacyNodeNames)
	
	for pos,tElevator in pairs(tAllElevators) do
		for _,floor in pairs(tElevator.floors) do
			if floor.pos and Shaft:secondary_node(floor.pos) then
				Elevators:set(floor.pos, floor.name, {
					facedir = floor.facedir,
				})
				convert_shaft_line(floor.pos)
				M(floor.pos):set_int("change_counter", 0)
			end
		end
	end
	
	Shaft.primary_node_names = originNodeNames
end


local wpath = minetest.get_worldpath()
function hyperloop.file2table(filename)
	local f = io.open(wpath..DIR_DELIM..filename, "r")
	if f == nil then return nil end
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
		os.remove(wpath..DIR_DELIM.."mod_hyperloop.data")
		hyperloop.convert = nil
	end
end

minetest.after(5, migrate)

minetest.register_lbm({
	label = "[Hyperloop] booking/seat/door migration",
	name = "hyperloop:migrate",
	nodenames = {
		"hyperloop:booking", "hyperloop:booking_ground",
		"hyperloop:doorTopPassive", "hyperloop:doorBottom",
		"hyperloop:seat",
	},
	run_at_every_load = true,
	action = function(pos, node)
		local meta = M(pos)
		if meta:get_string("key_str") ~= "" then
			local s = meta:get_string("key_str")
			meta:set_string("sStationPos", "("..string.sub(s, 2, -2)..")")
			if node.name == "hyperloop:booking" or node.name == "hyperloop:booking_ground" then
				meta:set_int("change_counter", 0)
			end
		end
	end
})
