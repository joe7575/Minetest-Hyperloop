--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--



local function final_formspec(name)
	local stations = hyperloop.get_stations(table.copy(hyperloop.tAllStations), name, {})
	if stations == nil then
		return nil
	end
	table.sort(stations)
	local tRes = {"size[10,9]label[2,0; Abfahrt ".. name ..": Wähle dein Ziel\nDeparture ".. name .. ": Select your destination]"}
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
			if fields.name ~= nil then
				if hyperloop.tAllStations ~= nil and hyperloop.tAllStations[fields.name] ~= nil then
					local station_pos = minetest.string_to_pos(hyperloop.tAllStations[fields.name].pos)
					if hyperloop.distance(pos, station_pos) > 30 then
						minetest.chat_send_player(player:get_player_name(), "Error: station too far away!")
						return
					end
					hyperloop.tAllStations[fields.name]["automat_pos"] = pos
					meta:set_string("station_name", fields.name)
					meta:set_string("infotext", "Station: "..fields.name)
					meta:set_string("formspec", final_formspec(fields.name))
				else
					minetest.chat_send_player(player:get_player_name(), "Error: Invalid station name!")
				end
			elseif fields.button ~= nil then
				local station_name = meta:get_string("station_name")
				local stations = hyperloop.get_stations(table.copy(hyperloop.tAllStations), station_name, {})
				table.sort(stations)
				-- place order
				local idx = tonumber(fields.button)
				print(station_name .. ":" .. stations[idx])
				hyperloop.order[station_name] = stations[idx]
			end
		end,

		on_destruct = function(pos)
			local meta = minetest.get_meta(pos)
			local station_name = meta:get_string("station_name")
			if hyperloop.tAllStations ~= nil and hyperloop.tAllStations[station_name.name] ~= nil
			and hyperloop.tAllStations[station_name.name]["automat_pos"] ~= nil then
				hyperloop.tAllStations[station_name]["automat_pos"] = nil
			end
		end,
		
		on_punch = function(pos)
			local meta = minetest.get_meta(pos)
			local station_name = meta:get_string("station_name")
			meta:set_string("infotext", "Station: "..station_name)
			meta:set_string("formspec", final_formspec(station_name))
		end,
		
		paramtype2 = "facedir",
		groups = {cracky=2},
		is_ground_content = false,
	})



