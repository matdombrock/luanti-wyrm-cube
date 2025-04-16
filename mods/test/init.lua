-- Register a globalstep function to increase player speed, jump, and sneak speed
-- minetest.register_globalstep(function(dtime)
--   for _, player in ipairs(minetest.get_connected_players()) do
--     local controls = player:get_player_control()
--     player:set_physics_override({
--       speed = 3,  -- Set player speed to 3 times the normal speed
--       jump = controls.sneak and 1 or 2,  -- Set player jump height to 1 if sneak key is held down, otherwise 2
--       sneak = true,  -- Enable sneaking
--       sneak_glitch = false,  -- Disable sneak glitching
--       sneak_speed = 5,  -- Set player sneak speed to 5 times the normal sneak speed
--     })
--   end
-- end)
--
-- -- Override fall damage to 25% of the normal fall damage
-- minetest.register_on_player_hpchange(function(player, hp_change, reason)
--   if reason.type == "fall" and hp_change < 0 then
--     return hp_change * 0.1
--   end
--   return hp_change
-- end, true)

minetest.register_chatcommand("teleport", {
  params = "",
  description = "Teleport to the location you are looking at",
  func = function(name)
    -- Get the player object
    local player = minetest.get_player_by_name(name)
    if player then
      -- Get the player's position and look direction
      local pos = player:get_pos()
      local look_dir = player:get_look_dir()

      -- Perform a raycast from the player's position in the look direction
      local ray = minetest.raycast(pos, vector.add(pos, vector.multiply(look_dir, 1000)), false, false)
      -- Iterate through the raycast result
      local count = 0
      for pointed_thing in ray do
	-- Log the pointed_thing type
	minetest.log(pointed_thing.type)
	if pointed_thing.type == "node" and count > 1 then
	  -- Adjust the target position slightly above the node to avoid clipping
	  local target_pos = vector.add(pointed_thing.above, {x = 0, y = 1.5, z = 0})
	  -- Teleport the player to the target position
	  player:set_pos(target_pos)
	  -- return true, "Teleported to the location you are looking at!"
	end
	count = count + 1
      end
      return false, "No suitable location found in the direction you are looking at!"
    else
      return false, "Player not found!"
    end
  end,
})

minetest.register_chatcommand("hidro", {
  params = "",
  description = "Gives the player 99 biofuel and 1 hidroplane",
  func = function(name)
    local player = minetest.get_player_by_name(name)
    if player then
      local inv = player:get_inventory()
      inv:add_item("main", "airutils:biofuel 99")
      inv:add_item("main", "hidroplane:hidro 1")
      return true, "You have been given 99 biofuel and 1 hidroplane."
    else
      return false, "Player not found."
    end
  end,
})

minetest.register_chatcommand("doom_move", {
  params = "",
  description = "DOOM Movement",
  func = function(name)
    -- Register a globalstep function to increase player speed, jump, and sneak speed
    minetest.register_globalstep(function(dtime)
      for _, player in ipairs(minetest.get_connected_players()) do
	local controls = player:get_player_control()
	player:set_physics_override({
	  speed = 3,  -- Set player speed to 3 times the normal speed
	  jump = controls.sneak and 1 or 2,  -- Set player jump height to 1 if sneak key is held down, otherwise 2
	  sneak = true,  -- Enable sneaking
	  sneak_glitch = false,  -- Disable sneak glitching
	  sneak_speed = 5,  -- Set player sneak speed to 5 times the normal sneak speed
	})
      end
    end)

    -- Override fall damage to 25% of the normal fall damage
    minetest.register_on_player_hpchange(function(player, hp_change, reason)
      if reason.type == "fall" and hp_change < 0 then
	return hp_change * 0.1
      end
      return hp_change
    end, true)

  end,
})
