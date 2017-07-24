--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

	
-- simple shaft without logic or "memory"
minetest.register_node("hyperloop:shaft", {
	description = "Hyperloop Elevator Shaft",
	tiles = {
		-- up, down, right, left, back, front
		'hyperloop_tube_open.png',
		'hyperloop_tube_open.png',
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
	},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local npos = table.copy(pos)
		npos.y = npos.y - 1
		if minetest.get_node_or_nil(npos).name == "hyperloop:shaft" then
			local node = minetest.get_node(npos)
			node.name = "hyperloop:shaft2"
			minetest.swap_node(npos, node)
		elseif minetest.get_node_or_nil(npos).name == "hyperloop:elevator_top" then
			npos.y = npos.y - 1
			hyperloop.update_elevator(npos)
		else
			minetest.remove_node(pos)
			return itemstack
		end
	end,
	
	after_destruct = function(pos)
		local npos = table.copy(pos)
		npos.y = npos.y - 1
		if minetest.get_node_or_nil(npos).name == "hyperloop:shaft2" then
			local node = minetest.get_node(npos)
			node.name = "hyperloop:shaft"
			minetest.swap_node(npos, node)
		elseif minetest.get_node_or_nil(npos).name == "hyperloop:elevator_top" then
			npos.y = npos.y - 1
			hyperloop.update_elevator(npos)
		end
	end,
	
	light_source = 6,
	paramtype2 = "facedir",
	groups = {cracky=1},
	is_ground_content = false,
})

-- simple shaft without logic or "memory"
minetest.register_node("hyperloop:shaft2", {
	description = "Hyperloop Elevator Shaft",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
	},

	diggable = false,
	paramtype2 = "facedir",
	groups = {cracky=1, not_in_creative_inventory=1},
	is_ground_content = false,
})
