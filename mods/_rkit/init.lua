Rkit = {}
Rkit.__index = Rkit

-- Constructor
function Rkit:new(mod_name)
	local instance = setmetatable({}, Rkit) -- Create a new table and attach the metatable
	instance.mod_name = mod_name or "unknown_mod"
	instance.enable_logging = true
	Rkit.player_state = { -- Static
		"null" == {
			fall_dmg = 1,
		},
	}
	return instance
end

-- Print a basic message to the console
function Rkit:log(message)
	if not self.enable_logging then
		return
	end
	core.log("[" .. self.mod_name .. "] " .. message)
end
-- Toggle logging
function Rkit:enable_log(enabled)
	self.enable_logging = enabled
end

-- Splits a spece delimited string into a table
-- Defaults to space if no delimiter is provided
function Rkit:string_split(str, delimiter)
	local result = {}
	delimiter = delimiter or "%s+" -- Default to space if no delimiter is provided
	for match in str:gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	-- Add the final segment if it doesn't end with the delimiter
	local last_match = str:match(".*" .. delimiter .. "(.*)$")
	if last_match and last_match ~= "" then
		table.insert(result, last_match)
	end
	return result
end

function array_reverse(array)
	local reversed = {}
	for i = #array, 1, -1 do
		table.insert(reversed, array[i])
	end
	return reversed
end

-- Returns true if the string contains the substring
function Rkit:string_includes(str, substring)
	return string.find(str, substring, 1, true) ~= nil
end

-- Sets player immunity with an optional timeout
-- This does not use the damage handler
function Rkit:no_dmg(player, seconds)
	player:set_hp(player:get_hp()) -- Ensure current HP is preserved
	player:set_armor_groups({ immortal = 1 })
	core.chat_send_player(player.get_player_name(player), "Damage disabled for " .. seconds .. " seconds.")
	if not seconds then
		return true
	end
	-- Re-enable damage after N seconds
	core.after(seconds, function()
		if player:is_player() then
			player:set_armor_groups({ immortal = 0 }) -- Restore default armor groups
			core.chat_send_player(player.get_player_name(player), "Damage enabled again.")
		end
	end)
	return true
end

-- Sets fall damage multiplier with an optional timeout
-- There is only one damage handler shared between all instances of Rkit
function Rkit:fall_dmg(player, mult, seconds)
	local player_name = player:get_player_name()
	Rkit.player_state[player_name].fall_damage = mult
	if not seconds then
		return true
	end
	-- Re-enable fall damage after N seconds
	core.after(seconds, function()
		if player:is_player() then
			Rkit.player_state[player_name].fall_damage = 1 -- Restore default fall damage
			core.chat_send_player(player_name, "Fall damage enabled again.")
		end
	end)
end

-- Percent chance
function Rkit:pchance(percent)
	return math.random(0.0, 100.0) <= percent
end

-- Write a simple message to the HUD
function Rkit:hud_msg(user, text, seconds)
	local bg_hud_id = user:hud_add({
		hud_elem_type = "image",
		position = { x = 0.5, y = 0.1 },
		offset = { x = 0, y = 0 },
		scale = { x = 850, y = 150 },
		alignment = { x = 0, y = 0 },
		text = "ui_bg.png",
	})
	-- Add HUD text
	local hud_id = user:hud_add({
		hud_elem_type = "text",
		position = { x = 0.5, y = 0.1 },
		offset = { x = 0, y = 0 },
		text = text,
		alignment = { x = 0, y = 0 },
		scale = { x = 100, y = 100 },
		size = { x = 2, y = 0 },
		style = 1,
		number = 0xFFFF99,
	})
	core.after(seconds or 3, function()
		if user and user:is_player() then
			user:hud_remove(hud_id)
			user:hud_remove(bg_hud_id)
		end
	end)
end

-- Simple particle ont-shot at a poistion (rainbow colors)
function Rkit:spawn_particles(pos, image_path, color_str, max_vel)
	image_path = image_path or "default_particle.png"
	color_str = color_str or "#FF0000"
	max_vel = max_vel or 3.0
	for i = 1, 128 do
		core.add_particle({
			pos = pos,
			velocity = { x = math.random(-max_vel, max_vel), y = 0, z = math.random(-max_vel, max_vel) },
			acceleration = { x = 0, y = 0.15 + math.random(), z = 0 },
			expirationtime = 10,
			size = 3,
			texture = image_path .. ".png^[colorize:" .. color_str .. ":127",
			glow = 10,
		})
	end
end

-- Simple particle ont-shot at a poistion (rainbow colors)
function Rkit:spawn_particles_rainbow(pos, image_path, max_vel)
	image_path = image_path or "default_particle.png"
	max_vel = max_vel or 3.0
	for i = 1, 128 do
		local color_str = string.format("#%06x", math.random(0, 0xFFFFFF))
		core.add_particle({
			pos = pos,
			velocity = { x = math.random(-max_vel, max_vel), y = 0, z = math.random(-max_vel, max_vel) },
			acceleration = { x = 0, y = 0.15 + math.random(), z = 0 },
			expirationtime = 10,
			size = 3,
			texture = image_path .. ".png^[colorize:" .. color_str .. ":127",
			glow = 10,
		})
	end
