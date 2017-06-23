minetest = {}
hyperloop = {}
core = {}

DIR_DELIM = ""
function minetest.get_worldpath()
	return "/home/joachim/temp/minetest/mods/hyperloop/"
end

dofile("/home/joachim/temp/minetest/builtin/common/serialize.lua")

minetest.serialize = core.serialize  
minetest.deserialize = core.deserialize  

function minetest.after(t, c)
end

function dump(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

function minetest.register_on_shutdown(list)
	print(dump(list))
end

tAllStations = {
	["Wangen"] = { 
		pos = "(1,2,3)",
		routes = {
			{"1.3", "3.1"},  -- Stuttgart
			{"1.2", "2.1"},  -- München
		},
	},

	["Stuttgart"] = {
		pos = "(1,2,3)",
		routes = {
			{"3.1", "1.3"},   -- Wangen
			{"3.2", "2.3"},   -- München
			{"3.4", "4.3"},   -- Heidelberg
		},
	},

	["München"] = {
		pos = "(1,2,3)",
		routes = {
			{"2.1", "1.2"},   -- Wangen
			{"2.3", "3.2"},   -- Stuttgart
		},
	},

	["Heidelberg"] = {
		pos = "(1,2,3)",
		routes = {
			{"4.3", "3.4"},   -- Heidelberg
		},
	},

	["Berlin"] = {
		pos = "(1,2,3)",
		routes = {
			{"5.6", "6.5"},  -- Hamburg
		},
	},

	["Hamburg"] = {
		pos = "(1,2,3)",
		routes = {
			{"6.5", "5.6"},  -- Berlin
		},
	},
}



require ("table")

function table.copy(t, seen)
	local n = {}
	seen = seen or {}
	seen[t] = n
	for k, v in pairs(t) do
		n[(type(k) == "table" and (seen[k] or table.copy(k, seen))) or k] =
		(type(v) == "table" and (seen[v] or table.copy(v, seen))) or v
	end
	return n
end


function minetest.pos_to_string(pos, decimal_places)
	local x = pos.x
	local y = pos.y
	local z = pos.z
	if decimal_places ~= nil then
		x = string.format("%." .. decimal_places .. "f", x)
		y = string.format("%." .. decimal_places .. "f", y)
		z = string.format("%." .. decimal_places .. "f", z)
	end
	return "(" .. x .. "," .. y .. "," .. z .. ")"
end

function minetest.string_to_pos(value)
	if value == nil then
		return nil
	end

	local p = {}
	p.x, p.y, p.z = string.match(value, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
	if p.x and p.y and p.z then
		p.x = tonumber(p.x)
		p.y = tonumber(p.y)
		p.z = tonumber(p.z)
		return p
	end
	local p = {}
	p.x, p.y, p.z = string.match(value, "^%( *([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+) *%)$")
	if p.x and p.y and p.z then
		p.x = tonumber(p.x)
		p.y = tonumber(p.y)
		p.z = tonumber(p.z)
		return p
	end
	return nil
end

--------------------------------------------------------------------------------
dofile("/home/joachim/temp/minetest/mods/hyperloop/utils.lua")


hyperloop.tAllStations = tAllStations

res = hyperloop.get_stations(table.copy(hyperloop.tAllStations), "Wangen", {})
print(dump(res))
print("")

print(hyperloop.get_stations_as_string())


res = hyperloop.get_stations(table.copy(hyperloop.tAllStations), "München", {})
----print(dump(res))
--print("")

res = hyperloop.get_stations(table.copy(hyperloop.tAllStations), "Berlin", {})
--print(dump(res))
--print("")

--print("")
res = hyperloop.get_stations(table.copy(hyperloop.tAllStations), "Hamburg", {})
--print(dump(res))
--print("")

res = hyperloop.get_stations(table.copy(hyperloop.tAllStations), "Düsseldorf", {})
--print(dump(res))
--print("")


local function final_formspec(name)
	local stations = hyperloop.get_stations(table.copy(hyperloop.tAllStations), name, {})
	local tRes = {"size[10,9]label[3,0;Wähle dein Ziel / Select your destination]"}
	for idx,s in ipairs(stations) do
		if idx < 9 then
			pos1 = "0,"..idx
			pos2 = "3,"..idx
		else
			pos1 = "6,"..(idx-8)
			pos2 = "9,"..(idx-8)
		end
		tRes[#tRes + 1] = "label["..pos1..".2;"..s.."]"
		tRes[#tRes + 1] = "button_exit["..pos2..";1,1;h;X]"
	end
	return table.concat(tRes)
end

print(final_formspec("Wangen"))

hyperloop.store_station_list()



