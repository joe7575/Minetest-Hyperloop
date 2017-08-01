--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--


--[[
	hyperloop.data.booking[departure_key_str] = arrival_key_str
]]--

function hyperloop.update_all_booking_machines()
	if hyperloop.debugging then
		print("update_all_booking_machines")
	end
	local t = minetest.get_us_time()
	for _, dataset in pairs(hyperloop.data.tAllStations) do
		if dataset.booking_pos ~= nil then
			minetest.registered_nodes["hyperloop:booking"].update(dataset.booking_pos)
			minetest.registered_nodes["hyperloop:booking_ground"].update(dataset.booking_pos)
		end
	end
	t = minetest.get_us_time() - t
	if hyperloop.debugging then
		print("time="..t)
	end
end


-- return sorted list of all network stations
local function get_station_list(key_str)	
	local tRes = {}
	local local_pos = hyperloop.data.tAllStations[key_str]["pos"]
	for idx,dest_key in ipairs(hyperloop.get_network_stations(key_str)) do
		if idx >= 12 then
			break
		end
		local dest_pos = hyperloop.data.tAllStations[dest_key]["pos"]
		tRes[#tRes+1] = {
			key_str = dest_key,
			info = hyperloop.data.tAllStations[dest_key]["booking_info"] or "",
			pos = dest_pos,
			name = hyperloop.data.tAllStations[dest_key]["station_name"],
			distance = hyperloop.distance(local_pos, dest_pos),
			pos_str = minetest.pos_to_string(dest_pos)
		}
	end
	table.sort(tRes, function(x,y)
			return x.distance < y.distance
		end)
	return tRes
end

-- check station name if unique, determine the nearest station and return key_str
local function valid_station_name(pos, station_name)
	local min_dist = 100
	local min_key = nil
	local dist, rmt_pos
	for key,item in pairs(hyperloop.data.tAllStations) do
		if item.station_name == station_name then
			return nil
		end
		dist = hyperloop.distance(pos, item.pos)
		if dist < min_dist then
			min_dist = dist
			min_key = key
		end
	end
	return min_key
end

local function naming_formspec(pos)
	local meta = minetest.get_meta(pos)
	local formspec = "size[6,4]"..
	"label[0,0;Please insert station name to which this booking machine belongs]" ..
	"field[0.5,1.5;5,1;name;Station name;MyTown]" ..
	"field[0.5,2.7;5,1;info;Additional station information;]" ..
	"button_exit[2,3.6;2,1;exit;Save]"
	meta:set_string("formspec", formspec)
	meta:set_int("change_counter", 0)
end

