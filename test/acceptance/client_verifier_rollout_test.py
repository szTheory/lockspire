"""Contracts for source-bound installed verifier rollout controls."""

from __future__ import annotations

import importlib.util
import inspect
import io
import json
import sys
import tempfile
import unittest
import urllib.error
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import build_provider  # noqa: E402
import clean_room_verifier_upgrade  # noqa: E402
import verifier_rollout  # noqa: E402
import verifier_receipts  # noqa: E402
from redaction import Redactor, SentinelSet  # noqa: E402


class VerifierRolloutContracts(unittest.TestCase):
    def test_token_error_body_withholds_unregistered_child_text(self) -> None:
        marker = "UNREGISTERED_TOKEN_ERROR_MARKER"
        response = io.BytesIO(b'{"token_endpoint":"https://issuer.example/token"}')
        error = urllib.error.HTTPError("https://issuer.example/token", 500, "failure", {}, io.BytesIO(marker.encode()))
        with mock.patch.object(clean_room_verifier_upgrade.urllib.request, "urlopen", side_effect=[response, error]):
            with self.assertRaises(build_provider.PackageInputError) as raised:
                clean_room_verifier_upgrade._token_request(
                    "https://issuer.example", "client", "secret", "https://client.example/cb",
                    "verifier", "code", Redactor(SentinelSet.for_run()),
                )
        self.assertFalse(marker in str(raised.exception), "unregistered HTTP body reached a retained error")
        self.assertIn("response diagnostics withheld", str(raised.exception))

    def test_failed_rollout_attempt_persists_only_child_output_digest(self) -> None:
        marker = "UNREGISTERED_CHILD_DIAGNOSTIC_MARKER"
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            log = root / "provider.log"
            log.write_text(marker, encoding="utf-8")
            verifier_rollout._write_failure_attempt(
                root / "receipts", "rollout", "locked", "builtin", "run-1",
                RuntimeError(marker), Redactor(SentinelSet.for_run()),
                log_paths=[log],
            )
            persisted = next((root / "receipts").glob("*.failure.json")).read_text(encoding="utf-8")
        self.assertFalse(marker in persisted, "unregistered child diagnostics reached durable rollout evidence")
        self.assertNotIn("redacted_error", persisted)
        self.assertNotIn('"tail"', persisted)
        record = json.loads(persisted)
        self.assertEqual(record["process_logs"][0]["bytes"], len(marker))
        self.assertEqual(len(record["process_logs"][0]["sha256"]), 64)

    def _rollout_fixture(self) -> dict[str, object]:
        path = ROOT / "test/fixtures/verifier-matrix-26/rollout/locked-builtin/receipt.json"
        return json.loads(path.read_text(encoding="utf-8"))

    def test_rollout_receipt_rejects_unproven_predecessor_and_unknown_sensitive_fields(self) -> None:
        receipt = self._rollout_fixture()
        expected = {
            "expected_pair": "locked", "expected_store": "builtin",
            "expected_runner": receipt["runner_revision"],
            "expected_candidate_source": receipt["candidate"]["source_revision"],
            "expected_scope": "rollout",
        }
        receipt["predecessor"] = {"kind": "candidate-substitution", "source_revision": receipt["candidate"]["source_revision"]}
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts._validate_rollout_structure(receipt, **expected)

        receipt = self._rollout_fixture()
        receipt["observations"]["client_secret"] = "unknown-sensitive-field"
        with self.assertRaises(verifier_receipts.ReceiptError):
            verifier_receipts._validate_rollout_structure(receipt, **expected)

    def test_rollout_rejects_artifact_pins_from_the_retired_hex_builder(self) -> None:
        receipt = self._rollout_fixture()
        expected = {
            "expected_pair": "locked", "expected_store": "builtin",
            "expected_runner": receipt["runner_revision"],
            "expected_candidate_source": receipt["candidate"]["source_revision"],
            "expected_scope": "rollout",
        }
        verifier_receipts._validate_rollout_structure(receipt, **expected)
        for field, retired in (
            ("archive_sha256", "792967609e41d216fc0178ef069570c39350c9bb5ee481da4e2852993267e758"),
            ("tree_sha256", "2dcf7705bd5651e853a02a931a1e0c595639438b3bd0a36a9c330017eab98315"),
        ):
            with self.subTest(field=field):
                mutated = self._rollout_fixture()
                mutated["predecessor"][field] = retired
                with self.assertRaises(verifier_receipts.ReceiptError):
                    verifier_receipts._validate_rollout_structure(mutated, **expected)

    def test_cli_group_selection_dispatches_explicit_scope_independent_of_matrix_width(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            receipt_dir = Path(temporary)
            rollout_result = {
                "pair": "locked", "store": "builtin", "scope": "rollout",
                "receipt_path": str(receipt_dir / "locked-builtin" / "receipt.json"),
            }
            rollout_out = io.StringIO()
            with mock.patch.object(verifier_rollout, "_run_rollout_cell", return_value=rollout_result) as cell:
                with redirect_stdout(rollout_out):
                    status = clean_room_verifier_upgrade.main([
                        "--group", "rollout", "--pair", "locked", "--store", "builtin",
                        "--receipt-dir", str(receipt_dir),
                    ])
            self.assertEqual(status, 0)
            cell.assert_called_once_with("locked", "builtin", receipt_dir / "locked-builtin")
            self.assertEqual(json.loads(rollout_out.getvalue().splitlines()[-1])["scope"], "rollout")
            self.assertEqual(json.loads(rollout_out.getvalue().splitlines()[-1])["executed_count"], 1)

            public_result = {
                "pair": "locked", "store": "builtin", "scope": "legacy-control",
                "receipt_path": str(receipt_dir / "locked-builtin" / "receipt.json"),
            }
            public_out = io.StringIO()
            with mock.patch.object(verifier_rollout, "_run_public_control", return_value=public_result) as control:
                with redirect_stdout(public_out):
                    status = clean_room_verifier_upgrade.main([
                        "--group", "legacy-control", "--pair", "locked", "--store", "builtin",
                        "--receipt-dir", str(receipt_dir),
                    ])
                self.assertEqual(status, 0)
                control.assert_called_once_with(receipt_dir / "locked-builtin")
                with redirect_stderr(io.StringIO()):
                    status = clean_room_verifier_upgrade.main([
                        "--group", "legacy-control", "--pair", "all", "--store", "all",
                        "--receipt-dir", str(receipt_dir),
                    ])
                self.assertEqual(status, 1, "public control must reject rollout matrix selections")
                control.assert_called_once()
            self.assertEqual(json.loads(public_out.getvalue().splitlines()[-1])["scope"], "legacy-control")

    def test_public_artifact_pin_and_source_evidence_are_verified_by_one_helper(self) -> None:
        helper = getattr(verifier_rollout, "verify_public_artifact", None)
        self.assertTrue(callable(helper), "public artifact verification must fail closed before producer startup")

    def test_rollout_group_is_an_installed_proof_group_with_owned_host_fixture(self) -> None:
        spec = importlib.util.find_spec("verifier_rollout")
        self.assertTrue(spec is not None, "rollout group must have an installed proof runner")
        self.assertIn("rollout", clean_room_verifier_upgrade.GROUPS)
        fixture = ROOT / "test/clean_room/provider_host/verifier_rollout.exs"
        self.assertTrue(fixture.is_file(), "rollout state controls must be host-owned")
        selected = build_provider.selected_host_fixture_sources({"rollout", "legacy-control"})
        self.assertEqual([path.name for path in selected], ["verifier_rollout.exs", "verifier_rollout.exs"])
        fixture_source = fixture.read_text(encoding="utf-8")
        self.assertFalse(fixture_source.startswith('"""'), "Elixir fixture must not start with a Python docstring")
        self.assertRegex(
            fixture_source,
            r'\bargs\s*=\s*case\s+System\.argv\(\)\s+do\s+'
            r'\["--"\s*\|\s*rest\]\s*->\s*rest(?:\s*;\s*|\s+)'
            r'values\s*->\s*values\s+end\b',
        )
        self.assertIn('write_mode: :dedicated', fixture_source,
                      "safe age inspection needs a dedicated reader context even during legacy writes")
        self.assertIn('legacy_read: :allow', fixture_source)
        self.assertIn('Application.fetch_env!(:lockspire, Lockspire.Web.Endpoint)', fixture_source,
                      "legacy age inspection must use Lockspire's configured key, not Phoenix's endpoint key")

    def test_rollout_contract_covers_predecessor_process_drain_and_persisted_formats(self) -> None:
        path = ROOT / "scripts/acceptance/clean_room/verifier_rollout.py"
        source = path.read_text(encoding="utf-8") if path.is_file() else ""
        for required in (
            "173059a166e9ade0f5f57c9980b7b2400a98538c",
            "old_process_exit_observed",
            "legacy_write_read_shared_store",
            "dedicated_write_after_drain",
            "switch_back_legacy_write_preserves_dedicated",
            "old_code_rejects_dedicated",
            "rollback_retains_dedicated_reads",
        ):
            self.assertIn(required, source)

    def test_public_legacy_control_is_pinned_and_separate_from_predecessor(self) -> None:
        path = ROOT / "scripts/acceptance/clean_room/verifier_rollout.py"
        source = path.read_text(encoding="utf-8") if path.is_file() else ""
        self.assertIn("629abdc1b6721620f3d9084dbbe78da1e254650da5c552d0cc0f5b0c00f1cc6d", source)
        self.assertIn("d04be40262e975a4eb8d8567eb0d1458a9c23181", source)
        self.assertIn("legacy-control", clean_room_verifier_upgrade.GROUPS)
        self.assertIn("verifier_rollout", clean_room_verifier_upgrade.MODULES["legacy-control"][0])

    def test_legacy_control_preserves_authenticated_deadline_and_hash(self) -> None:
        path = ROOT / "scripts/acceptance/clean_room/verifier_rollout.py"
        source = path.read_text(encoding="utf-8") if path.is_file() else ""
        self.assertIn("authenticated_deadline_preserved", source)
        self.assertIn("client_hash_preserved", source)
        self.assertIn("locked-only", source)

    def test_server_role_copies_environment_and_enables_only_owned_http_process(self) -> None:
        incoming = {"PORT": "4123", "CLEAN_ROOM_HTTP_SERVER": "false"}
        server_env = verifier_rollout._server_environment(incoming)
        self.assertEqual(server_env["PORT"], "4123")
        self.assertEqual(server_env["CLEAN_ROOM_HTTP_SERVER"], "true")
        self.assertEqual(incoming["CLEAN_ROOM_HTTP_SERVER"], "false")

    def test_projection_protocol_accepts_fixture_markers_and_rejects_missing_or_invalid_rows(self) -> None:
        projected = verifier_rollout._parse_projection_output(
            "ROW_FORMAT=legacy;HASH_DIGEST=" + "a" * 64 + ";AGE_KIND=migrated;SIGNED_AT_MS=123;DEADLINE_MS=456\n"
        )
        self.assertEqual(projected, {"format": "legacy", "hash_digest": "a" * 64, "age_kind": "migrated",
                                     "signed_at_ms": "123", "deadline": "456"})
        with self.assertRaisesRegex(build_provider.PackageInputError, "unavailable"):
            verifier_rollout._parse_projection_output("command completed without projection\n")
        with self.assertRaisesRegex(build_provider.PackageInputError, "safe hash witness"):
            verifier_rollout._parse_projection_output("ROW_FORMAT=invalid;HASH_DIGEST=unavailable;AGE_KIND=unavailable;DEADLINE_MS=unavailable\n")
        with self.assertRaisesRegex(build_provider.PackageInputError, "safe hash witness"):
            verifier_rollout._parse_projection_output("ROW_FORMAT=legacy;HASH_DIGEST=not-a-digest;AGE_KIND=migrated;DEADLINE_MS=nil\n")
        with self.assertRaisesRegex(build_provider.PackageInputError, "age_error=unsupported"):
            verifier_rollout._parse_projection_output(
                "ROW_FORMAT=invalid;HASH_DIGEST=" + "b" * 64 + ";AGE_KIND=unavailable;AGE_ERROR=unsupported\n"
            )

    def test_old_code_rejection_requires_actual_invalid_client_http_401(self) -> None:
        self.assertEqual(verifier_rollout._classify_old_code_rejection("installed token HTTP returned status 401 (invalid_client)"), 401)
        self.assertEqual(verifier_rollout._classify_old_code_rejection("installed token HTTP returned status 403 (invalid_client)"), 0)
        self.assertEqual(verifier_rollout._classify_old_code_rejection("installed token request did not issue an access token"), 0)
        self.assertEqual(verifier_rollout._classify_old_code_rejection("invalid_client"), 0)

    def test_http_auth_failure_is_reduced_to_safe_status_code(self) -> None:
        with mock.patch.object(verifier_rollout.runner, "_authorization_code", side_effect=build_provider.PackageInputError("installed token HTTP returned status 401 (invalid_client)")):
            passed, failure = verifier_rollout._http_auth_result("http://127.0.0.1/lockspire", 80, "id", "secret")
        self.assertFalse(passed)
        self.assertEqual(failure, "token-http-401-invalid_client")

    def test_readiness_failure_confirms_owned_server_session_cleanup(self) -> None:
        class Process:
            pid = 1234

            def __init__(self, *_args, **_kwargs):
                self.stopped = False

            def poll(self):
                return None

        with tempfile.TemporaryDirectory() as temporary:
            process = Process()
            with mock.patch.object(verifier_rollout, "start_owned_session", return_value=process), \
                 mock.patch.object(verifier_rollout, "stop_process_group", return_value=True) as stop_group, \
                 mock.patch.object(verifier_rollout.time, "monotonic", side_effect=(0, 36)):
                with self.assertRaisesRegex(build_provider.PackageInputError, "did not become HTTP ready"):
                    verifier_rollout._start_server(Path(temporary), {}, Path(temporary) / "server.log", "http://127.0.0.1:9")
            stop_group.assert_called_once_with(process, grace=10)
    def test_public_adopter_provisions_signing_key_before_mounted_http(self) -> None:
        source = (ROOT / "scripts/acceptance/clean_room/verifier_rollout.py").read_text(encoding="utf-8")
        public = source.split("def _run_public_control", 1)[1].split("def _configure", 1)[0]
        self.assertIn("runner._provision_signing_key(new_host, new_env)", public)
        self.assertIn('"old_process_pid": old_pid, "candidate_process_pid": candidate_pid', public)

    def test_rollout_reads_can_skip_persisted_consent_between_independent_hosts(self) -> None:
        parameters = inspect.signature(clean_room_verifier_upgrade._authorization_code).parameters
        self.assertIn("remember", parameters)
        self.assertTrue(parameters["remember"].default)
        source = (ROOT / "scripts/acceptance/clean_room/verifier_rollout.py").read_text(encoding="utf-8")
        self.assertIn("remember=False", source)

    def test_public_source_link_requires_terminal_identity_and_exact_package_file_match(self) -> None:
        helper = verifier_rollout.verify_public_artifact
        self.assertFalse(helper(Path("missing.tar"), verifier_rollout.PUBLIC_SHA256, verifier_rollout.PUBLIC_SOURCE))


if __name__ == "__main__":
    unittest.main()
