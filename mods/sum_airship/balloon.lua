local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)

local me = {
	lift = 4,
	speed = 4,
	fuel_time = 10,
	speed_mult = 4,
	i = {},
}

local ship = {
	initial_properties = {
		physical = true,
		pointable = true,
		collisionbox = {-0.6, -0.2, -0.6, 0.6, 0.4, 0.6},
		selectionbox = {-0.7, -0.35, -0.7, 0.7, 0.4, 0.7},
		hp_max = 3,
		visual = "mesh",
		backface_culling = true,
		mesh = "sum_airship.b3d",
		textures = {"sum_airship_texture.png"},
	},
	_animations = {
		idle = {x=  10, y= 90},
		fly = {x=  91, y= 170},
		boost = {x=  91, y= 170},
	},
	_driver = nil,
	_removed = false,
	_flags = {},
	_itemstring = "sum_airship:boat",
	_passenger = nil,
	_vel = 0,
	_regen_timer = 0,
	_fuel = 0,
}

local sounds = {
	engine_idle = {
		sound_name = "sum_airship_lip_trill",
		gain = 1.4,
		max_hear_distance = 10,
		loop = false,
		pitch = 0.75,
	},
	engine_stop = {
		sound_name = "sum_airship_lip_trill_end",
		gain = 2.2,
		max_hear_distance = 10,
		loop = false,
		pitch = 1,
	},
	engine_boost = {
		sound_name = "sum_airship_lip_trill",
		gain = 40,
		max_hear_distance = 10,
		loop = false,
		pitch = 1,
	},
}

function me.sound_play(self, sound_obj, sound_instance)
	sound_instance.handle = minetest.sound_play(sound_obj.sound_name, {
		gain = sound_obj.gain,
		max_hear_distance = sound_obj.max_hear_distance,
		loop = sound_obj.loop,
		pitch = sound_obj.pitch,
		object = self.object,
	})
	sound_instance.playing = true
	sound_instance.time_elapsed = 0
end

function me.sound_stop(sound_instance)
	if sound_instance.handle then
		minetest.sound_stop(sound_instance.handle)
	end
	sound_instance.playing = false
	sound_instance.time_elapsed = 0
	sound_instance.handle = nil
end

function me.sound_countdown(self, dtime)
	for _, sound in pairs(self._sounds) do
		if sound.playing then
			sound.time_elapsed = sound.time_elapsed + dtime
		end
	end
end

function me.update_sound(self, dtime, forward)
	me.sound_countdown(self, dtime)

	local is_thrust = (forward ~= 0) and self._driver

	if self._sounds.engine.time_elapsed > 2.1
	and self._sounds.engine.handle
	and self._sounds.engine.playing then
		me.sound_stop(self._sounds.engine)
	end
	if not self._sounds.engine.playing then
		if self._fuel > 1 then
			me.sound_play(self, sounds.engine_boost, self._sounds.engine)
		elseif is_thrust then
			me.sound_play(self, sounds.engine_idle, self._sounds.engine)
		end
		if self._fuel > 1 and self._sounds.engine_stop.playing then
			me.sound_stop(self._sounds.engine_stop)
		end
	end

	if self._fuel <= 1 and self._sounds.engine.playing then
		if self._fuel > 0 and not self._sounds.engine_stop.playing
		and self._sounds.engine_stop.time_elapsed == 0 then
			me.sound_play(self, sounds.engine_stop, self._sounds.engine_stop)
		end
		if not is_thrust
		or (self._sounds.engine_stop.time_elapsed == 0
		and self._sounds.engine_stop.playing) then
			me.sound_stop(self._sounds.engine)
		end
	end
end


function ship.on_activate(self, staticdata, dtime_s)
	local data = minetest.deserialize(staticdata)
	if type(data) == "table" then
		self._vel = data.v
		self._itemstring = data.itemstring
		self._fuel = data.fuel
		self._flags = data._flags
	end
	self.object:set_armor_groups({
		pierce=100,
		slash=100,
		blunt=100,
		magic=100,
		poison=100,
		fleshy=100,
	})
	self.object:set_animation(ship._animations.idle, 24)
	self._sounds = { -- workaround for copy vs reference issue
		engine = {
			handle = nil,
			gain = 0.1,
			playing = false,
			time_elapsed = 0,
		},
		engine_stop = {
			handle = nil,
			gain = 0.1,
			playing = false,
			time_elapsed = 0,
		},
	}
end

function ship.get_staticdata(self)
	return minetest.serialize({
		itemstring = self._itemstring,
		_flags = self._flags,
		v = self._vel,
		fuel = self._fuel,
	})
end

