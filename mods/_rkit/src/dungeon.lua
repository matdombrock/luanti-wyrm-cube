-- room_sizexroom_size
--[[
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
X . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . X . . . . . . . . . . . . . . . 
--]]

-- cfg
local dungeon_size = 8
local room_height = 6
local room_size = 31

local bom_dungeon = {
	["."] = { name = "air" },
	a = { name = "air" },
	-- s = { name = "default:stone" },
	s = { name = "default:stonebrick" },
	l = { name = "wool:white" },
	L = { name = "default:ladder_steel", param2 = 3 },
	w = { name = "default:wood" },
	W = { name = "default:acacia_wood" },
	o = { name = "default:glass" },
	t = { name = "default:torch_wall", param2 = 2 },
	T = { name = "default:torch_wall", param2 = 3 },
	b = { name = "beds:bed_bottom", param2 = 1 },
	B = { name = "beds:bed_top", param2 = 1 },
	h = { name = "default:bookshelf", param2 = 1 },
	c = { name = "default:chest", param2 = 1 },
	f = { name = "stairs:slab_wood" },
	F = { name = "flowers:tulip" },
	n = { name = "default:fence_acacia_wood" },
	g = { name = "doors:gate_acacia_wood_closed" },
	d = { name = "doors:door_glass_a", param2 = 3 },
	D = { name = "doors:door_glass_a", param2 = 1 },
	r = { name = "default:dirt" },
	["~"] = { name = "default:water_source" },
}

local def_ar_opt = { ceiling_str = "." }

local room_bps = {}

local function add_auto_room(layers)
	table.insert(room_bps, Rkit_structures.auto_room(layers, room_size, room_size, room_height, def_ar_opt))
end

add_auto_room({
	[[
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
]],
})

add_auto_room({
	[[
W . . . . . . . . . . . . . . . . . . . . . . . . . . . . . W 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
W . . . . . . . . . . . . . . . . . . . . . . . . . . . . . W 
]],
})

add_auto_room({
	[[
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . s . . . . . . . . . . . . . . . . . . . . . . . s . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . s . . . . . . . . . . . . . . . . . . . . . . . s . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
]],
})

add_auto_room({
	[[
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
]],
})

