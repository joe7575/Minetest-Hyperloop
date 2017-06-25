--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

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
		groups = {cracky=1},
		is_ground_content = false,
	})
