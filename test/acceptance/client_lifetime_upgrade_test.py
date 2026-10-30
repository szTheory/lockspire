"""Contract checks for packaged legacy HTTP upgrade receipts."""

from __future__ import annotations

from contextlib import redirect_stdout
from io import StringIO
import sys
import unittest
from pathlib import Path
from unittest.mock import Mock
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"))

import client_lifetime_upgrade as upgrade  # noqa: E402
from client_lifetime_upgrade import PackageInputError, validate_receipt  # noqa: E402
from package_input import PackageIdentity  # noqa: E402
from redaction import Redactor, SentinelSet  # noqa: E402


class LegacyUpgradeReceiptTest(unittest.TestCase):
    def test_legacy_http_boundary_uses_provider_signature_and_blocks_after_uncertain_cleanup(self) -> None:
        host = Path("/controlled/candidate")
        environment = {"MIX_ENV": "test"}
        started = []
        continuation = []
        process = Mock(pid=123, returncode=1)
        process.poll.return_value = 1

        def start_candidate(candidate_host, candidate_env):
            started.append((candidate_host, candidate_env))
            return process

        with patch.object(upgrade, "start_process", side_effect=start_candidate), \
             patch.object(upgrade, "wait_ready") as wait_ready, \
             patch.object(upgrade, "stop_started_processes", return_value=False) as stop:
            def candidate_then_database_teardown():
                upgrade.run_candidate_http_flow(
                    host, environment, 49123, lambda origin: {"origin": origin}
                )
                continuation.append("database teardown")

            with self.assertRaisesRegex(PackageInputError, "process group cleanup is unconfirmed"):
                candidate_then_database_teardown()

        self.assertEqual(started, [(host, environment)])
        wait_ready.assert_called_once_with("http://127.0.0.1:49123")
        stop.assert_called_once_with()
        self.assertEqual(continuation, [])

    def test_legacy_http_boundary_retries_owned_cleanup_after_startup_counter_failure(self) -> None:
        host = Path("/controlled/candidate")
        environment = {"MIX_ENV": "test"}
        cleanup_attempts = []

        def fail_after_process_registration(candidate_host, candidate_env):
            self.assertEqual(candidate_host, host)
            self.assertIs(candidate_env, environment)
            raise PackageInputError("callback counter setup failed")

        with patch.object(upgrade, "start_process", side_effect=fail_after_process_registration), \
             patch.object(upgrade, "stop_started_processes", side_effect=lambda: cleanup_attempts.append("stop") or False):
            with self.assertRaisesRegex(PackageInputError, "process group cleanup is unconfirmed"):
                upgrade.run_candidate_http_flow(host, environment, 49123, lambda _origin: None)

        self.assertEqual(cleanup_attempts, ["stop"])

    def test_child_failure_retains_only_its_bounded_event_witness(self) -> None:
        child = Mock(returncode=1)
        child.communicate.return_value = (b"private child output", b"private child error")
        with patch.object(upgrade.subprocess, "Popen", return_value=child):
            with self.assertRaises(upgrade.LegacyRunnerFailure) as caught:
                upgrade.run_process(
                    Path("/private/child"), {}, ("mix", "run"),
                    Redactor(SentinelSet.for_run()), stage="legacy_upgrade", scenario="selected",
                )

        self.assertEqual(caught.exception.summary, {
            "stage": "legacy_upgrade", "scenario": "selected", "event": "child_exit",
            "field": "stdout_stderr", "count": 2,
        })
        self.assertNotIn("private", str(caught.exception))

    def test_legacy_prefix_requires_http_use_promotion_and_state_preservation(self) -> None:
        scenario = self._scenario("public")
        scenario.pop("legacy_http_use_observation")
        scenario.pop("legacy_http_use_process")
        receipt = {"schema_version": 1, "scenarios": [scenario]}
        with self.assertRaises(PackageInputError):
            validate_receipt(receipt, {"public"})

    def test_complete_legacy_http_use_observation_is_accepted(self) -> None:
        validate_receipt({"schema_version": 1, "scenarios": [self._scenario("public")]}, {"public"})

    def test_main_temporary_root_validates_selected_prefix_and_all_selection(self) -> None:
        identity = PackageIdentity("tar", "1.7.0", "a" * 64, "b" * 64, "c" * 64, "d" * 40)
        with (
            patch.object(upgrade, "prepare_package", return_value=(Path("/candidate"), (), identity)) as prepare,
            patch.object(upgrade, "run_scenario", side_effect=lambda _root, prefix, *_args: {"prefix": prefix}) as run,
            patch.object(upgrade, "validate_receipt") as validate,
            patch.object(sys, "argv", ["client_lifetime_upgrade.py", "--scenario", "public"]),
            redirect_stdout(StringIO()),
        ):
            self.assertEqual(upgrade.main(), 0)

        prepare.assert_called_once()
        run.assert_called_once()
        self.assertEqual(run.call_args.args[1], "public")
        validate.assert_called_once_with(
            {"schema_version": 1, "scenarios": [{"prefix": "public"}]}, {"public"}
        )

        with (
            patch.object(upgrade, "prepare_package", return_value=(Path("/candidate"), (), identity)) as prepare_all,
            patch.object(upgrade, "run_scenario", side_effect=lambda _root, prefix, *_args: {"prefix": prefix}) as run_all,
            patch.object(upgrade, "validate_receipt") as validate_all,
            patch.object(sys, "argv", ["client_lifetime_upgrade.py"]),
            redirect_stdout(StringIO()),
        ):
            self.assertEqual(upgrade.main(), 0)

        prepare_all.assert_called_once()
        self.assertEqual([item.args[1] for item in run_all.call_args_list], ["public", "tenant_auth"])
        validate_all.assert_called_once_with(
            {"schema_version": 1, "scenarios": [{"prefix": "public"}, {"prefix": "tenant_auth"}]},
            {"public", "tenant_auth"},
        )

    @staticmethod
    def _scenario(prefix: str) -> dict[str, object]:
        def process(command: str, output: str = "") -> dict[str, object]:
            return {"pid": 123, "command": command, "exit_code": 0, "output": output}

        return {
            "prefix": prefix,
            "old_package": {
                "schema_version": 1, "source": "hex", "package": "lockspire",
                "version": "1.6.1", "sha256": "a" * 64, "archive_sha256": "a" * 64,
                "tree_sha256": "b" * 64, "source_revision": "c" * 40,
            },
            "candidate_package": {
                "kind": "tar", "version": "1.7.0", "archive_sha256": "d" * 64,
                "tree_sha256": "e" * 64, "source_revision": "f" * 40,
                "vendor_tree_sha256": "e" * 64, "compiled_candidate_sha256": "1" * 64,
                "resolved_dependency_verified": True,
            },
            "historical_migration_checksums_preserved": True,
            "historical_migration_checksum_count": 1,
            "historical_migration_checksums_sha256": "2" * 64,
            "old_processes": [process("lockspire.client.create") for _ in range(5)],
            "expansion_process": process("ecto.migrate"),
            "old_writer_processes_stopped_before_v1": True,
            "old_read_write_count": 5,
            "old_read_observation": process("run", "OLD_EXPANDED_ROWS_READ=5"),
            "v0_legacy_rows_observation": process("run", "V0_LEGACY_ROWS_VERIFIED=5;LEGACY_DATE_KINDS=4;STALE_AFTER_ROTATION_OBSERVED=1;LEGACY_V0_UNLIMITED=1;LEGACY_SECRET_PAST=1"),
            "old_rotation_observation": process("run", "STALE_DATE_SURVIVED_ROTATION=1"),
            "candidate_v1_write_process": process("lockspire.client.create"),
            "legacy_http_use_observation": {
                "par_http_status": 201, "authorize_http_status": 302, "login_http_status": 200, "token_http_status": 200,
                "lifetime_version": 0, "client_secret_date_kind": "past", "access_token_issued": True,
            },
            "legacy_http_use_process": process("run", "LEGACY_HTTP_AUTH=1;LEGACY_V0_UNLIMITED=1;LEGACY_SECRET_PAST=1"),
            "legacy_promotion_observation": {
                "old_secret_http_status": 401, "replacement_secret_http_status": 200,
                "management_put_http_status": 200, "old_management_http_status": 401,
                "replacement_management_http_status": 200, "lifetime_version": 1,
                "app_unlimited": True, "secret_current_policy_deadline": True,
                "management_current_policy_deadline": True, "whole_row_promoted": True,
                "unrelated_authority_preserved": True, "audit_persisted": True,
                "wire_client_expires_at": 0, "wire_registration_access_token_expires_at": 1900000000,
            },
            "legacy_promotion_process": process("run", "LEGACY_WHOLE_ROW_PROMOTED=1;LEGACY_MANAGEMENT_AUTHORITY_PRESERVED=1;LEGACY_MANAGEMENT_POLICY_DEADLINE=1;LEGACY_MANAGEMENT_AUDIT=1"),
            "v1_state_retained_observation": process("run", "V1_STATE_RETAINED=1"),
            "v1_state_retained": True,
            "database_cleanup_process": process("ecto.drop"),
            "old_binary_after_v1_traffic": False,
            "rollback_boundary": "retain schema and v1 state; fix forward or use lifetime-aware rollback",
        }


if __name__ == "__main__":
    unittest.main()
