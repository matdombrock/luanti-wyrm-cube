Rkit = {}
Rkit.__index = Rkit

-- Constructor
function Rkit:new(mod_name)
	local instance = setmetatable({}, Rkit) -- Create a new table and attach the metatable
	instance.mod_name = mod_name or "unknown_mod"
	instance.enable_logging = true
  Rkit.player_state = {
    "null" = {
      fall_dmg = 1
    }
  }
	return instance
end

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

function Rkit:string_includes(str, substring)
	return string.find(str, substring, 1, true) ~= nil
end

-- Sets player immunity with an optional timeout
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
function Rkit:fall_dmg(player, mult, seconds)
  local player_name = player:get_player_name()
  self.player_state[player_name].fall_damage = mult
  if not seconds then
    return true
  end
  -- Re-enable fall damage after N seconds
  core.after(seconds, function()
    if player:is_player() then
      self.player_state[player_name].fall_damage = 1 -- Restore default fall damage
      core.chat_send_player(player_name, "Fall damage enabled again.")
    end
  end)
end

-- Percent chance
function Rkit:pchance(percent)
	return math.random(0.0, 100.0) <= percent
end

-- Single Instance Stuff
local rk = Rkit:new("rkit_single")

core.register_on_player_hpchange(function(player, hp_change, reason)
	local player_name = player:get_player_name()
	local mult = Rkit.player_state[player_name].fall_damage or 1
	if reason.type == "fall" then
	  -- Check if the player has a specific privilege
	  rk:log("Fall Damage Mult: " .. mult)
	  return hp_change * mult -- Apply fall damage multiplier
	end
	return hp_change -- Allow other types of damage
end, true)
