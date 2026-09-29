/atom/movable/screen/screentip
	icon = null
	icon_state = null
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	screen_loc = "TOP,LEFT"
	maptext_height = 480
	maptext_width = 480
	maptext = ""
	layer = SCREENTIP_LAYER //Added to make screentips appear above action buttons (and other /atom/movable/screen objects)
	/// Weak reference so hovering cannot keep a deleted target alive.
	var/datum/weakref/hovered_atom_ref
	/// Invalidates text measurements that finish after the pointer has moved on.
	var/hover_version = 0
	var/showing_hover = FALSE
	/// Refreshed separately from mouse events, including while our ship is moving.
	var/fallback_maptext = ""

/atom/movable/screen/screentip/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	update_view()
	update_fallback()
	START_PROCESSING(SSprocessing, src)
	if(hud?.mymob)
		RegisterSignal(hud.mymob, list(COMSIG_MOB_LOGIN, COMSIG_MOB_LOGOUT), PROC_REF(on_connection_changed))

/atom/movable/screen/screentip/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	hovered_atom_ref = null
	return ..()

/atom/movable/screen/screentip/process(seconds_per_tick)
	if(!hud?.mymob?.client)
		return
	if(hovered_atom_ref && !hovered_atom_ref.resolve())
		clear_hover()
	update_fallback()

/// Starts a hover and returns the version to use for asynchronous text measurement.
/atom/movable/screen/screentip/proc/begin_hover(atom/target)
	hovered_atom_ref = WEAKREF(target)
	return ++hover_version

/// An exit from an older target must not clear a more recent hover.
/atom/movable/screen/screentip/proc/clear_hover(atom/target)
	if(target && !IS_WEAKREF_OF(target, hovered_atom_ref))
		return
	hovered_atom_ref = null
	hover_version++
	set_hover_text("")

/// Empty or suppressed hover text gives the fallback its turn.
/atom/movable/screen/screentip/proc/set_hover_text(new_maptext, text_y = 10)
	showing_hover = length(new_maptext) > 0
	if(showing_hover)
		maptext = new_maptext
		maptext_y = text_y
	else
		show_fallback()

/atom/movable/screen/screentip/proc/show_fallback()
	maptext = hud?.screentips_enabled == SCREENTIP_PREFERENCE_DISABLED ? "" : fallback_maptext
	maptext_y = 10

/atom/movable/screen/screentip/proc/update_fallback()
	fallback_maptext = hud?.screentips_enabled == SCREENTIP_PREFERENCE_DISABLED ? "" : get_fallback_maptext()
	if(!showing_hover)
		show_fallback()

/// Reused HUDs must not retain a hover from the previous connection.
/atom/movable/screen/screentip/proc/on_connection_changed(datum/source)
	SIGNAL_HANDLER
	update_fallback()
	clear_hover()

/// Reapply a changed preference even when the pointer stays still.
/atom/movable/screen/screentip/proc/refresh_hover()
	update_fallback()
	var/atom/target = hovered_atom_ref?.resolve()
	if(target && hud?.mymob?.client)
		target.on_mouse_enter(hud.mymob.client)
	else
		clear_hover()

/atom/movable/screen/screentip/proc/update_view(datum/source)
	SIGNAL_HANDLER
	if(!hud || !hud.mymob.canon_client?.view_size) //Might not have been initialized by now
		return
	maptext_width = view_to_pixels(hud.mymob.canon_client.view_size.getView())[1]
