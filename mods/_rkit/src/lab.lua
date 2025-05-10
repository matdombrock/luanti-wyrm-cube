local simple_bom = {
	["."] = { name = "air" },
	a = { name = "air" },
	s = { name = "default:stone" },
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
}

local master_bom = {
	["."] = { name = "air" },
	a = { name = "air" },
	A = { name = "air" },
	b = { name = "air" },
	B = { name = "air" },
	c = { name = "air" },
	C = { name = "air" },
	d = { name = "air" },
	D = { name = "air" },
	e = { name = "air" },
	E = { name = "air" },
	f = { name = "air" },
	F = { name = "air" },
	g = { name = "air" },
	G = { name = "air" },
	h = { name = "air" },
	H = { name = "air" },
	i = { name = "air" },
	I = { name = "air" },
	j = { name = "air" },
	J = { name = "air" },
	k = { name = "air" },
	K = { name = "air" },
	l = { name = "air" },
	L = { name = "air" },
	m = { name = "air" },
	M = { name = "air" },
	n = { name = "air" },
	N = { name = "air" },
	o = { name = "air" },
	O = { name = "air" },
	p = { name = "air" },
	P = { name = "air" },
	q = { name = "air" },
	Q = { name = "air" },
	r = { name = "air" },
	R = { name = "air" },
	s = { name = "air" },
	S = { name = "air" },
	t = { name = "air" },
	T = { name = "air" },
	u = { name = "air" },
	U = { name = "air" },
	v = { name = "air" },
	V = { name = "air" },
	w = { name = "air" },
	W = { name = "air" },
	x = { name = "air" },
	X = { name = "air" },
	y = { name = "air" },
	Y = { name = "air" },
	z = { name = "air" },
	Z = { name = "air" },
	["0"] = { name = "air" },
	["1"] = { name = "air" },
	["2"] = { name = "air" },
	["3"] = { name = "air" },
	["4"] = { name = "air" },
	["5"] = { name = "air" },
	["6"] = { name = "air" },
	["7"] = { name = "air" },
	["8"] = { name = "air" },
	["9"] = { name = "air" },
	["#"] = { name = "air" },
	["@"] = { name = "air" },
	["$"] = { name = "air" },
	["%"] = { name = "air" },
	["^"] = { name = "air" },
	["&"] = { name = "air" },
	["*"] = { name = "air" },
	["("] = { name = "air" },
	[")"] = { name = "air" },
	["!"] = { name = "air" },
	["?"] = { name = "air" },
	[","] = { name = "air" },
	["/"] = { name = "air" },
	["-"] = { name = "air" },
	["_"] = { name = "air" },
	["="] = { name = "air" },
	["+"] = { name = "air" },
	["["] = { name = "air" },
	["]"] = { name = "air" },
	["{"] = { name = "air" },
	["}"] = { name = "air" },
	["<"] = { name = "air" },
	[">"] = { name = "air" },
}

