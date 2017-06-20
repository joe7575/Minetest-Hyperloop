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


hyperloop = {
    ringList = {},
}

-- max teleport distance
-- Intllib
local S

if minetest.get_modpath("intllib") then
	S = intllib.Getter()
else
	S = function(s, a, ...) a = {a, ...}
		return s:gsub("@(%d+)", function(n)
			return a[tonumber(n)]
		end)
	end

end


local dist = tonumber(minetest.setting_get("map_generation_limit") or 31000)


dofile(minetest.get_modpath("hyperloop") .. "/utils.lua")
dofile(minetest.get_modpath("hyperloop") .. "/door.lua")
dofile(minetest.get_modpath("hyperloop") .. "/tubes.lua")

----------------------------------------------------------------------------------------------------
local function enter_display(pos, text)
    -- Use LCD from digilines. TODO: Own display
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
local function check_coordinates(str)
    -- obsolete?
	if not str or str == "" then
		return nil
	end

	-- get coords from string
	local x, y, z, desc = string.match(str, "^(-?%d+),(-?%d+),(-?%d+),?(.*)$")

	-- check coords
	if x == nil or string.len(x) > 6
	or y == nil or string.len(y) > 6
	or z == nil or string.len(z) > 6 then
		return nil
	end

	-- convert string coords to numbers
	x = tonumber(x)
	y = tonumber(y)
	z = tonumber(z)

	-- are coords in map range ?
	if x > dist or x < -dist
	or y > dist or y < -dist
	or z > dist or z < -dist then
		return nil
	end

	-- return ok coords
	return {x = x, y = y, z = z, desc = desc}
end

----------------------------------------------------------------------------------------------------
-- seat_pos: position of the seat
-- facedir: direction to the display
-- cmnd: "close", "open", or "animate"
local function door_command(seat_pos, facedir, cmnd)
    -- one step forward
    local lcd_pos = vector.add(seat_pos, facedir2dir(facedir))
    -- one step left
    local door_pos1 = vector.add(lcd_pos, facedir2dir(facedir + 1))
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
    local text = "We will start | in a few | seconds"
    enter_display(lcd_pos, text)
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
    local yaw = facedir2rad(facedir) + offs
    player:set_look_yaw(yaw)

    -- play arrival sound
    minetest.sound_stop(snd)
    minetest.sound_play("down", {
        pos = dst_pos,
        gain = 1.0,
        max_hear_distance = 10
    })
    -- activate display
    local lcd_pos = vector.add(dst_pos, facedir2dir(facedir))
    lcd_pos.y = lcd_pos.y + 1
    --print("LCD "..dump(pos)..dump(lcd_pos))
    local text = "Wellcome in | | Hauptstadt"
    enter_display(lcd_pos, text)

    minetest.after(6.0, on_open_door, dst_pos, facedir)
end

----------------------------------------------------------------------------------------------------
local function on_travel(src_pos, facedir, player, dst_pos, radiant)
    -- play sound and switch door state
    -- radiant is the player look direction at departure
    local snd = minetest.sound_play("normal", {
        pos = src_pos,
        gain = 1.0,
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
    local meta = minetest.get_meta(pos)
    local facedir = meta:get_int("facedir")
    if meta:get_int("arrival_time") ~= 0 then
        return
    end
    local target_coords = {
        x = meta:get_int("x"),
        y = meta:get_int("y"),
        z = meta:get_int("z")
    }

    minetest.sound_play("up", {
        pos = pos,
        gain = 1.0,
        max_hear_distance = 10
    })
    -- place player on the seat
    clicker:setpos(pos)
    -- rotate player to look in move direction
    clicker:set_look_horizontal(facedir2rad(facedir))

    -- activate display
    local lcd_pos = vector.add(pos, facedir2dir(facedir))
    lcd_pos.y = lcd_pos.y + 1
    --print("LCD "..dump(pos)..dump(lcd_pos))
    local text = "Next stop: | Hauptstadt | Dist: 2.2km | Arrival in: | "
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

    minetest.after(4.9, on_travel, pos, facedir, clicker, target_coords, facedir2rad(facedir))
end

-- Hyperloop Seat
minetest.register_node("hyperloop:seat", {
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

		-- text entry formspec
		meta:set_string("formspec", "field[text;" .. S("Enter teleport coords (e.g. 200,20,-200,Home)") .. ";${text}]")
		meta:set_string("infotext", S("Right-click to enchant teleport location"))
		meta:set_string("text", pos.x .. "," .. pos.y .. "," .. pos.z)
        meta:set_int("arrival_time", 0)

		-- set default coords
		meta:set_int("x", pos.x)
		meta:set_int("y", pos.y)
		meta:set_int("z", pos.z)
	end,

	after_place_node = function(pos, placer)
        local meta = minetest.get_meta(pos)
        local yaw = placer:get_look_horizontal()
        -- facedir according to radiant
		local facedir = rad2facedir(yaw)
        -- do a 180 degree correction
		meta:set_int("facedir", (facedir + 2) % 4)
        print("on_construct "..dump(pos))----------------------------------------------
	end,

	-- once entered, check coords, if ok then return potion
	on_receive_fields = function(pos, formname, fields, sender)

		local name = sender:get_player_name()

		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return
		end

		local coords = check_coordinates(fields.text)

		if coords then

			local meta = minetest.get_meta(pos)
            print("on_receive_fields "..dump(pos))----------------------------------------------

			meta:set_int("x", coords.x)
			meta:set_int("y", coords.y)
			meta:set_int("z", coords.z)
			meta:set_string("text", fields.text)

			if coords.desc and coords.desc ~= "" then

				meta:set_string("infotext", S("Teleport to @1", coords.desc))
			else
				meta:set_string("infotext", S("Pad Active (@1,@2,@3)",
					coords.x, coords.y, coords.z))
			end
            -- delete formspec so that right-click will work
            meta:set_string("formspec", nil)
		else
			minetest.chat_send_player(name, S("Teleport Pad coordinates failed!"))
		end
	end,

    on_rightclick = on_start_travel,
})

print ("[MOD] Hyperloop loaded")
