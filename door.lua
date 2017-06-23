--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

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
	description = "Hyperloop Doorframe",
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