local generic_bom = {
	["."] = { name = "air" },
	a = { name = "default:acacia_wood_planks" },
	A = { name = "default:acacia_wood" },
	b = { name = "default:brick" },
	B = { name = "default:cobble" },
	c = { name = "" },
	C = { name = "air" },
	d = { name = "air" },
	D = { name = "air" },
	e = { name = "air" },
	E = { name = "air" },
	f = { name = "air" },
	F = { name = "air" },
	g = { name = "air" },
	G = { name = "air" },
	h = { name = "air" },
	H = { name = "air" },
	i = { name = "air" },
	I = { name = "air" },
	j = { name = "air" },
	J = { name = "air" },
	k = { name = "air" },
	K = { name = "air" },
	l = { name = "air" },
	L = { name = "air" },
	m = { name = "air" },
	M = { name = "air" },
	n = { name = "air" },
	N = { name = "air" },
	o = { name = "air" },
	O = { name = "air" },
	p = { name = "air" },
	P = { name = "air" },
	q = { name = "air" },
	Q = { name = "air" },
	r = { name = "air" },
	R = { name = "air" },
	s = { name = "air" },
	S = { name = "air" },
	t = { name = "air" },
	T = { name = "air" },
	u = { name = "air" },
	U = { name = "air" },
	v = { name = "air" },
	V = { name = "air" },
	w = { name = "air" },
	W = { name = "air" },
	x = { name = "air" },
	X = { name = "air" },
	y = { name = "air" },
	Y = { name = "air" },
	z = { name = "air" },
	Z = { name = "air" },
	["0"] = { name = "air" },
	["1"] = { name = "doors:door_glass_a", param2 = 0 },
	["2"] = { name = "doors:door_glass_a", param2 = 1 },
	["3"] = { name = "doors:door_glass_a", param2 = 2 },
	["4"] = { name = "doors:door_glass_a", param2 = 3 },
	["5"] = { name = "default:chest", param2 = 0 },
	["6"] = { name = "default:chest", param2 = 1 },
	["7"] = { name = "default:chest", param2 = 2 },
	["8"] = { name = "default:chest", param2 = 3 },
	["9"] = { name = "air" },
	["#"] = { name = "air" },
	["@"] = { name = "air" },
	["$"] = { name = "air" },
	["%"] = { name = "air" },
	["^"] = { name = "air" },
	["&"] = { name = "air" },
	["*"] = { name = "air" },
	["("] = { name = "air" },
	[")"] = { name = "air" },
	["!"] = { name = "air" },
	["?"] = { name = "air" },
	[","] = { name = "air" },
	["/"] = { name = "air" },
	["-"] = { name = "air" },
	["_"] = { name = "air" },
	["="] = { name = "air" },
	["+"] = { name = "air" },
	["["] = { name = "air" },
	["]"] = { name = "air" },
	["{"] = { name = "air" },
	["}"] = { name = "air" },
	["<"] = { name = "air" },
	[">"] = { name = "air" },
}

local simple_bp = {
	[[
W s s s s s s s W
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s L a a a a a W s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s W a a c a a W s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s L T a a a T W s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s W t a a a t W s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s L a a a a a W s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s W a a a a a W s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s L a a a a a W s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s W a a a a a W s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s L w w w w w w s
s w w w w w w w s
s w w w w w w w s
s w w w w w w w s
s w w w w w w w s
W s s s s s s s W
]],
	[[
s s s s s s s s s
s L w w w w c w s
s w w w w w w w s
s w w w w w w w s
s w w w w r r r s
s w w w w r r r s
s s s s s s s s s
]],
	[[
W l l l l l l l W
l L a a a a a b l
l a a a a a f B l
l a a a h l l l W
l a a a l F F F g
W l d l W F F F n
a a a a n n n n n
]],
	[[
W l o o l o o l W
l a a a a a a a o
o a a a a a a a o
o a a a h o o l W
l t a t l a a a a
W l a l W a a a a
a T a T a a a a a
]],
	[[
W l l l l l l l W
l a a a a a a a l
l a a a a a a a l
l a a a h l l l W
l a a a l a a a a
W l l l W a a a a
a a a a a a a a a
]],
	[[
w w w w w w w w w
w w w w w w w w w
w w o w w w w w w
w w w w w w w w w
w w w w w f f f f
w w w w w a a a a
f f f f f a a a a
]],
}

local tower_bp = {
	[[
W s s s s s s s W
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s d s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s a s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s a a a L a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
s a a a a a a a s
W s s s s s s s W
]],
	[[
W s s s s s s s W
s s s s L s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
W s s s s s s s W
]],
}

