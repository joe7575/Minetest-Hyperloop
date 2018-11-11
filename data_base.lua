--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017-2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

local dbg = require("debugger")

-- for lazy programmers
local S = minetest.pos_to_string
local P = minetest.string_to_pos
local M = minetest.get_meta

--[[
	tStations["(x,y,z)"] = {
		["conn"] = {
			dir = "(200,0,20)",
		},
	}
]]--

hyperloop = {
	tDatabase = {
		tStations = {},  -- tube networks
		tElevators = {},  -- elevators
		station_chng_cnt = 0,  -- used for force updates
		elevator_chng_cnt = 0,  -- used for force updates
	},
	version = 2,  -- compatibility version
	booking = {},  -- open booking nodes
}

-- Configuration settings
hyperloop.wifi_enabled = minetest.setting_get("hyperloop_wifi_enabled") or false
hyperloop.free_tube_placement_enabled = minetest.setting_get("hyperloop_free_tube_placement_enabled") or false

-------------------------------------------------------------------------------
-- Data base storage
-------------------------------------------------------------------------------

local storage = minetest.get_mod_storage()
hyperloop.tDatabase = minetest.deserialize(storage:get_string("data")) or hyperloop.tDatabase

print(dump(hyperloop.tDatabase))

local function update_mod_storage()
	minetest.log("action", "[Hyperloop] Store data...")
	storage:set_string("data", minetest.serialize(hyperloop.tDatabase))
	-- store data each hour
	minetest.after(60*60, update_mod_storage)
	minetest.log("action", "[Hyperloop] Data stored")
end

minetest.register_on_shutdown(function()
	update_mod_storage()
end)

-- store data after one hour
minetest.after(60*60, update_mod_storage)


-------------------------------------------------------------------------------
-- Data base maintainance
-------------------------------------------------------------------------------

local function dbg_out(tStations, pos)
	local sKey = S(pos)
	if tStations then
		if tStations[sKey] then
			print("dbg_out: tStations[sKey].name = "..tStations[sKey].name)
			for idx,conn in ipairs(tStations[sKey].conn) do
				print("dbg_out: dir["..idx.."] = "..conn)
			end
		else
			print("dbg_out: tStations[sKey] is nil")
		end
	else
		print("dbg_out: tStations is nil")
	end
end	

