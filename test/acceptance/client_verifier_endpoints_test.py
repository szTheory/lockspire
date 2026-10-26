"""Contracts for source-bound installed verifier endpoint and release groups."""

from __future__ import annotations

import importlib.util
import hashlib
import json
import io
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]

import sys
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import build_provider  # noqa: E402
import clean_room_verifier_upgrade  # noqa: E402
import verifier_endpoints  # noqa: E402
from verifier_receipts import ENDPOINT_CASE_IDS, ReceiptError, validate_receipt  # noqa: E402


class VerifierEndpointContracts(unittest.TestCase):
    def test_endpoint_and_release_groups_route_to_explicit_entrypoints(self) -> None:
        self.assertEqual(clean_room_verifier_upgrade.MODULES["endpoints"], ("verifier_endpoints", "run_group"))
        self.assertIsNotNone(importlib.util.find_spec("verifier_endpoints"))

    def test_endpoint_group_owns_its_host_fixture(self) -> None:
        fixture = ROOT / "test/clean_room/provider_host/verifier_endpoints.exs"
        self.assertTrue(fixture.is_file(), "endpoint state preparation must stay in a host-owned fixture")
        selected = build_provider.selected_host_fixture_sources({"endpoints"})
        self.assertEqual([path.name for path in selected], ["verifier_endpoints.exs"])

    def test_endpoint_selection_is_explicit_and_independent_of_matrix_width(self) -> None:
        import tempfile

        with tempfile.TemporaryDirectory() as temporary:
            receipt_dir = Path(temporary)
            cell_result = {"pair": "locked", "store": "builtin", "scope": "endpoints", "receipt_path": str(receipt_dir / "locked-builtin" / "receipt.json")}
            with mock.patch.object(verifier_endpoints, "_run_endpoint_cell", return_value=cell_result) as cell:
                output = io.StringIO()
                with redirect_stdout(output):
                    status = clean_room_verifier_upgrade.main([
                        "--pair", "all", "--store", "builtin", "--group", "endpoints",
                        "--receipt-dir", str(receipt_dir),
                    ])
            self.assertEqual(status, 0)
            self.assertEqual(cell.call_count, 2)
            self.assertEqual([call.args[0] for call in cell.call_args_list], ["locked", "floor"])
            summary = json.loads(output.getvalue().splitlines()[-1])
            self.assertEqual(summary["scope"], "endpoints")
            self.assertEqual(summary["executed_count"], 2)
            with self.assertRaisesRegex(build_provider.PackageInputError, "unsupported endpoint"):
                verifier_endpoints.run_group(pair="unknown", store="builtin", receipt_dir=receipt_dir)

    def test_endpoint_receipt_rejects_a_missing_mounted_route_observation(self) -> None:
        binding = {"archive_sha256": "a" * 64, "source_revision": "b" * 40, "tree_sha256": "c" * 64}
        candidate = {"kind": "checkout", "version": "1.6.1", **binding,
                     "runner_revision": "b" * 40,
                     "source_proof": hashlib.sha256(json.dumps(binding, sort_keys=True, separators=(",", ":")).encode()).hexdigest()}
        observation = {"outcome": "pass", "executed": True, "assertion_passed": True,
                       "fresh_jti": True, "http_status": 200}
        receipt = {
            "schema": "lockspire-installed-verifier-v1", "scope": "endpoints", "run_id": "d" * 32,
            "runner": "b" * 40, "pair": "locked", "store": "builtin", "candidate": candidate,
            "host": {"vendor_tree_sha256": "c" * 64, "compiled_candidate_sha256": "e" * 64,
                     "resolved_dependency_verified": True, "lock_sha256": "f" * 64,
                     "phoenix": "1.8.13", "live_view": "1.2.10"},
            "runtime": {"elixir": "1.19.5", "otp": "28", "postgresql": "14.17"},
            "stable_case_ids": list(ENDPOINT_CASE_IDS),
            "observations": {case: dict(observation) for case in ENDPOINT_CASE_IDS},
            "executed_count": len(ENDPOINT_CASE_IDS), "partial": True,
        }
        validate_receipt(receipt, expected_pair="locked", expected_store="builtin")
        del receipt["observations"][ENDPOINT_CASE_IDS[4]]
        with self.assertRaisesRegex(ReceiptError, "omit or add a case"):
            validate_receipt(receipt, expected_pair="locked", expected_store="builtin")


if __name__ == "__main__":
    unittest.main()
