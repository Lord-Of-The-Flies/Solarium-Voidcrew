/**
 * Feral demons: AI-driven variants for map placement.
 *
 * The base /mob/living/basic/demon is a player-controlled wizard summon and has no
 * ai_controller, so a bare map placement stands still and lets itself be looted.
 * Ruins must place these subtypes instead.
 */
/mob/living/basic/demon/feral
	ai_controller = /datum/ai_controller/basic_controller/simple/simple_hostile_obstacles

/mob/living/basic/demon/slaughter/feral
	ai_controller = /datum/ai_controller/basic_controller/simple/simple_hostile_obstacles

// Ruin demons leave blood travel to the Stain's boons.
/mob/living/basic/demon/slaughter/feral/grant_loot()
	var/list/droppable_loot = ..()
	. = droppable_loot.Copy() // The parent shares its loot list with summoned slaughter demons.
	. -= /obj/item/organ/heart/demon
