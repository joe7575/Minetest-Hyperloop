--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local PI = 3.1415926

function table_extend(table1, table2)
	for k,v in pairs(table2) do 
		if (type(table1[k]) == 'table' and type(v) == 'table') then
			table_extend(table1[k], v)
		else
			table1[k] = v 
		end
	end
end


hyperloop.NeighborPos = {
	{ x=1,  y=0,  z=0},
	{ x=-1, y=0,  z=0},
	{ x=0,  y=1,  z=0},
	{ x=0,  y=-1, z=0},
	{ x=0,  y=0,  z=1},
	{ x=0,  y=0,  z=-1},
}

function hyperloop.rad2facedir(yaw)
	-- radiant (0..2*PI) to my facedir (0..3) from N, W, S to E
	return math.floor((yaw + PI/4) / PI * 2) % 4
end

function hyperloop.facedir2rad(facedir)
	-- my facedir (0..3) from N, W, S to E to radiant (0..2*PI)
	return facedir / 2 * PI
end

function hyperloop.facedir2dir(facedir)
	-- my facedir (0..3) from N, W, S to E to dir vector
	local tbl = {
		[0] = { x=0,  y=0, z=1},
		[1] = { x=-1, y=0, z=0},
		[2] = { x=0,  y=0, z=-1},
		[3] = { x=1,  y=0, z=0},
	}
	return tbl[facedir % 4]
end

function hyperloop.turnright(dir)
	local facedir = minetest.dir_to_facedir(dir)
	return minetest.facedir_to_dir((facedir + 1) % 4)
end

function hyperloop.turnleft(dir)
	local facedir = minetest.dir_to_facedir(dir)
	return minetest.facedir_to_dir((facedir + 3) % 4)
end

-- File writing / reading utilities
local wpath = minetest.get_worldpath()

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

function hyperloop.store_station_list()
	hyperloop.table2file("hyperloop_station_list", hyperloop.tAllStations)
end

-- distance between two points in (tube) blocks
function hyperloop.distance(pos1, pos2)
	if type(pos1) == "string" then
		pos1 = minetest.string_to_pos(pos1)
	end
	if type(pos2) == "string" then
		pos2 = minetest.string_to_pos(pos2)
	end
	pos1 = vector.floor(pos1)
	pos2 = vector.floor(pos2)
	return math.abs(pos1.x - pos2.x) + math.abs(pos1.y - pos2.y) + math.abs(pos1.z - pos2.z) - 2
end

-- Return true if both blocks given bei string-positions are nearby
function hyperloop.nearby(pos1, pos2)
	pos1 = minetest.string_to_pos(pos1)
	pos2 = minetest.string_to_pos(pos2)
	local pos = vector.subtract(pos1, pos2)
	local res = pos.x + pos.y + pos.z
	return res == 1 or res == -1
end

-- Scan for nodes with the given name in the surrounding
function hyperloop.scan_for_nodes(pos, name)
	local nodes = {}
	local node, npos
	local res = 0
	for _,dir in ipairs(hyperloop.NeighborPos) do
		npos = vector.add(pos, dir)
		node = minetest.get_node(npos)
		if node.name == name then
			node.pos = npos
			table.insert(nodes, node)
			res = res + 1
		end
	end
	return res, nodes
end

function hyperloop.is_player_around(pos)
	for _,obj in ipairs(minetest.get_objects_inside_radius(pos, 2)) do
		if obj:is_player() then
			return true
		end
	end
	return false
end

-------------------------------------------------------------------------------
---- Station maintenance
-------------------------------------------------------------------------------
-- Return station name, which matches the given retoure route
local function get_peer_station(tStations, rev_route)
	for station, dataSet in pairs(tStations) do
		for _,route in ipairs(dataSet["routes"]) do
			if rev_route[1] == route[1] and rev_route[2] == route[2] then
				return station
			end
		end
	end
end

