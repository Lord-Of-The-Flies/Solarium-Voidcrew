"""Reject ordinary R&D servers in ship hulls and modules before compilation."""

import argparse
from pathlib import Path

from tools.mapmerge2.dmm import DMM, parse_map_atom


SERVER = "/obj/machinery/rnd/server"
ALLOWED_SERVERS = (f"{SERVER}/ship", f"{SERVER}/relay")
MAP_ROOTS = ("_maps/voidcrew/ships", "_maps/voidcrew/ship_modules")


def is_subtype(path: str, parent: str) -> bool:
    return path == parent or path.startswith(parent + "/")


def ship_maps(repo_root: Path) -> list[Path]:
    maps = []
    for relative_root in MAP_ROOTS:
        root_maps = sorted((repo_root / relative_root).rglob("*.dmm"))
        if not root_maps:
            raise ValueError(f"No ship maps found under {relative_root}")
        maps.extend(root_maps)
    return maps


def invalid_servers(map_path: Path) -> list[tuple[tuple[int, int, int], str]]:
    map_data = DMM.from_file(map_path)
    if not map_data.grid:
        raise ValueError("Map has no placed tiles")

    # Inspect atom paths, not descriptions or other variable edits containing paths.
    bad_keys = {}
    for key, atoms in map_data.dictionary.items():
        paths = (parse_map_atom(atom)[0].strip() for atom in atoms)
        bad_keys[key] = [
            path for path in paths
            if is_subtype(path, SERVER)
            and not any(is_subtype(path, allowed) for allowed in ALLOWED_SERVERS)
        ]

    # Only placed dictionary entries spawn objects. Report each offending tile.
    return [
        (coordinates, path)
        for coordinates, key in sorted(map_data.grid.items())
        for path in bad_keys[key]
    ]


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("maps", nargs="*", type=Path, help="Defaults to all ship hulls and modules")
    parser.add_argument("--github", action="store_true", help="Emit GitHub error annotations")
    args = parser.parse_args(argv)
    try:
        maps = args.maps or ship_maps(Path("."))
    except ValueError as error:
        parser.error(str(error))

    failed = False
    for map_path in maps:
        prefix = f"::error file={map_path.as_posix()}::" if args.github else f"{map_path}: "
        try:
            problems = invalid_servers(map_path)
        except Exception as error:
            print(f"{prefix}Cannot validate ship research servers: {error}")
            failed = True
            continue
        for coordinates, path in problems:
            print(
                f"{prefix}Tile {coordinates}: {path} cannot supply ship research. "
                f"Use {SERVER}/ship for an onboard R&D server; "
                f"{SERVER}/relay is reserved for outpost research links."
            )
            failed = True

    if not failed:
        print(f"Checked {len(maps)} ship maps: no incompatible R&D servers.")
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
