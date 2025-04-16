local storage = airutils.storage
airutils.modname = core.get_current_modname()

--function to format formspec for mineclone. In case of minetest, just returns an empty string
function airutils.get_itemslot_bg(a, b, c, d)
    if mcl_formspec then
        return mcl_formspec.get_itemslot_bg(a,b,c,d)
    end
    return ""
end

local function get_formspec_by_size(self, size)
    local background = ""
    local hotbar = ""
    local is_minetest_game = airutils.is_minetest or false
    if is_minetest_game then
        background = background .. default.gui_bg .. default.gui_bg_img .. default.gui_slots
        hotbar = default.get_hotbar_bg(0,4.85)
    end
    local default_inventory_formspecs = {
	    ["2"]="size[8,6]".. background ..
	    "list[detached:" .. self._inv_id .. ";main;3.0,0;3,1;]" .. airutils.get_itemslot_bg(3.0, 0, 2, 1) ..
	    "list[current_player;main;0,2;8,4;]" .. airutils.get_itemslot_bg(0, 2, 8, 4) ..
	    "listring[]",

	    ["3"]="size[8,6]".. background ..
	    "list[detached:" .. self._inv_id .. ";main;2.5,0;3,1;]" .. airutils.get_itemslot_bg(2.5, 0, 3, 1) ..
	    "list[current_player;main;0,2;8,4;]" .. airutils.get_itemslot_bg(0, 2, 8, 4) ..
	    "listring[]",

	    ["4"]="size[8,6]".. background ..
	    "list[detached:" .. self._inv_id .. ";main;2,0;4,1;]" .. airutils.get_itemslot_bg(2.0, 0, 4, 1) ..
	    "list[current_player;main;0,2;8,4;]" .. airutils.get_itemslot_bg(0, 2, 8, 4) ..
	    "listring[]",

	    ["6"]="size[8,6]".. background ..
	    "list[detached:" .. self._inv_id .. ";main;1,0;6,1;]".. airutils.get_itemslot_bg(1.0, 0, 6, 1) ..
	    "list[current_player;main;0,2;8,4;]" .. airutils.get_itemslot_bg(0, 2, 8, 4) ..
	    "listring[]",

	    ["8"]="size[8,6]".. background ..
	    "list[detached:" .. self._inv_id .. ";main;0,0;8,1;]".. airutils.get_itemslot_bg(0, 0, 8, 1) ..
	    "list[current_player;main;0,2;8,4;]" .. airutils.get_itemslot_bg(0, 2, 8, 4) ..
	    "listring[]",

	    ["12"]="size[8,7]".. background ..
	    "list[detached:" .. self._inv_id .. ";main;1,0;6,2;]".. airutils.get_itemslot_bg(1, 0, 6, 2) ..
	    "list[current_player;main;0,3;8,4;]" .. airutils.get_itemslot_bg(0, 3, 8, 4) ..
	    "listring[]",

	    ["16"]="size[8,7]".. background ..
	    "list[detached:" .. self._inv_id .. ";main;0,0;8,2;]".. airutils.get_itemslot_bg(0, 0, 8, 2) ..
	    "list[current_player;main;0,3;8,4;]" .. airutils.get_itemslot_bg(0, 3, 8, 4) ..
	    "listring[]",

	    ["24"]="size[8,8]".. background ..
	    "list[detached:" .. self._inv_id .. ";main;0,0;8,3;]"..  airutils.get_itemslot_bg(0, 0, 8, 3) ..
	    "list[current_player;main;0,4;8,4;]" .. airutils.get_itemslot_bg(0, 4, 8, 4) ..
	    "listring[]",

	    ["32"]="size[8,9]".. background ..
	    "list[detached:" .. self._inv_id .. ";main;0,0.3;8,4;]".. airutils.get_itemslot_bg(0, 0.3, 8, 4) ..
	    "list[current_player;main;0,5;8,4;]".. airutils.get_itemslot_bg(0, 5, 8, 4) ..
	    "listring[]" ..
	    hotbar,

	    ["50"]="size[10,10]".. background ..
	    "list[detached:" .. self._inv_id .. ";main;0,0;10,5;]".. airutils.get_itemslot_bg(0, 0, 10, 5) ..
	    "list[current_player;main;1,6;8,4;]" .. airutils.get_itemslot_bg(1, 6, 8, 4) ..
	    "listring[]",
    }

	local formspec = default_inventory_formspecs[tostring(size)]
	return formspec