-- Return a table with all station names, the given 'sStation' is connected with
-- tRes is used for the resulting table (recursive call)
local function get_stations(tStations, sStation, tRes)
	if tStations[sStation] == nil then
		return nil
	end
	local dataSet = table.copy(tStations[sStation])
	if dataSet == nil then
		return nil
	end
	tStations[sStation] = nil
	for _,route in ipairs(dataSet["routes"]) do
		local rev_route = {route[2], route[1]}
		local s = get_peer_station(tStations, rev_route)
		if s ~= nil then
			tRes[#tRes + 1] = s
			get_stations(tStations, s, tRes)
		end
	end
	return tRes
end

-- Return a table with all network station names, the given 'sStation' belongs too
function hyperloop.get_network_stations(sStation)
	local tRes = {}
	local tStations = table.copy(hyperloop.tAllStations)
	local tOut = {}
	for _,name in ipairs(get_stations(tStations, sStation, tRes)) do
		if hyperloop.tAllStations[name].seat == true then
			tOut[#tOut+1] = name
		end
	end
	return tOut
end
	
-- Return a table with all station names, the given 'sStation' is directly connected with
function hyperloop.get_connections(sStation)
	local tRes = {}
	local dataSet = hyperloop.tAllStations[sStation]
	if dataSet == nil then
		return nil
	end
	for _,route in ipairs(dataSet["routes"]) do
		local rev_route = {route[2], route[1]}
		local s = get_peer_station(hyperloop.tAllStations, rev_route)
		if s ~= nil then
			tRes[#tRes + 1] = s
		end
	end
	return tRes
end
	
-- Return the networks table with all station names per network
function hyperloop.get_networks()
	local tNetwork = {}
	local tStations = table.copy(hyperloop.tAllStations)
	local sStation,_ = next(tStations, nil) 
	while sStation ~= nil do
		tNetwork[#tNetwork+1] = get_stations(tStations, sStation, {sStation})
		sStation,_ = next(tStations, nil) 
	end
	return tNetwork
end


-------------------------------------------------------------------------------
---- Station reservation/blocking
-------------------------------------------------------------------------------

-- reserve departure and arrival stations for some time
function hyperloop.reserve(departure, arrival)
	if hyperloop.tAllStations[departure] == nil then
		return false
	elseif hyperloop.tAllStations[arrival] == nil then
		return false
	else
		local t1 = hyperloop.tAllStations[departure].time_blocked or 0
		local t2 = hyperloop.tAllStations[arrival].time_blocked or 0
		
		if t1 > minetest.get_gametime() then
			return false
		elseif t2 > minetest.get_gametime() then
			return false
		else
			-- place a reservation for 20 seconds to start the trip
			hyperloop.tAllStations[departure].time_blocked = minetest.get_gametime() + 20
			hyperloop.tAllStations[arrival].time_blocked = minetest.get_gametime() + 20
			if hyperloop.debugging then
				print(departure.." and ".. arrival.." stations are reserved")
			end
			return true
		end
	end
end

-- block the already reserved stations
function hyperloop.block(departure, arrival, seconds)
	if hyperloop.tAllStations[departure] == nil then
		return false
	elseif hyperloop.tAllStations[arrival] == nil then
		return false
	else
		hyperloop.tAllStations[departure].time_blocked = minetest.get_gametime() + seconds
		hyperloop.tAllStations[arrival].time_blocked = minetest.get_gametime() + seconds
		if hyperloop.debugging then
			print(departure.." and ".. arrival.." stations are blocked")
		end
		return true
	end
end

-- check if station is blocked
function hyperloop.is_blocked(station)
	if hyperloop.tAllStations[station] == nil then
		return false
	else
		local t = hyperloop.tAllStations[station].time_blocked or 0
		print(t, minetest.get_gametime())
		return t > minetest.get_gametime()
	end
end

-- Store and read the station list to / from a file
-- so that upcoming actions are remembered when the game
-- is restarted
hyperloop.tAllStations = hyperloop.file2table("hyperloop_station_list")

minetest.register_on_shutdown(hyperloop.store_station_list)

-- store ring list once a day
minetest.after(60*60*24, hyperloop.store_station_list)



