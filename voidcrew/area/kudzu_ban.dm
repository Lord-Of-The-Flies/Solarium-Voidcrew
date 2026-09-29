/**
 * # Kudzu containment
 *
 * Trader outposts are permanent, indestructible and shared by every crew in
 * the zone for the whole round. A kudzu seed pack dropped on the concourse
 * (round 89, 2026-09-20) is a grief with no cleanup: the deck can't be
 * rebuilt around it, the NPC staff can't fight it, and the only people who
 * can hack it back are the crews who came to shop.
 *
 * Two routes are closed:
 * - Planting a kudzu seed pack while standing in a warded area is refused
 *   outright (the seed is kept, nothing spawns).
 * - Vines spreading in from outside - a cluster on a ship docked at the
 *   hangar, growing through the open airlock - stop at the area line. The
 *   controller is told not to spawn a piece on a warded turf.
 *
 * Kudzu in a hydroponics tray only grows pods, never vines, so trays are
 * left alone. Cutting the last vine of a cluster drops a fresh seed pack;
 * planting that one is refused the same way.
 */

/// Areas kudzu may neither be planted in nor spread into. Set on the trader
/// outpost areas; enforcement is the two overrides at the bottom of this file.
/area/var/repels_kudzu = FALSE

/area/voidcrew/trader_outpost
	repels_kudzu = TRUE

/area/voidcrew/outpost_hangar
	repels_kudzu = TRUE

/// Whether a turf sits in a warded area.
/proc/turf_repels_kudzu(turf/target)
	var/area/target_area = target?.loc
	return !!target_area?.repels_kudzu

/obj/item/seeds/kudzu/plant(mob/user)
	if(turf_repels_kudzu(get_turf(user)))
		to_chat(user, span_warning("The outpost's deck plating is sealed. [src] would never take root here."))
		return FALSE
	return ..()

/**
 * Spread stops at the area line. Returning the parent piece keeps spread()'s
 * pixel-offset animation pointed at a real vine: the parent lurches toward
 * the blocked tile and settles back, which reads as the vine failing to push
 * through. A seedless spawn (no parent) on a warded turf returns null; the
 * controller then finds itself with no vines and deletes itself on its next
 * process().
 */
/datum/spacevine_controller/spawn_spacevine_piece(turf/location, obj/structure/spacevine/parent, list/muts)
	if(turf_repels_kudzu(location))
		return parent
	return ..()
