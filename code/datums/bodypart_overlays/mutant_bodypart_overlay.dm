///Variant of bodypart_overlay meant to work synchronously with external organs. Gets imprinted upon Insert in on_species_gain
/datum/bodypart_overlay/mutant
	///Sprite datum we use to draw on the bodypart
	var/datum/sprite_accessory/sprite_datum

	///Defines what kind of 'organ' we're looking at. Sprites have names like 'm_mothwings_firemoth_ADJ'. 'mothwings' would then be feature_key
	var/feature_key = ""

	///The color this organ draws with. Updated by bodypart/inherit_color()
	var/draw_color
	/// ERP port: colors taken from `dna.features` at insertion time, kept so that temporary
	/// (dropped organ / null limb) renders don't permanently drop the color
	var/list/saved_draw_color
	/// ERP port: per-color-layer emissive flags (primary/secondary/tertiary) from `dna.features`
	var/list/saved_emissives
	///Override of the color of the organ, from dye sprays
	var/dye_color
	///Can this bodypart overlay be dyed?
	var/dyable = FALSE

	///Where does this organ inherit its color from?
	var/color_source = ORGAN_COLOR_INHERIT
	///Take on the dna/preference from whoever we're gonna be inserted in
	var/imprint_on_next_insertion = TRUE

/datum/bodypart_overlay/mutant/New(obj/item/organ/attached_organ)
	. = ..()

	RegisterSignal(attached_organ, COMSIG_ORGAN_IMPLANTED, PROC_REF(on_mob_insert))

/datum/bodypart_overlay/mutant/proc/on_mob_insert(obj/item/organ/parent, mob/living/carbon/receiver)
	SIGNAL_HANDLER

	if (isalien(receiver))
		return // Xenomorphs have no dna or other features required to support this, maybe one day

	if(!should_visual_organ_apply_to(parent.type, receiver))
		stack_trace("adding a [parent.type] to a [receiver.type] when it shouldn't be!")

	if(imprint_on_next_insertion) //We only want this set *once*
		var/feature_name = receiver.dna.features[feature_key]
		// ERP port: skyrat/bubber customized parts store an assoc list (name + color list) instead of a plain name
		// (keys are MUTANT_INDEX_NAME / MUTANT_INDEX_COLOR_LIST, spelled out because those defines live in the ERP include)
		if (islist(feature_name))
			var/list/feature_data = feature_name
			var/list/color_list = feature_data["color"]
			if (islist(color_list) && length(color_list))
				draw_color = color_list
				saved_draw_color = color_list
			else if (color_list)
				draw_color = color_list
				saved_draw_color = color_list
			feature_name = feature_data["name"]
			var/list/emissive_list = feature_data["emissive"]
			if (islist(emissive_list))
				saved_emissives = emissive_list
		if (isnull(feature_name))
			feature_name = receiver.dna.species.mutant_organs[parent.type]
		set_appearance_from_name(feature_name)
		imprint_on_next_insertion = FALSE

/datum/bodypart_overlay/mutant/get_overlay(layer, obj/item/bodypart/limb)
	inherit_color(limb) // If draw_color is not set yet, go ahead and do that

	if (!sprite_datum)
		return ..()

	// ERP port: skyrat/bubber "matrixed" parts are drawn one image per color layer (primary/secondary/tertiary)
	var/real_layer = bitflag_to_layer(layer)
	var/base_state = build_base_icon_state(real_layer, limb)
	var/list/color_layers = get_matrixed_color_layers(base_state)
	if (!length(color_layers))
		return ..()

	var/list/images = list()
	var/list/colors = islist(draw_color) ? draw_color : saved_draw_color
	var/index = 1
	for (var/layer_name in color_layers)
		var/mutable_appearance/part = mutable_appearance(sprite_datum.icon, "[base_state]_[layer_name]", layer = real_layer)
		if (sprite_datum.color_src)
			part.color = get_color_by_index(index, colors)
		if (sprite_datum.center)
			center_image(part, sprite_datum.dimension_x, sprite_datum.dimension_y)
		images += part
		index++

	if (blocks_emissive != EMISSIVE_BLOCK_NONE && limb)
		images += emissive_blocker(images[1].icon, images[1].icon_state, limb, layer = images[1].layer, alpha = images[1].alpha)

	// ERP port: per-color-layer emissive overlays
	if (sprite_datum.uses_emissives && islist(saved_emissives))
		var/count = min(length(color_layers), length(saved_emissives))
		for (var/emissive_index in 1 to count)
			if (!saved_emissives[emissive_index])
				continue
			var/image/base_image = images[emissive_index]
			var/mutable_appearance/glow = emissive_appearance(base_image.icon, base_image.icon_state, offset_spokesman = limb, layer = base_image.layer)
			glow.pixel_w = base_image.pixel_w
			glow.pixel_z = base_image.pixel_z
			images += glow

	return images

///Completely random image and color generation (obeys what a player can choose from)
/datum/bodypart_overlay/mutant/proc/randomize_appearance()
	randomize_sprite()
	draw_color = "#[random_color()]"
	imprint_on_next_insertion = FALSE

