/**
 * # Plumbing and ship movement
 *
 * Every voidcrew ship is a shuttle, so every dock and undock drags the whole hull through
 * /obj/docking_port/mobile/initiate_docking(), and a dock usually rotates it. Upstream plumbing
 * was written for a station that never moves and has two holes a ship falls through every
 * single time:
 *
 * 1. /datum/component/plumbing disables itself on COMSIG_MOVABLE_MOVED and nothing ever
 *    re-enables it. That signal fires from abstract_move() halfway through the transplant,
 *    while the machine is on the new turf but its ducts may still be on the old one, and
 *    with its pre-rotation connects; the cleanup then pokes whichever duct happens to sit
 *    in the stale direction. After the move every machine is inert until someone unwrenches
 *    and re-wrenches it, and even then the ducts around it are wrong (see 2).
 *
 * 2. /obj/machinery/duct keeps its geometry in `connects` (a direction bitfield) and in the
 *    direction values of `neighbours`, and neither is touched by shuttleRotate(). A duct that
 *    joined its neighbour to the EAST still says EAST after the ship turned, so the sprite
 *    draws the old shape while the neighbour now sits to the SOUTH. The base rotate also
 *    spins the duct's pixel offsets, which are the per-layer stagger from handle_layer(),
 *    not geometry, so off-centre layers drift a few pixels per dock as well.
 *
 * The fix follows the cable pattern in shuttle_move_callbacks.dm:
 *
 * - beforeShuttleMove(): while the layout is still intact, an active plumbing component
 *   disconnects cleanly and remembers that it owes a reconnect. The Moved handler then finds
 *   it already inactive and does nothing mid-transplant.
 * - shuttleRotate(): ducts rotate `connects` and every neighbour direction with the hull.
 * - lateShuttleMove(): every moved atom has landed and rotated, so components re-enable, which
 *   recomputes their connects from the new dir and re-registers them with the (unchanged,
 *   purely topological) ductnets around them. A duct whose neighbour did not make the trip -
 *   somebody ran ducting across the dock boundary - drops it and rebuilds its net.
 * - An aborted move (blocked dock, immobilised hull) has already run beforeShuttleMove() on
 *   everything; initiate_docking() calls restore_plumbing_after_aborted_move() so the
 *   disconnected components come straight back in place.
 */

/datum/component/plumbing
	/// TRUE from the moment a shuttle move disconnected us in beforeShuttleMove() until the
	/// move lands (or aborts) and reconnect_after_shuttle_move() re-enables us.
	var/owes_shuttle_reconnect = FALSE

/datum/component/plumbing/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_ATOM_BEFORE_SHUTTLE_MOVE, PROC_REF(on_parent_before_shuttle_move))
	RegisterSignal(parent, COMSIG_ATOM_LATE_SHUTTLE_MOVE, PROC_REF(on_parent_late_shuttle_move))

/datum/component/plumbing/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, list(COMSIG_ATOM_BEFORE_SHUTTLE_MOVE, COMSIG_ATOM_LATE_SHUTTLE_MOVE))

/// Disconnect while every duct is still where we last saw it. Returns nothing so the move mode is untouched.
/datum/component/plumbing/proc/on_parent_before_shuttle_move(atom/movable/source, turf/newT, rotation, move_mode, obj/docking_port/mobile/moving_dock)
	SIGNAL_HANDLER

	// MOVE_CONTENTS is only granted by the turf, after every content has answered, so the area
	// flag is the only sign we are actually being carried (matching cables and lattices).
	if(!(move_mode & MOVE_AREA))
		return
	if(!active)
		return
	disable()
	owes_shuttle_reconnect = TRUE

/datum/component/plumbing/proc/on_parent_late_shuttle_move(atom/movable/source, turf/oldT, list/movement_force, move_dir)
	SIGNAL_HANDLER

	reconnect_after_shuttle_move()

/// Re-enable after a shuttle move landed or aborted, if beforeShuttleMove() disconnected us.
/datum/component/plumbing/proc/reconnect_after_shuttle_move()
	if(!owes_shuttle_reconnect)
		return
	owes_shuttle_reconnect = FALSE
	if(QDELETED(parent))
		return
	// enable() recomputes demand/supply connects from the parent's (now rotated) dir before
	// it looks around for ducts and neighbouring machines.
	enable()

/obj/machinery/duct/shuttleRotate(rotation, params)
	// pixel_x/pixel_y are the duct layer stagger from handle_layer(), not a position.
	params &= ~ROTATE_OFFSET
	. = ..()
	if(!rotation)
		return
	// Assigned directly rather than through add/remove_connects(): a locked bitfield is
	// still geometry and has to turn with the hull.
	var/rotated_connects = NONE
	for(var/check_dir in GLOB.cardinals)
		if(connects & check_dir)
			rotated_connects |= angle2dir(rotation + dir2angle(check_dir))
	connects = rotated_connects
	for(var/atom/movable/neighbour as anything in neighbours)
		neighbours[neighbour] = angle2dir(rotation + dir2angle(neighbours[neighbour]))
	update_appearance()

/obj/machinery/duct/lateShuttleMove(turf/oldT, list/movement_force, move_dir)
	. = ..()
	if(!active)
		return
	var/list/lost_neighbours = list()
	for(var/atom/movable/neighbour as anything in neighbours)
		if(QDELETED(neighbour) || neighbour.loc != get_step(src, neighbours[neighbour]))
			lost_neighbours += neighbour
	if(!length(lost_neighbours))
		return
	// Part of our network stayed behind. remove_duct() tears the shared ductnet down and
	// queues attempt_connect() on every current neighbour, so both halves regrow apart;
	// it is called before the stale entries are dropped so the stranded side rebuilds too.
	if(duct)
		duct.remove_duct(src)
	for(var/atom/movable/neighbour as anything in lost_neighbours)
		neighbours -= neighbour
		if(QDELETED(neighbour))
			continue
		if(istype(neighbour, /obj/machinery/duct))
			var/obj/machinery/duct/other = neighbour
			other.neighbours -= src
			other.generate_connects()
	generate_connects()
	attempt_connect()

/**
 * Called by initiate_docking() when a move aborts after preflight_check(): beforeShuttleMove()
 * has already disconnected every plumbing component on the hull, and nothing has moved, so
 * re-enabling them in place restores the exact network they had.
 */
/obj/docking_port/mobile/proc/restore_plumbing_after_aborted_move(list/old_turfs)
	for(var/i in 1 to length(old_turfs))
		CHECK_TICK
		var/turf/oldT = old_turfs[i]
		if(!oldT)
			continue
		for(var/atom/movable/thing as anything in oldT)
			for(var/datum/component/plumbing/plumber as anything in thing.GetComponents(/datum/component/plumbing))
				plumber.reconnect_after_shuttle_move()
