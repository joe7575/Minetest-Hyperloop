--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

-- Tube chain arrangement:
--   [0] = tube0
--   [1] = tube1
--   [2] = tube2
--   [J] = junction
--
--   [0]  [1]-[1]  [1]-[2]-[1]  [J]-[1]-[2]-...-[2]-[1]-[J]



-- Scan all 8 neighbor positions for tube nodes.
-- Return:
--  0, nodes    - no node available
--  1, nodes    - one tube1 available
--  3, nodes    - two tube1 available
--  4, nodes    - one tube2 available
--  5, nodes    - invalid position
function hyperloop.scan_neighbours(pos)
	local nodes = {}
	local node, npos, idx
	local res = 0
	for _,dir in ipairs(hyperloop.NeighborPos) do
		npos = vector.add(pos, dir)
		node = minetest.get_node(npos)
		if string.find(node.name, "hyperloop:tube") then
			node.pos = npos
			table.insert(nodes, node)
			idx = string.byte(node.name, -1) - 48
			if idx == 0 then        -- starter tube node?
				idx = 1
			elseif idx == 2 then    -- normal tube node?
				return 4, nodes
			end
			res = res * 2 + idx
		end
	end
	if res > 3 then
		res = 5
	end
	return res, nodes
end


local function update_junction(pos)
	local res, nodes = hyperloop.scan_for_nodes(pos, "hyperloop:junction")
	for _,node in ipairs(nodes) do
		minetest.registered_nodes["hyperloop:junction"].update(node.pos)
	end
end	

-- update head tube meta data
local function update_node(pos, peer_pos)
	local meta = minetest.get_meta(minetest.string_to_pos(pos))
	meta:set_string("peer", peer_pos)
	update_junction(minetest.string_to_pos(pos))
	if hyperloop.debugging then
		meta:set_string("infotext", peer_pos)
	end
end


-- Degrade one node.
-- Needed when a new node is placed nearby.
local function degrade_tupe_node(node)
	if node.name == "hyperloop:tube0" then
		node.name = "hyperloop:tube1"
	elseif node.name == "hyperloop:tube1" then
		node.name = "hyperloop:tube2"
		node.diggable = false
	else
		return
	end
	minetest.swap_node(node.pos, node)
end

-- Upgrade one node.
-- Needed when a tube node is digged.
local function upgrade_node(digged_node_pos, new_head_node)
	-- copy peer info first
	local peer_pos = minetest.get_meta(digged_node_pos):get_string("peer")
	local pos = minetest.pos_to_string(new_head_node.pos)
	update_node(pos, peer_pos)
	update_node(peer_pos, pos)
	-- upgrade
	new_head_node.diggable = true
	if new_head_node.name == "hyperloop:tube2" then          -- 2 connections?
		new_head_node.name = "hyperloop:tube1"
	elseif new_head_node.name == "hyperloop:tube1" then      -- 1 connection?
		new_head_node.name = "hyperloop:tube0"
	end
	minetest.swap_node(new_head_node.pos, new_head_node)
end

-- Place a node without neighbours
local function starter_node(node)
	local meta = minetest.get_meta(node.pos)
	meta:set_string("peer", minetest.pos_to_string(node.pos))
	-- upgrade self to starter node
	node.name = "hyperloop:tube0"
	minetest.swap_node(node.pos, node)
end

-- Place a node with one neighbor
local function head_node(node, old_head)
	-- determine peer pos
	local peer_pos = minetest.get_meta(old_head.pos):get_string("peer")
	-- update self
	update_node(minetest.pos_to_string(node.pos), peer_pos)
	-- update peer
	update_node(peer_pos, minetest.pos_to_string(node.pos))
	-- upgrade self
	node.name = "hyperloop:tube1"
	minetest.swap_node(node.pos, node)
	-- degrade old head
	degrade_tupe_node(old_head)
end

local function link_node(node, node1, node2)
	-- determine the meta data from both head nodes
	local pos1 = minetest.get_meta(node1.pos):get_string("peer")
	local pos2 = minetest.get_meta(node2.pos):get_string("peer")
	-- exchange position data
	update_node(pos1, pos2)
	update_node(pos2, pos1)
	-- set to tube2
	node.name = "hyperloop:tube2"
	node.diggable = true
	minetest.swap_node(node.pos, node)
	-- degrade both nodes
	degrade_tupe_node(node1)
	degrade_tupe_node(node2)
end

local function remove_node(pos, node)
	-- can't call "remove_node(pos)" because subsequently "on_destruct" will be called
	node.name = "air"
	node.diggable = true
	minetest.swap_node(pos, node)
end

-- simple tube without logic or "memory"
minetest.register_node("hyperloop:tube2", {
		description = "Hyperloop Tube",
		tiles = {
			-- up, down, right, left, back, front
			"hyperloop_tube_locked.png^[transformR90]",
			"hyperloop_tube_locked.png^[transformR90]",
			"hyperloop_tube_locked.png",
			"hyperloop_tube_locked.png",
			"hyperloop_tube_locked.png",
			"hyperloop_tube_locked.png",
		},

		diggable = false,
		paramtype2 = "facedir",
		groups = {cracky=1, not_in_creative_inventory=1},
		is_ground_content = false,
	})

-- single-node and head-node with meta data about the peer head node position
for idx = 0,1 do
	minetest.register_node("hyperloop:tube"..idx, {
			description = "Hyperloop Tube",
			inventory_image = "hyperloop_tube_inventury.png",
			drawtype = "nodebox",
			tiles = {
				-- up, down, right, left, back, front
				'hyperloop_tube_closed.png^[transformR90]',
				'hyperloop_tube_closed.png^[transformR90]',
				'hyperloop_tube_closed.png',
				'hyperloop_tube_closed.png',
				'hyperloop_tube_open.png',
				'hyperloop_tube_open.png',
			},

			after_place_node = function(pos, placer, itemstack, pointed_thing)
				local res, nodes = hyperloop.scan_neighbours(pos)
				local node = minetest.get_node(pos)
				node.pos = pos
				if res == 0 then            -- no neighbor available?
					starter_node(node)
				elseif res == 1 then        -- one neighbor available?
					head_node(node, nodes[1])
				elseif res == 3 then        -- two neighbours available?
					link_node(node, nodes[1], nodes[2])
				else                        -- invalid position
					minetest.chat_send_player(placer:get_player_name(),
						"Error: Invalid tube block position!")
					remove_node(pos, node)
					return itemstack
				end
				update_junction(pos)
			end,

			on_destruct = function(pos)
				local res, nodes = hyperloop.scan_neighbours(pos)
				if res == 1 or res == 4 then
					upgrade_node(pos, nodes[1])
				end
				update_junction(pos)
			end,

			paramtype2 = "facedir",
			groups = {cracky=2, not_in_creative_inventory=idx},
			is_ground_content = false,
			drop = "hyperloop:tube0",
		})
end

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
	groups = {cracky = 3, stone = 2},
	sounds = default.node_sound_stone_defaults(),
})