function me.attach(self, player)
	if not (player and player:is_player()) then
		return false
	end
	self._driver = player
	self._driver:set_attach(self.object, "",
		{x = 0, y = -0.0, z = -2}, {x = 0, y = 0, z = 0})
	self._driver:set_look_horizontal(self.object:get_yaw())
end

function me.detach(self)
	if not self._driver then return false end
	self._driver:set_detach()
	self._driver = nil
	return true
end


function ship.on_death(self, killer)
	if killer and killer:is_player()
	and not minetest.is_creative_enabled(killer:get_player_name()) then
		local inv = killer:get_inventory()
		inv:add_item("main", self._itemstring)
	else
		minetest.add_item(self.object:get_pos(), self._itemstring)
	end
	me.detach(self)
	self._driver = nil
end

function ship.on_rightclick(self, clicker)
	local item = clicker:get_wielded_item()
	local item_name = item:get_name()
	if clicker and (item and item_name)
	and (string.find(item_name, ":coal")
	or string.find(item_name, ":charcoal")) then
		if not minetest.is_creative_enabled(clicker:get_player_name()) then
			item:take_item()
			clicker:set_wielded_item(item)
		end
		self._fuel = self._fuel + me.fuel_time
		me.sound_stop(self._sounds.engine)
		minetest.sound_play("sum_airship_fire", {
			gain = 1,
			object = self.object,
		})
	else
		me.attach(self, clicker)
	end
end


-- 10, 5, 5
-- this system ensures collision kind of works with balloons.
-- does not include entity to entity collisions
local balloon = {}
balloon.offset = 6
balloon.length = 3.5
balloon.height = 2.5
local balloon_nodes = {}
balloon_nodes[0] = { -- top
	p = vector.new(0, balloon.offset + balloon.height, 0),
	dir = vector.new(0, -5, 0),}
balloon_nodes[1] = { -- front
	p = vector.new(0, balloon.offset, balloon.length),
	dir = vector.new(0, -0.5, -1),}
balloon_nodes[2] = { -- back
	p = vector.new(0, balloon.offset, -balloon.length),
	dir = vector.new(0, 0, 1),}
balloon_nodes[3] = { -- left or right
	p = vector.new(balloon.length, balloon.offset, 0),
	dir = vector.new(-1, 0, 0),}
balloon_nodes[4] = { -- left or right
	p = vector.new(-balloon.length, balloon.offset, 0),
	dir = vector.new(1, 0, 0),}
-- diagonals
local vdiag = 0.7
balloon_nodes[5] = {
	p = vector.new(-balloon.length*vdiag, balloon.offset, -balloon.length*vdiag),
	dir = vector.new(vdiag, 0, vdiag),}
balloon_nodes[6] = {
	p = vector.new(balloon.length*vdiag, balloon.offset, -balloon.length*vdiag),
	dir = vector.new(-vdiag, 0, vdiag),}
balloon_nodes[7] = {
	p = vector.new(-balloon.length*vdiag, balloon.offset, balloon.length*vdiag),
	dir = vector.new(vdiag, 0, -vdiag),}
balloon_nodes[8] = {
	p = vector.new(balloon.length*vdiag, balloon.offset, balloon.length*vdiag),
	dir = vector.new(-vdiag, 0, -vdiag),}

function me.get_balloon_collide(self)
	local force = vector.new()
	local o = self.object:get_pos()
	for _, check in pairs(balloon_nodes) do
		local n = minetest.get_node(vector.add(check.p, o))
		if n and minetest.registered_nodes[n.name]
		and (minetest.registered_nodes[n.name] or {}).walkable then
			force = vector.add(force, check.dir)
		end
	end
	return force
end

me.chimney_dist = -0.8
me.chimney_yaw = 0.13
me.chimney_height = 1.5
function me.get_chimney_pos(self)
	local p = self.object:get_pos()
	local yaw = self.object:get_yaw()
	local ret = {
	x = p.x + (me.chimney_dist * math.sin(-yaw + me.chimney_yaw)),
	y = p.y + me.chimney_height,
	z = p.z + (me.chimney_dist * math.cos(-yaw + me.chimney_yaw))}
	return ret
end

