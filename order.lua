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
	
	local tRes = {"size[10,9]label[3,0;Wähle dein Ziel / Select your destination]"}
	for idx,s in ipairs(stations) do
		if idx < 9 then
			pos1 = "0,"..idx
			pos2 = "3,"..idx
		else
			pos1 = "6,"..(idx-8)
			pos2 = "9,"..(idx-8)
		end
		tRes[#tRes + 1] = "label["..pos1..".2;"..s.."]"
		tRes[#tRes + 1] = "button_exit["..pos2..";1,1;h;X]"
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
				local station_name = fields.name
				print(station_name)
				meta:set_string("station_name", station_name)
				local s = final_formspec(station_name)
				if s == nil then 
					minetest.chat_send_player(player:get_player_name(), "Error: Invalid station name!")
				else
					meta:set_string("formspec", s)
					if hyperloop.tAllStations ~= nil and hyperloop.tAllStations[station_name] ~= nil then
						local tmp = hyperloop.tAllStations[station_name]["pos"]
						hyperloop.tAllStations[station_name]["order"] = pos
						meta:set_string("station_pos", tmp)
					end
				end
			else
			end
		end,

		on_destruct = function(pos)
			local meta = minetest.get_meta(pos)
			local station_name = meta:get_string("station_name")
			hyperloop.tAllStations[station_name]["order"] = nil
		end,

		on_punch = function(pos)
			local meta = minetest.get_meta(pos)
			local station_name = meta:get_string("station_name")
			local s = final_formspec(station_name)
			meta:set_string("formspec", s)
		end,
		
		paramtype2 = "facedir",
		groups = {cracky=2},
		is_ground_content = false,
	})



