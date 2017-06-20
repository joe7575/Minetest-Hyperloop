--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local function scan_neighbours(pos)
    -- Scan all 8 neighbor positions for tube nodes.
    -- Return:
    --  0, nodes    - no node available
    --  1, nodes    - one tube1 available
    --  3, nodes    - two tube1 available
    --  4, nodes    - one tube2 available
    --  5, nodes    - invalid position
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
            if res > 3 then
                return 5, nodes
            end
        end
    end
    return res, nodes
end

local function degrade_tupe_node(node)
    print("degrade_tupe_node"..node.name)
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

local function upgrade_node(pos, node)
    -- Upgrade one node.
    -- Is needed when a tube node is digged.
    local meta_local = minetest.get_meta(pos)
    local meta_head = minetest.get_meta(node.pos)
    meta_head:set_string("other", meta_local:get_string("other"))
    meta_head:set_string("me", minetest.pos_to_string(node.pos))
    node.diggable = true
    if node.name == "hyperloop:tube2" then          -- 2 connections?
        node.name = "hyperloop:tube1"
    elseif node.name == "hyperloop:tube1" then      -- 1 connection?
        node.name = "hyperloop:tube0"
    end
    minetest.swap_node(node.pos, node)
end

local function starter_node(node)
    local meta = minetest.get_meta(node.pos)
    meta:set_string("local", minetest.pos_to_string(node.pos))
    meta:set_string("remote", minetest.pos_to_string(node.pos))
    -- upgrade self to starter node
    node.name = "hyperloop:tube0"
    minetest.swap_node(node.pos, node)
end

local function head_node(node, node1)
    local meta_local = minetest.get_meta(node.pos)
    local meta_head  = minetest.get_meta(node1.pos)
    -- set local data
    meta_local:set_string("local", minetest.pos_to_string(node.pos))
    meta_local:set_string("remote", meta_head:get_string("remote"))
    -- set remote data
    local rpos = minetest.string_to_pos(meta_head:get_string("remote"))
    local rmeta = minetest.get_meta(rpos)
    rmeta:set_string("remote", minetest.pos_to_string(node.pos))
    -- upgrade self
    node.name = "hyperloop:tube1"
    minetest.swap_node(node.pos, node)
    -- degrade old head
    degrade_tupe_node(node1)
end

local function link_node(node, node1, node2)
    -- determine the meta data from both remote heads
    local meta_head1 = minetest.get_meta(node1.pos)
    local meta_head2 = minetest.get_meta(node2.pos)
    local pos1 = minetest.string_to_pos(meta_head1:get_string("remote"))
    local pos2 = minetest.string_to_pos(meta_head2:get_string("remote"))
    local meta_rmt1 = minetest.get_meta(pos1)
    local meta_rmt2 = minetest.get_meta(pos2)
    -- exchange position data
    meta_rmt2:set_string("remote", meta_rmt1:get_string("local"))
    meta_rmt1:set_string("remote", meta_rmt2:get_string("local"))
    -- set to tube2
    node.name = "hyperloop:tube2"
    node.diggable = true
    minetest.swap_node(node.pos, node)
     -- degrade both nodes
    degrade_tupe_node(node1)
    degrade_tupe_node(node2)
end

local function remove_node(pos, node)
    ---minetest.remove_node(pos)   can't call because "on_destruct" will then be called, too
    node.name = "air"
    node.diggable = true
    minetest.swap_node(pos, node)
end

-- simple tube without logic or "memory"
minetest.register_node("hyperloop:tube2", {
	description = "Hyperloop Tube 2",
	tiles = {
		{
			name = "hyperloop_tube_red.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 2.0,
			},
		},
	},

    diggable = false,
	paramtype2 = "facedir",
	groups = {cracky=1, not_in_creative_inventory=1},
	is_ground_content = false,
})

-- single-node and head-node with meta info about the counter part node
for idx = 0,1 do
    minetest.register_node("hyperloop:tube"..idx, {
        description = "Hyperloop Tube "..idx,
        tiles = {
            {
                name = "hyperloop_tube_green.png",
                animation = {
                    type = "vertical_frames",
                    aspect_w = 32,
                    aspect_h = 32,
                    length = 2.0,
                },
            },
        },

        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local res, nodes = scan_neighbours(pos)
            minetest.chat_send_player(placer:get_player_name(), "res="..res)
            local node = minetest.get_node(pos)
            node.pos = pos
            hyperloop.dbg_nodes(nodes)-------------------------------------
            if res == 0 then            -- no neighbor available?
                starter_node(node)
            elseif res == 1 then        -- one neighbor available?
                head_node(node, nodes[1])
            elseif res == 3 then        -- two neighbours available?
                minetest.chat_send_player(placer:get_player_name(), "two neighbours")
                link_node(node, nodes[1], nodes[2])
            else                        -- invalid position
                minetest.chat_send_player(placer:get_player_name(), "Invalid tube block position")
                remove_node(pos, node)
            end
        end,
        
        on_destruct = function(pos)
            print("on_destruct")------------------------------
            local res, nodes = scan_neighbours(pos)
            print("res="..res.." nodes="..dump(nodes))------------------------------
            if res == 4 then
                upgrade_node(pos, nodes[1])
            end
        end,

        on_punch = function(pos, node, puncher, pointed_thing)
            local meta = minetest.get_meta(pos)
            loc = meta:get_string("local")
            rmt = meta:get_string("remote")
            minetest.chat_send_player(puncher:get_player_name(), "local="..loc.." remote="..rmt)
        end,
        
        paramtype2 = "facedir",
        groups = {cracky=2, not_in_creative_inventory=idx},
        is_ground_content = false,
        drop = "hyperloop:tube0",
    })
end

