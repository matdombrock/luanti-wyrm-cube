function split_cmd(input)
    local result = {}
    for word in string.gmatch(input, "%S+") do
        table.insert(result, word)
    end
    return result
end

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

minetest.register_on_joinplayer(function(player)
  local player_name = player:get_player_name()
  minetest.log("action", player_name .. " has joined the game!")
  local formspec = [[
  size[8,6]
  label[0.5,0.5;Welcome!]
  textarea[0.5,1;7.5,4;intro_text;;Welcome to Luanti!

  Here are some tips to get started:
  1. Gather resources to build your base.
  2. Avoid dangerous mobs at night.
  3. Explore the world to find hidden treasures.
  4. This is NOT MINECRAFT, so don't expect the same gameplay.

  Have fun and enjoy playing!]
  button_exit[3,5.5;2,1;exit;Start Playing]
  ]]
  -- minetest.show_formspec(player_name, "game_intro:formspec", formspec)
  -- Your custom logic here
end)

local function hidro(name)
  local player = minetest.get_player_by_name(name)
  if player then
    local inv = player:get_inventory()
    inv:add_item("main", "biofuel:fuel_can 99")
    inv:add_item("main", "hidroplane:hidro 1")
    return true, "You have been given 99 biofuel and 1 hidroplane."
  else
    return false, "Player not found."
  end
end

minetest.register_chatcommand("hidro", {
  params = "",
  description = "Gives the player 99 biofuel and 1 hidroplane",
  func = hidro,
})

local function fall_dmg(mult)
  minetest.register_on_player_hpchange(function(player, hp_change, reason)
    if reason.type == "fall" then
        -- Check if the player has a specific privilege
	if (mult == 0) then
	  player:set_physics_override({
	    fall_damage = false -- Disables fall damage completely
	  })
	end
	return hp_change * mult -- Apply fall damage multiplier
    end
    return hp_change -- Allow other types of damage
  end, true)
end


local move_speeds = {
  normal = { speed = 1, jump = 1, sneak = 1, fall = 1 },
  runner = { speed = 2, jump = 1.5, sneak = 1, fall = 1 },
  doom = { speed = 3, jump = 2, sneak = 5, fall = 0.1 },
  hyper = { speed = 16, jump = 8, sneak = 5, fall = 0 },
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
	  speed = move.speed,  -- Set player speed to 3 times the normal speed
	  jump = controls.sneak and 1 or move.jump,  -- Set player jump height to 1 if sneak key is held down, otherwise 2
	  sneak = true,  -- Enable sneaking
	  sneak_glitch = false,  -- Disable sneak glitching
	  sneak_speed = move.sneak,  -- Set player sneak speed to 5 times the normal sneak speed
	})
      end
    end)
    -- Override fall damage 
    fall_dmg(move.fall)
    return true, "Movement set to " .. param .. "."
  end,
})



minetest.register_chatcommand("ts", {
    params = "<dawn|noon|sunset|midnight> <speed?>",
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
    privs = {server = true},
    func = function(name, param)
        -- Ensure a value is provided
        if param == "" then
            return false, "Usage: /tpd <speed>"
        end

        -- Convert the parameter to a number
        local speed = tonumber(param)
        -- if not speed or speed <= 0 then
        --     return false, "Invalid time speed. Time speed must be a positive number."
        -- end

        -- Set the time speed
        minetest.setting_set("time_speed", speed)
        minetest.chat_send_all("Time speed has been set to " .. speed .. " by " .. name)

        return true, "Time speed set to " .. speed .. "."
    end,
})


