/obj/item/circuitboard/machine/rdserver/ship
	build_path = /obj/machinery/rnd/server/ship

/obj/item/circuitboard/machine/rdserver/relay
	name = "R&D Relay"
	build_path = /obj/machinery/rnd/server/relay

/**
 * # The R&D Kit ships flat-packed machines
 *
 * This kit used to hand a crew six loose boards, which meant framing and populating five machines
 * with stock parts before any of it worked - and then linking the server to the console by hand,
 * because `/obj/machinery/computer/rdconsole/Initialize()` only auto-links through
 * CONNECT_TO_RND_SERVER_ROUNDSTART when `no_default_techweb_link` is unset, and this fork sets it
 * (see code/__DEFINES/research.dm, VOIDCREW EDIT CHANGE). Setting an R&D bay up from scratch was
 * therefore the least interesting part of the round.
 *
 * ## What stays loose, and why
 *
 * The R&D console stays a circuit board. `/obj/item/flatpack` types its board as
 * `/obj/item/circuitboard/machine`, and the console is a `circuitboard/computer` - widening that
 * type for one item is not worth the blast radius. The ship disk also stays as it is.
 *
 * To keep the console buildable without a trip to a lathe, the kit now carries the standard
 * computer frame materials alongside the board: 5 iron sheet, 2 glass, 5 cable coil.
 *
 * ## Follow-up worth knowing about
 *
 * A flatpack adopts any component items placed inside it as `replacement_parts` on deploy, so a
 * "deluxe" kit that ships upgraded stock parts inside each flatpack is a small, self-contained
 * change if anyone wants one.
 */
/datum/storage/box/rndkit
	max_slots = 12
	max_specific_storage = WEIGHT_CLASS_SMALL
	max_total_storage = 99

/obj/item/storage/box/rndboards/all
	name = "\proper the Research & Development Kit"
	desc = "A box containing everything required to setup Research & Development equipment. The machines arrive flat-packed: deploy each one with a multitool, then frame the console from the included materials."
	illustration = "scicircuit"
	storage_type = /datum/storage/box/rndkit

/obj/item/storage/box/rndboards/all/PopulateContents()
	new /obj/item/flatpack(src, new /obj/item/circuitboard/machine/rdserver/ship())
	new /obj/item/flatpack(src, new /obj/item/circuitboard/machine/protolathe())
	new /obj/item/flatpack(src, new /obj/item/circuitboard/machine/destructive_analyzer())
	new /obj/item/flatpack(src, new /obj/item/circuitboard/machine/circuit_imprinter())
	new /obj/item/circuitboard/computer/rdconsole(src)
	new /obj/item/computer_disk/ship_disk(src)
	// Frame material for the console, which cannot be flat-packed - see the header.
	new /obj/item/stack/sheet/iron(src, 5)
	new /obj/item/stack/sheet/glass(src, 2)
	new /obj/item/stack/cable_coil(src, 5)
