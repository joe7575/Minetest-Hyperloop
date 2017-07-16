--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

local function on_final_close_door(pos, facedir)
	-- close the door and play sound if no player is around
	if hyperloop.is_player_around(pos) then
		-- try again later
		minetest.after(3.0, on_final_close_door, pos, facedir)
	else
		hyperloop.door_command(pos, facedir, "close", nil)
	end
end

local function on_open_door(pos, facedir)
	-- open the door and play sound
	local meta = minetest.get_meta(pos)
	meta:set_int("arrival_time", 0) -- finished
	-- open door
	hyperloop.door_command(pos, facedir, "open", nil)
	-- prepare dislay for the next trip
	hyperloop.enter_display(pos, facedir, "Thank you | for | travelling | with | Hyperloop.")
	minetest.after(5.0, on_final_close_door, pos, facedir)
end

----------------------------------------------------------------------------------------------------
local function on_arrival(player, src_pos, src_facedir, dst_pos, snd, radiant)
	-- get pos from arrival station
	local meta = minetest.get_meta(dst_pos)
	local facedir = meta:get_int("facedir")

	-- activate display
	local station_name = meta:get_string("station_name")
	local text = " | Welcome at | | "..string.sub(station_name, 1, 13)
	hyperloop.enter_display(dst_pos, facedir, text)
	-- stop timer
	minetest.get_node_timer(src_pos):stop()
	-- move player to the arrival station
	if player ~= nil then
		player:setpos(dst_pos)
		-- rotate player to look in correct arrival direction
		-- calculate the look correction
		local offs = radiant - player:get_look_horizontal()
		local yaw = hyperloop.facedir2rad(facedir) - offs
		player:set_look_yaw(yaw)
	end
	-- play arrival sound
	minetest.sound_stop(snd)
	minetest.sound_play("down2", {
			pos = dst_pos,
			gain = 0.5,
			max_hear_distance = 10
		})

	minetest.after(6.0, on_open_door, dst_pos, facedir)
end

----------------------------------------------------------------------------------------------------
local function on_travel(src_pos, facedir, player, dst_pos, radiant, atime)
	-- play sound and switch door state
	-- radiant is the player look direction at departure
	local snd = minetest.sound_play("normal2", {
			pos = src_pos,
			gain = 0.5,
			max_hear_distance = 1,
			loop = true,
		})
	hyperloop.door_command(src_pos, facedir, "animate", nil)
	minetest.after(atime, on_arrival, player, src_pos, facedir, dst_pos, snd, radiant)
	minetest.after(atime, on_final_close_door, src_pos, facedir)
end

----------------------------------------------------------------------------------------------------
local function display_timer(pos, elapsed)
	-- update display with trip data
	local meta = minetest.get_meta(pos)
	local atime = meta:get_int("arrival_time") - 1
	if hyperloop.debugging then
		print("Timer".. atime)
	end
	meta:set_int("arrival_time", atime)
	local facedir = meta:get_int("facedir")
	local text = meta:get_string("lcd_text")
	if atime > 0 then
		hyperloop.enter_display(pos, facedir, text..atime.." sec")
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

