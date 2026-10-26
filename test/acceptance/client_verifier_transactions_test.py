"""Strict behavioral contracts for installed transaction witnesses."""

from __future__ import annotations

import sys
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import clean_room_verifier_upgrade as runner  # noqa: E402
import verifier_receipts  # noqa: E402


def receipt(scope: str, case_ids: list[str]) -> dict[str, object]:
    observations = {
        case_id: {
            "outcome": "pass",
            "executed": True,
            "holder_backend_pid": 101,
            "contender_backend_pid": 202,
            "blocker_observed": True,
            "durable_state_verified": True,
        }
        for case_id in case_ids
    }
    if scope == "atomicity":
        for result in observations.values():
            result.update(
                {
                    "reached_insert": True,
                    "unchanged_ciphertext": True,
                    "absent_committed_audit": True,
                    "report_after_commit": True,
                }
            )
    return {
        "schema": "lockspire-installed-verifier-v1",
        "scope": scope,
        "run_id": "0123456789abcdef0123456789abcdef",
        "runner": "a" * 40,
        "pair": "locked",
        "store": "delegated",
        "candidate": {
            "kind": "checkout",
            "version": "1.6.1",
            "archive_sha256": "b" * 64,
            "tree_sha256": "c" * 64,
            "source_revision": "d" * 40,
            "runner_revision": "a" * 40,
            "source_proof": "e" * 64,
        },
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
        self.assertEqual(runner.MODULES["contention"], ("verifier_transactions", "run_group"))
        self.assertEqual(runner.MODULES["atomicity"], ("verifier_transactions", "run_group"))

    def test_contention_requires_both_real_lock_orders(self) -> None:
        contention_case_ids = getattr(verifier_receipts, "CONTENTION_CASE_IDS", None)
        self.assertEqual(
            contention_case_ids,
            [
                "VPROOF-02-CONTENTION-ROTATION-FIRST",
                "VPROOF-02-CONTENTION-MAINTENANCE-FIRST",
            ],
        )
        candidate = receipt("contention", (contention_case_ids or ["VPROOF-02-CONTENTION-ROTATION-FIRST"])[:1])
        with self.assertRaises(ValueError):
            verifier_receipts.validate_receipt(candidate, expected_pair="locked", expected_store="delegated")

    def test_atomicity_requires_insert_rollback_and_outer_commit_order_witnesses(self) -> None:
        atomicity_case_ids = getattr(verifier_receipts, "ATOMICITY_CASE_IDS", None)
        self.assertEqual(
            atomicity_case_ids,
            [
                "VPROOF-02-ATOMICITY-AUDIT-INSERT-ROLLBACK",
                "VPROOF-02-ATOMICITY-OUTER-ROLLBACK",
                "VPROOF-02-ATOMICITY-REPORT-AFTER-COMMIT",
            ],
        )
        atomicity_case_ids = atomicity_case_ids or ["VPROOF-02-ATOMICITY-AUDIT-INSERT-ROLLBACK"]
        candidate = receipt("atomicity", atomicity_case_ids)
        candidate["observations"][atomicity_case_ids[0]]["reached_insert"] = False
        with self.assertRaises(ValueError):
            verifier_receipts.validate_receipt(candidate, expected_pair="locked", expected_store="delegated")


if __name__ == "__main__":
    unittest.main()
