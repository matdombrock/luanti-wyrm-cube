
local w = "group:wool"
if not minetest.get_modpath("farming") then w = "default:paper" end
local b = "boats:boat"
local m = "default:steel_ingot"
local s = "farming:string"
minetest.register_craft({
	output = "sum_airship:canvas_roll",
	recipe = {
		{w, w, w},
		{w, w, w},
		{w, w, w},
	},
})
minetest.register_craft({
	output = "sum_airship:hull",
	recipe = {
		{b, b, b},
		{m, m, m},
	},
})
minetest.register_craft({
	output = "sum_airship:boat",
	recipe = {
		{"sum_airship:canvas_roll","sum_airship:canvas_roll","sum_airship:canvas_roll",},
		{s, m, s,},
		{s, "sum_airship:hull", s,},
	},
})