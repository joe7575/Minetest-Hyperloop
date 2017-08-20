--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--


local function enter_display(tStation, text)
    -- determine position
	if tStation ~= nil then
		local lcd_pos = hyperloop.new_pos(tStation.pos, tStation.facedir, "1F", 2)
		-- load map
		minetest.forceload_block(lcd_pos)
		-- update display
		minetest.registered_nodes["hyperloop:lcd"].update(lcd_pos, text) 
	end
end

local function on_final_close_door(tStation)
	-- close the door and play sound if no player is around
	if hyperloop.is_player_around(tStation.pos) then
		-- try again later
		minetest.after(3.0, on_final_close_door, tStation)
	else
		hyperloop.close_pod_door(tStation)
		enter_display(tStation, " |  | << Hyperloop >> | be anywhere")
	end
end

local function on_open_door(tArrival)
	-- open the door and play sound
	local meta = minetest.get_meta(tArrival.pos)
	meta:set_int("arrival_time", 0) -- finished
	-- open door
	hyperloop.open_pod_door(tArrival)
	-- prepare dislay for the next trip
	enter_display(tArrival, "Thank you | for | travelling | with | Hyperloop.")
	minetest.after(5.0, on_final_close_door, tArrival, tArrival.facedir)
end

local function on_arrival(tDeparture, tArrival, player, snd)
	-- activate display
	local text = " | Welcome at | | "..string.sub(tArrival.station_name, 1, 13)
	enter_display(tArrival, text)
	-- stop timer
	minetest.get_node_timer(tDeparture.pos):stop()
	-- move player to the arrival station
	if player ~= nil then
		local pos = table.copy(tArrival.pos)
		pos.y = pos.y + 1
		player:setpos(pos)
		-- rotate player to look in correct arrival direction
		-- calculate the look correction
		local offs = hyperloop.facedir_to_rad(tDeparture.facedir) - player:get_look_horizontal()
		local yaw = hyperloop.facedir_to_rad(tArrival.facedir) - offs
		player:set_look_yaw(yaw)
	end
	-- play arrival sound
	minetest.sound_stop(snd)
	minetest.sound_play("down2", {
			pos = tArrival.pos,
			gain = 0.5,
			max_hear_distance = 2
		})

	minetest.after(6.0, on_open_door, tArrival)
end

local function on_travel(tDeparture, tArrival, player, atime)
	-- play sound and switch door state
	local snd = minetest.sound_play("normal2", {
			pos = tDeparture.pos,
			gain = 0.5,
			max_hear_distance = 2,
			loop = true,
		})
	hyperloop.animate_pod_door(tDeparture)
	minetest.after(atime, on_arrival, tDeparture, tArrival, player, snd)
	minetest.after(atime, on_final_close_door, tDeparture)
end

local function display_timer(pos, elapsed)
	-- update display with trip data
	local meta = minetest.get_meta(pos)
	local key_str = meta:get_string("key_str")
	local tStation = hyperloop.get_station_data(key_str)
	local atime = meta:get_int("arrival_time") - 1
	if hyperloop.debugging then
		print("Timer".. atime)
	end
	meta:set_int("arrival_time", atime)
	local text = meta:get_string("lcd_text")
	if atime > 5 then
		enter_display(tStation, text..atime.." sec")
		return true
	else
		return false
	end
end

local function meter_to_km(dist)
	if dist < 1000 then
		return tostring(dist).." m"
	elseif dist < 10000 then
		return string.format("%.3f km", dist/1000)
	else
		return string.format("%.1f km", dist/1000)
	end
end

-- place the player, close the door, activate display
local function on_start_travel(pos, node, clicker)
	-- departure data
	local meta = minetest.get_meta(pos)
	local key_str = meta:get_string("key_str")
	local tDeparture = hyperloop.get_station_data(key_str)
	-- arrival data
	key_str = hyperloop.data.booking[tDeparture.key_str]
	if key_str == nil then
		minetest.chat_send_player(clicker:get_player_name(), "[Hyperloop] No booking entered!")
		return
	end
	local tArrival = hyperloop.get_station_data(key_str)
	-- delete booking
	hyperloop.data.booking[tDeparture.key_str] = nil
	if tArrival == nil then
		return
	end

	minetest.sound_play("up2", {
			pos = pos,
			gain = 0.5,
			max_hear_distance = 2
		})
	-- close the door at arrival station
	hyperloop.close_pod_door(tArrival)
	-- place player on the seat
	clicker:setpos(pos)
	-- rotate player to look in move direction
	clicker:set_look_horizontal(hyperloop.facedir_to_rad(tDeparture.facedir))

	-- activate display
	local dist = hyperloop.distance(pos, tArrival.pos) 
	local text = "Destination: | "..string.sub(tArrival.station_name, 1, 13).." | Distance: | "..
				 meter_to_km(dist).." | Arrival in: | "
	local atime
	if dist < 1000 then
		atime = 10 + math.floor(dist/200)		-- 10..15 sec
	elseif dist < 10000 then
		atime = 15 + math.floor(dist/600)		-- 16..32 sec
	else
		atime = 32								-- 32 sec is the maximum
	end
	enter_display(tDeparture, text..atime.." sec")

	-- block departure and arrival stations
	hyperloop.block(tDeparture.station_name, tArrival.station_name, atime+10)	

	-- store some data for on_timer()
	meta:set_int("arrival_time", atime)
	meta:set_string("lcd_text", text)
	minetest.get_node_timer(pos):start(1.0)
	hyperloop.close_pod_door(tDeparture)

	atime = atime - 9 -- substract start/arrival time
	minetest.after(4.9, on_travel, tDeparture, tArrival, clicker, atime)
end

-- Hyperloop Seat
minetest.register_node("hyperloop:seat", {
	description = "Hyperloop Pod Seat",
	tiles = {
		"hyperloop_seat-top.png",
		"hyperloop_seat-side.png",
		"hyperloop_seat-side.png",
		"hyperloop_seat-side.png",
		"hyperloop_seat-side.png",
		"hyperloop_seat-side.png",
	},
	drawtype = "nodebox",
	paramtype2 = "facedir",
	is_ground_content = false,
	walkable = false,
	drop = "",
	groups = {not_in_creative_inventory=1, crumbly=3},
	node_box = {
		type = "fixed",
		fixed = {
			{ -6/16, -8/16, -8/16,   6/16, -2/16, 5/16},
			{ -8/16, -8/16, -8/16,  -6/16,  4/16, 8/16},
			{  6/16, -8/16, -8/16,   8/16,  4/16, 8/16},
			{ -6/16, -8/16,  4/16,   6/16,  6/16, 8/16},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = { -8/16, -8/16, -8/16,   8/16, -2/16, 8/16 },
	},

	on_timer = display_timer,
	on_rightclick = on_start_travel,
	
	auto_place_node = function(pos, placer, facedir, key_str)
		local meta = minetest.get_meta(pos)
		meta:set_string("key_str", key_str)
	end,
})
