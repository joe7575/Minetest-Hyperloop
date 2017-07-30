--[[

	Hyperloop Mod
	=============

	v0.08 by JoSt

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	2017-06-18  v0.01  First version
	2017-07-06  v0.02  Version on GitHub
	2017-07-07  v0.03  Recipes added, settingstypes added
	2017-07-08  v0.04  Door removal issue fixed
	2017-07-16  v0.05  Doors can be opened manually
	2017-07-24  v0.06  Tubes with limited slope, elevator and deco blocks added
	2017-07-28  v0.07  Slope removed, Station auto-builder added
	2017-07-30  v0.08  Signs added, tube robot added, crowbar added

]]--


hyperloop = {
	data = {
		version = 1,				-- compatibility version
		tAllStations = {},		-- tube networks
		tAllElevators = {},     -- evevators
		tWifi = {},				-- WiFi pairing
		booking = {},			-- placed bookings
		change_counter = 0,		-- used for booking machine updates
	}
}

-- Configuration settings
hyperloop.debugging = false		-- for development only
hyperloop.wifi_enabled = minetest.setting_get("hyperloop_wifi_enabled") or false
hyperloop.free_tube_placement_enabled = minetest.setting_get("hyperloop_free_tube_placement_enabled") or false

dofile(minetest.get_modpath("hyperloop") .. "/utils.lua")
dofile(minetest.get_modpath("hyperloop") .. "/tube.lua")
dofile(minetest.get_modpath("hyperloop") .. "/booking.lua")
dofile(minetest.get_modpath("hyperloop") .. "/station.lua")
dofile(minetest.get_modpath("hyperloop") .. "/map.lua")
dofile(minetest.get_modpath("hyperloop") .. "/door.lua")
dofile(minetest.get_modpath("hyperloop") .. "/seat.lua")
dofile(minetest.get_modpath("hyperloop") .. "/robot.lua")
dofile(minetest.get_modpath("hyperloop") .. "/lcd.lua")
dofile(minetest.get_modpath("hyperloop") .. "/wifi.lua")
dofile(minetest.get_modpath("hyperloop") .. "/elevator.lua")
dofile(minetest.get_modpath("hyperloop") .. "/shaft.lua")
dofile(minetest.get_modpath("hyperloop") .. "/deco.lua")
dofile(minetest.get_modpath("hyperloop") .. "/tubecrowbar.lua")
dofile(minetest.get_modpath("hyperloop") .. "/recipes.lua")

print ("[MOD] Hyperloop loaded")
