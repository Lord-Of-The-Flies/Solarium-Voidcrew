/datum/map_template/shuttle/voidcrew/squab
	name = "Squab-Class Multipurpose Frigate"
	catalog_desc = "A commonly seen Nanotrasen frigate, usually manufactured with some sort of dual cargo-sci department. \
		The hull itself is highly modular and well equipped, although rather slow due to it's poor thrust-to-mass ratio. \
		Nontheless the Squab-Class continues to maintain Nanotrasen's interests in the region, while providing fairly \
		good conditions to its employees."
	suffix = "squab_nanotrasen_frigate"
	short_name = "Squab-Class"
	part_requirements = list(PART_CLASS_COMBAT = 6, PART_CLASS_SCIENCE = 16, PART_CLASS_TRADE = 6, PART_CLASS_MISC = 10)
	has_upgrade_slots = TRUE
	upgrade_slot_ids = list(
		"squab_lab",
		"squab_mech_bay",
		"lab_storage",
		"director_s_quarters",
		"squab_gear_room"
	)
	player_hidden = FALSE
	// job_slots = list()
	available_themes = list("nanotrasen_frigate", "cheap_frigate", "the_patrolboat")

/obj/docking_port/mobile/voidcrew/squab
	name = "Squab-Class Multipurpose Frigate"
	area_type = /area/shuttle/voidcrew/squab
	port_direction = 4
	preferred_direction = 4

/area/shuttle/voidcrew/squab
	name = "Squab-Class Multipurpose Frigate"
	icon_state = "station"
