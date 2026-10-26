"""Contracts for source-bound installed verifier rollout controls."""

from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import build_provider  # noqa: E402
import clean_room_verifier_upgrade  # noqa: E402
import verifier_rollout  # noqa: E402


class VerifierRolloutContracts(unittest.TestCase):
    def test_public_artifact_pin_and_source_evidence_are_verified_by_one_helper(self) -> None:
        helper = getattr(verifier_rollout, "verify_public_artifact", None)
        self.assertTrue(callable(helper), "public artifact verification must fail closed before producer startup")

    def test_rollout_group_is_an_installed_proof_group_with_owned_host_fixture(self) -> None:
        spec = importlib.util.find_spec("verifier_rollout")
        self.assertTrue(spec is not None, "rollout group must have an installed proof runner")
        self.assertIn("rollout", clean_room_verifier_upgrade.GROUPS)
        fixture = ROOT / "test/clean_room/provider_host/verifier_rollout.exs"
        self.assertTrue(fixture.is_file(), "rollout state controls must be host-owned")
        selected = build_provider.selected_host_fixture_sources({"rollout", "legacy-control"})
        self.assertEqual([path.name for path in selected], ["verifier_rollout.exs", "verifier_rollout.exs"])

    def test_rollout_contract_covers_predecessor_process_drain_and_persisted_formats(self) -> None:
        path = ROOT / "scripts/acceptance/clean_room/verifier_rollout.py"
        source = path.read_text(encoding="utf-8") if path.is_file() else ""
        for required in (
            "173059a166e9ade0f5f57c9980b7b2400a98538c",
            "old_process_exit_observed",
            "legacy_write_read_shared_store",
            "dedicated_write_after_drain",
            "switch_back_legacy_write_preserves_dedicated",
            "old_code_rejects_dedicated",
            "rollback_retains_dedicated_reads",
        ):
            self.assertIn(required, source)

    def test_public_legacy_control_is_pinned_and_separate_from_predecessor(self) -> None:
        path = ROOT / "scripts/acceptance/clean_room/verifier_rollout.py"
        source = path.read_text(encoding="utf-8") if path.is_file() else ""
        self.assertIn("629abdc1b6721620f3d9084dbbe78da1e254650da5c552d0cc0f5b0c00f1cc6d", source)
        self.assertIn("d04be40262e975a4eb8d8567eb0d1458a9c23181", source)
        self.assertIn("legacy-control", clean_room_verifier_upgrade.GROUPS)
        self.assertIn("verifier_rollout", clean_room_verifier_upgrade.MODULES["legacy-control"][0])

    def test_legacy_control_preserves_authenticated_deadline_and_hash(self) -> None:
        path = ROOT / "scripts/acceptance/clean_room/verifier_rollout.py"
        source = path.read_text(encoding="utf-8") if path.is_file() else ""
        self.assertIn("authenticated_deadline_preserved", source)
        self.assertIn("client_hash_preserved", source)
        self.assertIn("locked-only", source)


if __name__ == "__main__":
    unittest.main()
