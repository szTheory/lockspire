"""Contracts for installed verifier disclosure evidence."""

from __future__ import annotations

import sys
import unittest
import json
import tempfile
import secrets
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import clean_room_verifier_upgrade as runner  # noqa: E402
import verifier_disclosure  # noqa: E402
import verifier_receipts  # noqa: E402
from build_provider import PROVIDER_TEMPLATE, write_host_runtime  # noqa: E402
from redaction import Redactor, SentinelSet  # noqa: E402


class VerifierDisclosureContracts(unittest.TestCase):
    def test_private_handoff_registers_material_without_treating_transport_as_diagnostics(self) -> None:
        secret = secrets.token_urlsafe(32)
        ciphertext = "LSCV1.test." + secrets.token_urlsafe(40)
        client_id = "safe-disclosure-client"
        redactor = Redactor(SentinelSet.for_run())
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "private-handoff.json"
            path.write_text(json.dumps({"clients": {client_id: {
                "client_id": client_id, "secret": secret, "ciphertext": ciphertext,
                "nested_inspection_redacted": True, "audit_before": 0,
            }}}))
            path.chmod(0o600)
            try:
                result = verifier_disclosure._read_private_json(path, redactor)
            except RuntimeError:
                self.fail("private credential handoff was rejected as diagnostic material")
            self.assertTrue(result["clients"][client_id]["secret"] == secret)
            self.assertFalse(path.exists())
        with self.assertRaises(RuntimeError):
            redactor.assert_safe(secret)
        with self.assertRaises(RuntimeError):
            redactor.assert_safe(ciphertext)
        redactor.assert_safe(client_id)

    def test_disclosure_group_owns_a_real_host_capture_fixture(self) -> None:
        self.assertEqual(
            runner.MODULES["disclosure"],
            ("verifier_disclosure", "run_group"),
        )
        fixture = (
            PROVIDER_TEMPLATE
            / "lib"
            / "clean_room_provider"
            / "verifier_disclosure.ex"
        )
        self.assertTrue(
            fixture.is_file(),
            "disclosure proof must capture owned runtime channels in the generated host",
        )

    def test_disclosure_receipt_requires_nonempty_pair_specific_channel_witnesses(self) -> None:
        case_ids = getattr(verifier_receipts, "DISCLOSURE_CASE_IDS", None)
        self.assertEqual(
            case_ids,
            {
                "locked": ["VPROOF-02-DISCLOSURE-LOCKED-SUCCESS"],
                "floor": ["VPROOF-02-DISCLOSURE-FLOOR-SUCCESS"],
            },
        )

    def test_registration_startup_diagnostic_is_fixed_and_private(self) -> None:
        expression = verifier_disclosure._seed_expression(["client-a"], Path("/private/handoff"))
        self.assertIn("Application.ensure_all_started(:clean_room_provider)", expression)
        self.assertIn('failure_stage: "host_setup"', expression)
        self.assertIn("VERIFIER_DISCLOSURE_SEED_FAILURE=host_setup", expression)
        self.assertNotIn("Exception.message", expression)
        self.assertNotIn("inspect(_error)", expression)

    def test_success_capture_distinguishes_controls_and_operation_witnesses(self) -> None:
        payload = {
            "operation_result": "ok",
            "logger_event_count": 2,
            "query_event_count": 4,
            "logger_control_event_count": 2,
            "logger_operation_event_count": 0,
            "query_control_event_count": 1,
            "query_operation_event_count": 3,
            "logger_leak_count": 0,
            "query_leak_count": 0,
            "nested_inspection_redacted": True,
            "audit_after_count": 1,
            "ciphertext_changed": True,
        }
        self.assertEqual(verifier_disclosure.validate_capture_payload(payload), payload)
        no_query_operation = dict(payload, query_operation_event_count=0)
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_disclosure.validate_capture_payload(no_query_operation)

    def test_encoded_sentinel_output_is_rejected_before_receipt_acceptance(self) -> None:
        sentinel = secrets.token_urlsafe(32)
        redactor = Redactor(SentinelSet.for_run())
        redactor.register_material(sentinel)
        encoded = __import__("base64").urlsafe_b64encode(sentinel.encode()).decode()
        with self.assertRaises(RuntimeError):
            redactor.assert_safe(encoded)

    def test_generated_host_listener_is_disabled_unless_explicitly_owned(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            host = Path(temporary)
            write_host_runtime(host, "postgres://localhost/unused")
            config = (host / "config" / "config.exs").read_text()
        self.assertIn(
            'server: System.get_env("CLEAN_ROOM_HTTP_SERVER", "false") == "true"', config
        )
        self.assertNotIn("server: true", config)

    def test_stopped_owned_listener_is_not_accepting_and_can_be_rebound(self) -> None:
        import socket

        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
            probe.bind(("127.0.0.1", 0))
            port = probe.getsockname()[1]
        self.assertFalse(verifier_disclosure._listener_accepting(port))
        self.assertTrue(verifier_disclosure._listener_bindable(port))

    def test_failure_capture_rejects_zero_channel_and_missing_forced_failure_witnesses(self) -> None:
        validator = getattr(verifier_disclosure, "validate_failure_capture", None)
        self.assertTrue(
            callable(validator),
            "failure captures must reject missing forced-failure and nonempty owned-channel witnesses",
        )
        with self.assertRaises(verifier_receipts.ReceiptError):
            validator({
                "scenario": "unknown_key_crypto",
                "reason": "unknown_key",
                "forced_failure_observed": False,
                "operation_result": "failed",
                "failure_detail_count": 1,
                "storage_failure_witness": False,
                "logger_event_count": 0,
                "logger_control_event_count": 0,
                "logger_operation_event_count": 0,
                "logger_leak_count": 0,
                "query_event_count": 0,
                "query_control_event_count": 0,
                "query_operation_event_count": 0,
                "query_leak_count": 0,
                "cli_output_checked": False,
                "report_redacted": False,
                "audit_projection_safe": False,
                "audit_unchanged": False,
                "ciphertext_unchanged": False,
                "http_status": 401,
                "http_error_code": "invalid_client",
                "http_outcome_safe": False,
                "output_leak_count": 0,
            })

    def test_failure_receipt_scope_is_pair_bound_and_enabled(self) -> None:
        self.assertIn("disclosure-failure", verifier_receipts.GROUPS)
        self.assertEqual(
            verifier_receipts.DISCLOSURE_FAILURE_CASE_IDS["locked"],
            [
                "VPROOF-02-DISCLOSURE-LOCKED-MALFORMED-CRYPTO",
                "VPROOF-02-DISCLOSURE-LOCKED-UNKNOWN-KEY-CRYPTO",
                "VPROOF-02-DISCLOSURE-LOCKED-STORAGE-FAILURE",
            ],
        )

    def test_unsafe_nested_or_encoded_failure_output_is_rejected_before_artifact_write(self) -> None:
        persist = getattr(verifier_disclosure, "persist_safe_failure_artifact", None)
        self.assertTrue(
            callable(persist),
            "failure artifacts must be rejected before durable write when nested or encoded sentinels leak",
        )
        sentinel = secrets.token_urlsafe(32)
        redactor = Redactor(SentinelSet.for_run())
        redactor.register_material(sentinel)
        encoded = __import__("base64").urlsafe_b64encode(sentinel.encode()).decode()
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "failure-receipt.json"
            safe = {
                "scenario": "unknown_key_crypto",
                "reason": "unknown_key",
                "forced_failure_observed": True,
                "operation_result": "failed",
                "failure_detail_count": 1,
                "storage_failure_witness": False,
                "logger_event_count": 2,
                "logger_control_event_count": 2,
                "logger_operation_event_count": 0,
                "logger_leak_count": 0,
                "query_event_count": 3,
                "query_control_event_count": 1,
                "query_operation_event_count": 2,
                "query_leak_count": 0,
                "cli_output_checked": True,
                "report_redacted": True,
                "audit_projection_safe": True,
                "audit_unchanged": True,
                "ciphertext_unchanged": True,
                "http_status": 401,
                "http_error_code": "invalid_client",
                "http_outcome_safe": True,
                "output_leak_count": 0,
            }
            with self.assertRaises(verifier_receipts.ReceiptError):
                persist(path, {"capture": safe, "nested": {"diagnostic": [encoded]}}, redactor)
            self.assertFalse(path.exists())


if __name__ == "__main__":
    unittest.main()
