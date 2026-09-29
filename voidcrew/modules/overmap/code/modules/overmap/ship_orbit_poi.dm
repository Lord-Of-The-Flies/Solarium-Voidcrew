/**
 * Voidcrew: overmap-scale points of interest on the ghost orbit menu.
 *
 * Ghosts could already track a nuke disk but had no way to pick a ship to watch, which is
 * the one thing most observers actually want to do here. Ships are created and destroyed
 * all round long, so rather than registering points of interest at ship creation and
 * chasing every lifecycle edge (hull destroyed, NPC ship claimed at the helm, ship
 * abandoned), the whole set is re-synced every time the orbit menu builds its data. The
 * list is therefore always current as of the moment the ghost opened or refreshed it.
 *
 * The POI is the ship's mobile docking port rather than its overmap marker. The marker
 * lives on the overmap z-level, so orbiting it would park the ghost on a strategic map;
 * the docking port sits on the hull, so following one drops you aboard. The port carries
 * the ship's name and set_ship_name() keeps the two in sync, so renames are picked up for
 * free - get_other_pois() reads the name live.
 *
 * This file also files Voidcrew's own landmarks into their own categories instead of
 * leaving them buried in Misc (see poi_category() in code/modules/mob/dead/observer/orbit.dm):
 * hulls -> Ships, the system star and trader outpost interiors -> Maps. Both register
 * themselves as points of interest at their own lifecycle edges (stars.dm, trade/outpost_orbit.dm).
 */
/datum/orbit_menu/ui_static_data(mob/user)
	sync_ship_points_of_interest()
	return ..()

/// Brings the registered ship points of interest in line with the ships that exist right now.
/proc/sync_ship_points_of_interest()
	// Drop any ship port we previously listed whose ship is gone or no longer qualifies.
	for(var/datum/point_of_interest/poi as anything in SSpoints_of_interest.other_points_of_interest.Copy())
		var/obj/docking_port/mobile/voidcrew/port = poi.target
		if(!istype(port))
			continue
		var/obj/structure/overmap/ship/ship = port.current_ship
		if(!QDELETED(ship) && ship.is_orbitable_by_ghosts())
			continue
		SSpoints_of_interest.remove_point_of_interest(port)

	// Add every ship that qualifies and isn't listed yet.
	for(var/obj/structure/overmap/ship/ship as anything in SSovermap.simulated_ships)
		if(QDELETED(ship) || !ship.is_orbitable_by_ghosts())
			continue
		var/obj/docking_port/mobile/voidcrew/port = ship.shuttle
		if(QDELETED(port))
			continue
		if(SSpoints_of_interest.points_of_interest_by_target_ref[REF(port)])
			continue
		SSpoints_of_interest.make_point_of_interest(port)

/// TRUE if ghosts should be offered this ship in the orbit menu.
/obj/structure/overmap/ship/proc/is_orbitable_by_ghosts()
	return TRUE

/// NPC hulls only become interesting once players are actually flying them.
/obj/structure/overmap/ship/npc/is_orbitable_by_ghosts()
	return player_controlled

/**
 * Voidcrew routing for the orbit menu's non-mob categories.
 *
 * A ship's POI is its docking port, not the helm console the stock code looks for. The
 * star and the trader outpost anchors are overmap-scale places rather than portable
 * objects, and belong under Maps where a ghost can jump straight to them.
 *
 * Overrides the core proc rather than redeclaring it: the /proc/ form in DM is a fresh
 * declaration and a second one is a "duplicate definition" error, while the bare
 * /datum/x/name() form is an override that chains through ..().
 */
// SOL-EDIT START - раскладываем POI voidcrew по разделам Ships и Maps
/datum/orbit_menu/poi_category(atom/poi)
	if(istype(poi, /obj/docking_port/mobile/voidcrew))
		return ORBIT_CATEGORY_SHIPS
	if(is_overmap_location_poi(poi))
		return ORBIT_CATEGORY_MAPS
			return ..()
// SOL-EDIT END

/// Voidcrew's overmap-scale landmarks: the system star and trader outpost interiors.
// SOL-EDIT START
/proc/is_overmap_location_poi(atom/poi)
	return istype(poi, /obj/structure/overmap/star) \
		|| istype(poi, /obj/effect/landmark/tradepost_orbit_token)
// SOL-EDIT END

/// Labels Voidcrew's orbit entries so they aren't just a bare name among the anomalies.
// SOL-EDIT START - подпись раздела Maps для звезды и аванпоста
/datum/orbit_menu/get_misc_data(atom/movable/atom_poi)
	. = ..()

	if(is_overmap_location_poi(atom_poi))
		.[1]["extra"] = get_overmap_location_label(atom_poi)
		return

	var/obj/docking_port/mobile/voidcrew/port = atom_poi
	if(!istype(port))
		return
	var/obj/structure/overmap/ship/ship = port.current_ship
	if(QDELETED(ship))
		return
	.[1]["extra"] = "Ship: [length(ship.manifest)] crew"
	return .
// SOL-EDIT END

/**
 * The grey subtitle shown next to a Voidcrew Maps entry.
 *
 * A star class that gives itself a distinct name (binary systems, currently) is shown
 * as-is; everything else is just a star. Two copies of "Aurelia Beta" on one tile tell
 * a ghost nothing about what it is looking at.
 */
// SOL-EDIT START
/proc/get_overmap_location_label(atom/poi)
	if(istype(poi, /obj/effect/landmark/tradepost_orbit_token))
		return "Trade Outpost"
	if(istype(poi, /obj/structure/overmap/star))
		var/obj/structure/overmap/star/star = poi
		if(isnull(star.star_datum))
			return "Star"
		return star.star_datum.name == "Star" ? "Star" : star.star_datum.name
// SOL-EDIT END
