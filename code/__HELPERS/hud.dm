/// Width of a single hand slot background in the hands icon files. // SOL-EDIT - HORIZON_DREAM
#define UI_HAND_SLOT_WIDTH 48
/// How far a held item has to be nudged right to sit centered in its slot. // SOL-EDIT - HORIZON_DREAM
#define UI_HAND_ITEM_X_OFFSET ((UI_HAND_SLOT_WIDTH - ICON_SIZE_X) / 2)

/proc/ui_hand_position(i) //values based on old hand ui positions (CENTER:-/+16,SOUTH:5)
	return ui_hand_position_offset(i)

/// Same anchor as ui_hand_position, but for the held item itself instead of the slot background.
/// Slot backgrounds are UI_HAND_SLOT_WIDTH wide while items are ICON_SIZE_X wide, so items
/// need the extra UI_HAND_ITEM_X_OFFSET to end up centered rather than glued to the left edge. // SOL-EDIT - HORIZON_DREAM
/proc/ui_hand_item_position(i)
	return ui_hand_position_offset(i, UI_HAND_ITEM_X_OFFSET)

/proc/ui_hand_position_offset(i, x_offset = 0)
	var/x_off = IS_LEFT_INDEX(i) ? 0 : -1.5 // SOL-EDIT  - HORIZON_DREAM- было "-1"
	var/y_off = round((i-1) / 2)
	return "CENTER+[x_off]:[16 + x_offset],SOUTH+[y_off]:5"

/// Screen location of the DROP button: flush against the left edge of the hand slots block.
/// The two hand slot backgrounds are UI_HAND_SLOT_WIDTH wide and sit side by side, so the
/// block runs from the right slot's left edge to the left slot's right edge. DROP hugs the
/// left of that block and SWAP the right, leaving the middle free for the action progress bar.
/// Kept as two separate procs because the buttons no longer share a single centre anchor. // SOL-EDIT - HORIZON_DREAM
/proc/ui_drophand_position(mob/M)
	var/y_off = round((M.held_items.len-1) / 2)
	return "CENTER-1,SOUTH+[y_off+1]:5"

/// Screen location of the SWAP button: flush against the right edge of the hand slots block.
/// SWAP is only ICON_SIZE_X wide while the block is 2 * UI_HAND_SLOT_WIDTH, so it sits a full
/// tile in from the right slot's left edge. // SOL-EDIT - HORIZON_DREAM
/proc/ui_swaphand_position(mob/M)
	var/y_off = round((M.held_items.len-1) / 2)
	return "CENTER+1,SOUTH+[y_off+1]:5"

/proc/ui_perk_position(perk_count)
	var/y_off = perk_count < 1 ? 0 : perk_count/2
	return "WEST+0.5:12,NORTH-2-[y_off]:20"