----------------------------------------------------------------------------------------------------
-- place the player, close the door, activate display
local function on_start_travel(pos, node, clicker)
	-- local data
	local meta = minetest.get_meta(pos)
	local facedir = meta:get_int("facedir")
	local station_name = meta:get_string("station_name")
	if station_name == nil then
		print("[Hyperloop] Error: station_name == nil!")
		return
	end
	local booking = hyperloop.booking[station_name]
	if booking == nil then
		minetest.chat_send_player(clicker:get_player_name(), "[Hyperloop] No booking entered!")
		return
	end

	local dataSet = table.copy(hyperloop.tAllStations[booking])
	-- delete booking
	hyperloop.booking[station_name] = nil
	if dataSet == nil then
		return
	end

	-- destination data od the station
	local dest_pos = minetest.string_to_pos(dataSet.pos)
	local dest_meta = minetest.get_meta(dest_pos)
	local dest_name = dest_meta:get_string("station_name")

	-- seat is on top of the station block
	dest_pos = vector.add(dest_pos, {x=0,y=1,z=0})
	dest_meta = minetest.get_meta(dest_pos)
	local dest_facedir = dest_meta:get_int("facedir")

	minetest.sound_play("up2", {
			pos = pos,
			gain = 0.5,
			max_hear_distance = 10
		})
	-- close the door at arrival station
	hyperloop.door_command(dest_pos, dest_facedir, "close", dest_name)
	-- place player on the seat
	clicker:setpos(pos)
	-- rotate player to look in move direction
	clicker:set_look_horizontal(hyperloop.facedir2rad(facedir))

	-- activate display
	local dist = hyperloop.distance(pos, dest_pos) 
	local text = "Destination: | "..string.sub(dest_name, 1, 13).." | Distance: | "..meter_to_km(dist).." | Arrival in: | "
	local atime
	if dist < 1000 then
		atime = 10 + math.floor(dist/100)		-- 10..20 sec
	elseif dist < 10000 then
		atime = 20 + math.floor(dist/300)		-- 23..53 sec
	else
		atime = 40 + math.floor(dist/600)		-- 56..240 sec (120.000m)
	end
	hyperloop.enter_display(pos, dest_facedir, text..atime.." sec")

	-- block departure and arrival stations
	hyperloop.block(station_name, dest_name, atime+10)	

	-- store some data
	meta:set_int("arrival_time", atime)
	meta:set_string("lcd_text", text)
	minetest.get_node_timer(pos):start(1.0)

	hyperloop.door_command(pos, facedir, "close", station_name)

	atime = atime - 9 -- substract start/arrival time
	minetest.after(4.9, on_travel, pos, facedir, clicker, dest_pos, hyperloop.facedir2rad(facedir), atime)
end


function hyperloop.open_pod_door(station_name)
	if hyperloop.tAllStations[station_name] ~= nil and hyperloop.tAllStations[station_name].pos ~= nil then
		local pos = minetest.string_to_pos(hyperloop.tAllStations[station_name].pos)
		local seat_pos = vector.add(pos, {x=0, y=1, z=0})
		local meta = minetest.get_meta(seat_pos)
		local facedir = meta:get_int("facedir")
		hyperloop.door_command(seat_pos, facedir, "open")
		hyperloop.enter_display(seat_pos, facedir, " |  | << Hyperloop >> | be anywhere")
	end
end

function hyperloop.close_pod_door(station_name)
	if hyperloop.tAllStations[station_name] ~= nil and hyperloop.tAllStations[station_name].pos ~= nil then
		local pos = minetest.string_to_pos(hyperloop.tAllStations[station_name].pos)
		local seat_pos = vector.add(pos, {x=0, y=1, z=0})
		local meta = minetest.get_meta(seat_pos)
		local facedir = meta:get_int("facedir")
		hyperloop.door_command(seat_pos, facedir, "close", station_name)
		hyperloop.enter_display(seat_pos, facedir, " |  | << Hyperloop >> | be anywhere")
	end
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
	groups = {snappy = 3},
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

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("arrival_time", 0)
	end,

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local yaw = placer:get_look_horizontal()
		-- facedir according to radiant
		local facedir = hyperloop.rad2facedir(yaw)
		-- do a 180 degree correction
		meta:set_int("facedir", (facedir + 2) % 4)
		-- store station name locally
		local pos2 = vector.add(pos, {x=0, y=-1, z=0})
		local meta2 = minetest.get_meta(pos2)
		if meta2 ~= nil then
			local station_name = meta2:get_string("station_name")
			meta:set_string("station_name", station_name)
			if hyperloop.tAllStations[station_name] ~= nil then
				hyperloop.tAllStations[station_name]["seat"] = true
			end
		end
		hyperloop.change_counter = hyperloop.change_counter + 1
	end,

	on_destruct = function(pos)
		local meta = minetest.get_meta(pos)
		local station_name = meta:get_string("station_name")
		if hyperloop.tAllStations[station_name] ~= nil 
		and hyperloop.tAllStations[station_name]["seat"] ~= nil then
			hyperloop.tAllStations[station_name]["seat"] = nil
			hyperloop.open_pod_door(station_name)
		end
		hyperloop.change_counter = hyperloop.change_counter + 1
	end,

	on_rightclick = on_start_travel,
})
