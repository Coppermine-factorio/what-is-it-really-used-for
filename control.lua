SHOW_ALL = false	-- Set to true to also display disabled recipes and recipes without technology.

function find_technology(recipe, player)
	for _,tech in pairs(player.force.technologies) do
		if not tech.researched then
			for _, effect in pairs(tech.effects) do
				if effect.type == "unlock-recipe" then
					if effect.recipe == recipe then
						if tech.enabled then
							return tech.localised_name
						else
							if SHOW_ALL then 
								return {"disabled_tech", tech.localised_name}
							else 
								return false 
							end
						end
					end
				end
			end
		end
	end
	if SHOW_ALL then
		return {"not_found"}
	else
		return false
	end
end

function sort_recipes(recipes, player)
	function compare(l, r)
		-- We want hidden recipes at the end
		if l.hidden ~= r.hidden then
			return r.hidden
		end
		if l.group.order ~= r.group.order then
			return l.group.order < r.group.order
		end
		if l.subgroup.order ~= r.subgroup.order then
			return l.subgroup.order < r.subgroup.order
		end
		if l.order ~= r.order then
			return l.order < r.order
		end
		return l.name < r.name
	end
	table.sort(recipes, compare)
end

function add_recipe_to_list(recipe, table, player)
	local from_research = recipe.enabled or find_technology(recipe.name, player)
	if from_research then
		table.add{type="sprite", name="wiiuf_recipe_sprite_"..recipe.name, sprite="recipe/"..recipe.name}
		local label = table.add{
			type="label", name="wiiuf_recipe_label_"..recipe.name, caption=recipe.localised_name,
			single_line=false
		}
		label.style.minimal_height = 39
		label.style.maximal_width = 249
		if not recipe.enabled then
			label.style = "invalid_label_style"
			label.tooltip = {"behind_research", from_research}
		elseif recipe.hidden then
			label.style = "wiiuf_hidden_label_style"
		end
		return true
	else
		return false
	end
end