///Grab a random sprite
/datum/bodypart_overlay/mutant/proc/randomize_sprite()
	sprite_datum = get_random_appearance()

///Restrict our random sprites to ones that aren't locked/special
/datum/bodypart_overlay/mutant/proc/get_random_appearance() as /datum/sprite_accessory
	RETURN_TYPE(/datum/sprite_accessory)
	var/list/valid_restyles = list()
	var/list/feature_list = get_feature_registry()
	if(!length(feature_list))
		feature_list = get_global_feature_list()
	for(var/accessory in feature_list)
		var/datum/sprite_accessory/accessory_datum = feature_list[accessory]
		if(!istype(accessory_datum))
			continue
		if(initial(accessory_datum.locked)) //locked is for stuff that shouldn't appear here
			continue
		if(!initial(accessory_datum.natural_spawn))
			continue
		valid_restyles += accessory_datum
	return pick(valid_restyles)

///Return the BASE icon state of the sprite datum (so not the gender, layer, feature_key)
/datum/bodypart_overlay/mutant/proc/get_base_icon_state()
	return sprite_datum.icon_state

/// ERP port: skyrat/bubber parts can carry a list of colors (matrixed parts). Returns the color to draw with.
/datum/bodypart_overlay/mutant/proc/get_draw_color()
	var/color_value = draw_color
	if(isnull(color_value))
		color_value = saved_draw_color
	if(islist(color_value))
		return length(color_value) ? color_value[1] : null
	return color_value

/// ERP port: cached icon states of the sprite accessory's icon file
/datum/bodypart_overlay/mutant/proc/get_cached_icon_states()
	if (!sprite_datum?.icon)
		return null
	var/list/cached_states = SSaccessories.cached_mutant_icon_files[sprite_datum.icon]
	if (!islist(cached_states))
		cached_states = icon_states(new /icon(sprite_datum.icon))
		SSaccessories.cached_mutant_icon_files[sprite_datum.icon] = cached_states
	return cached_states

/// ERP port: builds the icon state the same way get_image() does, before any color layer suffix
/datum/bodypart_overlay/mutant/proc/build_base_icon_state(image_layer, obj/item/bodypart/limb)
	var/gender = (limb?.limb_gender == FEMALE) ? "f" : "m"
	var/list/icon_state_builder = list()
	icon_state_builder += sprite_datum.gender_specific ? gender : "m"
	icon_state_builder += feature_key
	icon_state_builder += get_base_icon_state()
	icon_state_builder += mutant_bodyparts_layertext(image_layer)
	return icon_state_builder.Join("_")

/// ERP port: `primary` / `secondary` / `tertiary` layers that actually exist for this part
/datum/bodypart_overlay/mutant/proc/get_matrixed_color_layers(base_state)
	var/list/found_layers = list()
	if (sprite_datum?.color_src != 32) // USE_MATRIXED_COLORS, defined in the ERP include
		return found_layers
	var/list/cached_states = get_cached_icon_states()
	if (!islist(cached_states))
		return found_layers
	for (var/layer_name in list("primary", "secondary", "tertiary"))
		if ("[base_state]_[layer_name]" in cached_states)
			found_layers += layer_name
	return found_layers

/// ERP port: matrixed parts keep their sprites in `..._primary` / `..._secondary` / `..._tertiary` states.
/// Returns the icon state to use (with the primary layer suffix) or null if the icon has no matrixed variants.
/datum/bodypart_overlay/mutant/proc/get_color_layer_suffix(base_state)
	if (sprite_datum?.color_src != 32) // USE_MATRIXED_COLORS
		return null

	var/list/cached_states = get_cached_icon_states()
	if (!islist(cached_states))
		return null

	if ("[base_state]_primary" in cached_states)
		return "[base_state]_primary"
	return null

/// ERP port: color of a given color layer index (1 = primary, 2 = secondary, 3 = tertiary)
/datum/bodypart_overlay/mutant/proc/get_color_by_index(index, list/colors)
	if (islist(colors) && length(colors))
		return colors[min(index, length(colors))]
	return get_draw_color()

///Get the image we need to draw on the person. Called from get_overlay() which is called from _bodyparts.dm. Limb can be null
/datum/bodypart_overlay/mutant/get_image(image_layer, obj/item/bodypart/limb)
	if(!sprite_datum)
		CRASH("Trying to call get_image() on [type] while it didn't have a sprite_datum. This shouldn't happen, report it as soon as possible.")

	var/finished_icon_state = build_base_icon_state(image_layer, limb)

	// ERP port: matrixed parts are drawn with their primary layer if the multi-layer path is not taken
	var/matrixed_state = get_color_layer_suffix(finished_icon_state)
	if(matrixed_state)
		finished_icon_state = matrixed_state

	var/mutable_appearance/appearance = mutable_appearance(sprite_datum.icon, finished_icon_state, layer = image_layer)

	if(sprite_datum.center)
		center_image(appearance, sprite_datum.dimension_x, sprite_datum.dimension_y)

	return appearance

/datum/bodypart_overlay/mutant/color_image(image/overlay, layer, obj/item/bodypart/limb)
	overlay.color = sprite_datum.color_src ? (dye_color || get_draw_color()) : null

