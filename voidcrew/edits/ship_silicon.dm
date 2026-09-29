/// Shared by roster construction and the CI map checks.
/proc/ship_job_definition_error(list/definition)
	if(!islist(definition))
		return "Ship job must be a list"
	var/role = definition["role"] || "crew"
	if(!(role in list("crew", "cyborg", "ai")))
		return "Unknown ship role: [role]"
	if(role == "crew")
		var/datum/outfit/job/outfit = definition["outfit"]
		if(!ispath(outfit, /datum/outfit/job) || !ispath(initial(outfit.jobtype), /datum/job))
			return "Ship crew needs an outfit with a valid job type"
		if(definition["borg_model"])
			return "Only cyborg roles can select a borg model"
		return null
	var/slots = definition["slots"]
	if(!isnum(slots) || slots < 1 || slots > 128 || round(slots) != slots)
		return "Silicon roles need 1-128 whole slots"
	if(definition["officer"] || definition["outfit"])
		return "Silicon roles cannot use human outfits or be ship officers"
	var/model = definition["borg_model"]
	if(role == "cyborg" && (!ispath(model, /obj/item/robot_model) || model == /obj/item/robot_model))
		return "Cyborg roles need a borg model"
	if(role == "ai" && model)
		return "AI roles cannot select a borg model"
	return null

/obj/structure/overmap/ship/proc/available_crew_ai_core()
	for(var/obj/structure/ai_core/latejoin_inactive/core as anything in GLOB.latejoin_ai_cores)
		if(!QDELETED(core) && core.available && core.active && (get_area(core) in shuttle.shuttle_areas) && isfloorturf(get_turf(core)))
			return core
	return null

/// Silicon roles are opt-in: never draft someone into an immobile AI or a borg.
/datum/job/proc/ship_roundstart_opted_in(mob/dead/new_player/player)
	if(ship_role == "crew")
		return TRUE
	return !!player.client?.prefs?.ship_category_preferences?[JOB_CAT_SILICON]

/datum/job/proc/finish_ship_silicon_spawn(mob/living/silicon/crewmate, obj/structure/overmap/ship/ship)
	ship.enlist_crewmember(crewmate)
	ship.manifest[crewmate.real_name] = src
	crewmate.radio?.bind_comms_to_ship(ship.shuttle)
	if(iscyborg(crewmate))
		var/mob/living/silicon/robot/borg = crewmate
		borg.model.transform_to(ship_borg_model, TRUE, FALSE)
		borg.update_appearance()
		borg.TryConnectToAI()
	else if(isAI(crewmate))
		for(var/datum/mind/member as anything in ship.ship_team.members)
			if(iscyborg(member.current))
				var/mob/living/silicon/robot/borg = member.current
				if(!borg.connected_ai)
					borg.TryConnectToAI()

/mob/living/silicon/robot/proc/crew_ai()
	var/obj/structure/overmap/ship/ship = mind?.assigned_role?.crew_ship_ref?.resolve()
	if(!ship)
		var/area/shuttle/voidcrew/ship_area = get_area(src)
		if(istype(ship_area))
			ship = ship_area.shuttle_port?.current_ship
	if(!ship)
		return null
	var/mob/living/silicon/ai/chosen
	for(var/datum/mind/member as anything in ship.ship_team.members)
		if(!isAI(member.current) || member.current.stat == DEAD)
			continue
		var/mob/living/silicon/ai/candidate = member.current
		if(!chosen || length(candidate.connected_robots) < length(chosen.connected_robots))
			chosen = candidate
	return chosen