add_auto_room({
	[[
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s w . . . . . . . . . . . . . . . . . . . . . . . . . . . w s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . w s s s o s s s w . . . . . . . . . . s 
s . . . . . . . . . . s . . . . . . . s . . . . . . . . . . s 
s . . . . . . . . . . s . . . . . . . s . . . . . . . . . . s 
. s s s s . s s s s s s . . . s . . . s s s s s s . s s s s . 
. . . . . . . . . . . o . . s s s . . o . . . . . . . . . . . 
. s s s s . s s s s s s . . . s . . . s s s s s s . s s s s . 
s . . . . . . . . . . s . . . . . . . s . . . . . . . . . . s 
s . . . . . . . . . . s . . . . . . . s . . . . . . . . . . s 
s . . . . . . . . . . w d s s d s s d w . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s w . . . . . . . . . . . . s . s . . . . . . . . . . . . w s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
]],
	[[
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s w . . . . . . . . . . . . . . . . . . . . . . . . . . . w s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . w s s s o s s s w . . . . . . . . . . s 
s . . . . . . . . . . s . . . . . . . s . . . . . . . . . . s 
s . . . . . . . . . . s . . . . . . . s . . . . . . . . . . s 
. s s s s . s s s s s s . . . s . . . s s s s s s . s s s s . 
. . . . . . . . . . . o . . s s s . . o . . . . . . . . . . . 
. s s s s . s s s s s s . . . s . . . s s s s s s . s s s s . 
s . . . . . . . . . . s . . . . . . . s . . . . . . . . . . s 
s . . . . . . . . . . s . . . . . . . s . . . . . . . . . . s 
s . . . . . . . . . . w d s s d s s d w . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s w . . . . . . . . . . . . s . s . . . . . . . . . . . . w s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
]],
	[[
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s w . . . . . . . . . . . . . . . . . . . . . . . . . . . w s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . w s s s o s s s w . . . . . . . . . . s 
s . . . . . . . . . . s . . . . . . . s . . . . . . . . . . s 
s . . . . . . . . . . s . . . . . . . s . . . . . . . . . . s 
. s s s s . s s s s s s . . . s . . . s s s s s s . s s s s . 
. . . . . . . . . . . o . . s s s . . o . . . . . . . . . . . 
. s s s s . s s s s s s . . . s . . . s s s s s s . s s s s . 
s . . . . . . . . . . s . . . . . . . s . . . . . . . . . . s 
s . . . . . . . . . . s . . . . . . . s . . . . . . . . . . s 
s . . . . . . . . . . w d s s d s s d w . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s w . . . . . . . . . . . . s . s . . . . . . . . . . . . w s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
]],
	[[
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s w . . . . . . . . . . . . . . . . . . . . . . . . . . . w s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . w s s s s s s s w . . . . . . . . . . s 
s . . . . . . . . . . s W W W W W W W s . . . . . . . . . . s 
s . . . . . . . . . . s W W W W W W W s . . . . . . . . . . s 
. s s s s . s s s s s s W W W s W W W s s s s s s . s s s s . 
. . . . . . . . . . . s W W s s s W W s . . . . . . . . . . . 
. s s s s . s s s s s s W W W s W W W s s s s s s . s s s s . 
s . . . . . . . . . . s W W W W W W W s . . . . . . . . . . s 
s . . . . . . . . . . s W W W W W W W s . . . . . . . . . . s 
s . . . . . . . . . . w d s s d s s d w . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s w . . . . . . . . . . . . s . s . . . . . . . . . . . . w s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
]],
	[[
s s s s s s s s s s s s s s s . s s s s s s s s s s s s s s s 
s w . s . . . . . . . . . . . . . . . . . . . . . . . s . w s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s s . . . . . . . . . . . . . . . . . . . . . . . . . . . s s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . s . s . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s s . . . . . . . . . . . . . . . . . . . . . . . . . . . s s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s w . s . . . . . . . . . . . . . . . . . . . . . . . s . w s 
s s s s s s s s s s s s s s s . s s s s s s s s s s s s s s s 
]],
})

add_auto_room({
	[[
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
]],
})

-- add_auto_room({
-- 	[[
-- s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- . . s s s s s s s s s s s s s s s s s s s s s s s s s s s . .
-- . . s s s s s s s s s s s s s s s s s s s s s s s s s s s . .
-- . . s s s s s s s s s s s s s s s s s s s s s s s s s s s . .
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s
-- s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s
-- ]],
-- })

add_auto_room({
	[[
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s  
s s . . . . . . . . . . . . . . . s s . . . . . s s s s s s s  
s s . . . . . . . . . . . . . . . s s . . . . . s s s s s s s  
s s . . s s s s s s s s s s s s s s s s s . s s s s s s s s s  
s s . . s s s s s s s s s s s s s s s s s . s s s s s s s s s  
s s . . s s s s s s s s s s s s s s s s s . s s s s s s s s s  
s s . . s s s s s s s s s s s s s s s s s . s s s s s s s s s  
s s . . s s s s s s s s s s s s s s s s s . s s s s s s s s s  
s s . . s s s s s s s s s s s s s s s s s . s s s s s s s s s  
s s . . s s s s s s s s s s s s s s s s s . s s s s s s s s s  
s s . . s s s s s s s s s s s s s s s s s . s s s s s s s s s  
s s . . s s s s s s s s s s s s s s s s s . s s s s s s s s s  
s s . . s s s s s s s s s s s s s s s s s . s s s s s s s s s  
. . . . s s s . . . . . . . . s s s s s s . s s s s s s s . .  
. . . . s s s . . . . . . . . . . . . . . . . . . . . . . . .  
. . . . s s s . . . . . . . . s s s s s s . s s s s s s s . .  
s s s s s s s s s . s s s s s s s s s s s . s s s s s s s s s  
s s s s s s s s s . s s s s s s s s s s s . s s s s s s s s s  
s s s s s s s s s . s s s s s s s s s s s . s s s s s s s s s  
s s s s s s s s s . s s s s s s s s s s s . s s s s s s s s s  
s s s s s s s s s . s s s s s s s s s s s . s s s s s s s s s  
s s s s s s s s s . s s s s s s s s s s s . s s s s s s s s s  
s s s s s s s s s . s s s s s s s s s s s . s s s s s s s s s  
s s s s s s s s s . s s s s s s s s s s s . s s s s s s s s s  
s s s s s s s s s . s s s s s s s s s s s . s s s s s s s s s  
s s s s s s s s s . s s s s . . . s s s s . s s s s s s s s s  
s s s s s s s s s . s s s s . . . . . . . . s s s s s s s s s  
s s s s s s s s s . . . . . . . . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s  
]],
})

