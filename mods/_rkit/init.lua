local modpath = core.get_modpath(core.get_current_modname())

-- Required
dofile(modpath .. "/src/main.lua") -- Load the main Rkit module
dofile(modpath .. "/src/static.lua")

-- Optional
dofile(modpath .. "/src/structures.lua")
dofile(modpath .. "/src/cmd.lua")

-- Experimental
dofile(modpath .. "/src/lab.lua")
dofile(modpath .. "/src/dungeon.lua")
