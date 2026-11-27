/proc/getviewsize(view = world.view)
	SHOULD_BE_PURE(TRUE)

	if(isnum(view))
		//resetting back to 0- this is the same as just checking !view but we want to be clear the point of the check.
		if(view == 0)
			return list(0, 0)
		var/totalviewrange = (view < 0 ? -1 : 1) + 2 * view
		return list(totalviewrange, totalviewrange)
	else
		var/list/viewrangelist = splittext(view, "x")
		return list(text2num(viewrangelist[1]), text2num(viewrangelist[2]))


/// Takes a string or num view, and converts it to pixel width/height in a list(pixel_width, pixel_height)
/proc/view_to_pixels(view)
	if(!view)
		return list(0, 0)
	var/list/view_info = getviewsize(view)
	view_info[1] *= ICON_SIZE_X
	view_info[2] *= ICON_SIZE_Y
	return view_info

/**
* Frustrated with bugs in can_see(), this instead uses viewers for a much more effective approach.
* ### Things to note:
* - Src/source must be a mob. `viewers()` returns mobs.
* - Adjacent objects are always considered visible.
*/

/// The default tile-distance between two atoms for one to consider the other as visible.
#define DEFAULT_SIGHT_DISTANCE 7
/// Sight range to check against a mob: use its actual viewport (widescreen is 19x15, not 15x15),
/// otherwise targets at the horizontal edges of the screen are considered invisible.
#define SIGHT_RANGE(observer) ((observer)?.client?.view || DEFAULT_SIGHT_DISTANCE)

/// Basic check to see if the src object can see the target object.
#define CAN_I_SEE(target) ((src in viewers(SIGHT_RANGE(src), target)) || in_range(target, src))


/// Checks the visibility between two other objects.
#define CAN_THEY_SEE(target, source) ((source in viewers(SIGHT_RANGE(source), target)) || in_range(target, source))


/// Further checks distance between source and target.
#define CAN_SEE_RANGED(target, source, dist) ((source in viewers(dist, target)) || in_range(target, source))
