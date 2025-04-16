

function grapple.check_for_id_in_player_data(p_name,id)
    if grapple.players[p_name] then
        for idx,grappledata in ipairs(grapple.players[p_name].grapples) do
            if grappledata.id == id then
                return true
            end
        end
    end
    return false
end

function grapple.return_grapple(p_name,grapple_id)
    local player = minetest.get_player_by_name(p_name)
    if player then
        local inv = player:get_inventory()
        local list = inv:get_list("main")
        local cont = true
        for k,v in pairs(list) do
            if not cont then return end
            if v:get_name() == "grapple:grapple_unloaded" then 
                local meta = v:get_meta()
                if meta:get_int("id") == grapple_id then
                    inv:set_stack("main", k, "grapple:grapple")
                    cont = false
                end
            end
        end        
    end

    -- remove grapple data after returning the loaded grapple
    if grapple.players[p_name] then
        for idx,grappledata in ipairs(grapple.players[p_name].grapples) do
            if grappledata.id == grapple_id then
                table.remove(grapple.players[p_name].grapples,idx)
            end
        end
    end

end


function grapple.midpoint(p1,p2)
    return vector.new((p1.x+p2.x)/2, (p1.y+p2.y)/2, (p1.z+p2.z)/2)
end


function grapple.rightclick_unloaded(itemstack, placer)
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

-- k: spring constant of rope, may be arbitrary. Larger values mean a spring that is harder to stretch, so lag will cause greater force to be applied.
-- deltal = abs of difference between natural length of rope and actual length of rope. Should be 0 if actual length is smaller than natural length
-- rhat: direction vector (unit vector) of the direction from current point to target point. 
-- m: assumed mass of the object m may be arbitrary
-- g: gravity vector (should normally be vector.new(0,-9.8,0)) 

-- returns acc, a vector to apply accelleration to the object

grapple.get_acc = function(k,deltal,rhat,m,g)
    local springforce = vector.multiply(rhat, k*deltal)
    local f_of_g = vector.multiply(g, m)
    local net_force = vector.add(springforce,f_of_g)
    local acc = vector.multiply(net_force, 1/m)
    return acc
end