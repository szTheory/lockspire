"""Behavioral contract for the bounded packaged authorization receipts."""

from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"))
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance"))

try:
    from selected_receipts import validate_selected_receipt, write_selected_receipt
    from clean_room_saas_journey import _exact_relative_consent_id
except ImportError:  # Lets the initial TDD RED be an assertion, not an import error.
    validate_selected_receipt = None  # type: ignore[assignment]
    write_selected_receipt = None  # type: ignore[assignment]
    _exact_relative_consent_id = None  # type: ignore[assignment]


class SelectedReceiptTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.path = Path(self.temporary.name) / "selected.json"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_module_exposes_behavioral_receipt_contract(self) -> None:
        self.assertTrue(callable(validate_selected_receipt))
        self.assertTrue(callable(write_selected_receipt))

    def test_explicit_single_case_is_partial_and_accepts_real_binding(self) -> None:
        receipt = self.receipt()
        self.write(receipt)
        accepted = validate_selected_receipt(
            self.path,
            expected_case_ids=("A171-003",),
            expected_source_revision="a" * 40,
            expected_binding=self.binding(),
        )
        self.assertEqual(accepted["selection"], "partial")
        self.assertEqual(accepted["expected_case_ids"], ["A171-003"])

    def test_writer_emits_exact_selected_contract(self) -> None:
        scenario = self.scenario()
        write_selected_receipt(
            self.path,
            selection="partial",
            expected_case_ids=("A171-003",),
            source_revision="a" * 40,
            candidate=self.binding(),
            scenarios=[scenario],
            cleanup=self.cleanup(),
            redaction={"sentinel_check_passed": True, "evidence_scan_passed": True},
        )
        receipt = json.loads(self.path.read_text(encoding="utf-8"))
        self.assertEqual(receipt["expected_case_ids"], ["A171-003"])
        self.assertEqual(receipt["counts"], {"executed": 1, "passed": 1, "failed": 0, "skipped": 0})

    def test_rejects_null_empty_missing_duplicate_and_unknown_cases(self) -> None:
        for cases in (None, [], [self.scenario("A171-003"), self.scenario("A171-003")], [self.scenario("X-1")]):
            receipt = self.receipt()
            receipt["scenarios"] = cases
            self.rejected(receipt)
        for expected_ids in (None, (), ("X-1",), ("A171-003", "A171-003")):
            with self.assertRaises(AssertionError):
                validate_selected_receipt(
                    self.path, expected_case_ids=expected_ids,  # type: ignore[arg-type]
                    expected_source_revision="a" * 40,
                )

    def test_rejects_partial_receipt_as_complete_twelve_case_acceptance(self) -> None:
        receipt = self.receipt()
        receipt["selection"] = "complete"
        self.rejected(receipt, expected_case_ids=(
            "A171-001", "A171-002", "A171-003", "A171-004", "A171-005", "A171-006",
            "P171-001", "P171-002", "P171-003", "P171-004", "P171-005", "P171-006",
        ))

    def test_rejects_empty_observations_and_unknown_fields(self) -> None:
        receipt = self.receipt()
        receipt["scenarios"][0]["observations"] = {}
        self.rejected(receipt)
        receipt = self.receipt()
        receipt["scenarios"][0]["raw_body"] = "must-not-be-retained"
        self.rejected(receipt)

    def test_rejects_duplicate_root_and_nested_json_object_keys(self) -> None:
        receipt = self.receipt()
        root_json = json.dumps(receipt, separators=(",", ":"))
        self.path.write_text(root_json.replace('"selection":"partial"', '"selection":"partial","selection":"complete"', 1), encoding="utf-8")
        with self.assertRaises(AssertionError):
            validate_selected_receipt(self.path, expected_case_ids=("A171-003",), expected_source_revision="a" * 40)

        nested_json = json.dumps(receipt, separators=(",", ":"))
        self.path.write_text(nested_json.replace('"control_status":302', '"control_status":302,"control_status":400', 1), encoding="utf-8")
        with self.assertRaises(AssertionError):
            validate_selected_receipt(self.path, expected_case_ids=("A171-003",), expected_source_revision="a" * 40)

    def test_rejects_bad_counts_and_failed_or_skipped_rows(self) -> None:
        for invalid in (True, 1.0, -1):
            receipt = self.receipt()
            receipt["scenarios"][0]["counts"]["executed"] = invalid
            self.rejected(receipt)
        for outcome, counts in (
            ("failed", {"executed": 1, "passed": 0, "failed": 1, "skipped": 0}),
            ("skipped", {"executed": 1, "passed": 0, "failed": 0, "skipped": 1}),
            ("passed", {"executed": 0, "passed": 0, "failed": 0, "skipped": 0}),
        ):
            receipt = self.receipt()
            receipt["scenarios"][0]["outcome"] = outcome
            receipt["scenarios"][0]["counts"] = counts
            receipt["counts"] = counts
            self.rejected(receipt)

    def test_rejects_source_package_provenance_redaction_and_cleanup_mutations(self) -> None:
        mutations = (
            ("source_revision", "b" * 40),
            ("candidate.archive_sha256", "d" * 64),
            ("candidate.tree_sha256", "d" * 64),
            ("candidate.vendor_tree_sha256", "d" * 64),
            ("candidate.compiled_candidate_sha256", None),
            ("candidate.resolved_dependency_verified", False),
            ("redaction.sentinel_check_passed", False),
            ("cleanup.databases_removed", False),
        )
        for field, value in mutations:
            receipt = self.receipt()
            target = receipt
            *parents, leaf = field.split(".")
            for parent in parents:
                target = target[parent]
            target[leaf] = value
            self.rejected(receipt)

    def test_rejects_substitution_of_another_valid_receipt_digest(self) -> None:
        expected = self.receipt()
        self.write(expected)
        expected_digest = hashlib.sha256(self.path.read_bytes()).hexdigest()
        substituted = self.receipt()
        substituted["scenarios"][0]["observations"]["control_status"] = 303
        self.write(substituted)
        accepted = validate_selected_receipt(
            self.path,
            expected_case_ids=("A171-003",),
            expected_source_revision="a" * 40,
            expected_binding=self.binding(),
        )
        self.assertEqual(accepted["selection"], "partial")

        with self.assertRaisesRegex(AssertionError, "bytes differ from the externally supplied digest"):
            validate_selected_receipt(
                self.path,
                expected_case_ids=("A171-003",),
                expected_source_revision="a" * 40,
                expected_receipt_sha256=expected_digest,
            )

    def test_each_authorization_case_requires_its_positive_observation_contract(self) -> None:
        identifiers = (
            "A171-001", "A171-002", "A171-003", "A171-004", "A171-005", "A171-006",
            "P171-001", "P171-002", "P171-003", "P171-004", "P171-005", "P171-006",
        )
        for identifier in identifiers:
            receipt = self.receipt_for(identifier)
            self.write(receipt)
            validate_selected_receipt(
                self.path, expected_case_ids=(identifier,), expected_source_revision="a" * 40,
                expected_binding=self.binding(),
            )

            missing = self.receipt_for(identifier)
            missing["scenarios"][0]["observations"].pop(next(iter(missing["scenarios"][0]["observations"])))
            self.rejected(missing, expected_case_ids=(identifier,))

            false = self.receipt_for(identifier)
            first_boolean = next(key for key, value in false["scenarios"][0]["observations"].items() if type(value) is bool)
            false["scenarios"][0]["observations"][first_boolean] = False
            self.rejected(false, expected_case_ids=(identifier,))

    def test_rejects_invalid_par_http_and_discovery_statuses(self) -> None:
        invalid_statuses = (
            ("P171-001", "pushed_status", 302),
            ("P171-002", "foreign_status", 302),
            ("P171-003", "expired_status", 302),
            ("P171-004", "token_status", 400),
            ("P171-006", "discovery_status", 404),
        )
        for identifier, field, status in invalid_statuses:
            receipt = self.receipt_for(identifier)
            receipt["scenarios"][0]["observations"][field] = status
            self.rejected(receipt, expected_case_ids=(identifier,))

    def test_rejects_missing_or_skipped_par_rows_from_complete_selection(self) -> None:
        full_ids = (
            "A171-001", "A171-002", "A171-003", "A171-004", "A171-005", "A171-006",
            "P171-001", "P171-002", "P171-003", "P171-004", "P171-005", "P171-006",
        )
        receipt = self.receipt()
        receipt["selection"] = "complete"
        receipt["expected_case_ids"] = list(full_ids)
        receipt["scenarios"] = [self.scenario(identifier) for identifier in full_ids[:-1]]
        receipt["counts"] = {"executed": 11, "passed": 11, "failed": 0, "skipped": 0}
        self.rejected(receipt, expected_case_ids=full_ids)

        receipt = self.receipt_for("P171-005")
        receipt["scenarios"][0]["outcome"] = "skipped"
        receipt["scenarios"][0]["counts"] = {"executed": 1, "passed": 0, "failed": 0, "skipped": 1}
        receipt["counts"] = receipt["scenarios"][0]["counts"]
        self.rejected(receipt, expected_case_ids=("P171-005",))

    def test_pushed_consent_projection_rejects_false_authority_facts(self) -> None:
        receipt = self.receipt_for("P171-005")
        for field in ("candidate_scopes_match", "candidate_state_matches", "candidate_nonce_matches", "candidate_front_channel_scope_not_merged"):
            mutation = copy.deepcopy(receipt)
            mutation["scenarios"][0]["observations"][field] = False
            self.rejected(mutation, expected_case_ids=("P171-005",))

    def test_consent_boundary_accepts_only_exact_relative_route(self) -> None:
        self.assertTrue(callable(_exact_relative_consent_id))
        self.assertEqual(_exact_relative_consent_id("/lockspire/consent/abc123"), "abc123")
        for location in (
            "https://attacker.example/lockspire/consent/abc123",
            "/lockspire/consent/abc123?next=/",
            "/lockspire/consent/abc123#fragment",
            "/lockspire/consent/",
        ):
            self.assertIsNone(_exact_relative_consent_id(location))

    def test_cli_contract_rejects_receipt_check_without_external_binding(self) -> None:
        # The runner must validate caller-supplied source and byte identity before reading a receipt.
        runner = Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room_saas_journey.py"
        import subprocess

        result = subprocess.run(
            [sys.executable, str(runner), "--check-selected-receipt", str(self.path)],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 2)

    def rejected(self, receipt: dict[str, object], *, expected_case_ids: tuple[str, ...] = ("A171-003",)) -> None:
        self.write(receipt)
        with self.assertRaises(AssertionError):
            validate_selected_receipt(
                self.path,
                expected_case_ids=expected_case_ids,
                expected_source_revision="a" * 40,
                expected_binding=self.binding(),
            )

    def write(self, receipt: dict[str, object]) -> None:
        self.path.write_text(json.dumps(receipt), encoding="utf-8")

    @staticmethod
    def binding() -> dict[str, object]:
        return {
            "kind": "tar", "version": "1.47.0", "source_revision": "a" * 40,
            "archive_sha256": "b" * 64, "tree_sha256": "c" * 64,
            "vendor_tree_sha256": "c" * 64, "compiled_candidate_sha256": "e" * 64,
            "resolved_dependency_verified": True,
        }

    @staticmethod
    def cleanup() -> dict[str, bool]:
        return {"processes_stopped": True, "databases_removed": True, "temporary_roots_removed": True}

    @classmethod
    def scenario(cls, identifier: str = "A171-003") -> dict[str, object]:
        observations = {
            "A171-001": {"control_status": 302, "control_callback_exact": True, "mismatch_status": 400, "mismatch_no_location": True},
            "A171-002": {"callback_status": 302, "callback_exact_registered": True, "foo_preserved": True, "trusted_state_only": True, "error_invalid_request": True, "no_duplicate_state": True},
            "A171-003": {"control_status": 302, "control_reached_host_handoff": True, "unsupported_status": 400, "html_content_type": True, "no_location": True, "no_oauth_error_parameters": True},
            "A171-004": {"callback_status": 302, "login_required": True, "state_matches": True, "no_host_login_redirect": True},
            "A171-005": {"callback_status": 302, "login_required": True, "state_matches": True, "no_host_login_redirect": True, "stale_auth_time_used": True},
            "A171-006": {"max_age_token_status": 200, "max_age_signature_valid": True, "max_age_issuer_audience_nonce_valid": True, "max_age_auth_time_integer": True, "max_age_auth_time_equal": True, "claims_token_status": 200, "claims_signature_valid": True, "claims_issuer_audience_nonce_valid": True, "claims_auth_time_integer": True, "claims_auth_time_equal": True},
            "P171-001": {"direct_status": 302, "direct_safe_callback": True, "pushed_status": 201, "pushed_json_media_type": True, "pushed_positive_expires_in": True, "token_status": 200, "token_issued": True, "replay_status": 400, "replay_no_location": True},
            "P171-002": {"owner_control_status": 302, "owner_control_reached_consent": True, "foreign_status": 400, "foreign_no_location": True, "owner_reuse_status": 400, "owner_reuse_no_location": True},
            "P171-003": {"live_control_status": 302, "live_control_reached_consent": True, "expired_status": 400, "expired_no_location": True},
            "P171-004": {"direct_status": 302, "direct_safe_callback": True, "pushed_status": 201, "pushed_json_media_type": True, "pushed_positive_expires_in": True, "token_status": 200, "token_issued": True, "replay_status": 400, "replay_no_location": True},
            "P171-005": {"control_consent_boundary_exact": True, "candidate_consent_boundary_exact": True, "candidate_client_id_matches": True, "candidate_scopes_match": True, "candidate_state_matches": True, "candidate_nonce_matches": True, "candidate_front_channel_scope_not_merged": True},
            "P171-006": {"discovery_status": 200, "issuer_matches_configured": True, "authorization_endpoint_mounted": True, "token_endpoint_mounted": True, "userinfo_endpoint_mounted": True, "jwks_uri_mounted": True, "pushed_authorization_endpoint_mounted": True, "revocation_endpoint_mounted": True, "introspection_endpoint_mounted": True},
        }.get(identifier, {})
        return {
            "id": identifier, "outcome": "passed",
            "observations": observations,
            "counts": {"executed": 1, "passed": 1, "failed": 0, "skipped": 0},
        }

    @classmethod
    def receipt(cls) -> dict[str, object]:
        return {
            "schema_version": 1, "selection": "partial", "expected_case_ids": ["A171-003"],
            "source_revision": "a" * 40, "candidate": cls.binding(), "scenarios": [cls.scenario()],
            "counts": {"executed": 1, "passed": 1, "failed": 0, "skipped": 0},
            "cleanup": cls.cleanup(),
            "redaction": {"sentinel_check_passed": True, "evidence_scan_passed": True},
        }

    @classmethod
    def receipt_for(cls, identifier: str) -> dict[str, object]:
        receipt = cls.receipt()
        receipt["expected_case_ids"] = [identifier]
        receipt["scenarios"] = [cls.scenario(identifier)]
        return receipt


if __name__ == "__main__":
    unittest.main(verbosity=2)
