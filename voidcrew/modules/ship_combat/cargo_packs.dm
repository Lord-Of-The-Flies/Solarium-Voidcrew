// Ship Combat Cargo Supply Packs
// Purchasable missile component crates and combat equipment

/datum/supply_pack/ship_combat
	group = "Ship Combat"
	crate_type = /obj/structure/closet/crate/secure/gear

// ========== MISSILE COMPONENT PACKS ==========

/datum/supply_pack/ship_combat/missile_frames
	name = "Ящик с ракетными каркасами"
	desc = "Ящик с четырьмя ракетными каркасами. \
		Требуется проводка, схема наведения и боеголовка для подготовки."
	cost = CARGO_CRATE_VALUE * 4
	contains = list(/obj/structure/ship_missile = 4)
	crate_name = "ящик с ракетными каркасами"

/datum/supply_pack/ship_combat/tracking_circuits
	name = "Ящик со схемами наведения ракет"
	desc = "Ящик с шестью схемами наведения ракет. \
		Необходимы для систем наведения ракет."
	cost = CARGO_CRATE_VALUE * 3
	contains = list(/obj/item/electronics/ship_missile_tracking = 6)
	crate_name = "ящик со схемами наведения"

/datum/supply_pack/ship_combat/warhead_standard
	name = "Ящик со стандартными боеголовками"
	desc = "Ящик с четырьмя стандартными ракетными боеголовками. \
		Умеренный урон, подходят для общего боя."
	cost = CARGO_CRATE_VALUE * 8
	contains = list(/obj/item/bombcore/missile = 4)
	crate_name = "ящик со стандартными боеголовками"

/datum/supply_pack/ship_combat/warhead_light
	name = "Ящик с лёгкими боеголовками"
	desc = "Ящик с шестью лёгкими ракетными боеголовками. \
		Меньше урона, но дешевле."
	cost = CARGO_CRATE_VALUE * 5
	contains = list(/obj/item/bombcore/missile/light = 6)
	crate_name = "ящик с лёгкими боеголовками"

/datum/supply_pack/ship_combat/warhead_heavy
	name = "Ящик с тяжёлыми боеголовками"
	desc = "Ящик с двумя тяжёлыми ракетными боеголовками. \
		Огромный урон, но дорого."
	cost = CARGO_CRATE_VALUE * 12
	contains = list(/obj/item/bombcore/missile/heavy = 2)
	crate_name = "ящик с тяжёлыми боеголовками"

// Chemical missiles now use standard chemical grenades - no cargo pack needed
// Players order grenade casings from Science/Medical cargo and build their own

/datum/supply_pack/ship_combat/missiles_kit
	name = "Набор для сборки ракет"
	desc = "Стартовый набор для сборки ракет: четыре каркаса, \
		четыре схемы наведения, четыре стандартные боеголовки и катушка кабеля."
	cost = CARGO_CRATE_VALUE * 12
	contains = list(
		/obj/structure/ship_missile = 4,
		/obj/item/electronics/ship_missile_tracking = 4,
		/obj/item/bombcore/missile = 4,
		/obj/item/stack/cable_coil = 1,
	)
	crate_name = "набор для сборки ракет"

// ========== EQUIPMENT PACKS ==========

/datum/supply_pack/ship_combat/launcher_kit
	name = "Набор с ракетной пусковой установкой"
	desc = "Стартовый набор для корабельного боя: плата ракетной пусковой \
		установки, два каркаса, схемы наведения и две стандартные боеголовки."
	cost = CARGO_CRATE_VALUE * 8
	contains = list(
		/obj/item/circuitboard/machine/ship_combat/missile_launcher = 1,
		/obj/structure/ship_missile = 2,
		/obj/item/electronics/ship_missile_tracking = 2,
		/obj/item/bombcore/missile = 2,
		/obj/item/stack/cable_coil = 1,
	)
	crate_name = "набор с ракетной пусковой установкой"

/datum/supply_pack/ship_combat/combat_starter
	name = "Стартовый набор для корабельного боя"
	desc = "Всё необходимое для начала корабельного боя: \
		плата боевой консоли, плата пусковой установки, каркасы, схемы наведения, боеголовки и проводка."
	cost = CARGO_CRATE_VALUE * 15
	contains = list(
		/obj/item/circuitboard/computer/ship_combat_console = 1,
		/obj/item/circuitboard/machine/ship_combat/missile_launcher = 1,
		/obj/structure/ship_missile = 4,
		/obj/item/electronics/ship_missile_tracking = 4,
		/obj/item/bombcore/missile = 2,
		/obj/item/bombcore/missile/light = 2,
		/obj/item/stack/cable_coil = 1,
	)
	crate_name = "стартовый набор для корабельного боя"
