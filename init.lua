

local modpath = minetest.get_modpath("winter_is_coming")

local modname = "winter_is_coming"
local winter_is_coming = {}



minetest.register_node(modname..":frozen_tree_base", {
	description = "Frozen Tree",
	tiles = {
		"default_tree_top.png^"..modname.."_trunkfrost.png", 
		"default_tree_top.png^"..modname.."_trunkfrost.png", 
		"default_tree.png^"..modname.."_treefrost.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	drop = modname..':frozen_tree 1',
	groups = {tree = 1, choppy = 3, oddly_breakable_by_hand = 2, frost=2},
	sounds = default.node_sound_wood_defaults(),

	--on_place = minetest.rotate_node
})

minetest.register_node(modname..":frozen_tree", {
	description = "Frozen Tree",
	tiles = {
		"default_tree_top.png^"..modname.."_trunkfrost.png", 
		"default_tree_top.png^"..modname.."_trunkfrost.png", 
		"default_tree.png^"..modname.."_trunkfrost.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {tree = 1, choppy = 3, oddly_breakable_by_hand = 2, frost=2},
	sounds = default.node_sound_wood_defaults(),

	--on_place = minetest.rotate_node
})


minetest.register_node(modname..":dead_twigs", {
	description = "Dead Twigs",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {modname.."_deadtwigs.png"},
	special_tiles = {modname.."_deadtwigs.png"},
	paramtype = "light",
	drop="default:stick 1",
	is_ground_content = false,
	groups = {snappy = 3, flammable = 1, leaves = 1, frost=1}
})

minetest.register_node(modname..":dead_twigs_snowy", {
	description = "Dead Twigs",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tiles = {modname.."_deadtwigs_snowy.png"},
	special_tiles = {modname.."_deadtwigs_snowy.png"},
	paramtype = "light",
	drop="default:stick 1",
	is_ground_content = false,
	groups = {snappy = 3, flammable = 1, leaves = 1, frost=1}
})

minetest.register_node(modname..":permafrost", {
	description = "Permafrost",
	tiles = {"default_dirt.png^"..modname.."_trunkfrost.png"},
	groups = {cracky = 2, soil = 1, frost=2},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node(modname..":river_ice", {
	description = "River Ice",
	tiles = {"default_ice.png"},
	is_ground_content = false,
	paramtype = "light",
	groups = {cracky = 3, puts_out_fire = 1},
	sounds = default.node_sound_glass_defaults(),
})

-- this is dirt with snow that turns back into dirt with dry grass when thawed
minetest.register_node(modname..":dirt_with_dry_snow", {
	description = "Dirt with Snow",
	tiles = {"default_snow.png", "default_dirt.png",
		{name = "default_dirt.png^default_snow_side.png",
			tileable_vertical = false}},
	groups = {crumbly = 3, soil = 1},
	drop = 'default:dirt',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_snow_footstep", gain = 0.15},
	}),
})

winter_is_coming.check_waving_snow = function(pos) 
		
		local myname = minetest.get_node(pos).name
		pos.y = pos.y - 1
		local uname = minetest.get_node(pos).name
		local nodedef = minetest.registered_nodes[uname]
		pos.y = pos.y + 1
			
		if nodedef ~= nil and nodedef.waving ~= nil then
			-- it's waving, we should too
			if myname == "default:snow" then
				minetest.set_node(pos, {name = modname..":waving_snow"})
			end
		elseif myname == modname..":waving_snow" then
			minetest.set_node(pos, {name = "default:snow"})
		end

end

-- waiting on engine support for nodeboxed drawtypes. in the mean time large waving snow is better than thin floating snow
minetest.register_node(modname..":waving_snow", {
	description = "Snow",
	tiles = {"default_snow.png"},
	waving = 1,
	inventory_image = "default_snowball.png",
	wield_image = "default_snowball.png",
	paramtype = "light",
	buildable_to = true,
	drawtype = "allfaces_optional",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
		},
	},
	groups = {crumbly = 3, falling_node = 1, puts_out_fire = 1},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_snow_footstep", gain = 0.15},
		dug = {name = "default_snow_footstep", gain = 0.2},
		dig = {name = "default_snow_footstep", gain = 0.2}
	}),
	drops="default:snow",

	on_construct = winter_is_coming.check_waving_snow,
})