add_auto_room({
	[[
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s . . . . . . . . . . . . . . s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s . s  
. . s . . . . s s s s s s s s s s s s s s s s s s s s s s . .  
. . s . . . . s s s s s s s s s s s s s s s s s s s s s s . .  
. . s . . . . s s s s s s s s s s s s s s s s s s s s s s . .  
s . s . . . . s s s s s s s s s s s s s s s s s s s s s s s s  
s . s . . . . s s s s s s s s s s s s s s s s s s s s s s s s  
s . s . . . . s s s s s s s s s s s s s s s s s s s s s s s s  
s . s . . . . s s s s s s s s s s s s s s s s s s s s s s s s  
s . s . . . . s s s s s s s s s s s s s s s s s s s s s s s s  
s . s . . . . s s s s s s s s s s s s s s s s s s s s s s s s  
s . s . . . . s s s s s s s s s s s s s s s s s s s s s s s s  
s . s . . . . s s s s s s s s s s s s s s s s s s s s s s s s  
s . s . . . . s s s s s s s s s s s s s s s s s s s s s s s s  
s . s . . . . s s s s s s s s s s s s s s s s s s s s s s s s  
s . s . . . . . . . s s s s s s s s s s s s s s s s s s s s s  
s . s s s s s s s . s s s s s s s s s s s s s s s s s s s s s  
s . . . . . . . . . . . . . . . . s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s  
]],
})

add_auto_room({
	[[
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s . . . . . . . . . . . . . s s s s s s s . s 
s . s s s s s s s . s s s s . . . s s s s . s s s s s s s . s 
s . s s s s s s s . s . . . . . . . . . s . s s s s s s s . s 
s . s s s s s s s . s . s s . . . s s . s . s s s s s s s . s 
s . s s s s s s s . s . s . . . . . s . s . s s s s s s s . s 
. . . . . . . . . . . . . . s s s . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . s s s . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . s s s . . . . . . . . . . . . . . 
s . s s s s s s s . s . s . . . . . s . s . s s s s s s s . s 
s . s s s s s s s . s . s s . . . s s . s . s s s s s s s . s 
s . s s s s s s s . s . . . . . . . . . s . s s s s s s s . s 
s . s s s s s s s . s s s s . . . s s s s . s s s s s s s . s 
s . s s s s s s s . . . . . . . . . . . . . s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . s s s s s s s s s s s s . . . s s s s s s s s s s s s . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
]],
})

add_auto_room({
	[[
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s s s s s s s . s s s s s s . . . s s s s s s . s s s s s s s 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
s s s s s s s . s s s s s s . . . s s s s s s . s s s s s s s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s . . . . . . . . . . . . . . . . . . . . . . . . . . . . . s 
s . . . . . . . . . . . . s . . . s . . . . . . . . . . . . s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
]],
})