function ship.on_step(self, dtime, moveresult)
	local exit = false
	local pi = nil
	-- allow to exit
	if self._driver and self._driver:is_player() then
		local name = self._driver:get_player_name()
		pi = self._driver:get_player_control()
		exit = pi.aux1
	end
	if exit then
		me.detach(self)
		return false
	end

	local climb = 0
	local right = 0
	local forward = 0
	local v = self.object:get_velocity()
	local p = self.object:get_pos()
	local node_below = minetest.get_node(vector.offset(p, 0, -0.8, 0)).name
	local is_on_floor = (minetest.registered_nodes[node_below] or {}).walkable
	local in_water = minetest.get_item_group(minetest.get_node(p).name, "liquid") ~= 0
	local on_water = (minetest.get_item_group(minetest.get_node(vector.offset(p, 0, -0.2, 0)).name, "liquid") ~= 0 and not in_water)

	local speedboost = 1
	if self._fuel > 0 then
		self._fuel = self._fuel - dtime
		speedboost = 3
	end

	if pi then
		if pi.up then forward = 1
		elseif pi.down then forward = -1 end
		if pi.jump then climb = 1
		elseif pi.sneak then climb = -1 end
		if pi.right then right = 1
		elseif pi.left then right = -1 end

		local yaw = self.object:get_yaw()
		local dir = minetest.yaw_to_dir(yaw)
		self.object:set_yaw(yaw - right * dtime)
		local added_vel = vector.multiply(dir, forward * dtime * me.speed * speedboost)
		added_vel.y = added_vel.y + (climb * dtime * me.lift)
		v = vector.add(v, added_vel)
	end

	if self._driver then
		local collide_force = me.get_balloon_collide(self)
		if collide_force ~= vector.new() then
			collide_force = vector.multiply(collide_force, 0.1)
			v = vector.multiply(v, 0.95)
		end
		v = vector.add(v, collide_force)
	end

	if not self._driver then
		v.y = v.y - dtime
	end

	if minetest.get_modpath("sum_air_currents") then
		if self._driver or not is_on_floor then
			local wind_vel = sum_air_currents.get_wind(p)
			wind_vel = vector.multiply(wind_vel, dtime)
			v = vector.add(wind_vel, v)
		end
	end
	if in_water then
		v.y = 1
	elseif on_water and not self._driver then
		v.y = 0
	end

	if (not self._driver) and is_on_floor then
		v.x = v.x * 0.8
		v.y = v.y * 0.95
		v.z = v.z * 0.8
	else
		v.x = v.x * (0.98)
		v.y = v.y * (0.98)
		v.z = v.z * (0.98)
	end

	local wind_vel = vector.new(0,0,0)
	if minetest.get_modpath("sum_air_currents") ~= nil then
		wind_vel = sum_air_currents.get_wind(p)
		if self._driver or not is_on_floor then
			v = vector.add(wind_vel, v)
		end
	end


	self.object:set_velocity(v)

	me.update_sound(self, dtime, forward)


	local is_thrust = self._driver and forward ~= 0

	local chimney_pos = me.get_chimney_pos(self)

	local spread = 0.06
	if self._fuel > 0 or (math.random(0,100) > 80 and is_thrust) or math.random(0,100) > 95 then
		minetest.add_particle({
			pos = vector.offset(chimney_pos, math.random(-1, 1)*spread, 0, math.random(-1, 1)*spread),
			velocity = vector.add(wind_vel, {x=0, y=math.random(0.2*100,0.7*100)/100, z=0}),
			expirationtime = math.random(0.5, 2),
			size = math.random(0.1, 4),
			collisiondetection = false,
			vertical = false,
			texture = "sum_airship_smoke.png",
		})
	end
	-- animations
	if self._fuel > 0 then
		self.object:set_animation(self._animations.boost, 25)
	elseif is_thrust then
		self.object:set_animation(self._animations.fly, 25)
	else
		self.object:set_animation(self._animations.idle, 25)
	end
end


minetest.register_entity("sum_airship:boat", ship)

minetest.register_craftitem("sum_airship:boat", {
	description = "Airship",
	inventory_image = "sum_airship.png",
	groups = { vehicle = 1, airship = 1, transport = 1},
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end
		local node = minetest.get_node(pointed_thing.under)
		if placer and not placer:get_player_control().sneak then
			local def = minetest.registered_nodes[node.name]
			if def and def.on_rightclick then
				return def.on_rightclick(pointed_thing.under, node, placer, itemstack) or itemstack
			end
		end
		local pos = vector.offset(pointed_thing.above, 0, 0, 0)
		local self = minetest.add_entity(pos, "sum_airship:boat"):get_luaentity()
		if not minetest.is_creative_enabled(placer:get_player_name()) then
			itemstack:take_item()
		end
		return itemstack
	end,
})


-- Support SilverSandstone's subtitles mod:
if minetest.get_modpath("subtitles") then
	subtitles.register_description('sum_airship_lip_trill',     'Engine purring');
	subtitles.register_description('sum_airship_lip_trill_end', 'Engine sputtering');
	subtitles.register_description('sum_airship_fire',          'Engine stoked');
end
