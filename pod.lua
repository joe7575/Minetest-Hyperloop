--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

function hyperloop.enter_display(seat_pos, facedir, text)
    -- Use LCD from digilines. TODO: Own display
	if seat_pos == nil then
		return
	end
    -- activate display
    local pos = vector.add(seat_pos,  hyperloop.facedir2dir(facedir))
    pos.y = pos.y + 1
	
    local node = minetest.get_node(pos)
    local spec = digilines.getspec(node)
    if spec then
        -- Effector actions --> Receive
        if spec.effector then
            spec.effector.action(pos, node, "lcd", text)
        end
    end
end

-- to build the pod
minetest.register_node("hyperloop:pod_wall", {
		description = "Hyperloop Pod Wall",
		tiles = {
			-- up, down, right, left, back, front
			"hyperloop_skin.png^[transformR90]",
			"hyperloop_skin.png^[transformR90]",
			"hyperloop_skin.png",
			"hyperloop_skin.png",
			"hyperloop_skin.png",
			"hyperloop_skin.png",
		},
		paramtype2 = "facedir",
		groups = {cracky=1},
		is_ground_content = false,
	})
