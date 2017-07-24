--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local tilesL = {"hyperloop_alpsL.png", "hyperloop_seaL.png", "hyperloop_agyptL.png"}
local tilesR = {"hyperloop_alpsR.png", "hyperloop_seaR.png", "hyperloop_agyptR.png"}

for idx = 1,3 do
	
	minetest.register_node("hyperloop:poster"..idx.."L", {
		description = "Hyperloop Promo Poster "..idx,
		tiles = {
			-- up, down, right, left, back, front
			"hyperloop_skin2.png",
			"hyperloop_skin2.png",
			"hyperloop_skin2.png",
			"hyperloop_skin2.png",
			"hyperloop_skin2.png",
			tilesL[idx],
		},
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -8/16, -8/16, -6/16,  8/16,  8/16, 8/16},
			},
		},
		selection_box = {
			type = "fixed",
			fixed = { -8/16, -8/16, -6/16,  24/16,  8/16, 8/16},
		},
		
		after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			local facedir
			facedir, pos = hyperloop.right_hand_side(pos, placer)
			meta:set_string("pos", minetest.pos_to_string(pos))
			if minetest.get_node_or_nil(pos).name == "air" then
				minetest.add_node(pos, {name="hyperloop:poster"..idx.."R", param2=facedir})
			end
		end,

		on_destruct = function(pos)
			local meta = minetest.get_meta(pos)
			pos = minetest.string_to_pos(meta:get_string("pos"))
			if pos ~= nil and minetest.get_node_or_nil(pos).name == "hyperloop:poster"..idx.."R" then
				minetest.remove_node(pos)
			end
		end,
		
		
		paramtype2 = "facedir",
		light_source = 4,
		is_ground_content = false,
		groups = {cracky = 2, stone = 2},
	})

	minetest.register_node("hyperloop:poster"..idx.."R", {
		description = "Hyperloop Promo Poster "..idx,
		tiles = {
			-- up, down, right, left, back, front
			"hyperloop_skin2.png",
			"hyperloop_skin2.png",
			"hyperloop_skin2.png",
			"hyperloop_skin2.png",
			"hyperloop_skin2.png",
			tilesR[idx],
		},
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -8/16, -8/16, -6/16,  8/16,  8/16, 8/16},
			},
		},
		paramtype2 = "facedir",
		light_source = 4,
		is_ground_content = false,
		groups = {cracky = 2, stone = 2, not_in_creative_inventory=1},
	})
end


minetest.register_node("hyperloop:sign", {
	description = "Hyperloop Station Sign",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_sign_top.png",
		"hyperloop_sign.png",
		"hyperloop_sign.png",
		"hyperloop_sign.png",
		"hyperloop_sign.png",
		"hyperloop_sign.png",
	},
	drawtype = "nodebox",
	light_source = 4,
	is_ground_content = false,
	groups = {cracky = 2, stone = 2},
})