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
	key_str = get_key_str(pos)			-- station location
	hyperloop.data.tAllStations[key] = {
		routes = {
			{"(-752,2,-313)", "(-757,2,-313)"}, 
			{"(-751,2,-312)", "(-751,2,-309)"}
		}, 
		version = 1,
		time_blocked = 0, 
		booking_pos = {x,y,z},
		booking_info = "...",
		station_name = "..."
		owner = "JoSto", 
		pos = {x,y,z},
		facedir = n,		-- seat -> LCD
	}
	
	Add Station Block: 
		- key_str = get_key_str(pos)
		- version = 1
		- routes = {...}
		- time_blocked = 0
		- owner = placer:name()
		- pos = pos
		- facedir = n
		
	Dig Station Block: 
		tAllStations[key_str] = nil
		
	Add Booking Machine
		- key_str = next located station
		- meta:key_str = key_str
		- station_name = "..."
		- booking_pos = pos
		- booking_info = "..."
		
	Dig Booking Machine
		- key_str = meta:key_str
		- station_name = nil
		- booking_pos = nil
		- booking_info = nil
		
]]--

-- Station Pod Assembly Plan
local AssemblyPlan = {
	-- y-offs, x/z-path, facedir-offs, name
	-- middle slice
	{ 1, "2F", 0, "hyperloop:pod_wall"},
	{ 1, "",   0, "hyperloop:pod_wall"},
	{ 1, "",   0, "hyperloop:pod_wall"},
	{ 0, "1B", 0, "hyperloop:pod_wall"},
	{ 0, "1B", 0, "hyperloop:pod_wall"},
	{ 0, "1B", 0, "hyperloop:pod_wall"},
	{-1, "",   0, "hyperloop:pod_wall"},
	{-1, "",   0, "hyperloop:pod_wall"},
	{ 0, "1F", 2, "hyperloop:seat"},
	{ 1, "1F", 0, "hyperloop:lcd"},
	-- right slice	
	{-1, "1F1R", 0, "hyperloop:pod_wall"},
	{ 1, "",   0, "hyperloop:pod_wall"},
	{ 1, "",   0, "hyperloop:pod_wall"},
	{ 0, "1B", 0, "hyperloop:pod_wall"},
	{ 0, "1B", 0, "hyperloop:pod_wall"},
	{ 0, "1B", 0, "hyperloop:pod_wall"},
	{-1, "",   0, "hyperloop:pod_wall"},
	{-1, "",   0, "hyperloop:pod_wall"},
	{ 0, "1F", 0, "hyperloop:pod_wall"},
	{ 0, "1F", 0, "hyperloop:pod_wall"},
	{ 1, "",   0, "hyperloop:pod_wall"},
	{ 0, "1B", 0, "hyperloop:pod_wall"},
	-- left slice	
	{-1, "2L2R", 0, "hyperloop:pod_wall"},
	{ 1, "",   0, "hyperloop:pod_wall"},
	{ 1, "",   0, "hyperloop:pod_wall"},
	{ 0, "1B", 0, "hyperloop:pod_wall"},
	{ 0, "1B", 0, "hyperloop:pod_wall"},
	{ 0, "1B", 0, "hyperloop:pod_wall"},
	{-1, "",   0, "hyperloop:pod_wall"},
	{-1, "",   0, "hyperloop:pod_wall"},
	{ 0, "1F", 0, "hyperloop:pod_wall"},
	{ 1, "",   0, "hyperloop:pod_wall"},
	{ 0, "1F", 1, "hyperloop:doorTopPassive"},
	{-1, "",   1, "hyperloop:doorBottom"},
}

