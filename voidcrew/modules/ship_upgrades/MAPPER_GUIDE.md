# Ship mapper guide

Build and edit ships in **Ship Workshop**, part of
[Voidcrew's maintained StrongDMM fork](https://github.com/voidcrew/StrongDMM).
Use normal mapping tools for floors, walls, objects and utilities. The Workshop
handles ship-specific tasks such as assembling rooms, creating areas and
registering new content.

Start with the [editor setup and placement rules](../../GUIDES/mapping.md).
For DM definitions, loader behavior, connector geometry and manual registration,
use the separate [modular ship technical guide](TECHNICAL_GUIDE.md).

| Task | Instructions |
| --- | --- |
| Change an existing ship or room | [Open and edit a ship](#open-and-edit-a-ship) |
| Build a ship from scratch | [Build a new ship](#build-a-new-ship) |
| Give rooms their own areas | [Create or assign ship areas](#create-or-assign-ship-areas) |
| Make a room swappable | [Make an upgrade room](#make-an-upgrade-room) |
| Add another room layout or a ship theme | [Room options](#create-another-room-option) and [ship variants](#add-a-ship-variant-theme) |
| Configure docking or jobs | [Docking port](#set-up-the-docking-port) and [crew](#configure-crew-and-equipment) |
| Finish an edit | [Review and save](#review-and-save), then [test in game](#test-in-game) |

## How a modular ship fits together

| Piece | What it means while mapping |
| --- | --- |
| Hull | The permanent ship layout and equipment shared by its room options. |
| Upgrade room (slot) | A position on the hull that can hold different room options. |
| Room option (module) | The contents loaded into that position, such as a diner or greenhouse. It can add crew jobs. |
| Ship variant (theme) | A version of the ship with its own hull appearance, available room options and optional crew roster. |

The Workshop displays the hull and selected rooms together. **You can edit this
assembled view**: your changes go to the hull or room file selected in
**Part to edit**. Saving writes the individual source files used by the game.

## Open and edit a ship

1. Open your checkout's `tgstation.dme`, then **Voidcrew > Ship Workshop**.
2. Under **1 Choose a ship**, search for and select the ship.
3. In **2 Build**, expand **Room options & ship variants**. Choose the
   **Ship variant**, when available, and the room options you want to work on.
   Choosing an option in **Room: ...** also makes that room the active part to edit.
4. Map normally. Check **Editing: ...** above the canvas before making changes.
   Choose the hull in **Part to edit** for permanent walls, doors and utilities.
5. Use **3 Review & save** when ready to save your work.

These controls answer different questions:

| Control | Effect |
| --- | --- |
| **Part to edit** | Chooses where your next edits go. The displayed room choices stay the same. |
| **Room: ...** | Chooses the option shown in that slot and activates it for editing. |
| **Ship variant** | Switches the hull theme and resets the displayed rooms to its defaults. |
| **Show whole ship** | Shows the assembled ship, centers it and adjusts the zoom. |
| **Areas** | Shows area markers; it is the same setting as **View > Areas** (`Ctrl+1` on Windows). |

For an existing room, read its ship's slot notes before moving infrastructure:
[Delta](ships/delta.dm) and [Scarab](ships/scarab.dm), for example, divide power
and atmos equipment between hull and modules differently. Inspect paths and
equipment in the assembled view. **Advanced view & source files > Show only the
part being edited** helps identify which objects belong to that part.

A themed room can have its own map file. An edit to one theme's room does not
automatically update the others. The source filename is shown under
**Advanced view & source files**.

## Build a new ship

For a small first layout, use **three rooms: a permanent bridge and two
swappable rooms**, with two ship themes.

1. Choose **Create a new ship...**, enter a unique ship name, choose a canvas
   size, then **Create ship & start building**. The starting variant is
   **Standard**. You receive an empty canvas with a mobile docking port.
2. With the hull selected in **Part to edit**, draw the three rooms, exterior,
   doors and connecting route using normal StrongDMM tools.
3. [Assign ship areas](#create-or-assign-ship-areas) to the mapped hull, including
   walls and doors. Bridge and the other rooms can each have a different area
   while belonging to the same ship.
4. Add permanent systems: helm, one crew spawn cryopod with a clear exit,
   propulsion, power, air supply, lighting and alarms. An existing working ship
   is a useful equipment reference.
5. Furnish the two swappable rooms, then [make each an upgrade room](#make-an-upgrade-room).
   Leave the bridge in the hull.
6. [Create another option](#create-another-room-option) for each upgrade room.
   For example, one slot could offer a workshop or laboratory, and the other
   a lounge or greenhouse. Give each option a distinct name.
7. Finish those options in Standard, then [copy the ship as a new variant](#add-a-ship-variant-theme),
   such as Industrial. You now have two themes with copies of every room
   option. Edit the second theme's hull and rooms to suit it.
8. [Set up docking](#set-up-the-docking-port) at the entrance and
   [configure the crew and equipment](#configure-crew-and-equipment).
9. [Review and save](#review-and-save). Reopen the saved ship to continue later.

Finish the shared room choices before copying a theme so the copy includes
them all. Creating rooms or options later applies to the selected variant.

New ships start hidden from the player ship list. Keep that setting while
building. When ready to test the shipyard, use **Ship details & canvas size >
Edit ship details...**, clear **Hide from the player ship list**, and save.
That panel also contains the description and hull cost; crew jobs are configured
separately. A saved draft still needs previews, a build and a playtest.

## Create or assign ship areas

1. Choose the hull in **Part to edit** for permanent room areas.
2. Use the normal **Grab tool (`3`)** to select the room's tiles.
3. Choose **Make or assign an area...**.
4. Select an existing ship area and use **Assign area to selected tiles**, or
   enter an **Area name** and use **Create area for selection**.

Area assignment changes the area only. Your floors, walls and objects stay as
mapped. Creating an area makes a real ship-owned area type; saving writes its
definition and includes it in the project.

For an irregular room, create the area once, then assign additional selections
or use **Paint selected area**. Without a selection, open **Ship areas...** to
create an area for later painting. Give distinct rooms distinct area names.

Ordinary room modules inherit the hull's areas. Put shared power and alarm
groupings in the hull; assigning an area while a module is active makes it part
of that module instead.

## Make an upgrade room

This works on existing ships as well as ships created in the Workshop.

1. Select the hull in **Part to edit** and choose the intended ship variant.
2. Use **Grab (`3`)** to select the room rectangle.
3. Choose **Make an upgrade room...**, enter a unique **Room name**, then
   **Make this an upgrade room**.
4. The new room becomes the active part. Edit its contents normally.

The action creates the slot and its first room option, handles alignment and
registration, and moves the selected room's nonpermanent objects into the
module. Floors, walls, areas, doors and core utilities stay in the hull.
Check the resulting split before replacing equipment: machinery ownership
depends on its type.

Keep the selection inside the intended room, clear of other upgrade slots and
permanent routes. On a themed ship, the new room is added to the selected
variant. Other variants are unchanged.

## Create another room option

1. Choose the existing room option in **Room: ...** so it is active.
2. Under **Room options & ship variants**, choose **Create another room option...**.
3. Enter a unique **Room option name**. Leave **Start with an empty room**
   unchecked to copy the current option, or check it to start without its contents.
4. Choose **Create room option**, then map the new option in the assembled ship.

A copied option includes its room jobs; review them in **Crew & equipment...**.
An empty option begins without those jobs. The new option is available in the
selected variant. Changing its furniture does not change the original option.

Keep essential hull equipment and door approaches usable in every option.
Existing ship slot notes still apply to copied and empty rooms.

## Add a ship variant (theme)

For ships created through the Workshop:

1. Finish the hull and room options you want to use as the starting point.
2. Under **Room options & ship variants**, choose **Copy ship as a new variant...**.
3. Enter a unique **Variant name**, then **Create ship variant**.
4. Use **Ship variant** to switch between versions. Edit the copied hull and
   each copied room option, and review the variant's crew.

The action copies the current hull and all room options available to that
variant, including options currently not displayed. Their map files can then
be edited independently. Job changes on a room option apply wherever that
option is used; use the variant roster for a theme-specific base crew.

**Adding themes to older, hand-written ships currently requires the
[technical theme workflow](TECHNICAL_GUIDE.md#add-a-theme).** Their existing
themes and rooms can still be edited in the Workshop.

## Set up the docking port

1. Select the hull and use **Grab (`3`)** to select the entrance airlock or a
   single entrance tile.
2. Choose **Set up docking port...**.
3. Set **Airlock opens to space** to the outward direction.
4. Choose **Place docking port here** or **Move docking port here**.

The helper configures the port's facing and ship-relative docking direction.
It applies to the current variant. Test docking and undocking in game after
changing the entrance, port or hull geometry.

## Configure crew and equipment

Open **Crew & equipment...**, then choose **Jobs belong to**:

| Roster | When it applies |
| --- | --- |
| Ship crew | The base crew. |
| Variant | Replaces the base crew for that variant. An empty roster inherits the ship crew. |
| Room option | Adds jobs when that option is installed. |

Select a job to edit it, or choose **+ Create job**. Set its name, **Number of
slots**, category and officer status. Choose a **Starting job outfit** to supply
the underlying job, ID access and default equipment. For a variant with a
different crew, **Copy ship crew into this variant** provides a starting roster.

Select an equipment slot, then choose an item using **Find an item** or the
normal **Environment** panel. The equipment preview updates as you choose.
Use **Backpack contents...** and **Belt contents...** for stored items and
quantities. Choose **Apply changes**, then save the Workshop.

The preview helps check appearance. Test actual spawning, access, item fit and
outfit behavior in game. Give each job the workspace and equipment it needs.

## Review and save

1. Choose **3 Review & save** and read **Map checks** for the displayed combination.
2. Inspect **Changes to save**, then choose **Save all changes**. This saves
   pending changes across ships edited in the Workshop. `Ctrl+S` also saves
   Workshop work.
3. Review `git diff` and new files. Submit changed maps, generated DM definitions,
   project JSON files and `tgstation.dme` changes together. The JSON files let
   the Workshop reopen the ship's settings, areas and crew.
4. Run the [general mapping checks](../../GUIDES/mapping.md#check-an-edit),
   regenerate previews and playtest the affected combinations.

An assembly check covers the displayed combination. It does not simulate
power, atmos or gameplay. Check each changed room with the hull in every theme
that uses it. Pricing and specialized registration changes are covered in the
[technical guide](TECHNICAL_GUIDE.md#costs-and-starting-equipment).

### Regenerate ship previews

The in-game shipyard uses committed images. Workshop saves do not regenerate them.

From the repository root, run:

```sh
python tools/ship_previews/generate_ship_previews.py
```

See [preview setup and output checks](TECHNICAL_GUIDE.md#regenerate-ship-previews)
for dependencies and discovery limits. Wait for the full run and inspect the
expected PNGs and `previews/manifest.json`; submit them with the map changes.
A room missing from the manifest needs investigation even if the command succeeds.

### Test in game

1. Build the project and start a local server. A new draft must be unhidden to
   appear in the player shipyard.
2. To test all choices without account unlocks, set `FREE_SHIPS 1` in your local
   `config/voidcrew/voidcrew_config.txt` before starting. Restore the previous
   setting after testing and keep that local change out of the submission.
3. From the latejoin ship menu, choose **Open Shipyard**. Select the hull,
   theme and rooms, inspect the preview, then launch. Check the crew jobs in
   the join menu.
4. Try the default configuration and each changed option in every affected theme.
   Walk from the spawn pod through the ship. Check equipment with the intended
   crew access, power, atmos and lighting, then docking and undocking.
5. Check runtime and mapping errors. State which combinations were actually
   playtested when submitting the change.

**Overmap.Spawn > Spawn Specific Ship** can test the default spawn path,
including hidden drafts. It does not open the customization selector or test
optional theme and room selections.

## If something looks wrong

| Problem | Next step |
| --- | --- |
| Editing the wrong part | Check **Editing: ...** and choose the hull or room in **Part to edit**. |
| Missing or doubled equipment | Inspect hull and room together; use **Show only the part being edited** to find the owning file. |
| A change appears in only one theme | Check the source filename, then edit the other affected theme's room. |
| Cannot create a name | Use a distinct name in that chooser; capitalization and extra whitespace do not make a duplicate unique. |
| Save reports an external or generated-file conflict | Preserve both versions and resolve the file conflict before continuing; see [source ownership](TECHNICAL_GUIDE.md#workshop-files-and-source-ownership). |
| Ship is missing, a room is shifted or its preview is stale | Follow the [technical troubleshooting table](TECHNICAL_GUIDE.md#troubleshooting). |