function identify(item, player, side)
	
	local ingredient_in = {}
	local mined_from = {}
	local looted_from = {}
	local product_of = {}
	
	for name, recipe in pairs(player.force.recipes) do
		for _, ingredient in pairs(recipe.ingredients) do
			if ingredient.name ==  item then
				table.insert(ingredient_in, recipe)
				break
			end
		end
		
		for _, product in pairs(recipe.products) do
			if product.name == item then
				table.insert(product_of, recipe)
				break
			end
		end
	end

	-- Sort both recipe lists
	sort_recipes(ingredient_in, player)
	sort_recipes(product_of, player)
	
	for _, entity in pairs(game.entity_prototypes) do
		if entity.loot then
			for _,loot in pairs(entity.loot) do
				if loot.item == item then
					table.insert(looted_from, entity)
					break
				end
			end
		end
		
		if (entity.type == "resource" or entity.type == "tree") and entity.mineable_properties and entity.mineable_properties.products then
			for _, product in pairs(entity.mineable_properties.products) do
				if product.name == item then
					table.insert(mined_from, entity)
					break
				end
			end
		end
	end
	
	local table_height = 350
	if side then table_height = 250 end

	local section_width = 300
	
	-- GUI stuff
	if player.gui.center.wiiuf_center_frame then player.gui.center.wiiuf_center_frame.destroy() end
	if side and player.gui.left.wiiuf_left_frame then player.gui.left.wiiuf_left_frame.destroy() end
	
	
	-- Create center frame
	local main_frame = {}
	if not side then
		main_frame = player.gui.center.add{type = "frame", name = "wiiuf_center_frame", direction = "vertical"}
	else
		main_frame = player.gui.left.add{type = "frame", name = "wiiuf_left_frame", direction = "vertical"}
	end
	
	
	-- Title flow
	local title_flow = main_frame.add{type = "flow", name = "wiiuf_title_flow", direction = "horizontal"}

	local sprite = "questionmark"
	local localised_name = item
	if game.item_prototypes[item] then
		sprite = "item/"..item
		localised_name = game.item_prototypes[item].localised_name
	elseif game.fluid_prototypes[item] then
		sprite = "fluid/"..item
		localised_name = game.fluid_prototypes[item].localised_name
	end
	
	title_flow.add{type = "sprite", name = "wiiuf_title_sprite", sprite = sprite}
	title_flow.add{type = "label", name = "wiiuf_title_label", caption = localised_name, style = "frame_caption_label_style"}
	
	-- buttons
	local button_style = "slot_button_style"
	if side then button_style = "search_button_style" end
	
	button_style = "small_slot_button_style"
	
	title_flow.add{type = "sprite-button", name = "wiiuf_minimise_" .. item, sprite = "arrow-bar", style = button_style, tooltip = {"minimise"}}
	if side then
		title_flow.add{type = "sprite-button", name = "wiiuf_show_" .. item, sprite = "arrow-right", style = button_style, tooltip = {"show", localised_name}}
	else
		title_flow.add{type = "sprite-button", name = "wiiuf_pin_" .. item, sprite = "arrow-left", style = button_style, tooltip = {"pin"}}
	end
	title_flow.add{type = "sprite-button", name = "wiiuf_close", sprite = "close", style = button_style, tooltip = {"close"}}

	-- Body flow
	local body_flow = {}
	if side then
		local body_scroll = main_frame.add{type = "scroll-pane", name = "wiiuf_body_scroll"}
		body_scroll.style.maximal_width = 250
		body_scroll.vertical_scroll_policy = "never"
		body_flow = body_scroll.add{type = "flow", name = "wiiuf_body_flow", direction = "horizontal", style = "achievements_flow_style"}
	else
		body_flow = main_frame.add{type = "flow", name = "wiiuf_body_flow", direction = "horizontal", style = "achievements_flow_style"}
	end

	-- mined from
	if #mined_from > 0 then
		local mined_frame = body_flow.add{type = "frame", name = "wiiuf_mined_frame", caption = {"mined_from"}}
		local mined_scroll = mined_frame.add{type = "scroll-pane", name = "wiiuf_mined_scroll"}
		mined_scroll.style.minimal_height = table_height
		mined_scroll.style.maximal_height = table_height
		local mined_table = mined_scroll.add{type = "table", name = "wiiuf_mined_table", colspan = 2}
		for i, entity in pairs(mined_from) do
			mined_table.add{type = "sprite", name = "wiiuf_sprite_" .. i, sprite = "entity/"..entity.name}
			local label = mined_table.add{type = "label", name = "wiiuf_label_" .. i, caption = entity.localised_name}
			label.style.minimal_height = 34
		end
	end
	-- looted from
	if #looted_from > 0 then
		local looted_frame = body_flow.add{type = "frame", name = "wiiuf_looted_frame", caption = {"looted_from"}}
		local looted_scroll = looted_frame.add{type = "scroll-pane", name = "wiiuf_looted_scroll"}
		looted_scroll.style.minimal_height = table_height
		looted_scroll.style.maximal_height = table_height
		local looted_table = looted_scroll.add{type = "table", name = "wiiuf_looted_table", colspan = 2}
		for i, entity in pairs(looted_from) do
			looted_table.add{type = "sprite", name = "wiiuf_sprite_" .. i, sprite = "entity/"..entity.name}
			local label = looted_table.add{type = "label", name = "wiiuf_label_" .. i, caption = entity.localised_name}
			label.style.minimal_height = 34
		end
	end

	-- ingredient in
	local ingredient_frame = body_flow.add{type = "frame", name = "wiiuf_ingredient_frame", caption = {"ingredient_in"}}
	local ingredient_scroll = ingredient_frame.add{type = "scroll-pane", name = "wiiuf_ingredient_scroll"}
	ingredient_scroll.style.minimal_height = table_height
	ingredient_scroll.style.maximal_height = table_height
	if not side then
		ingredient_scroll.style.minimal_width = section_width
		ingredient_scroll.style.maximal_width = section_width
	end
	local ingredient_table = ingredient_scroll.add{type = "table", name = "wiiuf_ingredient_table", colspan = 2}
	local is_ingredient = false
	for i, recipe in pairs(ingredient_in) do
		if add_recipe_to_list(recipe, ingredient_table, player) then
			is_ingredient = true
		end
	end
	
	if side and not is_ingredient then
		ingredient_frame.destroy()
	end

	-- product of
	local product_frame = body_flow.add{type = "frame", name = "wiiuf_product_frame", caption = {"product_of"}}
	local product_scroll = product_frame.add{type = "scroll-pane", name = "wiiuf_product_scroll"}
	product_scroll.style.minimal_height = table_height
	product_scroll.style.maximal_height = table_height
	if not side then
		product_scroll.style.minimal_width = section_width
		product_scroll.style.maximal_width = section_width
	end
	local product_table = product_scroll.add{type = "table", name = "wiiuf_product_table", colspan = 2}
	local is_product = false
	for i, recipe in pairs(product_of) do
		if add_recipe_to_list(recipe, product_table, player) then
			is_product = true
		end
	end

	if side and not is_product then
		product_frame.destroy()
	end

	-- Add an empty recipe frame so that things don't shift when it's used later
	local recipe_frame = body_flow.add{
		type="frame", name="wiiuf_recipe_frame", caption={"wiiuf_recipe_details"}
	}
	local recipe_scroll = recipe_frame.add{type="scroll-pane", name="wiiuf_recipe_scroll"}
	if not side then
		recipe_scroll.style.minimal_width = section_width
		recipe_scroll.style.maximal_width = section_width
	end
	local label = recipe_scroll.add{
		type="label", name="wiiuf_recipe_hint", caption={"wiiuf_recipe_hint"}, single_line=false
	}
	label.style.maximal_width = 249