end

core.register_node("_rkit:scaffold", {
	description = "Scaffolding",
	tiles = { "scaffold.png" },
	is_ground_content = false,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	drawtype = "glasslike", -- Allows transparency and gives a glass-like appearance
})
function Rkit:contruction(origin, bom, bp, callback, opt)
	opt.speed = opt.speed or 1.0 -- How fast to build
	opt.force_build = opt.force_build or true -- Overwrite non-air blocks
	opt.pre_clear = opt.pre_clear or true -- Place air blocks before building (does not emerge)
	opt.auto_emerge = opt.auto_emerge or true -- Automatically emerge the area before building
	opt.build_order = opt.build_order or "blocks" -- (blocks, layers, random, instant)
	opt.scaffold = opt.scaffold or true -- Place scaffolding before building
	opt.scaffold_block = opt.scaffold_block or "_rkit:scaffold" -- Block to use for scaffolding
	opt.rotate = opt.rotate or 0 -- Rotate the construction (45 degree increments)

	if type(bp) ~= "table" then
		error("Expected 'bp' to be a table, got " .. type(bp))
	end

	-- Rotate construction layer 90 degrees clockwise
	local function rotate_construction_layer(input)
		local lines = {}
		for line in input:gmatch("[^\n]+") do
			table.insert(lines, line)
		end

		local rotated = {}
		local num_rows = #lines
		local num_cols = #lines[1]:gsub(" ", "") -- Count non-space characters

		for col = 1, num_cols do
			local new_row = {}
			for row = num_rows, 1, -1 do
				table.insert(new_row, lines[row]:sub(col * 2 - 1, col * 2 - 1)) -- Extract character
			end
			table.insert(rotated, table.concat(new_row, " "))
		end

		return table.concat(rotated, "\n")
	end

	-- Init build record
	local build_record = {}
	for key, _ in pairs(bom) do
		build_record[key] = {}
	end

	local pending = 0
	local place_node = function(pos, block)
		local ctx = { block = block }
		local emerge_cb = function(pos_target, action, num_calls_remaining, context)
			core.set_node(pos, context.block)
			pending = pending - 1
			if (pending == 0) and callback then
				callback(build_record)
			end
		end
		if opt.auto_emerge then
			core.emerge_area(pos, pos, emerge_cb, ctx)
		else
			core.set_node(pos, block)
			pending = pending - 1
			if (pending == 0) and callback then
				callback(build_record)
			end
		end
	end

	local default_block = { name = "default:stone" }
	local height = #bp

	-- Construction loop
	for y, layer in ipairs(bp) do
		for _ = 1, opt.rotate do
			layer = rotate_construction_layer(layer)
		end
		local split_rows = Rkit:string_split(layer, "\n")
		local width = #split_rows
		for x, row in ipairs(split_rows) do
			local split_vals = Rkit:string_split(row)
			local length = #split_vals
			local layer_area = width * length
			for z, value in ipairs(split_vals) do
				local block = bom[value] or default_block
				if block.param2 then
					block.param2 = (block.param2 + opt.rotate) % 4
				end
				local b_pos = { x = origin.x + x, y = origin.y + y, z = origin.z + z }
				local current_node = core.get_node(b_pos)
				if not opt.force_build and current_node.name ~= "air" then
					core.log("Skipping " .. b_pos.x .. "," .. b_pos.y .. "," .. b_pos.z .. " - Not air")
					goto continue
				end
				local delay = (y * layer_area + (x * z)) / (layer_area * opt.speed) -- Blocks
				if opt.build_order == "layers" then
					delay = (y * layer_area) / (layer_area * opt.speed)
				end
				if opt.build_order == "random" then
					delay = math.random((height * layer_area) + (width * length)) / (layer_area * opt.speed)
				end
				if opt.build_order == "instant" then
					delay = 0
				end
				if build_record[value] == nil then
					-- build_record[value] = {}
					error("Invalid block type: " .. value)
				end
				table.insert(build_record[value], b_pos)
				pending = pending + 1
				if opt.pre_clear then
					core.set_node(b_pos, { name = "air" })
				end
				core.after(delay, function()
					if opt.scaffold then
						core.set_node(b_pos, { name = opt.scaffold_block })
						core.after(delay, function()
							place_node(b_pos, block)
						end)
						return
					end
					place_node(b_pos, block)
				end)
			end
		end
		::continue::
	end
end

-- Single Instance Stuff
local rk = Rkit:new("rkit_single")

core.register_on_player_hpchange(function(player, hp_change, reason)
	local player_name = player:get_player_name()
	local mult = 1
	if Rkit.player_state[player_name] then -- Static
		mult = Rkit.player_state[player_name].fall_damage
	end
	if reason.type == "fall" then
		-- Check if the player has a specific privilege
		rk:log("Fall Damage Mult: " .. mult)
		return hp_change * mult -- Apply fall damage multiplier
	end
	return hp_change -- Allow other types of damage
end, true)
