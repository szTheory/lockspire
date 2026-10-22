"""Receipt assertions for the custom PostgreSQL adapter proof leg."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"))

from lifetime_receipts import validate_lifetime_receipt  # noqa: E402


CUSTOM_SCENARIOS = ("custom.issue_replace", "custom.shared_rollback", "custom.unsupported")
FRESH_SCENARIOS = (
    "fresh.register_use",
    "fresh.secret_expiry_rotate",
    "fresh.management_put_recover",
    "fresh.app_expiry_disabled",
)


class LifetimeReceiptTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.path = Path(self.temporary.name) / "receipt.json"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_custom_receipt_requires_complete_success_observations(self) -> None:
        receipt = self._receipt()
        validate_lifetime_receipt(self._write(receipt), expected_scenarios=CUSTOM_SCENARIOS)

        receipt = self._receipt()
        receipt["scenarios"][1]["observations"]["independent_observer"] = False
        self.assert_rejected(receipt)

    def test_custom_receipt_rejects_skipped_required_scenario(self) -> None:
        receipt = self._receipt()
        receipt["scenarios"][2]["outcome"] = "skipped"
        receipt["scenarios"][2]["counts"] = {"executed": 1, "passed": 0, "failed": 0, "skipped": 1}
        receipt["counts"]["passed"] -= 1
        receipt["counts"]["skipped"] += 1
        self.assert_rejected(receipt)

    def test_custom_receipt_requires_all_three_scenarios(self) -> None:
        receipt = self._receipt()
        receipt["scenarios"].pop(1)
        receipt["counts"] = {"executed": 3, "passed": 3, "failed": 0, "skipped": 0}
        self.assert_rejected(receipt)

    def test_fresh_receipt_requires_independent_expiry_rotation_and_recovery_scenarios(self) -> None:
        receipt = self._receipt()
        fresh = self._scenario(
            "fresh.register_use",
            {"registration_http_status": 201, "token_http_status": 200, "access_token_issued": True, "pkce_method": "S256"},
            2,
        )
        fresh["leg"] = "fresh"
        receipt["scenarios"] = [fresh]
        receipt["counts"] = fresh["counts"]
        with self.assertRaises(AssertionError):
            validate_lifetime_receipt(self._write(receipt), expected_scenarios=FRESH_SCENARIOS)

    def test_fresh_lifetime_scenarios_require_real_route_outcomes_and_positive_events(self) -> None:
        receipt = self._receipt()
        receipt["scenarios"] = [self._fresh_scenario(identifier) for identifier in FRESH_SCENARIOS]
        receipt["counts"] = {
            "executed": len(FRESH_SCENARIOS),
            "passed": len(FRESH_SCENARIOS),
            "failed": 0,
            "skipped": 0,
        }
        validate_lifetime_receipt(self._write(receipt), expected_scenarios=FRESH_SCENARIOS)

        receipt = self._receipt()
        receipt["scenarios"] = [self._fresh_scenario(identifier) for identifier in FRESH_SCENARIOS]
        receipt["scenarios"][1]["event_counts"] = {"secret_expired": 0, "secret_rotated": 1}
        receipt["counts"] = {
            "executed": len(FRESH_SCENARIOS),
            "passed": len(FRESH_SCENARIOS),
            "failed": 0,
            "skipped": 0,
        }
        with self.assertRaises(AssertionError):
            validate_lifetime_receipt(self._write(receipt), expected_scenarios=FRESH_SCENARIOS)

    def _fresh_scenario(self, identifier: str) -> dict[str, object]:
        observations: dict[str, object] = {"production_routes_used": True}
        events: dict[str, int] = {"registration_succeeded": 1, "authorization_code_redeemed": 1}
        if identifier == "fresh.register_use":
            observations.update({
                "registration_http_status": 201,
                "token_http_status": 200,
                "access_token_issued": True,
                "pkce_method": "S256",
            })
        elif identifier == "fresh.secret_expiry_rotate":
            observations.update({"expiry_rejected": True, "rotation_restored_auth": True, "unrelated_deadlines_preserved": True})
            events = {"secret_expired": 1, "secret_rotated": 1}
        elif identifier == "fresh.management_put_recover":
            observations.update({"old_credential_rejected": True, "new_credential_accepted": True, "host_authorized_recovery": True, "unrelated_deadlines_preserved": True})
            events = {"management_token_replaced": 1, "host_recovery": 1}
        elif identifier == "fresh.app_expiry_disabled":
            observations.update({"expired_get_allowed": True, "expired_delete_allowed": True, "expired_put_rejected": True, "disabled_management_denied": True, "state_retained": True})
            events = {"app_expired": 1, "disabled_management_denied": 1}
        return {
            "id": identifier,
            "leg": "fresh",
            "contract_case_ids": ["C-APP-14", "C-MGMT-02", "C-MGMT-03"],
            "outcome": "passed",
            "observations": observations,
            "event_counts": events,
            "audit_counts": {"observed": 1},
            "counts": {"executed": 1, "passed": 1, "failed": 0, "skipped": 0},
        }

    def assert_rejected(self, receipt: dict[str, object]) -> None:
        with self.assertRaises(AssertionError):
            validate_lifetime_receipt(self._write(receipt), expected_scenarios=CUSTOM_SCENARIOS)

    def _write(self, receipt: dict[str, object]) -> Path:
        self.path.write_text(json.dumps(receipt), encoding="utf-8")
        return self.path

    def _receipt(self) -> dict[str, object]:
        issue = self._scenario(
            "custom.issue_replace",
            {
                "callbacks_executed": 6,
                "authority_shared": True,
                "management_credential_replaced": True,
                "example_executed": True,
            },
            2,
        )
        rollback = self._scenario(
            "custom.shared_rollback",
            {
                "independent_observer": True,
                "rollback_preserved": True,
                "replacement_observed": True,
                "issuance_observed": True,
            },
            2,
        )
        unsupported = self._scenario(
            "custom.unsupported",
            {"unsupported_rejected": True, "example_executed": True},
            1,
        )
        return {
            "schema_version": 1,
            "source_revision": "a" * 40,
            "candidate": {
                "kind": "tar", "version": "1.7.0",
                "archive_sha256": "b" * 64, "tree_sha256": "c" * 64,
            },
            "scenarios": [issue, rollback, unsupported],
            "counts": {"executed": 5, "passed": 5, "failed": 0, "skipped": 0},
            "cleanup": {
                "processes_stopped": True,
                "databases_removed": True,
                "temporary_roots_removed": True,
            },
        }

    @staticmethod
    def _scenario(identifier: str, observations: dict[str, object], executed: int) -> dict[str, object]:
        return {
            "id": identifier,
            "leg": "custom",
            "contract_case_ids": ["C-APP-06"],
            "outcome": "passed",
            "observations": observations,
            "event_counts": {},
            "audit_counts": {},
            "counts": {"executed": executed, "passed": executed, "failed": 0, "skipped": 0},
        }


if __name__ == "__main__":
    unittest.main()
