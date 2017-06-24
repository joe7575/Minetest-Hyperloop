--[[

	Hyperloop Mod
	=============

	v0.01 by JoSt

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	2017-06-18  v0.01  First version

]]--


hyperloop = {
    tAllStations = {},
	order = {},
}

dofile(minetest.get_modpath("hyperloop") .. "/utils.lua")
dofile(minetest.get_modpath("hyperloop") .. "/tubes.lua")
dofile(minetest.get_modpath("hyperloop") .. "/order.lua")
dofile(minetest.get_modpath("hyperloop") .. "/station.lua")
dofile(minetest.get_modpath("hyperloop") .. "/door.lua")
dofile(minetest.get_modpath("hyperloop") .. "/seat.lua")

print ("[MOD] Hyperloop loaded")
