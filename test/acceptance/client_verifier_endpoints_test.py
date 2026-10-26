"""Contracts for source-bound installed verifier endpoint and release groups."""

from __future__ import annotations

import importlib.util
import hashlib
import json
import io
import subprocess
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]

import sys
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import build_provider  # noqa: E402
import clean_room_verifier_upgrade  # noqa: E402
import verifier_endpoints  # noqa: E402
from verifier_receipts import ENDPOINT_CASE_IDS, ReceiptError, validate_receipt  # noqa: E402
from verifier_receipts import RELEASE_RPC_CASE_ID, RELEASE_RPC_OBSERVATION_FIELDS  # noqa: E402


class VerifierEndpointContracts(unittest.TestCase):
    def test_endpoint_and_release_groups_route_to_explicit_entrypoints(self) -> None:
        self.assertEqual(clean_room_verifier_upgrade.MODULES["endpoints"], ("verifier_endpoints", "run_group"))
        self.assertIsNotNone(importlib.util.find_spec("verifier_endpoints"))

    def test_endpoint_group_owns_its_host_fixture(self) -> None:
        fixture = ROOT / "test/clean_room/provider_host/verifier_endpoints.exs"
        self.assertTrue(fixture.is_file(), "endpoint state preparation must stay in a host-owned fixture")
        selected = build_provider.selected_host_fixture_sources({"endpoints"})
        self.assertEqual([path.name for path in selected], ["verifier_endpoints.exs"])

    def test_endpoint_selection_is_explicit_and_independent_of_matrix_width(self) -> None:
        import tempfile

        with tempfile.TemporaryDirectory() as temporary:
            receipt_dir = Path(temporary)
            cell_result = {"pair": "locked", "store": "builtin", "scope": "endpoints", "receipt_path": str(receipt_dir / "locked-builtin" / "receipt.json")}
            with mock.patch.object(verifier_endpoints, "_run_endpoint_cell", return_value=cell_result) as cell:
                output = io.StringIO()
                with redirect_stdout(output):
                    status = clean_room_verifier_upgrade.main([
                        "--pair", "all", "--store", "builtin", "--group", "endpoints",
                        "--receipt-dir", str(receipt_dir),
                    ])
            self.assertEqual(status, 0)
            self.assertEqual(cell.call_count, 2)
            self.assertEqual([call.args[0] for call in cell.call_args_list], ["locked", "floor"])
            summary = json.loads(output.getvalue().splitlines()[-1])
            self.assertEqual(summary["scope"], "endpoints")
            self.assertEqual(summary["executed_count"], 2)
            with self.assertRaisesRegex(build_provider.PackageInputError, "unsupported endpoint"):
                verifier_endpoints.run_group(pair="unknown", store="builtin", receipt_dir=receipt_dir)

    def test_endpoint_receipt_rejects_a_missing_mounted_route_observation(self) -> None:
        binding = {"archive_sha256": "a" * 64, "source_revision": "b" * 40, "tree_sha256": "c" * 64}
        candidate = {"kind": "checkout", "version": "1.6.1", **binding,
                     "runner_revision": "b" * 40,
                     "source_proof": hashlib.sha256(json.dumps(binding, sort_keys=True, separators=(",", ":")).encode()).hexdigest()}
        observation = {"outcome": "pass", "executed": True, "assertion_passed": True,
                       "fresh_jti": True, "http_status": 200,
                       "configured_issuer": "https://issuer.example/lockspire",
                       "discovered_issuer": "https://issuer.example/lockspire",
                       "assertion_audience": "https://issuer.example/lockspire",
                       "rejected_audience_uri": "https://issuer.example/lockspire/wrong"}
        receipt = {
            "schema": "lockspire-installed-verifier-v1", "scope": "endpoints", "run_id": "d" * 32,
            "runner": "b" * 40, "pair": "locked", "store": "builtin", "candidate": candidate,
            "host": {"vendor_tree_sha256": "c" * 64, "compiled_candidate_sha256": "e" * 64,
                     "resolved_dependency_verified": True, "lock_sha256": "f" * 64,
                     "phoenix": "1.8.13", "live_view": "1.2.10"},
            "runtime": {"elixir": "1.19.5", "otp": "28", "postgresql": "14.17"},
            "stable_case_ids": list(ENDPOINT_CASE_IDS),
            "observations": {case: dict(observation) for case in ENDPOINT_CASE_IDS},
            "executed_count": len(ENDPOINT_CASE_IDS), "partial": True,
        }
        receipt["observations"][ENDPOINT_CASE_IDS[2]]["revoked_token_inactive"] = True
        receipt["observations"][ENDPOINT_CASE_IDS[6]].update({
            "fapi_security_excluded": True,
            "fapi_message_signing_excluded": True,
        })
        validate_receipt(receipt, expected_pair="locked", expected_store="builtin")
        del receipt["observations"][ENDPOINT_CASE_IDS[4]]
        with self.assertRaisesRegex(ReceiptError, "omit or add a case"):
            validate_receipt(receipt, expected_pair="locked", expected_store="builtin")

    def test_release_rpc_group_has_a_real_release_owned_executor(self) -> None:
        self.assertEqual(clean_room_verifier_upgrade.MODULES["release-rpc"],
                         ("verifier_endpoints", "run_release_rpc_group"))
        self.assertTrue(callable(getattr(verifier_endpoints, "_run_release_rpc", None)),
                        "release group must assemble and operate an owned running release")
        manifest = (ROOT / "test/clean_room/provider_host/mix.exs").read_text(encoding="utf-8")
        self.assertIn('{:lockspire, path: "vendor/lockspire"}', manifest,
                      "the installed candidate must be included in the assembled host release")
        self.assertNotIn('path: "vendor/lockspire", runtime: false', manifest)

    def test_release_rpc_cli_selection_is_locked_builtin_only(self) -> None:
        import tempfile

        with tempfile.TemporaryDirectory() as temporary:
            receipt_dir = Path(temporary)
            result = {"pair": "locked", "store": "builtin", "scope": "release-rpc",
                      "receipt_path": str(receipt_dir / "locked-builtin" / "receipt.json")}
            output = io.StringIO()
            with mock.patch.object(verifier_endpoints, "_run_release_rpc", return_value=result) as release:
                with redirect_stdout(output):
                    status = clean_room_verifier_upgrade.main([
                        "--pair", "locked", "--store", "builtin", "--group", "release-rpc",
                        "--receipt-dir", str(receipt_dir),
                    ])
                self.assertEqual(status, 0)
                release.assert_called_once_with(receipt_dir / "locked-builtin")
                with redirect_stdout(io.StringIO()):
                    status = clean_room_verifier_upgrade.main([
                        "--pair", "all", "--store", "builtin", "--group", "release-rpc",
                        "--receipt-dir", str(receipt_dir),
                    ])
                self.assertEqual(status, 1)
                release.assert_called_once()
            self.assertEqual(json.loads(output.getvalue().splitlines()[-1])["executed_count"], 1)

    def test_release_rpc_receipt_binds_the_loaded_binary_and_context_origins(self) -> None:
        binding = {"archive_sha256": "a" * 64, "source_revision": "b" * 40, "tree_sha256": "c" * 64}
        candidate = {"kind": "checkout", "version": "1.6.1", **binding,
                     "runner_revision": "b" * 40,
                     "source_proof": hashlib.sha256(json.dumps(binding, sort_keys=True, separators=(",", ":")).encode()).hexdigest()}
        observation = {
            "outcome": "pass", "executed": True, "assembly_succeeded": True,
            "running_process_observed": True, "rpc_executed": True,
            "startup_mode_dedicated": True, "task_local_mode_dedicated": True,
            "task_local_check_ready": True, "rpc_dry_run_complete": True,
            "rpc_fresh_check_ready": True, "loaded_candidate_verified": True,
            "rpc_exit_code": 0, "check_exit_code": 0, "task_local_exit_code": 0,
            "process_pid": "1234", "release_node": "lockspire-verifier-a@127.0.0.1",
            "rpc_invocation": "bin/clean_room_provider rpc dry_run",
            "check_invocation": "bin/clean_room_provider rpc check",
            "task_local_invocation": "mix lockspire.clients.verifier.rewrap --check --limit 100",
            "compiled_module_relative_path": "lib/lockspire-1.6.1/ebin/Elixir.Lockspire.Admin.ClientVerifierMaintenance.beam",
            "compiled_module_sha256": "d" * 64, "startup_context_source": "startup",
            "task_local_context_source": "task_local", "startup_current_key_id": "release-startup",
            "task_local_current_key_id": "task-local", "dry_run_scanned": 0,
            "dry_run_pending": 0, "fresh_check_scanned": 0,
        }
        self.assertEqual(set(observation), RELEASE_RPC_OBSERVATION_FIELDS)
        receipt = {
            "schema": "lockspire-installed-verifier-v1", "scope": "release-rpc", "run_id": "e" * 32,
            "runner": "b" * 40, "pair": "locked", "store": "builtin", "candidate": candidate,
            "host": {"vendor_tree_sha256": "c" * 64, "compiled_candidate_sha256": "e" * 64,
                     "resolved_dependency_verified": True, "lock_sha256": "f" * 64,
                     "phoenix": "1.8.13", "live_view": "1.2.10"},
            "runtime": {"elixir": "1.19.5", "otp": "28", "postgresql": "14.17"},
            "stable_case_ids": [RELEASE_RPC_CASE_ID], "observations": {RELEASE_RPC_CASE_ID: observation},
            "executed_count": 1, "partial": True,
        }
        validate_receipt(receipt, expected_pair="locked", expected_store="builtin")
        receipt["observations"][RELEASE_RPC_CASE_ID]["compiled_module_relative_path"] = "/tmp/Elixir.Lockspire.Admin.ClientVerifierMaintenance.beam"
        with self.assertRaisesRegex(ReceiptError, "bind the assembled candidate"):
            validate_receipt(receipt, expected_pair="locked", expected_store="builtin")

    def test_release_server_starts_as_owned_foreground_process(self) -> None:
        import tempfile
        import urllib.request

        with tempfile.TemporaryDirectory() as temporary:
            release_root = Path(temporary) / "release"
            binary_dir = release_root / "bin"
            binary_dir.mkdir(parents=True)
            process = mock.Mock()
            process.poll.return_value = None
            with mock.patch.object(verifier_endpoints.subprocess, "Popen", return_value=process) as launch, \
                 mock.patch.object(verifier_endpoints.urllib.request, "urlopen") as urlopen:
                urlopen.return_value.__enter__.return_value.status = 200
                actual = verifier_endpoints._start_release_server(
                    binary_dir / "clean_room_provider", {}, "https://issuer.example/lockspire",
                    release_root / "release-server.log",
                )
            self.assertIs(actual, process)
            self.assertEqual(launch.call_args.args[0], (str(binary_dir / "clean_room_provider"), "start"))
            self.assertTrue(launch.call_args.kwargs["start_new_session"])
            self.assertIsNot(launch.call_args.kwargs["stdout"], subprocess.PIPE)
            self.assertEqual(launch.call_args.kwargs["stderr"], subprocess.STDOUT)


if __name__ == "__main__":
    unittest.main()