-- Convert to list and add pos based on key string
local function table_to_list(table)
	local lRes = {}
	for key,item in pairs(table) do 
		item.pos = P(key)
		lRes[#lRes+1] = item 
	end
	return lRes
end

-- Distance between two points in (tube) blocks
function hyperloop.distance(pos1, pos2)
	return math.floor(math.abs(pos1.x - pos2.x) + 
			math.abs(pos1.y - pos2.y) + math.abs(pos1.z - pos2.z))
end

-- Add the distance to pos to each list item
local function add_distance_to_list(lStations, pos)
	for _,item in ipairs(lStations) do 
		item.distance = hyperloop.distance(item.pos, pos)
	end
	return lStations
end

-- Return a table with all stations, the given station (as 'sKey') is connected with
-- tRes is used for the resulting table (recursive call)
local function get_stations(tStations, sKey, tRes)
	print("get_stations", sKey)
	if not tStations[sKey] or not tStations[sKey].conn then 
		return {} 
	end
	for dir,dest in pairs(tStations[sKey].conn) do
		-- Not already visited?
		print("get_stations", dir,dest)
		if not tRes[dest] then
			-- Known station?
			if tStations[dest] then
				tRes[dest] = tStations[dest]
				get_stations(tStations, dest, tRes)
			end
		end
	end
	return tRes
end

-- Create/update an elevator or station entry.
-- tAttr is a table with additional attributes to be stored.
local function update_station(tStations, pos, name, tAttr)
	local sKey = S(pos)
	if not tStations[sKey] then
		tStations[sKey] = {
			conn = {},
		}
	end
	tStations[sKey].name = name
	for k,v in pairs(tAttr) do
		tStations[sKey][k] = v
	end
	dbg_out(tStations, pos)
end

-- Delete an elevator or station entry.
local function delete_station(tStations, pos)
	local sKey = S(pos)
	tStations[sKey] = nil
end

-- Update the connection data base. The output dir information is needed
-- to be able to delete a connection, if necessary.
-- Returns true, if data base is changed.
local function update_conn_table(tStations, pos, out_dir, conn_pos)
	--dbg()
	local sKey = S(pos)
	local res = false
	if not tStations[sKey] then
		tStations[sKey] = {}
		res = true
	end
	if not tStations[sKey].conn then
		tStations[sKey].conn = {}
		res = true
	end
	conn_pos = S(conn_pos)
	if tStations[sKey].conn[out_dir] ~= conn_pos then
		tStations[sKey].conn[out_dir] = conn_pos
		res = true
	end
	return res
end

function hyperloop.update_station(pos, name, tAttr)
	update_station(hyperloop.tDatabase.tStations, pos, name, tAttr)
	hyperloop.tDatabase.station_chng_cnt = hyperloop.tDatabase.station_chng_cnt + 1
end

function hyperloop.update_elevator(pos, name, tAttr)
	update_station(hyperloop.tDatabase.tElevators, pos, name, tAttr)
	hyperloop.tDatabase.elevator_chng_cnt = hyperloop.tDatabase.elevator_chng_cnt + 1
end

function hyperloop.delete_station(pos)
	delete_station(hyperloop.tDatabase.tStations, pos)
	hyperloop.tDatabase.station_chng_cnt = hyperloop.tDatabase.station_chng_cnt + 1
end

function hyperloop.delete_elevator(pos)
	delete_station(hyperloop.tDatabase.tElevators, pos)
	hyperloop.tDatabase.elevator_chng_cnt = hyperloop.tDatabase.elevator_chng_cnt + 1
end

function hyperloop.update_station_conn_table(pos, out_dir, conn_pos)
	if update_conn_table(hyperloop.tDatabase.tStations, pos, out_dir, conn_pos) then
		hyperloop.tDatabase.station_chng_cnt = hyperloop.tDatabase.station_chng_cnt + 1
	end
end	

function hyperloop.update_elevator_conn_table(pos, out_dir, conn_pos)
	if update_conn_table(hyperloop.tDatabase.tElevators, pos, out_dir, conn_pos) then
		hyperloop.tDatabase.elevator_chng_cnt = hyperloop.tDatabase.elevator_chng_cnt + 1
	end
end	

function hyperloop.get_elevator(pos)
	local sKey = S(pos)
	if hyperloop.tDatabase.tElevators[sKey] then
		local item = table.copy(hyperloop.tDatabase.tElevators[sKey])
		if item then
			item.pos = pos
			return item
		end
	end
end

function hyperloop.get_station(pos)
	local sKey = S(pos)
	if hyperloop.tDatabase.tStations[sKey] then
		local item = table.copy(hyperloop.tDatabase.tStations[sKey])
		if item then
			item.pos = pos
			return item
		end
	end
end

---- Return a table with all network nodes (stations/junctions), 
---- the given 'pos' belongs too.
function hyperloop.get_station_table(pos)
	local tRes = {}
	local sKey = S(pos)
	return get_stations(hyperloop.tDatabase.tStations, sKey, tRes)
end

---- Return a table with all elevator nodes, 
---- the given 'pos' belongs too.
function hyperloop.get_elevator_table(pos)
	local tRes = {}
	local sKey = S(pos)
	return get_stations(hyperloop.tDatabase.tElevators, sKey, tRes)
end

-- Return a list with sorted elevators
function hyperloop.sort_based_on_level(tStations)
	local lStations = table_to_list(table.copy(tStations))
	table.sort(lStations, function(a,b) return a.pos.y > b.pos.y end)
	return lStations
end
	
-- Return a list with sorted stations
function hyperloop.sort_based_on_distance(tStations, pos)
	local lStations = table_to_list(tStations)
	lStations = add_distance_to_list(lStations, pos)
	table.sort(lStations, function(a,b) return a.distance < b.distance end)
	return lStations
end
