local mod_name = minetest.get_current_modname()
local mod_path = minetest.get_modpath(mod_name)

dofile(mod_path .. DIR_DELIM .. "balloon.lua")
dofile(mod_path .. DIR_DELIM .. "crafts.lua")
