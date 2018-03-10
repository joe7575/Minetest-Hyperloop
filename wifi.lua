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
		hyperloop.data.tWifi[channel] = pos_W1

	- W2 placed:
		pos_W1 = hyperloop.data.tWifi[channel]
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
	if res == 1 or res == 4 then        -- one neighbor available?
		return nodes[1]
	end
end

local function get_head_node_pos(pos)
	local meta = minetest.get_meta(pos)
	local head_node_pos = meta:get_string("head_node_pos")
	if head_node_pos == nil then
		return nil
	end
	return minetest.string_to_pos(head_node_pos)
end

local function read_peer_pos(pos)
	if pos ~= nil then
		local meta = minetest.get_meta(pos)
		return meta:get_string("peer")
	else
		return nil
	end
end

local function wifi_register(pos, channel)
	if hyperloop.data.tWifi[channel] == nil then
		hyperloop.data.tWifi[channel] = pos
		return nil
	elseif vector.equals(hyperloop.data.tWifi[channel], pos) then
		return nil
	else
		local pos = hyperloop.data.tWifi[channel]
		hyperloop.data.tWifi[channel] = nil
		return pos
	end
end

local function wifi_unregister(pos)
	-- delete channel registration
	local meta = minetest.get_meta(pos)
	local channel = meta:get_string("channel")
	if channel ~= nil and hyperloop.data.tWifi[channel] ~= nil 
	and vector.equals(hyperloop.data.tWifi[channel], pos) then
		hyperloop.data.tWifi[channel] = nil
	end
end

local function wifi_update(pos, peer_pos)
	local rmt_head_pos1 = read_peer_pos(pos)
	if rmt_head_pos1 == nil then
		return nil
	end
	-- store peer_pos and tube head pos locally
	minetest.get_meta(pos):set_string("wifi_peer", peer_pos)
	minetest.get_meta(pos):set_string("infotext", "tube peer="..rmt_head_pos1..
					" wifi peer="..minetest.pos_to_string(peer_pos))
	return rmt_head_pos1
end

local function wifi_pairing(pos, peer_pos)
	local rmt_head_pos1	 -- own remote tube head 
	local rmt_head_pos2  -- remote tube head of the peer wifi node
	rmt_head_pos1 = read_peer_pos(pos)
	if rmt_head_pos1 == nil then
		return false
	end
	-- update the peer wifi node also to get the other remote tube head pos
	rmt_head_pos2 = wifi_update(peer_pos, pos)
	if rmt_head_pos2 == nil then
		return false
	end
	-- update both remote tube head nodes with the position from each other
	hyperloop.update_head_node(rmt_head_pos1, rmt_head_pos2)
	hyperloop.update_head_node(rmt_head_pos2, rmt_head_pos1)
	-- store peer_pos and tube head pos locally
	minetest.get_meta(pos):set_string("wifi_peer", peer_pos)
	minetest.get_meta(pos):set_string("infotext", "tube peer="..rmt_head_pos1..
					" wifi peer="..minetest.pos_to_string(peer_pos))
	if hyperloop.debugging then
		print("wifi_pairing meta="..dump(minetest.get_meta(pos):to_table()))
	end
	return true
end

-- Place the wifi node as head of a tube chain
local function place_wifi_node(pos, head_node)
	local peer_pos = minetest.get_meta(head_node.pos):get_string("peer")
	-- update self
	hyperloop.update_head_node(minetest.pos_to_string(pos), peer_pos)
	-- update peer
	hyperloop.update_head_node(peer_pos, minetest.pos_to_string(pos))
	-- degrade head tube to link tube
	hyperloop.degrade_tupe_node(head_node, pos)
	if hyperloop.debugging then
		print("wifi meta="..dump(minetest.get_meta(pos):to_table()))
	end
end


minetest.register_node("hyperloop:tube_wifi1", {
	description = "Hyperloop WiFi Tube",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_wifi.png",
	},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local head_node = search_head(pos)
		if head_node ~= nil then
			if head_node.name == "hyperloop:tube1" then
				local formspec = "size[5,4]"..
				"field[0.5,0.5;3,1;channel;Insert channel ID;chA]" ..
				"button_exit[1,2;2,1;exit;Save]"
				local meta = minetest.get_meta(pos)
				meta:set_string("formspec", formspec)
				local head_node_pos = minetest.pos_to_string(head_node.pos)
				meta:set_string("head_node_pos", head_node_pos)
				place_wifi_node(pos, head_node)
			else
				local node = minetest.get_node(pos)
				hyperloop.remove_node(pos, node)
				return itemstack
			end
		else
			hyperloop.chat(player, "You can't start with a WiFi block!")
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
		meta:set_string("channel", fields.channel)
		local peer_pos = wifi_register(pos, fields.channel)
		if peer_pos ~= nil then
			if wifi_pairing(pos, peer_pos) then
				hyperloop.chat(player, "WiFi pairing completed!")
				meta:set_string("formspec", nil)
			else
				hyperloop.chat(player, "Pairing fault. Retry please!")
			end
		end
		hyperloop.data.change_counter = hyperloop.data.change_counter + 1
	end,

	on_destruct = function(pos)
		-- unpair peer wifi node
		local peer = minetest.get_meta(pos):get_string("wifi_peer")
		peer = minetest.string_to_pos(peer)
		if peer ~= nil then
			hyperloop.upgrade_node(peer)
		else  -- no pairing so far
			-- delete channel registration
			wifi_unregister(pos)
		end
		-- unpair local wifi node
		hyperloop.upgrade_node(pos)
		hyperloop.data.change_counter = hyperloop.data.change_counter + 1
	end,

	paramtype2 = "facedir",
	groups = {cracky=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})