-- update junction and station blocks
-- pos is the head node position
function hyperloop.update_junction(pos)
	local node = minetest.get_node(pos)
	if node.name ~= "ignore" then   -- node loaded?
		local res, nodes = hyperloop.scan_for_nodes(pos, "hyperloop:junction")
		-- we use this for loop, knowing that max. one junction will be found
		for _,node in ipairs(nodes) do
			minetest.registered_nodes["hyperloop:junction"].update(node.pos)
		end
		res, nodes = hyperloop.scan_for_nodes(pos, "hyperloop:station")
		-- we use this for loop, knowing that max. one junction will be found
		for _,node in ipairs(nodes) do
			minetest.registered_nodes["hyperloop:station"].update(node.pos)
		end
	end
	hyperloop.data.change_counter = hyperloop.data.change_counter + 1
end	

-- station list key
function hyperloop.get_key_str(pos)
	pos = minetest.pos_to_string(pos)
	return '"'..string.sub(pos, 2, -2)..'"'
end

-- return the station data as table, based on the given station key
function hyperloop.get_station_data(key_str)
	if key_str ~= nil and hyperloop.data.tAllStations[key_str] ~= nil then
		local item = table.copy(hyperloop.data.tAllStations[key_str])
		if item.station_name == nil then  --ö station uncomplete?
			return nil
		end
		item.key_str = key_str
		return item
	end
	return nil
end

local function store_station(pos, placer)
	local key_str = hyperloop.get_key_str(pos)
	local facedir = hyperloop.get_facedir(placer)
	-- do a facedir correction 
	facedir = (facedir + 3) % 4				-- face to LCD
	hyperloop.data.tAllStations[key_str] = {
		version=hyperloop.version,			-- for version checks
		pos=pos, 							-- station/junction block
		routes={}, 							-- will be calculated later
		time_blocked=0, 					-- for reservations
		owner=placer:get_player_name(), 
		facedir=facedir						-- face to LCD
	}
end

local function store_junction(pos, placer)
	local key_str = hyperloop.get_key_str(pos)
	hyperloop.data.tAllStations[key_str] = {
		version=hyperloop.version,			-- for version checks
		pos=pos, 							-- station/junction block
		routes={}, 							-- will be calculated later
		owner=placer:get_player_name(), 
		junction=true,
	}
end

-- used for station and junction blocks
local function delete_station(pos)
	local key_str = hyperloop.get_key_str(pos)
	hyperloop.data.tAllStations[key_str] = nil
	hyperloop.data.change_counter = hyperloop.data.change_counter + 1
end

-- called after each change on the tube nodes
local function store_routes(pos)
	local meta = minetest.get_meta(pos)
	local res, nodes = hyperloop.scan_neighbours(pos)
	-- generate a list with all tube heads
	local tRoutes = {}
	for _,node in ipairs(nodes) do
		if node.name == "hyperloop:tube1" then
			local peer = minetest.get_meta(node.pos):get_string("peer")
			local route = {minetest.pos_to_string(node.pos), peer}
			table.insert(tRoutes, route)
		end
	end
	-- store list
	local key_str = hyperloop.get_key_str(pos)
	if hyperloop.data.tAllStations[key_str] ~= nil then
		hyperloop.data.tAllStations[key_str].routes = tRoutes
	end
end


-- Calls the node related "auto_place_node()" callback.
local function call_auto_place_node(name, pos, placer, facedir, key_str)
	local node = minetest.registered_nodes[name]
	if node.auto_place_node ~= nil then
		node.auto_place_node(pos, placer, facedir, key_str)
	end
end

local function place_node(pos, facedir, node_name, placer, key_str)
	if node_name == "hyperloop:lcd" then
		-- wallmounted devices need a facedir correction
		local tbl = {[0]=4, [1]=2, [2]=5, [3]=3} 
		minetest.add_node(pos, {name=node_name, paramtype2="wallmounted", param2=tbl[facedir]})
	else
		minetest.add_node(pos, {name=node_name, param2=facedir})
	end
	call_auto_place_node(node_name, pos, placer, facedir, key_str)
end

