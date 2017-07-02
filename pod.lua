--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

function hyperloop.enter_display(seat_pos, facedir, text)
	if seat_pos == nil then
		return
	end
    -- determine position
    local pos = vector.add(seat_pos,  hyperloop.facedir2dir(facedir))
    pos.y = pos.y + 1
	-- load map
	minetest.forceload_block(pos)
	-- update display
	minetest.registered_nodes["hyperloop:lcd"].update(pos, text) 
end

-- to build the pod
minetest.register_node("hyperloop:pod_wall", {
		description = "Hyperloop Pod Wall",
		tiles = {
			-- up, down, right, left, back, front
			"hyperloop_skin.png^[transformR90]",
			"hyperloop_skin.png^[transformR90]",
			"hyperloop_skin.png",
			"hyperloop_skin.png",
			"hyperloop_skin.png",
			"hyperloop_skin.png",
		},
		paramtype2 = "facedir",
		groups = {cracky=1, stone = 2},
		is_ground_content = false,
		sounds = default.node_sound_metal_defaults(),
	})


-- for tube viaducts
minetest.register_node("hyperloop:pillar", {
		description = "Hyperloop Pillar",
		tiles = {"hyperloop_tube_locked.png^[transformR90]"},
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -3/8, -4/8, -3/8,   3/8, 4/8, 3/8},
			},
		},
		is_ground_content = false,
		groups = {cracky = 2, stone = 2},
		sounds = default.node_sound_metal_defaults(),
	})