end

local function inventory_id(maker_name)
	local id= airutils.modname .. "_" .. maker_name .. "_"
	for i=0,5 do
		id=id..(math.random(0,9))
	end
	return id
end

function airutils.load_inventory(self)
	if self._inv then
		local inv_content = core.deserialize(storage:get_string(self._inv_id))
        if inv_content then
		    self._inv:set_list("main", inv_content)
        end
	end
end

function airutils.save_inventory(self)
    if self._inv then
	    local inv_content = self._inv:get_list("main")
        if inv_content then
	        for k, v in pairs(inv_content) do
		        inv_content[k] = v:to_string()
	        end

	        local inv_content = core.serialize(inv_content)
	        storage:set_string(self._inv_id, inv_content)
        end
    end
end

function airutils.remove_inventory(self)
    local inventory = airutils.get_inventory(self)
    if inventory then
        if inventory:is_empty("main") then
	        return core.remove_detached_inventory(self._inv_id)
        else
            local inv_content = inventory:get_list("main")
            if inv_content then
                local pos = self.object:get_pos()
                for k, v in pairs(inv_content) do
                    local count = 0
                    for i = 0,v:get_count()-1,1
                    do
                        core.add_item({x=pos.x+math.random()-0.5,y=pos.y,z=pos.z+math.random()-0.5},v:get_name())
                        count = count + 1
                        if count >= 5 then break end
                    end
                end
            end
            return core.remove_detached_inventory(self._inv_id)
        end
    end
    return false
end

function airutils.destroy_inventory(self)
    airutils.remove_inventory(self)
    storage:set_string(self._inv_id, nil)
end

--show inventory form to user
function airutils.show_vehicle_trunk_formspec(self, player, size)
    local form = get_formspec_by_size(self, size)
    core.show_formspec(player:get_player_name(), airutils.modname .. ":inventory",
        form
    )
end

function airutils.create_inventory(self, size, owner)
    owner = owner or ""
    if owner == "" then owner = self.owner end
    --core.chat_send_all("slots: " .. size)
    if owner ~= nil and owner ~= "" then
        if self._inv_id == "" then
            self._inv_id = inventory_id(owner)
        end
        local vehicle_inv = core.create_detached_inventory(self._inv_id, {
            allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
                local is_moderator = core.check_player_privs(player, {server=true}) or core.check_player_privs(player, {protection_bypass=true})
                if player:get_player_name() ~= owner and is_moderator == false then
                    return 0
                end
                return count -- allow moving
            end,

            allow_put = function(inv, listname, index, stack, player)
                local is_moderator = core.check_player_privs(player, {server=true}) or core.check_player_privs(player, {protection_bypass=true})
                if player:get_player_name() ~= owner and is_moderator == false then
                    return 0
                end
                return stack:get_count() -- allow putting
            end,

            allow_take = function(inv, listname, index, stack, player)
                local is_moderator = core.check_player_privs(player, {server=true}) or core.check_player_privs(player, {protection_bypass=true})
                if player:get_player_name() ~= owner and is_moderator == false then
                    return 0
                end
                return stack:get_count() -- allow taking
            end,
	        on_put = function(inv, toList, toIndex, stack, player)
                airutils.save_inventory(self)
	        end,
	        on_take = function(inv, toList, toIndex, stack, player)
                airutils.save_inventory(self)
	        end,
            on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
                airutils.save_inventory(self)
            end,
        }, owner)
        if size >= 8 then
            if vehicle_inv:set_size("main", size) then
	            vehicle_inv:set_width("main", 8)
            end
        else
            vehicle_inv:set_size("main", size)
        end
	    self._inv = vehicle_inv
        airutils.load_inventory(self)
    end
end

function airutils.get_inventory(self)
    if self._inv then
        return core.get_inventory({type="detached", name=self._inv_id})
    end
    return nil
end

function airutils.list_inventory(self)
    local inventory = airutils.get_inventory(self)
    if inventory then
        local list = inventory.get_list("main")

        core.chat_send_all(dump(list))
    end
end

