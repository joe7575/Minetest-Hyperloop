--[[

	Hyperloop Mod
	=============

	v0.01 by JoSt

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	2017-06-18  v0.01  First version

]]--


local function enter_display(pos, text)
    -- Use LCD from digilines. TODO: Own display
	if pos == nil then
		return
	end
    local node = minetest.get_node(pos)
    local spec = digilines.getspec(node)
    if spec then
        -- Effector actions --> Receive
        if spec.effector then
            spec.effector.action(pos, node, "lcd", text)
        end
    end
end

----------------------------------------------------------------------------------------------------
-- seat_pos: position of the seat
-- facedir: direction to the display
-- cmnd: "close", "open", or "animate"
local function door_command(seat_pos, facedir, cmnd)
    -- one step forward
    local lcd_pos = vector.add(seat_pos, hyperloop.facedir2dir(facedir))
    -- one step left
    local door_pos1 = vector.add(lcd_pos, hyperloop.facedir2dir(facedir + 1))
    -- one step up
    local door_pos2 = vector.add(door_pos1, {x=0, y=1, z=0})

    local node1 = minetest.get_node(door_pos1)
    local node2 = minetest.get_node(door_pos2)

    -- switch from the radian following facedir to the silly original one
    local tbl = {[0]=0, [1]=3, [2]=2, [3]=1}
    facedir = (facedir + 3) % 4   -- first turn left
    facedir = tbl[facedir]
    
    if cmnd == "open" then
        node1.name = "air"
        minetest.swap_node(door_pos1, node1)
        node2.name = "air"
        minetest.swap_node(door_pos2, node2)
    elseif cmnd == "close" then
        node1.name = "hyperloop:doorBottom"
        node1.param2 = facedir
        minetest.swap_node(door_pos1, node1)
        node2.name = "hyperloop:doorTopPassive"
        node2.param2 = facedir
        minetest.swap_node(door_pos2, node2)
    elseif cmnd == "animate" then
        node2.name = "hyperloop:doorTopActive"
        node2.param2 = facedir
        minetest.swap_node(door_pos2, node2)
    end
end

----------------------------------------------------------------------------------------------------
local function on_open_door(pos, facedir)
    -- open the door and play sound
    local meta = minetest.get_meta(pos)
    meta:set_int("arrival_time", 0) -- finished

    -- open the door
    minetest.sound_play("door", {
        pos = pos,
        gain = 0.5,
        max_hear_distance = 10,
    })
    door_command(pos, facedir, "open")
    
    -- prepare dislay for the next trip
    local lcd_pos = vector.add(pos,  hyperloop.facedir2dir(facedir))
    lcd_pos.y = lcd_pos.y + 1
    --local text = "We will start | in a few | seconds"
	local text = "Thanks for | travelling | with | Hyperloop."
    enter_display(lcd_pos, text)
	-- delete order
	hyperloop.order = {}
end

----------------------------------------------------------------------------------------------------
local function on_arrival(player, src_pos, dst_pos, snd, radiant)
    -- open the door an the departure station
    local meta = minetest.get_meta(src_pos)
    local facedir = meta:get_int("facedir")
    door_command(src_pos, facedir, "open")

    -- get coords from arrival station
    meta = minetest.get_meta(dst_pos)
    facedir = meta:get_int("facedir")
    --print("on_arrival "..dump(dst_pos))----------------------------------------------

    -- close the door at arrival station
    door_command(dst_pos, facedir, "close")
    
    -- move player to the arrival station
    player:setpos(dst_pos)
    -- rotate player to look in correct arrival direction
    -- calculate the look correction
    local offs = radiant - player:get_look_horizontal()
    local yaw = hyperloop.facedir2rad(facedir) + offs
    player:set_look_yaw(yaw)

    -- play arrival sound
    minetest.sound_stop(snd)
    minetest.sound_play("down2", {
        pos = dst_pos,
        gain = 0.5,
        max_hear_distance = 10
    })
    -- activate display
    local lcd_pos = vector.add(dst_pos,  hyperloop.facedir2dir(facedir))
    lcd_pos.y = lcd_pos.y + 1
    --print("LCD "..dump(pos)..dump(lcd_pos))
	local station_name = meta:get_string("station_name")
    local text = "Wellcome in | | "..station_name
    enter_display(lcd_pos, text)

    minetest.after(6.0, on_open_door, dst_pos, facedir)
end