-- Form spec for the station list
-- param key_str: local station key
local function formspec(key_str)
	local tRes = {"size[12,10]label[3,0; Wähle dein Ziel :: Select your destination]"}
	tRes[2] = "label[1,0.6;Destination]label[3.5,0.6;Distance]label[5,0.6;Position]label[7,0.6;Local Info]"
	for idx,tDest in ipairs(get_station_list(key_str)) do
		if idx >= 12 then
			break
		end
		local ypos = 0.5 + idx*0.8
		local ypos2 = ypos - 0.2
		tRes[#tRes+1] = "button_exit[0,"..ypos2..";1,1;button;"..idx.."]"
		tRes[#tRes+1] = "label[1,"..ypos..";"..tDest.name.."]"
		tRes[#tRes+1] = "label[3.5,"..ypos..";"..tDest.distance.." m]"
		tRes[#tRes+1] = "label[4.7,"..ypos..";"..tDest.pos_str.."]"
		tRes[#tRes+1] = "label[7,"..ypos..";"..tDest.info.."]"
	end
	return table.concat(tRes)
end


local function on_receive_fields(pos, formname, fields, player)
	local meta = minetest.get_meta(pos)
	-- station name entered?
	if fields.name ~= nil then
		local station_name = string.trim(fields.name)
		if station_name == "" then
			return
		end
		-- valid name entered?
		local key_str = valid_station_name(pos, station_name)
		if key_str ~= nil then
			if hyperloop.data.tAllStations[key_str]["booking_pos"] ~= nil then
				hyperloop.chat(player, "Station has already a booking machine!")
				return
			end
			-- store meta and generate station formspec
			hyperloop.data.tAllStations[key_str]["booking_pos"] = pos
			hyperloop.data.tAllStations[key_str]["booking_info"] = string.trim(fields.info)
			hyperloop.data.tAllStations[key_str]["station_name"] = station_name
			meta:set_string("key_str", key_str)
			meta:set_string("infotext", "Station: "..station_name)
			meta:set_string("formspec", formspec(key_str))
			hyperloop.data.change_counter = hyperloop.data.change_counter + 1
		else
			hyperloop.chat(player, "Invalid station name!")
		end
	-- destination selected?
	elseif fields.button ~= nil then
		local key_str = meta:get_string("key_str")
		local idx = tonumber(fields.button)
		local tDest = get_station_list(key_str)[idx]
		-- place booking if not already blocked
		if hyperloop.reserve(key_str, tDest.key_str, player) then
			hyperloop.data.booking[key_str] = hyperloop.get_key_str(tDest.pos)
			-- open the pod door
			hyperloop.open_pod_door(hyperloop.get_station_data(key_str))
		end
	end
end
	
local function on_destruct(pos)
	local meta = minetest.get_meta(pos)
	local key_str = meta:get_string("key_str")
	if hyperloop.data.tAllStations[key_str] ~= nil 
	and hyperloop.data.tAllStations[key_str]["booking_pos"] ~= nil then
		hyperloop.data.tAllStations[key_str]["station_name"] = nil
		hyperloop.data.tAllStations[key_str]["booking_pos"] = nil
		hyperloop.data.tAllStations[key_str]["booking_info"] = nil
	end
	hyperloop.data.change_counter = hyperloop.data.change_counter + 1
end

local function update(pos)
	local meta = minetest.get_meta(pos)
	local key_str = meta:get_string("key_str")
	local stations = get_station_list(key_str)
	meta:set_string("formspec", formspec(key_str, stations))
end

-- wap from wall to ground 
local function swap_node(pos, placer)
	pos.y = pos.y - 1
	if minetest.get_node_or_nil(pos).name ~= "air" then
		local node = minetest.get_node(pos)
		node.name = "hyperloop:booking_ground"
		node.param2 = hyperloop.get_facedir(placer)
		pos.y = pos.y + 1
		minetest.swap_node(pos, node)
	else
		pos.y = pos.y + 1
	end
end

-- wall mounted booking machine
minetest.register_node("hyperloop:booking", {
	description = "Hyperloop Booking Machine",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_booking.png",
		"hyperloop_booking.png",
		"hyperloop_booking.png",
		"hyperloop_booking.png",
		"hyperloop_booking.png",
		"hyperloop_booking_front.png",
	},
	
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16, -8/16, 2/16,  8/16,  8/16, 8/16},
		},
	},
	
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		naming_formspec(pos)
		swap_node(pos, placer)
	end,

	on_receive_fields = on_receive_fields,
	on_destruct = on_destruct,
	update = update,

	paramtype = 'light',
	light_source = 2,
	paramtype2 = "facedir",
	groups = {cracky=2},
	is_ground_content = false,
})

-- ground mounted booking machine
minetest.register_node("hyperloop:booking_ground", {
	description = "Hyperloop Booking Machine",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_booking.png",
		"hyperloop_booking.png",
		"hyperloop_booking.png",
		"hyperloop_booking.png",
		"hyperloop_booking.png",
		"hyperloop_booking_front.png",
	},
	
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -8/16, -8/16, -3/16,  8/16,  8/16, 3/16},
		},
	},
	
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		naming_formspec(pos)
	end,

	on_receive_fields = on_receive_fields,
	on_destruct = on_destruct,
	update = update,
	drop = "hyperloop:booking",
	light_source = 2,
	paramtype = 'light',
	paramtype2 = "facedir",
	groups = {cracky=2, not_in_creative_inventory=1},
	is_ground_content = false,
})

minetest.register_abm({
	label = "[Hyperloop] Booking machine update",
	nodenames = {"hyperloop:booking", "hyperloop:booking_ground"},
	interval = 10.0, -- Run every 10 seconds
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)
		local counter = meta:get_int("change_counter") or 0
		if hyperloop.data.change_counter ~= counter then
			local key_str = meta:get_string("key_str") or nil
			if key_str ~= nil and hyperloop.data.tAllStations[key_str] ~= nil then
				local stations = get_station_list(key_str)
				meta:set_string("formspec", formspec(key_str, stations))
			end
			meta:set_int("change_counter", hyperloop.data.change_counter)
		end
	end
})

