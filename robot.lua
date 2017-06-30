--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local function move_robot(pos, dir, number, cnt)
	if number > 1 then
		pos = vector.add(pos, dir)
		minetest.place_node(pos, {name="hyperloop:tube1", param2=minetest.dir_to_facedir(dir)})
		if cnt == 8 then
			local pos1 = table.copy(pos)
			cnt = 0
			print("jetzt")
			for i = 1,20 do
				pos1.y = pos1.y - 1
				minetest.place_node(pos1, {name="hyperloop:pillar"})
			end
		end
		minetest.after(1, move_robot, pos, dir, number-1, cnt+1)
	end
end

-- to build the pod
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
			local meta = minetest.get_meta(pos)
			local formspec = "size[5,4]"..
			"field[0.5,0.5;3,1;number;Insert Block number (1.99);5]" ..
			"button_exit[1,2;2,1;exit;Save]"
			local res, nodes = hyperloop.scan_neighbours(pos)
			if res == 1 then        -- one neighbor available?
				meta:set_string("formspec", formspec)
				local dir = vector.subtract(pos, nodes[1].pos)
				meta:set_string("dir", minetest.pos_to_string(dir))
				print(dump(dir))
			end
		end,
		
		on_receive_fields = function(pos, formname, fields, player)
			if fields.number == nil then
				return
			end
			local number = tonumber(fields.number)
			if number == nil then
				return
			end
			local meta = minetest.get_meta(pos)
			local dir = minetest.string_to_pos(meta:get_string("dir"))
			minetest.dig_node(pos)
			pos.y = pos.y + 1
			minetest.place_node(pos, {name="hyperloop:tube1", param2=minetest.dir_to_facedir(dir)})
			minetest.after(1, move_robot, pos, dir, number, 1)
		end,
		
		paramtype2 = "facedir",
		groups = {cracky=1},
		is_ground_content = false,
	})
