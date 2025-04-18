
hover = {}
hover.modname = core.get_current_modname()
hover.modpath = core.get_modpath(hover.modname)

dofile(hover.modpath .. "/settings.lua")
dofile(hover.modpath .. "/hover.lua")


local S = core.get_translator("hovercraft")

local hover_colors = {
	red = {
		max_speed = 10,
		jump_vel = 4.0,
		fall_vel = 1.0,
		bounce = 0.5,
	},
	blue = {
		max_speed = 12,
		decel = 0.1,
		jump_vel = 4.0,
		fall_vel = 1.0,
		bounce = 0.8,
	},
	green = {
		decel = 0.15,
		jump_vel = 5.5,
		fall_vel = 1.5,
		bounce = 0.5,
	},
	yellow = {},
}


if core.settings:get_bool("hovercraft.extended_colors", true) then
	for _, color in ipairs({"white", "black", "grey", "dark_grey", "cyan",
			"orange", "brown", "pink", "magenta", "violet", "dark_green"}) do
		hover_colors[color] = {
			max_speed = 12,
			accel = 0.25,
			decel = 0.05,
			jump_vel = 3.0,
			fall_vel = 0.5,
			bounce = 0.25,
		}
	end
end


for color, c_def in pairs(hover_colors) do
	local title = ""
	local whitespace = true
	for idx=1, #color do
		local c = color:sub(idx, idx)
		if whitespace then
			c = c:upper()
			whitespace = false
		end

		if c == "_" then
			c = " "
			whitespace = true
		end

		title = title .. c
	end

	hover:register_hovercraft(":hovercraft:hover_" .. color, {
		description = S(title .. " Hovercraft"),
		textures = {"hovercraft_" .. color .. ".png"},
		inventory_image = "hovercraft_" .. color .. "_inv.png",
		max_speed = c_def.max_speed or 8,
		acceleration = c_def.accel or 0.25,
		deceleration = c_def.decel or 0.05,
		jump_velocity = c_def.jump_vel or 3.0,
		fall_velocity = c_def.fall_vel or 0.5,
		bounce = c_def.bounce or 0.25,
	})
end


local ing = {
	motor = core.registered_items["basic_materials:motor"]
		and "basic_materials:motor" or "",
	block = "default:steelblock",
	wool_base = "wool:black",
}

if core.registered_items[ing.block] and core.registered_items[ing.wool_base] then
	for color in pairs(hover_colors) do
		if core.registered_items["wool:" .. color] then
			core.register_craft({
				output = "hovercraft:hover_" .. color,
				recipe = {
					{"", ing.motor, ing.block},
					{"wool:" .. color, "wool:" .. color, "wool:" .. color},
					{ing.wool_base, ing.wool_base, ing.wool_base},
				},
			})
		end
	end
end
