--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

-- return a sorted list with station names from the same network as the given station
local function get_station_list(name)
	local stations = hyperloop.get_stations(table.copy(hyperloop.tAllStations), name, {})
	if stations == nil then
		return nil
	end
	table.sort(stations)
	return stations
end

-- Form spec for the station list
-- param name: local station name
-- param stations: station name list
local function formspec(name, stations)
	local tRes = {"size[10,9]label[2,0; Abfahrt ".. name ..": Wähle dein Ziel\nDeparture ".. 
		name .. ": Select your destination]"}
	local pos1, pos2
	for idx,s in ipairs(stations) do
		if idx < 9 then
			pos1 = "0,"..idx
			pos2 = "1,"..idx
		else
			pos1 = "5,"..(idx-8)
			pos2 = "6,"..(idx-8)
		end
		tRes[#tRes + 1] = "button_exit["..pos1..";1,1;button;"..idx.."]"
		tRes[#tRes + 1] = "label["..pos2..".2;"..s.."]"
	end
	return table.concat(tRes)
end

minetest.register_node("hyperloop:order", {
		description = "Hyperloop Order Machine",
		tiles = {
			-- up, down, right, left, back, front
			"order.png",
			"order.png",
			"order.png",
			"order.png",
			"order.png",
			"order_front.png",
		},

		after_place_node = function(pos, placer, itemstack, pointed_thing)
			local meta = minetest.get_meta(pos)
			local formspec = "size[5,4]"..
			"label[0,0;Please insert station name to which this order machine belongs]" ..
			"field[1,1.5;3,1;name;Name;MyTown]" ..
			"button_exit[1,2;2,1;exit;Save]"
			meta:set_string("formspec", formspec)
		end,

		on_receive_fields = function(pos, formname, fields, player)
			local meta = minetest.get_meta(pos)
			-- station name entered?
			if fields.name ~= nil then
				local station_name = string.trim(fields.name)
				if station_name == "" then
					return
				end
				-- valid name entered?
				if hyperloop.tAllStations[station_name] ~= nil then
					if hyperloop.tAllStations[station_name]["automat_pos"] ~= nil then
						minetest.chat_send_player(player:get_player_name(), 
							"Error: Station already has an order automat!")
						return
					end
					-- check distance to the named station
					local station_pos = minetest.string_to_pos(hyperloop.tAllStations[station_name].pos)
					if hyperloop.distance(pos, station_pos) > 30 then
						minetest.chat_send_player(player:get_player_name(), "Error: station too far away!")
						return
					end
					-- store meta and generate station formspec
					local stations = get_station_list(station_name)
					hyperloop.tAllStations[station_name]["automat_pos"] = pos
					meta:set_string("station_name", station_name)
					meta:set_string("infotext", "Station: "..station_name)
					meta:set_string("formspec", formspec(station_name, stations))
				else
					minetest.chat_send_player(player:get_player_name(), "Error: Invalid station name!")
				end
			-- destination selected?
			elseif fields.button ~= nil then
				local station_name = meta:get_string("station_name")
				-- place order
				local idx = tonumber(fields.button)
				local destination = get_station_list(station_name)[idx]
				print(station_name .. ":" .. destination)
				hyperloop.order[station_name] = destination
			end
		end,

		on_destruct = function(pos)
			local meta = minetest.get_meta(pos)
			local station_name = meta:get_string("station_name")
			if hyperloop.tAllStations[station_name] ~= nil 
			and hyperloop.tAllStations[station_name]["automat_pos"] ~= nil then
				hyperloop.tAllStations[station_name]["automat_pos"] = nil
			end
		end,
		
		paramtype2 = "facedir",
		groups = {cracky=2},
		is_ground_content = false,
	})



