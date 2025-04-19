Rkit = {}

Rkit.split_cmd = function(input)
	local result = {}
	for word in string.gmatch(input, "%S+") do
		table.insert(result, word)
	end
	return result
end

-- Sets player immunity with an optional timeout
Rkit.no_dmg = function(player, seconds)
	player:set_hp(player:get_hp()) -- Ensure current HP is preserved
	player:set_armor_groups({ immortal = 1 })
	minetest.chat_send_player(player.get_player_name(player), "Damage disabled for " .. seconds .. " seconds.")

	if not seconds then
		return true
	end
	-- Re-enable damage after 5 seconds
	minetest.after(seconds, function()
		if player:is_player() then
			player:set_armor_groups({ immortal = 0 }) -- Restore default armor groups
			minetest.chat_send_player(player.get_player_name(player), "Damage enabled again.")
		end
	end)
	return true
end

-- Percent chance
Rkit.pchance = function(percent)
	return math.random(0.0, 100.0) <= percent
end