end

function show_recipe_details(recipe_name, player)
	local recipe = player.force.recipes[recipe_name]

	local main_frame = player.gui.center.wiiuf_center_frame
	if not main_frame then
		main_frame = player.gui.left.wiiuf_left_frame
		if main_frame then
			main_frame = main_frame.wiiuf_body_scroll
		end
	end

	if not main_frame then
		player.print("No main frame")
		return
	end

	local body_flow = main_frame.wiiuf_body_flow

	-- Remove any existing recipe entry
	if body_flow.wiiuf_recipe_frame then
		body_flow.wiiuf_recipe_frame.destroy()
	end

	local section_width = 300

	local recipe_frame = body_flow.add{
		type="frame", name="wiiuf_recipe_frame", caption={"wiiuf_recipe_details"}
	}
	local recipe_scroll = recipe_frame.add{type="scroll-pane", name="wiiuf_recipe_scroll"}
	recipe_scroll.style.minimal_width = section_width
	recipe_scroll.style.maximal_width = section_width

	function add_sprite_and_label(add_to, thing_to_add, sprite_dir, i)
		if sprite_dir == "auto" then
			if game.item_prototypes[thing_to_add.name] then
				sprite_dir = "item"
			elseif game.fluid_prototypes[thing_to_add.name] then
				sprite_dir = "fluid"
			else
				player.print("Unknown sprite type for "..thing_to_add.name)
				return
			end
		end
		local localised_name = thing_to_add.localised_name
		if sprite_dir == "item" then
			localised_name = game.item_prototypes[thing_to_add.name].localised_name
		elseif sprite_dir == "fluid" then
			localised_name = game.fluid_prototypes[thing_to_add.name].localised_name
		end
		local table = add_to.add{type="table", name="wiiuf_recipe_table_"..i, colspan=2}
		table.add{
			type="sprite", name="wiiuf_recipe_item_sprite_"..thing_to_add.name,
			sprite=sprite_dir.."/"..thing_to_add.name
		}
		local label = table.add{
			type="label", name="wiiuf_recipe_item_label_"..thing_to_add.name, caption=localised_name,
			single_line=false
		}
		label.style.maximal_width = 249
	end

	local i = 0

	add_sprite_and_label(recipe_scroll, recipe, "recipe", i)
	i = i + 1
	recipe_scroll.add{
		type="label", name="wiiuf_recipe_ingredients_heading", caption={"wiiuf_recipe_ingredients_heading"}
	}
	for _, ingredient in pairs(recipe.ingredients) do
		add_sprite_and_label(recipe_scroll, ingredient, "auto", i)
		i = i + 1
	end
	recipe_scroll.add{
		type="label", name="wiiuf_recipe_products_heading", caption={"wiiuf_recipe_products_heading"}
	}
	for _, product in pairs(recipe.products) do
		add_sprite_and_label(recipe_scroll, product, "auto", i)
		i = i + 1
	end
end