minetest.register_abm({
	nodenames = { "default:snow"},
	neighbors = { "group:leaves" },
	interval = 1,
	chance = 5,
	action = winter_is_coming.check_waving_snow,
})

local freeze_pairs = {
	["default:dirt"] = modname..":permafrost",
	["default:dirt_with_grass"] = "default:dirt_with_snow",
	["default:dirt_with_grass_footsteps"] = "default:dirt_with_snow",
	["default:dirt_with_dry_grass"] = modname..":dirt_with_dry_snow",
	["default:tree"] = modname..":frozen_tree",
	["default:water_source"] = "default:ice",
	["default:river_water_source"] = modname..":river_ice",

}

winter_is_coming.init = function() 
	local n=0
	local freeze_keys = {}
	local freeze_vals = {}

	for k,v in pairs(freeze_pairs) do
		n=n+1
		freeze_keys[n]=k
		freeze_vals[n]=v
	end
	
	minetest.register_abm({
		nodenames = freeze_keys,
		neighbors = freeze_vals,
		interval = 2,
		chance = 20,
		catch_up = false,
		action = function(pos, node, active_object_count, active_object_count_wider)
			
			local frozen_name = freeze_pairs[node.name]
			if frozen_name == nil then
				return
			end
			
			-- don't freeze near furnaces
			if nil ~= minetest.find_node_near(pos, 4, {"default:furnace"}) then
				return
			end
			
			local n = {x=pos.x, y=pos.y, z=pos.z}
			n.y = n.y + 1
			local q = minetest.get_node(n)
			
			if q ~= nil then -- extra environment checks
				
				if minetest.get_item_group(q.name, "flora") > 0 then 
					minetest.set_node(n, {name="default:dry_shrub"})
				end
				
				-- the base of trees have special tiles
				if q.name == "default:tree" and node.name == "default:tree" then 
					frozen_name = modname..":frozen_tree_base"
				end
			end
			
			-- fix rotation of logs
			local nodedef = minetest.registered_nodes[node.name]
			
			if nodedef ~= nil and nodedef.paramtype2 == "facedir" then
				minetest.set_node(pos, {name=frozen_name, param2 = node.param2})
			else
				minetest.set_node(pos, {name=frozen_name})
			end
			
		end,
	})
	
end

-- fix stupid default game political decisions
minetest.registered_nodes["default:snow"].node_box.type = "leveled"

winter_is_coming.init()
--[[
minetest.register_abm({
	nodenames = { "default:snow" },
	interval = 1,
	chance = 5,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local n = minetest.find_node_near(pos, 2, {"default:dirt_with_grass"})
		if n == nil then
			return
		end
		
					
		-- don't freeze near furnaces
		if nil ~= minetest.find_node_near(n, 4, {"default:furnace_active"}) then
			return
		end
		
		minetest.set_node(n, {name="default:dirt_with_snow"})
		
		n.y = n.y + 1
		local q = minetest.get_node(n)
		
		if q == nil then 
			return
		end
		
		if minetest.get_item_group(q.name, "flora") > 0 then 
			minetest.set_node(n, {name="default:dry_shrub"})
			return
		end
		
		if q.name == "default:tree" then 
			n.y = n.y + 1
			local r = minetest.get_node(n)
			if r.name == "default:tree" then
				minetest.set_node(q.pos, {name=modname..":frozen_tree_base", param2=q.param2})
				return
			end
		end
		
	end,
})
]]

