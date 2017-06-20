-- We need:
-- * tube_power0, can be placed and docked by a tube
-- * tube_power1, can be docked by a second tube
-- * tube_power2, can't be docked by a third tube
for idx = 0,2 do
    local img 
    if idx < 2 then
        img = "hyperloop_power_tube_green.png"
    else
        img = "hyperloop_power_tube_red.png"
    end
    minetest.register_node("hyperloop:tube_power"..idx, {
        description = "Hyperloop Power Tube",
        tiles = {
            {
                name = img,
                animation = {
                    type = "vertical_frames",
                    aspect_w = 32,
                    aspect_h = 32,
                    length = 2.0,
                },
            },
        },

        after_place_node = function(pos, placer, itemstack, pointed_thing)
            local nodes = scan_tube_neighbours(pos, true, {"hyperloop:tube_head", "hyperloop:tube_power1"})
            -- power node can't be placed nearby another power node
            for _,node in ipairs(nodes) do
                if node.name == "hyperloop:tube_power0" or node.name == "hyperloop:tube_power1" then
                    -- remove node again
                    minetest.chat_send_player(placer:get_player_name(), "Power Tube block can't be placed here.")
                    minetest.remove_node(pos)
                    return
                end
            end

            local meta = minetest.get_meta(pos)
            local station_name = meta:get_string("station") or "<unknown>"
            local ring_addr
            if #nodes == 0 then     -- are we the one and only?
                --print("start ring")----------------------
                -- a new ring starts here
                ring_addr = determine_ring_addr(pos)
            else
                --print("degrade to tubes")----------------------
                -- degrade neighbor nodes
                swap_to_tube(pos, placer, nodes)
                ring_addr = meta:get_string("ring_addr")

                -- already connected with two tube nodes?
                if #nodes == 2 then
                    --print("switch to tube_power1")----------------------
                    -- tube_power1 cant be docked by a third tube
                    local node = minetest.get_node(pos)
                    node.name = "hyperloop:tube_power1"    
                    minetest.swap_node(pos, node)
                end
            end
            meta:set_string("infotext", "Power Tube block "..idx..". ring at: "..ring_addr.." Station Name: "..station_name)
            -- store ring_addr in ring list
            if hyperloop.ringList[ring_addr] ~= nil then
                table.insert(hyperloop.ringList[ring_addr], pos)
            else
                hyperloop.ringList[ring_addr] = {pos}
            end
            --print("store ring_addr in ring list")-------------------------------------
            --hyperloop.dbg_ringlist()------------------------------------------
        end,

        on_destruct = function(pos)
            local nodes = scan_tube_neighbours(pos, true, {"hyperloop:tube"})
            -- upgrade neighbor nodes
            swap_to_tube_head(pos, nodes)
        end,

        paramtype2 = "facedir",
        groups = {cracky=2, not_in_creative_inventory=idx},
        is_ground_content = false,
        drop = "hyperloop:tube_power0",
    })
end


