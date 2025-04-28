-- Wyrm Cubes Mod for Luanti
local rk = Rkit:new("wyrm_cube")

local modpath = core.get_modpath(core.get_current_modname())
local txt = {
	intro = io.open(modpath .. "/txt/intro.txt", "r"):read("*a"),
	guide = io.open(modpath .. "/GUIDE.md", "r"):read("*a"),
}
-- CONFIG
local cfg = {
	cube_count = core.settings:get("wyrm_cube_cube_count") or 7, -- Number of wyrm cubes to place
	max_cube_dist = core.settings:get("wyrm_cube_spawn_distance") or 10000, -- Maximum distance from the spawn point to place wyrm cubes
	monster_spawn_amt = core.settings:get("wyrm_cube_monster_spawn_amt") or 32, -- Probability of spawning a monster when radar is used
	monster_spawn_time = core.settings:get("wyrm_cube_monster_spawn_time") or 30, -- Time between random monster spawns
	monster_spawn_delay = core.settings:get("wyrm_cube_spawn_") or (60 * 3), -- Time before starting random monster spawns
	supply_drop_amt = core.settings:get("wyrm_cube_supply_drop_amt") or 5, -- Number of supply drops to spawn
	supply_drop_range = core.settings:get("wyrm_cube_supply_drop_range") or 16, -- Will be double this number.
	enable_logging = core.settings:get("wyrm_cube_enable_logging"), -- Enable or disable logging
}

-- Persistent mod storage
local mod_storage = core.get_mod_storage()
local players_list = mod_storage:get_string("players_list")
-- Store wyrm cube positions as a single serialized table
local wyrm_cubes = {}

--
-- UTILITY FUNCTIONS
--

-- Still in use over Rkit so that it can be toggled more easily
local function log(message)
	if not cfg.enable_logging then
		return
	end
	core.log("[Wyrm Cube] " .. message)
end

local function spawn_particles(pos)
	rk:spawn_particles_rainbow(pos, "wyrm_line_particle", 3.0)
	core.sound_play("woosh", {
		pos = pos,
		max_hear_distance = 128,
		gain = 0.6,
		loop = false,
	})
end

local function spawn_particles_bad(pos)
	rk:spawn_particles(pos, "wyrm_line_particle", "#FF0000", 3.0)
	core.sound_play("bad_spawn", {
		pos = pos,
		max_hear_distance = 128,
		gain = 0.1,
		loop = false,
	})
end

local function spawn_monster(name)
	-- Get the player's position
	local player = core.get_player_by_name(name)
	if not player then
		return false, "Player not found!"
	end

	local pos = player:get_pos()

	-- Generate a random position around the player
	local random_offset = {
		x = math.random(8, 24),
		y = math.random(-8, 8),
		z = math.random(8, 24),
	}
	random_offset.x = random_offset.x * (math.random(0, 1) == 0 and -1 or 1)
	random_offset.z = random_offset.z * (math.random(0, 1) == 0 and -1 or 1)

	local spawn_pos = vector.add(pos, random_offset)

	-- Check if the position is suitable for spawning
	local node_at_spawn = core.get_node(spawn_pos).name
	local node_below = core.get_node({ x = spawn_pos.x, y = spawn_pos.y - 1, z = spawn_pos.z }).name
	local node_above = core.get_node({ x = spawn_pos.x, y = spawn_pos.y + 1, z = spawn_pos.z }).name
	if
		node_at_spawn == "air"
		and node_above == "air"
		and node_below ~= "air"
		and node_below ~= "default:water_source"
	then
		local entity = core.add_entity(spawn_pos, "mobs:oerkki")
		spawn_particles_bad(spawn_pos)
		if entity then
			return true, "Monster spawned at " .. core.pos_to_string(spawn_pos)
		else
			return false, "Failed to spawn monster!"
		end
	else
		return false, "Invalid spawn location: " .. node_at_spawn
	end
end

local function monster_spawn_timer(player)
	-- Check if the player is still online
	if core.get_player_by_name(player:get_player_name()) then
		for i = 1, cfg.monster_spawn_amt do
			core.after(i / 2, function()
				spawn_monster(player:get_player_name())
			end)
		end
		-- Schedule the next spawn
		core.after(cfg.monster_spawn_time, function()
			monster_spawn_timer(player)
		end)
	end
end

local move_speeds = {
	stuck = { speed = 0, jump = 0, sneak = 0, fall = 0, gravity = 0 },
	normal = { speed = 1, jump = 1, sneak = 1, fall = 1, gravity = 1 },
	runner = { speed = 2, jump = 1.5, sneak = 1, fall = 1, gravity = 1 },
	doom = { speed = 3, jump = 2, sneak = 5, fall = 0.1, gravity = 1 },
	hyper = { speed = 16, jump = 8, sneak = 5, fall = 0, gravity = 1 },
	moon = { speed = 1, jump = 1, sneak = 1, fall = 1, gravity = 0.1654 },
	mars = { speed = 1, jump = 1, sneak = 1, fall = 1, gravity = 0.38 },
	low_orbit = { speed = 1, jump = 1, sneak = 1, fall = 1, gravity = 0.01 },
	rabbit = { speed = 1, jump = 3, sneak = 1, fall = 1, gravity = 1 },
}
-- TODO: This loop is sus
local function set_move(player, move)
	for _, playerx in ipairs(core.get_connected_players()) do
		if playerx.name ~= player.name then
			goto continue
		end
		local controls = playerx:get_player_control()
		playerx:set_physics_override({
			speed = move.speed, -- Set player speed
			jump = controls.sneak and 1 or move.jump, -- Set player jump height to 1 if sneak key is held doen
			sneak = true, -- Enable sneaking
			sneak_glitch = false, -- Disable sneak glitching
			sneak_speed = move.sneak, -- Set player sneak speed
			gravity = move.gravity, -- Set player gravity
		})
		rk:fall_dmg(playerx, move.fall)
		::continue::
	end
end

-- Draw a GUI element telling the player the potion will expire
local function warn_potion(user, potion_name, seconds)
	rk:hud_msg(user, "POTION:\n" .. potion_name .. " (" .. seconds .. "s)", 3)
	core.after(seconds - 3, function()
		rk:hud_msg(user, "POTION WEARING OFF:\n" .. potion_name, 3)
	end)
end