-- snow accumulation on parts of nature
--[[ very broken atm, works far too well
minetest.register_abm({
	nodenames = {"group:tree", "group:leaves" },
	neighbors = {"air"},
	interval = 2,
	chance = 20,
	catch_up = false,
	action = function(pos, node)
		local above = {x = pos.x, y = pos.y + 1, z = pos.z}
		local a = minetest.get_node(above)
		
		if a.name ~= "air" then
			return
		end
		
		-- make sure some snow or ice is nearby
		local n = minetest.find_node_near(pos, 6, 
			{"default:snow", "default:snowblock", "default:ice", modname..":waving_snow", modname..":river_ice"})
		if n == nil then
			return
		end
		
		
		minetest.set_node(above, {name = "default:snow"})
	end
})
]]

--[[
minetest.register_abm({
	nodenames = { "default:snow"},
	interval = 1,
	chance = 5,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local n = minetest.find_node_near(pos, 1, {"default:tree"})
		if n ~= nil then
			minetest.set_node(n, {name=modname..":frozen_tree"})
		end
	end,
})
]]
--[[
-- trees grow frost
minetest.register_abm({
	nodenames = { modname..":frozen_tree_base", modname..":frozen_tree"},
	interval = 1,
	chance = 10,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local n = minetest.find_node_near(pos, 1, {"default:tree"})
		if n ~= nil then
			minetest.set_node(n, {name=modname..":frozen_tree", param2=node.param2})
		end
	end,
})
-- trees grow frost
minetest.register_abm({
	nodenames = { modname..":frozen_tree_base", modname..":frozen_tree", modname..":dead_twigs"},
	interval = 1,
	chance = 10,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local n = minetest.find_node_near(pos, 1, {"default:leaves"})
		if n ~= nil then
			minetest.set_node(n, {name=modname..":dead_twigs"})
		end
	end,
})
]]
-- snow piles up
minetest.register_abm({
	nodenames = { "default:dirt_with_snow" },
	neighbors = { "air" },
	interval = 5,
	chance = 5,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local n = minetest.find_node_near(pos, 1, {"default:dirt_with_snow"})
		if n ~= nil then
			n.y = n.y + 1
			
			-- don't freeze near torches
			if nil ~= minetest.find_node_near(n, 1, {"default:torch"}) then
				return
			end
			
			local q = minetest.get_node(n)
			if q ~= nil and (q.name == "air" or q.name == "default:grass") then 
				minetest.set_node(n, {name="default:snow"})
			end
		end
	end,
})

-- snowy grass spreads
minetest.register_abm({
	nodenames = { "default:dirt_with_snow" },
	neighbors = { "default:dirt_with_grass", "default:dirt_with_rainforest_litter", "default:dirt_with_dry_grass" },
	interval = 5,
	chance = 5,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local n = minetest.find_node_near(pos, 1, {"default:dirt_with_grass", "default:dirt_with_rainforest_litter", "default:dirt_with_dry_grass"})
		if n ~= nil then
			
			-- don't freeze near torches
			if nil ~= minetest.find_node_near(n, 3, {"default:torch"}) then
				return
			end
			
			minetest.set_node(n, {name="default:dirt_with_snow"})
			
			n.y = n.y + 1
			local q = minetest.get_node(n)
			
			if q == nil then 
				return
			end
			
			if minetest.get_item_group(q.name, "flora") > 0 then 
				minetest.set_node(n, {name="default:dry_shrub"})
				return
			end
			
			if q.name == "default:tree" then 
				n.y = n.y + 1
				local r = minetest.get_node(n)
				if r.name == "default:tree" then
					minetest.set_node(q.pos, {name=modname..":frozen_tree_base", param2=q.param2})
					return
				end
			end

		end
	end,
})

-- twigs get snowy
minetest.register_abm({
	nodenames = { modname..":dead_twigs" },
	interval = 10,
	chance = 50,
	action = function(pos, node, active_object_count, active_object_count_wider)
		minetest.set_node(pos, {name=modname..":dead_twigs_snowy"})
	end,
})
