--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017-2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

]]--

local Tube = hyperloop.Tube

local sFormspec = "size[7.5,3]"..
	"field[0.5,1;7,1;channel;Enter channel string;]" ..
	"button_exit[2,2;3,1;exit;Save]"

minetest.register_node("hyperloop:tube_wifi1", {
	description = "Hyperloop WiFi Tube",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_locked.png^[transformR90]",
		"hyperloop_tube_wifi.png",
	},

	after_place_node = function(pos, placer)
		-- determine the tube side
		local tube_dir = Tube:get_primary_dir(pos)
		if tube_dir then		
			Tube:prepare_pairing(pos, tube_dir, sFormspec)
			Tube:after_place_node(pos, {tube_dir})
		end
	end,

	tubelib2_on_update = function(pos, out_dir, peer_pos, peer_in_dir)
		Tube:prepare_pairing(pos, out_dir, sFormspec)
	end,
	
	on_receive_fields = function(pos, formname, fields, player)
		if fields.channel ~= nil then
			Tube:pairing(pos, fields.channel)
		end
	end,
	
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		Tube:stop_pairing(pos, oldmetadata, sFormspec)
		local tube_dir = tonumber(oldmetadata.fields.tube_dir or 0)
		Tube:after_dig_node(pos, {tube_dir})
	end,

	paramtype2 = "facedir",
	on_rotate = screwdriver.disallow,
	paramtype = "light",
	groups = {cracky = 2},
	sunlight_propagates = true,
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

