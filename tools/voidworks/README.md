# Voidworks compatibility

`compatibility.json` tells the Voidworks map editor which version of the editor contract this game code provides. Voidworks checks it when a project loads:

- If the number here is **lower** than the one Voidworks was built for, Voidworks tells the mapper their game code is out of date and to pull the latest master.
- If the number here is **higher**, Voidworks tells them to update Voidworks before saving ships.

Increase `voidworks_api` by one when a change here breaks what Voidworks reads or writes, such as:

- ship, room, crew or theme variables and datums that the Ship Workshop edits
- the files and folders under `voidcrew/mapping/ship_projects/`
- `tools/ship_previews/generate_ship_previews.py` and the preview metadata format
- planet and ruin definitions that the Planet and Ruin Workshops edit

Release a Voidworks version that understands the new number at the same time, so mappers are not left without a working editor.

CI posts a warning (never a failure) on PRs that change the files declaring what Voidworks reads, listed in `tools/ci/check_voidworks_compat.py`, without touching `compatibility.json`. Most such changes are compatible; the warning only asks you to check.

## Horusheresy maps in Available Maps

Voidworks scans only `_maps` and `voidcrew/_maps` for its **Available Maps** list. Maps in `Horusheresy/_maps` still open through **Open Map...**, but they are not listed.

To list them, run this from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File tools/voidworks/sync_horusheresy_maps.ps1
```

The script mirrors `Horusheresy/_maps` into `voidcrew/_maps/horusheresy` using NTFS hardlinks. Both paths point at the same file, so saving a map through Voidworks updates the original file in `Horusheresy/_maps`. The mirror is ignored by git. Re-run the script after adding new maps to `Horusheresy/_maps`, and reopen the project in Voidworks so the cached map list refreshes.
