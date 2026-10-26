"""Contracts for source-bound installed verifier rollout controls."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import build_provider  # noqa: E402
import clean_room_verifier_upgrade  # noqa: E402
import verifier_rollout  # noqa: E402


class VerifierRolloutContracts(unittest.TestCase):
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
        self.assertIn('args = case System.argv() do ["--" | rest] -> rest; values -> values end', fixture_source)
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

    def test_readiness_failure_cleans_owned_server_and_log_handle(self) -> None:
        class Process:
            pid = 1234

            def __init__(self, *_args, **_kwargs):
                self.stopped = False

            def poll(self):
                return None

            def terminate(self):
                self.stopped = True

            def wait(self, timeout=None):
                return 0

        with tempfile.TemporaryDirectory() as temporary:
            process = Process()
            with mock.patch.object(verifier_rollout.subprocess, "Popen", return_value=process), \
                 mock.patch.object(verifier_rollout.time, "monotonic", side_effect=(0, 36)):
                with self.assertRaisesRegex(build_provider.PackageInputError, "did not become HTTP ready"):
                    verifier_rollout._start_server(Path(temporary), {}, Path(temporary) / "server.log", "http://127.0.0.1:9")
            self.assertTrue(process.stopped)

    def test_process_log_redaction_removes_registered_material_before_retention(self) -> None:
        redactor = verifier_rollout.Redactor(verifier_rollout.SentinelSet.for_run())
        redactor.register_material("one-time-secret-value")
        rendered = verifier_rollout._redacted_log_tail("client_secret=one-time-secret-value\nHTTP 500", redactor)
        self.assertNotIn("one-time-secret-value", rendered)
        self.assertIn("HTTP 500", rendered)

    def test_public_source_link_requires_terminal_identity_and_exact_package_file_match(self) -> None:
        helper = verifier_rollout.verify_public_artifact
        self.assertFalse(helper(Path("missing.tar"), verifier_rollout.PUBLIC_SHA256, verifier_rollout.PUBLIC_SOURCE))


if __name__ == "__main__":
    unittest.main()
