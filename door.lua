--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

-- Open/close/animate the pod door
-- seat_pos: position of the seat
-- facedir: direction to the display
-- cmnd: "close", "open", or "animate"
function hyperloop.door_command(seat_pos, facedir, cmnd)
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
		minetest.sound_play("door", {
			pos = seat_pos,
			gain = 0.5,
			max_hear_distance = 5,
		})
        node1.name = "air"
        minetest.swap_node(door_pos1, node1)
        node2.name = "air"
        minetest.swap_node(door_pos2, node2)
    elseif cmnd == "close" then
		minetest.sound_play("door", {
			pos = seat_pos,
			gain = 0.5,
			max_hear_distance = 5,
		})
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

minetest.register_node("hyperloop:doorTopPassive", {
	description = "Hyperloop Door Top",
	tiles = {
        -- up, down, right, left, back, front
  	    "hyperloop_skin_door.png",
	    "hyperloop_skin_door.png",
	    "hyperloop_skin_door.png",
	    "hyperloop_skin_door.png",
	    "hyperloop_door1OUT.png",
	    "hyperloop_door1OUT.png",
	},
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-8/16, -8/16, -6/16, 8/16, 8/16, 6/16},
    },
	paramtype2 = "facedir",
	groups = {cracky=1, not_in_creative_inventory=1},
	is_ground_content = false,
})

minetest.register_node("hyperloop:doorTopActive", {
	description = "Hyperloop Door Top",
	tiles = {
        -- up, down, right, left, back, front
  	    "hyperloop_skin_door.png",
	    "hyperloop_skin_door.png",
	    "hyperloop_skin_door.png",
	    "hyperloop_skin_door.png",
		{
			name = "hyperloop_door1IN.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 1.0,
			},
		},
	    "hyperloop_door1OUT.png",
	},
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-8/16, -8/16, -6/16, 8/16, 8/16, 6/16},
    },
	paramtype2 = "facedir",
	light_source = 2,
	groups = {cracky=1, not_in_creative_inventory=1},
	is_ground_content = false,
})

minetest.register_node("hyperloop:doorBottom", {
	description = "Hyperloop Door Bottom",
	tiles = {
        -- up, down, right, left, back, front
  	    "hyperloop_skin_door.png",
	    "hyperloop_skin_door.png",
	    "hyperloop_skin_door.png",
	    "hyperloop_skin_door.png",
	    "hyperloop_door2IN.png",
	    "hyperloop_door2OUT.png",
	},
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = {-8/16, -8/16, -6/16, 8/16, 8/16, 6/16},
    },
	paramtype2 = "facedir",
	groups = {cracky=1, not_in_creative_inventory=1},
	is_ground_content = false,
})

minetest.register_node("hyperloop:doorframe", {
	description = "Hyperloop Pod Doorframe",
	tiles = {
        -- up, down, right, left, back, front
  	    "hyperloop_skin_door.png^[transformR90]",
	    "hyperloop_skin_door.png^[transformR90]",
	    "hyperloop_skin_door.png",
	    "hyperloop_skin_door.png",
	    "hyperloop_skin.png",
	    "hyperloop_skin.png",
	},
	paramtype2 = "facedir",
	groups = {cracky=1},
	is_ground_content = false,
})

