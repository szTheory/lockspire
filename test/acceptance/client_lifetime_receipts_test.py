from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"))

from lifetime_receipts import validate_lifetime_receipt  # noqa: E402


REQUIRED = (
    "fresh.register_use",
    "fresh.secret_expiry_rotate",
    "fresh.management_put_recover",
    "fresh.app_expiry_disabled",
    "custom.issue_replace",
    "custom.shared_rollback",
    "custom.unsupported",
    "legacy.public",
    "legacy.tenant_auth",
)


class LifetimeReceiptsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.path = Path(self.temporary.name) / "receipt.json"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_complete_candidate_receipt_accepts_all_nine_positive_scenarios(self) -> None:
        receipt = self.receipt()
        self.path.write_text(json.dumps(receipt), encoding="utf-8")
        validated = validate_lifetime_receipt(self.path, expected_scenarios=REQUIRED)
        self.assertEqual(len(validated["scenarios"]), 9)

    def test_missing_required_scenario_is_rejected(self) -> None:
        receipt = self.receipt()
        receipt["scenarios"].pop()
        self.rejected(receipt)

    def test_skipped_required_scenario_is_rejected(self) -> None:
        receipt = self.receipt()
        receipt["scenarios"][-1]["outcome"] = "skipped"
        receipt["scenarios"][-1]["counts"] = {"executed": 1, "passed": 0, "failed": 0, "skipped": 1}
        receipt["counts"] = {"executed": 9, "passed": 8, "failed": 0, "skipped": 1}
        self.rejected(receipt)

    def test_candidate_source_identity_must_match_receipt_source(self) -> None:
        receipt = self.receipt()
        receipt["candidate"]["source_revision"] = "d" * 40
        self.rejected(receipt)

    def test_missing_cleanup_observation_is_rejected(self) -> None:
        receipt = self.receipt()
        receipt["cleanup"]["temporary_roots_removed"] = False
        self.rejected(receipt)

    def test_unknown_receipt_field_is_rejected(self) -> None:
        receipt = self.receipt()
        receipt["raw_log"] = "must never be retained"
        self.rejected(receipt)

    def rejected(self, receipt: dict[str, object]) -> None:
        self.path.write_text(json.dumps(receipt), encoding="utf-8")
        with self.assertRaises(AssertionError):
            validate_lifetime_receipt(self.path, expected_scenarios=REQUIRED)

    @classmethod
    def receipt(cls) -> dict[str, object]:
        candidate = {
            "kind": "tar",
            "version": "1.7.0",
            "archive_sha256": "b" * 64,
            "tree_sha256": "c" * 64,
            "source_revision": "a" * 40,
        }
        scenarios = []
        for identifier in REQUIRED:
            leg = identifier.split(".", 1)[0]
            scenarios.append({
                "id": identifier,
                "leg": leg,
                "contract_case_ids": ["C-APP-06"],
                "outcome": "passed",
                "observations": {"proof_observed": True},
                "event_counts": {"observed": 1},
                "audit_counts": {"observed": 1},
                "counts": {"executed": 1, "passed": 1, "failed": 0, "skipped": 0},
            })
        return {
            "schema_version": 1,
            "source_revision": "a" * 40,
            "candidate": candidate,
            "scenarios": scenarios,
            "counts": {"executed": 9, "passed": 9, "failed": 0, "skipped": 0},
            "cleanup": {"processes_stopped": True, "databases_removed": True, "temporary_roots_removed": True},
        }


if __name__ == "__main__":
    unittest.main()
