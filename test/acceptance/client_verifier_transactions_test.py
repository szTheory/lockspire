"""Strict behavioral contracts for installed transaction witnesses."""

from __future__ import annotations

import sys
from pathlib import Path
import hashlib
import json
import types
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import clean_room_verifier_upgrade as runner  # noqa: E402
import verifier_receipts  # noqa: E402


def receipt(scope: str, case_ids: list[str]) -> dict[str, object]:
    observations = {}
    for index, case_id in enumerate(case_ids):
        if scope == "contention":
            observations[case_id] = {
                "outcome": "pass", "executed": True,
                "holder_backend_pid": 101, "contender_backend_pid": 202,
                "blocker_observed": True, "material_conflict": index == 0,
                "credential_pair_coherent": True, "durable_state_verified": True,
            }
        else:
            observations[case_id] = {"outcome": "pass", "executed": True}
    if scope == "atomicity":
        observations[case_ids[0]].update({
            "reached_insert": True, "unchanged_ciphertext": True,
            "absent_committed_audit": True,
        })
        observations[case_ids[1]].update({
            "provisional_change_observed": True, "outer_rollback_observed": True,
            "unchanged_ciphertext": True, "absent_committed_audit": True,
        })
        observations[case_ids[2]].update({
            "nested_report_rejected": True, "mutation_absent": True,
            "success_report_after_commit": True, "report_absent_before_commit": True,
        })
    candidate = {
        "kind": "checkout",
        "version": "1.6.1",
        "archive_sha256": "b" * 64,
        "tree_sha256": "c" * 64,
        "source_revision": "d" * 40,
        "runner_revision": "a" * 40,
    }
    binding = json.dumps(
        {key: candidate[key] for key in ("archive_sha256", "source_revision", "tree_sha256")},
        sort_keys=True,
        separators=(",", ":"),
    ).encode()
    candidate["source_proof"] = hashlib.sha256(binding).hexdigest()
    return {
        "schema": "lockspire-installed-verifier-v1",
        "scope": scope,
        "run_id": "0123456789abcdef0123456789abcdef",
        "runner": "a" * 40,
        "pair": "locked",
        "store": "delegated",
        "candidate": {**candidate},
        "host": {
            "vendor_tree_sha256": "c" * 64,
            "compiled_candidate_sha256": "f" * 64,
            "resolved_dependency_verified": True,
            "lock_sha256": "1" * 64,
            "phoenix": "1.8.13",
            "live_view": "1.2.10",
        },
        "runtime": {"elixir": "1.19.5", "otp": "28", "postgresql": "14.17"},
        "stable_case_ids": case_ids,
        "observations": observations,
        "executed_count": len(case_ids),
        "partial": True,
    }


class VerifierTransactionContracts(unittest.TestCase):
    def test_both_transaction_groups_dispatch_to_one_host_witness_module(self) -> None:
        self.assertEqual(runner.MODULES["contention"], ("verifier_transactions", "run_contention_group"))
        self.assertEqual(runner.MODULES["atomicity"], ("verifier_transactions", "run_atomicity_group"))

    def test_cli_dispatch_executes_both_group_entrypoints(self) -> None:
        calls: list[tuple[str, dict[str, object]]] = []
        module = types.ModuleType("verifier_transactions")

        def contention(**kwargs: object) -> list[object]:
            calls.append(("contention", kwargs))
            return []

        def atomicity(**kwargs: object) -> list[object]:
            calls.append(("atomicity", kwargs))
            return []

        module.run_contention_group = contention
        module.run_atomicity_group = atomicity
        with mock.patch.dict(sys.modules, {"verifier_transactions": module}):
            self.assertEqual(runner.main(["--group", "contention", "--pair", "all", "--store", "delegated"]), 0)
            self.assertEqual(runner.main(["--group", "atomicity", "--pair", "all", "--store", "delegated"]), 0)
        self.assertEqual([name for name, _kwargs in calls], ["contention", "atomicity"])
        self.assertTrue(all(kwargs["pair"] == "all" and kwargs["store"] == "delegated" for _name, kwargs in calls))

    def test_contention_requires_both_real_lock_orders(self) -> None:
        contention_case_ids = getattr(verifier_receipts, "CONTENTION_CASE_IDS", None)
        self.assertEqual(
            contention_case_ids,
            [
                "VPROOF-02-CONTENTION-ROTATION-FIRST",
                "VPROOF-02-CONTENTION-MAINTENANCE-FIRST",
            ],
        )
        candidate = receipt("contention", contention_case_ids)
        verifier_receipts.validate_receipt(candidate, expected_pair="locked", expected_store="delegated")
        candidate["observations"][contention_case_ids[1]]["contender_backend_pid"] = 101
        with self.assertRaises(ValueError):
            verifier_receipts.validate_receipt(candidate, expected_pair="locked", expected_store="delegated")

    def test_atomicity_requires_insert_rollback_and_outer_commit_order_witnesses(self) -> None:
        atomicity_case_ids = getattr(verifier_receipts, "ATOMICITY_CASE_IDS", None)
        self.assertEqual(
            atomicity_case_ids,
            [
                "VPROOF-02-ATOMICITY-AUDIT-INSERT-ROLLBACK",
                "VPROOF-02-ATOMICITY-OUTER-ROLLBACK",
                "VPROOF-02-ATOMICITY-NESTED-REPORT-AND-COMMIT-ORDER",
            ],
        )
        atomicity_case_ids = atomicity_case_ids or ["VPROOF-02-ATOMICITY-AUDIT-INSERT-ROLLBACK"]
        candidate = receipt("atomicity", atomicity_case_ids)
        verifier_receipts.validate_receipt(candidate, expected_pair="locked", expected_store="delegated")
        candidate["observations"][atomicity_case_ids[0]]["reached_insert"] = False
        with self.assertRaises(ValueError):
            verifier_receipts.validate_receipt(candidate, expected_pair="locked", expected_store="delegated")


if __name__ == "__main__":
    unittest.main()
