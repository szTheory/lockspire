"""Contracts for the installed verifier core host seam."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import build_provider  # noqa: E402
import clean_room_verifier_upgrade  # noqa: E402


class CoreBuilderBoundaryTest(unittest.TestCase):
    def test_group_selected_sources_are_explicit_and_missing_sources_fail_closed(self) -> None:
        selector = getattr(build_provider, "selected_host_fixture_sources", None)
        self.assertTrue(callable(selector), "builder must expose selected optional host fixture sources")
        with tempfile.TemporaryDirectory() as source_temporary:
            source_root = Path(source_temporary)
            for relative in (
                "verifier_rollout.exs",
                "verifier_endpoints.exs",
                "lib/clean_room_provider/verifier_transactions.ex",
                "lib/clean_room_provider/verifier_recovery.ex",
                "lib/clean_room_provider/verifier_disclosure.ex",
            ):
                path = source_root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("fixture", encoding="utf-8")
            paths = selector(
                {"rollout", "endpoints", "contention", "recovery", "disclosure"},
                source_root=source_root,
            )
        self.assertEqual(
            {path.name for path in paths},
            {
                "verifier_rollout.exs",
                "verifier_endpoints.exs",
                "verifier_transactions.ex",
                "verifier_recovery.ex",
                "verifier_disclosure.ex",
            },
        )
        with tempfile.TemporaryDirectory() as temporary:
            missing_root = Path(temporary)
            with self.assertRaises(build_provider.PackageInputError):
                selector({"disclosure"}, source_root=missing_root)

    def test_lifetime_adapter_declares_only_public_maintenance_callbacks(self) -> None:
        adapter = ROOT / "test/clean_room/provider_host/lib/clean_room_provider/lifetime_client_store.ex"
        source = adapter.read_text(encoding="utf-8")
        for callback in (
            "Lockspire.Storage.ClientVerifierMaintenance",
            "Lockspire.Storage.UsedJtiStore",
            "verifier_maintenance_contract",
            "verifier_inventory_page",
            "compare_and_rewrap",
            "record_used_jti",
        ):
            self.assertIn(callback, source)
        self.assertNotIn("Lockspire.TestRepo", source)
        self.assertNotIn("Lockspire.TestSupport", source)


class CoreMatrixSelectionTest(unittest.TestCase):
    def test_runner_accepts_all_pairs_and_stores_for_the_four_cell_core_matrix(self) -> None:
        try:
            args = clean_room_verifier_upgrade.parse_args(
                ["--pair", "all", "--store", "all", "--group", "core"]
            )
        except SystemExit:
            args = None
        self.assertIsNotNone(args, "installed runner must accept the finite all-pair/all-store core matrix")
        self.assertEqual((args.pair, args.store, args.group), ("all", "all", "core"))


if __name__ == "__main__":
    unittest.main()