----------------------------------------------------------------------------------------------------
local function on_travel(src_pos, facedir, player, dst_pos, radiant)
    -- play sound and switch door state
    -- radiant is the player look direction at departure
    local snd = minetest.sound_play("normal2", {
        pos = src_pos,
        gain = 0.5,
        max_hear_distance = 1,
        loop = true,
    })
    door_command(src_pos, facedir, "animate")
    minetest.after(6.0, on_arrival, player, src_pos, dst_pos, snd, radiant)
end

----------------------------------------------------------------------------------------------------
local function display_timer(pos, elapsed)
    -- update display with trip data
    local meta = minetest.get_meta(pos)
    local atime = meta:get_int("arrival_time") - 1
    meta:set_int("arrival_time", atime)
    local lcd_pos = minetest.string_to_pos(meta:get_string("lcd_pos"))
    local text = meta:get_string("lcd_text")
    if atime > 0 then
        enter_display(lcd_pos, text..atime.." sec")
        return true
    else
        enter_display(lcd_pos, "We will start | in a view | minutes..")
        return false
    end
end


----------------------------------------------------------------------------------------------------
local function on_start_travel(pos, node, clicker)
    -- place the player, close the door, activate display
	print("on_start_travel")
    local meta = minetest.get_meta(pos)
    local facedir = meta:get_int("facedir")
--    if meta:get_int("arrival_time") ~= 0 then
--		minetest.chat_send_player(clicker:get_player_name(), "Error: arrival_time > 0!")
--        return
--    end
	local station_name = meta:get_string("station_name")
    if station_name == nil then
		minetest.chat_send_player(clicker:get_player_name(), "Error: station_name == nil!")
        return
    end
	local order = hyperloop.order[station_name]
	if order == nil then
		minetest.chat_send_player(clicker:get_player_name(), "Error: No order entered!")
		return
	end
	local dataSet = hyperloop.tAllStations[order]
	if dataSet == nil then
		return
	end
    local target_coords = minetest.string_to_pos(dataSet.pos)
	-- seat is on top of the station block
	target_coords = vector.add(target_coords, {x=0,y=1,z=0})
    minetest.sound_play("up2", {
        pos = pos,
        gain = 0.5,
        max_hear_distance = 10
    })
    -- place player on the seat
    clicker:setpos(pos)
    -- rotate player to look in move direction
    clicker:set_look_horizontal(hyperloop.facedir2rad(facedir))

    -- activate display
    local lcd_pos = vector.add(pos, hyperloop.facedir2dir(facedir))
    lcd_pos.y = lcd_pos.y + 1
    --print("LCD "..dump(pos)..dump(lcd_pos))
	meta = minetest.get_meta(target_coords)
	local dest = meta:get_string("station_name")
    local text = "Next stop: | "..dest.." | Dist: 2.2km | Arrival in: | "
    local atime = 15
    enter_display(lcd_pos, text..atime.." sec")
    
    -- store some data
    meta:set_int("arrival_time", atime)
    meta:set_string("lcd_pos", minetest.pos_to_string(lcd_pos))
    meta:set_string("lcd_text", text)
    meta:set_string("lcd_text", text)
    minetest.get_node_timer(pos):start(1.0)
    
    --print("on_rightclick "..dump(pos))----------------------------------------------

    -- close the door
    minetest.sound_play("door", {
        pos = pos,
        gain = 0.5,
        max_hear_distance = 10,
    })
    door_command(pos, facedir, "close")

    minetest.after(4.9, on_travel, pos, facedir, clicker, target_coords, hyperloop.facedir2rad(facedir))
end

-- Hyperloop Seat
minetest.register_node("hyperloop:seat", {
	description = "Hyperloop Pod Seat",
	tiles = {
        "seat-top.png",
        "seat-side.png",
        "seat-side.png",
        "seat-side.png",
        "seat-side.png",
        "seat-side.png",
    },
	drawtype = "nodebox",
	paramtype2 = "facedir",
	is_ground_content = false,
    walkable = false,
	--description = S("Hyperloop Pad (place and right-click to enchant location)"),
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
        --print("on_construct "..dump(pos))----------------------------------------------
		-- store station name locally
		local pos2 = vector.add(pos, {x=0, y=-1, z=0})
		local meta2 = minetest.get_meta(pos2)
		if meta2 ~= nil then
			meta:set_string("station_name", meta2:get_string("station_name"))
		end
	end,

    on_rightclick = on_start_travel,
})
