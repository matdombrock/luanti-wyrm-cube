
crafting.register_craft({
	output = "sum_airship:canvas_roll",
	items = {
		"group:fuzzy 9"
	}
})
crafting.register_craft({
	output = "sum_airship:hull",
	items = {
		"group:boat 3",
		"rp_default:ingot_steel 3"
	}
})
crafting.register_craft({
	output = "sum_airship:boat",
	items = {
		"sum_airship:canvas_roll 3",
		"rp_default:ingot_steel 8",
		"rp_default:ingot_steel",
		"sum_airship:hull",
	}
})