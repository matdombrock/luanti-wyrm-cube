

-- grapple throwable

minetest.register_entity("grapple:grapple_throwable",{
    initial_properties = {
        visual = "mesh",
        mesh = "grapple.obj",
        physical = true,
        visual_size = {x=1,y=1},
        hp_max = 50,
        textures = {"grapple_black.png"},
        collisionbox = {-.25,-.25,-.25,.25,.25,.25},
        -- static_save = false,
    },
    _player = "",
    _timer = 0,
    _id = 0,
    _remove = false,
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        if puncher and self._timer > 1 then 
            if not(self._id) then self.object:remove() end
            grapple.return_grapple(self._player,self._id)
        end
    end,

    on_step = function(self,dtime,moveresult)

        if self._remove == true then self.object:remove() return end

        local player = minetest.get_player_by_name(self._player)

        if not player then self._remove = true return end

        self._timer = self._timer + dtime

        -- if self._timer > 0 

        if self._id == 0 then self._remove = true return end
        if not(grapple.players[self._player] ) then self._remove = true return end

        local id_found = false
        for _,grappledata in pairs(grapple.players[self._player].grapples) do
            if grappledata.id == self._id then
                id_found = true 
                
                grappledata.p1 = self.object:get_pos()
                grappledata.p2 = player:get_pos()
                if not grappledata.rope_spawned then
                    grappledata.rope_spawned = true
                    -- local mid = grapple.midpoint(grappledata.p1,grappledata.p2)
                    minetest.add_entity(grappledata.p1, "grapple:rope", minetest.write_json({
                        _player = self._player,
                        _id = self._id,
                    }))
                end

            end
        end

        if not id_found then self._remove = true return end






        -- handle collisions

        if moveresult and self._id ~= 0 then
            for _,collision in pairs(moveresult.collisions) do

                if collision.type == "object" then
                    -- hit object, attach the object to a solid grapple
                    -- check if the object is fleshy
                    local armour_groups = collision.object:get_armor_groups()
                    if (armour_groups.fleshy or 0) > 0 then
                        local meta = minetest.write_json({
                            _player = self._player,
                            _id = self._id,
                        })
                        local pos = collision.object:get_pos()
                        pos.y = pos.y + .3
                        local obj = minetest.add_entity(pos, "grapple:grapple_hook", meta)    
        
                        -- obj:set_attach(collision.object,nil,nil,nil,true)
                        collision.object:set_attach(obj,nil,nil,nil,true)

                        for _,grappledata in pairs(grapple.players[self._player].grapples) do
                            if grappledata.id == self._id then
                                grappledata.stuck = true
                                grappledata.type = "object"
                            end
                        end

                        self._remove = true
                        return

                    end
                end
                if collision.type == "node" then
                    local meta = minetest.write_json({
                        _player = self._player,
                        _id = self._id,
                    })
                    local pos = self.object:get_pos()
                    local obj = minetest.add_entity(pos, "grapple:grapple_hook", meta)    
                    obj:set_rotation(self.object:get_rotation())

                    for _,grappledata in pairs(grapple.players[self._player].grapples) do
                        if grappledata.id == self._id then
                            grappledata.stuck = true
                            grappledata.type = "node"
                        end
                    end

                    local meta = minetest.write_json({
                        _player = self._player,
                        _id = self._id,

                    })
                    local pos = player:get_pos()
                    local obj = minetest.add_entity(pos, "grapple:player_att", meta)  
                    player:set_attach(obj)

                    self._remove = true
                    return
                end
            end
        end


    end,

    on_activate = function( self, staticdata, dtime_s)
        if staticdata ~= "" and staticdata ~= nil then
            local data = minetest.parse_json(staticdata) or {}
            if data and data._player then 
                self._player = data._player
                self._id = data._id
            end
        end
    end,



})









-- solid grapple (hooked)