/datum/bodypart_overlay/mutant/added_to_limb(obj/item/bodypart/limb)
	inherit_color(limb)

///Change our accessory sprite, using the accesssory type. If you need to change the sprite for something, use simple_change_sprite()
/datum/bodypart_overlay/mutant/set_appearance(accessory_type)
	sprite_datum = fetch_sprite_datum(accessory_type)
	cache_key = jointext(generate_icon_cache(), "_")

///In a lot of cases, appearances are stored in DNA as the Name, instead of the path. Use set_appearance instead of possible
/datum/bodypart_overlay/mutant/proc/set_appearance_from_name(accessory_name)
	sprite_datum = fetch_sprite_datum_from_name(accessory_name)
	cache_key = jointext(generate_icon_cache(), "_")

///Generate a unique key based on our sprites. So that if we've aleady drawn these sprites, they can be found in the cache and wont have to be drawn again (blessing and curse, but mostly curse)
/datum/bodypart_overlay/mutant/generate_icon_cache()
	. = list()
	. += "[get_base_icon_state()]"
	. += "[feature_key]"
	// ERP port: matrixed parts carry a list of colors, expand them so different colors don't share a cache entry
	var/color_value = dye_color || draw_color || saved_draw_color
	if(islist(color_value))
		for(var/sub_color in color_value)
			. += "[sub_color]"
	else
		. += "[color_value]"
	return .

///Return a dumb glob list for this specific feature (called from parse_sprite)
/datum/bodypart_overlay/mutant/proc/get_global_feature_list()
	// ERP port: prefer the skyrat/bubber sprite accessory registry (SSaccessories.sprite_accessories)
	var/list/feature_list = get_feature_registry()
	if(islist(feature_list))
		return feature_list
	CRASH("External organ has no feature list, it will render invisible")

/// ERP port: the skyrat/bubber sprite accessory registry, keyed by feature key then accessory name
/datum/bodypart_overlay/mutant/proc/get_feature_registry()
	if(!islist(SSaccessories.sprite_accessories))
		return null
	return SSaccessories.sprite_accessories[feature_key]

///Give the organ its color. Force will override the existing one.
/datum/bodypart_overlay/mutant/proc/inherit_color(obj/item/bodypart/bodypart_owner, force)
	if(isnull(bodypart_owner))
		draw_color = null
		return TRUE

	if(draw_color && !force)
		return FALSE

	switch(color_source)
		if(ORGAN_COLOR_OVERRIDE)
			draw_color = override_color(bodypart_owner)
		if(ORGAN_COLOR_INHERIT)
			draw_color = bodypart_owner.draw_color
		if(ORGAN_COLOR_HAIR)
			var/datum/species/species = bodypart_owner.owner?.dna?.species
			var/fixed_color = species?.get_fixed_hair_color(bodypart_owner.owner)
			if(!ishuman(bodypart_owner.owner))
				draw_color = fixed_color
				return
			var/mob/living/carbon/human/human_owner = bodypart_owner.owner
			var/obj/item/bodypart/head/my_head = human_owner.get_bodypart(BODY_ZONE_HEAD) //not always the same as bodypart_owner
			//head hair color takes priority, owner hair color is a backup if we lack a head or something
			if(!my_head)
				draw_color = fixed_color || human_owner.hair_color
				return
			if(my_head.head_flags & (HEAD_HAIR|HEAD_FACIAL_HAIR))
				draw_color = my_head.fixed_hair_color || my_head.hair_color
			else //inherit mutant color of the bodypart if the owner doesn't have hair.
				draw_color = bodypart_owner.draw_color

	return TRUE

///Sprite accessories are singletons, stored list("Big Snout" = instance of /datum/sprite_accessory/snout/big), so here we get that singleton
/datum/bodypart_overlay/mutant/proc/fetch_sprite_datum(datum/sprite_accessory/accessory_path)
	return fetch_sprite_datum_from_name(initial(accessory_path.name))

///Get the singleton from the sprite name
/datum/bodypart_overlay/mutant/proc/fetch_sprite_datum_from_name(accessory_name)
	// ERP port: skyrat/bubber accessories are registered by feature key, so check that registry first
	var/list/registry = get_feature_registry()
	if(islist(registry))
		var/datum/sprite_accessory/registered = registry[accessory_name]
		if(registered)
			return registered

	var/list/feature_list = get_global_feature_list()
	var/found = feature_list[accessory_name]
	if(found)
		return found

	if(!length(feature_list))
		CRASH("External organ [type] returned no sprite datums from get_global_feature_list(), so no accessories could be found!")
	else if(accessory_name)
		CRASH("External organ [type] couldn't find sprite accessory [accessory_name]!")
	else
		CRASH("External organ [type] had fetch_sprite_datum called with a null accessory name!")

///From dye sprays. Set the dye_color (draw_color override) of this organ to a new value.
/datum/bodypart_overlay/mutant/proc/set_dye_color(new_color, obj/item/organ/organ)
	dye_color = new_color
	if(organ.owner)
		organ.owner.update_body_parts()
	else
		organ.bodypart_owner?.update_icon_dropped()
