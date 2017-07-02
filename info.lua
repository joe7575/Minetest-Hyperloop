--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local function on_rightclick(pos, node, clicker, itemstack, pointed_thing)	
	print("on_rightclick "..dump(pos))
	local player_name = clicker:get_player_name()
	local meta = minetest.get_meta(pos)
	local station_name = meta:get_string("station_name") or ""
	local short_info = meta:get_string("short_info") or ""
	local long_info = meta:get_string("long_info") or ""
	local formspec = "size[8,8]"..
	"label[3,0;Information Block]" ..
	"field[0.5,1.2;7.5,1;name;Station Name;"..station_name.."]" ..
	"field[0.5,2.5;7.5,1;short_info;Short information for Booking Maschines about this area;"..short_info.."]" ..
	"textarea[0.5,3.5;7.5,4;long_info;Long information for local visitors;"..long_info.."]"..
	"button_exit[3,7;2,1;exit;Save]"
	minetest.show_formspec(player_name, "hyperloop:info", formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "hyperloop:info" then
		return
	end	
	print("on_receive_fields "..dump(pos))
	local meta = minetest.get_meta(pos)
	-- station name entered?
	if fields.name ~= nil then
		local station_name = string.trim(fields.name)
		if station_name == "" then
			return
		end
		-- valid name entered?
		if hyperloop.tAllStations[station_name] ~= nil then
			if hyperloop.tAllStations[station_name]["înfo"] ~= nil then
				minetest.chat_send_player(player:get_player_name(), 
					"[Hyperloop] Error: Station already has an Info Block!")
				return
			end
			-- check distance to the named station
			local station_pos = minetest.string_to_pos(hyperloop.tAllStations[station_name].pos)
			if hyperloop.distance(pos, station_pos) > 30 then
				minetest.chat_send_player(player:get_player_name(), "[Hyperloop] Error: station too far away!")
				return
			end
			-- store meta and generate station formspec
			hyperloop.tAllStations[station_name]["info"] = fields.short_info
			meta:set_string("station_name", station_name)
			meta:set_string("short_info", fields.short_info)
			meta:set_string("long_info", fields.long_info)
			meta:set_string("infotext", fields.long_info)
			--hyperloop.update_all_booking_machines()
		else
			minetest.chat_send_player(player:get_player_name(), "[Hyperloop] Error: Invalid station name!")
		end
	end
end

minetest.register_node("hyperloop:info", {
		description = "Hyperloop Info Block",
		tiles = {
			-- up, down, right, left, back, front
			"hyperloop_booking.png",
			"hyperloop_booking.png",
			"hyperloop_info.png",
			"hyperloop_info.png",
			"hyperloop_info.png",
			"hyperloop_info.png",
		},

		on_rightclick = on_rightclick,
		on_receive_fields = on_receive_fields,
		
		on_destruct = function(pos)
			local meta = minetest.get_meta(pos)
			local station_name = meta:get_string("station_name")
			if hyperloop.tAllStations[station_name] ~= nil 
			and hyperloop.tAllStations[station_name]["info"] ~= nil then
				hyperloop.tAllStations[station_name]["info"] = nil
				--hyperloop.update_all_booking_machines()
			end
		end,

		light_source = 2,
		paramtype2 = "facedir",
		groups = {cracky=2},
		is_ground_content = false,
	})



