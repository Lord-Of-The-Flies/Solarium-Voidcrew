/**
 * # Trader outpost orbit point
 *
 * Выводит интерьер торгового аванпоста в меню орбиты призраков.
 *
 * Аванпосты не лежат на карте как ландмарк надписи: SSovermap ставит по одному на
 * зону и подгружает интерьер из шаблона в рантайме (см. outpost.dm). Зато шаблон
 * интерьера - обычная .dmm, и якорь можно положить прямо в неё, картой.
 * setup_orbit_token() после загрузки находит такой якорь и, если его нет, ставит
 * свой на свободный пол конкорса.
 *
 * Якорь - обычная точка интереса, поэтому он едет вместе с остальными через
 * SSpoints_of_interest: сам появляется в разделе Maps, по нему можно кликнуть, и
 * из меню исчезает, если аванпост удалили. Орбита ведёт призрака на пол конкорса,
 * а не на тайл аванпоста на овермапе: овермап - это стратегическая карта, а
 * админу нужен осмотр interior'а.
 *
 * Якорь бывает двух видов и оба равнозначны:
 * - положенный в .dmm интерьера (карта уже содержит tradepost_orbit_token);
 * - созданный аванпостом в рантайме, если в .dmm его нет.
 * Тип сам регистрирует себя как точку интереса в Initialize, поэтому вариант из
 * карты виден в меню не хуже рантаймного, а setup_orbit_token() переиспользует
 * его вместо того, чтобы ставить второй. Имя в обоих случаях берётся из аванпоста.
 */
// SOL-EDIT START

/obj/effect/landmark/tradepost_orbit_token
	name = "trade outpost"
	desc = "Ghost orbit anchor for a trader outpost interior."
	icon_state = "x4"

	/// Аванпост, которому принадлежит якорь. Ссылка нежная: если аванпост удалят
	/// первым, якорь не должен держать удалённый датум.
	var/obj/structure/overmap/trader_outpost/outpost

/obj/effect/landmark/tradepost_orbit_token/Initialize(mapload)
	. = ..()
	// Второй раз вызывать make_point_of_interest не нужно: AddElement идемпотентен,
	// а этот же путь используется и для якоря, созданного в рантайме.
	SSpoints_of_interest.make_point_of_interest(src)

/obj/effect/landmark/tradepost_orbit_token/Destroy()
	SSpoints_of_interest.remove_point_of_interest(src)
	outpost = null
	return ..()

/// Якорь орбиты внутри интерьера этого аванпоста, null пока интерьер не поднят.
var/obj/effect/landmark/tradepost_orbit_token/orbit_token

/**
 * Ставит якорь орбиты на конкорсе.
 *
 * Вызывается в конце успешного load_level(). Если в .dmm интерьера якорь уже
 * положен, он переиспользуется - иначе в меню было бы по два входа на аванпост.
 * Имя берётся из аванпоста, то есть из outpost_name магазина, так что подписи
 * "Undertow Exchange", "Quartermain Depot" и "Waystation Halcyon" не приходится
 * дублировать руками в каждом .dmm. Повторные вызовы безопасны.
 */
/obj/structure/overmap/trader_outpost/proc/setup_orbit_token()
	if(orbit_token || !loaded || !template_bottom_left || !outpost_template?.width || !outpost_template?.height)
		return

	// Тип указан прямо в переменной: DM не выводит его из возвращаемого значения
	// прока, а безтиповой var не даёт обращаться к .name/.desc/. Имя переменной -
	// anchor_token, а не token, потому что token() - встроенный прок DM.
	var/obj/effect/landmark/tradepost_orbit_token/anchor_token = get_interior_orbit_token()
	if(!anchor_token)
		var/turf/anchor = get_orbit_anchor_turf()
		if(!anchor)
			log_mapping("TRADER OUTPOST: '[name]' has no clear floor and no placed orbit token.")
			return
		anchor_token = new /obj/effect/landmark/tradepost_orbit_token(anchor)

	// get_other_pois() показывает в меню atom.name, поэтому имя обязано совпадать
	// с именем аванпоста, а не называться "trade outpost" или "Outfitter".
	anchor_token.name = name
	anchor_token.desc = "Interior of [name]."
	anchor_token.outpost = src
	SSpoints_of_interest.make_point_of_interest(anchor_token)
	orbit_token = anchor_token
	log_mapping("TRADER OUTPOST: ghost orbit anchor ready for '[name]' at [anchor_token.x], [anchor_token.y], [anchor_token.z].")

/obj/structure/overmap/trader_outpost/Destroy()
	. = ..()
	// QDEL_NULL идёт после родителя, чтобы POI снялся в Destroy() самого якоря.
	QDEL_NULL(orbit_token)

/// Якорь, уже положенный в .dmm интерьера, если карта его содержит.
/obj/structure/overmap/trader_outpost/proc/get_interior_orbit_token() as /obj/effect/landmark/tradepost_orbit_token
	for(var/turf/candidate as anything in get_interior_turfs())
		for(var/obj/effect/landmark/tradepost_orbit_token/placed in candidate)
			return placed
	return null

/// Все тайлы поднятого интерьера, включая стены. Тип указан явно по той же
/// причине, что и выше: block() без аннотации даёт безтиповый результат.
/obj/structure/overmap/trader_outpost/proc/get_interior_turfs() as /list
	var/turf/top_right = locate(
		template_bottom_left.x + outpost_template.width - 1,
		template_bottom_left.y + outpost_template.height - 1,
		template_bottom_left.z
	)
	return block(template_bottom_left, top_right)

/**
 * Тайл конкорса, на котором можно оставить призрака.
 *
 * Сначала идут ниши лифта - единственное место в каждом интерьере аванпоста,
 * гарантированно состоящее из ровного проходимого пола (именно туда сажает
 * attack_ghost()). Если ниш нет - любой свободный тайл загруженного шаблона.
 */
/obj/structure/overmap/trader_outpost/proc/get_orbit_anchor_turf() as /turf
	for(var/turf/alcove as anything in lobby_alcove_turfs)
		if(is_open_orbit_anchor(alcove))
			return alcove

	for(var/turf/candidate as anything in get_interior_turfs())
		if(is_open_orbit_anchor(candidate))
			return candidate

	return null

/**
 * TRUE, если призрака можно поставить на T, не засунув его внутрь декораций:
 * открытый пол, на котором ничего плотного не стоит.
 *
 * Плотность берётся из переменных типа, а не из результатов Initialize, поэтому
 * проверка работает и на roundstart-пути, где интерьер поднимается ещё до того,
 * как его атомы проинициализированы.
 */
/proc/is_open_orbit_anchor(turf/T)
	if(!istype(T, /turf/open/floor) || T.density)
		return FALSE
	// /obj, а не /obj/movable: в содержимом тайла лежит вся мебель конкорса, и она
	// неподвижна - узкий тип в цикле просто выкинул бы её из проверки.
	for(var/obj/thing in T)
		if(thing.density)
			return FALSE
	return TRUE
// SOL-EDIT END
