import contextlib
import io
from pathlib import Path
import tempfile
import unittest

from tools.ci.check_ship_research_servers import invalid_servers, main, ship_maps
from tools.mapmerge2.dmm import TGM_HEADER


class ShipResearchServersTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def write_map(self, atom, *, tgm=True, relative="ship_test.dmm", unused=None):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        atoms = [atom, "/turf/open/floor/plating", "/area/template_noop"]
        separator = ",\n" if tgm else ","
        opening = "(\n" if tgm else "("
        text = f'{TGM_HEADER}\n' if tgm else ""
        text += f'"a" = {opening}{separator.join(atoms)})\n'
        if unused:
            text += f'"b" = {opening}{unused}{separator}/turf/open/space{separator}/area/space)\n'
        text += '\n(1,1,1) = {"\na\na\n"}\n'
        path.write_text(text, encoding="utf-8")
        return path

    def test_rejects_regular_servers_and_their_subtypes(self):
        for suffix in ("", "/master", "/preserved", "/shipwreck", "/relay_backup"):
            for tgm in (True, False):
                with self.subTest(suffix=suffix, tgm=tgm):
                    atom = f"/obj/machinery/rnd/server{suffix}"
                    path = self.write_map(atom, tgm=tgm)
                    self.assertEqual(invalid_servers(path), [((1, 1, 1), atom), ((1, 2, 1), atom)])

    def test_accepts_ship_servers_relays_and_their_subtypes(self):
        for suffix in ("/ship", "/ship/custom", "/relay", "/relay/custom"):
            with self.subTest(suffix=suffix):
                path = self.write_map(f"/obj/machinery/rnd/server{suffix}")
                self.assertEqual(invalid_servers(path), [])

    def test_variable_edits_do_not_hide_a_regular_server(self):
        path = self.write_map('/obj/machinery/rnd/server{\n\tname = "ship R&D server"\n\t}')
        self.assertEqual(len(invalid_servers(path)), 2)

    def test_ignores_paths_in_strings_and_unplaced_dictionary_entries(self):
        path = self.write_map(
            '/obj/item/paper{\n\tdesc = "/obj/machinery/rnd/server"\n\t}',
            unused="/obj/machinery/rnd/server",
        )
        self.assertEqual(invalid_servers(path), [])

    def test_scans_all_hull_variants_and_nested_modules_only(self):
        hull = self.write_map("/obj/item/paper", relative="_maps/voidcrew/ships/ship_variant.dmm")
        module = self.write_map("/obj/item/paper", relative="_maps/voidcrew/ship_modules/new_ship/lab_variant.dmm")
        self.write_map("/obj/machinery/rnd/server", relative="_maps/map_files/station/research.dmm")
        self.assertEqual(ship_maps(self.root), [hull, module])
        with self.assertRaises(ValueError):
            ship_maps(self.root / "missing")

    def test_failure_exit_code_and_actionable_diagnostics(self):
        path = self.write_map("/obj/machinery/rnd/server")
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = main([str(path), "--github"])
        self.assertEqual(result, 1)
        self.assertIn(f"::error file={path.as_posix()}::Tile (1, 2, 1)", output.getvalue())
        self.assertIn("Use /obj/machinery/rnd/server/ship", output.getvalue())

    def test_valid_map_passes_and_unreadable_maps_fail(self):
        path = self.write_map("/obj/machinery/rnd/server/ship")
        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(main([str(path)]), 0)
            self.assertEqual(main([str(self.root / "missing.dmm")]), 1)
            path.write_text("", encoding="utf-8")
            self.assertEqual(main([str(path)]), 1)


if __name__ == "__main__":
    unittest.main()