function minimise(item, player, from_side)
	if not player.gui.left.wiiuf_item_flow then
		local item_flow = player.gui.left.add{type = "scroll-pane", name = "wiiuf_item_flow", style = "small_spacing_scroll_pane_style"}
		local item_table = item_flow.add{type = "table", colspan = 1, name = "wiiuf_item_table", style = "slot_table_style"}
		item_table.add{type = "sprite-button", name = "wiiuf_close", sprite = "close", style = "slot_button_style", tooltip = {"close"}}
		item_flow.style.maximal_height = 350
	end	
	
	local sprite = "questionmark"
	local localised_name = item
	if game.item_prototypes[item] then
		sprite = "item/"..item
		localised_name = game.item_prototypes[item].localised_name
	elseif game.fluid_prototypes[item] then
		sprite = "fluid/"..item
		localised_name = game.fluid_prototypes[item].localised_name
	end
	if not player.gui.left.wiiuf_item_flow.wiiuf_item_table["wiiuf_show_" .. item] then
		player.gui.left.wiiuf_item_flow.wiiuf_item_table.add{type = "sprite-button", name = "wiiuf_show_" .. item, sprite = sprite, tooltip = {"show", localised_name}, style = "slot_button_style"}
	end
	if not from_side and player.gui.center.wiiuf_center_frame then player.gui.center.wiiuf_center_frame.destroy() end
	if from_side and player.gui.left.wiiuf_left_frame then player.gui.left.wiiuf_left_frame.destroy() end
end

function add_top_button(player)
	local flow = player.gui.top.wiiuf_flow
	if not flow then
		flow = player.gui.top.add{type = "flow", name = "wiiuf_flow"}
	end
	if global.n_fluids < 10 then flow.direction = "vertical" else flow.direction = "horizontal" end

	if flow["looking-glass"] then flow["looking-glass"].destroy()	end -- remove the old 1.0.x button
	
	if flow["search_flow"] then flow["search_flow"].destroy() end
	local search_flow = flow.add{type = "flow", name = "search_flow", direction = "horizontal", style = "search_flow_style"}
	search_flow.add{type = "flow", name = "search_bar_placeholder", direction = "vertical"}
	search_flow.add{type = "sprite-button", name = "looking-glass", sprite = "looking-glass", style = "search_button_style", tooltip = {"top_button_tooltip"}}

end

script.on_init(function()
	global.n_fluids = 0
	for _ in pairs(game.fluid_prototypes) do
		global.n_fluids = global.n_fluids +1
	end
	for _, player in pairs(game.players) do add_top_button(player) end
end)

script.on_configuration_changed(function()
	global.n_fluids = 0
	for _ in pairs(game.fluid_prototypes) do
		global.n_fluids = global.n_fluids +1
	end
	for _, player in pairs(game.players) do add_top_button(player) end
end)

script.on_event(defines.events.on_player_created, function(event)
	add_top_button(game.players[event.player_index])
end)

script.on_event(defines.events.on_gui_click, function(event)
	local player = game.players[event.player_index]
	if event.element.name == "looking-glass" then
		if player.cursor_stack.valid_for_read then
			identify(player.cursor_stack.name, player)
		else
			local flow = player.gui.top.wiiuf_flow
			
			if flow.fluids_table then flow.fluids_table.destroy()
			else
				local fluids_table = flow.add{type = "table", colspan = math.ceil(global.n_fluids/10), name = "fluids_table", style = "slot_table_style"}
				for _, fluid in pairs(game.fluid_prototypes) do
					fluids_table.add{type = "sprite-button", name = "wiiuf_fluid_" .. fluid.name, sprite = "fluid/"..fluid.name, style = "slot_button_style", tooltip = fluid.localised_name}
				end
			end
		end
	
	--Label for fluid in search results. Check it before root "wiiuf_fluid_"
	elseif event.element.name:find("wiiuf_fluid_label_") then
		identify(event.element.name:sub(19), player)
	
	--Sprite for fluid in search results
	elseif event.element.name:find("wiiuf_fluid_") then
		identify(event.element.name:sub(13), player)
		if player.gui.top.wiiuf_flow.fluids_table then player.gui.top.wiiuf_flow.fluids_table.destroy() end
	
	elseif event.element.name == "wiiuf_close" then
		event.element.parent.parent.destroy()
	
	elseif event.element.name:find("wiiuf_minimise_") then
		minimise(event.element.name:sub(16), player, event.element.parent.parent.name == "wiiuf_left_frame")
	
	elseif event.element.name:find("wiiuf_show_") then
		identify(event.element.name:sub(12), player)
		if event.element.parent.name == "wiiuf_item_table" then 
			event.element.destroy()
			if #player.gui.left.wiiuf_item_flow.wiiuf_item_table.children_names == 1 then
				player.gui.left.wiiuf_item_flow.destroy()
			end
		else player.gui.left.wiiuf_left_frame.destroy()
		end
	
	elseif event.element.name:find("wiiuf_pin_") then
		identify(event.element.name:sub(11), player, true)
		
	--Sprite for item in search results
	elseif event.element.name:find("wiiuf_item_sprite_") then
		identify(event.element.name:sub(19), player)
		player.gui.top.wiiuf_flow.search_flow.search_bar_placeholder.search_bar_scroll.destroy()
		player.gui.top.wiiuf_flow.search_flow.search_bar_placeholder.search_bar_textfield.destroy()
	--Label for item in search results
	elseif event.element.name:find("wiiuf_item_label_") then
		identify(event.element.name:sub(18), player)
		player.gui.top.wiiuf_flow.search_flow.search_bar_placeholder.search_bar_scroll.destroy()
		player.gui.top.wiiuf_flow.search_flow.search_bar_placeholder.search_bar_textfield.destroy()
	-- Sprite for recipe in list
	elseif event.element.name:find("wiiuf_recipe_sprite_") then
		show_recipe_details(event.element.name:sub(21), player)
	-- Label for recipe in list
	elseif event.element.name:find("wiiuf_recipe_label_") then
		show_recipe_details(event.element.name:sub(20), player)
	-- Sprite for item in recipe view
	elseif event.element.name:find("wiiuf_recipe_item_sprite_") then
		identify(event.element.name:sub(26), player)
	-- Label for item in recipe view
	elseif event.element.name:find("wiiuf_recipe_item_label_") then
		identify(event.element.name:sub(25), player)
	end
end)

