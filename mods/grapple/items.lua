minetest.register_tool("grapple:grapple", {
    description = "Grappling Hook",
    inventory_image = "grapple_loaded.png",
    on_use = function(itemstack, player, pointed_thing)
        local p_name = player:get_player_name()
        local look_dir = player:get_look_dir()
        local p_pos = player:get_pos()
        local look_horiz = player:get_look_horizontal()
        local look_vert = player:get_look_vertical()
        local spawn_pos = vector.add(p_pos,vector.new(0,1.8,0))
        spawn_pos = vector.add(vector.multiply(look_dir,.3),spawn_pos)

        if minetest.get_node(spawn_pos).name == "air" then 

            -- create a new id
            local grapple_id = math.random(1, 1000000)

            -- make data for the id
            
            table.insert(grapple.players[p_name].grapples,{
                id = grapple_id,
                recall = false,
                pull = false,
                pull_timer = 0,
                timer = 0,
                stuck = false,
            })

            -- spawn the grapple entity and throw it

            local obj = minetest.add_entity(spawn_pos, "grapple:grapple_throwable", minetest.write_json({
                _player = player:get_player_name(),
                _id = grapple_id
            }))

            obj:set_rotation(vector.new(look_vert,look_horiz,0))
            obj:set_acceleration(vector.new(0,-9.8,0))
            obj:set_velocity(vector.multiply(look_dir, 17))

            -- set the unloaded grapple with the id in meta
            local unloaded_grapple = ItemStack("grapple:grapple_unloaded")
            local meta = unloaded_grapple:get_meta()
            meta:set_int("id", grapple_id)
            
            -- give back an unloaded grapple
            return unloaded_grapple

        end
    end
})


local function rightclick_unloaded(itemstack, placer)
    local p_name = placer:get_player_name()
    local meta = itemstack:get_meta()
    local id = meta:get_int("id") or -1
    if not grapple.check_for_id_in_player_data(p_name,id) then
        return ItemStack("grapple:grapple")
    end

    local id_found = false
    for _,grappledata in pairs(grapple.players[p_name].grapples) do
        
        if grappledata.id == id then
            id_found = true
            grappledata.recall = true
        end
    end

    if not(id_found) then 
        return ItemStack("grapple:grapple")
    end
end

minetest.register_tool("grapple:grapple_unloaded", {
    description = "Grappling Hook (Unloaded)",
    inventory_image = "grapple_unloaded.png",

    -- leftclick to pull on the line
    on_use = function(itemstack, player, pointed_thing)
        local p_name = player:get_player_name()
        local meta = itemstack:get_meta()
        local id = meta:get_int("id") or -1
        if not grapple.check_for_id_in_player_data(p_name,id) then
            return ItemStack("grapple:grapple")
        end
    
        local id_found = false
        for _,grappledata in pairs(grapple.players[p_name].grapples) do
            
            if grappledata.id == id then
                id_found = true
                if grappledata.pull_timer <= 0 then
                    grappledata.pull = true
                end
            end
        end
    
        if not(id_found) then 
            return ItemStack("grapple:grapple")
        end
    end,

    -- rightclick to recall the grapple
    on_place = function(itemstack, placer, pointed_thing)
        return rightclick_unloaded(itemstack,placer)
    end,
    on_secondary_use = function(itemstack, user, pointed_thing)
        return rightclick_unloaded(itemstack,user)
    end,
})