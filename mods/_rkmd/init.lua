local move_speeds = {
	normal = { speed = 1, jump = 1, sneak = 1 },
	runner = { speed = 2, jump = 1.5, sneak = 1 },
	doom = { speed = 3, jump = 2, sneak = 5 },
	hyper = { speed = 16, jump = 8, sneak = 5 },
}
minetest.register_chatcommand("mv", {
	params = "<normal|doom|hyper>",
	description = "Change player movement settings",
	func = function(name, param)
		-- Write the move name value to the sceen for debugging
		minetest.log("action", param)
		local move = move_speeds[param]
		if move == nil then
			return false, "Invalid movement type. Use: normal, doom, or hyper. Got " .. name
		end
		-- Register a globalstep function to increase player speed, jump, and sneak speed
		minetest.register_globalstep(function(dtime)
			for _, player in ipairs(minetest.get_connected_players()) do
				local controls = player:get_player_control()
				player:set_physics_override({
					speed = move.speed, -- Set player speed to 3 times the normal speed
					jump = controls.sneak and 1 or move.jump, -- Set player jump height to 1 if sneak key is held down, otherwise 2
					sneak = true, -- Enable sneaking
					sneak_glitch = false, -- Disable sneak glitching
					sneak_speed = move.sneak, -- Set player sneak speed to 5 times the normal sneak speed
				})
			end
		end)
		return true, "Movement set to " .. param .. "."
	end,
})
minetest.register_chatcommand("ts", {
	params = "<dawn|noon|sunset|midnight>",
	description = "Set the time of day to morning, noon, sunset, or midnight",
	func = function(name, param)
		-- Define time values for specific times of day
		local times = {
			dawn = 0.23, -- Around 6:00 AM in-game time
			d = 0.23,
			noon = 0.5, -- Around 12:00 PM in-game time
			n = 0.5,
			sunset = 0.77, -- Around 6:00 PM in-game time
			s = 0.77,
			midnight = 0, -- 12:00 AM in-game time
			m = 0,
		}

		-- Check if the parameter matches one of the predefined times
		if times[param] then
			-- Set the time of day
			minetest.set_timeofday(times[param])
			return true, "Time set to " .. param .. "."
		else
			return false, "Invalid time. Use: morning, noon, sunset, or midnight."
		end
	end,
})
minetest.register_chatcommand("tspd", {
	params = "<speed>",
	description = "Set the time speed of the game. Usage: /set_time_speed <speed>",
	privs = { server = true },
	func = function(name, param)
		-- Ensure a value is provided
		if param == "" then
			return false, "Usage: /tpd <speed>"
		end

		-- Convert the parameter to a number
		local speed = tonumber(param)
		-- Set the time speed
		minetest.setting_set("time_speed", speed)
		minetest.chat_send_all("Time speed has been set to " .. speed .. " by " .. name)

		return true, "Time speed set to " .. speed .. "."
	end,
})
minetest.register_chatcommand("lsent", {
	params = "<search>",
	description = "List all registered entities. Optionally provide a search term to filter results.",
	privs = { server = true },
	func = function(name, param)
		local entities = {}
		for entity_name, def in pairs(minetest.registered_entities) do
			if param == "" or string.find(entity_name, param, 1, true) then
				table.insert(entities, entity_name)
			end
		end
		table.sort(entities) -- Optional: Sort alphabetically
		if #entities == 0 then
			return false, "No entities found matching the search term: " .. param
		end

		return true, "\n\nRegistered entities:\n" .. table.concat(entities, "\n")
	end,
})
minetest.register_chatcommand("lsnode", {
	params = "<search>",
	description = "List all registered nodes. Optionally provide a search term to filter results.",
	privs = { server = true },
	func = function(name, param)
		local nodes = {}
		for node_name, def in pairs(minetest.registered_nodes) do
			if param == "" or string.find(node_name, param, 1, true) then
				table.insert(nodes, node_name)
			end
		end
		table.sort(nodes) -- Optional: Sort alphabetically
		if #nodes == 0 then
			return false, "No nodes found matching the search term: " .. param
		end
		return true, "\n\nRegistered nodes:\n" .. table.concat(nodes, "\n")
	end,
})
minetest.register_chatcommand("no_dmg", {
	params = "<seconds>",
	description = "Disable damage for a specified number of seconds.",
	privs = { server = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end

		-- Parse the number of seconds from the parameter
		local seconds = tonumber(param or 120)
		if not seconds or seconds <= 0 then
			return false, "Invalid number of seconds. Usage: /no_dmg <seconds>"
		end

		Rkit.no_dmg(player, seconds)

		return true, "Damage disabled for " .. seconds .. " seconds."
	end,
})
minetest.register_chatcommand("tp", {
	params = "<x> <y> <z>",
	description = "Teleport the player to the specified position (x, y, z).",
	privs = { teleport = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end

		-- Parse the coordinates from the parameters
		local x, y, z = param:match("^(%-?%d+%.?%d*) (%-?%d+%.?%d*) (%-?%d+%.?%d*)$")
		if not x or not y or not z then
			return false, "Invalid coordinates. Usage: /teleport_to <x> <y> <z>"
		end

		-- Convert coordinates to numbers
		x, y, z = tonumber(x), tonumber(y), tonumber(z)

		-- Teleport the player to the specified position
		local new_position = { x = x, y = y, z = z }
		player:set_pos(new_position)

		Rkit.no_dmg(player, 5) -- Disable damage for 5 seconds

		return true, "Teleported to position: " .. minetest.pos_to_string(new_position)
	end,
})
minetest.register_chatcommand("tpr", {
	params = "<range>",
	description = "Teleport the player to a random location within the specified range and disable damage for 5 seconds.",
	privs = { teleport = true },
	func = function(name, param)
		-- Ensure a valid range is provided
		local range = tonumber(param) or 500
		if not range or range <= 0 then
			return false, "Please provide a valid positive number as the range."
		end

		-- Get the player's object
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end

		-- Generate random coordinates within the range
		local random_x = math.random(-range, range)
		local random_y = 128 -- Keep Y between 5 and 100 for safety
		local random_z = math.random(-range, range)

		-- Set the new position
		local new_position = { x = random_x, y = random_y, z = random_z }
		player:set_pos(new_position)

		Rkit.no_dmg(player, 5) -- Disable damage for 5 seconds

		return true, "Teleported to random location: " .. minetest.pos_to_string(new_position)
	end,
})
minetest.register_chatcommand("blink", {
	params = "<x> <y> <z>",
	description = "Teleport the player to the specified RELATIVE position (x, y, z).",
	privs = { teleport = true },
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end

		-- Parse the coordinates from the parameters
		local dx, dy, dz = param:match("^(%-?%d+%.?%d*) (%-?%d+%.?%d*) (%-?%d+%.?%d*)$")
		if not dx or not dy or not dz then
			return false, "Invalid coordinates. Usage: /blink <x> <y> <z>"
		end

		-- Convert coordinates to numbers
		dx, dy, dz = tonumber(dx), tonumber(dy), tonumber(dz)

		-- Get the player's current position
		local player_pos = player:get_pos()

		-- Calculate the new position
		local new_position = {
			x = player_pos.x + dx,
			y = player_pos.y + dy,
			z = player_pos.z + dz,
		}

		-- Teleport the player to the new position
		player:set_pos(new_position)
	end,
})
minetest.register_chatcommand("clear_inventory", {
	description = "Clear the player's inventory.",
	privs = { server = true },
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end

		-- Get the player's inventory
		local inv = player:get_inventory()
		if inv then
			inv:set_list("main", {}) -- Clear the main inventory
			inv:set_list("craft", {}) -- Clear the crafting inventory
			minetest.chat_send_player(name, "Your inventory has been cleared.")
			return true, "Inventory cleared."
		else
			return false, "Failed to access player's inventory."
		end
	end,
})
minetest.register_chatcommand("spawn_relative_entity", {
	params = "<entity> <x> <y> <z>",
	description = "Spawn an entity relative to the player's position. Usage: /spawn_relative_entity <entity> <x> <y> <z>",
	privs = { server = true },
	func = function(name, param)
		-- Ensure parameters are provided
		if param == "" then
			return false, "Usage: /spawn_relative_entity <entity> <x> <y> <z>"
		end

		-- Parse parameters
		local entity, dx, dy, dz = param:match("^(%S+)%s+([%-?%d%.]+)%s+([%-?%d%.]+)%s+([%-?%d%.]+)$")
		if not entity or not dx or not dy or not dz then
			return false, "Invalid parameters. Usage: /spawn_relative_entity <entity> <x> <y> <z>"
		end

		-- Convert relative offsets to numbers
		dx, dy, dz = tonumber(dx), tonumber(dy), tonumber(dz)
		if not dx or not dy or not dz then
			return false, "Coordinates must be numbers. Usage: /spawn_relative_entity <entity> <x> <y> <z>"
		end

		-- Get the player's object
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end

		-- Get the player's current position
		local player_pos = player:get_pos()

		-- Calculate the spawn position
		local spawn_pos = {
			x = player_pos.x + dx,
			y = player_pos.y + dy,
			z = player_pos.z + dz,
		}

		-- Spawn the entity
		local entity_obj = minetest.add_entity(spawn_pos, entity)
		if not entity_obj then
			return false, "Failed to spawn entity. Check if the entity name is correct."
		end

		return true,
			"Spawned entity '" .. entity .. "' at relative position (" .. dx .. ", " .. dy .. ", " .. dz .. ")."
	end,
})
minetest.register_chatcommand("respawn", {
	description = "Teleport to your respawn or bed location",
	privs = {}, -- No special privileges required
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found."
		end

		player:respawn()
		return true, "Teleported to your respawn location!"
	end,
})
minetest.register_chatcommand("su", {
	description = "Alias for /grantme all",
	func = function(name, param)
		-- Call the original command's functionality
		return minetest.registered_chatcommands["grantme"].func(name, "all")
	end,
})

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
	D = { name = "default:dirt" },
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
s w w w w D D D s
s w w w w D D D s
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
W s s s s s s s s
s s s s s s s s s
s s s s L s s s s
s s s s s s s s s
s s s s s s s s s
s s s s s s s s s
W s s s s s s s s
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

minetest.register_chatcommand("construct_test", {
	description = "...",
	func = function(name, param)
		local pos = minetest.get_player_by_name(name):get_pos()
		-- pos.y = pos.y - 2 - 6
		pos.y = pos.y - 2
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
		Rkit:contruction(pos, simple_bom, make_bp_tower(), callback, opt)
	end,
})
