--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

function hyperloop.update_junction(pos)
	local node = minetest.get_node(pos)
	if node.name ~= "ignore" then   -- node loaded?
		local res, nodes = hyperloop.scan_for_nodes(pos, "hyperloop:junction")
		-- we use this for loop, knowing that max. one junction will be found
		for _,node in ipairs(nodes) do
			minetest.registered_nodes["hyperloop:junction"].update(node.pos)
		end
	end
	hyperloop.change_counter = hyperloop.change_counter + 1
end	

local function default_name(pos)
	pos = minetest.pos_to_string(pos)
	return '"'..string.sub(pos, 2, -2)..'"'
end

local function store_routes(pos, owner)
	local meta = minetest.get_meta(pos)
	local station_name = meta:get_string("station_name")
	if station_name ~= nil and station_name ~= "" then
		local res, nodes = hyperloop.scan_neighbours(pos)
		-- generate a list with all tube heads
		local tRoutes = {}
		for _,node in ipairs(nodes) do
			if node.name == "hyperloop:tube1" then
				local peer = minetest.get_meta(node.pos):get_string("peer")
				local route = {minetest.pos_to_string(node.pos), peer}
				table.insert(tRoutes, route)
			end
		end
		-- store list
		local spos = minetest.pos_to_string(pos)
		if hyperloop.tAllStations[station_name] == nil then
			-- add a new station
			hyperloop.tAllStations[station_name] = {pos=spos, routes=tRoutes, time_blocked=0}
		else
			hyperloop.tAllStations[station_name].routes = tRoutes
		end
		if owner ~= nil then
			hyperloop.tAllStations[station_name].owner = owner:get_player_name()
		end
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
			meta:set_string("station_name", default_name(pos))
			meta:set_string("infotext", "Station "..default_name(pos))
			meta:set_string("formspec", formspec)
			store_routes(pos, placer)
			--hyperloop.update_all_booking_machines()
		end,

		on_receive_fields = function(pos, formname, fields, player)
			if fields.name == nil then
				return
			end
			local station_name = string.trim(fields.name)
			if station_name == "" then
				return
			end
			-- delete temp name
			hyperloop.tAllStations[default_name(pos)] = nil
			-- check if station already available
			local spos = minetest.pos_to_string(pos)
			if hyperloop.tAllStations[station_name] ~= nil 
			and hyperloop.tAllStations[station_name]["pos"] ~= spos then
				minetest.chat_send_player(player:get_player_name(), 
					"[Hyperloop] Error: Station name already assigned!")
				return
			end
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", nil)
			meta:set_string("station_name", station_name)
			meta:set_string("infotext", "Station '"..station_name.."'")
			store_routes(pos, player)
			--hyperloop.update_all_booking_machines()
		end,

		on_destruct = function(pos)
			-- delete station data
			local meta = minetest.get_meta(pos)
			local station_name = meta:get_string("station_name")
			if hyperloop.tAllStations[station_name] ~= nil then
				hyperloop.tAllStations[station_name] = nil
				--hyperloop.update_all_booking_machines()
			end
		end,

		-- called from tube head blocks
		update = function(pos)
			if hyperloop.debugging then
				print("Junction update() called")
			end
			store_routes(pos, nil)
		end,

		paramtype2 = "facedir",
		groups = {cracky=2},
		is_ground_content = false,
	})

minetest.register_lbm({
	label = "[Hyperloop] Junction update",
	name = "hyperloop:update",
	nodenames = {"hyperloop:junction"},
	run_at_every_load = true,
	action = function(pos, node)
		if hyperloop.debugging then
			print("Junction loaded")
		end
		store_routes(pos, nil)
	end
})

