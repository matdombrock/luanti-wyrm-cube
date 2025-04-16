
-- Slimes by TomasJLuis
-- Migration to Mobs Redo API by TenPlus1

-- get path and translator

local path = minetest.get_modpath("mobs_slimes")
local S = minetest.get_translator("mobs_slimes")

-- load mod files

dofile(path .. "/greenslimes.lua")
dofile(path .. "/lavaslimes.lua")

-- cannot find mesecons?, craft glue instead
if not minetest.get_modpath("mesecons_materials") then

	minetest.register_craftitem(":mesecons_materials:glue", {
		image = "jeija_glue.png",
		description = S("Glue")
	})
end

print("[MOD] Mobs Redo Slimes loaded")
