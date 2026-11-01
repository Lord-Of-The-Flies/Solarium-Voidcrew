# Mapping for Voidcrew

Use [Voidcrew's maintained StrongDMM fork](https://github.com/voidcrew/StrongDMM)
to build maps for this codebase. It provides normal StrongDMM mapping tools,
plus **Ship Workshop** for editing assembled ships and creating ships, rooms,
areas and crew, and **Ruin Workshop** for ruin projects.

## Set up the editor

1. Download the Windows x64 ZIP from the [latest release](https://github.com/voidcrew/StrongDMM/releases/latest).
2. **Extract the entire ZIP into a folder**, then run `StrongDMM.exe` from that
   folder. Running it inside the ZIP can prevent it from starting.
3. Work in a branch or a separate testing checkout of Voidcrew. Choose
   **Voidcrew > Open Project...** and select that checkout's `tgstation.dme`.
   This loads its types and icons; saves go to the checkout you opened.
4. For ships, open **Voidcrew > Ship Workshop** and follow the
   [ship mapper guide](../modules/ship_upgrades/MAPPER_GUIDE.md). For ruins, use
   **Voidcrew > Ruin Workshop**. Other maps can be opened as ordinary `.dmm` files.

Save maps in **TGM format**; they still use the `.dmm` extension. For ordinary
map tabs, check the save format under **File > Preferences...**. Ship Workshop
saves its maps as TGM. Keep edits focused so the map diff is reviewable.

## Find the right files

| Task | Maps | Definitions and instructions |
| --- | --- | --- |
| Build or edit a ship hull | [`_maps/voidcrew/ships/`](../../_maps/voidcrew/ships/) | Start in Ship Workshop with the [ship mapper guide](../modules/ship_upgrades/MAPPER_GUIDE.md). |
| Edit a modular room or ship variant | [`_maps/voidcrew/ship_modules/`](../../_maps/voidcrew/ship_modules/) and the ship hulls | Select the room and variant in Ship Workshop. The [technical guide](../modules/ship_upgrades/TECHNICAL_GUIDE.md) covers definitions, alignment and manual registration. |
| Edit a Voidcrew ruin | [`_maps/voidcrew/RandomRuins/`](../../_maps/voidcrew/RandomRuins/) | [`voidcrew/datums/ruins/`](../datums/ruins/) registers ruins. The parent template's `prefix` determines the map directory; some ruins use upstream `_maps/RandomRuins/` paths. |
| Edit a bitrunning safehouse | [`_maps/safehouses/`](../../_maps/safehouses/) | Read the [safehouse guide](../../_maps/safehouses/README.md). |

A map's registration tells the game where and how to load it. Workshop creation
actions write the registrations they support along with the maps; review and
submit those files together. If creating a map outside those actions, follow
an existing template for that map family and include new `.dm` files in
`tgstation.dme`. Changes to modular hulls and modules also need
[regenerated ship previews](../modules/ship_upgrades/MAPPER_GUIDE.md#regenerate-ship-previews).

## Placement rules

1. **Use the correct object subtype.** For example, use the intended closet type
   instead of changing another closet's `icon_state`. Adjust access separately
   when needed. Check typepaths in this checkout before copying from another fork.
2. **Use directional subtypes where available.** Verify the mounting side and
   facing in the editor and in game. A light's `/directional/north` mounts on the
   north wall; sinks and showers use a different facing convention. Other
   directional objects need an appropriate `dir`.
3. **Keep atmos layers consistent.** Scrubbers use **piping layer 2** and vents
   use **piping layer 4**. Connect their pipes on the matching layer. This refers
   to `piping_layer`, not the sprite's drawing `layer`.
4. **Set access deliberately.** Give air alarms and APCs the intended crew access
   instead of using all-access variants. Do not place Cargo department budget
   cards as station equipment.
5. **Keep equipment reachable on foot.** Place furniture flush against a wall,
   or leave a connected walkway behind it. A row of tables or racks one tile
   away can trap wall equipment behind a strip accessible only by climbing.
   Check that each machine, locker and supply table has a usable approach.
6. **Keep doors and spawn exits clear.** Check the path all the way into the
   room, including both sides of doors. A clear doorway can still lead into a
   pocket blocked by furniture. On modular ships, inspect the assembled hull
   and module together: the door may be in a different file from the obstruction.
7. **Mount equipment against a full wall face.** Use suitable `/nodiagonal` or
   never-diagonal walls for interior partitions with wall mounts. Rounded corner
   sprites can leave buttons, lights and APCs floating. Preserve this distinction
   when changing a theme's wall materials.
8. **Use hidden pipes under walls.** Visible pipes should not pass through
   closed wall turfs. Arrange dense storage side by side where possible so the
   rear closet or crate is not hidden behind another.

For modular ships, the ship's slot notes also specify which tiles, machines,
power and atmos equipment belong to the hull. Follow those notes when changing
a room; infrastructure ownership differs between ships.

## Check an edit

Run commands from the repository root. The Python map tools need `bidict` and
`PyYAML`; ship previews also need `Pillow`:

```sh
python -m pip install bidict PyYAML Pillow
```

1. **Check the saved map.** Keep the TGM header, confirm object directions and
   areas, and review `git diff`. If the editor saved another format, use the
   [map merger tools](../../tools/mapmerge2/README.md) to convert it.
2. **Lint the changed maps.** Supply their paths explicitly. For example:

   ```sh
   python -m tools.maplint.source _maps/voidcrew/ships/ship_delta_a.dmm
   ```

   Replace the example with your changed files. The [map linter](../../tools/maplint/README.md)
   checks its configured rules; it does not prove the map is playable or that
   every typepath exists.

   Existing maps can have lint findings already. Compare with the unchanged
   version, fix problems introduced by your edit, and review findings on the
   tiles you touched. Record remaining findings when submitting the change.
3. **Regenerate previews for modular ship edits.** Commit the resulting PNG and
   manifest changes with the maps. Inspect the preview with the modules selected.
4. **Build with BYOND 516 through Juke.** On Windows:

   ```bat
   tools/build/build.bat
   ```

   On Linux, use `tools/build/build.sh`. See the [build instructions](../../tools/build/README.md).
5. **Load and playtest the map.** Check walking routes, access, lighting, power,
   atmos and machinery. A successful build does not prove that a dynamically
   loaded map is correct. Modular ships need the [shipyard test procedure](../modules/ship_upgrades/MAPPER_GUIDE.md#test-in-game).