local function make_bp_tower()
	local bp = {
		[[
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
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

	local section_height = 32
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

local test_room1 = [[
s s s s . s s s s 
s . T s D s T . s 
s . . T t T . . s 
s . . . s . . . s 
. . . . . . . . . 
s . . s . s . . s 
s . . T . T . . s 
s . t . . . t . s 
s s s s . s s s s 
]]

local test_room2 = [[
s s s s . s s s s 
s . T . . . T . s 
s . . . . . . . s 
. . . . . . . . . 
. . . . . . . . . 
. . . . . . . . . 
s . . . . . . . s 
s . t . . . t . s 
s s s s . s s s s 
]]

local test_room3 = [[
s s s s . s s s s 
s W . s . s . W s 
s . . T . T . . s 
. . . . . . . . . 
. . . . . . . . . 
. . . s . s . . . 
s . . T . T . . s 
s W t . . . t W s 
s s s s . s s s s 
]]

local test_room4 = [[
s s s s . s s s s 
s W s s . s T W s 
s . s . t . . s s 
s . s . s . . . s 
. . . . s . . . . 
s . s s s s s . s 
s . s s s s . . s 
s W s s . . t W s 
s s s s . s s s s 
]]

local test_room5 = [[
s . . . . . . . s 
. . . . . . . . . 
. . w . . . w . . 
. . . . . . . . . 
. . . . . . . . . 
. . . . . . . . . 
. . w . . . w . . 
. . . . . . . . . 
s . . . . . . . s 
]]
local test_room6 = [[
s . . . . . . . s 
. . . . . . . . . 
. . w w w w w . . 
. . w . . . w . . 
. . w . . . w . . 
. . w . . . w . . 
. . w w d w w . . 
. . . . . . . . . 
s . . . . . . . s 
]]
local test_room7a = [[
s . . . . . . . s 
. s . . . . . s . 
. . w w w w w . . 
. . w . . . w . . 
. . w . . . w . . 
. . w . . . w . . 
. . w w d w w . . 
. s . s . s . s . 
s . . . . . . . s 
]]
local test_room7b = [[
s . . . . . . . s 
. . . . . . . . . 
. . w w w w w . . 
. . w . . . w . . 
. . w . . . w . . 
. . w . . . w . . 
. . w w d w w . . 
. . . . . . . . . 
s . . . . . . . s 
]]
minetest.register_chatcommand("construct_test", {
	description = "...",
	func = function(name, param)
		local pos = minetest.get_player_by_name(name):get_pos()
		-- pos.y = pos.y - 2 - 6
		pos.y = pos.y - 2

		local auto_room_opt = {}
		local bpx = Rkit_structures.auto_room(test_room, 9, 9, 6, auto_room_opt)
		local opt = { speed = 32 }
		local callback = function(build_record)
			core.log("callback now!")
			local chests = build_record["c"]
			if not chests then
				return false
			end
			for _, cpos in ipairs(chests) do
				local meta = minetest.get_meta(cpos)
				local inv = meta:get_inventory()
				inv:set_list("main", { "default:diamond", "default:wood 64", "default:glass" })
			end
		end
		Rkit_structures.contruction(pos, simple_bom, bpx, callback, opt)
	end,
})

minetest.register_chatcommand("construct_test2", {
	description = "...",
	func = function(name, param)
		local pos = minetest.get_player_by_name(name):get_pos()
		-- pos.y = pos.y - 2 - 6
		pos.y = pos.y - 2

		local auto_room_opt = { ceiling_str = "." }
		local bps = {
			Rkit_structures.auto_room({ test_room1 }, 9, 9, 6, auto_room_opt),
			Rkit_structures.auto_room({ test_room2 }, 9, 9, 6, auto_room_opt),
			Rkit_structures.auto_room({ test_room3 }, 9, 9, 6, auto_room_opt),
			Rkit_structures.auto_room({ test_room4 }, 9, 9, 6, auto_room_opt),
			Rkit_structures.auto_room({ test_room5 }, 9, 9, 6, auto_room_opt),
			Rkit_structures.auto_room({ test_room6 }, 9, 9, 6, auto_room_opt),
			Rkit_structures.auto_room({ test_room7a, test_room7b }, 9, 9, 6, auto_room_opt),
			make_bp_tower(),
		}
		local opt = { speed = 32 }
		local callback = function(build_record)
			core.log("callback now!")
		end
		for _ = 1, 10 do
			for __ = 1, 10 do
				Rkit_structures.contruction(pos, simple_bom, bps[math.random(1, #bps)], callback, opt)
				pos.x = pos.x + 9
			end
			pos.z = pos.z + 9
			pos.x = pos.x - 9 * 10
		end
	end,
})
