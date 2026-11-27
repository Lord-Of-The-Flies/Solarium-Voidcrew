/**
 * One accurate sentence about whether you can come back this round.
 *
 * The observe and ghost confirmations both hardcoded "You will not be able to play this round!",
 * which is simply wrong on a server that allows respawning - players were being talked out of
 * ghosting by a warning that did not apply, and pointed at nothing when it did. This reads the
 * real respawn config and points at the button below, so the prompt matches what the server is
 * actually running.
 */
/proc/get_respawn_notice()
	var/respawn_setting = CONFIG_GET(flag/allow_respawn)
	if(respawn_setting == RESPAWN_FLAG_DISABLED)
		return "Вы не сможете играть в этом раунде!"

	var/notice = "Вы сможете вернуться позже: нажмите кнопку «Возродиться» на панели действий слева вверху, затем выберите корабль в меню присоединения."
	if(respawn_setting == RESPAWN_FLAG_NEW_CHARACTER)
		notice += " Вернуться придётся другим персонажем."

	var/respawn_delay = CONFIG_GET(number/respawn_delay)
	if(respawn_delay)
		var/delay_text = replacetext(DisplayTimeText(respawn_delay), " minutes", " мин.")
		delay_text = replacetext(delay_text, " minute", " мин.")
		notice += " Сначала нужно подождать [delay_text] после смерти, если только вы не погибли в [ZONE_NAME_GREEN]."

	return notice

/**
 * Respawn action button for ghosts.
 *
 * Respawning is otherwise only reachable through the "Respawn" verb in the OOC tab, which most
 * players never open. Every observer gets this button instead. It reds out whenever
 * [/mob/verb/abandon_mob] would refuse the respawn - the config has respawning switched off, or
 * the respawn delay is still running - and counts the remaining delay down on the button itself.
 */
/datum/action/cooldown/respawn
	name = "Возродиться"
	desc = "Покинуть этого персонажа и вернуться в лобби, чтобы присоединиться заново как кто-то новый."
	button_icon = 'icons/hud/actions.dmi'
	button_icon_state = "ghost"
	check_flags = NONE
	transparent_when_unavailable = TRUE
	//A ghost watching another ghost has a respawn button of its own already.
	show_to_observers = FALSE

/datum/action/cooldown/respawn/Grant(mob/granted_to)
	. = ..()
	if(!owner)
		return
	refresh_respawn_delay()
	//ghostize() writes the time of death onto the persistent client *after* it has already
	//moved the player into the ghost, so the value read above can still be a stale one from an
	//earlier death. Tick for a moment so the button settles on the real delay.
	if(CONFIG_GET(number/respawn_delay))
		START_PROCESSING(SSfastprocess, src)

/**
 * Works out when the owner is next allowed to respawn, mirroring [/mob/proc/check_respawn_delay].
 *
 * Recomputed on every check rather than cached, both because of the ordering above and because
 * an admin can change the respawn delay mid-round.
 */
/datum/action/cooldown/respawn/proc/refresh_respawn_delay()
	var/delay = CONFIG_GET(number/respawn_delay)
	var/datum/persistent_client/persistent_client = owner?.persistent_client
	var/time_of_death = persistent_client?.time_of_death
	//A death in the Neutral Zone waives the delay (see green_zone_respawn.dm).
	if(persistent_client?.died_in_green_zone())
		time_of_death = 0
	next_use_time = (delay && time_of_death) ? (time_of_death + delay) : 0
	if(next_use_time > world.time)
		START_PROCESSING(SSfastprocess, src)

/datum/action/cooldown/respawn/process()
	refresh_respawn_delay()
	return ..()

/datum/action/cooldown/respawn/IsAvailable(feedback = FALSE)
	refresh_respawn_delay()
	. = ..()
	if(!.)
		//Ghosts read chat rather than their own sprite, and it is where abandon_mob() reports
		//its own refusals, so the reason goes there rather than into a balloon alert.
		if(feedback && owner && next_use_time > world.time)
			var/wait_text = replacetext(DisplayTimeText(next_use_time - world.time, 1), " minutes", " мин.")
			wait_text = replacetext(wait_text, " minute", " мин.")
			to_chat(owner, span_warning("Нужно подождать [wait_text] до возрождения!"))
		return FALSE
	//Admins are allowed to talk their way past a disabled config, so leave their button lit.
	if(CONFIG_GET(flag/allow_respawn) == RESPAWN_FLAG_DISABLED && !check_rights_for(owner.client, R_ADMIN))
		if(feedback)
			to_chat(owner, span_boldnotice("Возрождение отключено!"))
		return FALSE
	return TRUE

/datum/action/cooldown/respawn/Activate(atom/target)
	//abandon_mob() runs its own confirmation prompts and delay checks. Deliberately no
	//StartCooldown() here - the delay is driven by the owner's time of death instead.
	owner.abandon_mob()
	return TRUE

/**
 * A ghost has no client when it is created, so there is no screen to hang a button off yet.
 * Hud creation is the first point a player is actually looking through this ghost, which is also
 * the point Grant() can place a button.
 *
 * Deliberately not an /mob/dead/observer/Initialize() override: observer already defines
 * Initialize(), and a second definition of the same proc on the same type replaces it rather than
 * extending it, which would drop all of the upstream ghost setup.
 */
/mob/dead/observer/create_mob_hud()
	. = ..()
	if(!.)
		return
	if(locate(/datum/action/cooldown/respawn) in actions)
		return
	var/datum/action/cooldown/respawn/respawn_button = new(src)
	respawn_button.Grant(src)
