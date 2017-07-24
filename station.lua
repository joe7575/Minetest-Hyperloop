--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

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


local function check_space(pos, facedir)
	local clbk = function(pos, facedir, block)
		return minetest.get_node_or_nil(pos).name == "air"
	end
	
	local my_pos = table.copy(pos)
	return assembly_plan(my_pos, facedir, clbk)
end

local function construct(pos, facedir)
	local clbk = function(pos, facedir, block)
		if block == "hyperloop:lcd" then
			local tbl = {[0]=4, [1]=2, [2]=5, [3]=3} 
			minetest.add_node(pos, {name=block, paramtype2="wallmounted", param2=tbl[facedir]})
			hyperloop.after_lcd_placed(pos, tbl[facedir])
		elseif block == "hyperloop:seat" then
			minetest.add_node(pos, {name=block, param2=facedir})
			hyperloop.after_seat_placed(pos, facedir)
		else
			minetest.place_node(pos, {name=block, param2=facedir})
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
		pos.y = pos.y + 0.5
		--pos = vector.floor(pos)
		print(dump(pos))
		local facedir = hyperloop.get_facedir(placer)
		if check_space(pos, facedir) then
			print("checked")
			construct(pos, facedir)
			itemstack:take_item(1)
			print("done")
		end
		return itemstack
	end,
})