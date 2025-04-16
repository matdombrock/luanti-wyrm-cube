-- map/init.lua

-- Mod global namespace

map = {}


-- Load support for MT game translation.
local S = minetest.get_translator("map")


-- Update HUD flags
-- Global to allow overriding

function map.update_hud_flags(player)
	local creative_enabled = minetest.is_creative_enabled(player:get_player_name())

	local minimap_enabled = creative_enabled or
	player:get_inventory():contains_item("main", "wyrm_gps:gps")
	local radar_enabled = creative_enabled

	player:hud_set_flags({
		minimap = minimap_enabled,
		minimap_radar = radar_enabled
	})
end


-- Set HUD flags 'on joinplayer'

minetest.register_on_joinplayer(function(player)
	map.update_hud_flags(player)
end)


-- Cyclic update of HUD flags

local function cyclic_update()
	for _, player in ipairs(minetest.get_connected_players()) do
		map.update_hud_flags(player)
	end
	minetest.after(5.3, cyclic_update)
end

minetest.after(5.3, cyclic_update)


-- Mapping kit item

minetest.register_craftitem("wyrm_gps:gps", {
	description = S("GPS Kit") .. "\n" .. S("Use with 'Minimap' key"),
	inventory_image = "wc_gps.png",
	stack_max = 1,
	groups = {tool = 1},
	light_source = 14, -- Maximum light level is 14 in Minetest
	paramtype = "light", -- Required for light emission
	sunlight_propagates = true, -- Allows light to pass through
	glow = 10,

	on_use = function(itemstack, user, pointed_thing)
		map.update_hud_flags(user)

		local bg_hud_id = user:hud_add({
			hud_elem_type = "image",
			position = {x = 0.5, y = 0.1}, -- Centered at the top of the screen
			offset = {x = 0, y = 0},
			scale = {x = 650, y = 100}, -- Adjust scale for the size of the block
			alignment = {x = 0, y = 0},
			text = "ui_bg.png", -- A black texture (you need to include this in your mod)
		})
		-- Add HUD text
		local pos = user:get_pos()
		local hud_id = user:hud_add({
			hud_elem_type = "text", -- HUD element type
			position = {x = 0.5, y = 0.1}, -- Centered at the top of the screen
			offset = {x = 0, y = 0}, -- No additional offset
			text = 'X: ' .. math.floor(pos.x) .. ' Y: ' .. math.floor(pos.y) .. ' Z: ' .. math.floor(pos.z), -- The text to display
			alignment = {x = 0, y = 0}, -- Center alignment
			scale = {x = 100, y = 100}, -- Scale for larger text
			size = {x = 2, y = 0}, -- No size limit
			style = 1, -- Style for the text
			number = 0xFFFF99, --  color in hexadecimal (RGB)
		})
		minetest.after(5, function()
			user:hud_remove(hud_id) -- Remove the text after 5 seconds
			user:hud_remove(bg_hud_id) -- Remove the background after 5 seconds
		end)
	end,
})