add_auto_room({
	[[
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
s . . . . . . . . . . . s s . . . . . . . . . . . . . . . . s 
s . s s s s s . s s s . s s s s . s . s s s s s s s s s . s s 
s . s s s s s . s s s . . . . s . s . s . . . . . . . s . s s 
s . s s s s s . s s s . s s . s . s . s . s s s s s . s . s s 
s . . s s s s . s s s . s s . s . s . s . s . . . s . s . s s 
s s . s s . . . . s s . s s . s . s . s . s . s . s . s . s s 
s s . s s . s s . s s . s s . s . s . s . s . s . s . s . s s 
s s . s s . s s . s s . . . . s . s . s . s . s . s . s . s s 
s s . s s . s s . s s . s s . s . s . s . s . s s s . s . s s 
s s . . . . s s . s s . s s . s . s . s . s . . . . . s . s s 
s s . s s s s s . s s . s s . . . s . s . s s s s s s s . s s 
s s . s s s s s . s s . s s . . . s . s . . . . . . . . . s s 
s s . s s s s s . s s . s s s s s s . s s s s s s s s s . s s 
. . . . . . . . . s s . . s s s s s . . . . . . . . . . . . . 
. . . . . . . . . s s . . s s s . . . s s s s s s s s s s . . 
. . . . . . . . . s s . . s s s . s . . . . . . . . . . . . . 
s s . s s s s s . s s . s s s s . s s s s s s s s s s s s . s 
s s . s s . s s . s s . s s . s . s s s s s s s s s s s s . s 
s s . s s . s s . s s . s s . . . . . . . . . . . . . . . . s 
s s . s s . s s . s s . s s . s s s s s s s s s s s s s s s s 
s s . . . . s s . s s . s s . . . s s s s s s s s s s s s s s 
s s . s s . s s . . . . s s s s . s . . . . . . . . . . . . s 
s s . s s . s s . s s . s s . . . s . . . . . . . . . . . . s 
s s . s . . . s . s s . s s . s s s s s s s s s s s . s s . s 
s s . s . . . s . s s . s s . . . . . . . . . . . . . s s . s 
s s . s s s s s . s s . s s s s . s s s . s s s s s . s s . s 
s s . . . . . . . s s . . . . . . s s s . s s s s s . s s . s 
s s s s . s s s s s s s s s . . . s . . . . . . . . . s . . s 
s s s s . . . . . . . . . . . . . s . . s s s s s s s s . . s 
s s s s s s s s s s s s s s . . . s s s s s s s s s s s s s s 
]],
})

add_auto_room({
	[[
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . s . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . s s s . . . . . . . . . . . . . . 
. . . . . . . . . . . . . s ~ ~ ~ s . . . . . . . . . . . . . 
. . . . . . . . . . . . s ~ ~ ~ ~ ~ s . . . . . . . . . . . . 
. . . . . . . . . . . s ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . . . . 
. . . . . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . . . 
. . . . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . . 
. . . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . 
. . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . 
. . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . 
. . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . 
. . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . 
. . . s s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s s . . . 
. . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . 
. . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . 
. . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . 
. . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . 
. . . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . 
. . . . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . . 
. . . . . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . . . 
. . . . . . . . . . . s ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . . . . 
. . . . . . . . . . . . s ~ ~ ~ ~ ~ s . . . . . . . . . . . . 
. . . . . . . . . . . . . s ~ ~ ~ s . . . . . . . . . . . . . 
. . . . . . . . . . . . . . s s s . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . s . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
]],
	[[
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . s . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . s s s . . . . . . . . . . . . . . 
. . . . . . . . . . . . . s ~ ~ ~ s . . . . . . . . . . . . . 
. . . . . . . . . . . . s ~ ~ ~ ~ ~ s . . . . . . . . . . . . 
. . . . . . . . . . . s ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . . . . 
. . . . . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . . . 
. . . . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . . 
. . . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . 
. . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . 
. . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . 
. . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . 
. . . . s s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s s . . . . 
. . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . 
. . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . 
. . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . 
. . . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . 
. . . . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . . 
. . . . . . . . . . s ~ ~ ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . . . 
. . . . . . . . . . . s ~ ~ ~ ~ ~ ~ ~ s . . . . . . . . . . . 
. . . . . . . . . . . . s ~ ~ ~ ~ ~ s . . . . . . . . . . . . 
. . . . . . . . . . . . . s ~ ~ ~ s . . . . . . . . . . . . . 
. . . . . . . . . . . . . . s s s . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . s . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
]],
	[[
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 
]],
})