-- timer function, called cyclically
local function construct(idx, pos, facedir, placer, key_str)
	local item = AssemblyPlan[idx]
	if item ~= nil then
		local y, path, fd_offs, node_name = item[1], item[2], item[3], item[4]
		pos = hyperloop.new_pos(pos, facedir, path, y)
		place_node(pos, (facedir + fd_offs) % 4, node_name, placer, key_str)
		minetest.after(0.5, construct, idx+1, pos, facedir, placer, key_str)
	else
		hyperloop.chat(placer, "Station completed. Now place the Booking Machine!")
	end
end	
	
local function check_space(pos, facedir, placer)
	for _,item in ipairs(AssemblyPlan) do
		local y, path, node_name = item[1], item[2], item[4]
		pos = hyperloop.new_pos(pos, facedir, path, y)
		if minetest.is_protected(pos, placer:get_player_name()) then
			hyperloop.chat(placer, "Area is protected!")
			return false
		elseif minetest.get_node_or_nil(pos).name ~= "air" then
			hyperloop.chat(placer,"Not enough space to build the station!")
			return false
		end
	end
	return true
end

local station_formspec =
	"size[8,9]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"label[2.5,0;Hyperloop Station Pod Builder]" ..
	"image[0.7,0.9;3,3;hyperloop_station_formspec.png]"..
	"list[context;src;4,0.9;1,4;]"..
	"label[5,1.2;30 x Hypersteel Pod Shell]" ..
	"label[5,2.2;4 x Hypersteel Ingot]" ..
	"label[5,3.2;2 x Blue Wool]" ..
	"label[5,4.2;2 x Glass]" ..
	"list[current_player;main;0,5.3;8,4;]"..
    "listring[context;src]"..
    "listring[current_player;main]"


