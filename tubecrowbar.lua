--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017-2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("hyperloop")
local I, NS = dofile(MP.."/intllib.lua")

local Shaft = hyperloop.Shaft
local Tube = hyperloop.Tube


local function chat_message(dir, cnt, peer_pos, peer_dir)
	local sdir = tubelib2.dir_to_string(dir)
	if Shaft:secondary_node(peer_pos, peer_dir) then
		local npos, node = Shaft:get_node(peer_pos, peer_dir)
		return "[Hyperloop] To the "..sdir..": "..cnt.." tube nodes to "..node.name.." at "..S(npos)
	else
		return "[Hyperloop] To the "..sdir..": "..cnt.." tube nodes to "..S(peer_pos)
	end
end

local function repair_tubes(itemstack, placer, pointed_thing)
	if pointed_thing.type == "node" then
		local pos = pointed_thing.under
		local dir1, dir2, fpos1, fpos2, fdir1, fdir2, cnt1, cnt2 = 
				Shaft:tool_repair_tube(pos, placer, pointed_thing)
		if fpos1 and fpos2 then
			minetest.chat_send_player(placer:get_player_name(), chat_message(dir1, cnt1, fpos1, fdir1))
			minetest.chat_send_player(placer:get_player_name(), chat_message(dir2, cnt2, fpos2, fdir2))
			minetest.sound_play({
				name="hyperloop_crowbar"},{
				pos = pos,
				gain=2,
				max_hear_distance=5,
				loop=false})
		else
			local dir1, dir2, fpos1, fpos2, fdir1, fdir2, cnt1, cnt2 = 
					Tube:tool_repair_tube(pos, placer, pointed_thing)
			if fpos1 and fpos2 then
				minetest.chat_send_player(placer:get_player_name(), chat_message(dir1, cnt1, fpos1, fdir1))
				minetest.chat_send_player(placer:get_player_name(), chat_message(dir2, cnt2, fpos2, fdir2))
				minetest.sound_play({
					name="hyperloop_crowbar"},{
					pos = pos,
					gain=2,
					max_hear_distance=5,
					loop=false})
			end
		end
	else
		minetest.chat_send_player(placer:get_player_name(), 
			I("[Crowbar Help]\n")..
			I("    left: remove node\n")..
			I("    right: repair tube/shaft line\n"))
	end
end

local function add_to_inventory(placer, item_name)
	local inv = placer:get_inventory()
	local item = ItemStack(item_name)
	if inv and item and inv:room_for_item("main", item) then
		inv:add_item("main", item)
	end
end	

local function remove_tube(itemstack, placer, pointed_thing)
	if minetest.check_player_privs(placer:get_player_name(), "hyperloop") then
		if pointed_thing.type == "node" then
			local pos = pointed_thing.under
			if Shaft:tool_remove_tube(pos, "default_break_glass") then
				add_to_inventory(placer, "hyperloop:shaft")
			elseif Tube:tool_remove_tube(pos, "default_break_glass") then
				add_to_inventory(placer, "hyperloop:tubeS")
			end
		end
	else
		minetest.chat_send_player(placer:get_player_name(), I("You don't have the necessary privs!"))
	end
end

local function dump_data_base(pos)
	print(dump(hyperloop.tDatabase))
end

-- Tool for tube workers to crack a protected tube line
minetest.register_node("hyperloop:tube_crowbar", {
	description = I("Hyperloop Tube Crowbar"),
	inventory_image = "hyperloop_tubecrowbar.png",
	wield_image = "hyperloop_tubecrowbar.png",
	use_texture_alpha = true,
	groups = {cracky=1, book=1},
	on_use = remove_tube,
	on_place = repair_tubes,
	on_secondary_use = repair_tubes,
	node_placement_prediction = "",
	stack_max = 1,
})

minetest.register_privilege("hyperloop", 
	{description = "Rights to remove tube nodes by means of the crowbar", 
	give_to_singleplayer = false})

