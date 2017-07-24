--[[

	Hyperloop Mod
	=============

	v0.06 by JoSt

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

]]--


hyperloop = {
	data = {
		tAllStations = {},		-- tube networks
		tAllElevators = {},     -- evevators
		tWifi = {},				-- WiFi pairing
		booking = {},			-- placed bookings
		change_counter = 0,		-- used for booking machine updates
	}
}

hyperloop.min_slope_counter = 50

hyperloop.debugging = false

dofile(minetest.get_modpath("hyperloop") .. "/utils.lua")
dofile(minetest.get_modpath("hyperloop") .. "/tube.lua")
dofile(minetest.get_modpath("hyperloop") .. "/booking.lua")
dofile(minetest.get_modpath("hyperloop") .. "/junction.lua")
dofile(minetest.get_modpath("hyperloop") .. "/station.lua")
dofile(minetest.get_modpath("hyperloop") .. "/map.lua")
dofile(minetest.get_modpath("hyperloop") .. "/door.lua")
dofile(minetest.get_modpath("hyperloop") .. "/seat.lua")
dofile(minetest.get_modpath("hyperloop") .. "/pod.lua")
dofile(minetest.get_modpath("hyperloop") .. "/lcd.lua")
dofile(minetest.get_modpath("hyperloop") .. "/wifi.lua")
dofile(minetest.get_modpath("hyperloop") .. "/elevator.lua")
dofile(minetest.get_modpath("hyperloop") .. "/shaft.lua")
dofile(minetest.get_modpath("hyperloop") .. "/deco.lua")
dofile(minetest.get_modpath("hyperloop") .. "/recipes.lua")

print ("[MOD] Hyperloop loaded")
