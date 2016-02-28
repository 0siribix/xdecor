-- Add more ingredients here that make a soup.
local ingredients_list = {
	"apple", "mushroom", "honey", "pumpkin", "egg", "bread", "meat",
	"chicken", "carrot", "potato"
}

local cauldron_cbox = {
	{0,  0, 0,  16, 16, 0},
	{0,  0, 16, 16, 16, 0},
	{0,  0, 0,  0,  16, 16},
	{16, 0, 0,  0,  16, 16},
	{0,  0, 0,  16, 8,  16}
}

local function fill_water_bucket(pos, node, clicker, itemstack)
	local wield_item = clicker:get_wielded_item():get_name()
	if wield_item == "bucket:bucket_empty" then
		minetest.set_node(pos, {name="xdecor:cauldron_empty", param2=node.param2})
		itemstack:replace("bucket:bucket_water")
	end
end
	

xdecor.register("cauldron_empty", {
	description = "Cauldron",
	groups = {cracky=2, oddly_breakable_by_hand=1},
	on_rotate = screwdriver.rotate_simple,
	tiles = {"xdecor_cauldron_top_empty.png", "xdecor_cauldron_sides.png"},
	infotext = "Cauldron (empty)",
	on_rightclick = function(pos, node, clicker, itemstack)
		local wield_item = clicker:get_wielded_item():get_name()
		if wield_item == "bucket:bucket_water" or
				wield_item == "bucket:bucket_river_water" then
			minetest.set_node(pos, {name="xdecor:cauldron_idle", param2=node.param2})
			itemstack:replace("bucket:bucket_empty")
		end
	end,
	collision_box = xdecor.pixelbox(16, cauldron_cbox)
})

xdecor.register("cauldron_idle", {
	groups = {cracky=2, oddly_breakable_by_hand=1, not_in_creative_inventory=1},
	on_rotate = screwdriver.rotate_simple,
	tiles = {"xdecor_cauldron_top_idle.png", "xdecor_cauldron_sides.png"},
	drop = "xdecor:cauldron_empty",
	infotext = "Cauldron (idle)",
	collision_box = xdecor.pixelbox(16, cauldron_cbox),
	on_rightclick = fill_water_bucket,
	on_construct = function(pos)
		local timer = minetest.get_node_timer(pos)
		timer:start(10.0)
	end,
	on_timer = function(pos)
		local below_node = {x=pos.x, y=pos.y-1, z=pos.z}
		if not minetest.get_node(below_node).name:find("fire") then
			return true
		end

		local node = minetest.get_node(pos)
		minetest.set_node(pos, {name="xdecor:cauldron_boiling_water", param2=node.param2})
		return true
	end
})

xdecor.register("cauldron_boiling_water", {
	groups = {cracky=2, oddly_breakable_by_hand=1, not_in_creative_inventory=1},
	on_rotate = screwdriver.rotate_simple,
	drop = "xdecor:cauldron_empty",
	infotext = "Cauldron (active) - Drop foods inside to make a soup",
	damage_per_second = 2,
	tiles = {
		{ name = "xdecor_cauldron_top_anim_boiling_water.png",
			animation = {type="vertical_frames", length=3.0} },
		"xdecor_cauldron_sides.png"
	},
	collision_box = xdecor.pixelbox(16, cauldron_cbox),
	on_rightclick = fill_water_bucket,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local timer = minetest.get_node_timer(pos)
		meta:set_string("infotext", "Cauldron (active) - Drop some foods inside to make a soup")
		timer:start(5.0)
	end,
	on_timer = function(pos)
		local objs = minetest.get_objects_inside_radius(pos, 0.5)
		if objs == {} then return true end

		local ingredients = {}
		for _, obj in pairs(objs) do
			if obj and not obj:is_player() and obj:get_luaentity().itemstring then
				local itemstring = obj:get_luaentity().itemstring:match(":([%w_]+)")
				if ingredients == {} then
					for _, rep in pairs(ingredients) do
						if itemstring == rep then return end
					end
				end

				for _, ing in pairs(ingredients_list) do
					if itemstring and itemstring:find(ing) then
						ingredients[#ingredients+1] = itemstring
					end
				end
			end
		end

		local node = minetest.get_node(pos)
		if #ingredients >= 2 then
			for _, obj in pairs(objs) do
				obj:remove()
			end
			minetest.set_node(pos, {name="xdecor:cauldron_soup", param2=node.param2})
		end

		local node_under = {x=pos.x, y=pos.y-1, z=pos.z}
		if not minetest.get_node(node_under).name:find("fire") then
			minetest.set_node(pos, {name="xdecor:cauldron_idle", param2=node.param2})
		end
		return true
	end	
})

xdecor.register("cauldron_soup", {
	groups = {cracky=2, oddly_breakable_by_hand=1, not_in_creative_inventory=1},
	on_rotate = screwdriver.rotate_simple,
	drop = "xdecor:cauldron_empty",
	infotext = "Cauldron (active) - Use a bowl to eat the soup",
	damage_per_second = 2,
	tiles = {
		{ name = "xdecor_cauldron_top_anim_soup.png",
			animation = {type="vertical_frames", length=3.0} },
		"xdecor_cauldron_sides.png"
	},
	collision_box = xdecor.pixelbox(16, cauldron_cbox),
	on_rightclick = function(pos, node, clicker, itemstack)
		local inv = clicker:get_inventory()
		local wield_item = clicker:get_wielded_item()

		if wield_item:get_name() == "xdecor:bowl" then
			if wield_item:get_count() > 1 then
				if inv:room_for_item("main", "xdecor:bowl_soup 1") then
					itemstack:take_item()
					inv:add_item("main", "xdecor:bowl_soup 1")
				else
					minetest.chat_send_player(clicker:get_player_name(),
						"No room in your inventory to add a bowl of soup!")
					return
				end
			else
				itemstack:replace("xdecor:bowl_soup 1")
			end

			minetest.set_node(pos, {name="xdecor:cauldron_empty", param2=node.param2})
			return itemstack
		end
	end
})

