--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

-- Check data base and remove invalid entries
local function check_station_data()
	local tRes = {}
	local node
	for key,item in pairs(table.copy(hyperloop.data.tAllStations)) do
		if item.pos ~= nil then
			node = minetest.get_node(item.pos)
			if node ~= nil then
				if node.name == "hyperloop:station" or node.name == "hyperloop:junction" or node.name == "ignore" then
					-- valid data
					tRes[key] = item
				else -- node removed via WorldEdit?
					print("[Hyperloop] "..key..": "..node.name.." is no station")
				end
			else -- unloaded?
				print("[Hyperloop] "..key..": node is nil")
				-- probably valid data
				tRes[key] = item
			end
		else
			-- invalid data
			print("[Hyperloop] "..key..": item.pos == nil")
		end
	end
	hyperloop.data.tAllStations = tRes
end


-- Return a text block with all station names and their attributes
local function station_list_as_string(pos)
	local sortedList = {}
	local distance = 0
	for key_str, dataSet in pairs(table.copy(hyperloop.data.tAllStations)) do
		distance = hyperloop.distance(pos, dataSet["pos"])
		dataSet.distance = distance
		dataSet.key_str = key_str
		sortedList[#sortedList+1] = dataSet
	end
	table.sort(sortedList, function(x,y) 
			return x.distance < y.distance
		end)
	if hyperloop.debugging then
		print("tAllStations="..dump(sortedList))
		print("tWifi="..dump(hyperloop.data.tWifi))
	end
	local tRes = {"label[0,0;Dist.]label[1.1,0;Station/Junction]label[2.9,0;Position]"..
		          "label[4.9,0;State]label[6.4,0;Owner]label[8,0;Directly connected with]"}
	local state, owner
	for idx,dataSet in ipairs(sortedList) do
		if idx == 18 then
			break
		end
		local ypos = 0.2 + idx * 0.4
		if dataSet.station_name ~= nil then
			state = "Station"
		elseif dataSet.junction == true then
			dataSet.station_name = "<no name>"
			state = "Junction"
		else
			dataSet.station_name = "<no name>"
			state = "No Booking M."
		end
		if dataSet.owner ~= nil then
			owner = dataSet.owner
		else
			owner = "unknown"
		end
		tRes[#tRes+1] = "label[0,"..ypos..";"..dataSet.distance.." m]"
		tRes[#tRes+1] = "label[1.1,"..ypos..";"..dataSet.station_name.."]"
		tRes[#tRes+1] = "label[2.9,"..ypos..";"..minetest.pos_to_string(dataSet.pos).."]"
		tRes[#tRes+1] = "label[4.9,"..ypos..";"..state.."]"
		tRes[#tRes+1] = "label[6.4,"..ypos..";"..owner.."]"
		tRes[#tRes+1] = "label[8,"..ypos..";"
		for _,key_str in ipairs(hyperloop.get_connections(dataSet.key_str)) do
			if hyperloop.data.tAllStations[key_str].station_name ~= nil then
				tRes[#tRes + 1] = hyperloop.data.tAllStations[key_str].station_name
			else
				tRes[#tRes + 1] = key_str
			end
			tRes[#tRes + 1] = ", "
		end
		tRes[#tRes] = "]"
	end
	return table.concat(tRes)
end


local function map_on_use(itemstack, user)
	check_station_data()
	local player_name = user:get_player_name()
	--local pos = user:get_pos()
	local pos = user:getpos()
	local sStationList = station_list_as_string(pos)
	local formspec = "size[12,10]" .. default.gui_bg ..
	default.gui_bg_img ..
	sStationList ..
	"button_exit[5,9.5;2,1;close;Close]"

	minetest.show_formspec(player_name, "hyperloop:station_map", formspec)
	return itemstack
end

-- Tool for tube workers to find the next station
minetest.register_node("hyperloop:station_map", {
	description = "Hyperloop Station Book",
	inventory_image = "hyperloop_stations_book.png",
	wield_image = "hyperloop_stations_book.png",
	groups = {cracky=1, book=1},
	on_use = map_on_use,
	on_place = map_on_use,
})

