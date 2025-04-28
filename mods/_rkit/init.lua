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
function Rkit:string_split(str)
	local result = {}
	for word in string.gmatch(str, "%S+") do
		table.insert(result, word)
	end
	return result
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
	for i = 1, math.random(1, 128) do
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
	for i = 1, math.random(1, 128) do
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
