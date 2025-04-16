local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)
local S = minetest.get_translator(minetest.get_current_modname())


minetest.register_craftitem("sum_airship:canvas_roll", {
	description = S("Canvas Roll"),
	_doc_items_longdesc = S("Used in crafting airships."),
	inventory_image = "sum_airship_canvas.png",
	stack_max = 64,
	groups = { craftitem = 1 },
})
minetest.register_craftitem("sum_airship:hull", {
	description = S("Airship Hull"),
	_doc_items_longdesc = S("Used in crafting airships."),
	inventory_image = "sum_airship_hull.png",
	stack_max = 1,
	groups = { craftitem = 1 },
})

if minetest.get_modpath("mcl_boats")
and minetest.get_modpath("mcl_wool")
and minetest.get_modpath("mcl_core")
and minetest.get_modpath("mcl_mobitems") then
    dofile(mod_path .. "/crafting_mcl.lua")
elseif (minetest.get_modpath("rp_farming")
or minetest.get_modpath("rp_mobs_mobs"))
and minetest.get_modpath("rp_default")
and minetest.get_modpath("rp_crafting") then
    dofile(mod_path .. "/crafting_rp.lua")
elseif minetest.get_modpath("default") then
    dofile(mod_path .. "/crafting_mtg.lua")
end