script.on_event("inspect_item", function(event)
	local player = game.players[event.player_index]
	if player.cursor_stack.valid_for_read then
		identify(player.cursor_stack.name, player)
	else
		if player.gui.top.wiiuf_flow.search_flow.search_bar_placeholder.search_bar_textfield then
			player.gui.top.wiiuf_flow.search_flow.search_bar_placeholder.search_bar_textfield.destroy()
			if player.gui.top.wiiuf_flow.search_flow.search_bar_placeholder.search_bar_scroll then player.gui.top.wiiuf_flow.search_flow.search_bar_placeholder.search_bar_scroll.destroy() end
		else
			player.gui.top.wiiuf_flow.search_flow.search_bar_placeholder.add{type = "textfield", name = "search_bar_textfield"}
		end
	end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
	if event.element.name == "search_bar_textfield" then
		local player = game.players[event.player_index]
		if player.gui.top.wiiuf_flow.search_flow.search_bar_placeholder.search_bar_scroll then player.gui.top.wiiuf_flow.search_flow.search_bar_placeholder.search_bar_scroll.destroy() end
		
		if string.len(event.element.text) < 2 then return end
		
		local scroll_pane = player.gui.top.wiiuf_flow.search_flow.search_bar_placeholder.add{type = "scroll-pane", name = "search_bar_scroll", style = "small_spacing_scroll_pane_style"}
		scroll_pane.style.maximal_height = 250
		local results_table = scroll_pane.add{type = "table", name = "results_table", colspan = 2, style = "row_table_style"}
		
		-- The first row of the table is regarded as the table headers and don't get the table style applied to them
		-- We don't want this however, so we fill it in with blanks.
		results_table.add{type = "label", name = "wiiuf_filler_label_1"}
		results_table.add{type = "label", name = "wiiuf_filler_label_2"}
		
		-- remove capitals, purge special characters, and replace spaces with -
		local text = event.element.text:lower()
		text = text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
		text = text:gsub(" ", "%%-")
		
		for _, item in pairs(game.item_prototypes) do
			if item.name:lower():find(text) then
				results_table.add{type = "sprite", name = "wiiuf_item_sprite_" .. item.name, sprite = "item/"..item.name}
				local label = results_table.add{type = "label", name = "wiiuf_item_label_" .. item.name, caption = item.localised_name}
				label.style.minimal_height = 34
				label.style.minimal_width = 101
			end
		end
		for _, item in pairs(game.fluid_prototypes) do
			if item.name:lower():find(text) then
				results_table.add{type = "sprite", name = "wiiuf_fluid_" .. item.name, sprite = "fluid/"..item.name}
				local label = results_table.add{type = "label", name = "wiiuf_fluid_label_" .. item.name, caption = item.localised_name}
				label.style.minimal_height = 34
				label.style.minimal_width = 101
			end
		end
	end
end)

-- vim:noet
