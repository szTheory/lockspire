"""Contracts for installed verifier recovery and stale-identity issuance proofs."""

from __future__ import annotations

import sys
import subprocess
import tempfile
import unittest
import contextlib
import io
import os
import re
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from unittest import mock
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))

import clean_room_verifier_upgrade  # noqa: E402
import verifier_recovery  # noqa: E402
import build_provider  # noqa: E402
from package_input import PackageInputError  # noqa: E402
from redaction import Redactor, SentinelSet  # noqa: E402


class RecoveryDispatchTest(unittest.TestCase):
    def test_recovery_startup_config_switch_is_explicit_and_bound_to_keyset(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            host = Path(temporary)
            config = host / "config"
            config.mkdir()
            runtime = config / "runtime.exs"
            runtime.write_text(
                'config :lockspire, Lockspire.Security.ClientSecretVerifier,\n'
                '  keys: [{"verifier-old", System.fetch_env!("OLD_KEY")}],\n'
                '  current: "verifier-old",\n  write_mode: :dedicated,\n'
                '  legacy_read: :reject\n',
                encoding="utf-8",
            )
            missing_fingerprint = verifier_recovery._configure_http_and_recovery_keys(
                host, include_new=False
            )
            missing_config = runtime.read_text(encoding="utf-8")
            self.assertIn('server: System.get_env("CLEAN_ROOM_HTTP_SERVER", "false") == "true"', missing_config)
            self.assertIn('keys: [{"verifier-old", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY")}]', missing_config)
            self.assertNotIn('"verifier-new"', missing_config)
            restored_fingerprint = verifier_recovery._configure_http_and_recovery_keys(
                host, include_new=True
            )
            restored_config = runtime.read_text(encoding="utf-8")
            self.assertIn('"verifier-new", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY_NEXT")', restored_config)
            self.assertNotEqual(missing_fingerprint, restored_fingerprint)

    def test_concurrent_recovery_witness_has_owned_pool_headroom(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            host = Path(temporary)
            config = host / "config"
            config.mkdir()
            (config / "config.exs").write_text(
                'config :clean_room_provider, CleanRoomProvider.Repo, url: "postgres://owned", pool_size: 2\n',
                encoding="utf-8",
            )
            verifier_recovery._increase_recovery_pool_for_concurrency(host)
            self.assertIn("pool_size: 6", (config / "config.exs").read_text(encoding="utf-8"))

    def test_recovery_failure_summary_names_only_fixed_false_fields(self) -> None:
        observations = {
            case_id: {field: True for field in fields}
            for case_id, fields in verifier_recovery.RECOVERY_REQUIRED_FIELDS.items()
        }
        observations[verifier_recovery.RECOVERY_CASES[2]].update({
            "missing_startup_context_has_protecting_key": False,
            "missing_key_http_status": 401,
            "basic_http_status": 200,
            "post_http_status": 200,
            "restored_http_status": 200,
            "old_secret_after_rotation_http_status": 401,
            "new_secret_after_rotation_http_status": 200,
            "missing_key_error_code": "invalid_client",
            "old_secret_after_rotation_error_code": "invalid_client",
            "new_secret_after_rotation_error_code": "other",
        })
        observations[verifier_recovery.RECOVERY_CASES[3]]["expired_http_status"] = 401
        observations[verifier_recovery.RECOVERY_CASES[1]]["interruption_not_ready"] = False
        self.assertEqual(
            verifier_recovery._failed_recovery_fields(observations),
            [(verifier_recovery.RECOVERY_CASES[1], ["interruption_not_ready"])],
        )

    def test_startup_context_witness_reads_only_fixed_boolean_markers(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            logfile = Path(temporary) / "server.log"
            logfile.write_text(
                "SAFE_RECOVERY_CONTEXT_VALID=true\n"
                "SAFE_RECOVERY_PROTECTING_KEY=false\n"
                "unregistered-child-content-must-not-be-returned\n",
                encoding="utf-8",
            )
            self.assertEqual(verifier_recovery._read_startup_context(logfile), (True, False))

    def test_builtin_partial_readiness_uses_public_report_separation(self) -> None:
        host_source = (
            ROOT
            / "test/clean_room/provider_host/lib/clean_room_provider/verifier_recovery.ex"
        ).read_text(encoding="utf-8")
        self.assertIn(
            "ClientVerifierMaintenance.run(mode: :check, after_client_id: cursor, limit: 1)",
            host_source,
        )
        self.assertIn(
            "ClientVerifierMaintenance.run(mode: :dry_run, after_client_id: cursor, limit: 1)",
            host_source,
        )
        self.assertIn(
            "check == {:error, :client_secret_verifier_maintenance_check_requires_fresh_scan}",
            host_source,
        )
        self.assertIn("scan_complete?: true", host_source)
        self.assertIn("custody_condition_met?: false", host_source)
        self.assertNotIn("initial_cursor: ^cursor", host_source)

    def test_private_handoff_registers_secrets_and_deletes_file(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            handoff = Path(temporary) / "handoff.json"
            handoff.write_text(
                '{"jwt":{"client_id":"owned-client","secret":"private-secret"},'
                '"basic":{"client_id":"basic-client","secret":"basic-secret"},'
                '"post":{"client_id":"post-client","secret":"post-secret"}}',
                encoding="utf-8",
            )
            os.chmod(handoff, 0o600)
            redactor = Redactor(SentinelSet.for_run())
            values = verifier_recovery._read_private_handoff(handoff, redactor)
            self.assertFalse(handoff.exists())
            self.assertEqual(values["jwt"]["secret"], "private-secret")
            self.assertNotIn("private-secret", redactor.text("private-secret"))

    def test_declared_host_otp_apps_support_http_after_mix_path_pruning(self) -> None:
        manifest = (ROOT / "test/clean_room/provider_host/mix.exs").read_text()
        declared = re.search(r"extra_applications:\s*(\[[^\]]+\])", manifest)
        self.assertIsNotNone(declared)

        class HarmlessResponder(BaseHTTPRequestHandler):
            def do_GET(self) -> None:
                status = int(self.path.removeprefix("/probe/"))
                self.send_response(status if status in {200, 400, 401, 500} else 404)
                self.send_header("Content-Length", "0")
                self.end_headers()

            def log_message(self, *_args) -> None:
                pass

        server = ThreadingHTTPServer(("127.0.0.1", 0), HarmlessResponder)
        thread = threading.Thread(target=server.serve_forever, kwargs={"poll_interval": 0.05})
        thread.start()
        try:
            with tempfile.TemporaryDirectory(prefix="lockspire-http-otp-contract-") as temporary:
                child = Path(temporary)
                (child / "mix.exs").write_text(
                    "defmodule HttpOtpContract.MixProject do\n"
                    "  use Mix.Project\n"
                    '  def project, do: [app: :http_otp_contract, version: "0.0.0"]\n'
                    # The real host already receives ssl through its HTTP deps.
                    f"  def application, do: [extra_applications: [:ssl] ++ {declared.group(1)}]\n"
                    "end\n"
                )
                environment = os.environ.copy()
                environment.update({
                    "MIX_ENV": "dev", "MIX_BUILD_PATH": str(child / "_build"),
                    "MIX_DEPS_PATH": str(child / "deps"), "MIX_HOME": str(child / "mix-home"),
                    "HEX_HOME": str(child / "hex-home"),
                })
                environment.setdefault("ERL_FLAGS", "+S 4")
                # Dynamic startup alone must not conceal Mix's pruned code path.
                expression = (
                    "case Application.ensure_all_started(:inets) do "
                    "{:ok, _} -> :ok; "
                    '{:error, _} -> IO.puts("SAFE_HTTP_FAILURE=startup"); System.halt(1) end; '
                    "Enum.each([200, 400, 401, 500], fn expected -> "
                    f'url = String.to_charlist("http://127.0.0.1:{server.server_port}/probe/#{{expected}}"); '
                    "case :httpc.request(:get, {url, []}, [timeout: 2000], []) do "
                    "{:ok, {{_, actual, _}, _, _}} -> "
                    'unless actual == expected, do: raise("HTTP status mismatch"); '
                    '{:error, {:failed_connect, _}} -> IO.puts("SAFE_HTTP_FAILURE=connect"); System.halt(1); '
                    '{:error, :service_not_available} -> IO.puts("SAFE_HTTP_FAILURE=service"); System.halt(1); '
                    '_ -> IO.puts("SAFE_HTTP_FAILURE=other"); System.halt(1) end end); '
                    'IO.puts("SAFE_HOST_HTTP_STATUSES=true")'
                )
                result = subprocess.run(
                    ["mix", "run", "-e", expression], cwd=child, env=environment,
                    capture_output=True, text=True, timeout=30, check=False,
                )
                self.assertEqual(
                    result.returncode, 0,
                    "declared host OTP applications cannot execute HTTP; "
                    f"safe_failure={next((reason for reason in ('startup', 'connect', 'service', 'other') if 'SAFE_HTTP_FAILURE=' + reason in result.stdout), 'none')}; "
                    "child diagnostics withheld",
                )
                self.assertIn("SAFE_HOST_HTTP_STATUSES=true", result.stdout)
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=2)

    def test_recovery_and_issuance_groups_share_the_owned_recovery_runner(self) -> None:
        host_source = (
            ROOT
            / "test/clean_room/provider_host/lib/clean_room_provider/verifier_recovery.ex"
        ).read_text(encoding="utf-8")
        self.assertIn(
            'String.upcase(System.fetch_env!("LOCKSPIRE_PROOF_PAIR"))',
            host_source,
        )
        issuance_source = host_source.split("def run_issuance(store, issuer)", 1)[1].split(
            "def run_issuance(_store, _issuer)", 1
        )[0]
        self.assertIn("start_monitored_worker(", issuance_source)
        self.assertNotIn("Task.async(", issuance_source)
        self.assertEqual(
            clean_room_verifier_upgrade.MODULES["issuance"][0],
            clean_room_verifier_upgrade.MODULES["recovery"][0],
        )
        self.assertNotEqual(
            clean_room_verifier_upgrade.MODULES["issuance"][1],
            clean_room_verifier_upgrade.MODULES["recovery"][1],
        )

    def test_child_failure_reduces_nested_secret_bearing_exception_to_fixed_reason(self) -> None:
        child_code = (
            "import secrets,sys; "
            "secret='child-'+secrets.token_hex(16); "
            "print('CHILD_GENERATED_SENTINEL='+secret); "
            "print('CHILD_STDERR_SENTINEL='+secret,file=sys.stderr); "
            "raise RuntimeError(repr({'client': {'client_secret': secret, 'metadata': {'secret': secret}}}))"
        )
        generated_secrets: list[str] = []
        child_streams: list[str] = []

        def child_failure() -> str:
            completed = subprocess.run(
                [sys.executable, "-c", child_code],
                text=True,
                capture_output=True,
                check=False,
            )
            child_streams.extend((completed.stdout, completed.stderr))
            generated_secrets.extend(
                line.removeprefix("CHILD_GENERATED_SENTINEL=")
                for line in completed.stdout.splitlines()
                if line.startswith("CHILD_GENERATED_SENTINEL=")
            )
            generated_secrets.extend(
                line.removeprefix("CHILD_STDERR_SENTINEL=")
                for line in completed.stderr.splitlines()
                if line.startswith("CHILD_STDERR_SENTINEL=")
            )
            raise RuntimeError(repr({"child_stdout": completed.stdout, "child_stderr": completed.stderr}))

        with tempfile.TemporaryDirectory() as owned_output:
            with self.assertRaises(PackageInputError) as caught:
                verifier_recovery._capture_child_output(child_failure)
            self.assertEqual(list(Path(owned_output).iterdir()), [])

        self.assertEqual(
            str(caught.exception),
            "installed verifier host scenario failed; child diagnostics withheld",
        )
        self.assertEqual(len(generated_secrets), 2)
        self.assertTrue(all(secret not in str(caught.exception) for secret in generated_secrets))
        self.assertIn("CHILD_GENERATED_SENTINEL=", child_streams[0])
        self.assertIn("CHILD_STDERR_SENTINEL=", child_streams[1])

    def test_failed_mix_hides_unregistered_child_stdout_stderr_and_exception_bytes(self) -> None:
        child_code = (
            "import secrets,sys; "
            "secret='unregistered-'+secrets.token_hex(16); "
            "print('CHILD_OUT='+secret); "
            "print('CHILD_ERR='+secret,file=sys.stderr); "
            "print('SAFE_FAILURE_STAGE=expired_apply'); "
            "raise RuntimeError(repr({'client': {'secret': secret}}))"
        )
        child = subprocess.run(
            [sys.executable, "-c", child_code], text=True, capture_output=True, check=False
        )
        self.assertNotEqual(child.returncode, 0)
        combined = (child.stdout + child.stderr).encode()
        secret = child.stdout.split("CHILD_OUT=", 1)[1].splitlines()[0]
        observed = io.StringIO()

        with tempfile.TemporaryDirectory() as owned_output:
            with mock.patch.object(
                build_provider,
                "bounded_run",
                return_value=subprocess.CompletedProcess(
                    args=("mix", "run"), returncode=1, stdout=combined, stderr=None
                ),
            ), contextlib.redirect_stdout(observed), contextlib.redirect_stderr(observed):
                with self.assertRaises(PackageInputError) as caught:
                    build_provider.run_child_command_output(Path(owned_output), {}, "run")
            self.assertEqual(list(Path(owned_output).iterdir()), [])

        captured = str(caught.exception) + observed.getvalue()
        self.assertEqual(
            captured,
            "provider Mix command failed; child diagnostics withheld; SAFE_FAILURE_STAGE=expired_apply",
        )
        self.assertNotIn(secret, captured)
        self.assertIn("CHILD_OUT=", child.stdout)
        self.assertIn("CHILD_ERR=", child.stderr)

    def test_narrow_failure_stages_survive_both_boundaries_without_child_bytes(self) -> None:
        stages = (
            "recovery_interrupt_lock_start", "recovery_interrupt_lock_held",
            "recovery_interrupt_apply_start", "recovery_interrupt_blocked",
            "recovery_interrupt_not_blocked", "recovery_interrupt_kill",
            "recovery_interrupt_lock_release", "recovery_interrupt_observe",
            "recovery_interrupt_cleanup",
            "expired_code_interaction", "expired_code_token", "expired_assertion",
            "expired_request", "expired_http_connect", "expired_http_timeout",
            "expired_http_transport",
            "expired_request_argument", "expired_request_case", "expired_request_function_clause",
            "expired_request_match", "expired_request_erlang", "expired_request_error",
            "expired_request_undefined_httpc", "expired_request_undefined", "expired_request_runtime",
            "expired_request_key", "expired_request_bad_map", "expired_request_bad_arity",
            "expired_request_system_limit",
        )
        for stage in stages:
            with self.subTest(stage=stage), tempfile.TemporaryDirectory() as owned_output:
                output = ("unknown-child-material\nSAFE_FAILURE_STAGE=" + stage + "\n").encode()
                with mock.patch.object(
                    build_provider, "bounded_run",
                    return_value=subprocess.CompletedProcess(
                        args=("mix", "run"), returncode=1, stdout=output, stderr=None
                    ),
                ):
                    with self.assertRaises(PackageInputError) as caught:
                        verifier_recovery._capture_child_output(
                            lambda: build_provider.run_child_command_output(Path(owned_output), {}, "run")
                        )
                self.assertEqual(
                    str(caught.exception),
                    f"installed verifier host scenario failed at {stage}; child diagnostics withheld",
                )
                self.assertEqual(list(Path(owned_output).iterdir()), [])

    def test_unknown_stage_suffix_never_becomes_a_known_stage(self) -> None:
        for suffix in ("_unknown-child-material", "-unknown-child-material", ".unknown-child-material"):
            with self.subTest(suffix=suffix), tempfile.TemporaryDirectory() as owned_output:
                output = ("SAFE_FAILURE_STAGE=expired_http" + suffix + "\n").encode()
                with mock.patch.object(
                    build_provider, "bounded_run",
                    return_value=subprocess.CompletedProcess(
                        args=("mix", "run"), returncode=1, stdout=output, stderr=None
                    ),
                ):
                    with self.assertRaises(PackageInputError) as caught:
                        verifier_recovery._capture_child_output(
                            lambda: build_provider.run_child_command_output(Path(owned_output), {}, "run")
                        )
                self.assertEqual(
                    str(caught.exception),
                    "installed verifier host scenario failed; child diagnostics withheld",
                )


if __name__ == "__main__":
    unittest.main()
