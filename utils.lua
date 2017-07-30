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
	{ x= 0, y= 1, z= 0},
	{ x= 0, y=-1, z= 0},
	{ x= 1, y= 0, z= 0},
	{ x=-1, y= 0, z= 0},
	{ x= 0, y= 0, z= 1},
	{ x= 0, y= 0, z=-1},
}

function hyperloop.chat(player, text)
	if player ~= nil then
		minetest.chat_send_player(player:get_player_name(), "[Hyperloop] "..text)
	end
end

function hyperloop.get_facedir(placer)
	local lookdir = placer:get_look_dir()
	return core.dir_to_facedir(lookdir)
end

function hyperloop.facedir_to_rad(facedir)
	local tbl = {[0]=0, [1]=3, [2]=2, [3]=1}
	return tbl[facedir] / 2 * PI
end

-- calculate the new pos based on the given pos, the players facedir, the y-offset
-- and the given walk path like "3F2L" (F-orward, L-eft, R-ight, B-ack).
function hyperloop.new_pos(pos, facedir, path, y_offs)
	local _pos = table.copy(pos)
	_pos.y = _pos.y + y_offs
	while path:len() > 0 do
		local num = tonumber(path:sub(1,1))
		local dir = path:sub(2,2)
		path = path:sub(3)
		if dir == "B" then
			facedir = (facedir + 2) % 4
		elseif dir == "L" then
			facedir = (facedir + 3) % 4
		elseif dir == "R" then
			facedir = (facedir + 1) % 4
		end
		dir = core.facedir_to_dir(facedir)
		_pos = vector.add(_pos, vector.multiply(dir, num))
	end
	return _pos
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

-- Return a table with all station names, the given 'key_str' is connected with
-- tRes is used for the resulting table (recursive call)
local function get_stations(tStations, key_str, tRes)
	if tStations[key_str] == nil then
		return {}
	end
	local dataSet = table.copy(tStations[key_str])
	if dataSet == nil then
		return {}
	end
	tStations[key_str] = nil
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

-- Return a table with all network station names, the given 'key_str' belongs too
function hyperloop.get_network_stations(key_str)
	local tRes = {}
	local tStations = table.copy(hyperloop.data.tAllStations)
	local tOut = {}
	for _,name in ipairs(get_stations(tStations, key_str, tRes)) do
		if hyperloop.data.tAllStations[name].station_name ~= nil then
			tOut[#tOut+1] = name
		end
	end
	return tOut
end
	
-- Return a table with all station names, the given 'key_str' is directly connected with
function hyperloop.get_connections(key_str)
	local tRes = {}
	local dataSet = hyperloop.data.tAllStations[key_str]
	if dataSet == nil then
		return nil
	end
	for _,route in ipairs(dataSet["routes"]) do
		local rev_route = {route[2], route[1]}
		local s = get_peer_station(hyperloop.data.tAllStations, rev_route)
		if s ~= nil then
			tRes[#tRes + 1] = s
		end
	end
	return tRes
end
	
-- Return the networks table with all station names per network
function hyperloop.get_networks()
	local tNetwork = {}
	local tStations = table.copy(hyperloop.data.tAllStations)
	local key_str,_ = next(tStations, nil) 
	while key_str ~= nil do
		tNetwork[#tNetwork+1] = get_stations(tStations, key_str, {key_str})
		key_str,_ = next(tStations, nil) 
	end
	return tNetwork
end

function hyperloop.check_network_level(pos, player)
	for key,item in pairs(hyperloop.data.tAllStations) do
		if pos.y == item.pos.y then
			return
		end
	end
	hyperloop.chat(player, "These is no station/junction on this level. "..
						   "Do you realy want to start a new network?!")
end

-------------------------------------------------------------------------------
---- Station reservation/blocking
-------------------------------------------------------------------------------

-- reserve departure and arrival stations for some time
function hyperloop.reserve(departure, arrival)
	if hyperloop.data.tAllStations[departure] == nil then
		return false
	elseif hyperloop.data.tAllStations[arrival] == nil then
		return false
	else
		local t1 = hyperloop.data.tAllStations[departure].time_blocked or 0
		local t2 = hyperloop.data.tAllStations[arrival].time_blocked or 0
		
		if t1 > minetest.get_gametime() then
			return false
		elseif t2 > minetest.get_gametime() then
			return false
		else
			-- place a reservation for 20 seconds to start the trip
			hyperloop.data.tAllStations[departure].time_blocked = minetest.get_gametime() + 20
			hyperloop.data.tAllStations[arrival].time_blocked = minetest.get_gametime() + 20
			if hyperloop.debugging then
				print(departure.." and ".. arrival.." stations are reserved")
			end
			return true
		end
	end
end

local function get_key_str(pos)
	pos = minetest.pos_to_string(pos)
	return '"'..string.sub(pos, 2, -2)..'"'
end

-- block the already reserved stations
function hyperloop.block(departure, arrival, seconds)
	if hyperloop.data.tAllStations[departure] == nil then
		return false
	elseif hyperloop.data.tAllStations[arrival] == nil then
		return false
	else
		hyperloop.data.tAllStations[departure].time_blocked = minetest.get_gametime() + seconds
		hyperloop.data.tAllStations[arrival].time_blocked = minetest.get_gametime() + seconds
		if hyperloop.debugging then
			print(departure.." and ".. arrival.." stations are blocked")
		end
		return true
	end
end

-- check if station is blocked
function hyperloop.is_blocked(key_str)
	if hyperloop.data.tAllStations[key_str] == nil then
		return false
	else
		local t = hyperloop.data.tAllStations[key_str].time_blocked or 0
		return t > minetest.get_gametime()
	end
end

-------------------------------------------------------------------------------
---- Station File writing / reading utilities
-------------------------------------------------------------------------------
local wpath = minetest.get_worldpath()

-- Convert legacy data
local function convert_station_list(tAllStations)
	tRes = {}
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
	