local function allow_metadata_inventory(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = minetest.get_meta(pos)
	if meta:get_int("busy") == 1 then
		return 0
	end
	return stack:get_count()
end

local function check_inventory(inv, player)
	local list = inv:get_list("src")
	if list[1]:get_name() == "hyperloop:pod_wall" and list[1]:get_count() >= 30 then
		if list[2]:get_name() == "hyperloop:hypersteel_ingot" and list[2]:get_count() >= 4 then
			if list[3]:get_name() == "wool:blue" and list[3]:get_count() >= 2 then
				if list[4]:get_name() == "default:glass" and list[4]:get_count() >= 2 then
					return true
				end
			end
		end
	end
	hyperloop.chat(player,"Not enough inventory items to build the station!")
	return false
end
	
local function remove_inventory_items(inv, meta)
	inv:remove_item("src", ItemStack("hyperloop:pod_wall 30"))
	inv:remove_item("src", ItemStack("hyperloop:hypersteel_ingot 4"))
	inv:remove_item("src", ItemStack("wool:blue 2"))
	inv:remove_item("src", ItemStack("default:glass 2"))
	meta:set_int("busy", 0)
end

local function add_inventory_items(inv)
	inv:add_item("src", ItemStack("hyperloop:pod_wall 30"))
	inv:add_item("src", ItemStack("hyperloop:hypersteel_ingot 4"))
	inv:add_item("src", ItemStack("wool:blue 2"))
	inv:add_item("src", ItemStack("default:glass 2"))
end

local function build_station(pos, placer)
	-- check protection
	if minetest.is_protected(pos, placer:get_player_name()) then
		return
	end			
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local facedir = hyperloop.get_facedir(placer)
	-- do a facedir correction 
	facedir = (facedir + 3) % 4				-- face to LCD
	if check_inventory(inv, placer) then
		local key_str = hyperloop.get_key_str(pos)
		hyperloop.data.tAllStations[key_str].facedir = facedir
		if check_space(table.copy(pos), facedir, placer) then
			construct(1, table.copy(pos), facedir, placer, hyperloop.get_key_str(pos))
			meta:set_string("formspec", station_formspec .. "button_exit[1,3.9;2,1;destroy;Destroy Station]")
			meta:set_int("built", 1)
			meta:set_int("busy", 1)
			-- remove items aften the station is build
			minetest.after(20, remove_inventory_items, inv, meta)
		end
	end
end

local function destroy_station(pos, placer)
	-- check protection
	if minetest.is_protected(pos, placer:get_player_name()) then
		return
	end		
	
	local key_str = hyperloop.get_key_str(pos)
	if key_str ~= nil and hyperloop.data.tAllStations[key_str] ~= nil then
		local facedir = hyperloop.data.tAllStations[key_str].facedir
		-- remove nodes
		local _pos = table.copy(pos)
		for _,item in ipairs(AssemblyPlan) do
			local y, path, node_name = item[1], item[2], item[4]
			_pos = hyperloop.new_pos(_pos, facedir, path, y)
			minetest.remove_node(_pos)
		end
		-- maintain meta
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", station_formspec .. "button_exit[1,3.9;2,1;build;Build Station]")
		local inv = meta:get_inventory()
		add_inventory_items(inv)
		meta:set_int("built", 0)
	else
		local meta = minetest.get_meta(pos)
		meta:set_int("built", 0)
	end
end

minetest.register_node("hyperloop:station", {
	description = "Hyperloop Station Block",
	drawtype = "nodebox",
	tiles = {
		"hyperloop_station.png",
		"hyperloop_station_connection.png",
		"hyperloop_station_connection.png",
	},

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", station_formspec .. "button_exit[1,3.9;2,1;build;Build Station]")
		local inv = meta:get_inventory()
		inv:set_size('src', 4)
	end,
	
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		hyperloop.check_network_level(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Position "..hyperloop.get_key_str(pos))
		store_station(pos, placer)
		store_routes(pos)
		hyperloop.data.change_counter = hyperloop.data.change_counter + 1
	end,

	on_dig = function(pos, node, puncher, pointed_thing)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if inv:is_empty("src") and meta:get_int("built") ~= 1 then
			minetest.node_dig(pos, node, puncher, pointed_thing)
		end
	end,

	allow_metadata_inventory_put = allow_metadata_inventory,
	allow_metadata_inventory_take = allow_metadata_inventory,

	on_receive_fields = function(pos, formname, fields, player)
		if fields.destroy ~= nil then
			destroy_station(pos, player)
		elseif fields.build ~= nil then
			build_station(pos, player)
		end
	end,
		
	on_destruct = delete_station,
			
	-- called from tube head blocks
	update = function(pos)
		if hyperloop.debugging then
			print("Station update() called")
		end
		store_routes(pos)
	end,
	
	paramtype2 = "facedir",
	groups = {cracky=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("hyperloop:junction", {
	description = "Hyperloop Junction Block",
	tiles = {
		"hyperloop_junction_top.png",
		"hyperloop_junction_top.png",
		"hyperloop_station_connection.png",
	},

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		hyperloop.check_network_level(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Position "..hyperloop.get_key_str(pos))
		store_junction(pos, placer)
		store_routes(pos)
		hyperloop.data.change_counter = hyperloop.data.change_counter + 1
	end,

	on_destruct = delete_station,

	-- called from tube head blocks
	update = function(pos)
		if hyperloop.debugging then
			print("Junction update() called")
		end
		store_routes(pos)
	end,

	paramtype2 = "facedir",
	groups = {cracky=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("hyperloop:pod_wall", {
	description = "Hyperloop Pod Shell",
	tiles = {
		-- up, down, right, left, back, front
		"hyperloop_skin2.png",
		"hyperloop_skin2.png",
		"hyperloop_skin.png",
	},
	paramtype2 = "facedir",
	groups = {cracky=2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})


minetest.register_lbm({
	label = "[Hyperloop] Station update",
	name = "hyperloop:update",
	nodenames = {"hyperloop:junction", "hyperloop:station"},
	run_at_every_load = true,
	action = function(pos, node)
		if hyperloop.debugging then
			print("Junction/Station loaded")
		end
		store_routes(pos)
	end
})