minetest.register_entity("grapple:grapple_hook",{
    initial_properties = {
        visual = "mesh",
        mesh = "grapple.obj",
        physical = true,
        visual_size = {x=1,y=1},
        hp_max = 50,
        textures = {"grapple_black.png"},
        collisionbox = {-.25,-.25,-.25,.25,.25,.25},
        stepheight = 1,

    },
    _player = "",
    _id = 0,
    _remove = false,
    _velocity = 0,
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        if puncher then 
            if not(self._id) then self.object:remove() end
            grapple.return_grapple(self._player,self._id)
            self._remove = true
        end
    end,

    on_step = function(self,dtime,moveresult)

        if self._remove == true then 
            self.object:remove() 
            return
        end

        if self._id == 0 then self.object:remove() return end

        if not(grapple.players[self._player] ) then self.object:remove() return end

        local player = minetest.get_player_by_name(self._player)
        if not player then self.object:remove() return end

        local id_found = false
        for _,grappledata in pairs(grapple.players[self._player].grapples) do

            if grappledata.id == self._id then
                id_found = true 

                if grappledata.type and grappledata.type == "node" then
                    grappledata.p1 = self.object:get_pos() -- p1 is the target
                    grappledata.p2 = player:get_pos() -- p2 is the object to move
                end
                if grappledata.type and grappledata.type == "object" then
                    grappledata.p1 = player:get_pos() -- p1 is the target
                    grappledata.p2 = self.object:get_pos() -- p2 is the object to move
                end

                if grappledata.type and grappledata.type == "object" then
                    grappledata.length_n = grappledata.length_n or vector.distance(grappledata.p1,grappledata.p2)
                    local len_real = vector.distance(grappledata.p1, grappledata.p2)
                    grappledata.pull_vel = grappledata.pull_vel or 0 -- m/s

                    -- set the new natural length
                    if grappledata.length_n > 0 then
                        grappledata.length_n = grappledata.length_n - grappledata.pull_vel * dtime -- s cancel, leaving m
                    end
                    local deltal =  len_real - grappledata.length_n 

                    if deltal < 0 then 
                        deltal = 0
                    else 
                        -- cap speed if the deltal is too long 
                        if deltal > 1.5 and self._old_len < len_real then 
                            local vel = self.object:get_velocity()
                            local mag = vector.length(vel)
                            local unit_vel = vector.normalize(vel)
                            self.object:set_velocity(vector.multiply(vel,mag/10))
                        end

                    end
                    self._old_len = len_real 

                    -- break the line if it is too long
                    if len_real > 30 then
                        grapple.return_grapple(self._player,grappledata.id)
                    end

                    local p_pos = grappledata.p2

                    -- determine the acceleration to set
                    

                    local k = 40 -- rope spring constant
                    local rhat = vector.direction(p_pos,grappledata.p1)
                    local m = 60 -- in kg, assumed
                    local p_gravity = player:get_physics_override().gravity
                    local g = vector.new(0,-1*p_gravity,0)
                    local max_a = 5

                    local acc = grapple.get_acc(k,deltal,rhat,m,g)
                    self.object:set_acceleration(acc)
                end



                if grappledata.pull == true then
                    if grappledata.type and grappledata.type == "object" then
                        grappledata.pull = false
                        grappledata.pull_timer = 2 -- timeout
                        -- attached to a node to pull player towards

                        grappledata.pull_vel = grappledata.pull_vel + 3 -- m/s

                        self._target = grappledata.p1

                    end
                end

                
            end
        end

        if not id_found then self.object:remove() return end
        

    end,

    on_activate = function( self, staticdata, dtime_s)
        if staticdata ~= "" and staticdata ~= nil then
            local data = minetest.parse_json(staticdata) or {}
            if data and data._player then 
                self._player = data._player
                self._id = data._id
            end
        end      
    end,



})





-- rope entity

minetest.register_entity("grapple:rope",{
    initial_properties = {
        visual = "mesh",
        mesh = "grapple_rope_2.b3d",
        physical = false,
        immortal = true,
        hp_max = 32,
        textures = {"blank.png"},
        collisionbox = {-.1,-.1,-.1,.1,.1,.1},
        static_save = false,
    },
    
    _player = "",
    _id = 0,
    _timer = 0,

    on_activate = function( self, staticdata, dtime_s)
        if staticdata ~= "" and staticdata ~= nil then
            local data = minetest.parse_json(staticdata) or {}
            if data and data._player then 
                self._player = data._player
                self._id = data._id
            end
        end
    end,

    on_step = function(self,dtime)
        self._timer = self._timer + dtime
        if self._timer > .5 then
            self.object:set_properties({textures={"grapple_black.png"}})
        end
        if not self._player then self.object:remove() return end
        if not self._id then self.object:remove() return end
        if not grapple.players[self._player] then self.object:remove() return end
        

        local id_found = false
        for _,grappledata in pairs(grapple.players[self._player].grapples) do
            if grappledata.id == self._id then
                id_found = true 
                
                if grappledata.p1 then
                    self:_set_orientation(grappledata.p1,grappledata.p2)
                end

            end
        end

        if not id_found then self.object:remove() return end
    end,

    _set_orientation = function(self,p1,p2)
        p2 = vector.add(p2, vector.new(.3,.75,0))
        local rot = vector.dir_to_rotation(vector.direction(p1, p2))
        self.object:set_pos(p1)
        self.object:set_rotation(rot)
        self.object:set_properties({
            visual_size = {x = 6, z = 10 * vector.distance(p2, p1), y = 6}
        })

    end
})



