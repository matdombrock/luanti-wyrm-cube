
local w = "group:wool"
local b = "group:boat"
local m = "mcl_core:iron_ingot"
local s = "mcl_mobitems:string"
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