local function place_wyrm_cube_callback(pos, action, num_calls_remaining, context)
	-- On first call, record number of blocks
	if not context.total_blocks then
		context.total_blocks = num_calls_remaining + 1
		context.loaded_blocks = 0
	end

	-- Increment number of blocks loaded
	context.loaded_blocks = context.loaded_blocks + 1

	-- Send progress message
	if context.total_blocks ~= context.loaded_blocks then
		local perc = 100 * context.loaded_blocks / context.total_blocks
		local msg = string.format("Loading blocks %d/%d (%.2f%%)", context.loaded_blocks, context.total_blocks, perc)
		log(msg)
	end
	log("Emerge callback called for position: " .. core.pos_to_string(context.pos))

	if #wyrm_cubes >= cfg.cube_count then
		log("Already placed " .. #wyrm_cubes .. " wyrm cubes, stopping placement")
		return
	end
	local node = core.get_node(context.pos)
	local below = core.get_node(context.pos_below)
	if node.name == "ignore" then
		log("Node is ignore, not placing wyrm cube at " .. core.pos_to_string(context.pos))
		return
	end
	if node.name == "air" then
		local checks = 0
		while checks < 64 and (below.name == "air" or below.name == "ignore") do
			context.pos.y = context.pos.y - 1
			context.pos_below.y = context.pos_below.y - 1
			below = core.get_node(context.pos_below)
			checks = checks + 1
		end
		if checks < 64 then
			-- Successfully found a solid block below
			core.set_node(context.pos, { name = "wyrm_cube:wyrm_cube" })
			table.insert(wyrm_cubes, context.pos)
			log("Placed wyrm cube at " .. core.pos_to_string(context.pos))
			log("Node name: " .. node.name .. ", Below node name: " .. below.name)
		end
	end
end

-- Function to place a wyrm cube at a valid surface position
local function place_wyrm_cube(pos)
	if #wyrm_cubes >= cfg.cube_count then
		log("Already placed " .. #wyrm_cubes .. " wyrm cubes, stopping placement")
		return
	end

	local pos_below = { x = pos.x, y = pos.y - 1, z = pos.z }

	local context = { pos = pos, pos_below = pos_below } -- persist data between callback calls
	core.emerge_area(pos_below, pos, place_wyrm_cube_callback, context)
end

-- Function to randomly place wyrm cubes in areas after world generation
local function place_wyrm_cubes()
	local remaining = cfg.cube_count - #wyrm_cubes
	if remaining <= 0 then
		log("All wyrm cubes already placed")
		return
	end
	log("Attempting placement of " .. remaining .. " wyrm cubes")
	local pos = {
		x = math.random(-cfg.max_cube_dist, cfg.max_cube_dist),
		y = math.random(5, 50), -- Adjust Y range as needed
		z = math.random(-cfg.max_cube_dist, cfg.max_cube_dist),
	}
	place_wyrm_cube(pos)
	-- wait for 1 second
	core.after(0.5, function()
		if #wyrm_cubes < cfg.cube_count then
			place_wyrm_cubes()
		end
	end)
end

-- Load saved wyrm cube positions from storage
local function load_saved_cubes()
	log("Loading saved wyrm cube positions from storage")
	local saved_data = mod_storage:get_string("wyrm_cubes")
	if saved_data and saved_data ~= "" then
		local data = core.deserialize(saved_data)
		if data then
			wyrm_cubes = data
			log("Loaded " .. #wyrm_cubes .. " wyrm cubes from storage")
		else
			log("WARNING: Failed to deserialize wyrm cube data")
		end
	else
		log("No saved wyrm cube data found")
	end
end

-- Save all wyrm cube positions to mod storage
local function save_wyrm_cubes()
	mod_storage:set_string("wyrm_cubes", core.serialize(wyrm_cubes))
	log("Saved " .. #wyrm_cubes .. " wyrm cubes to storage")
end

local supply_drop_items = {
	{ 1, "wyrm_cube:donut 1" },
	{ 5, "wyrm_cube:potion_mv_runner 16" },
	{ 3, "wyrm_cube:potion_mv_doom 4" },
	{ 1, "wyrm_cube:potion_mv_hyper 2" },
	{ 3, "wyrm_cube:potion_mv_moon 4" },
	{ 3, "wyrm_cube:potion_mv_mars 4" },
	{ 2, "wyrm_cube:potion_mv_low_orbit 2" },
	{ 4, "wyrm_cube:potion_mv_rabbit 4" },
	{ 5, "wyrm_cube:potion_immunity_1 4" },
	{ 3, "wyrm_cube:potion_immunity_2 4" },
	{ 1, "wyrm_cube:potion_immunity_3 2" },
	{ 3, "wyrm_cube:potion_cat 4" },
	{ 2, "wyrm_cube:potion_feather 2" },
	{ 2, "wyrm_cube:potion_bird 2" },
	{ 10, "wyrm_cube:potion_health_1 8" },
	{ 7, "wyrm_cube:potion_health_2 4" },
	{ 4, "wyrm_cube:potion_health_3 1" },
	{ 20, "wyrm_gps:gps 1" },
	{ 20, "wyrm_cube:radio 1" },
	{ 10, "wyrm_cube:transmuter 1" },
	{ 10, "wyrm_cube:respawner 8" },
	{ 20, "wyrm_cube:meta_scanner 1" },
	{ 20, "wyrm_cube:meta_vacuum 1" },
	{ 20, "wyrm_cube:capsule_yurt 8" },
	{ 3, "wyrm_cube:capsule_airport 2" },
	{ 5, "wyrm_cube:capsule_watchtower 8" },
	{ 1, "wyrm_cube:capsule_megatower 1" },
	{ 10, "wyrm_cube:lamp_small 32" },
	{ 5, "default:sword_diamond 1" },
	{ 10, "default:sword_steel 1" },
	{ 20, "default:sword_stone 1" },
	{ 1, "3d_armor:boots_mithril 1" },
	{ 10, "3d_armor:boots_diamond 1" },
	{ 20, "3d_armor:boots_steel 1" },
	{ 1, "3d_armor:chestplate_mithril 1" },
	{ 10, "3d_armor:chestplate_diamond 1" },
	{ 20, "3d_armor:chestplate_steel 1" },
	{ 1, "3d_armor:helmet_mithril 1" },
	{ 10, "3d_armor:helmet_diamond 1" },
	{ 20, "3d_armor:helmet_steel 1" },
	{ 1, "shields:shield_mithril 1" },
	{ 10, "shields:shield_diamond 1" },
	{ 20, "shields:shield_steel 1" },
	{ 5, "default:torch 32" },
	{ 10, "default:pick_diamond 1" },
	{ 10, "default:axe_diamond 1" },
	{ 10, "default:shovel_diamond 1" },
	{ 4, "hammermod:steel_hammer 1" },
	{ 6, "farming:bread 32" },
	{ 6, "default:apple 32" },
	{ 5, "default:tree 99" },
	{ 5, "default:stone 99" },
	{ 5, "default:ladder_steel 99" },
	{ 5, "bucket:bucket_water 8" },
	{ 10, "beds:bed_bottom 1" },
	{ 5, "animalia:saddle 1" },
	{ 5, "animalia:spawn_horse 1" },
	{ 2, "animalia:libri_animalia 1" },
	{ 5, "leads:lead 8" },
	{ 20, "binoculars:binoculars 1" },
	{ 10, "goodtorch:flashlight_off 1" },
	{ 10, "x_bows:bow_wood 1" },
	{ 20, "x_bows:arrow_wood 99" },
	{ 10, "grapple:grapple 1" },
	{ 5, "tnt:tnt 1" },
	{ 20, "biofuel:fuel_can 32" },
	{ 20, "hangglider:hangglider 1" },
	{ 5, "motorboat:boat 2" },
	{ 2, "hidroplane:hidro 2" },
	{ 20, "motorbike:cyan 4" },
	{ 10, "sum_airship:boat 3" },
	{ 1, "fishing_boat:boat 1" },
	{ 5, "sailing_kit:boat 2" },
	{ 20, "boats:boat 8" },
	{ 4, "hovercraft:hover_white 4" },
}

local function supply_drop(name)
	-- Get the player's position
	local player = core.get_player_by_name(name)
	if not player then
		log("Player not found: " .. name)
		return false, "Player not found!"
	end

	local pos = player:get_pos()
	local dist_x = cfg.supply_drop_range
	dist_x = dist_x + math.random(0, dist_x)
	local dist_z = cfg.supply_drop_range
	dist_z = dist_z + math.random(0, dist_z)
	if rk:pchance(50) then
		dist_x = -dist_x
	end
	if rk:pchance(50) then
		dist_z = -dist_z
	end
	local dir = { x = dist_x, y = 48, z = dist_z }

	-- Try to place the chest in a random adjacent location
	local chest_pos = vector.add(pos, dir)
	-- Place the chest
	local cur_node = core.get_node(chest_pos)
	if cur_node.name ~= "air" then
		log("No suitable location to place the supply drop for player: " .. name)
		-- Try again
		core.after(1, function()
			if player then
				log("Trying supply drop again")
				supply_drop(name)
			else
				log("Player not found: " .. name)
				return false, "Player not found!"
			end
		end)
		return false, "No suitable location to place the supply drop!"
	end
	log("Placing supply drop at " .. core.pos_to_string(chest_pos) .. " for player: " .. name)
	core.set_node(chest_pos, { name = "wyrm_cube:supply_drop" })

	local meta = core.get_meta(chest_pos)
	local inv = meta:get_inventory()
	inv:set_size("main", 8 * 4) -- Default chest size

	for _, item in ipairs(supply_drop_items) do
		local chance = item[1]
		local item_name = item[2]
		if rk:pchance(chance) then
			inv:add_item("main", item_name)
		end
	end
	-- end
	return false, "Placed the supply drop!"
end

local function supply_drops(user, num)
	for i = 1, num do
		core.after(i / 2, function()
			supply_drop(user:get_player_name())
		end)
	end
end

-- TODO: This code is pretty messy
local function spawn_yurt(name, param)
	local player = core.get_player_by_name(name)
	if not player then
		return false, "Player not found!"
	end

	-- Dimensions of the house
	local width = 7
	local height = 4
	local length = 7

	local corner_stone = player:get_pos()
	corner_stone.y = corner_stone.y - 1
	corner_stone.x = corner_stone.x - math.floor(width / 2)
	corner_stone.z = corner_stone.z - math.floor(length / 2)

	-- place the corner stone
	core.set_node(corner_stone, { name = "default:wood" })

	-- Build the walls
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			for z = 0, length - 1 do
				local block = "wool:white"
				if x == 3 and y < 3 and z == 0 then
					goto continue -- Skip this block for the door
				end
				if y == 2 and (z ~= 0) and ((x >= 2 and x < width - 2) or (z >= 2 and z < length - 2)) then
					block = "default:glass"
				end
				-- ensure we only build walls
				if x == 0 or x == width - 1 or z == 0 or z == length - 1 then
					core.set_node({
						x = corner_stone.x + x,
						y = corner_stone.y + y,
						z = corner_stone.z + z,
					}, { name = block })
				end
				::continue::
			end
		end
	end

	-- Build the roof
	for x = -1, width do
		for z = -1, length do
			core.set_node({
				x = corner_stone.x + x,
				y = corner_stone.y + height,
				z = corner_stone.z + z,
			}, { name = "stairs:slab_silver_sandstone_brick" })
		end
	end

	-- Build the floor
	for x = 0, width - 1 do
		for z = 0, length - 1 do
			core.set_node({
				x = corner_stone.x + x,
				y = corner_stone.y,
				z = corner_stone.z + z,
			}, { name = "default:wood" })
		end
	end
	-- place a bed
	core.set_node({
		x = corner_stone.x + 1,
		y = corner_stone.y + 1,
		z = corner_stone.z + 4,
	}, { name = "beds:bed_bottom" })
	core.set_node({
		x = corner_stone.x + 1,
		y = corner_stone.y + 1,
		z = corner_stone.z + 5,
	}, { name = "beds:bed_top" })
	core.set_node({
		x = corner_stone.x + width - 2,
		y = corner_stone.y + 1,
		z = corner_stone.z + 4,
	}, { name = "beds:bed_bottom" })
	core.set_node({
		x = corner_stone.x + width - 2,
		y = corner_stone.y + 1,
		z = corner_stone.z + 5,
	}, { name = "beds:bed_top" })

	-- place chest
	core.set_node({
		x = corner_stone.x + 1,
		y = corner_stone.y + 1,
		z = corner_stone.z + 1,
	}, { name = "wyrm_cube:supply_drop" })
	-- Put some items in the chest
	local meta = core.get_meta({
		x = corner_stone.x + 1,
		y = corner_stone.y + 1,
		z = corner_stone.z + 1,
	})
	local inv = meta:get_inventory()
	inv:set_size("main", 8 * 4) -- Default chest size
	inv:add_item("main", "stairs:stair_wood 99")
	inv:add_item("main", "stairs:stair_stone 99")
	inv:add_item("main", "default:glass 99")
	inv:add_item("main", "doors:door_glass_a 99")
	inv:add_item("main", "wool:white 99")
	inv:add_item("main", "stairs:slab_silver_sandstone_brick 99")
	inv:add_item("main", "wyrm_cube:lamp_small 99")
	inv:add_item("main", "wyrm_cube:lamp 99")
	inv:add_item("main", "wyrm_cube:lamp_blinking_off 99")
	inv:add_item("main", "screwdriver:screwdriver 99")
	core.set_node({
		x = corner_stone.x + width - 2,
		y = corner_stone.y + 1,
		z = corner_stone.z + 1,
	}, { name = "wyrm_cube:supply_drop" })

	-- place transmuter
	core.set_node({
		x = corner_stone.x + math.floor(width / 2),
		y = corner_stone.y + 1,
		z = corner_stone.z + length - 2,
	}, { name = "wyrm_cube:transmuter" })

	-- Build the door
	core.set_node({
		x = corner_stone.x + 3,
		y = corner_stone.y + 1,
		z = corner_stone.z,
	}, { name = "doors:door_glass_a" }) -- Use wood blocks for the door

	-- place lamps
	core.set_node({
		x = corner_stone.x + 1,
		y = corner_stone.y + 3,
		z = corner_stone.z + 5,
	}, { name = "wyrm_cube:lamp_small" })
	core.set_node({
		x = corner_stone.x + 5,
		y = corner_stone.y + 3,
		z = corner_stone.z + 5,
	}, { name = "wyrm_cube:lamp_small" })
	core.set_node({
		x = corner_stone.x + 1,
		y = corner_stone.y + 3,
		z = corner_stone.z + -1,
	}, { name = "wyrm_cube:lamp_small" })
	core.set_node({
		x = corner_stone.x + 5,
		y = corner_stone.y + 3,
		z = corner_stone.z + -1,
	}, { name = "wyrm_cube:lamp_small" })

	spawn_particles(corner_stone)

	return true, "House created with the corner stone as the starting point!"
end

local function spawn_landing_strip(name)
	local length = 32
	local width = 5
	local player = core.get_player_by_name(name)
	if not player then
		return false, "Player not found!"
	end
	local player_pos = player:get_pos()
	local pos = player_pos
	pos.y = pos.y - 1
	for x = -length, length do
		for z = -width, width do
			local block = "default:stone"
			local delay = 0
			if x % 2 == 0 and z > -width + 3 and z < width - 3 and z ~= 0 then
				block = "wyrm_cube:lamp_blinking_off"
				if x % 4 == 0 then
					delay = 1
				end
			end
			core.after(delay, function()
				core.set_node({
					x = pos.x + x,
					y = pos.y,
					z = pos.z + z,
				}, { name = block })
			end)
			for y = 1, 17 do
				core.set_node({
					x = pos.x + x,
					y = pos.y + y,
					z = pos.z + z,
				}, { name = "air" })
			end
		end
	end
	for x = -width, width do
		for z = -length, length do
			local block = "default:stone"
			local delay = 0
			if z % 2 == 0 and x > -width + 3 and x < width - 3 and x ~= 0 then
				block = "wyrm_cube:lamp_blinking_off"
				if z % 4 == 0 then
					delay = 1
				end
			end
			core.after(delay, function()
				core.set_node({
					x = pos.x + x,
					y = pos.y,
					z = pos.z + z,
				}, { name = block })
			end)
			for y = 1, 17 do
				core.set_node({
					x = pos.x + x,
					y = pos.y + y,
					z = pos.z + z,
				}, { name = "air" })
			end
		end
	end

	spawn_particles(pos)
end

local function spawn_watchtower(name)
	local player = core.get_player_by_name(name)
	if not player then
		return false, "Player not found!"
	end
	local pos = player:get_pos()
	pos.y = pos.y - 1
	local pos_c = vector.new(pos) -- cache
	local height_c = 32
	local width_c = 5
	local height = height_c
	local width = width_c
	for y = 1, height do
		if y % 8 == 0 then
			width = width + 2
			pos.x = pos.x - 1
			pos.z = pos.z - 1
		end
		for x = 1, width do
			for z = 1, width do
				core.set_node({
					x = pos.x + x,
					y = pos.y + y,
					z = pos.z + z,
				}, { name = "default:aspen_wood" })
			end
		end
	end
	-- Place a lamp at each corner
	core.set_node({
		x = pos.x + 1,
		y = pos.y + height,
		z = pos.z + 1,
	}, { name = "wyrm_cube:lamp" })
	core.set_node({
		x = pos.x + 1,
		y = pos.y + height + 1,
		z = pos.z + 1,
	}, { name = "wyrm_cube:lamp" })

	core.set_node({
		x = pos.x + width,
		y = pos.y + height,
		z = pos.z + 1,
	}, { name = "wyrm_cube:lamp" })
	core.set_node({
		x = pos.x + width,
		y = pos.y + height + 1,
		z = pos.z + 1,
	}, { name = "wyrm_cube:lamp" })

	core.set_node({
		x = pos.x + 1,
		y = pos.y + height,
		z = pos.z + width,
	}, { name = "wyrm_cube:lamp" })
	core.set_node({
		x = pos.x + 1,
		y = pos.y + height + 1,
		z = pos.z + width,
	}, { name = "wyrm_cube:lamp" })

	core.set_node({
		x = pos.x + width,
		y = pos.y + height,
		z = pos.z + width,
	}, { name = "wyrm_cube:lamp" })
	core.set_node({
		x = pos.x + width,
		y = pos.y + height + 1,
		z = pos.z + width,
	}, { name = "wyrm_cube:lamp" })
	-- Drill a hole down the middle
	for y = 1, height do
		for x = 1, width do
			for z = 1, width do
				if x == math.floor(width / 2) and z == math.floor(width / 2) then
					core.set_node({
						x = pos.x + x,
						y = pos.y + y,
						z = pos.z + z,
					}, { name = "default:ladder_steel", param2 = 5 })
					core.set_node({
						x = pos.x + x,
						y = pos.y + y,
						z = pos.z + z + 1,
					}, { name = "air" })
					local block = "default:aspen_wood"
					if y % 4 == 0 and y > 8 then
						block = "wyrm_cube:lamp_blinking_off"
					end
					core.set_node({
						x = pos.x + x,
						y = pos.y + y,
						z = pos.z + z - 1,
					}, { name = block })
					core.set_node({
						x = pos.x + x,
						y = pos.y + y,
						z = pos.z + z + 2,
					}, { name = block })
				end
			end
		end
	end
	-- Make a walkway through the front
	pos = pos_c
	for x = 1, width_c do
		for z = 1, width_c do
			if x == math.floor(width_c / 2) and z > math.floor(width_c / 2) then
				core.set_node({
					x = pos.x + x,
					y = pos.y + 1,
					z = pos.z + z,
				}, { name = "air" })
				core.set_node({
					x = pos.x + x,
					y = pos.y + 2,
					z = pos.z + z,
				}, { name = "air" })
			end
		end
	end
	-- Place a door
	core.set_node({
		x = pos.x + math.floor(width_c / 2),
		y = pos.y + 1,
		z = pos.z + width_c,
	}, { name = "doors:door_glass_a" })
	-- Place a small lamp above the door
	core.set_node({
		x = pos.x + math.floor(width_c / 2),
		y = pos.y + 3,
		z = pos.z + width_c + 1,
	}, { name = "wyrm_cube:lamp_small", param2 = 5 })
	pos = pos_c
	pos.y = pos.y + height + 2
	pos.x = pos.x + width_c / 2
	pos.z = pos.z + width_c / 2
	player:set_pos(pos)
	spawn_particles(pos)
end
-- TODO: Not DRY. Basically a copy of watchtower
local function spawn_megatower(name)
	local player = core.get_player_by_name(name)
	if not player then
		return false, "Player not found!"
	end
	local pos = player:get_pos()
	pos.y = pos.y - 1
	local pos_c = vector.new(pos) -- cache
	local height_c = 256
	local width_c = 15
	local height = height_c
	local width = width_c
	for y = 1, height do
		if y % 32 == 0 then
			width = width + 2
			pos.x = pos.x - 1
			pos.z = pos.z - 1
		end
		for x = 1, width do
			for z = 1, width do
				core.set_node({
					x = pos.x + x,
					y = pos.y + y,
					z = pos.z + z,
				}, { name = "default:aspen_wood" })
			end
		end
	end
	-- Place a lamp at each corner
	core.set_node({
		x = pos.x + 1,
		y = pos.y + height,
		z = pos.z + 1,
	}, { name = "wyrm_cube:lamp" })
	core.set_node({
		x = pos.x + 1,
		y = pos.y + height + 1,
		z = pos.z + 1,
	}, { name = "wyrm_cube:lamp" })

	core.set_node({
		x = pos.x + width,
		y = pos.y + height,
		z = pos.z + 1,
	}, { name = "wyrm_cube:lamp" })
	core.set_node({
		x = pos.x + width,
		y = pos.y + height + 1,
		z = pos.z + 1,
	}, { name = "wyrm_cube:lamp" })

	core.set_node({
		x = pos.x + 1,
		y = pos.y + height,
		z = pos.z + width,
	}, { name = "wyrm_cube:lamp" })
	core.set_node({
		x = pos.x + 1,
		y = pos.y + height + 1,
		z = pos.z + width,
	}, { name = "wyrm_cube:lamp" })

	core.set_node({
		x = pos.x + width,
		y = pos.y + height,
		z = pos.z + width,
	}, { name = "wyrm_cube:lamp" })
	core.set_node({
		x = pos.x + width,
		y = pos.y + height + 1,
		z = pos.z + width,
	}, { name = "wyrm_cube:lamp" })
	-- Drill a hole down the middle
	for y = 1, height do
		for x = 1, width do
			for z = 1, width do
				if x == math.floor(width / 2) and z == math.floor(width / 2) then
					core.set_node({
						x = pos.x + x,
						y = pos.y + y,
						z = pos.z + z,
					}, { name = "default:ladder_steel", param2 = 5 })
					core.set_node({
						x = pos.x + x,
						y = pos.y + y,
						z = pos.z + z + 1,
					}, { name = "air" })
					local block = "default:aspen_wood"
					if y % 4 == 0 and y > 8 then
						block = "wyrm_cube:lamp_blinking_off"
					end
					core.set_node({
						x = pos.x + x,
						y = pos.y + y,
						z = pos.z + z - 1,
					}, { name = block })
					core.set_node({
						x = pos.x + x,
						y = pos.y + y,
						z = pos.z + z + 2,
					}, { name = block })
				end
			end
		end
	end
	-- Make a walkway through the front
	pos = pos_c
	for x = 1, width_c do
		for z = 1, width_c do
			if x == math.floor(width_c / 2) and z > math.floor(width_c / 2) then
				core.set_node({
					x = pos.x + x,
					y = pos.y + 1,
					z = pos.z + z,
				}, { name = "air" })
				core.set_node({
					x = pos.x + x,
					y = pos.y + 2,
					z = pos.z + z,
				}, { name = "air" })
			end
		end
	end
	-- Place a door
	core.set_node({
		x = pos.x + math.floor(width_c / 2),
		y = pos.y + 1,
		z = pos.z + width_c,
	}, { name = "doors:door_glass_a" })
	-- Place a small lamp above the door
	core.set_node({
		x = pos.x + math.floor(width_c / 2),
		y = pos.y + 3,
		z = pos.z + width_c + 1,
	}, { name = "wyrm_cube:lamp_small", param2 = 5 })
	pos = pos_c
	pos.y = pos.y + height + 2
	pos.x = pos.x + width_c / 2
	pos.z = pos.z + width_c / 2
	player:set_pos(pos)
	spawn_particles(pos)
end

local function spawn_clouds(name)
	local player = core.get_player_by_name(name)
	if not player then
		return false, "Player not found!"
	end
	local player_name = player:get_player_name()
	local is_spawning = mod_storage:get_int(player_name .. "_spawning_clouds")
	if is_spawning ~= 1 then
		return false, "Not spawning clouds!"
	end
	local pos = player:get_pos()
	pos.y = pos.y - 1
	local width = 64
	local wh = width / 2
	local layers = 1
	local amt = width * width * layers
	local time = 6
	for i = 1, amt do
		local r_pos = vector.new(pos)
		r_pos.x = r_pos.x + math.random(-wh, wh)
		r_pos.y = r_pos.y + math.random(-layers, 0)
		r_pos.z = r_pos.z + math.random(-wh, wh)
		-- Cap r_pos to 300 y, prevents spawning at wyrm head
		if r_pos.y > 300 then
			r_pos.y = 300
		end
		local current_node = core.get_node(r_pos)
		if current_node.name ~= "air" then
			log("Not air, skipping: " .. current_node.name)
			goto continue
		end
		log("Spawning cloud at: " .. core.pos_to_string(r_pos))
		core.after(i / (amt / time), function()
			core.set_node(r_pos, { name = "wyrm_cube:cloud_block" })
		end)
		::continue::
	end
	core.after(6, function()
		spawn_clouds(name)
	end)
end

local function set_game_over(player)
	local final_pos_str = mod_storage:get_string("final_pos")
	-- Convert to a real position table
	local final_pos = core.string_to_pos(final_pos_str)
	if not final_pos then
		log("Final position not found, using default")
		final_pos = { x = 0, y = 128, z = 0 }
	end
	final_pos.z = final_pos.z - 48
	final_pos.x = final_pos.x - 4
	player:set_pos(final_pos)
	set_move(player, move_speeds.stuck)
	-- Show the Wyrm Cube logo
	core.after(7, function()
		player:hud_add({
			hud_elem_type = "image",
			position = { x = 0.5, y = 0.5 },
			offset = { x = 0, y = 0 },
			scale = { x = 12, y = 12 },
			alignment = { x = 0, y = 0 },
			text = "header.png",
		})
	end)
end

local function set_end_game()
	core.set_timeofday(0) -- midnight
	core.setting_set("time_speed", 1)
end

local function spawn_end_callback(pos, action, num_calls_remaining, context)
	-- On first call, record number of blocks
	if not context.total_blocks then
		context.total_blocks = num_calls_remaining + 1
		context.loaded_blocks = 0
	end

	-- Increment number of blocks loaded
	context.loaded_blocks = context.loaded_blocks + 1

	-- Send progress message
	if context.total_blocks ~= context.loaded_blocks then
		local perc = 100 * context.loaded_blocks / context.total_blocks
		local msg = string.format("Loading blocks %d/%d (%.2f%%)", context.loaded_blocks, context.total_blocks, perc)
		log(msg)
		return
	end

	local name = context.name
	local height = 256
	local width = 17
	local player = core.get_player_by_name(name)
	local pos = player:get_pos()
	local pos_p = vector.new(pos) -- cache
	pos.y = height
	pos.x = pos.x - math.floor(width / 2)
	pos.z = pos.z - math.floor(width / 2)
	for x = 1, width do
		for z = 1, width do
			core.set_node({
				x = pos.x + x,
				y = pos.y,
				z = pos.z + z,
			}, { name = "wyrm_cube:cloud_block_perm" })
		end
	end
	-- Build the walls
	width = width - 8
	pos.x = pos.x + 4
	pos.z = pos.z + 4
	local t_height = 8
	for y = 1, t_height do
		for x = 1, width do
			for z = 1, width do
				if z ~= 1 and z ~= width and x ~= 1 and x ~= width then
					core.set_node({
						x = pos.x + x,
						y = pos.y + y,
						z = pos.z + z,
					}, { name = "air" })
				else
					core.set_node({
						x = pos.x + x,
						y = pos.y + y,
						z = pos.z + z,
					}, { name = "wyrm_cube:cloud_block_perm" })
				end
			end
		end
	end
	-- Place disintegrating walls
	for y = 1, t_height * 3 do
		for x = 1, width do
			for z = 1, width do
				if z ~= 1 and z ~= width and x ~= 1 and x ~= width then
					core.set_node({
						x = pos.x + x,
						y = pos.y + y,
						z = pos.z + z,
					}, { name = "air" })
				else
					local chance = 100 - (y / (t_height * 3)) * 100
					if rk:pchance(chance) then
						core.set_node({
							x = pos.x + x,
							y = pos.y + y + t_height,
							z = pos.z + z,
						}, { name = "wyrm_cube:cloud_block_perm" })
					end
				end
			end
		end
	end
	-- Place a door
	core.set_node({
		x = pos.x + math.floor(width / 2) + 1,
		y = pos.y + 2,
		z = pos.z + width,
	}, { name = "air" })
	core.set_node({
		x = pos.x + math.floor(width / 2) + 1,
		y = pos.y + 1,
		z = pos.z + width,
	}, { name = "doors:door_glass_a" })

	-- Place a waterfall
	local waterfall_pos = vector.new(pos)
	waterfall_pos.x = waterfall_pos.x + math.floor(width / 2) + 1
	waterfall_pos.y = waterfall_pos.y + 1
	waterfall_pos.z = waterfall_pos.z + width + 4
	core.set_node(waterfall_pos, { name = "default:water_source" })
	waterfall_pos.x = waterfall_pos.x - 1
	core.set_node(waterfall_pos, { name = "wyrm_cube:cloud_block_perm" })
	waterfall_pos.x = waterfall_pos.x + 2
	core.set_node(waterfall_pos, { name = "wyrm_cube:cloud_block_perm" })
	waterfall_pos.x = waterfall_pos.x - 1
	waterfall_pos.z = waterfall_pos.z - 1
	core.set_node(waterfall_pos, { name = "wyrm_cube:cloud_block_perm" })

	-- Place a Wyrm Chest in the middle
	local chest_pos = vector.new(pos)
	chest_pos.x = chest_pos.x + math.floor(width / 2) + 1
	chest_pos.y = chest_pos.y + 1
	chest_pos.z = chest_pos.z + math.floor(width / 2) + 1
	core.set_node(chest_pos, { name = "wyrm_cube:wyrm_chest" })
	local meta = core.get_meta(chest_pos)
	local inv = meta:get_inventory()
	inv:set_size("main", 1)
	inv:add_item("main", "wyrm_cube:wyrm_sigil 1")

	-- Reset the width and position for the next part
	width = width + 4
	pos.x = pos.x - 4
	pos.z = pos.z - 4

	-- Move to second part
	pos.z = pos.z + 128 - width

	for x = 1, width do
		for z = 1, width do
			core.set_node({
				x = pos.x + x,
				y = pos.y - 1,
				z = pos.z + z,
			}, { name = "wyrm_cube:cloud_block_perm" })
		end
	end
	-- Place a wyrm portal
	local portal_pos = vector.new(pos)
	portal_pos.x = portal_pos.x + math.floor(width / 2) + 1
	portal_pos.y = portal_pos.y + 1
	portal_pos.z = portal_pos.z + 1 -- Can be overwritten! BAD
	core.set_node(portal_pos, { name = "wyrm_cube:wyrm_portal" })

	width = width - 4
	pos.x = pos.x + 2
	pos.z = pos.z + 2
	t_height = 256
	for y = 1, t_height do
		for x = 1, width do
			for z = 1, width do
				local block = "wyrm_cube:wyrm_scale"
				if z == 1 and x > 2 and x < width - 1 then
					block = "wyrm_cube:wyrm_belly"
				end
				core.set_node({
					x = pos.x + x,
					y = pos.y + y - 1,
					z = pos.z + z,
				}, { name = block })
			end
		end
		if y % 4 == 0 then
			if rk:pchance(50) then
				pos.x = pos.x + 1
			end
			if rk:pchance(50) then
				pos.x = pos.x - 1
			end
		end
		if rk:pchance(50) then
			pos.z = pos.z + 1
		end
	end
	-- Make the head
	width = width + 4
	pos.x = pos.x - 2
	pos.z = pos.z - 2 - 16
	local length = 32
	local head_final = {}
	for y = 1, 16 do
		if y == 1 then
			width = width - 2
			pos.x = pos.x + 1
		end
		if y == 2 then
			width = width + 2
			pos.x = pos.x - 1
		end
		for x = 1, width do
			for z = 1, length do
				local block = "wyrm_cube:wyrm_scale"
				local n_pos = {
					x = pos.x + x,
					y = pos.y + y + t_height - 1,
					z = pos.z + z,
				}
				core.set_node(n_pos, { name = block })
				head_final = vector.new(n_pos)
			end
		end
		mod_storage:set_string("final_pos", core.pos_to_string(head_final))
		-- Place the eyes
		if y >= 9 and y <= 12 then
			core.set_node({
				x = pos.x + 1,
				y = pos.y + y + t_height - 1,
				z = pos.z,
			}, { name = "wyrm_cube:wyrm_eye" })
			core.set_node({
				x = pos.x + width,
				y = pos.y + y + t_height - 1,
				z = pos.z,
			}, { name = "wyrm_cube:wyrm_eye" })
		end
		if y > 4 then
			if y < 14 then
				length = length - 1
			else
				length = length - 2
			end
			pos.z = pos.z + 1
			if y % 4 == 0 then
				width = width - 2
				pos.x = pos.x + 1
			end
		end
	end
	core.after(0.1, function()
		pos_p.y = height + 3
		player:set_pos(pos_p)
		set_end_game()
	end)
end
local function spawn_end(name)
	mod_storage:set_int("end_game", 1)
	local context = { name = name }
	local player_pos = core.get_player_by_name(name):get_pos()
	local pos_s = vector.new(player_pos)
	pos_s.z = pos_s.z - 128
	pos_s.x = pos_s.x - 128
	local pos_e = vector.new(player_pos)
	pos_e.z = pos_e.z + 256
	pos_e.x = pos_e.x + 128
	pos_e.y = pos_e.y + 512
	core.emerge_area(pos_s, pos_e, spawn_end_callback, context)
end

--
-- NODE REGISTRATION
--

-- Register the wyrm cube node
core.register_node("wyrm_cube:wyrm_cube", {
	description = "Wyrm Cube",
	drawtype = "mesh",
	mesh = "wyrm_cube.obj",
	tiles = { "wyrm_cube.png" },
	is_ground_content = false,
	groups = { cracky = 3, oddly_breakable_by_hand = 2 },
	sounds = default.node_sound_stone_defaults(),
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	after_place_node = function(pos, placer)
		local player_name = placer:get_player_name() or "unknown"
		log("Player " .. player_name .. " placed a wyrm cube at " .. core.pos_to_string(pos))
		table.insert(wyrm_cubes, pos)
		save_wyrm_cubes()
		spawn_particles(pos)
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		core.set_timeofday(0) -- midnight
		local player_name = digger:get_player_name() or "unknown"
		log("Player " .. player_name .. " removed a wyrm cube at " .. core.pos_to_string(pos))
		for i, cube_pos in ipairs(wyrm_cubes) do
			if vector.equals(pos, cube_pos) then
				table.remove(wyrm_cubes, i)
				break
			end
		end
		local player_pos = digger:get_pos()
		core.sound_play("cube_get", {
			pos = player_pos,
			gain = 10.0,
			max_hear_distance = 10,
			loop = false,
		})
		save_wyrm_cubes()
		spawn_particles(pos)
		-- Spawn a tower
		local t_pos = vector.new(pos)
		for i = 1, 64 do
			core.set_node(t_pos, { name = "default:obsidian" })
			if math.random() > 0.5 then
				if math.random() > 0.75 then
					t_pos.x = t_pos.x + 1
				elseif math.random() > 0.75 then
					t_pos.x = t_pos.x - 1
				end
				core.set_node(t_pos, { name = "default:obsidian" })
			end
			t_pos.y = t_pos.y + 1
		end
		local chest_options = {
			"draconis:axe_ice_draconic_steel",
			"draconis:axe_fire_draconic_steel",
			"draconis:boots_ice_draconic_steel",
			"draconis:boots_fire_draconic_steel",
			"draconis:sword_ice_draconic_steel",
			"draconis:sword_fire_draconic_steel",
			"draconis:helmet_ice_draconic_steel",
			"draconis:helmet_fire_draconic_steel",
			"draconis:leggings_ice_draconic_steel",
			"draconis:leggings_fire_draconic_steel",
			"draconis:chestplate_ice_draconic_steel",
			"draconis:chestplate_fire_draconic_steel",
			"draconis:axe_dragonhide_fire_red",
			"draconis:axe_dragonhide_ice_sapphire",
			"draconis:sword_dragonhide_fire_red",
			"draconis:sword_dragonhide_ice_sapphire",
		}
		local chest_pos = vector.new(t_pos)
		chest_pos.y = chest_pos.y + 1
		core.set_node(chest_pos, { name = "wyrm_cube:wyrm_chest" })
		local meta = core.get_meta(chest_pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 2) -- Default chest size
		inv:add_item("main", chest_options[math.random(1, #chest_options)] .. " 1")
		inv:add_item("main", chest_options[math.random(1, #chest_options)] .. " 1")
		local chest_pos2 = vector.new(pos)
		chest_pos2.y = chest_pos2.y - 2
		local glass_pos = vector.new(pos)
		glass_pos.y = glass_pos.y - 1
		core.set_node(glass_pos, { name = "default:glass" })
		core.set_node(chest_pos2, { name = "wyrm_cube:wyrm_chest" })
		local meta2 = core.get_meta(chest_pos2)
		local inv2 = meta2:get_inventory()
		inv2:set_size("main", 2)
		inv2:add_item("main", chest_options[math.random(1, #chest_options)] .. " 1")
		inv2:add_item("main", chest_options[math.random(1, #chest_options)] .. " 1")
		-- Spawn a dragon at the cube's position
		local d_pos = vector.new(pos)
		d_pos.y = d_pos.y + 32
		d_pos.x = d_pos.x + 8
		core.add_entity(d_pos, "draconis:fire_dragon")
	end,
})

core.register_node("wyrm_cube:lamp", {
	description = "A Lamp",
	tiles = { "wyrm_lamp.png" },
	is_ground_content = false,
	groups = { cracky = 3 },
	sounds = default.node_sound_stone_defaults(),
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	after_place_node = function(pos, placer)
		--
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		--
	end,
})

core.register_node("wyrm_cube:lamp_small", {
	description = "A Lamp",
	tiles = { "wyrm_lamp.png" },
	drawtype = "mesh",
	mesh = "small_cube.obj",
	is_ground_content = false,
	paramtype2 = "facedir", -- Enable full rotation support
	on_rotate = screwdriver.rotate_simple, -- Allow simple rotation using the screwdriver
	groups = { cracky = 3 },
	sounds = default.node_sound_stone_defaults(),
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true, -- Allows light to pass through
	glow = 10,
	after_place_node = function(pos, placer)
		--
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		--
	end,
})

core.register_node("wyrm_cube:lamp_blinking_off", {
	description = "Blinking Lamp (Off)",
	tiles = { "wyrm_lamp_off.png" },
	groups = { cracky = 3 },
	light_source = 0,
	on_construct = function(pos)
		-- Start the timer with an interval of 1 second
		core.get_node_timer(pos):start(1)
	end,
	on_timer = function(pos, elapsed)
		-- Switch to the "on" state
		core.swap_node(pos, { name = "wyrm_cube:lamp_blinking_on" })
		return true -- Continue the timer
	end,
})

core.register_node("wyrm_cube:lamp_blinking_on", {
	description = "Blinking Lamp (On)",
	tiles = { "wyrm_lamp.png" },
	groups = { cracky = 3, not_in_creative_inventory = 1 },
	light_source = 14, -- Emit light when "on"
	drop = "wyrm_cube:lamp_blinking_off", -- Drop the "off" node
	on_timer = function(pos, elapsed)
		-- Switch to the "off" state
		core.swap_node(pos, { name = "wyrm_cube:lamp_blinking_off" })
		return true -- Continue the timer
	end,
})

core.register_node("wyrm_cube:cloud_block", {
	description = "Walkable Cloud",
	tiles = { "cloud.png" },
	groups = {},
	light_source = 1,
	paramtype = "light",
	glow = 1,
	on_construct = function(pos)
		-- Start the timer with an interval of 1 second
		core.get_node_timer(pos):start(10)
		return true
	end,
	on_timer = function(pos, elapsed)
		-- Switch to the "on" state
		core.swap_node(pos, { name = "air" })
		return true -- Continue the timer
	end,
})
core.register_node("wyrm_cube:cloud_block_perm", {
	description = "Walkable Cloud (Permanent)",
	tiles = { "cloud.png" },
	groups = {},
	light_source = 2,
	paramtype = "light",
	glow = 2,
})
core.register_node("wyrm_cube:wyrm_scale", {
	description = "Wyrm Scale",
	tiles = { "wyrm_scale.png" },
	groups = {},
	light_source = 8,
	paramtype = "light",
	glow = 4,
})
core.register_node("wyrm_cube:wyrm_belly", {
	description = "Wyrm Belly",
	tiles = { "wyrm_belly.png" },
	groups = {},
	light_source = 14,
	paramtype = "light",
	glow = 8,
})
core.register_node("wyrm_cube:wyrm_eye", {
	description = "Wyrm Eye",
	tiles = { "wyrm_eye.png" },
	groups = {},
	light_source = 14,
	paramtype = "light",
	glow = 14,
})
core.register_node("wyrm_cube:wyrm_portal", {
	description = "Wyrm Portal",
	tiles = { "wyrm_portal.png" },
	groups = {},
	light_source = 14,
	paramtype = "light",
	glow = 14,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		mod_storage:set_int("game_over", 1)
		set_game_over(clicker)
	end,
})
core.register_node("wyrm_cube:supply_drop", {
	description = "Supply Drop",
	tiles = {
		"supply_drop.png",
		"supply_drop.png",
		"supply_drop.png",
		"supply_drop.png",
		"supply_drop.png",
		"supply_drop.png",
	},
	paramtype2 = "facedir",
	groups = { choppy = 2, oddly_breakable_by_hand = 2, falling_node = 1 },
	is_ground_content = false,
	light_source = 14,
	paramtype = "light",
	glow = 10,
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string(
			"formspec",
			"size[8,9]"
				.. "list[current_name;main;0,0.3;8,4;]"
				.. "list[current_player;main;0,4.85;8,1;]"
				.. "list[current_player;main;0,6.08;8,3;8]"
				.. "listring[current_name;main]"
				.. "listring[current_player;main]"
		)
		meta:set_string("infotext", "Supply Drop")
		local inv = meta:get_inventory()
		inv:set_size("main", 8 * 4)

		-- Trigger falling right after placement
		core.after(0, function()
			core.check_for_falling(pos)
		end)
	end,

	can_dig = function(pos, player)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,

	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "main", drops)
		drops[#drops + 1] = "wyrm_cube:supply_drop"
		core.remove_node(pos)
		return drops
	end,
})

core.register_node("wyrm_cube:wyrm_chest", {
	description = "Wyrm Chest",
	tiles = { "wyrm_cube.png", "wyrm_cube.png", "wyrm_cube.png", "wyrm_cube.png", "wyrm_cube.png", "wyrm_cube.png" },
	paramtype2 = "facedir",
	groups = { choppy = 2, oddly_breakable_by_hand = 2, falling_node = 1 },
	is_ground_content = false,
	light_source = 14,
	paramtype = "light",
	glow = 10,
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string(
			"formspec",
			"size[8,9]"
				.. "list[current_name;main;0,0.3;8,4;]"
				.. "list[current_player;main;0,4.85;8,1;]"
				.. "list[current_player;main;0,6.08;8,3;8]"
				.. "listring[current_name;main]"
				.. "listring[current_player;main]"
		)
		meta:set_string("infotext", "Wyrm Chest")
		local inv = meta:get_inventory()
		inv:set_size("main", 2)

		-- Trigger falling right after placement
		core.after(0, function()
			core.check_for_falling(pos)
		end)
	end,

	can_dig = function(pos, player)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,

	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "main", drops)
		drops[#drops + 1] = "wyrm_cube:wyrm_chest"
		core.remove_node(pos)
		return drops
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		log("putting item: " .. stack:get_name())
		if stack:get_name() == "wyrm_cube:wyrm_cube" and stack:get_count() >= cfg.cube_count then
			core.after(0, function()
				spawn_end(player:get_player_name())
				core.remove_node(pos)
				spawn_particles(pos)
			end)
		end
		if stack:get_name() == "wyrm_cube:wyrm_sigil" then
			core.after(0, function()
				core.remove_node(pos)
				core.add_node(pos, { name = "wyrm_cube:wyrm_portal" })
				spawn_particles(pos)
			end)
		end
		return stack:get_count()
	end,
})

local transmutation_rates = {
	{ "ore", 0.6 },
	{ "wyrm", 0.25 },
	{ "diamond", 1 },
	{ "gold", 0.8 },
	{ "crystal", 0.9 },
	{ "obsidian", 0.9 },
	{ "mithril", 0.9 },
	{ "steel", 0.7 },
	{ "mese", 0.6 },
	{ "flower", 0.5 },
	{ "copper", 0.5 },
	{ "bronze", 0.5 },
	{ "iron", 0.4 },
	{ "tin", 0.4 },
	{ "coal", 0.3 },
	{ "wood", 0.2 },
	-- Override for specific items
	{ "gold_ingot", 0.25 },
	{ "mese_crystal", 0.2 },
	-- Not allowed to transmute
	{ "supply_dropper", 0 },
}

local function calculate_transmute_rate(meta, stack)
	local transmute_rate = 0.1
	local out_type = "air"
	local out_count = 0
	if stack == nil then
		transmute_rate = 0
		log("got nil stack")
	end
	if stack ~= nil and not stack:is_empty() then
		-- Check the tranmutation rate
		for _, item in ipairs(transmutation_rates) do
			local item_name = item[1]
			local item_rate = item[2]
			if rk:string_includes(stack:get_name(), item_name) then
				transmute_rate = item_rate
				break
			end
		end

		-- Output type
		out_type = "default:gold_ingot"
		if stack:get_name() == "default:gold_ingot" then
			out_type = "default:mese_crystal"
		end
		if stack:get_name() == "default:mese_crystal" then
			out_type = "wyrm_cube:tech_chip"
		end
		if stack:get_name() == "wyrm_cube:tech_chip" then
			out_type = "wyrm_cube:supply_dropper"
		end

		out_count = math.floor(stack:get_count() * transmute_rate)
	end
	meta:set_float("transmute_rate", transmute_rate)
	log("transmute_rate: " .. transmute_rate)
	meta:set_string("out_type", out_type)
	local can_transmute_string = "//// TRANSMUTE READY!"
	if out_count == 0 then
		can_transmute_string = "//// NOT ENOUGH ITEMS TO TRANSMUTE!"
	end
	meta:set_string(
		"formspec",
		"size[8,9]"
			.. "list[current_name;main;0,0.3;8,4;]"
			.. "label[0,1.5;// JUNK > INGOT > CRYSTAL > CHIP > SUPPLY DROP]"
			.. "label[0,2;// TRANSMUTATION RATE: "
			.. transmute_rate
			.. "x ("
			.. out_count
			.. ")]"
			.. "label[0,2.5;// TRANSMUTATION TYPE: "
			.. out_type
			.. "]"
			.. "label[0,3;"
			.. can_transmute_string
			.. "]"
			.. "button[3,4;2,1;transmute;TRANSMUTE]"
			.. "list[current_player;main;0,5;8,1;]"
			.. "list[current_player;main;0,6;8,3;8]"
			.. "listring[current_name;main]"
			.. "listring[current_player;main]"
	)
	return transmute_rate
end

core.register_node("wyrm_cube:transmuter", {
	description = "Transmuter",
	drawtype = "mesh",
	mesh = "transmuter.obj",
	tiles = { "transmuter.png" },
	paramtype2 = "facedir",
	on_rotate = screwdriver.rotate_simple, -- Allow simple rotation using the screwdriver
	groups = { choppy = 2, oddly_breakable_by_hand = 2, falling_node = 1 },
	is_ground_content = false,
	light_source = 14,
	paramtype = "light",
	glow = 10,
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		calculate_transmute_rate(meta, nil)
		meta:set_string("infotext", "Transmuter")
		local inv = meta:get_inventory()
		inv:set_size("main", 1)

		-- Trigger falling right after placement
		core.after(0, function()
			core.check_for_falling(pos)
		end)
	end,

	can_dig = function(pos, player)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("main")
	end,

	on_receive_fields = function(pos, formname, fields, player)
		if fields.transmute then
			local meta = core.get_meta(pos)
			local inv = meta:get_inventory()
			local stack = inv:get_stack("main", 1)
			local transmute_rate = meta:get_float("transmute_rate") or 0.1
			local out_type = meta:get_string("out_type") or "air"
			if not stack:is_empty() then
				-- Calculate the number to give (10% of the item count)
				local out_count = math.floor(stack:get_count() * transmute_rate)
				log("out: " .. out_count)
				log("rate: " .. transmute_rate)
				log("#stack:" .. stack:get_count())
				if out_count > 0 then
					inv:set_stack("main", 1, out_type .. " " .. out_count)
					spawn_particles(pos)
					-- Notify the player
					core.chat_send_player(player:get_player_name(), "Items transmuted!")
					calculate_transmute_rate(meta, inv:get_stack("main", 1))
				else
					core.chat_send_player(player:get_player_name(), "Not enough items to transmute!")
				end
			else
				core.chat_send_player(player:get_player_name(), "The chest is empty!")
			end
		end
	end,

	on_blast = function(pos)
		local drops = {}
		default.get_inventory_drops(pos, "main", drops)
		drops[#drops + 1] = "wyrm_cube:supply_drop"
		core.remove_node(pos)
		return drops
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		log("putting item: " .. stack:get_name())
		local meta = core.get_meta(pos)
		-- Wait 0.1 seconds because the take will happen after
		core.after(0.1, function()
			calculate_transmute_rate(meta, stack)
		end)
		return stack:get_count()
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return count
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		log("taking item: " .. stack:get_name())
		local meta = core.get_meta(pos)
		calculate_transmute_rate(meta, nil)
		return stack:get_count()
	end,
})

--
-- TOOLS & CRAFT ITEMS
--

-- Register the wyrm radar item
core.register_tool("wyrm_cube:wyrm_radar", {
	description = "wyrm Radar",
	inventory_image = "wyrm_radar.png",
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		local player_pos = user:get_pos()

		local nearest_cube, nearest_distance = nil, math.huge

		-- Find the nearest wyrm cube
		for _, pos in ipairs(wyrm_cubes) do
			local distance = vector.distance(player_pos, pos)
			if distance < nearest_distance then
				nearest_cube = pos
				nearest_distance = distance
			end
		end

		if nearest_cube then
			local difference = vector.subtract(nearest_cube, player_pos)
			local direction = vector.normalize(difference)
			local steps = math.floor(nearest_distance / 1) -- Adjust step size for smoother line
			local color_str = "#FFFF00" -- Yellow color for particles

			-- Display wyrm cube information
			log(user:get_player_name() .. " Distance: " .. nearest_distance)
			log(user:get_player_name() .. " Remaining Wyrm Cubes: " .. #wyrm_cubes)

			rk:hud_msg(user, "Distance: " .. math.floor(nearest_distance) .. "\nCUBE: #" .. #wyrm_cubes, 6)

			-- Render a line of particles pointing to the wyrm cube
			for i = 1, steps do
				local particle_pos = vector.add(player_pos, vector.multiply(direction, i))
				particle_pos.y = particle_pos.y + 1 -- Adjust the height for better visibility

				core.add_particle({
					pos = particle_pos,
					velocity = { x = 0, y = 0, z = 0 },
					acceleration = { x = 0, y = 0.1 + math.random(), z = 0 },
					expirationtime = 10,
					size = 3,
					texture = "wyrm_line_particle.png^[colorize:" .. color_str .. ":127",
					glow = 10,
				})
			end
			core.sound_play("scan", {
				pos = player_pos,
				gain = 1.0,
				max_hear_distance = 10,
				loop = false,
			})
		else
			core.sound_play("scan_bad", {
				pos = player_pos,
				gain = 10.0,
				max_hear_distance = 10,
				loop = false,
			})
		end
		for i = 1, cfg.monster_spawn_amt do
			core.after(i / 2, function()
				spawn_monster(user:get_player_name())
			end)
		end
	end,
})

core.register_tool("wyrm_cube:meta_scanner", {
	description = "Meta Scanner",
	inventory_image = "meta_scanner.png",
	light_source = 14,
	paramtype = "light",
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		if not user then
			return
		end

		-- Get player's position and look direction
		local pos = user:get_pos()
		local dir = user:get_look_dir()

		-- Adjust the starting position slightly above the player's feet to avoid self-collision
		pos.y = pos.y + 1.5

		-- Perform the raycast
		local ray = core.raycast(pos, vector.add(pos, vector.multiply(dir, 10)), true, true)

		-- Iterate through the raycast results
		for pointed in ray do
			if pointed.type == "node" then
				-- Player is looking at a node
				local node = core.get_node(pointed.under)
				local node_name = node.name
				rk:hud_msg(user, "NODE:\n" .. node_name, 3)
				spawn_particles(pointed.under)
				break
			elseif pointed.type == "object" then
				-- Player is looking at an entity
				local obj = pointed.ref
				if obj and obj:get_luaentity() then
					local entity_name = obj:get_luaentity().description or obj:get_luaentity().name
					rk:hud_msg(user, "ENTITY:\n" .. entity_name, 3)
					spawn_particles(pointed.under)
				elseif obj and obj:is_player() then
					goto continue
				end
				break
			end
			::continue::
		end
	end,
})

core.register_tool("wyrm_cube:meta_vacuum", {
	description = "Meta Vacuum",
	inventory_image = "vac.png",
	light_source = 14,
	paramtype = "light",
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		if not user then
			return
		end

		local pos = user:get_pos()
		local dir = user:get_look_dir()
		pos.y = pos.y + 1.5

		-- Perform the raycast
		local ray = core.raycast(pos, vector.add(pos, vector.multiply(dir, 10)), true, true)

		-- Iterate through the raycast results
		for pointed in ray do
			if pointed.type == "node" then
				-- Player is looking at a node
				local pointed_pos = pointed.under
				local node = core.get_node(pointed_pos)
				local def = core.registered_nodes[node.name]

				if def and def.diggable ~= false then
					-- Simulate digging the node
					local drops = core.get_node_drops(node.name)
					local inv = user:get_inventory()

					-- Attempt to add drops to the player's inventory
					local has_room = true
					for _, drop in ipairs(drops) do
						if not inv:room_for_item("main", drop) then
							has_room = false
							break
						end
					end

					if has_room then
						-- Add drops directly to the player's inventory
						for _, drop in ipairs(drops) do
							inv:add_item("main", drop)
						end

						-- sneak is pressed just replace with air
						if user:get_player_control().sneak then
							core.set_node(pointed_pos, { name = "air" })
						else
							-- Call the engine's dig logic to trigger callbacks and side effects
							core.node_dig(pointed_pos, node, user)
						end
						spawn_particles(pointed_pos)
					else
						core.chat_send_player(user:get_player_name(), "Inventory full!")
					end
				else
					core.chat_send_player(user:get_player_name(), "This node cannot be dug.")
				end

				break
			elseif pointed.type == "object" then
				-- Ignore objects for now
			end
		end
	end,
})

core.register_craftitem("wyrm_cube:tech_chip", {
	description = "Tech Chip",
	inventory_image = "tech_chip.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 1,
	on_use = function(itemstack, user, pointed_thing)
		return itemstack
	end,
})

core.register_craftitem("wyrm_cube:supply_dropper", {
	description = "Supply Dropper",
	inventory_image = "supply_dropper.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		supply_drops(user, cfg.supply_drop_amt)
		itemstack:take_item(1)
		return itemstack
	end,
})

core.register_craftitem("wyrm_cube:capsule_airport", {
	description = "Airport Capsule",
	inventory_image = "capsule_yellow.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		spawn_landing_strip(user:get_player_name())
		itemstack:take_item(1)
		return itemstack
	end,
})

core.register_craftitem("wyrm_cube:capsule_yurt", {
	description = "Yurt Capsule",
	inventory_image = "capsule_white.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		spawn_yurt(user:get_player_name())
		itemstack:take_item(1)
		return itemstack
	end,
})

core.register_craftitem("wyrm_cube:capsule_watchtower", {
	description = "Watchtower Capsule",
	inventory_image = "capsule_black.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		spawn_watchtower(user:get_player_name())
		itemstack:take_item(1)
		return itemstack
	end,
})

core.register_craftitem("wyrm_cube:capsule_megatower", {
	description = "Megatower Capsule",
	inventory_image = "capsule_red.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		spawn_megatower(user:get_player_name())
		itemstack:take_item(1)
		return itemstack
	end,
})

core.register_craftitem("wyrm_cube:wyrm_sigil", {
	description = "Wyrm Sigil",
	inventory_image = "wyrm_sigil.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		local player_name = user:get_player_name()
		if mod_storage:get_int(player_name .. "_spawning_clouds") == 1 then
			return itemstack
		end
		mod_storage:set_int(player_name .. "_spawning_clouds", 1)
		spawn_clouds(user:get_player_name())
		return itemstack
	end,
})

core.register_craftitem("wyrm_cube:radio", {
	description = "Radio to play some tunes",
	inventory_image = "wyrm_radio.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		local playing = meta:get_int("playing") or -1
		log(playing or "nil")
		local text = ""
		if playing ~= nil and playing > -1 then
			-- Stop the sound
			core.sound_stop(playing)
			meta:set_int("playing", -1)
			text = "STOPPED"
		else
			local track = "track" .. math.random(1, 3)
			local track_num = core.sound_play(track, {
				pos = user:get_pos(),
				gain = 1.0,
				max_hear_distance = 100,
				loop = false,
			})
			meta:set_int("playing", track_num)
			text = "PLAY: " .. track
		end
		core.sound_play("static", {
			pos = user:get_pos(),
			gain = 1.0,
			max_hear_distance = 100,
			loop = false,
		})
		rk:hud_msg(user, text, 2)
		return itemstack
	end,
})

core.register_craftitem("wyrm_cube:respawner", {
	description = "Respawner",
	inventory_image = "respawner.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		user:respawn()
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_mv_runner", {
	description = "Wyrm Potion: Runner",
	inventory_image = "potion_blue.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		set_move(user:get_player_name(), move_speeds.runner)
		warn_potion(user, "Runner", 30)
		core.after(30, function()
			set_move(user:get_player_name(), move_speeds.normal)
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_mv_doom", {
	description = "Wyrm Potion: DOOM",
	inventory_image = "potion_pink.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		set_move(user:get_player_name(), move_speeds.doom)
		warn_potion(user, "DOOM", 30)
		core.after(30, function()
			set_move(user:get_player_name(), move_speeds.normal)
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_mv_hyper", {
	description = "Wyrm Potion: Hyper",
	inventory_image = "potion_cyan.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		set_move(user:get_player_name(), move_speeds.hyper)
		warn_potion(user, "Hyper", 30)
		core.after(30, function()
			set_move(user:get_player_name(), move_speeds.normal)
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_mv_moon", {
	description = "Wyrm Potion: Moon",
	inventory_image = "potion_white.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		set_move(user:get_player_name(), move_speeds.moon)
		warn_potion(user, "Moon", 30)
		core.after(30, function()
			set_move(user:get_player_name(), move_speeds.normal)
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_mv_mars", {
	description = "Wyrm Potion: Mars",
	inventory_image = "potion_red.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		set_move(user:get_player_name(), move_speeds.mars)
		warn_potion(user, "Mars", 30)
		core.after(30, function()
			set_move(user:get_player_name(), move_speeds.normal)
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_mv_low_orbit", {
	description = "Wyrm Potion: Low Orbit",
	inventory_image = "potion_yellow.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		set_move(user:get_player_name(), move_speeds.low_orbit)
		warn_potion(user, "Low Orbit", 30)
		core.after(30, function()
			set_move(user:get_player_name(), move_speeds.normal)
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_mv_rabbit", {
	description = "Wyrm Potion: Rabbit",
	inventory_image = "potion_cyan.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		set_move(user:get_player_name(), move_speeds.rabbit)
		warn_potion(user, "Rabbit", 30)
		core.after(30, function()
			set_move(user:get_player_name(), move_speeds.normal)
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_immunity_1", {
	description = "Wyrm Potion: Immunity 1",
	inventory_image = "potion_white.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		rk:no_dmg(user:get_player_name(), 6)
		warn_potion(user, "Immunity 1", 6)
		core.after(6, function()
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_immunity_2", {
	description = "Wyrm Potion: Immunity 2",
	inventory_image = "potion_white.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		rk:no_dmg(user:get_player_name(), 30)
		warn_potion(user, "Immunity 2", 30)
		core.after(30, function()
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_immunity_3", {
	description = "Wyrm Potion: Immunity 3",
	inventory_image = "potion_white.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		rk:no_dmg(user:get_player_name(), 120)
		warn_potion(user, "Immunity 3", 120)
		core.after(120, function()
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_health_1", {
	description = "Wyrm Potion: Health 1",
	inventory_image = "potion_green.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		local hp = user:get_hp()
		local new_hp = math.min(hp + 2, 20) -- Ensure HP does not exceed 20
		user:set_hp(new_hp)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_health_2", {
	description = "Wyrm Potion: Health 2",
	inventory_image = "potion_green.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		local hp = user:get_hp()
		local new_hp = math.min(hp + 10, 20)
		user:set_hp(new_hp)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_health_3", {
	description = "Wyrm Potion: Health 3",
	inventory_image = "potion_green.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		local hp = user:get_hp()
		user:set_hp(20)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:donut", {
	description = "Replicat's Magic Donut",
	inventory_image = "donut.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		user:set_hp(200)
		rk:no_dmg(user:get_player_name(), 30)
		set_move(user:get_player_name(), move_speeds.doom)
		warn_potion(user, "Donut", 30)
		core.after(30, function()
			set_move(user:get_player_name(), move_speeds.normal)
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_cat", {
	description = "Wyrm Potion: Cat",
	inventory_image = "potion_pink.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		rk:fall_dmg(user, 0.1)
		warn_potion(user, "Cat", 16)
		core.after(16, function()
			rk:fall_dmg(user, 1)
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_feather", {
	description = "Wyrm Potion: Feather",
	inventory_image = "potion_yellow.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		rk:fall_dmg(user, 0)
		warn_potion(user, "Feather", 60)
		core.after(60, function()
			rk:fall_dmg(user, 1)
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		itemstack:take_item(1)
		return itemstack
	end,
})
core.register_craftitem("wyrm_cube:potion_bird", {
	description = "Wyrm Potion: Bird",
	inventory_image = "potion_white.png",
	stack_max = 99,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		-- Grant flying permission
		local player_name = user:get_player_name()
		local privs = core.get_player_privs(player_name) -- Get the player's current privileges
		privs.fly = true -- Add the 'fly' privilege
		core.set_player_privs(player_name, privs)
		core.chat_send_player(player_name, "You can now fly!")
		warn_potion(user, "Bird", 120)
		core.after(120, function()
			-- Remove flying permission
			privs.fly = nil -- Remove the 'fly' privilege
			core.set_player_privs(player_name, privs)
			spawn_particles(user:get_pos())
		end)
		spawn_particles(user:get_pos())
		-- Remove one item from the stack
		itemstack:take_item(1)
		-- Return the updated itemstack
		return itemstack
	end,
})

core.register_tool("wyrm_cube:wyrm_guide", {
	description = "Cube Hunter's Guide",
	inventory_image = "wyrm_guide.png",
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	on_use = function(itemstack, user, pointed_thing)
		local player_name = user:get_player_name()
		local mission_log = #wyrm_cubes .. " / " .. cfg.cube_count .. " Wyrm Cubes remaining"
		core.show_formspec(
			player_name,
			"wyrm_cube:wyrm_guide_formspec",
			string.format(
				[[
        formspec_version[4]
        size[8,8]
        background[0,0;8,8;ui_bg.png]
        style_type[hypertext;font=mono;textcolor=#003300]
        hypertext[0.5,0.5;7.5,7;Wyrm Guide;<mono>// MISSION LOG:

%s

=======

%s</mono>]

        ]],
				mission_log,
				txt.guide
			)
		)
	end,
})

--
-- CHAT COMMANDS
--

core.register_chatcommand("wc_log", {
	params = "<on|off>",
	description = "Enable or disable logging",
	privs = { server = true },
	func = function(name, param)
		if param == "on" then
			cfg.log_enabled = true
			return true, "Logging enabled."
		elseif param == "off" then
			cfg.log_enabled = false
			return true, "Logging disabled."
		else
			return false, "Invalid parameter. Use 'on' or 'off'."
		end
	end,
})

core.register_chatcommand("wc_mv", {
	params = "<normal|doom|hyper>",
	description = "Change player movement settings",
	privs = { server = true },
	func = function(name, param)
		-- Write the move name value to the sceen for debugging
		core.log("action", param)
		local move = move_speeds[param]
		if move == nil then
			return false, "Invalid movement type. Use: normal, doom, or hyper. Got " .. name
		end
		set_move(name, move) -- Set the player movement speed
		return true, "Movement set to " .. param .. "."
	end,
})
core.register_chatcommand("wc_spawn_hmob", {
	description = "Spawn a  monster near the player",
	privs = { server = true },
	func = spawn_monster,
})
-- place wyrm cubes command
core.register_chatcommand("wc_spawn_cubes", {
	params = "",
	description = "Place wyrm cubes in the world",
	privs = { server = true },
	func = function(name, param)
		log("Placing wyrm cubes on command")
		place_wyrm_cubes()
		return true, "wyrm cubes placed"
	end,
})
core.register_chatcommand("wc_spawn_yurt", {
	description = "Creates a small building a few blocks in front of the player.",
	privs = { server = true },
	func = spawn_yurt,
})
core.register_chatcommand("wc_spawn_landing_strip", {
	description = "Creates a landing strip a few blocks in front of the player.",
	privs = { server = true },
	func = spawn_landing_strip,
})
core.register_chatcommand("wc_spawn_watchtower", {
	description = "Creates a watchtower tower a few blocks in front of the player.",
	privs = { server = true },
	func = spawn_watchtower,
})
core.register_chatcommand("wc_spawn_megatower", {
	description = "Creates a megatower tower a few blocks in front of the player.",
	privs = { server = true },
	func = spawn_megatower,
})
core.register_chatcommand("wc_spawn_clouds", {
	description = "Creates walkable clouds.",
	privs = { server = true },
	func = function(name, param)
		mod_storage:set_int(name .. "_spawning_clouds", 1)
		spawn_clouds(name)
	end,
})
core.register_chatcommand("wc_stop_clouds", {
	description = "Stops walkable clouds.",
	privs = { server = true },
	func = function(name, param)
		local player = core.get_player_by_name(name)
		if player then
			local player_name = player:get_player_name()
			mod_storage:set_int(player_name .. "_spawning_clouds", 0)
			return true, "Cloud spawning stopped"
		else
			return false, "Player not found"
		end
	end,
})
core.register_chatcommand("wc_supply_drops", {
	description = "Creates a set of supply drops a few blocks in front of the player.",
	privs = { server = true },
	func = function(name, param)
		local player = core.get_player_by_name(name)
		supply_drops(player, cfg.supply_drop_amt)
	end,
})
core.register_chatcommand("wc_supply_drop", {
	description = "Creates a single supply drop a few blocks in front of the player.",
	privs = { server = true },
	func = supply_drop,
})

core.register_chatcommand("wc_spawn_particles", {
	description = "Creates a particle effect at the player's position.",
	privs = { server = true },
	func = function(name, param)
		local player = core.get_player_by_name(name)
		if player then
			spawn_particles(player:get_pos())
			return true, "Particles spawned"
		else
			return false, "Player not found"
		end
	end,
})

core.register_chatcommand("wc_spawn_end", {
	description = "Enters the end game.",
	privs = { server = true },
	func = function(name, param)
		spawn_end(name)
	end,
})

core.register_chatcommand("wc_wcc", {
	description = "Go to (check) a Wyrm Cube location.",
	params = "<cube_num>",
	privs = { server = true },
	func = function(name, param)
		local cube_num = tonumber(param)
		if cube_num == nil then
			return false, "Invalid cube number. Use a number between 1 and " .. #wyrm_cubes
		end
		if cube_num < 1 or cube_num > #wyrm_cubes then
			return false, "Invalid cube number. Use a number between 1 and " .. #wyrm_cubes
		end
		local cube_pos = vector.new(wyrm_cubes[cube_num])
		cube_pos.y = cube_pos.y + 2
		cube_pos.z = cube_pos.z + 2
		local player = core.get_player_by_name(name)
		player:set_pos(cube_pos)
	end,
})

--
-- PLAYER JOIN HANDLER
--

-- Register a handler that runs when players join
core.register_on_joinplayer(function(player)
	-- set the time speed
	core.setting_set("time_speed", 256)

	core.sound_play("intro", {
		pos = player:get_pos(),
		gain = 10.0,
		max_hear_distance = 100,
		loop = false,
	})

	players_list = mod_storage:get_string("players_list")
	if players_list == "" then
		players_list = {}
	else
		players_list = core.deserialize(players_list)
	end
	-- https://api.luanti.org/class-reference/#player-only-no-op-for-other-objects
	player:set_sky({
		type = "regular", -- Type of sky (plain, skybox, or regular)
		clouds = true,
		sky_color = {
			-- day_sky = "#b272f7",
			day_sky = "#14d9ae",
			day_horizon = "#f2b244",
		},
	})

	core.after(cfg.monster_spawn_delay, function()
		monster_spawn_timer(player)
	end)

	-- Show the main logo
	local bg_hud_id = player:hud_add({
		hud_elem_type = "image",
		position = { x = 0.5, y = 0.15 },
		offset = { x = 0, y = 0 },
		scale = { x = 8, y = 8 },
		alignment = { x = 0, y = 0 },
		text = "header.png",
	})
	core.after(5, function()
		if player and player:is_player() then
			player:hud_remove(bg_hud_id)
		end
	end)

	-- Reset fall damage
	mod_storage:set_float(player:get_player_name() .. "_rk:fall_dmg_mult", 1)

	-- Reset cloud spawning
	-- Must be re-init by player
	-- No other way to start vloud spawning again
	-- mod_storage:set_int(player:get_player_name() .. "_spawning_clouds", 0)

	-- If player was spawning clouds, start again
	if mod_storage:get_int(player:get_player_name() .. "_spawning_clouds") == 1 then
		spawn_clouds(player:get_player_name())
	end

	-- Check for and set end_game
	if mod_storage:get_int("end_game") == 1 then
		set_end_game()
		return
	end
	if mod_storage:get_int("game_over") == 1 then
		core.after(1, function()
			set_game_over(player)
		end)
		return
	end

	-- RETURNS if the player has already received a kit
	-- Check if the player has already received a kit
	if players_list[player:get_player_name()] then
		local formspec = [[
        size[8,6]
        label[0.5,0.5;OH NO!]
        textarea[0.5,1;7.5,4;intro_text;;Oh wait, it's you again!
I thought you were dead! 
Well, good luck out there.
        ]
        button_exit[3,5.5;2,1;exit;Start Playing]
        ]]
		core.show_formspec(player:get_player_name(), "game_intro:formspec", formspec)
		return
	end

	-- BELOW IS ONLY FOR NEW PLAYERS

	players_list[player:get_player_name()] = true
	mod_storage:set_string("players_list", core.serialize(players_list))

	-- Give the player a wyrm radar
	local inv = player:get_inventory()
	if inv then
		inv:add_item("main", "wyrm_cube:wyrm_radar")
		inv:add_item("main", "wyrm_cube:wyrm_guide")
		inv:add_item("main", "wyrm_cube:capsule_yurt")
		core.chat_send_player(player:get_player_name(), "You have received a wyrm Radar!")
	end
	core.after(5, function()
		supply_drops(player, cfg.supply_drop_amt)
	end)
	core.after(10, function()
		place_wyrm_cubes()
	end)

	-- Teleport the player high into the air
	local pos = player:get_pos()
	local new_position = { x = pos.x, y = 128, z = pos.z }
	player:set_pos(new_position)
	rk:no_dmg(player, 10) -- Disable damage for 5 seconds

	core.after(15, function()
		local formspec = string.format(
			[[
        size[8,6]
        label[0.5,0.5;OH NO!]
        textarea[0.5,1;7.5,4;intro_text;;%s]
        button_exit[3,5.5;2,1;exit;Start Playing]
        ]],
			txt.intro
		)
		core.show_formspec(player:get_player_name(), "game_intro:formspec", formspec)
	end)
end)

--
-- HP CHANGE HANDLER
--

core.register_on_player_hpchange(function(player, hp_change, reason)
	local player_name = player:get_player_name()
	local mult = mod_storage:get_float(player_name .. "_rk:fall_dmg_mult") or 1
	if mult == 0 then
		player:set_physics_override({
			fall_damage = false, -- Disables fall damage completely
		})
		log(player:get_player_name() .. " fall damage disabled")
	else
		player:set_physics_override({
			fall_damage = true,
		})
		log(player:get_player_name() .. " fall damage enabled")
	end
	if reason.type == "fall" then
		-- Check if the player has a specific privilege
		log("Fall Damage Mult: " .. mult)
		return hp_change * mult -- Apply fall damage multiplier
	end
	return hp_change -- Allow other types of damage
end, true)

--
-- SHUTDOWN HANDLER
--

-- Register server shutdown to ensure data is saved
core.register_on_shutdown(function()
	save_wyrm_cubes()
end)

--
-- INIT
--

log("Initializing Wyrm Cube mod")
load_saved_cubes()
