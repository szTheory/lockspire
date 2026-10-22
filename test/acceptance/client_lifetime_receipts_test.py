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

    def test_candidate_leg_identity_rejects_mismatched_package_trees(self) -> None:
        from lifetime_receipts import validate_candidate_identity_agreement

        first = {"kind": "tar", "version": "1.7.0", "archive_sha256": "b" * 64, "tree_sha256": "c" * 64, "source_revision": "a" * 40}
        second = {**first, "tree_sha256": "d" * 64}
        with self.assertRaises(AssertionError):
            validate_candidate_identity_agreement([first, second])

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
            observations: dict[str, object] = {"proof_observed": True}
            events = {"observed": 1}
            audits = {"observed": 1}
            if identifier == "fresh.register_use":
                observations.update({"registration_http_status": 201, "token_http_status": 200, "access_token_issued": True, "pkce_method": "S256"})
                events = {"registration_succeeded": 1, "authorization_code_redeemed": 1}
            elif identifier == "fresh.secret_expiry_rotate":
                observations.update({"expiry_rejected": True, "rotation_restored_auth": True, "unrelated_deadlines_preserved": True})
                events = {"secret_expired": 1, "secret_rotated": 1}
            elif identifier == "fresh.management_put_recover":
                observations.update({"old_credential_rejected": True, "new_credential_accepted": True, "host_authorized_recovery": True, "unrelated_deadlines_preserved": True})
                events = {"management_token_replaced": 1, "host_recovery": 1}
            elif identifier == "fresh.app_expiry_disabled":
                observations.update({"expired_get_allowed": True, "expired_delete_allowed": True, "expired_put_rejected": True, "disabled_management_denied": True, "state_retained": True})
                events = {"app_expired": 1, "disabled_management_denied": 1}
            elif identifier == "custom.issue_replace":
                observations.update({"callbacks_executed": 6, "authority_shared": True, "management_credential_replaced": True, "example_executed": True})
                events, audits = {}, {}
            elif identifier == "custom.shared_rollback":
                observations.update({"independent_observer": True, "rollback_preserved": True, "replacement_observed": True, "issuance_observed": True})
                events, audits = {}, {}
            elif identifier == "custom.unsupported":
                observations.update({"unsupported_rejected": True, "example_executed": True})
                events, audits = {}, {}
            scenarios.append({
                "id": identifier,
                "leg": leg,
                "contract_case_ids": ["C-APP-06"],
                "outcome": "passed",
                "observations": observations,
                "event_counts": events,
                "audit_counts": audits,
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
