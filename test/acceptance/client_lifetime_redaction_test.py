"""Boundary tests for retained client-lifetime proof output."""

from __future__ import annotations

import base64
import hashlib
from pathlib import Path
import sys
import unittest
from contextlib import redirect_stderr
from io import StringIO
from unittest.mock import patch


CLEAN_ROOM = Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"
sys.path.insert(0, str(CLEAN_ROOM))
import redaction  # noqa: E402
import client_lifetime_upgrade as upgrade  # noqa: E402


class LifetimeRedactionTest(unittest.TestCase):
    def assert_material_absent(self, material: str, rendered: str) -> None:
        if material in rendered:
            self.fail("protected material remained in retained output")

    def test_safe_failure_summary_is_allowlisted(self) -> None:
        summary = redaction.safe_failure_summary(
            stage="legacy_upgrade", scenario="public", event="child_exit",
            field="stdout_stderr", count=3,
        )
        self.assertEqual(
            summary,
            {"stage": "legacy_upgrade", "scenario": "public", "event": "child_exit", "field": "stdout_stderr", "count": 3},
        )
        self.assertEqual(set(summary), redaction.SAFE_FAILURE_FIELDS)

        protected = "phase166-secret-body-987654"
        unsafe = redaction.safe_failure_summary(
            stage=protected, scenario="public", event="assertion_failure",
            field=protected, count=-1,
        )
        self.assert_material_absent(protected, str(unsafe))
        self.assertEqual(unsafe["stage"], "unknown")
        self.assertEqual(unsafe["field"], "unknown")
        self.assertEqual(unsafe["count"], 0)

    def test_real_material_and_encoded_forms_are_registered_before_rendering(self) -> None:
        value = "phase166-secret-credential+/="
        redactor = redaction.Redactor(redaction.SentinelSet.for_run())
        redactor.register_material(value)
        representations = {
            value,
            base64.b64encode(value.encode()).decode(),
            base64.urlsafe_b64encode(value.encode()).decode(),
            hashlib.sha256(value.encode()).hexdigest(),
        }
        for representation in representations:
            self.assert_material_absent(representation, redactor.text(representation))

    def test_failed_child_stdout_and_stderr_never_reach_diagnostics(self) -> None:
        credential = "phase166-generated-client-secret-987654"
        encoded = base64.urlsafe_b64encode(credential.encode()).decode()
        output = f'client_secret="{credential}"\nraw response: {encoded}\n'
        stderr = f"assertion payload={credential}"

        class FailedProcess:
            pid = 41
            returncode = 2

            def communicate(self, timeout: int):
                return output.encode(), stderr.encode()

        redactor = redaction.Redactor(redaction.SentinelSet.for_run())
        with patch.object(upgrade.subprocess, "Popen", return_value=FailedProcess()):
            with self.assertRaises(upgrade.PackageInputError) as raised:
                upgrade.run_process(
                    Path("/tmp/child"), {}, ("run",), redactor,
                    stage="legacy_upgrade", scenario="public",
                )

        diagnostic = str(raised.exception)
        self.assertEqual(diagnostic, "legacy package child failed; diagnostics withheld")
        self.assertEqual(raised.exception.summary, {
            "stage": "legacy_upgrade", "scenario": "public", "event": "child_exit",
            "field": "stdout_stderr", "count": 3,
        })
        self.assert_material_absent(credential, diagnostic)
        self.assert_material_absent(encoded, diagnostic)
        self.assertNotIn("raw response", diagnostic)

    def test_registered_credentials_are_rejected_from_child_arguments(self) -> None:
        credential = "phase166-generated-client-secret-987654"
        redactor = redaction.Redactor(redaction.SentinelSet.for_run())
        redactor.register_material(credential)
        with patch.object(upgrade.subprocess, "Popen") as popen:
            with self.assertRaises(upgrade.PackageInputError) as raised:
                upgrade.run_process(
                    Path("/tmp/child"), {}, ("run", credential), redactor,
                    stage="legacy_upgrade", scenario="public",
                )
        diagnostic = str(raised.exception)
        self.assertEqual(diagnostic, "legacy package child failed; diagnostics withheld")
        self.assertEqual(raised.exception.summary, {
            "stage": "legacy_upgrade", "scenario": "public", "event": "child_start",
            "field": "argv", "count": 1,
        })
        self.assert_material_absent(credential, diagnostic)
        popen.assert_not_called()

    def test_child_start_exception_is_reduced_to_safe_identifiers(self) -> None:
        class SecretOSError(OSError):
            pass

        with patch.object(upgrade.subprocess, "Popen", side_effect=SecretOSError("raw secret body")):
            with self.assertRaises(upgrade.PackageInputError) as raised:
                upgrade.run_process(
                    Path("/tmp/child"), {}, ("run",), redaction.Redactor(redaction.SentinelSet.for_run()),
                    stage="legacy_upgrade", scenario="public",
                )
        self.assertNotIn("raw secret body", str(raised.exception))
        self.assertEqual(str(raised.exception), "legacy package child failed; diagnostics withheld")
        self.assertEqual(raised.exception.summary, {
            "stage": "legacy_upgrade", "scenario": "public", "event": "child_start",
            "field": "exception", "count": 1,
        })

    def test_upgrade_main_never_prints_untrusted_package_error_text(self) -> None:
        unregistered = "phase166-unregistered-client_secret=synthetic-987654"
        registered = "phase166-registered-client_secret=synthetic-123456"
        sentinels = redaction.SentinelSet(
            authorization_code="code", access_token="access", refresh_token="refresh",
            bearer_client_secret=registered, dpop_client_secret="dpop-secret",
            session_encryption_key="session-key", pkce_verifier="verifier",
            dpop_private_key="private-key", dpop_proof="proof", cookie="cookie",
        )

        for material in (unregistered, registered):
            with self.subTest(material="registered" if material == registered else "unregistered"):
                stderr = StringIO()
                with (
                    patch.object(upgrade.SentinelSet, "for_run", return_value=sentinels),
                    patch.object(upgrade, "prepare_package", side_effect=upgrade.PackageInputError(material)),
                    patch.object(sys, "argv", ["client_lifetime_upgrade.py", "--scenario", "public"]),
                    redirect_stderr(stderr),
                ):
                    self.assertEqual(upgrade.main(), 1)
                rendered = stderr.getvalue()
                self.assert_material_absent(material, rendered)
                self.assertIn("runner_failure", rendered)
                self.assertNotIn("legacy upgrade detail:", rendered)

    def test_success_receipt_keeps_only_allowlisted_markers(self) -> None:
        secret = "phase166-child-token-987654"

        class SuccessfulProcess:
            pid = 42
            returncode = 0

            def communicate(self, timeout: int):
                return (f"V0_LEGACY_ROWS_VERIFIED=5;LEGACY_DATE_KINDS=4;STALE_AFTER_ROTATION_OBSERVED=1\nraw={secret}\n".encode(), b"")

        with patch.object(upgrade.subprocess, "Popen", return_value=SuccessfulProcess()):
            receipt = upgrade.run_process(
                Path("/tmp/child"), {}, ("run",), redaction.Redactor(redaction.SentinelSet.for_run()),
                stage="legacy_upgrade", scenario="public",
            )
        self.assertEqual(set(receipt), upgrade.PROCESS_FIELDS)
        self.assertEqual(receipt["output"], "V0_LEGACY_ROWS_VERIFIED=5;LEGACY_DATE_KINDS=4;STALE_AFTER_ROTATION_OBSERVED=1")
        self.assert_material_absent(secret, str(receipt))

    def test_zero_scenarios_and_unallowlisted_receipt_fields_reject(self) -> None:
        with self.assertRaises(upgrade.PackageInputError):
            upgrade.validate_receipt({"schema_version": 1, "scenarios": []}, expected_prefixes=set())
        with self.assertRaises(upgrade.PackageInputError):
            upgrade.validate_receipt({"schema_version": 1, "scenarios": [], "raw": "credential"})


if __name__ == "__main__":
    unittest.main()
