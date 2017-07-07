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
	for name, dataSet in pairs(table.copy(hyperloop.tAllStations)) do
		distance = hyperloop.distance(pos, minetest.string_to_pos(dataSet["pos"]))
		dataSet.name = name
		dataSet.distance = distance
		sortedList[#sortedList+1] = dataSet
	end
	table.sort(sortedList, function(x,y) 
			return x.distance < y.distance
		end)
	if hyperloop.debugging then
		print("tAllStations="..dump(sortedList))
		print("tWifi="..dump(hyperloop.tWifi))
	end
	--local tRes = {"(player distance: station name (position) seat/machine/owner  =>  directly connected with)\n\n"}
	local tRes = {"size[10,10]label[0,0;Dist.]label[0.8,0;Station]label[2.5,0;Position]label[4.2,0;State]label[5.7,0;Owner]label[7.1,0;Connected with]"}
	local state, owner
	for idx,dataSet in ipairs(sortedList) do
		if idx == 18 then
			break
		end
		ypos = 0.2 + idx * 0.4
		if dataSet.seat == true and dataSet.booking_pos ~= nil then
			state = "completed"
		elseif dataSet.seat == true then
			state = "no Booking M."
		else
			state = "no Pod Seat"
		end
		if dataSet.owner ~= nil then
			owner = dataSet.owner
		else
			owner = "unknown"
		end
		tRes[#tRes+1] = "label[0,"..ypos..";"..dataSet.distance.." m]"
		tRes[#tRes+1] = "label[0.8,"..ypos..";"..dataSet.name.."]"
		tRes[#tRes+1] = "label[2.5,"..ypos..";"..dataSet.pos.."]"
		tRes[#tRes+1] = "label[4.2,"..ypos..";"..state.."]"
		tRes[#tRes+1] = "label[5.7,"..ypos..";"..owner.."]"
		tRes[#tRes+1] = "label[7.1,"..ypos..";"
		for _,s in ipairs(hyperloop.get_connections(dataSet.name)) do
			tRes[#tRes + 1] = s
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
	local formspec = "size[10,8]" .. default.gui_bg ..
	default.gui_bg_img ..
	"textarea[0.5,0.5;9.5,8;text;Station List:;" ..
	sStationList .. "]" ..
	"button_exit[4,7.5;2,1;close;Close]"

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

