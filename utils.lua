--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local PI = 3.1415926

hyperloop.NeighborPos = {
    { x=1,  y=0,  z=0},
    { x=-1, y=0,  z=0},
    { x=0,  y=1,  z=0},
    { x=0,  y=-1, z=0},
    { x=0,  y=0,  z=1},
    { x=0,  y=0,  z=-1},
}

function hyperloop.rad2facedir(yaw)
    -- radiant (0..2*PI) to my facedir (0..3) from N, W, S to E
    return math.floor((yaw + PI/4) / PI * 2) % 4
end

function hyperloop.facedir2rad(facedir)
    -- my facedir (0..3) from N, W, S to E to radiant (0..2*PI)
    return facedir / 2 * PI
end

function hyperloop.facedir2dir(facedir)
    -- my facedir (0..3) from N, W, S to E to dir vector
    local tbl = {
        [0] = { x=0,  y=0, z=1},
        [1] = { x=-1, y=0, z=0},
        [2] = { x=0,  y=0, z=-1},
        [3] = { x=1,  y=0, z=0},
    }
    return tbl[facedir % 4]
end

function hyperloop.turnright(dir)
	local facedir = minetest.dir_to_facedir(dir)
	return minetest.facedir_to_dir((facedir + 1) % 4)
end

function hyperloop.turnleft(dir)
	local facedir = minetest.dir_to_facedir(dir)
	return minetest.facedir_to_dir((facedir + 3) % 4)
end

-- File writing / reading utilities
local wpath = minetest.get_worldpath()

function hyperloop.file2table(filename)
	local f = io.open(wpath..DIR_DELIM..filename, "r")
	if f == nil then return {} end
	local t = f:read("*all")
	f:close()
	if t == "" or t == nil then return {} end
	return minetest.deserialize(t)
end

function hyperloop.table2file(filename, table)
	local f = io.open(wpath..DIR_DELIM..filename, "w")
	f:write(minetest.serialize(table))
	f:close()
end

function hyperloop.store_ring_list()
	hyperloop.table2file("hyperloop_ringlist", hyperloop.ringList)
end


function hyperloop.dbg_ringlist()
    print("RingList:")
    print(dump(hyperloop.ringList))-------------------------------------------
    for addr,list in ipairs(hyperloop.ringList) do
        for idx, pos in ipairs(list) do
            print("addr:"..addr.." idx:"..idx.." pos:"..minetest.pos_to_string(pos))
        end
    end
end

function hyperloop.dbg_nodes(nodes)
    print("Nodes:")
    for _,node in ipairs(nodes) do
        print("name:"..node.name)
    end
end

-- Store and read the RingList to / from a file
-- so that upcoming actions are remembered when the game
-- is restarted
hyperloop.ringList = hyperloop.file2table("hyperloop_ringlist")

minetest.register_on_shutdown(hyperloop.store_ring_list)

-- store ring list once a day
minetest.after(60*60*24, hyperloop.store_ring_list)

