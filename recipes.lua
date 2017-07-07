--[[

	Hyperloop Mod
	=============

	Copyright (C) 2017 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	see init.lua

]]--

hyperloop.wifi_enabled = minetest.setting_get("hyperloop_wifi_enabled") or false


minetest.register_craftitem("hyperloop:hypersteel_ingot", {
	description = "Hypersteel Ingot",
	inventory_image = "hyperloop_hypersteel_ingot.png",
})


minetest.register_craft({
	output = "hyperloop:hypersteel_ingot 3",
	recipe = {
		{"default:steel_ingot", "default:tin_ingot"},
		{"default:copper_ingot", "dye:cyan"},
	},
})

minetest.register_craft({
	output = "hyperloop:tube0 8",
	recipe = {
		{"", "hyperloop:hypersteel_ingot", ""},
		{"hyperloop:hypersteel_ingot", "", "hyperloop:hypersteel_ingot"},
		{"", "hyperloop:hypersteel_ingot", ""},
	},
})

minetest.register_craft({
	output = "hyperloop:pillar 8",
	recipe = {
		{"", "hyperloop:hypersteel_ingot", ""},
		{"", "hyperloop:hypersteel_ingot", ""},
		{"", "hyperloop:hypersteel_ingot", ""},
	},
})

minetest.register_craft({
	output = "hyperloop:seat",
	recipe = {
		{"", "", "wool:blue"},
		{"wool:blue", "wool:blue", "wool:blue"},
		{"wool:blue", "hyperloop:hypersteel_ingot", "hyperloop:hypersteel_ingot"},
	},
})

minetest.register_craft({
	output = "hyperloop:pod_wall 8",
	recipe = {
		{"hyperloop:hypersteel_ingot", "hyperloop:hypersteel_ingot", "hyperloop:hypersteel_ingot"},
		{"hyperloop:hypersteel_ingot", "dye:cyan", "hyperloop:hypersteel_ingot"},
		{"hyperloop:hypersteel_ingot", "hyperloop:hypersteel_ingot", "hyperloop:hypersteel_ingot"},
	},
})

minetest.register_craft({
	output = "hyperloop:booking 1",
	recipe = {
		{"hyperloop:hypersteel_ingot", "", "hyperloop:hypersteel_ingot"},
		{"", "default:paper", ""},
		{"hyperloop:hypersteel_ingot", "", "hyperloop:hypersteel_ingot"},
	},
})



minetest.register_craft({
	output = "hyperloop:junction",
	recipe = {
		{"", "hyperloop:hypersteel_ingot", ""},
		{"hyperloop:hypersteel_ingot", "default:mese_crystal", "hyperloop:hypersteel_ingot"},
		{"", "hyperloop:hypersteel_ingot", ""},
	},
})

 if hyperloop.wifi_enabled then
	minetest.register_craft({
		output = "hyperloop:tube_wifi1 2",
		recipe = {
			{"default:mese_crystal", "hyperloop:hypersteel_ingot", "default:mese_crystal"},
			{"hyperloop:hypersteel_ingot", "default:mese_crystal", "hyperloop:hypersteel_ingot"},
			{"default:mese_crystal", "hyperloop:hypersteel_ingot", "default:mese_crystal"},
		},
	})
end

minetest.register_craft({
	output = "hyperloop:station_map",
	recipe = {
		{"default:paper", "dye:red", ""},
		{"default:paper", "dye:red", ""},
		{"default:paper", "dye:red", ""},
	},
})

minetest.register_craft({
	output = "hyperloop:lcd",
	recipe = {
		{"default:mese_crystal", "default:glass", ""},
		{"dye:black", "default:glass", ""},
		{"hyperloop:hypersteel_ingot", "default:glass", ""},
	},
})