local function make_bp_tower()
	local bp = {
		[[
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s s  
]],
	}
	table.insert(
		bp,
		[[
. . . . . . . . .
. . . . . . . . .
. . W s s s W . .
. . s . L . s . .
. . s . . . s . .
. . s . . . s . .
. . W s d s W . .
. . . . . . . . .
. . . . . . . . .
]]
	)
	table.insert(
		bp,
		[[
. . . . . . . . .
. . . . . . . . .
. . W s s s W . .
. . s . L . s . .
. . s . . . s . .
. . s . . . s . .
. . W s a s W . .
. . . . . . . . .
. . . . . . . . .
]]
	)
	local section1a = [[
. . . . . . . . .
. . . . . . . . .
. . W s s s W . .
. . s . L . s . .
. . s . . . s . .
. . s . . . s . .
. . W s s s W . .
. . . . . . . . .
. . . . . . . . .
]]
	local section1b = [[
. . . . . . . . .
. . . . . . . . .
. . W s s s W . .
. . s T L T s . .
. . o . . . o . .
. . s . . . s . .
. . W s o s W . .
. . . . . . . . .
. . . . . . . . .
]]
	local section2a = [[
. . . . . . . . .
. W s s s s s W .
. s W s s s W s .
. s s . L . s s .
. s s . . . s s .
. s s . . . s s .
. s W s s s W s .
. W s s s s s W .
. . . . . . . . .
]]
	local section2b = [[
. . . . . . . . .
. W s s s s s W .
. s W s s s W s .
. s s T L T s s .
. o . . . . . o .
. s s . . . s s .
. s W s . s W s .
. W s s o s s W .
. . . . . . . . .
]]
	local section3a = [[
W s s s s s s s W
s W s s s s s W s
s s W s s s W s s
s s s . L . s s s
s s s . . . s s s
s s s . . . s s s
s s W s s s W s s
s W s s s s s W s
W s s s s s s s W
]]
	local section3b = [[
W s s s s s s s W
s W s s s s s W s
s s W s s s W s s
s s s T L T s s s
o . . . . . . . o
s s s . . . s s s
s s W s . s W s s
s W s s . s s W s
W s s s o s s s W
]]

	local section_height = 4
	for _ = 1, section_height do
		table.insert(bp, section1a)
		table.insert(bp, section1b)
	end
	for _ = 1, section_height do
		table.insert(bp, section2a)
		table.insert(bp, section2b)
	end
	for _ = 1, section_height do
		table.insert(bp, section3a)
		table.insert(bp, section3b)
	end

	table.insert(
		bp,
		[[
W W s s s s s W W
W s s s s s s s W
s s s s s s s s s
s s s s L s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
W s s s s s s s W
W W s s s s s W W
]]
	)
	table.insert(
		bp,
		[[
w w w w w w w w w
w . T . . . T . w
w . . . s . . . w
w . . . L . . . w
w . . . . . . . w
w . . . . . . . w
w . . . . . . . w
w . t c . c t . w
w w w w w w w w w
]]
	)

	return bp
end
table.insert(room_bps, make_bp_tower())

minetest.register_chatcommand("ct", {
	description = "...",
	func = function(name, param)
		local pos = minetest.get_player_by_name(name):get_pos()
		-- pos.y = pos.y - 2 - 6
		pos.y = pos.y - 2

		local opt = {
			speed = 32,
			scaffold = false,
			pre_clear = false,
			build_order = "instant",
			degradation = 0.1,
			-- degradation_block = "default:goldblock",
			degradation_block = "default:mossycobble",
		}
		local callback = function(build_record)
			core.log("callback now!")
		end
		for _ = 1, dungeon_size do
			for __ = 1, dungeon_size do
				opt.rotate = math.random(0, 3)
				Rkit_structures.contruction(pos, bom_dungeon, room_bps[math.random(1, #room_bps)], callback, opt)
				pos.x = pos.x + room_size
			end
			pos.z = pos.z + room_size
			pos.x = pos.x - room_size * dungeon_size
		end
	end,
})
