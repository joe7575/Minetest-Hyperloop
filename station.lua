--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

----------------------------------------------------------------------------------------------------
-- Check if the given construction area is not already protected
----------------------------------------------------------------------------------------------------
local function check_area(pos1, pos2, owner)
	if not areas then return true end
	for id, a in ipairs(areas:getAreasIntersectingArea(pos1, pos2)) do
		print(dump(a.owner))
		if a.owner ~= owner then
			return false
		end
	end
	return true
end

local function assembly_plan(pos, facedir, clbk)
	local placedir = hyperloop.facedir_to_placedir(facedir)
	local res = true
	facedir = (facedir + 1) % 4
	pos = hyperloop.new_pos(pos, placedir, "1L")
	res = clbk(pos, facedir, "hyperloop:tube0") and res
	pos.y = pos.y + 1
	res = clbk(pos, facedir, "hyperloop:pod_wall") and res
	pos.y = pos.y + 1
	res = clbk(pos, facedir, "hyperloop:pod_wall") and res
	pos.y = pos.y - 2
	pos = hyperloop.new_pos(pos, placedir, "1R")
	facedir = (facedir + 2) % 4
	res = clbk(pos, facedir, "hyperloop:tube0") and res
	pos.y = pos.y + 2
	res = clbk(pos, facedir, "hyperloop:lcd") and res
	pos.y = pos.y - 2
	facedir = (facedir + 2) % 4
	pos = hyperloop.new_pos(pos, placedir, "1R")
	res = clbk(pos, facedir, "hyperloop:junction") and res
	pos.y = pos.y + 1
	res = clbk(pos, facedir, "hyperloop:seat") and res
	return res
end


local function check_space(pos, facedir, placer)
	local clbk = function(pos, facedir, block)
		if minetest.is_protected(pos, placer:get_player_name()) then
			return false
		end
		return minetest.get_node_or_nil(pos).name == "air"
	end
	
	local my_pos = table.copy(pos)
	return assembly_plan(my_pos, facedir, clbk)
end

-- Calls the node related "after_place_node()" callback.
-- We have to use this way because "place_node()" can't be used in protected areas
-- (player is unknown) and "add_node()" does not call "after_place_node()".
local function call_callbacks(name, pos, placer, itemstack, pointed_thing)
	local items = ItemStack(name)
	local node = items:get_definition()
	if node.after_place_node ~= nil then
		node.after_place_node(pos, placer, itemstack, pointed_thing)
	end
end

local function construct(pos, facedir, itemstack, placer, pointed_thing)
	local clbk = function(pos, facedir, block)
		if block == "hyperloop:lcd" then
			local tbl = {[0]=4, [1]=2, [2]=5, [3]=3} 
			minetest.add_node(pos, {name=block, paramtype2="wallmounted", param2=tbl[facedir]})
			call_callbacks(block, pos, placer, itemstack, pointed_thing)
		elseif block == "hyperloop:seat" then
			minetest.add_node(pos, {name=block, param2=facedir})
			-- "hyperloop:seat" uses this special function because seat has no "after_place_node()"
			-- But the seat can be used as normal furniture.
			hyperloop.after_seat_placed(pos, facedir)
		else
			minetest.add_node(pos, {name=block, param2=facedir})
			call_callbacks(block, pos, placer, itemstack, pointed_thing)
		end
	end
	
	local my_pos = table.copy(pos)
	return assembly_plan(my_pos, facedir, clbk)
end

minetest.register_node("hyperloop:station", {
	description = "Hyperloop Station Core",
	inventory_image = "hyperloop_station_inventory.png",
	wield_image = "hyperloop_station_inventory.png",

	on_place = function(itemstack, placer, pointed_thing)
		print("on_place")
		local pos = minetest.pointed_thing_to_face_pos(placer, pointed_thing)
		pos.x = pos.x + 0.5
		pos.y = pos.y + 0.5
		pos.z = pos.z + 0.5
		pos = vector.floor(pos)
		print(dump(pos))
		local facedir = hyperloop.get_facedir(placer)
		if check_space(pos, facedir, placer) then
			print("checked")
			construct(pos, facedir, itemstack, placer, pointed_thing)
			itemstack:take_item(1)
			print("done")
		end
		return itemstack
	end,
})