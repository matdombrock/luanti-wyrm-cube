core.register_node("_rkit:scaffold", {
	description = "Scaffolding",
	tiles = { "scaffold.png" },
	is_ground_content = false,
	light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	glow = 10,
	drawtype = "glasslike", -- Allows transparency and gives a glass-like appearance
})

Rkit_structures = {}

function Rkit_structures.auto_room(main_layers, width, length, height, opt)
	if opt.floor_str == nil then
		opt.floor_str = "s"
	end
	if opt.ceiling_str == nil then
		opt.ceiling_str = "w"
	end
	if opt.wall_str == nil then
		opt.wall_str = "s"
	end
	if opt.air_str == nil then
		opt.air_str = "."
	end
	if opt.doors == nil then
		opt.doors = { "d", "D" }
	end
	if opt.lights == nil then
		opt.lights = { "t", "T" }
	end
	if opt.light_layer == nil then
		opt.light_layer = 2
	end

	local make_layer = function(node_str)
		local new_layer = ""
		for z = 1, length do
			for x = 1, width do
				new_layer = new_layer .. node_str .. " "
			end
			new_layer = new_layer .. "\n"
		end
		return new_layer
	end

	local sub_doors = function(layer, replace)
		local new_layer = layer
		for _, str in pairs(opt.doors) do
			new_layer = string.gsub(new_layer, str, replace)
		end
		return new_layer
	end

	local sub_lights = function(layer, replace)
		local new_layer = layer
		for _, str in pairs(opt.lights) do
			new_layer = string.gsub(new_layer, str, replace)
		end
		return new_layer
	end

	local bp = {}
	local floor_layer = make_layer(opt.floor_str)
	table.insert(bp, floor_layer)

	for y = 1, height do
		local layer = main_layers[#main_layers]
		if y < #main_layers then
			layer = main_layers[y]
		end
		if y == 2 then
			layer = sub_doors(layer, opt.air_str)
		end
		if y > 2 then
			layer = sub_doors(layer, opt.wall_str)
		end
		if y ~= opt.light_layer then
			layer = sub_lights(layer, opt.air_str)
		end
		table.insert(bp, layer)
	end

	local ceiling_layer = make_layer(opt.ceiling_str)
	table.insert(bp, ceiling_layer)

	return bp
end

-- https://api.luanti.org/nodes/#node-paramtypes
function Rkit_structures.rotate_to_wallmounted(rotate)
	rotate = rotate % 4
	-- local rot_map = { 4, 2, 5, 3 }
	local rot_map = { 5, 3, 4, 2 }
	local out = rot_map[rotate + 1]
	return out
end

function Rkit_structures.rotate_to_facedir(rotate)
	rotate = rotate % 4
	-- No rot map, maps directly
	local out = rotate
	return out
end

function Rkit_structures.contruction(origin, bom, bp, callback, opt)
	if opt.speed == nil then
		opt.speed = 1
	end
	if opt.force_build == nil then
		opt.force_build = true
	end
	if opt.pre_clear == nil then
		opt.pre_clear = true
	end
	if opt.auto_emerge == nil then
		opt.auto_emerge = true
	end
	if opt.build_order == nil then
		opt.build_order = "blocks"
	end
	if opt.scaffold == nil then
		opt.scaffold = true
	end
	if opt.scaffold_block == nil then
		opt.scaffold_block = "_rkit:scaffold"
	end
	if opt.degradation == nil then
		opt.degradation = 0
	end
	if opt.degradation_block == nil then
		opt.degradation_block = "air"
	end
	if opt.rotate == nil then
		opt.rotate = 0
	end

	if type(bp) ~= "table" then
		error("Expected 'bp' to be a table, got " .. type(bp))
	end

	-- Rotate construction layer 90 degrees clockwise
	local function rotate_construction_layer(input)
		local lines = {}
		for line in input:gmatch("[^\n]+") do
			table.insert(lines, line)
		end

		local rotated = {}
		local num_rows = #lines
		local num_cols = #lines[1]:gsub(" ", "") -- Count non-space characters

		for col = 1, num_cols do
			local new_row = {}
			for row = num_rows, 1, -1 do
				table.insert(new_row, lines[row]:sub(col * 2 - 1, col * 2 - 1)) -- Extract character
			end
			table.insert(rotated, table.concat(new_row, " "))
		end

		return table.concat(rotated, "\n")
	end

	-- Init build record
	local build_record = {}
	for key, _ in pairs(bom) do
		build_record[key] = {}
	end

	local height = #bp

	local pending = 0
	local place_node = function(pos, block)
		local ctx = { block = block }
		local emerge_cb = function(pos_target, action, num_calls_remaining, context)
			core.set_node(pos, context.block)
			pending = pending - 1
			if (pending == 0) and callback then
				callback(build_record)
			end
		end
		if opt.auto_emerge then
			core.emerge_area(pos, pos, emerge_cb, ctx)
		else
			core.set_node(pos, block)
			pending = pending - 1
			if (pending == 0) and callback then
				callback(build_record)
			end
		end
	end

	local default_block = { name = "default:stone" }

	-- Construction loop
	for y, layer in ipairs(bp) do
		-- Always rotate once to align with expected north
		layer = rotate_construction_layer(layer)
		for _ = 1, opt.rotate do
			layer = rotate_construction_layer(layer)
		end
		local split_rows = Rkit:string_split(layer, "\n")
		local width = #split_rows
		for x, row in ipairs(split_rows) do
			local split_vals = Rkit:string_split(row)
			local length = #split_vals
			local layer_area = width * length
			for z, value in ipairs(split_vals) do
				local block = table.copy(bom[value]) or table.copy(default_block)

				-- Handle degradation
				-- Degradation increases with height
				if block.name ~= "air" then
					local h_norm = (y / height)
					local deg_chance = opt.degradation * h_norm
					if math.random() < deg_chance then
						block = { name = opt.degradation_block }
					end
				end

				-- Handle rotation
				if block.rotate then
					local meta = core.registered_nodes[block.name]
					if meta.paramtype2 == "wallmounted" then
						-- block.param2 = 2 + ((block.rotate - 2) + opt.rotate) % 4
						block.param2 = Rkit_structures.rotate_to_wallmounted(block.rotate + opt.rotate)
					else -- facedir
						-- block.param2 = (block.rotate + opt.rotate) % 4
						block.param2 = Rkit_structures.rotate_to_facedir(block.rotate + opt.rotate)
					end
				end

				local b_pos = { x = origin.x + x, y = origin.y + y, z = origin.z + z }
				local current_node = core.get_node(b_pos)
				if not opt.force_build and current_node.name ~= "air" then
					core.log("Skipping " .. b_pos.x .. "," .. b_pos.y .. "," .. b_pos.z .. " - Not air")
					goto continue
				end
				local delay = (y * layer_area + (x * z)) / (layer_area * opt.speed) -- Blocks
				if opt.build_order == "layers" then
					delay = (y * layer_area) / (layer_area * opt.speed)
				end
				if opt.build_order == "random" then
					delay = math.random((height * layer_area) + (width * length)) / (layer_area * opt.speed)
				end
				if opt.build_order == "instant" then
					delay = 0
				end
				if build_record[value] == nil then
					-- build_record[value] = {}
					error("Invalid block type: " .. value)
				end
				table.insert(build_record[value], b_pos)
				pending = pending + 1
				if opt.pre_clear then
					core.set_node(b_pos, { name = "air" })
				end
				core.after(delay, function()
					if opt.scaffold then
						core.set_node(b_pos, { name = opt.scaffold_block })
						core.after(delay, function()
							place_node(b_pos, block)
						end)
						return
					end
					place_node(b_pos, block)
				end)
			end
		end
		::continue::
	end
end
