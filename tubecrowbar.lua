--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local function determine_peer(pos, node)
	local _pos = table.copy(pos)
	local _node = table.copy(node)
	while true do
		--print(minetest.pos_to_string(pos))
		if _node.name == "hyperloop:tube2" then
			local res, nodes = hyperloop.scan_neighbours(_node.pos)
			if res == 12 and #nodes == 2 then
				if vector.equals(nodes[1].pos, _pos) then
					_pos = table.copy(_node.pos)
					_node = nodes[2]
				else
					_pos = table.copy(_node.pos)
					_node = nodes[1]
				end
			elseif nodes[1].name == "hyperloop:tube1" then
				return nodes[1].pos
			elseif nodes[2] ~= nil and nodes[2].name == "hyperloop:tube1" then
				return nodes[2].pos
			else
				return nil
			end
		else
			return nil
		end
	end
end
			
			
			
local function crack_tube_line(itemstack, placer, pointed_thing)
	if pointed_thing.type ~= "node" then
		return
	end
	local pos = pointed_thing.under
	local node = minetest.get_node(pos)
	if node.name == "hyperloop:tube2" then
        minetest.sound_play({
            name="default_dig_cracky"},{
            gain=1,
            max_hear_distance=5,
            loop=false})
		local res, nodes = hyperloop.scan_neighbours(pos)
		if res == 12 and #nodes == 2 then
			local peer1 = determine_peer(pos, nodes[1])
			local peer2 = determine_peer(pos, nodes[2])
			if peer1 ~= nil and peer2 ~= nil then
				peer1 = minetest.pos_to_string(peer1)
				peer2 = minetest.pos_to_string(peer2)
				hyperloop.swap_tube_node(nodes[1], peer1)
				hyperloop.swap_tube_node(nodes[2], peer2)
				minetest.remove_node(pos)
				itemstack:take_item(1)
			end
		elseif res == 4 and #nodes == 1 then
			local peer1 = determine_peer(pos, nodes[1])
			if peer1 ~= nil then
				peer1 = minetest.pos_to_string(peer1)
				hyperloop.swap_tube_node(nodes[1], peer1)
				minetest.remove_node(pos)
				itemstack:take_item(1)
			end
		end
	end
	return itemstack
end

-- Tool for tube workers to crack a tube line
minetest.register_node("hyperloop:tube_crowbar", {
	description = "Hyperloop Tube Crowbar",
	inventory_image = "hyperloop_tubecrowbar.png",
	wield_image = "hyperloop_tubecrowbar.png",
	groups = {cracky=1, book=1},
	on_use = crack_tube_line,
	on_place = function(itemstack, placer, pointed_thing)
		return itemstack
	end,
})

