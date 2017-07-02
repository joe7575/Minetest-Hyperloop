--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

--[[

	[H1]----[H2][W1]     [W2][H3]----[H4]
	pairing:
	- W1 placed:
		hyperloop.tWifi[channel] = pos_W1

	- W2 placed:
		pos_W1 = hyperloop.tWifi[channel]
		wifi_pairing(pos_W2, pos_W1)
			determine pos_H4 via H3
			call W1.update(pos_H4)

	- W1 update(pos_H4) called:
		determine pos_H1 via H2
		update H1 with pos_H4
		degrade H2 to tube2
		return pos_H1

	- W2:
		update H4 with pos_H1
		degrade H3 to tube2

]]--

local function search_head(pos)
	local res, nodes = hyperloop.scan_neighbours(pos)
	if res == 1 then        -- one neighbor available?
		return nodes[1]
	end
end

local function read_peer_pos(pos)
	local meta = minetest.get_meta(pos)
	return meta:get_string("peer")
end
	
local function wifi_register(pos, channel)
	if hyperloop.tWifi[channel] == nil then
		hyperloop.tWifi[channel] = pos
		return nil
	else
		local pos = hyperloop.tWifi[channel]
		hyperloop.tWifi[channel] = nil
		return pos
	end
end

local function wifi_update(pos, peer_pos)
	local rmt_head_pos1	 -- own remote tube head 
	local local_head     -- local tube head node 
	-- determine remote tube head via local tube head
	local_head = search_head(pos)
	rmt_head_pos1 = read_peer_pos(local_head.pos)
	if rmt_head_pos1 == nil then
		return nil
	end
	-- store peer_pos and tube head pos locally
	minetest.get_meta(pos):set_string("wifi_peer", peer_pos)
	minetest.get_meta(pos):set_string("peer", rmt_head_pos1)
	-- degrade head tube to link tube
	hyperloop.degrade_tupe_node(local_head)
	return rmt_head_pos1
end

local function wifi_pairing(pos, peer_pos)
	local rmt_head_pos1	 -- own remote tube head 
	local rmt_head_pos2  -- remote tube head of the peer wifi node
	local local_head     -- local tube head node 
	-- determine remote tube head via local tube head
	local_head = search_head(pos)
	rmt_head_pos1 = read_peer_pos(local_head.pos)
	if rmt_head_pos1 == nil then
		return false
	end
	-- update the peer wifi node also to get the other remote tube head pos
	rmt_head_pos2 = wifi_update(peer_pos, pos)
	-- update both remote tube head nodes with the position from each other
	hyperloop.update_head_node(rmt_head_pos1, rmt_head_pos2)
	hyperloop.update_head_node(rmt_head_pos2, rmt_head_pos1)
	-- store peer_pos and tube head pos locally
	minetest.get_meta(pos):set_string("wifi_peer", peer_pos)
	minetest.get_meta(pos):set_string("peer", rmt_head_pos1)
	-- degrade head tube to link tube
	hyperloop.degrade_tupe_node(local_head)
	return true
end

minetest.register_node("hyperloop:tube_wifi1", {
		description = "Hyperloop WiFi Tube",
		inventory_image = "hyperloop_tube_wifi_inventory.png",
		drawtype = "nodebox",
		tiles = {
			-- up, down, right, left, back, front
			"hyperloop_tube_locked.png^[transformR90]",
			"hyperloop_tube_locked.png^[transformR90]",
			"hyperloop_tube_wifi.png",
			"hyperloop_tube_wifi.png",
			"hyperloop_tube_wifi.png",
			"hyperloop_tube_wifi.png",
			--"hyperloop_tube_wifi.png",
			--"hyperloop_tube_wifi.png",
		},

		after_place_node = function(pos, placer, itemstack, pointed_thing)
			local res, nodes = hyperloop.scan_neighbours(pos)
			if res == 1 and nodes[1].name == "hyperloop:tube1" then
				local formspec = "size[5,4]"..
				"field[0.5,0.5;3,1;channel;Insert channel ID;myName:myChannel]" ..
				"button_exit[1,2;2,1;exit;Save]"
				local meta = minetest.get_meta(pos)
				meta:set_string("formspec", formspec)
			else
				local node = minetest.get_node(pos)
				hyperloop.remove_node(pos, node)
				return itemstack
			end
		end,
		
		on_receive_fields = function(pos, formname, fields, player)
			if fields.channel == nil then
				return
			end
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec", nil)
			local peer_pos = wifi_register(pos, fields.channel)
			if peer_pos then
				if wifi_pairing(pos, peer_pos, true) ~= nil then
					minetest.chat_send_player(player:get_player_name(), 
						"WiFi pairing completed!")
					hyperloop.update_all_booking_machines()
				end
			end
		end,

		on_destruct = function(pos)
			-- unpair peer wifi node
			local peer = minetest.get_meta(pos):get_string("wifi_peer")
			peer = minetest.string_to_pos(peer)
			if peer ~= nil then
				hyperloop.upgrade_node(peer)
			end
			-- unpair local wifi node
			hyperloop.upgrade_node(pos)
			hyperloop.update_all_booking_machines()
		end,

		paramtype2 = "facedir",
		groups = {cracky=2},
		is_ground_content = false,
	})

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


