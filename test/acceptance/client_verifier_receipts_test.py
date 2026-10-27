"""Closed-matrix contract tests for installed verifier receipts."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import verifier_receipts  # noqa: E402


class CompleteMatrixContracts(unittest.TestCase):
    def test_required_scope_is_explicit_and_keeps_both_disclosure_receipts(self) -> None:
        required = verifier_receipts.required_receipt_keys()
        self.assertEqual(len(required), 26)
        self.assertIn(("core", "locked", "builtin"), required)
        self.assertIn(("rollout", "floor", "delegated"), required)
        self.assertIn(("legacy-control", "locked", "builtin"), required)
        self.assertIn(("release-rpc", "locked", "builtin"), required)
        self.assertIn(("disclosure", "locked", "delegated"), required)
        self.assertIn(("disclosure-failure", "locked", "delegated"), required)
        self.assertNotIn(("legacy-control", "floor", "delegated"), required)

    def test_aggregate_rejects_missing_duplicate_unknown_and_zero_case_links(self) -> None:
        required = verifier_receipts.required_receipt_keys()
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_complete_matrix([], expected_runner="a" * 40)
        rows = [
            {"scope": scope, "pair": pair, "store": store,
             "run_id": f"{index:032x}", "receipt_sha256": f"{index + 1:064x}",
             "runner_revision": "a" * 40,
             "candidate_source_archive_tree": ["d" * 40, "e" * 64, "f" * 64],
             "host_lock_sha256": "1" * 64, "compiled_candidate_sha256": "2" * 64,
             "executed_count": len(verifier_receipts.expected_case_ids((scope, pair, store))),
             "outcome": "pass",
             "stable_case_ids": verifier_receipts.expected_case_ids((scope, pair, store))}
            for index, (scope, pair, store) in enumerate(required)
        ]
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_matrix_links(rows[:-1], expected_runner="a" * 40)
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_matrix_links(rows + [rows[0]], expected_runner="a" * 40)
        changed = [*rows[:-1], {**rows[-1], "scope": "unknown"}]
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_matrix_links(changed, expected_runner="a" * 40)
        changed = [*rows[:-1], {**rows[-1], "stable_case_ids": []}]
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts.validate_matrix_links(changed, expected_runner="a" * 40)


if __name__ == "__main__":
    unittest.main()
