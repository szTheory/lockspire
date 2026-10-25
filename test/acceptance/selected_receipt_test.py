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

try:
    from selected_receipts import validate_selected_receipt, write_selected_receipt
except ImportError:  # Lets the initial TDD RED be an assertion, not an import error.
    validate_selected_receipt = None  # type: ignore[assignment]
    write_selected_receipt = None  # type: ignore[assignment]


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
        substituted["scenarios"][0]["observations"]["control_status"] = 204
        self.write(substituted)
        with self.assertRaises(AssertionError):
            validate_selected_receipt(
                self.path,
                expected_case_ids=("A171-003",),
                expected_source_revision="a" * 40,
                expected_receipt_sha256=expected_digest,
            )

    def test_each_authorization_case_requires_its_positive_observation_contract(self) -> None:
        identifiers = ("A171-001", "A171-002", "A171-003", "A171-004", "A171-005", "A171-006")
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
