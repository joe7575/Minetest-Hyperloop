--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local function get_inventory_item(inv)
	local stack = ItemStack("hyperloop:tube0")
	local taken = inv:remove_item("src", stack)
	return taken:get_count() == 1
end

local function get_inventory(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = ItemStack("hyperloop:tube0 99")
	return inv:remove_item("src", stack)
end

local function set_inventory(pos, stack)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	inv:add_item("src", stack)
	return inv
end

local function allow_metadata_inventory(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

local function place_tube(pos, name, facedir, placer)
	if minetest.is_protected(pos, placer:get_player_name()) then
		hyperloop.chat(placer, "Area is protected!")
		return false
	elseif minetest.get_node_or_nil(pos).name ~= "air" and minetest.get_node_or_nil(pos).name ~= "default:water_source" then
		return false
	end
	if hyperloop.scan_neighbours(pos) ~= 1 then
		return false
	end
	minetest.add_node(pos, {name=name, param2=facedir})
	minetest.registered_nodes[name].after_place_node(pos, placer, nil, nil)
	return true
end

local function move_robot(pos, inv, facedir, placer)
	print("move_robot")
	if get_inventory_item(inv) then
		print("get_inventory_item")
		-- remve robot and replace through tube
		local stack = get_inventory(pos)
		minetest.dig_node(pos)
		place_tube(pos, "hyperloop:tube1", facedir, placer)
		-- place robot on the new position
		pos = hyperloop.new_pos(pos, facedir, "1F", 0)
		if place_tube(pos, "hyperloop:robot", facedir, placer) then
			inv = set_inventory(pos, stack)
			print("set_inventory")
			minetest.after(1, move_robot, pos, inv, facedir, placer)
		else
			pos = hyperloop.new_pos(pos, facedir, "1B", 0)
			minetest.dig_node(pos)
			place_tube(pos, "hyperloop:robot", facedir, placer)
			stack:add_item("src", ItemStack("hyperloop:tube0"))
			set_inventory(pos, stack)
		end
	end
end

local station_formspec =
	"size[8,8]"..
	"label[3,0;Hyperloop Tube Robot]" ..
	"label[1,1.3;Hyperloop Tubes]" ..
	"list[context;src;3,1;1,1;]"..
	"button_exit[4,1;1,1;button;Start]"..
	"list[current_player;main;0,4;8,4;]"..
    "listring[context;src]"..
    "listring[current_player;main]"

minetest.register_node("hyperloop:robot", {
	description = "Hyperloop Tube Robot",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_robot.png^[transformR90]",
		"hyperloop_robot.png^[transformR90]",
		"hyperloop_robot.png",
		"hyperloop_robot.png",
		"hyperloop_robot.png",
		"hyperloop_robot.png",
	},
		
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local res, nodes = hyperloop.scan_neighbours(pos)
		if res == 1 then        -- one neighbor available?
			local dir = vector.subtract(pos, nodes[1].pos)
			local facedir = minetest.dir_to_facedir(dir)
			local meta = minetest.get_meta(pos)
			meta:set_int("facedir", facedir)
			meta:set_string("formspec", station_formspec)
			local inv = meta:get_inventory()
			inv:set_size('src', 1)
		else
			hyperloop.chat(player, "You can't start with a Robot block!")
			local node = minetest.get_node(pos)
			hyperloop.remove_node(pos, node)
			return itemstack
		end
	end,
	
	on_receive_fields = function(pos, formname, fields, player)
		if fields.button == nil then
			return
		end
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local facedir = meta:get_int("facedir")
		minetest.after(1, move_robot, pos, inv, facedir, player)
	end,
	
	on_dig = function(pos, node, puncher, pointed_thing)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if inv:is_empty("src") then
			minetest.node_dig(pos, node, puncher, pointed_thing)
		end
	end,

	allow_metadata_inventory_put = allow_metadata_inventory,
	allow_metadata_inventory_take = allow_metadata_inventory,

	paramtype2 = "facedir",
	groups = {cracky=1},
	is_ground_content = false,
})
