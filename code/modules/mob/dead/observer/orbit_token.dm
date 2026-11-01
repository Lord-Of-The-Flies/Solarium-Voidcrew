// SOL-EDIT START - маркер статичной карты для меню орбиты
// Тип живёт в корне, а не в solarium/_astramilitarum.dm, потому что сам маркер
// лежит в корневой карте _maps/map_files/generic/CentCom.dmm: неопределённый тип
// в .dmm ломает сборку без -DASTRAMILITARUM.

/obj/effect/landmark/centcom_orbit_token
	name = "CentComm Orbit Token"
	desc = "Маркер для добавления CentComm в список Orbit меню."
	icon_state = "x4"

/obj/effect/landmark/centcom_orbit_token/Initialize(mapload)
	. = ..()
	SSpoints_of_interest.make_point_of_interest(src)

/obj/effect/landmark/centcom_orbit_token/Destroy()
	SSpoints_of_interest.remove_point_of_interest(src)
	return ..()

/// Ставим в раздел Maps. Без /proc/ - это переопределение хука, а новое объявление
/// дало бы "duplicate definition".
/datum/orbit_menu/poi_category(atom/poi)
	if(istype(poi, /obj/effect/landmark/centcom_orbit_token))
		return ORBIT_CATEGORY_MAPS
	return ..()

/// В меню показываем название карты, а не имя ландмарка.
/datum/orbit_menu/get_misc_data(atom/movable/atom_poi)
	. = ..()
	if(istype(atom_poi, /obj/effect/landmark/centcom_orbit_token))
		.[1]["full_name"] = "Central Command"
		.[1]["extra"] = "Central Command"
	return .
// SOL-EDIT END
