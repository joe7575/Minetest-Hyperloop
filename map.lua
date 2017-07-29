--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

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
	local tRes = {"label[0,0;Dist.]label[0.9,0;Station/Junction]label[2.7,0;Position]"..
		          "label[4.7,0;State]label[6.2,0;Owner]label[7.8,0;Directly connected with]"}
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
		tRes[#tRes+1] = "label[0.9,"..ypos..";"..dataSet.station_name.."]"
		tRes[#tRes+1] = "label[2.7,"..ypos..";"..minetest.pos_to_string(dataSet.pos).."]"
		tRes[#tRes+1] = "label[4.7,"..ypos..";"..state.."]"
		tRes[#tRes+1] = "label[6.2,"..ypos..";"..owner.."]"
		tRes[#tRes+1] = "label[7.8,"..ypos..";"
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
	local player_name = user:get_player_name()
	--local pos = user:get_pos()
	local pos = user:getpos()
	local sStationList = station_list_as_string(pos)
	local formspec = "size[12,10]" .. default.gui_bg ..
	default.gui_bg_img ..
	"textarea[0.5,0.5;9.5,8;text;Station List:;" ..
	sStationList .. "]" ..
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