-- attachment for players to ride
minetest.register_entity("grapple:player_att",{
    initial_properties = {
        visual = "sprite",
        physical = true,
        hp_max = 32,
        textures = {"blank.png"},
        collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
        stepheight = 1,
        pointable = false,
    },
    
    _player = "",
    _id = 0,
    _target = nil,
    _old_len = 0,

    on_activate = function( self, staticdata, dtime_s)
        if staticdata ~= "" and staticdata ~= nil then
            local data = minetest.parse_json(staticdata) or {}
            if data and data._player then 
                self._player = data._player
                self._id = data._id
            end
        end
    end,



    on_step = function(self,dtime)
        if not self._player then self.object:remove() return end
        if not self._id then self.object:remove() return end
        if not grapple.players[self._player] then self.object:remove() return end
        local player = minetest.get_player_by_name(self._player)
        if not player then self.object:remove() return end
        local id_found = false
        for _,grappledata in pairs(grapple.players[self._player].grapples) do
            if grappledata.id == self._id then
                if grappledata.type and grappledata.type == "node" then
                    id_found = true 

                    grappledata.length_n = grappledata.length_n or vector.distance(grappledata.p1,grappledata.p2)
                    local len_real = vector.distance(grappledata.p1, grappledata.p2)
                    grappledata.pull_vel = grappledata.pull_vel or 0 -- m/s

                    -- set the new natural length
                    if grappledata.length_n > 0 then
                        grappledata.length_n = grappledata.length_n - grappledata.pull_vel * dtime -- s cancel, leaving m
                    end
                    local deltal =  len_real - grappledata.length_n 

                    if deltal < 0 then 
                        deltal = 0
                    else 
                        -- cap speed if the deltal is too long 
                        if deltal > 1.5 and self._old_len < len_real then 
                            local vel = self.object:get_velocity()
                            local mag = vector.length(vel)
                            local unit_vel = vector.normalize(vel)
                            self.object:set_velocity(vector.multiply(vel,mag/10))
                        end

                    end
                    self._old_len = len_real 
                    

                    -- allow players to offset their mass to steer a bit, or start swinging

                    local p_pos = grappledata.p2

                    local controls = player:get_player_control()
                    local look = player:get_look_dir()
                    look.y = 0
                    look = vector.dir_to_rotation(look)

                    local n_offset = vector.zero()
                    local plus = .3
                    if controls.up then
                        n_offset.z = n_offset.y + plus
                    end
                    if controls.down then 
                        n_offset.z = n_offset.y - plus 
                    end
                    if controls.left then
                        n_offset.x = n_offset.x - plus 
                    end
                    if controls.right then
                        n_offset.x = n_offset.x + plus 
                    end

                    n_offset = vector.rotate(n_offset,look)

                    p_pos = vector.add(p_pos,n_offset)

                    -- determine the acceleration to set
                    

                    local k = 40 -- rope spring constant
                    local rhat = vector.direction(p_pos,grappledata.p1)
                    local m = 60 -- in kg, assumed
                    local p_gravity = player:get_physics_override().gravity
                    local g = vector.new(0,-1*p_gravity,0)
                    local max_a = 5

                    local acc = grapple.get_acc(k,deltal,rhat,m,g)
                    self.object:set_acceleration(acc)

                end


                if grappledata.pull == true then
                    if grappledata.type and grappledata.type == "node" then
                        grappledata.pull = false
                        grappledata.pull_timer = 2 -- timeout
                        -- attached to a node to pull player towards

                        grappledata.pull_vel = grappledata.pull_vel + 3 -- m/s

                        self._target = grappledata.p1

                    end
                end

                
            end
        end

        if not id_found then self.object:remove() return end

    end,

})