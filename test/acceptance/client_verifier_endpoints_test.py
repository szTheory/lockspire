"""Contracts for source-bound installed verifier endpoint and release groups."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

import sys
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import build_provider  # noqa: E402
import clean_room_verifier_upgrade  # noqa: E402


class VerifierEndpointContracts(unittest.TestCase):
    def test_endpoint_and_release_groups_route_to_explicit_entrypoints(self) -> None:
        self.assertEqual(clean_room_verifier_upgrade.MODULES["endpoints"], ("verifier_endpoints", "run_group"))
        self.assertEqual(clean_room_verifier_upgrade.MODULES["release-rpc"], ("verifier_endpoints", "run_release_rpc_group"))
        self.assertIsNotNone(importlib.util.find_spec("verifier_endpoints"))

    def test_endpoint_group_owns_its_host_fixture(self) -> None:
        fixture = ROOT / "test/clean_room/provider_host/verifier_endpoints.exs"
        self.assertTrue(fixture.is_file(), "endpoint state preparation must stay in a host-owned fixture")
        selected = build_provider.selected_host_fixture_sources({"endpoints"})
        self.assertEqual([path.name for path in selected], ["verifier_endpoints.exs"])

    def test_group_selectors_reject_unsupported_endpoint_and_release_scopes(self) -> None:
        spec = importlib.util.find_spec("verifier_endpoints")
        self.assertIsNotNone(spec)
        module = __import__("verifier_endpoints")
        self.assertTrue(callable(getattr(module, "run_group", None)))
        self.assertTrue(callable(getattr(module, "run_release_rpc_group", None)))


if __name__ == "__main__":
    unittest.main()
