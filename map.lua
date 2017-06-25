--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

local function map_on_use(itemstack, user)
	local player_name = user:get_player_name()
	local pos = user:get_pos()
	local sStationList = hyperloop.get_stations_as_string(pos)
	local formspec = "size[8,8]" .. default.gui_bg ..
	default.gui_bg_img ..
	"textarea[0.5,0.5;7.5,8;text;Station List:;" ..
	sStationList .. "]" ..
	"button_exit[2.5,7.5;3,1;close;Close]"

	minetest.show_formspec(player_name, "hyperloop:station_map", formspec)
	return itemstack
end

-- Tool for tube workers to find the next station
minetest.register_node("hyperloop:station_map", {
		description = "Hyperloop Station Map",
		inventory_image = "hyperloop_stations_book.png",
		wield_image = "hyperloop_stations_book.png",
		groups = {cracky=1, book=1},
		on_use = map_on_use,
		on_place = map_on_use,
	})

