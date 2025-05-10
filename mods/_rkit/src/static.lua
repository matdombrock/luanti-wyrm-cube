-- Single Instance Stuff
local rk = Rkit:new("rkit_static")

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