minetest.register_chatcommand("lsent", {
    params = "<search>",
    description = "List all registered entities. Optionally provide a search term to filter results.",
    privs = {server = true},
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
    privs = {server = true},
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

local function no_dmg(player, seconds)
  -- Disable all damage for 5 seconds
  seconds = seconds or 5
  player:set_hp(player:get_hp()) -- Ensure current HP is preserved
  player:set_armor_groups({immortal = 1})
  minetest.chat_send_player(player.get_player_name(player), "Damage disabled for " .. seconds .. " seconds.")

  -- Re-enable damage after 5 seconds
  minetest.after(seconds, function()
      if player:is_player() then
          player:set_armor_groups({immortal = 0}) -- Restore default armor groups
          minetest.chat_send_player(player.get_player_name(player), "Damage enabled again.")
      end
  end)
end

minetest.register_chatcommand("tp", {
    params = "<x> <y> <z>",
    description = "Teleport the player to the specified position (x, y, z).",
    privs = {teleport = true},
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
        local new_position = {x = x, y = y, z = z}
        player:set_pos(new_position)

	no_dmg(player, 5) -- Disable damage for 5 seconds

        return true, "Teleported to position: " .. minetest.pos_to_string(new_position)
    end,
})

minetest.register_chatcommand("tpr", {
    params = "<range>",
    description = "Teleport the player to a random location within the specified range and disable damage for 5 seconds.",
    privs = {teleport = true},
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
        local random_y = math.random(5, 100) -- Keep Y between 5 and 100 for safety
        local random_z = math.random(-range, range)

        -- Set the new position
        local new_position = {x = random_x, y = random_y, z = random_z}
        player:set_pos(new_position)

        no_dmg(player, 5) -- Disable damage for 5 seconds

        return true, "Teleported to random location: " .. minetest.pos_to_string(new_position)
    end,
})

minetest.register_chatcommand("clear_inventory", {
    description = "Clear the player's inventory.",
    privs = {server = true},
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
    privs = {server = true},
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

        return true, "Spawned entity '" .. entity .. "' at relative position (" .. dx .. ", " .. dy .. ", " .. dz .. ")."
    end,
})


local target_pos = {x = 100, y = 20, z = 100}

-- Register the chat command
minetest.register_chatcommand("arrow", {
    params = "<length>",
    description = "Draws an arrow pointing to a static world location",
    privs = {server = true},  -- Only allow players with the 'server' privilege to use this command
    func = function(name, param)
        -- Parse the arrow length from the command parameter
        local length = tonumber(param) or 10
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, "Player not found!"
        end

        -- Get the player's current position
        local player_pos = player:get_pos()

        -- Calculate the direction vector to the target position
        local direction = vector.subtract(target_pos, player_pos)
        local direction_normalized = vector.normalize(direction)
        -- Draw the arrow using particles
        for i = 1, length do
            local particle_pos = vector.add(player_pos, vector.multiply(direction_normalized, i))
            minetest.add_particle({
                pos = particle_pos,
                velocity = {x = 0, y = 0, z = 0},
                acceleration = {x = 0, y = 0, z = 0},
                expirationtime = 5,
                size = 4,
                texture = "arrow_particle.png", -- Provide your own arrow particle texture
                glow = 10,
            })
        end

        return true, "Arrow drawn pointing to the target position!"
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

local function start_kit(name)
  local player = minetest.get_player_by_name(name)
  if player then
    local inv = player:get_inventory()
    inv:add_item("main", "default:sword_steel 1")
    inv:add_item("main", "3d_armor:boots_steel 1")
    inv:add_item("main", "3d_armor:chestplate_steel 1")
    inv:add_item("main", "3d_armor:helmet_steel 1")
    inv:add_item("main", "shields:shield_steel 1")
    inv:add_item("main", "default:torch 32")
    inv:add_item("main", "default:pick_steel 1")
    inv:add_item("main", "default:axe_steel 1")
    inv:add_item("main", "default:shovel_steel 1")
    inv:add_item("main", "farming:hoe_steel 1")
    inv:add_item("main", "farming:bread 32")
    inv:add_item("main", "default:apple 32")
    inv:add_item("main", "default:tree 64") -- Wood (raw) block
    inv:add_item("main", "default:tree 64") -- Wood (raw) block
    inv:add_item("main", "default:stone 64")
    inv:add_item("main", "beds:bed_bottom 1")
    inv:add_item("main", "animalia:saddle 1")
    inv:add_item("main", "animalia:spawn_horse 1")
    inv:add_item("main", "animalia:libri_animalia 1")
    inv:add_item("main", "leads:lead 8")
    inv:add_item("main", "bucket:bucket_water 8")
    inv:add_item("main", "default:chest 8")
    inv:add_item("main", "binoculars:binoculars 1")
    inv:add_item("main", "goodtorch:flashlight_off 1")
    inv:add_item("main", "x_bows:bow_wood 1")
    inv:add_item("main", "x_bows:arrow_wood 99")
    inv:add_item("main", "grapple:grapple 1")
    inv:add_item("main", "hangglider:hangglider 1")
    inv:add_item("main", "farming:hemp_rope 198")
    return true, "You have been given a start kit."
  else
    return false, "Player not found."
  end
end

minetest.register_chatcommand("start_kit", {
    params = "",
    description = "Gives the player a start kit",
    func = start_kit,
})
