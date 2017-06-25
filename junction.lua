--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local function store_routes(pos)
	local meta = minetest.get_meta(pos)
	local station_name = meta:get_string("station_name")
	print("station_name="..station_name)
	if station_name ~= nil and station_name ~= "" then
		local res, nodes = hyperloop.scan_neighbours(pos)
		-- generate a list with all tube heads
		local tRoutes = {}
		for _,node in ipairs(nodes) do
			print(node.name)
			if node.name == "hyperloop:tube1" then
				local peer = minetest.get_meta(node.pos):get_string("peer")
				local route = {minetest.pos_to_string(node.pos), peer}
				--print(dump(route))
				table.insert(tRoutes, route)
			end
		end
		-- store list
		local spos = minetest.pos_to_string(pos)
		hyperloop.tAllStations[station_name] = {pos=spos, routes=tRoutes}
	end
end

minetest.register_node("hyperloop:junction", {
		description = "Hyperloop Junction Block",
		tiles = {"hyperloop_station.png"},

		after_place_node = function(pos, placer, itemstack, pointed_thing)
			local meta = minetest.get_meta(pos)
			local formspec = "size[5,4]"..
			"label[0,0;Please insert station name]" ..
			"field[1,1.5;3,1;name;Name;MyTown]" ..
			"button_exit[1,2;2,1;exit;Save]"
			meta:set_string("formspec", formspec)
		end,

		on_receive_fields = function(pos, formname, fields, player)
			if fields.name == nil then
				return
			end
			local station_name = string.trim(fields.name)
			if station_name == "" then
				return
			end
			-- check if station already available
			local spos = minetest.pos_to_string(pos)
			if hyperloop.tAllStations[station_name] ~= nil 
			and hyperloop.tAllStations[station_name]["pos"] ~= spos then
				minetest.chat_send_player(player:get_player_name(), 
					"Error: Station name already assigned!")
				return
			end
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", nil)
			meta:set_string("station_name", station_name)
			meta:set_string("infotext", "Station '"..station_name.."'")
			store_routes(pos)
		end,

		on_destruct = function(pos)
			-- delete station data
			local meta = minetest.get_meta(pos)
			local station_name = meta:get_string("station_name")
			if hyperloop.tAllStations[station_name] ~= nil then
				hyperloop.tAllStations[station_name] = nil
			end
		end,

		-- called from tube head blocks
		update = function(pos)
			if hyperloop.debugging then
				print("Junction update() called")
			end
			store_routes(pos)
		end,

		paramtype2 = "facedir",
		groups = {cracky=2},
		is_ground_content = false,
	})


