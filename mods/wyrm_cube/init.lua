local path = minetest.get_modpath(minetest.get_current_modname())
dofile(path .. "/guide.lua")
-- Wyrm Cubes Mod for Minetest
-- CONFIG
local cube_count = 7 -- Number of wyrm cubes to place
local max_cube_dist = 10000 -- Maximum distance from the spawn point to place wyrm cubes
local monster_spawn_amt = 32 -- Probability of spawning a monster when radar is used
local monster_spawn_time = 30 -- Time between random monster spawns
local monster_spawn_delay = 60 * 3 -- Time before starting random monster spawns
local supply_drop_range = 16 -- Will be double this number.
local enable_logging = true -- Enable or disable logging

-- Persistent mod storage
local mod_storage = minetest.get_mod_storage()
local players_list = mod_storage:get_string("players_list")
-- Store wyrm cube positions as a single serialized table
local wyrm_cubes = {}

-- 
-- LOGGING FUNCTION
--

local function log(message)
    if not enable_logging then
        return
    end
    minetest.log("[Wyrm Cube] " .. message)
end

--
-- EMERGE AREA CALLBACK
--
local function emerge_callback(pos, action, num_calls_remaining, context)
    -- On first call, record number of blocks
    if not context.total_blocks then
        context.total_blocks  = num_calls_remaining + 1
        context.loaded_blocks = 0
    end

    -- Increment number of blocks loaded
    context.loaded_blocks = context.loaded_blocks + 1

    -- Send progress message
    if context.total_blocks ~= context.loaded_blocks then
        local perc = 100 * context.loaded_blocks / context.total_blocks
        local msg  = string.format("Loading blocks %d/%d (%.2f%%)",
        context.loaded_blocks, context.total_blocks, perc)
        log(msg)
    end
    log("Emerge callback called for position: " .. minetest.pos_to_string(context.pos))

    if #wyrm_cubes >= cube_count then
        log("Already placed " .. #wyrm_cubes .. " wyrm cubes, stopping placement")
        return
    end
    local node = minetest.get_node(context.pos)
    local below = minetest.get_node(context.pos_below)
    if node.name == "ignore" then
        log("Node is ignore, not placing wyrm cube at " .. minetest.pos_to_string(context.pos))
        return
    end
    if node.name == "air" then
        local checks = 0
        while checks < 64 and (below.name == "air" or below.name == "ignore") do
            context.pos.y = context.pos.y - 1
            context.pos_below.y = context.pos_below.y - 1
            below = minetest.get_node(context.pos_below)
            checks = checks + 1
        end
        if checks < 64 then
            -- Successfully found a solid block below
            minetest.set_node(context.pos, {name = "wyrm_cube:wyrm_cube"})
            table.insert(wyrm_cubes, context.pos)
            log("Placed wyrm cube at " .. minetest.pos_to_string(context.pos))
            log("Node name: " .. node.name .. ", Below node name: " .. below.name)
        end
    end
end

--
-- UTILITY FUNCTIONS
--

-- Percent chance
local function pchance(percent)
    return math.random(0.0, 100.0) <= percent
end

-- Returns true if the string contains the substring
function string_includes(str, substring)
    return string.find(str, substring, 1, true) ~= nil
end

-- Write a message to the HUD
local function hud_msg(user, text, seconds)
    local bg_hud_id = user:hud_add({
        hud_elem_type = "image",
        position = {x = 0.5, y = 0.1}, -- Centered at the top of the screen
        offset = {x = 0, y = 0},
        scale = {x = 850, y = 150}, -- Adjust scale for the size of the block
        alignment = {x = 0, y = 0},
        text = "ui_bg.png", -- A black texture (you need to include this in your mod)
    })
    -- Add HUD text
    local hud_id = user:hud_add({
        hud_elem_type = "text", -- HUD element type
        position = {x = 0.5, y = 0.1}, -- Centered at the top of the screen
        offset = {x = 0, y = 0}, -- No additional offset
        text = text, -- The text to display
        alignment = {x = 0, y = 0}, -- Center alignment
        scale = {x = 100, y = 100}, -- Scale for larger text
        size = {x = 2, y = 0}, -- No size limit
        style = 1, -- Style for the text
        number = 0xFFFF99, --  color in hexadecimal (RGB)
    })
    minetest.after(seconds or 3, function()
        if user and user:is_player() then
            user:hud_remove(hud_id)
            user:hud_remove(bg_hud_id)
        end
    end)
end

local function spawn_particles(pos)
    for i = 1, math.random(1, 128) do
        local color_str = string.format("#%06x", math.random(0, 0xFFFFFF))
        minetest.add_particle({
            pos = pos,
            velocity = {x = math.random(-3.0, 3.0), y = 0, z = math.random(-3.0, 3.0)},
            acceleration = {x = 0, y = 0.1 + math.random(), z = 0},
            expirationtime = 10, -- Duration of the particle
            size = 3, -- Increase for better visibility
            texture = "wyrm_line_particle.png^[colorize:" .. color_str .. ":127",
            glow = 10, -- Add glow for visibility in the dark
        }) 
    end
    minetest.sound_play("woosh", {
        pos = pos,
        max_hear_distance = 128,
        gain = 0.6,
        loop = false,
    })
end

local function spawn_particles_bad(pos)
    for i = 1, math.random(1, 128) do
        local color_str = "#FF0000" -- Red color for bad particles
        minetest.add_particle({
            pos = pos,
            velocity = {x = math.random(-3.0, 3.0), y = 0, z = math.random(-3.0, 3.0)},
            acceleration = {x = 0, y = 0.1 + math.random(), z = 0},
            expirationtime = 10, -- Duration of the particle
            size = 3, -- Increase for better visibility
            texture = "wyrm_line_particle.png^[colorize:" .. color_str .. ":127",
            glow = 10, -- Add glow for visibility in the dark
        }) 
    end
    minetest.sound_play("bad_spawn", {
        pos = pos,
        max_hear_distance = 128,
        gain = 0.1,
        loop = false,
    })
end

local function spawn_monster(name)
    -- Get the player's position
    local player = minetest.get_player_by_name(name)
    if not player then
        return false, "Player not found!"
    end

    local pos = player:get_pos()

    -- Generate a random position around the player
    local random_offset = {
        x = math.random(8, 24), -- Random offset between -10 and 10 blocks
        y = math.random(-8, 8),  -- Random offset vertically (to avoid spawning too high/low)
        z = math.random(8, 24)
    }
    random_offset.x = random_offset.x * (math.random(0, 1) == 0 and -1 or 1)
    random_offset.z = random_offset.z * (math.random(0, 1) == 0 and -1 or 1)

    local spawn_pos = vector.add(pos, random_offset)

    -- Check if the position is suitable for spawning the slime (air and not inside a solid block)
    local node_at_spawn = minetest.get_node(spawn_pos).name
    local node_below = minetest.get_node({x = spawn_pos.x, y = spawn_pos.y - 1, z = spawn_pos.z}).name
    local node_above = minetest.get_node({x = spawn_pos.x, y = spawn_pos.y + 1, z = spawn_pos.z}).name
    if node_at_spawn == "air" and node_above == "air" and node_below ~= "air" and node_below ~= "default:water_source" then
        -- Spawn the slime entity
        local entity = minetest.add_entity(spawn_pos, "mobs:oerkki")
        spawn_particles_bad(spawn_pos)
        if entity then
            return true, "Monster spawned at " .. minetest.pos_to_string(spawn_pos)
        else
            return false, "Failed to spawn monster!"
        end
    else
        return false, "Invalid spawn location: " .. node_at_spawn
    end
end

local function monster_spawn_timer(player)
    -- Check if the player is still online
    if minetest.get_player_by_name(player:get_player_name()) then
        for i = 1, monster_spawn_amt do
            minetest.after(i / 2, function()
                spawn_monster(player:get_player_name())
            end)
        end
        -- Schedule the next spawn
        minetest.after(monster_spawn_time, function()
            monster_spawn_timer(player)
        end)
    end
end

local function no_dmg(player, seconds)
    -- Disable all damage for 5 seconds
    seconds = seconds or 5
    player:set_hp(player:get_hp()) -- Ensure current HP is preserved
    player:set_armor_groups({immortal = 1})
    log(player.get_player_name(player) .. " Damage disabled for " .. seconds .. " seconds.")

    -- Re-enable damage after 5 seconds
    minetest.after(seconds, function()
        if player:is_player() then
            player:set_armor_groups({immortal = 0}) -- Restore default armor groups
            log(player.get_player_name(player) .. " Damage enabled again.")
        end
    end)
end

local move_speeds = {
  normal = { speed = 1, jump = 1, sneak = 1, fall = 1, gravity = 1},
  runner = { speed = 2, jump = 1.5, sneak = 1, fall = 1, gravity = 1},
  doom = { speed = 3, jump = 2, sneak = 5, fall = 0.1, gravity = 1},
  hyper = { speed = 16, jump = 8, sneak = 5, fall = 0, gravity = 1},
  moon = { speed = 1, jump = 1, sneak = 1, fall = 1, gravity = 0.1654},
  mars = { speed = 1, jump = 1, sneak = 1, fall = 1, gravity = 0.38},
  low_orbit = { speed = 1, jump = 1, sneak = 1, fall = 1, gravity = 0.01},
  rabbit = { speed = 1, jump = 3, sneak = 1, fall = 1, gravity = 1},
}
local function set_move(player, move)
   for _, playerx in ipairs(minetest.get_connected_players()) do
       if playerx.name ~= player.name then goto continue end
       local controls = playerx:get_player_control()
       playerx:set_physics_override({
           speed = move.speed,  -- Set player speed
           jump = controls.sneak and 1 or move.jump,  -- Set player jump height to 1 if sneak key is held doen
           sneak = true,  -- Enable sneaking
           sneak_glitch = false,  -- Disable sneak glitching
           sneak_speed = move.sneak,  -- Set player sneak speed
           gravity = move.gravity,  -- Set player gravity 
       })
       -- fall_dmg(move.fall)
       local player_name = playerx:get_player_name()
       mod_storage:set_float(player_name .. "_fall_dmg_mult", move.fall)
       log(player .. " movement changed" .. move.fall)
       ::continue::
   end
end

-- Draw a GUI element telling the player the potion will expire
local function warn_potion(user, potion_name, seconds)
    local bg_hud_id = user:hud_add({
        hud_elem_type = "image",
        position = {x = 0.5, y = 0.1}, -- Centered at the top of the screen
        offset = {x = 0, y = 0},
        scale = {x = 650, y = 150}, -- Adjust scale for the size of the block
        alignment = {x = 0, y = 0},
        text = "ui_bg.png", -- A black texture (you need to include this in your mod)
    })
    -- Add HUD text
    local hud_id = user:hud_add({
        hud_elem_type = "text", -- HUD element type
        position = {x = 0.5, y = 0.1}, -- Centered at the top of the screen
        offset = {x = 0, y = 0}, -- No additional offset
        text = 'POTION:\n' .. potion_name .. " (" .. seconds .. "s)", -- The text to display
        alignment = {x = 0, y = 0}, -- Center alignment
        scale = {x = 100, y = 100}, -- Scale for larger text
        size = {x = 2, y = 0}, -- No size limit
        style = 1, -- Style for the text
        number = 0xFFFF99, --  color in hexadecimal (RGB)
    })
    minetest.after(3, function()
        if user and user:is_player() then
            user:hud_remove(hud_id)
            user:hud_remove(bg_hud_id)
        end
    end)
    minetest.after(seconds - 3, function()
        local bg_hud_id2 = user:hud_add({
            hud_elem_type = "image",
            position = {x = 0.5, y = 0.1}, -- Centered at the top of the screen
            offset = {x = 0, y = 0},
            scale = {x = 650, y = 150}, -- Adjust scale for the size of the block
            alignment = {x = 0, y = 0},
            text = "ui_bg.png", -- A black texture (you need to include this in your mod)
        })
        -- Add HUD text
        local hud_id2 = user:hud_add({
            hud_elem_type = "text", -- HUD element type
            position = {x = 0.5, y = 0.1}, -- Centered at the top of the screen
            offset = {x = 0, y = 0}, -- No additional offset
            text = 'POTION WEARING OFF:\n' .. potion_name, -- The text to display
            alignment = {x = 0, y = 0}, -- Center alignment
            scale = {x = 100, y = 100}, -- Scale for larger text
            size = {x = 2, y = 0}, -- No size limit
            style = 1, -- Style for the text
            number = 0xFFFF99, --  color in hexadecimal (RGB)
        })
        minetest.after(3, function()
            if user and user:is_player() then
                user:hud_remove(hud_id2)
                user:hud_remove(bg_hud_id2)
            end
        end)
    end)
end

-- Function to place a wyrm cube at a valid surface position
local function place_wyrm_cube(pos)
    if #wyrm_cubes >= cube_count then
        log("Already placed " .. #wyrm_cubes .. " wyrm cubes, stopping placement")
        return
    end

    local pos_below = {x = pos.x, y = pos.y - 1, z = pos.z}


    local context = {pos = pos, pos_below = pos_below} -- persist data between callback calls
    minetest.emerge_area(pos_below, pos, emerge_callback, context)
end

-- Function to randomly place wyrm cubes in areas after world generation
local function place_wyrm_cubes()
    local remaining = cube_count - #wyrm_cubes
    if remaining <= 0 then
        log("All wyrm cubes already placed")
        return
    end
    log("Attempting placement of " .. remaining .." wyrm cubes")
    -- for i = 1, remaining do
    local pos = {
        x = math.random(-max_cube_dist, max_cube_dist),
        y = math.random(5, 50), -- Adjust Y range as needed
        z = math.random(-max_cube_dist, max_cube_dist),
    }
    place_wyrm_cube(pos)
    -- wait for 1 second
    minetest.after(0.5, function()
        if #wyrm_cubes < cube_count then
            place_wyrm_cubes()
        end
    end)
end

-- Load saved wyrm cube positions from storage
local function load_saved_cubes()
    log("Loading saved wyrm cube positions from storage")
    local saved_data = mod_storage:get_string("wyrm_cubes")
    if saved_data and saved_data ~= "" then
        local data = minetest.deserialize(saved_data)
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
    mod_storage:set_string("wyrm_cubes", minetest.serialize(wyrm_cubes))
    log("Saved " .. #wyrm_cubes .. " wyrm cubes to storage")
end

local function supply_drop(name)
    -- Get the player's position
    local player = minetest.get_player_by_name(name)
    if not player then
        log("Player not found: " .. name)
        return false, "Player not found!"
    end

    local pos = player:get_pos()
    local dist_x = supply_drop_range
    dist_x = dist_x + math.random(0, dist_x)
    local dist_z = supply_drop_range
    dist_z = dist_z + math.random(0, dist_z)
    if pchance(50) then
        dist_x = -dist_x
    end
    if pchance(50) then
        dist_z = -dist_z
    end
    local dir = {x = dist_x, y = 48, z = dist_z}

    -- Try to place the chest in a random adjacent location
    local chest_pos = vector.add(pos, dir)
    -- Place the chest
    local cur_node = minetest.get_node(chest_pos)
    if cur_node.name ~= "air" then
        log("No suitable location to place the supply drop for player: " .. name)
        -- Try again
        minetest.after(1, function()
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
    log("Placing supply drop at " .. minetest.pos_to_string(chest_pos) .. " for player: " .. name)
    minetest.set_node(chest_pos, {name = "wyrm_cube:supply_drop"})

    local meta = minetest.get_meta(chest_pos)
    local inv = meta:get_inventory()
    inv:set_size("main", 8*4) -- Default chest size

    if pchance(5) then inv:add_item("main", "wyrm_cube:potion_mv_runner 16") end
    if pchance(3) then inv:add_item("main", "wyrm_cube:potion_mv_doom 4") end
    if pchance(1) then inv:add_item("main", "wyrm_cube:potion_mv_hyper 2") end
    if pchance(3) then inv:add_item("main", "wyrm_cube:potion_mv_moon 4") end
    if pchance(3) then inv:add_item("main", "wyrm_cube:potion_mv_mars 4") end
    if pchance(2) then inv:add_item("main", "wyrm_cube:potion_mv_low_orbit 2") end
    if pchance(4) then inv:add_item("main", "wyrm_cube:potion_mv_rabbit 4") end
    if pchance(5) then inv:add_item("main", "wyrm_cube:potion_immunity_1 4") end
    if pchance(3) then inv:add_item("main", "wyrm_cube:potion_immunity_2 4") end
    if pchance(1) then inv:add_item("main", "wyrm_cube:potion_immunity_3 2") end
    if pchance(3) then inv:add_item("main", "wyrm_cube:potion_cat 4") end
    if pchance(2) then inv:add_item("main", "wyrm_cube:potion_feather 2") end
    if pchance(2) then inv:add_item("main", "wyrm_cube:potion_bird 2") end
    if pchance(10) then inv:add_item("main", "wyrm_cube:potion_health_1 8") end
    if pchance(7) then inv:add_item("main", "wyrm_cube:potion_health_2 4") end
    if pchance(4) then inv:add_item("main", "wyrm_cube:potion_health_3 1") end

    if pchance(20) then inv:add_item("main", "wyrm_gps:gps 1") end
    if pchance(20) then inv:add_item("main", "wyrm_cube:radio 1") end
    if pchance(10) then inv:add_item("main", "wyrm_cube:transmuter 1") end
    if pchance(10) then inv:add_item("main", "wyrm_cube:respawner 8") end
    if pchance(20) then inv:add_item("main", "wyrm_cube:meta_scanner 1") end
    if pchance(20) then inv:add_item("main", "wyrm_cube:meta_vacuum 1") end
    if pchance(20) then inv:add_item("main", "wyrm_cube:capsule_yurt 8") end
    if pchance(3) then inv:add_item("main", "wyrm_cube:capsule_airport 2") end
    if pchance(5) then inv:add_item("main", "wyrm_cube:capsule_watchtower 8") end
    if pchance(1) then inv:add_item("main", "wyrm_cube:capsule_megatower 1") end
    if pchance(10) then inv:add_item("main", "wyrm_cube:lamp_small 32") end

    if pchance(5) then inv:add_item("main", "default:sword_diamond 1") end
    if pchance(10) then inv:add_item("main", "default:sword_steel 1") end
    if pchance(20) then inv:add_item("main", "default:sword_stone 1") end

    if pchance(1) then inv:add_item("main", "3d_armor:boots_mithril 1") end
    if pchance(10) then inv:add_item("main", "3d_armor:boots_diamond 1") end
    if pchance(20) then inv:add_item("main", "3d_armor:boots_steel 1") end

    if pchance(1) then inv:add_item("main", "3d_armor:chestplate_mithril 1") end
    if pchance(10) then inv:add_item("main", "3d_armor:chestplate_diamond 1") end
    if pchance(20) then inv:add_item("main", "3d_armor:chestplate_steel 1") end

    if pchance(1) then inv:add_item("main", "3d_armor:helmet_mithril 1") end
    if pchance(10) then inv:add_item("main", "3d_armor:helmet_diamond 1") end
    if pchance(20) then inv:add_item("main", "3d_armor:helmet_steel 1") end

    if pchance(1) then inv:add_item("main", "shields:shield_mithril 1") end
    if pchance(10) then inv:add_item("main", "shields:shield_diamond 1") end
    if pchance(20) then inv:add_item("main", "shields:shield_steel 1") end

    if pchance(5) then inv:add_item("main", "default:torch 32") end

    if pchance(10) then inv:add_item("main", "default:pick_diamond 1") end
    if pchance(10) then inv:add_item("main", "default:axe_diamond 1") end
    if pchance(10) then inv:add_item("main", "default:shovel_diamond 1") end
    if pchance(4) then inv:add_item("main", "hammermod:steel_hammer 1") end

    if pchance(6) then inv:add_item("main", "farming:bread 32") end
    if pchance(6) then inv:add_item("main", "default:apple 32") end

    if pchance(5) then inv:add_item("main", "default:tree 99") end -- Wood (raw) block
    if pchance(5) then inv:add_item("main", "default:stone 99") end

    if pchance(5) then inv:add_item("main", "default:ladder_steel 99") end
    if pchance(5) then inv:add_item("main", "bucket:bucket_water 8") end

    if pchance(10) then inv:add_item("main", "beds:bed_bottom 1") end

    if pchance(5) then inv:add_item("main", "animalia:saddle 1") end
    if pchance(5) then inv:add_item("main", "animalia:spawn_horse 1") end
    if pchance(2) then inv:add_item("main", "animalia:libri_animalia 1") end
    if pchance(5) then inv:add_item("main", "leads:lead 8") end

    if pchance(20) then inv:add_item("main", "binoculars:binoculars 1") end
    if pchance(10) then inv:add_item("main", "goodtorch:flashlight_off 1") end

    if pchance(10) then inv:add_item("main", "x_bows:bow_wood 1") end
    if pchance(20) then inv:add_item("main", "x_bows:arrow_wood 99") end

    if pchance(10) then inv:add_item("main", "grapple:grapple 1") end

    if pchance(20) then inv:add_item("main", "biofuel:fuel_can 32") end
    if pchance(20) then inv:add_item("main", "hangglider:hangglider 1") end
    if pchance(5) then inv:add_item("main", "motorboat:boat 2") end
    if pchance(2) then inv:add_item("main", "hidroplane:hidro 2") end
    if pchance(20) then inv:add_item("main", "motorbike:cyan 4") end
    if pchance(10) then inv:add_item("main", "sum_airship:boat 3") end
    if pchance(1) then inv:add_item("main", "fishing_boat:boat 1") end
    if pchance(5) then inv:add_item("main", "sailing_kit:boat 2") end
    if pchance(20) then inv:add_item("main", "boats:boat 8") end
    -- Inventory will not overflow, so we can add a lot of items
    for i = 1, 99 do
        inv:add_item("main", "wyrm_cube:lamp 1")
    end
    -- end
    return false, "Placed the supply drop!"
end

local function supply_drops(user, num)
    for i = 1, num do
        minetest.after(i / 2, function()
            supply_drop(user:get_player_name())
        end)
    end
end

local function spawn_yurt(name, param)
    local player = minetest.get_player_by_name(name)
    if not player then
        return false, "Player not found!"
    end

    -- Get the block the player is pointing at
    local player_pos = player:get_pos()
    local look_dir = player:get_look_dir()
    local start_pos = vector.add(player_pos, {x = 0, y = 1.5, z = 0}) -- Eye level
    local end_pos = vector.add(start_pos, vector.multiply(look_dir, 10)) -- 10 nodes ahead
    local pointed_things = minetest.raycast(start_pos, end_pos, false, false)
    local corner_stone = nil
    for thing in pointed_things do
        log("thing position: " .. minetest.pos_to_string(thing.under))
        if thing.type == "node" then
            corner_stone = thing.under -- The block the player is looking at
            log("Pointed thing is: " .. thing.type)
            break
        end
    end
    if corner_stone == nil then
        log("Pointed thing is nil!")
        return false, "You must be pointing at a block!"
    end

    -- Dimensions of the house
    local width = 7
    local height = 4
    local length = 7

    -- Ignore the logic above and just use the player's position
    corner_stone = player:get_pos()
    corner_stone.y = corner_stone.y - 1
    corner_stone.x = corner_stone.x - math.floor(width / 2)
    corner_stone.z = corner_stone.z - math.floor(length / 2)

    -- place the corner stone
    minetest.set_node(corner_stone, {name = "default:wood"}) -- Use wood blocks for the corner stone

    -- Build the walls
    for x = 0, width - 1 do
        for y = 0, height - 1 do
            for z = 0, length - 1 do
                local block = "wool:white"
                if (x == 3 and y < 3 and z == 0) then 
                    goto continue -- Skip this block for the door 
                end
                if (y == 2 and (z ~= 0) and ((x >= 2 and x < width - 2) or (z >= 2 and z < length - 2))) then
                    block = "default:glass"
                end
                -- ensure we only build walls
                if x == 0 or x == width - 1 or z == 0 or z == length - 1 then
                    minetest.set_node({
                        x = corner_stone.x + x,
                        y = corner_stone.y + y,
                        z = corner_stone.z + z
                    }, {name = block})
                end
                ::continue::
            end
        end
    end

    -- Build the roof
    for x = -1, width do
        for z = -1, length do
            minetest.set_node({
                x = corner_stone.x + x,
                y = corner_stone.y + height,
                z = corner_stone.z + z
            }, {name = "stairs:slab_silver_sandstone_brick"})
        end
    end

    -- Build the floor
    for x = 0, width - 1 do
        for z = 0, length - 1 do
            minetest.set_node({
                x = corner_stone.x + x,
                y = corner_stone.y,
                z = corner_stone.z + z
            }, {name = "default:wood"})
        end
    end

    -- place a bed
    minetest.set_node({
        x = corner_stone.x + 1,
        y = corner_stone.y + 1,
        z = corner_stone.z + 4
    }, {name = "beds:bed_bottom"})
    minetest.set_node({
        x = corner_stone.x + 1,
        y = corner_stone.y + 1,
        z = corner_stone.z + 5
    }, {name = "beds:bed_top"})
    minetest.set_node({
        x = corner_stone.x + width - 2,
        y = corner_stone.y + 1,
        z = corner_stone.z + 4
    }, {name = "beds:bed_bottom"})
    minetest.set_node({
        x = corner_stone.x + width - 2,
        y = corner_stone.y + 1,
        z = corner_stone.z + 5
    }, {name = "beds:bed_top"})

    -- place chest
    minetest.set_node({
        x = corner_stone.x + 1,
        y = corner_stone.y + 1,
        z = corner_stone.z + 1
    }, {name = "wyrm_cube:supply_drop"})
    -- Put some items in the chest
    local meta = minetest.get_meta({
        x = corner_stone.x + 1,
        y = corner_stone.y + 1,
        z = corner_stone.z + 1
    })
    local inv = meta:get_inventory()
    inv:set_size("main", 8*4) -- Default chest size
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
    minetest.set_node({
        x = corner_stone.x + width - 2,
        y = corner_stone.y + 1,
        z = corner_stone.z + 1
    }, {name = "wyrm_cube:supply_drop"})

    -- place transmuter
    minetest.set_node({
        x = corner_stone.x + math.floor(width / 2),
        y = corner_stone.y + 1,
        z = corner_stone.z + length - 2
    }, {name = "wyrm_cube:transmuter"})

    -- Build the door
    minetest.set_node({
        x = corner_stone.x + 3,
        y = corner_stone.y + 1,
        z = corner_stone.z
    }, {name = "doors:door_glass_a"}) -- Use wood blocks for the door

    -- place lamps
    minetest.set_node({
        x = corner_stone.x + 1,
        y = corner_stone.y + 3,
        z = corner_stone.z + 5
    }, {name = "wyrm_cube:lamp_small"})
    minetest.set_node({
        x = corner_stone.x + 5,
        y = corner_stone.y + 3,
        z = corner_stone.z + 5
    }, {name = "wyrm_cube:lamp_small"})
    minetest.set_node({
        x = corner_stone.x + 1,
        y = corner_stone.y + 3,
        z = corner_stone.z + -1
    }, {name = "wyrm_cube:lamp_small"})
    minetest.set_node({
        x = corner_stone.x + 5,
        y = corner_stone.y + 3,
        z = corner_stone.z + -1
    }, {name = "wyrm_cube:lamp_small"})

    spawn_particles(corner_stone)

    return true, "House created with the corner stone as the starting point!"
end

local function spawn_landing_strip(name)
    local length = 32
    local width = 5
    local player = minetest.get_player_by_name(name)
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
            if (x % 2 == 0 and z > -width + 3 and z < width - 3 and z ~= 0) then
                block = "wyrm_cube:lamp_blinking_off"
                if x % 4 == 0 then
                    delay = 1
                end
            end
            minetest.after(delay, function()
                minetest.set_node({
                    x = pos.x + x,
                    y = pos.y,
                    z = pos.z + z
                }, {name = block})
            end)
            for y = 1, 17 do
                minetest.set_node({
                    x = pos.x + x,
                    y = pos.y + y,
                    z = pos.z + z
                }, {name = "air"})
            end
        end
    end
    for x = -width, width do
        for z = -length, length do
            local block = "default:stone"
            local delay = 0
            if (z % 2 == 0 and x > -width + 3 and x < width - 3 and x ~= 0) then
                block = "wyrm_cube:lamp_blinking_off"
                if z % 4 == 0 then
                    delay = 1
                end
            end
            minetest.after(delay, function()
                minetest.set_node({
                    x = pos.x + x,
                    y = pos.y,
                    z = pos.z + z
                }, {name = block})
            end)
            for y = 1, 17 do
                minetest.set_node({
                    x = pos.x + x,
                    y = pos.y + y,
                    z = pos.z + z
                }, {name = "air"})
            end
        end
    end

    spawn_particles(pos)
end

local function spawn_watchtower(name)
    local player = minetest.get_player_by_name(name)
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
                minetest.set_node({
                    x = pos.x + x,
                    y = pos.y + y,
                    z = pos.z + z
                }, {name = "default:aspen_wood"})
            end
        end
    end
    -- Place a lamp at each corner
    minetest.set_node({
        x = pos.x + 1,
        y = pos.y + height,
        z = pos.z + 1
    }, {name = "wyrm_cube:lamp"})
    minetest.set_node({
        x = pos.x + 1,
        y = pos.y + height + 1,
        z = pos.z + 1
    }, {name = "wyrm_cube:lamp"})

    minetest.set_node({
        x = pos.x + width,
        y = pos.y + height,
        z = pos.z + 1
    }, {name = "wyrm_cube:lamp"})
    minetest.set_node({
        x = pos.x + width,
        y = pos.y + height + 1,
        z = pos.z + 1
    }, {name = "wyrm_cube:lamp"})

    minetest.set_node({
        x = pos.x + 1,
        y = pos.y + height,
        z = pos.z + width
    }, {name = "wyrm_cube:lamp"})
    minetest.set_node({
        x = pos.x + 1,
        y = pos.y + height + 1,
        z = pos.z + width
    }, {name = "wyrm_cube:lamp"})

    minetest.set_node({
        x = pos.x + width,
        y = pos.y + height,
        z = pos.z + width
    }, {name = "wyrm_cube:lamp"})
    minetest.set_node({
        x = pos.x + width,
        y = pos.y + height + 1,
        z = pos.z + width
    }, {name = "wyrm_cube:lamp"})
    -- Drill a hole down the middle
    for y = 1, height do
        for x = 1, width do
            for z = 1, width do
                if x == math.floor(width / 2) and z == math.floor(width / 2) then
                    minetest.set_node({
                        x = pos.x + x,
                        y = pos.y + y,
                        z = pos.z + z
                    }, {name = "default:ladder_steel", param2 = 5})
                    minetest.set_node({
                        x = pos.x + x,
                        y = pos.y + y,
                        z = pos.z + z + 1
                    }, {name = "air"})
                    local block = "default:aspen_wood"
                    if y % 4 == 0 and y > 8 then
                        block = "wyrm_cube:lamp_blinking_off"
                    end
                    minetest.set_node({
                        x = pos.x + x,
                        y = pos.y + y,
                        z = pos.z + z - 1
                    }, {name = block})
                    minetest.set_node({
                        x = pos.x + x,
                        y = pos.y + y,
                        z = pos.z + z + 2
                    }, {name = block})

                end
            end
        end
    end
    -- Make a walkway through the front
    pos = pos_c
    for x = 1, width_c do
        for z = 1, width_c do
            if x == math.floor(width_c / 2) and z > math.floor(width_c / 2) then
                minetest.set_node({
                    x = pos.x + x,
                    y = pos.y + 1,
                    z = pos.z + z
                }, {name = "air"})
                minetest.set_node({
                    x = pos.x + x,
                    y = pos.y + 2,
                    z = pos.z + z
                }, {name = "air"})
            end
        end
    end
    -- Place a door
    minetest.set_node({
        x = pos.x + math.floor(width_c / 2),
        y = pos.y + 1,
        z = pos.z + width_c
    }, {name = "doors:door_glass_a"})
    -- Place a small lamp above the door
    minetest.set_node({
        x = pos.x + math.floor(width_c / 2),
        y = pos.y  + 3,
        z = pos.z + width_c + 1
    }, {name = "wyrm_cube:lamp_small", param2 = 5})
    pos = pos_c
    pos.y = pos.y + height + 2
    pos.x = pos.x + width_c / 2
    pos.z = pos.z + width_c / 2
    player:set_pos(pos)
    spawn_particles(pos)
end

local function spawn_megatower(name)
    local player = minetest.get_player_by_name(name)
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
                minetest.set_node({
                    x = pos.x + x,
                    y = pos.y + y,
                    z = pos.z + z
                }, {name = "default:aspen_wood"})
            end
        end
    end
    -- Place a lamp at each corner
    minetest.set_node({
        x = pos.x + 1,
        y = pos.y + height,
        z = pos.z + 1
    }, {name = "wyrm_cube:lamp"})
    minetest.set_node({
        x = pos.x + 1,
        y = pos.y + height + 1,
        z = pos.z + 1
    }, {name = "wyrm_cube:lamp"})

    minetest.set_node({
        x = pos.x + width,
        y = pos.y + height,
        z = pos.z + 1
    }, {name = "wyrm_cube:lamp"})
    minetest.set_node({
        x = pos.x + width,
        y = pos.y + height + 1,
        z = pos.z + 1
    }, {name = "wyrm_cube:lamp"})

    minetest.set_node({
        x = pos.x + 1,
        y = pos.y + height,
        z = pos.z + width
    }, {name = "wyrm_cube:lamp"})
    minetest.set_node({
        x = pos.x + 1,
        y = pos.y + height + 1,
        z = pos.z + width
    }, {name = "wyrm_cube:lamp"})

    minetest.set_node({
        x = pos.x + width,
        y = pos.y + height,
        z = pos.z + width
    }, {name = "wyrm_cube:lamp"})
    minetest.set_node({
        x = pos.x + width,
        y = pos.y + height + 1,
        z = pos.z + width
    }, {name = "wyrm_cube:lamp"})
    -- Drill a hole down the middle
    for y = 1, height do
        for x = 1, width do
            for z = 1, width do
                if x == math.floor(width / 2) and z == math.floor(width / 2) then
                    minetest.set_node({
                        x = pos.x + x,
                        y = pos.y + y,
                        z = pos.z + z
                    }, {name = "default:ladder_steel", param2 = 5})
                    minetest.set_node({
                        x = pos.x + x,
                        y = pos.y + y,
                        z = pos.z + z + 1
                    }, {name = "air"})
                    local block = "default:aspen_wood"
                    if y % 4 == 0 and y > 8 then
                        block = "wyrm_cube:lamp_blinking_off"
                    end
                    minetest.set_node({
                        x = pos.x + x,
                        y = pos.y + y,
                        z = pos.z + z - 1
                    }, {name = block})
                    minetest.set_node({
                        x = pos.x + x,
                        y = pos.y + y,
                        z = pos.z + z + 2
                    }, {name = block})

                end
            end
        end
    end
    -- Make a walkway through the front
    pos = pos_c
    for x = 1, width_c do
        for z = 1, width_c do
            if x == math.floor(width_c / 2) and z > math.floor(width_c / 2) then
                minetest.set_node({
                    x = pos.x + x,
                    y = pos.y + 1,
                    z = pos.z + z
                }, {name = "air"})
                minetest.set_node({
                    x = pos.x + x,
                    y = pos.y + 2,
                    z = pos.z + z
                }, {name = "air"})
            end
        end
    end
    -- Place a door
    minetest.set_node({
        x = pos.x + math.floor(width_c / 2),
        y = pos.y + 1,
        z = pos.z + width_c
    }, {name = "doors:door_glass_a"})
    -- Place a small lamp above the door
    minetest.set_node({
        x = pos.x + math.floor(width_c / 2),
        y = pos.y  + 3,
        z = pos.z + width_c + 1
    }, {name = "wyrm_cube:lamp_small", param2 = 5})
    pos = pos_c
    pos.y = pos.y + height + 2
    pos.x = pos.x + width_c / 2
    pos.z = pos.z + width_c / 2
    player:set_pos(pos)
    spawn_particles(pos)
end

--
-- NODE REGISTRATION
--

-- Register the wyrm cube node
minetest.register_node("wyrm_cube:wyrm_cube", {
    description = "Wyrm Cube",
    drawtype = "mesh",
    mesh = "wyrm_cube.obj", -- Add the mesh for a spherical look
    tiles = {"wyrm_cube.png"},
    is_ground_content = false,
    groups = {cracky = 3,  oddly_breakable_by_hand = 2},
    sounds = default.node_sound_stone_defaults(),
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    after_place_node = function(pos, placer)
        local player_name = placer:get_player_name() or "unknown"
        log("Player " .. player_name .. " placed a wyrm cube at " .. 
        minetest.pos_to_string(pos))
        table.insert(wyrm_cubes, pos)
        save_wyrm_cubes()
        spawn_particles(pos)
    end,
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        local player_name = digger:get_player_name() or "unknown"
        log("Player " .. player_name .. " removed a wyrm cube at " .. 
        minetest.pos_to_string(pos))
        for i, cube_pos in ipairs(wyrm_cubes) do
            if vector.equals(pos, cube_pos) then
                table.remove(wyrm_cubes, i)
                break
            end
        end
        minetest.sound_play("cube_get", {
            pos = player_pos, -- Position where the sound will be played
            gain = 10.0, -- Volume of the sound
            max_hear_distance = 10, -- Max distance where the sound can be heard
            loop = false, -- Set to true if you want the sound to loop
        })
        save_wyrm_cubes()
        spawn_particles(pos)
        -- Spawn a tower
        local t_pos = vector.new(pos)
        for i = 1, 64 do
            minetest.set_node(t_pos, {name = "default:obsidian"})
            if math.random() > 0.5 then
                if math.random() > 0.75 then
                    t_pos.x = t_pos.x + 1
                elseif math.random() > 0.75 then
                    t_pos.x = t_pos.x - 1
                end
                minetest.set_node(t_pos, {name = "default:obsidian"})
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
        minetest.set_node(chest_pos, {name = "wyrm_cube:wyrm_chest"})
        local meta = minetest.get_meta(chest_pos)
        local inv = meta:get_inventory()
        inv:set_size("main", 2) -- Default chest size
        inv:add_item("main", chest_options[math.random(1, #chest_options)] .." 1")
        inv:add_item("main", chest_options[math.random(1, #chest_options)] .." 1")
        local chest_pos2 = vector.new(pos)
        chest_pos2.y = chest_pos2.y - 2
        local glass_pos = vector.new(pos)
        glass_pos.y = glass_pos.y - 1
        minetest.set_node(glass_pos, {name = "default:glass"})
        minetest.set_node(chest_pos2, {name = "wyrm_cube:wyrm_chest"})
        local meta2 = minetest.get_meta(chest_pos2)
        local inv2 = meta2:get_inventory()
        inv2:set_size("main", 2) -- Default chest size
        inv2:add_item("main", chest_options[math.random(1, #chest_options)] .." 1")
        inv2:add_item("main", chest_options[math.random(1, #chest_options)] .." 1")
        -- Spawn a dragon at the cube's position
        local d_pos = vector.new(pos)
        d_pos.y = d_pos.y + 32
        d_pos.x = d_pos.x + 8
        minetest.add_entity(d_pos, "draconis:fire_dragon")
    end,
})

minetest.register_node("wyrm_cube:lamp", {
    description = "A Lamp",
    tiles = {"wyrm_lamp.png"},
    is_ground_content = false,
    groups = {cracky = 3},
    sounds = default.node_sound_stone_defaults(),
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    after_place_node = function(pos, placer)
        -- 
    end,
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        -- 
    end,
})

minetest.register_node("wyrm_cube:lamp_small", {
    description = "A Lamp",
    tiles = {"wyrm_lamp.png"},
    drawtype = "mesh",
    mesh = "small_cube.obj", -- Add the mesh for a spherical look
    is_ground_content = false,
    paramtype2 = "facedir", -- Enable full rotation support
    on_rotate = screwdriver.rotate_simple, -- Allow simple rotation using the screwdriver
    groups = {cracky = 3},
    sounds = default.node_sound_stone_defaults(),
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    after_place_node = function(pos, placer)
        -- 
    end,
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        -- 
    end,
})

minetest.register_node("wyrm_cube:lamp_blinking_off", {
    description = "Blinking Lamp (Off)",
    tiles = {"wyrm_lamp_off.png"},
    groups = {cracky = 3},
    light_source = 0,
    on_construct = function(pos)
        -- Start the timer with an interval of 1 second
        minetest.get_node_timer(pos):start(1)
    end,
    on_timer = function(pos, elapsed)
        -- Switch to the "on" state
        minetest.swap_node(pos, {name = "wyrm_cube:lamp_blinking_on"})
        return true -- Continue the timer
    end,
})

minetest.register_node("wyrm_cube:lamp_blinking_on", {
    description = "Blinking Lamp (On)",
    tiles = {"wyrm_lamp.png"},
    groups = {cracky = 3, not_in_creative_inventory = 1},
    light_source = 14, -- Emit light when "on"
    drop = "wyrm_cube:lamp_blinking_off", -- Drop the "off" node
    on_timer = function(pos, elapsed)
        -- Switch to the "off" state
        minetest.swap_node(pos, {name = "wyrm_cube:lamp_blinking_off"})
        return true -- Continue the timer
    end,
})

minetest.register_node("wyrm_cube:supply_drop", {
    description = "Supply Drop",
    tiles = {"supply_drop.png", "supply_drop.png", "supply_drop.png",
    "supply_drop.png", "supply_drop.png", "supply_drop.png"},
    paramtype2 = "facedir",
    groups = {choppy = 2, oddly_breakable_by_hand = 2, falling_node = 1},
    is_ground_content = false,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    glow = 10,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("formspec",
        "size[8,9]"..
        "list[current_name;main;0,0.3;8,4;]"..
        "list[current_player;main;0,4.85;8,1;]"..
        "list[current_player;main;0,6.08;8,3;8]"..
        "listring[current_name;main]"..
        "listring[current_player;main]")
        meta:set_string("infotext", "Supply Drop")
        local inv = meta:get_inventory()
        inv:set_size("main", 8*4)

        -- Trigger falling right after placement
        minetest.after(0, function()
            minetest.check_for_falling(pos)
        end)
    end,

    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:is_empty("main")
    end,

    on_blast = function(pos)
        local drops = {}
        default.get_inventory_drops(pos, "main", drops)
        drops[#drops + 1] = "wyrm_cube:supply_drop"
        minetest.remove_node(pos)
        return drops
    end,
})

minetest.register_node("wyrm_cube:wyrm_chest", {
    description = "Wyrm Chest",
    tiles = {"wyrm_cube.png", "wyrm_cube.png", "wyrm_cube.png",
    "wyrm_cube.png", "wyrm_cube.png", "wyrm_cube.png"},
    paramtype2 = "facedir",
    groups = {choppy = 2, oddly_breakable_by_hand = 2, falling_node = 1},
    is_ground_content = false,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    glow = 10,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("formspec",
        "size[8,9]"..
        "list[current_name;main;0,0.3;8,4;]"..
        "list[current_player;main;0,4.85;8,1;]"..
        "list[current_player;main;0,6.08;8,3;8]"..
        "listring[current_name;main]"..
        "listring[current_player;main]")
        meta:set_string("infotext", "Wyrm Chest")
        local inv = meta:get_inventory()
        inv:set_size("main", 2)

        -- Trigger falling right after placement
        minetest.after(0, function()
            minetest.check_for_falling(pos)
        end)
    end,

    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:is_empty("main")
    end,

    on_blast = function(pos)
        local drops = {}
        default.get_inventory_drops(pos, "main", drops)
        drops[#drops + 1] = "wyrm_cube:wyrm_chest"
        minetest.remove_node(pos)
        return drops
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        log("putting item: " .. stack:get_name())
        if stack:get_name() == "wyrm_cube:wyrm_cube" and stack:get_count() >= cube_count then
            minetest.after(0, function()
                hud_msg(player, "GAME OVER!", 100)
                minetest.remove_node(pos)
                spawn_particles(pos)
            end)
        end
        return stack:get_count() -- Allow any number of items to be placed
    end,
})

local function calculate_transmute_rate(meta, stack)
    local transmute_rate = 0.1
    local out_type = "air"
    local out_count = 0
    if stack == nil then
        transmute_rate = 0
        log("got nil stack")
    end
    if stack ~= nil and not stack:is_empty() then

        -- Rate
        -- Base rate for all ores
        if string_includes(stack:get_name(), "ore") then
            transmute_rate = 0.6
        end
        if string_includes(stack:get_name(), "wyrm") then
            transmute_rate = 0.25
        end
        if string_includes(stack:get_name(), "diamond") then
            transmute_rate = 1
        end
        if string_includes(stack:get_name(), "gold") then
            transmute_rate = 0.8
        end
        if string_includes(stack:get_name(), "crystal") then
            transmute_rate = 0.9
        end
        if string_includes(stack:get_name(), "obsidian") then
            transmute_rate = 0.9
        end
        if string_includes(stack:get_name(), "mithril") then
            transmute_rate = 0.9
        end
        if string_includes(stack:get_name(), "steel") then
            transmute_rate = 0.7
        end
        if string_includes(stack:get_name(), "mese") then
            transmute_rate = 0.6
        end
        if string_includes(stack:get_name(), "flower") then
            transmute_rate = 0.5
        end
        if string_includes(stack:get_name(), "copper") then
            transmute_rate = 0.5
        end
        if string_includes(stack:get_name(), "bronze") then
            transmute_rate = 0.5
        end
        if string_includes(stack:get_name(), "iron") then
            transmute_rate = 0.4
        end
        if string_includes(stack:get_name(), "tin") then
            transmute_rate = 0.4
        end
        if string_includes(stack:get_name(), "coal") then
            transmute_rate = 0.3
        end
        if string_includes(stack:get_name(), "wood") then
            transmute_rate = 0.2
        end
        -- Overrides for specific items
        if string_includes(stack:get_name(), "gold_ingot") then
            transmute_rate = 0.25
        end
        if string_includes(stack:get_name(), "mese_crystal") then
            transmute_rate = 0.2
        end
        -- Dont allow supply_dropper to be transmuted
        if string_includes(stack:get_name(), "supply_dropper") then
            transmute_rate = 0
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
    meta:set_string("formspec",
        "size[8,9]" ..
        "list[current_name;main;0,0.3;8,4;]" ..
        "label[0,1.5;// JUNK > INGOT > CRYSTAL > CHIP > SUPPLY DROP]" ..
        "label[0,2;// TRANSMUTATION RATE: " .. transmute_rate .. "x (" .. out_count .. ")]" ..
        "label[0,2.5;// TRANSMUTATION TYPE: " .. out_type .. "]" ..
        "label[0,3;" .. can_transmute_string .. "]" ..
        "button[3,4;2,1;transmute;TRANSMUTE]" ..
        "list[current_player;main;0,5;8,1;]" ..
        "list[current_player;main;0,6;8,3;8]" ..
        "listring[current_name;main]" ..
        "listring[current_player;main]")
    return transmute_rate
end

minetest.register_node("wyrm_cube:transmuter", {
    description = "Transmuter",
    drawtype = "mesh",
    mesh = "transmuter.obj",
    tiles = {"transmuter.png"},
    paramtype2 = "facedir",
    on_rotate = screwdriver.rotate_simple, -- Allow simple rotation using the screwdriver
    groups = {choppy = 2, oddly_breakable_by_hand = 2, falling_node = 1},
    is_ground_content = false,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    glow = 10,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        calculate_transmute_rate(meta, nil)
        meta:set_string("infotext", "Transmuter")
        local inv = meta:get_inventory()
        inv:set_size("main", 1)

        -- Trigger falling right after placement
        minetest.after(0, function()
            minetest.check_for_falling(pos)
        end)
    end,

    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:is_empty("main")
    end,

    on_receive_fields = function(pos, formname, fields, player)
        if fields.transmute then
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local stack = inv:get_stack("main", 1)
            local transmute_rate = meta:get_float("transmute_rate") or 0.1
            local out_type = meta:get_string("out_type") or "air"
            if not stack:is_empty() then
                -- Calculate the number to give (10% of the item count)
                local out_count = math.floor(stack:get_count() * transmute_rate)
                log("out: "..out_count)
                log("rate: "..transmute_rate)
                log("#stack:"..stack:get_count())
                if out_count > 0 then
                    inv:set_stack("main", 1, out_type .. " " .. out_count)
                    spawn_particles(pos)
                    -- Notify the player
                    minetest.chat_send_player(player:get_player_name(), "Items transmuted!")
                    calculate_transmute_rate(meta, inv:get_stack("main", 1))
                else
                    minetest.chat_send_player(player:get_player_name(), "Not enough items to transmute!")
                end
            else
                minetest.chat_send_player(player:get_player_name(), "The chest is empty!")
            end
        end
    end,

    on_blast = function(pos)
        local drops = {}
        default.get_inventory_drops(pos, "main", drops)
        drops[#drops + 1] = "wyrm_cube:supply_drop"
        minetest.remove_node(pos)
        return drops
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        log("putting item: " .. stack:get_name())
        local meta = minetest.get_meta(pos)
        -- Wait 0.1 seconds because the take will happen after
        minetest.after(0.1, function()
            calculate_transmute_rate(meta, stack)
        end)
        return stack:get_count() -- Allow any number of items to be placed
    end,

    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        -- local meta = minetest.get_meta(pos)
        -- calculate_transmute_rate(meta, nil)
        return count -- Allow any number of items to be taken
    end,

    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        log("taking item: " .. stack:get_name())
        local meta = minetest.get_meta(pos)
        calculate_transmute_rate(meta, nil)
        return stack:get_count() -- Allow any number of items to be taken
    end,
})

--
-- TOOLS & CRAFT ITEMS
--

-- Register the wyrm radar item
minetest.register_tool("wyrm_cube:wyrm_radar", {
    description = "wyrm Radar",
    inventory_image = "wyrm_radar.png",
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
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

            local bg_hud_id = user:hud_add({
                hud_elem_type = "image",
                position = {x = 0.5, y = 0.1}, -- Centered at the top of the screen
                offset = {x = 0, y = 0},
                scale = {x = 650, y = 150}, -- Adjust scale for the size of the block
                alignment = {x = 0, y = 0},
                text = "ui_bg.png", -- A black texture (you need to include this in your mod)
            })
            -- Add HUD text
            local hud_id = user:hud_add({
                hud_elem_type = "text", -- HUD element type
                position = {x = 0.5, y = 0.1}, -- Centered at the top of the screen
                offset = {x = 0, y = 0}, -- No additional offset
                text = 'DIST: ' .. math.floor(nearest_distance) .. '\nCUBE: #' .. #wyrm_cubes, -- The text to display
                alignment = {x = 0, y = 0}, -- Center alignment
                scale = {x = 100, y = 100}, -- Scale for larger text
                size = {x = 2, y = 0}, -- No size limit
                style = 1, -- Style for the text
                number = 0xFFFF99, --  color in hexadecimal (RGB)
            })

            -- Automatically remove the text after 10 seconds (optional)
            minetest.after(6, function()
                if user and user:is_player() then
                    user:hud_remove(hud_id)
                    user:hud_remove(bg_hud_id)
                end
            end)

            -- Render a line of particles pointing to the wyrm cube
            for i = 1, steps do
                local particle_pos = vector.add(player_pos, vector.multiply(direction, i))
                particle_pos.y = particle_pos.y + 1 -- Adjust the height for better visibility

                minetest.add_particle({
                    pos = particle_pos,
                    velocity = {x = 0, y = 0, z = 0},
                    acceleration = {x = 0, y = 0.1 + math.random(), z = 0},
                    expirationtime = 10, -- Duration of the particle
                    size = 3, -- Increase for better visibility
                    texture = "wyrm_line_particle.png^[colorize:" .. color_str .. ":127",
                    glow = 10, -- Add glow for visibility in the dark
                })
            end
            minetest.sound_play("scan", {
                pos = player_pos, -- Position where the sound will be played
                gain = 1.0, -- Volume of the sound
                max_hear_distance = 10, -- Max distance where the sound can be heard
                loop = false, -- Set to true if you want the sound to loop
            })
        else
            log(user:get_player_name() .. " No Wyrm Cubes found!")
            minetest.sound_play("scan_bad", {
                pos = player_pos, -- Position where the sound will be played
                gain = 10.0, -- Volume of the sound
                max_hear_distance = 10, -- Max distance where the sound can be heard
                loop = false, -- Set to true if you want the sound to loop
            })
        end
        for i = 1, monster_spawn_amt do
            minetest.after(i / 2, function()
                spawn_monster(user:get_player_name())
            end)
        end
    end,
})

minetest.register_tool("wyrm_cube:meta_scanner", {
    description = "Meta Scanner",
    inventory_image = "meta_scanner.png", -- Replace with your custom icon if you have one
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
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
        local ray = minetest.raycast(pos, vector.add(pos, vector.multiply(dir, 10)), true, true)

        -- Iterate through the raycast results
        for pointed in ray do
            if pointed.type == "node" then
                -- Player is looking at a node
                local node = minetest.get_node(pointed.under)
                local node_name = node.name
                -- minetest.chat_send_player(user:get_player_name(), "You are looking at node: " .. node_name)
                hud_msg(user, "NODE:\n" .. node_name, 3)
                spawn_particles(pointed.under)
                break
            elseif pointed.type == "object" then
                -- Player is looking at an entity
                local obj = pointed.ref
                if obj and obj:get_luaentity() then
                    local entity_name = obj:get_luaentity().description or obj:get_luaentity().name
                    -- minetest.chat_send_player(user:get_player_name(), "You are looking at entity: " .. entity_name)
                    hud_msg(user, "ENTITY:\n" .. entity_name, 3)
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

minetest.register_tool("wyrm_cube:meta_vacuum", {
    description = "Meta Vacuum",
    inventory_image = "vac.png", -- Replace with your custom icon if you have one
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        if not user then
            return
        end

        -- Get the player's position and look direction
        local pos = user:get_pos()
        local dir = user:get_look_dir()

        -- Adjust the starting position slightly above the player's feet to avoid self-collision
        pos.y = pos.y + 1.5

        -- Perform the raycast
        local ray = minetest.raycast(pos, vector.add(pos, vector.multiply(dir, 10)), true, true)

        -- Iterate through the raycast results
        for pointed in ray do
            if pointed.type == "node" then
                -- Player is looking at a node
                local pointed_pos = pointed.under
                local node = minetest.get_node(pointed_pos)
                local def = minetest.registered_nodes[node.name]

                if def and def.diggable ~= false then
                    -- Simulate digging the node
                    local drops = minetest.get_node_drops(node.name)
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
                            minetest.set_node(pointed_pos, {name = "air"})
                        else
                            -- Call the engine's dig logic to trigger callbacks and side effects
                            minetest.node_dig(pointed_pos, node, user)
                        end
                        spawn_particles(pointed_pos)
                    else
                        minetest.chat_send_player(user:get_player_name(), "Inventory full!")
                    end
                else
                    minetest.chat_send_player(user:get_player_name(), "This node cannot be dug.")
                end

                break
            elseif pointed.type == "object" then
                -- Ignore objects for now
            end
        end
    end,
})

minetest.register_craftitem("wyrm_cube:tech_chip", {
    description = "Tech Chip",
    inventory_image = "tech_chip.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 1,
    on_use = function(itemstack, user, pointed_thing)
        return itemstack
    end,
})

minetest.register_craftitem("wyrm_cube:supply_dropper", {
    description = "Supply Dropper",
    inventory_image = "supply_dropper.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        supply_drops(user, 5)        -- Remove one item from the stack
        itemstack:take_item(1)

        -- Return the updated itemstack
        return itemstack
    end,
})

minetest.register_craftitem("wyrm_cube:capsule_airport", {
    description = "Airport Capsule",
    inventory_image = "capsule_yellow.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        spawn_landing_strip(user:get_player_name())
        -- Remove one item from the stack
        itemstack:take_item(1)

        -- Return the updated itemstack
        return itemstack
    end,
})

minetest.register_craftitem("wyrm_cube:capsule_yurt", {
    description = "Yurt Capsule",
    inventory_image = "capsule_white.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        -- Call your custom function to build the yurt
        spawn_yurt(user:get_player_name())

        -- Remove one item from the stack
        itemstack:take_item(1)

        -- Return the updated itemstack
        return itemstack
    end,
})

minetest.register_craftitem("wyrm_cube:capsule_watchtower", {
    description = "Watchtower Capsule",
    inventory_image = "capsule_black.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        -- Call your custom function to build the yurt
        spawn_watchtower(user:get_player_name())

        -- Remove one item from the stack
        itemstack:take_item(1)

        -- Return the updated itemstack
        return itemstack
    end,
})

minetest.register_craftitem("wyrm_cube:capsule_megatower", {
    description = "Megatower Capsule",
    inventory_image = "capsule_red.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        -- Call your custom function to build the yurt
        spawn_megatower(user:get_player_name())

        -- Remove one item from the stack
        itemstack:take_item(1)

        -- Return the updated itemstack
        return itemstack
    end,
})

minetest.register_craftitem("wyrm_cube:radio", {
    description = "Radio to play some tunes",
    inventory_image = "wyrm_radio.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        local meta = itemstack:get_meta()
        local playing = meta:get_int("playing") or -1
        log(playing or "nil")
        local text = ""
        if playing ~= nil and playing > -1 then
            -- Stop the sound
            minetest.sound_stop(playing)
            meta:set_int("playing", -1)
            text = "STOPPED"
        else
            local track = "track" .. math.random(1,3)
            local track_num = minetest.sound_play(track, {
                pos = user:get_pos(), -- Position where the sound will be played
                gain = 1.0, -- Volume of the sound
                max_hear_distance = 100, -- Max distance where the sound can be heard
                loop = false, -- Set to true if you want the sound to loop
            })
            meta:set_int("playing", track_num) 
            text = "PLAY: " .. track
        end
        minetest.sound_play("static", {
            pos = user:get_pos(), -- Position where the sound will be played
            gain = 1.0, -- Volume of the sound
            max_hear_distance = 100, -- Max distance where the sound can be heard
            loop = false, -- Set to true if you want the sound to loop
        })
        local bg_hud_id = user:hud_add({
            hud_elem_type = "image",
            position = {x = 0.5, y = 0.1}, -- Centered at the top of the screen
            offset = {x = 0, y = 0},
            scale = {x = 650, y = 150}, -- Adjust scale for the size of the block
            alignment = {x = 0, y = 0},
            text = "ui_bg.png", -- A black texture (you need to include this in your mod)
        })
        -- Add HUD text
        local hud_id = user:hud_add({
            hud_elem_type = "text", -- HUD element type
            position = {x = 0.5, y = 0.1}, -- Centered at the top of the screen
            offset = {x = 0, y = 0}, -- No additional offset
            text = text, -- The text to display
            alignment = {x = 0, y = 0}, -- Center alignment
            scale = {x = 100, y = 100}, -- Scale for larger text
            size = {x = 2, y = 0}, -- No size limit
            style = 1, -- Style for the text
            number = 0xFFFF99, --  color in hexadecimal (RGB)
        })

        -- Automatically remove the text after 10 seconds (optional)
        minetest.after(2, function()
            if user and user:is_player() then
                user:hud_remove(hud_id)
                user:hud_remove(bg_hud_id)
            end
        end)
        return itemstack
    end,
})

minetest.register_craftitem("wyrm_cube:respawner", {
    description = "Respawner",
    inventory_image = "respawner.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        -- Call your custom function to build the yurt
        user:respawn()
        spawn_particles(user:get_pos())

        -- Remove one item from the stack
        itemstack:take_item(1)

        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_mv_runner", {
    description = "Wyrm Potion: Runner",
    inventory_image = "potion_blue.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        set_move(user:get_player_name(), move_speeds.runner)
        warn_potion(user, "Runner", 30)
        minetest.after(30, function()
            set_move(user:get_player_name(), move_speeds.normal)
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_mv_doom", {
    description = "Wyrm Potion: DOOM",
    inventory_image = "potion_pink.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        set_move(user:get_player_name(), move_speeds.doom)
        warn_potion(user, "DOOM", 30)
        minetest.after(30, function()
            set_move(user:get_player_name(), move_speeds.normal)
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_mv_hyper", {
    description = "Wyrm Potion: Hyper",
    inventory_image = "potion_cyan.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        set_move(user:get_player_name(), move_speeds.hyper)
        warn_potion(user, "Hyper", 30)
        minetest.after(30, function()
            set_move(user:get_player_name(), move_speeds.normal)
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_mv_moon", {
    description = "Wyrm Potion: Moon",
    inventory_image = "potion_white.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        set_move(user:get_player_name(), move_speeds.moon)
        warn_potion(user, "Moon", 30)
        minetest.after(30, function()
            set_move(user:get_player_name(), move_speeds.normal)
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_mv_mars", {
    description = "Wyrm Potion: Mars",
    inventory_image = "potion_red.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        set_move(user:get_player_name(), move_speeds.mars)
        warn_potion(user, "Mars", 30)
        minetest.after(30, function()
            set_move(user:get_player_name(), move_speeds.normal)
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_mv_low_orbit", {
    description = "Wyrm Potion: Low Orbit",
    inventory_image = "potion_yellow.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        set_move(user:get_player_name(), move_speeds.low_orbit)
        warn_potion(user, "Low Orbit", 30)
        minetest.after(30, function()
            set_move(user:get_player_name(), move_speeds.normal)
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_mv_rabbit", {
    description = "Wyrm Potion: Rabbit",
    inventory_image = "potion_cyan.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        set_move(user:get_player_name(), move_speeds.rabbit)
        warn_potion(user, "Rabbit", 30)
        minetest.after(30, function()
            set_move(user:get_player_name(), move_speeds.normal)
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_immunity_1", {
    description = "Wyrm Potion: Immunity 1",
    inventory_image = "potion_white.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        no_dmg(user:get_player_name(), 6) 
        warn_potion(user, "Immunity 1", 6)
        minetest.after(6, function()
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_immunity_2", {
    description = "Wyrm Potion: Immunity 2",
    inventory_image = "potion_white.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        no_dmg(user:get_player_name(), 30)
        warn_potion(user, "Immunity 2", 30)
        minetest.after(30, function()
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_immunity_3", {
    description = "Wyrm Potion: Immunity 3",
    inventory_image = "potion_white.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        no_dmg(user:get_player_name(), 120)
        warn_potion(user, "Immunity 3", 120)
        minetest.after(120, function()
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_health_1", {
    description = "Wyrm Potion: Health 1",
    inventory_image = "potion_green.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        local hp = user:get_hp()
        local new_hp = math.min(hp + 2, 20) -- Ensure HP does not exceed 20
        user:set_hp(new_hp)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_health_2", {
    description = "Wyrm Potion: Health 2",
    inventory_image = "potion_green.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        local hp = user:get_hp()
        local new_hp = math.min(hp + 10, 20) -- Ensure HP does not exceed 20
        user:set_hp(new_hp)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_health_3", {
    description = "Wyrm Potion: Health 3",
    inventory_image = "potion_green.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        local hp = user:get_hp()
        user:set_hp(20)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})

minetest.register_craftitem("wyrm_cube:potion_cat", {
    description = "Wyrm Potion: Cat",
    inventory_image = "potion_pink.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        fall_dmg(user:get_player_name(), 0.1)
        warn_potion(user, "Cat", 16)
        minetest.after(16, function()
            fall_dmg(user:get_player_name(), 1)
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_feather", {
    description = "Wyrm Potion: Feather",
    inventory_image = "potion_yellow.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        fall_dmg(user:get_player_name(), 0) 
        warn_potion(user, "Feather", 60)
        minetest.after(60, function()
            fall_dmg(user:get_player_name(), 1)
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})
minetest.register_craftitem("wyrm_cube:potion_bird", {
    description = "Wyrm Potion: Bird",
    inventory_image = "potion_white.png",
    stack_max = 99,
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        -- Grant flying permission
        local player_name = user:get_player_name()
        local privs = minetest.get_player_privs(player_name) -- Get the player's current privileges
        privs.fly = true -- Add the 'fly' privilege
        minetest.set_player_privs(player_name, privs) 
        minetest.chat_send_player(player_name, "You can now fly!")
        warn_potion(user, "Bird", 120)
        minetest.after(120, function()
            -- Remove flying permission
            local privs = minetest.get_player_privs(player_name) -- Get the player's current privileges
            privs.fly = nil -- Remove the 'fly' privilege
            minetest.set_player_privs(player_name, privs)
            spawn_particles(user:get_pos())
        end)
        spawn_particles(user:get_pos())
        -- Remove one item from the stack
        itemstack:take_item(1)
        -- Return the updated itemstack
        return itemstack
    end,
})

minetest.register_tool("wyrm_cube:wyrm_guide", {
    description = "Guidebook for Wyrm Cube",
    inventory_image = "wyrm_guide.png",
    light_source = 14, -- Maximum light level is 14 in Minetest
    paramtype = "light", -- Required for light emission
    sunlight_propagates = true, -- Allows light to pass through
    glow = 10,
    on_use = function(itemstack, user, pointed_thing)
        -- Open the book for reading
        local player_name = user:get_player_name()
        local mission_log = #wyrm_cubes .. " / ".. cube_count .. " Wyrm Cubes remaining"
        minetest.show_formspec(player_name, "wyrm_cube:wyrm_guide_formspec", string.format([[
        size[8,8]
textarea[0.5,0.5;7.5,7;book_content;Wyrm Guide;// MISSION LOG:

%s

-------

// GUIDE:
%s]

        ]], mission_log, GuideTxt))
    end,
})




--
-- CHAT COMMANDS
--

minetest.register_chatcommand("wc_log", {
  params = "<on|off>",
  description = "Enable or disable logging",
  func = function(name, param)
    if param == "on" then
      log_enabled = true
      return true, "Logging enabled."
    elseif param == "off" then
      log_enabled = false
      return true, "Logging disabled."
    else
      return false, "Invalid parameter. Use 'on' or 'off'."
    end
  end,
})

minetest.register_chatcommand("wc_mv", {
  params = "<normal|doom|hyper>",
  description = "Change player movement settings",
  func = function(name, param)
    -- Write the move name value to the sceen for debugging
    minetest.log("action", param)
    local move = move_speeds[param]
    if move == nil then
      return false, "Invalid movement type. Use: normal, doom, or hyper. Got " .. name
    end
    set_move(name, move) -- Set the player movement speed
    -- Override fall damage 
    fall_dmg(move.fall)
    return true, "Movement set to " .. param .. "."
  end,
})


minetest.register_chatcommand("wc_spawn_hmob", {
    description = "Spawn a  monster near the player",
    privs = {server = true}, -- Only players with server privilege can use this command
    func = spawn_monster,
})


-- place wyrm cubes command
minetest.register_chatcommand("wc_spawn_cubes", {
    params = "",
    description = "Place wyrm cubes in the world",
    func = function(name, param)
        log("Placing wyrm cubes on command")
        place_wyrm_cubes()
        return true, "wyrm cubes placed"
    end,
})

minetest.register_chatcommand("wc_spawn_yurt", {
    description = "Creates a small building a few blocks in front of the player.",
    privs = {server = true},  -- Optional: Restrict command to players with specific privileges
    func = spawn_yurt
})

minetest.register_chatcommand("wc_spawn_landing_strip", {
    description = "Creates a landing strip a few blocks in front of the player.",
    privs = {server = true},  -- Optional: Restrict command to players with specific privileges
    func = spawn_landing_strip
})

minetest.register_chatcommand("wc_spawn_watchtower", {
    description = "Creates a watchtower tower a few blocks in front of the player.",
    privs = {server = true},  -- Optional: Restrict command to players with specific privileges
    func = spawn_watchtower
})

minetest.register_chatcommand("wc_spawn_megatower", {
    description = "Creates a megatower tower a few blocks in front of the player.",
    privs = {server = true},  -- Optional: Restrict command to players with specific privileges
    func = spawn_megatower
})

minetest.register_chatcommand("wc_supply_drops", {
    description = "Creates a supply drop a few blocks in front of the player.",
    privs = {server = true},  -- Optional: Restrict command to players with specific privileges
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        supply_drops(player, 5)
    end
})
minetest.register_chatcommand("wc_supply_drop", {
    description = "Creates a supply drop a few blocks in front of the player.",
    privs = {server = true},  -- Optional: Restrict command to players with specific privileges
    func = supply_drop
})

minetest.register_chatcommand("wc_spawn_particles", {
    description = "Creates a particle effect at the player's position.",
    privs = {server = true},  -- Optional: Restrict command to players with specific privileges
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            spawn_particles(player:get_pos())
            return true, "Particles spawned"
        else
            return false, "Player not found"
        end
    end,
})

--
-- PLAYER JOIN HANDLER
--

-- Register a handler that runs when players join
minetest.register_on_joinplayer(function(player)
    -- set the time speed
    minetest.setting_set("time_speed", 256)
    minetest.chat_send_player(player:get_player_name(), 
    "Wyrm Cubes mod loaded with " .. #wyrm_cubes .. " wyrm cubes in the world")

    minetest.sound_play("intro", {
        pos = player:get_pos(), -- Position where the sound will be played
        gain = 10.0, -- Volume of the sound
        max_hear_distance = 100, -- Max distance where the sound can be heard
        loop = false, -- Set to true if you want the sound to loop
    })

    if players_list == "" then
        players_list = {}
    else
        players_list = minetest.deserialize(players_list)
    end
    -- https://api.luanti.org/class-reference/#player-only-no-op-for-other-objects
    player:set_sky({
        type = "regular",        -- Type of sky (plain, skybox, or regular)
        clouds = true,           -- Enable or disable clouds
        sky_color = {
            -- day_sky = "#b272f7",
            day_sky = "#14d9ae",
            day_horizon = "#f2b244",
        },
    })

    minetest.after(monster_spawn_delay, function()
        monster_spawn_timer(player)
    end)

    -- Show the main logo
    local bg_hud_id = player:hud_add({
        hud_elem_type = "image",
        position = {x = 0.5, y = 0.15}, -- Centered at the top of the screen
        offset = {x = 0, y = 0},
        scale = {x = 8, y = 8}, -- Adjust scale for the size of the block
        alignment = {x = 0, y = 0},
        text = "header.png", -- A black texture (you need to include this in your mod)
    })
    minetest.after(5, function()
        if player and player:is_player() then
            player:hud_remove(bg_hud_id)
        end
    end)

    -- Reset fall damage
    mod_storage:set_float(player:get_player_name() .. "_fall_dmg_mult", 1)


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
        minetest.show_formspec(player:get_player_name(), "game_intro:formspec", formspec)
        return
    end

    -- BELOW IS ONLY FOR NEW PLAYERS 

    players_list[player:get_player_name()] = true
    mod_storage:set_string("players_list", minetest.serialize(players_list))

    -- Give the player a wyrm radar
    local inv = player:get_inventory()
    if inv then
        inv:add_item("main", "wyrm_cube:wyrm_radar")
        inv:add_item("main", "wyrm_cube:wyrm_guide")
        inv:add_item("main", "wyrm_cube:capsule_yurt")
        minetest.chat_send_player(player:get_player_name(), "You have received a wyrm Radar!")
    end
    minetest.after(5, function()
       supply_drops(player, 5)
    end)
    minetest.after(10, function()
        place_wyrm_cubes()
    end)

    -- Teleport the player high into the air
    local pos = player:get_pos()
    local new_position = {x = pos.x, y = 128, z = pos.z}
    player:set_pos(new_position)
    no_dmg(player, 10) -- Disable damage for 5 seconds

    minetest.after(15, function()
        local formspec = string.format([[
        size[8,6]
        label[0.5,0.5;OH NO!]
        textarea[0.5,1;7.5,4;intro_text;;%s]
        button_exit[3,5.5;2,1;exit;Start Playing]
        ]], IntroTxt)
        minetest.show_formspec(player:get_player_name(), "game_intro:formspec", formspec)
    end)
end)

--
-- INIT
--

log("Initializing Wyrm Cube mod")
load_saved_cubes()

minetest.register_on_player_hpchange(function(player, hp_change, reason)
    local player_name = player:get_player_name()
    local mult = mod_storage:get_float(player_name .."_fall_dmg_mult") or 1
    if (mult == 0) then
        player:set_physics_override({
            fall_damage = false -- Disables fall damage completely
        })
        log(player:get_player_name() .. " fall damage disabled")
    else
        player:set_physics_override({
            fall_damage = true
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
minetest.register_on_shutdown(function()
    save_wyrm_cubes()
end)


