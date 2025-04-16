grapple = {}

grapple.players = {}

local path = minetest.get_modpath("grapple")

dofile(path.."/api.lua")
dofile(path.."/entities.lua")
dofile(path.."/items.lua")




-- handle returning grapples to players
local t = 0
minetest.register_globalstep(function(dtime)
    for pl_name,p_data in pairs(grapple.players) do 
        if p_data.grapples then


            for _,grappledata in pairs(p_data.grapples) do

                grappledata.timer = grappledata.timer + dtime
                if grappledata.pull_timer > 0 then 
                    grappledata.pull_timer = grappledata.pull_timer - dtime
                    if grappledata.pull_timer < 0 then
                        grappledata.pull_timer = 0
                        grappledata.pull = false
                    end
                end

                if grappledata.recall or (grappledata.timer > 10 and grappledata.stuck == false) then
                    -- return loaded grapple 
                    grapple.return_grapple(pl_name,grappledata.id)
                end
            end

        end
    end

    -- every second, check if the player is selecting the grapple, if not, recall it. 

    t = t + dtime
    if t > 1 then
        t = 0
        for pl_name,p_data in pairs(grapple.players) do 
            
            for _,grappledata in pairs(p_data.grapples) do
                if grappledata.recall == false then
                    local player = minetest.get_player_by_name(pl_name)
                    local inv = player:get_inventory()
                    local selected = player:get_wield_index()
                    local list = inv:get_list("main")

                    local sel_item = list[selected]
                    local sel_item_meta = sel_item:get_meta()

                    if sel_item_meta:get_int("id") ~= grappledata.id then
                        grappledata.recall = true
                    end
                end
            end
        end
    end


end)

minetest.register_on_joinplayer(function(player, last_login)
    local p_name = player:get_player_name()
    grapple.players[p_name] = {}
    grapple.players[p_name].grapples = {}
end)

minetest.register_on_leaveplayer(function(player, timed_out)
    local p_name = player:get_player_name()
    grapple.players[p_name] = nil
end)