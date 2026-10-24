import copy
import contextlib
import io
import signal
import time
from types import SimpleNamespace
import inspect
import json
import os
import shutil
import stat
import subprocess
import tempfile
import sys
import unittest
import uuid
from unittest.mock import patch
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"))
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance"))
import clean_room_admin_journey as admin_journey
from admin_receipts import validate_receipt, write_receipt
import build_provider as provider_builder
from package_input import PackageInputError

FULL_CASE_IDS = (
    "allowed_entry", "assets", "live_navigation", "params_patch", "detail_task",
    "allowed_reconnect", "anonymous_http_denied", "nonstaff_http_denied",
    "cached_join_denied", "reconnect_denied", "params_denied", "public_session_denied",
    "consent_session_denied", "public_discovery", "public_jwks", "public_protocol_error",
)
FULL_CASE_EVIDENCE = {
    "allowed_entry": {"static_200", "join_allowed", "protected_content", "prefix_ok"},
    "assets": {"assets_200"},
    "live_navigation": {"live_navigation", "prefix_ok"},
    "params_patch": {"params_patch", "prefix_ok"},
    "detail_task": {"detail_task", "prefix_ok"},
    "allowed_reconnect": {"socket_closed", "reconnect_join", "interaction_after_reconnect"},
    "anonymous_http_denied": {"anonymous_denied", "protected_content_absent", "prefix_ok"},
    "nonstaff_http_denied": {"nonstaff_denied", "protected_content_absent", "prefix_ok"},
    "cached_join_denied": {"static_200", "cached_join_denied", "protected_content_absent"},
    "reconnect_denied": {"reconnect_denied", "protected_content_absent"},
    "params_denied": {"params_denied", "protected_content_absent"},
    "public_session_denied": {"public_session_denied", "protected_content_absent"},
    "consent_session_denied": {"consent_session_denied", "protected_content_absent"},
    "public_discovery": {"discovery_200", "no_staff_checks"},
    "public_jwks": {"jwks_200", "no_staff_checks"},
    "public_protocol_error": {"protocol_error_shape", "no_staff_checks"},
}
FULL_OBSERVATIONS = frozenset().union(*FULL_CASE_EVIDENCE.values()) | {"assets_200"}


def full_scenario(case_id):
    flags = {name: name in FULL_CASE_EVIDENCE[case_id] for name in FULL_OBSERVATIONS}
    counts = {name: 0 for name in ("assets", "websocket_handshakes", "successful_joins", "navigations", "params_checks", "http_checks", "staff_checks")}
    if case_id == "allowed_entry":
        counts.update(assets=2, successful_joins=1, http_checks=1, staff_checks=1)
    elif case_id == "assets":
        counts.update(assets=2)
    elif case_id == "allowed_reconnect":
        counts.update(websocket_handshakes=2, successful_joins=2, staff_checks=2)
    elif case_id in {"live_navigation", "params_patch", "detail_task"}:
        counts.update(navigations=1, params_checks=1, staff_checks=1)
    elif case_id in {"anonymous_http_denied", "nonstaff_http_denied"}:
        counts.update(http_checks=1, staff_checks=1)
    elif case_id in {"cached_join_denied", "reconnect_denied", "params_denied", "public_session_denied", "consent_session_denied"}:
        counts.update(staff_checks=1)
        if case_id == "params_denied":
            counts["params_checks"] = 1
    return {"id": case_id, "outcome": "passed", "duration_ms": 20, "counts": counts, "observations": flags}


class AdminReceiptTests(unittest.TestCase):
    def setUp(self):
        self.run_id = str(uuid.uuid4())
        self.source = "a" * 40
        self.archive = "b" * 64
        self.tree = "c" * 64
        self.receipt = {
            "schema_version": 1,
            "run_id": self.run_id,
            "source_revision": self.source,
            "source_dirty": True,
            "candidate": {
                "version": "1.6.1",
                "archive_sha256": self.archive,
                "tree_sha256": self.tree,
            },
            "pair": "locked",
            "runtime": {
                "phoenix": "1.8.13",
                "live_view": "1.2.10",
                "elixir": "1.20.4",
                "otp": "29",
                "node": "26.10.0",
                "chrome": "Chrome/155.0.8059.85",
            },
            "mount": "/lockspire",
            "evidence_kind": "real_browser_cdp",
            "scenarios": [{
                "id": "tracer.browser_join_navigation",
                "outcome": "passed",
                "duration_ms": 20,
                "counts": {"assets": 2, "websocket_handshakes": 2, "successful_joins": 2, "navigations": 4},
                "observations": {"login": True, "overview": True, "clients": True, "authorized_http": True, "connected_hook": True},
            }],
            "cleanup": {"processes_stopped": True, "database_removed": True, "profile_removed": True, "run_root_removed": True},
            "result": "passed",
        }

    def test_valid_receipt_binds_run_source_candidate_runtime_and_cleanup(self):
        validated = validate_receipt(
            self.receipt,
            expected_run_id=self.run_id,
            expected_source=self.source,
            expected_pair="locked",
            expected_mount="/lockspire",
            expected_archive=self.archive,
            expected_tree=self.tree,
        )
        self.assertEqual(validated["result"], "passed")

    def test_floor_pair_accepts_only_the_exact_floor_runtime(self):
        floor_receipt = copy.deepcopy(self.receipt)
        floor_receipt["pair"] = "floor"
        floor_receipt["runtime"]["phoenix"] = "1.8.5"
        floor_receipt["runtime"]["live_view"] = "1.1.28"

        validated = validate_receipt(floor_receipt, expected_pair="floor")

        self.assertEqual(validated["pair"], "floor")

        floor_receipt["runtime"]["phoenix"] = "1.8.13"
        floor_receipt["runtime"]["live_view"] = "1.2.10"
        with self.assertRaisesRegex(ValueError, "do not match selected pair"):
            validate_receipt(floor_receipt, expected_pair="floor")

    def test_runner_and_provider_expose_explicit_floor_pair_selection(self):
        args = admin_journey.parse_args(
            ["--pair", "floor", "--mount", "/lockspire", "--receipt", "receipt.json"]
        )

        self.assertEqual(args.pair, "floor")
        self.assertIn("proof_pair", inspect.signature(provider_builder.prepare_provider).parameters)

    def test_runtime_sources_may_use_only_the_child_or_pair_dependency_cache(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            child = root / "host"
            deps = root / "pair-cache" / "provider" / "deps"
            child.mkdir()
            deps.mkdir(parents=True)
            sources = [child / "module.beam", child / "phoenix.beam", deps / "phoenix.js", deps / "live_view.js"]
            for source in sources:
                source.touch()
            proof = "RUNTIME_PROOF|1.8.5|1.1.28|1.20.4|29|" + "|".join(map(str, sources))
            with patch.object(admin_journey, "run_child_command_output", return_value=proof):
                runtime = admin_journey.runtime_versions(child, {"MIX_DEPS_PATH": str(deps)})
            self.assertEqual((runtime["phoenix"], runtime["live_view"]), ("1.8.5", "1.1.28"))

            outside = root / "root-checkout" / "phoenix.js"
            outside.parent.mkdir()
            outside.touch()
            sources[-2] = outside
            proof = "RUNTIME_PROOF|1.8.5|1.1.28|1.20.4|29|" + "|".join(map(str, sources))
            with patch.object(admin_journey, "run_child_command_output", return_value=proof):
                with self.assertRaises(PackageInputError):
                    admin_journey.runtime_versions(child, {"MIX_DEPS_PATH": str(deps)})

    def test_floor_pair_uses_its_frozen_lock_and_isolated_environment_cache(self):
        with tempfile.TemporaryDirectory() as temporary:
            child = Path(temporary) / "provider_host"
            child.mkdir()
            (child / "mix.exs").write_bytes((provider_builder.PROVIDER_TEMPLATE / "mix.exs").read_bytes())
            (child / "mix.lock").write_bytes((provider_builder.PROVIDER_TEMPLATE / "mix.lock").read_bytes())

            lock_hash = provider_builder.configure_proof_pair(child, "floor", admin_proof=True)
            floor_lock = provider_builder.FLOOR_TEMPLATE / "mix.lock"
            manifest = (child / "mix.exs").read_text()
            marker = (child / provider_builder.PROOF_PAIR_MARKER).read_text()
            floor_cache = provider_builder.proof_pair_cache_root(Path(temporary) / "cache", "floor", "test")
            locked_cache = provider_builder.proof_pair_cache_root(Path(temporary) / "cache", "locked", "test")

            self.assertEqual((child / "mix.lock").read_bytes(), floor_lock.read_bytes())
            self.assertIn('{:phoenix, "== 1.8.5"}', manifest)
            self.assertIn('{:phoenix_live_view, "== 1.1.28"}', manifest)
            self.assertEqual(marker, f"pair=floor\nlock_sha256={lock_hash}\n")
            self.assertIn("/floor/", str(floor_cache))
            self.assertIn("/test", str(floor_cache))
            self.assertNotEqual(floor_cache, locked_cache)

    def test_reused_pair_mismatch_and_wrong_runtime_are_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            child = Path(temporary) / "provider_host"
            child.mkdir()
            (child / "mix.exs").write_bytes((provider_builder.PROVIDER_TEMPLATE / "mix.exs").read_bytes())
            (child / "mix.lock").write_bytes((provider_builder.PROVIDER_TEMPLATE / "mix.lock").read_bytes())
            provider_builder.configure_proof_pair(child, "floor", admin_proof=True)
            (child / provider_builder.PROOF_PAIR_MARKER).write_text("pair=locked\nlock_sha256=wrong\n")

            with self.assertRaisesRegex(PackageInputError, "reused provider proof pair"):
                provider_builder.configure_proof_pair(child, "floor", admin_proof=True, reused=True)

        with self.assertRaisesRegex(PackageInputError, "do not match selected pair"):
            admin_journey.validate_pair_runtime("floor", {"phoenix": "1.8.13", "live_view": "1.2.10"})

    def test_passed_receipt_requires_positive_browser_join_and_navigation(self):
        for key, value in (("assets", 1), ("websocket_handshakes", 0), ("successful_joins", 0), ("navigations", 0)):
            with self.subTest(key=key):
                malformed = copy.deepcopy(self.receipt)
                malformed["scenarios"][0]["counts"][key] = value
                with self.assertRaises(ValueError):
                    validate_receipt(malformed)

    def test_candidate_mismatch_and_cleanup_failure_cannot_be_reported_as_passed(self):
        malformed = copy.deepcopy(self.receipt)
        malformed["candidate"]["tree_sha256"] = "d" * 64
        with self.assertRaises(ValueError):
            validate_receipt(malformed, expected_tree=self.tree)

    def test_cleanup_failure_cannot_be_reported_as_passed(self):
        malformed = copy.deepcopy(self.receipt)
        malformed["cleanup"]["profile_removed"] = False
        malformed["result"] = "failed"
        self.assertEqual(validate_receipt(malformed)["result"], "failed")

    def test_unhashable_scenario_identifier_is_rejected_as_invalid_receipt(self):
        malformed = copy.deepcopy(self.receipt)
        malformed["scenarios"][0]["id"] = []
        try:
            validate_receipt(malformed)
        except Exception as error:
            self.assertIsInstance(error, ValueError, "malformed receipt data must fail with the validator's safe error")
        else:
            self.fail("unhashable scenario identity was accepted")

    def test_writer_creates_private_receipt_file(self):
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "nested" / "receipt.json"
            write_receipt(
                destination,
                self.receipt,
                expected_run_id=self.run_id,
                expected_source=self.source,
                expected_pair="locked",
                expected_mount="/lockspire",
                expected_archive=self.archive,
                expected_tree=self.tree,
                expected_scenario_set="tracer",
            )
            self.assertTrue(destination.exists())
            self.assertEqual(destination.stat().st_mode & 0o777, 0o600)
            self.assertEqual(validate_receipt(__import__("json").loads(destination.read_text()))["result"], "passed")

    def test_suite_has_exact_known_case_count(self):
        self.assertEqual(sum(name.startswith("test_") for name in dir(type(self))), 22)

    def test_receipt_durations_accept_only_nonnegative_integer_milliseconds(self):
        for duration in (True, 1.5, -1, float("inf"), float("nan")):
            with self.subTest(duration=duration):
                malformed = copy.deepcopy(self.receipt)
                malformed["scenarios"][0]["duration_ms"] = duration
                with self.assertRaises(ValueError):
                    validate_receipt(malformed)

    def test_receipt_cli_binding_compares_expected_candidate_version_exactly(self):
        with self.assertRaisesRegex(ValueError, "candidate version differs from the expected candidate"):
            validate_receipt(self.receipt, expected_version="1.6.10")

    def test_receipt_rejects_stale_run_source_pair_and_mount_bindings(self):
        wrong_expectations = (
            {"expected_run_id": str(uuid.uuid4())},
            {"expected_source": "d" * 40},
            {"expected_pair": "floor"},
            {"expected_mount": "/"},
            {"expected_archive": "d" * 64},
            {"expected_tree": "d" * 64},
        )
        for expected in wrong_expectations:
            with self.subTest(expected=sorted(expected)):
                with self.assertRaises(ValueError):
                    validate_receipt(self.receipt, **expected)

    def test_cli_rejects_a_well_formed_failed_receipt_as_success_evidence(self):
        failed = copy.deepcopy(self.receipt)
        failed["scenarios"][0]["outcome"] = "failed"
        failed["result"] = "failed"
        with tempfile.TemporaryDirectory() as temporary:
            receipt_path = Path(temporary) / "failed-receipt.json"
            receipt_path.write_text(json.dumps(failed), encoding="utf-8")
            validator_path = Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room" / "admin_receipts.py"
            result = subprocess.run(
                [
                    sys.executable, str(validator_path), "--check", str(receipt_path),
                    "--expected-run-id", self.run_id, "--expected-source", self.source,
                    "--expected-pair", "locked", "--expected-mount", "/lockspire",
                    "--expected-archive", self.archive, "--expected-tree", self.tree,
                    "--expected-version", "1.6.1", "--expected-scenario-set", "tracer",
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                check=False,
            )
        self.assertNotEqual(result.returncode, 0, "a failed receipt cannot be accepted as success evidence")

    def test_browser_failure_summary_discards_hostile_child_fields(self):
        summarize = getattr(admin_journey, "safe_browser_failure_summary", None)
        self.assertTrue(callable(summarize), "browser diagnostics must pass through a strict allowlist")
        if not callable(summarize):
            return
        sentinel = "phase170-private-cookie-sentinel"
        summary = summarize({
            "failure": sentinel,
            "stage": sentinel,
            "outcome": "failed",
            "counts": {"assets": sentinel, "cookie": sentinel},
            "observations": {"login": sentinel, "session": sentinel},
        })
        rendered = __import__("json").dumps(summary)
        self.assertNotIn(sentinel, rendered)
        self.assertEqual(set(summary), {"failure", "stage", "outcome", "counts", "observations"})
        self.assertEqual(summary["counts"], {})
        self.assertEqual(summary["observations"], {})

    def test_runtime_versions_cannot_retain_arbitrary_child_strings(self):
        malformed = copy.deepcopy(self.receipt)
        malformed["runtime"]["node"] = "phase170-private-cookie-sentinel"
        with self.assertRaises(ValueError):
            validate_receipt(malformed)

    def test_full_receipt_accepts_all_sixteen_named_boundary_cases(self):
        full = copy.deepcopy(self.receipt)
        full["scenarios"] = [full_scenario(case_id) for case_id in FULL_CASE_IDS]
        try:
            validated = validate_receipt(full, expected_scenario_set="full")
        except ValueError as error:
            self.fail(f"complete full case-set receipt should validate: {error}")
        self.assertEqual(validated["result"], "passed")
        self.assertEqual({item["id"] for item in validated["scenarios"]}, set(FULL_CASE_IDS))

    def test_full_scenario_extraction_preserves_each_case_outcome(self):
        observed = {"scenarios": [full_scenario(case_id) for case_id in FULL_CASE_IDS]}
        observed["scenarios"][-1]["outcome"] = "failed"
        extracted = admin_journey.full_scenarios_from_observation(observed)
        self.assertEqual(len(extracted), 16)
        self.assertEqual([item["outcome"] for item in extracted].count("passed"), 15)
        self.assertEqual(extracted[-1]["outcome"], "failed")

    def test_full_receipt_rejects_missing_duplicate_and_unknown_case_ids(self):
        for label, ids in (
            ("missing", FULL_CASE_IDS[:-1]),
            ("duplicate", FULL_CASE_IDS[:-1] + (FULL_CASE_IDS[0], FULL_CASE_IDS[0])),
            ("unknown", FULL_CASE_IDS[:-1] + ("secret_cookie",)),
        ):
            with self.subTest(label=label):
                malformed = copy.deepcopy(self.receipt)
                malformed["scenarios"] = [
                    full_scenario(case_id) if case_id in FULL_CASE_EVIDENCE
                    else {**full_scenario(FULL_CASE_IDS[0]), "id": case_id}
                    for case_id in ids
                ]
                with self.assertRaises(ValueError):
                    validate_receipt(malformed, expected_scenario_set="full")

    def test_full_receipt_requires_live_boundary_counters_before_and_after_mutation(self):
        for case_id, counter in (("cached_join_denied", "staff_checks"), ("reconnect_denied", "staff_checks"), ("params_denied", "params_checks")):
            with self.subTest(case_id=case_id):
                full = copy.deepcopy(self.receipt)
                full["scenarios"] = [full_scenario(item) for item in FULL_CASE_IDS]
                selected = next(item for item in full["scenarios"] if item["id"] == case_id)
                selected["counts"][counter] = 0
                with self.assertRaises(ValueError):
                    validate_receipt(full, expected_scenario_set="full")


class AdminCleanupRegressionTests(unittest.TestCase):
    def test_nested_diagnostics_never_copy_unknown_keys_or_values(self):
        sentinel = "phase170-private-nested-key-sentinel"
        for malformed in (sentinel, [], {}):
            with self.subTest(malformed=type(malformed).__name__):
                observed = {"scenarios": [{
                    "id": malformed, "failure": malformed, "outcome": malformed,
                    "counts": {sentinel: sentinel, 7: sentinel, "assets": sentinel},
                    "observations": {sentinel: sentinel, 7: False, "static_200": False},
                }]}
                rendered = json.dumps(admin_journey.safe_browser_failure_summary(observed))
                self.assertNotIn(sentinel, rendered)
                self.assertNotIn('"7"', rendered)
                self.assertIn("unknown", rendered)
                observed["scenarios"][0]["counts"].pop(7)
                observed["scenarios"][0]["observations"].pop(7)
                self.assertNotIn(sentinel, json.dumps(admin_journey.safe_browser_failure_summary(observed)))

    def test_main_removes_raw_root_and_writes_failed_receipt_when_drop_raises(self):
        for fault in (subprocess.TimeoutExpired("secret-command", 30), OSError("private-error")):
            with self.subTest(fault=type(fault).__name__), tempfile.TemporaryDirectory() as temporary:
                base = Path(temporary) / "run"
                base.mkdir()
                (base / "provider.log").write_text("phase170-private-log-sentinel")
                identity = SimpleNamespace(source_revision="a" * 40, version="1.6.1", archive_sha256="b" * 64, tree_sha256="c" * 64)
                captured = {}
                def retain(_path, receipt, **_kwargs):
                    captured.update(receipt)
                output = io.StringIO()
                with patch.object(admin_journey.tempfile, "mkdtemp", return_value=str(base)), patch.object(admin_journey, "package_source"), patch.object(admin_journey, "prepare_package", return_value=(base, [], identity)), patch.object(admin_journey, "prepare_provider", return_value=base), patch.object(admin_journey, "run_child_command", side_effect=RuntimeError("phase170-private-exception-sentinel")), patch.object(admin_journey, "bounded_run", side_effect=fault), patch.object(admin_journey.subprocess, "run", return_value=SimpleNamespace(stdout=b"")), patch.object(admin_journey, "write_receipt", side_effect=retain), contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
                    status = admin_journey.main(["--pair", "locked", "--mount", "/lockspire", "--scenario", "tracer", "--receipt", str(Path(temporary) / "receipt.json")])
                self.assertEqual(status, 1)
                self.assertFalse(base.exists())
                self.assertFalse(captured["cleanup"]["database_removed"])
                self.assertTrue(captured["cleanup"]["run_root_removed"])
                self.assertEqual(captured["result"], "failed")
                self.assertNotIn("private", output.getvalue())


    def test_completed_browser_keeps_a_valid_failed_receipt_when_drop_raises(self):
        observed = {
            "id": "tracer.browser_join_navigation", "outcome": "passed", "duration_ms": 20,
            "counts": {"assets": 2, "websocket_handshakes": 2, "successful_joins": 2, "navigations": 4},
            "observations": {"login": True, "overview": True, "clients": True, "authorized_http": True, "connected_hook": True},
            "runtime": {"node": "26.10.0", "chrome": "Chrome/155.0.8059.85"}, "profile_removed": True,
        }
        for fault in (subprocess.TimeoutExpired("private-command", 30), OSError("private-error")):
            with self.subTest(fault=type(fault).__name__), tempfile.TemporaryDirectory() as temporary:
                base = Path(temporary) / "run"
                base.mkdir()
                receipt_path = Path(temporary) / "receipt.json"
                identity = SimpleNamespace(source_revision="a" * 40, version="1.6.1", archive_sha256="b" * 64, tree_sha256="c" * 64)
                output = io.StringIO()
                with patch.object(admin_journey.tempfile, "mkdtemp", return_value=str(base)), patch.object(admin_journey, "package_source"), patch.object(admin_journey, "prepare_package", return_value=(base, [], identity)), patch.object(admin_journey, "prepare_provider", return_value=base), patch.object(admin_journey, "run_child_command"), patch.object(admin_journey, "runtime_versions", return_value={"phoenix": "1.8.13", "live_view": "1.2.10", "elixir": "1.20.4", "otp": "29"}), patch.object(admin_journey, "wait_ready"), patch.object(admin_journey.subprocess, "Popen"), patch.object(admin_journey, "stop_owned", return_value=True), patch.object(admin_journey, "bounded_run", side_effect=[SimpleNamespace(stdout=json.dumps(observed), returncode=0), fault]), patch.object(admin_journey.subprocess, "run", return_value=SimpleNamespace(stdout=b"")), contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
                    status = admin_journey.main(["--pair", "locked", "--mount", "/", "--scenario", "tracer", "--receipt", str(receipt_path)])
                self.assertEqual(status, 1)
                retained = validate_receipt(json.loads(receipt_path.read_text()))
                self.assertEqual(retained["result"], "failed")
                self.assertFalse(retained["cleanup"]["database_removed"])
                self.assertTrue(retained["cleanup"]["run_root_removed"])
                self.assertFalse(base.exists())
                self.assertNotIn("private", output.getvalue())
                self.assertNotIn("private", receipt_path.read_text())

    def test_main_never_retains_nested_hostile_browser_data(self):
        sentinel = "phase170-private-browser-key-and-value"
        hostile = {"id": [], "failure": {}, "outcome": [], "counts": {sentinel: sentinel}, "observations": {sentinel: sentinel}}
        observation = {"id": "full", "outcome": "failed", "scenarios": [hostile] * 16}
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary) / "run"
            base.mkdir()
            receipt = Path(temporary) / "receipt.json"
            identity = SimpleNamespace(source_revision="a" * 40, version="1.6.1", archive_sha256="b" * 64, tree_sha256="c" * 64)
            output = io.StringIO()
            with patch.object(admin_journey.tempfile, "mkdtemp", return_value=str(base)), patch.object(admin_journey, "package_source"), patch.object(admin_journey, "prepare_package", return_value=(base, [], identity)), patch.object(admin_journey, "prepare_provider", return_value=base), patch.object(admin_journey, "run_child_command"), patch.object(admin_journey, "runtime_versions", return_value={"phoenix": "1.8.13", "live_view": "1.2.10"}), patch.object(admin_journey, "wait_ready"), patch.object(admin_journey.subprocess, "Popen"), patch.object(admin_journey, "stop_owned", return_value=True), patch.object(admin_journey, "bounded_run", side_effect=[SimpleNamespace(stdout=json.dumps(observation), returncode=1), SimpleNamespace(returncode=0)]), patch.object(admin_journey.subprocess, "run", return_value=SimpleNamespace(stdout=b"")), contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
                status = admin_journey.main(["--pair", "locked", "--mount", "/", "--receipt", str(receipt)])
            self.assertEqual(status, 1)
            self.assertNotIn(sentinel, output.getvalue())
            self.assertFalse(receipt.exists())
            self.assertFalse(base.exists())

    def test_real_runner_interruption_and_browser_timeout_remove_owned_resources(self):
        root = Path(__file__).resolve().parents[2]
        for mode in ("SIGTERM", "SIGINT", "timeout"):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as temporary:
                task_root = Path(temporary)
                tools = task_root / "bin"
                tools.mkdir()
                fake = """#!/usr/bin/env python3
import os, signal, sys, time
from pathlib import Path
if 'ecto.drop' in sys.argv: raise SystemExit(0)
name = Path(sys.argv[0]).name
Path(os.environ['PROOF_TEST_ROOT'], name + '.pid').write_text(str(os.getpid()))
print('phase170-private-child-output', flush=True)
while True: time.sleep(1)
"""
                for name in ("mix", "node"):
                    executable = tools / name
                    executable.write_text(fake)
                    executable.chmod(0o700)
                driver = task_root / "driver.py"
                driver.write_text("""
import json, os, sys
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
sys.path.insert(0, sys.argv[1] + '/scripts/acceptance')
import clean_room_admin_journey as journey
root = Path(os.environ['PROOF_TEST_ROOT'])
base = root / 'private-run'
base.mkdir()
(root / 'base').write_text(str(base))
identity = SimpleNamespace(source_revision='a' * 40, version='1.6.1', archive_sha256='b' * 64, tree_sha256='c' * 64)
def retain(_path, receipt, **kwargs):
    (root / 'cleanup.json').write_text(json.dumps(receipt['cleanup']))
original = journey.bounded_run
def bounded(command, **kwargs):
    if command[0] == 'node' and os.environ['PROOF_TEST_MODE'] == 'timeout': kwargs['timeout'] = .2
    return original(command, **kwargs)
with patch.object(journey.tempfile, 'mkdtemp', return_value=str(base)), patch.object(journey, 'package_source'), patch.object(journey, 'prepare_package', return_value=(base, [], identity)), patch.object(journey, 'prepare_provider', return_value=base), patch.object(journey, 'run_child_command'), patch.object(journey, 'runtime_versions', return_value={'phoenix':'1.8.13','live_view':'1.2.10'}), patch.object(journey, 'wait_ready'), patch.object(journey, 'write_receipt', side_effect=retain), patch.object(journey, 'bounded_run', side_effect=bounded):
    raise SystemExit(journey.main(['--pair','locked','--mount','/','--scenario','tracer','--receipt',str(root / 'receipt.json')]))
""")
                environment = {**os.environ, "PATH": str(tools) + os.pathsep + os.environ["PATH"], "PROOF_TEST_ROOT": str(task_root), "PROOF_TEST_MODE": mode}
                process = subprocess.Popen([sys.executable, str(driver), str(root)], env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
                try:
                    deadline = time.monotonic() + 5
                    while not (task_root / "node.pid").exists() and process.poll() is None and time.monotonic() < deadline:
                        time.sleep(.02)
                    self.assertTrue((task_root / "node.pid").exists(), "real Node child started")
                    if mode != "timeout":
                        process.send_signal(getattr(signal, mode))
                    output, _ = process.communicate(timeout=12)
                    self.assertNotEqual(process.returncode, 0)
                    self.assertNotIn("phase170-private", output)
                    self.assertFalse((task_root / "private-run").exists())
                    self.assertTrue(all(json.loads((task_root / "cleanup.json").read_text()).values()))
                    for name in ("mix", "node"):
                        with self.assertRaises(ProcessLookupError):
                            os.kill(int((task_root / (name + ".pid")).read_text()), 0)
                finally:
                    if process.poll() is None:
                        process.kill()
                    process.communicate()
                    for name in ("mix", "node"):
                        pid_file = task_root / (name + ".pid")
                        if pid_file.exists():
                            try:
                                os.killpg(int(pid_file.read_text()), signal.SIGKILL)
                            except ProcessLookupError:
                                pass


class HostProofReceiptDirectoryTests(unittest.TestCase):
    ROOT = Path(__file__).resolve().parents[2]
    DIAGNOSTIC = "receipt directory must be below .artifacts"

    def test_unsafe_receipt_directories_are_rejected_before_any_file_changes(self):
        for case in ("traversal", "contained_traversal", "symlink_root", "symlink_parent", "symlink_destination"):
            with self.subTest(case=case), tempfile.TemporaryDirectory() as temporary:
                task_root = Path(temporary)
                repo = task_root / "repo"
                repo.mkdir()
                subprocess.run(["git", "init", "--quiet", str(repo)], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10)
                outside = repo / "outside"
                outside.mkdir()
                sentinels = {name: ("private-external-" + name).encode() for name in ("lifecycle.json", "locked-lockspire.json", "locked-nested.json", "locked-root.json")}
                for name, data in sentinels.items():
                    (outside / name).write_bytes(data)
                artifacts = repo / ".artifacts"
                if case == "symlink_root":
                    artifacts.symlink_to(outside, target_is_directory=True)
                    receipt_dir = ".artifacts/new-output"
                else:
                    artifacts.mkdir()
                    if case == "traversal":
                        receipt_dir = ".artifacts/../outside"
                    elif case == "contained_traversal":
                        receipt_dir = ".artifacts/new-parent/../new-output"
                    elif case == "symlink_parent":
                        (artifacts / "link").symlink_to(outside, target_is_directory=True)
                        receipt_dir = ".artifacts/link/new-output"
                    else:
                        (artifacts / "link").symlink_to(outside, target_is_directory=True)
                        receipt_dir = ".artifacts/link"
                before = {path.relative_to(repo): path.read_bytes() for path in outside.rglob("*") if path.is_file()}
                result = subprocess.run(["bash", str(self.ROOT / "scripts/ci/run_host_integration_proof.sh"), "--pair", "locked", "--receipt-dir", receipt_dir], cwd=repo, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=15, check=False)
                after = {path.relative_to(repo): path.read_bytes() for path in outside.rglob("*") if path.is_file()}
                self.assertEqual(after, before, "external receipt sentinels and directory contents must remain untouched")
                self.assertFalse((artifacts / "new-parent").exists(), "reject before creating any component")
                self.assertFalse((outside / "new-output").exists(), "reject symlinks before mkdir")
                self.assertEqual(result.returncode, 64, result.stdout)
                self.assertEqual(result.stdout.strip(), self.DIAGNOSTIC)


class HostProofWrapperFailureTests(unittest.TestCase):
    ROOT = Path(__file__).resolve().parents[2]
    SENTINEL = "phase170-fake-tool-secret-sentinel"

    @classmethod
    def setUpClass(cls):
        cls._temporary = tempfile.TemporaryDirectory(prefix="lockspire-host-proof-fakes-")
        cls.tools = Path(cls._temporary.name)
        package_dir = cls.tools / "package"
        package_dir.mkdir()
        version = __import__("re").search(r'version: "([^"]+)"', (cls.ROOT / "mix.exs").read_text()).group(1)
        cls.package_template = package_dir / f"lockspire-{version}.tar"
        subprocess.run(
            ["mix", "hex.build", "--output", str(cls.package_template)],
            cwd=cls.ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=True,
        )

        cls.fake_mix = cls.tools / "mix-fake.py"
        cls.fake_mix.write_text(
            "#!/usr/bin/env python3\n"
            "import os, signal, shutil, sys, time\n"
            "args = sys.argv[1:]\n"
            "stage = os.environ.get('LOCKSPIRE_PROOF_FAKE_STAGE', '')\n"
            "if args[0] == 'hex.build':\n"
            "    shutil.copyfile(os.environ['LOCKSPIRE_PROOF_TEST_PACKAGE_TEMPLATE'], args[args.index('--output') + 1])\n"
            "elif args[0] == 'run':\n"
            "    print('PAIR_RUNTIME|1.8.13|1.2.10|1.20.4|29')\n"
            "elif args[0] in {'test.setup', 'lockspire.test.setup'}:\n"
            "    pass\n"
            "elif args[0] == 'ecto.drop':\n"
            "    with open(os.environ['LOCKSPIRE_PROOF_DROP_RECORD'], 'a') as output: output.write(os.environ['LOCKSPIRE_TEST_DB_NAME'] + '\\n')\n"
            "    if stage in {'drop-failure', 'shared-drop-failure'}: raise SystemExit(49)\n"
            "    if stage == 'drop-timeout': time.sleep(30)\n"
            "elif args[0] == 'test':\n"
            "    if stage in {'shared-failure', 'signal', 'timeout'}: print(os.environ['LOCKSPIRE_PROOF_FAKE_SECRET'], file=sys.stderr, flush=True)\n"
            "    if stage in {'shared-failure', 'shared-drop-failure'}: raise SystemExit(37)\n"
            "    if stage == 'signal': os.kill(os.getpid(), signal.SIGTERM)\n"
            "    if stage in {'timeout', 'wrapper-signal'}:\n"
            "        from pathlib import Path\n"
            "        Path(os.environ['LOCKSPIRE_PROOF_READY']).write_text(str(os.getpid()))\n"
            "        time.sleep(30)\n"
            "    print('Result: 43 passed')\n"
            "else:\n"
            "    raise SystemExit(2)\n",
            encoding="utf-8",
        )
        cls.fake_mix.chmod(cls.fake_mix.stat().st_mode | stat.S_IXUSR)

        cls.fake_journey = cls.tools / "journey-fake.py"
        cls.fake_journey.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "from pathlib import Path\n"
            "stage = os.environ.get('LOCKSPIRE_PROOF_FAKE_STAGE', '')\n"
            "print(os.environ['LOCKSPIRE_PROOF_FAKE_SECRET'], file=sys.stderr)\n"
            "if stage == 'browser-failure': raise SystemExit(41)\n"
            "payload = {'evidence': 'safe'} if stage in {'success', 'drop-failure', 'drop-timeout'} else {'unsafe': os.environ['LOCKSPIRE_PROOF_FAKE_SECRET']}\n"
            "Path(sys.argv[sys.argv.index('--receipt') + 1]).write_text(json.dumps(payload))\n",
            encoding="utf-8",
        )
        cls.fake_journey.chmod(cls.fake_journey.stat().st_mode | stat.S_IXUSR)

        cls.fake_validator = cls.tools / "validator-fake.py"
        cls.fake_validator.write_text(
            "#!/usr/bin/env python3\n"
            "import os\n"
            "print(os.environ['LOCKSPIRE_PROOF_FAKE_SECRET'], file=__import__('sys').stderr)\n"
            "raise SystemExit(0 if os.environ.get('LOCKSPIRE_PROOF_FAKE_STAGE') in {'success', 'drop-failure', 'drop-timeout'} else 43)\n",
            encoding="utf-8",
        )
        cls.fake_validator.chmod(cls.fake_validator.stat().st_mode | stat.S_IXUSR)

        cls.fake_chrome = cls.tools / "chrome-fake.sh"
        cls.fake_chrome.write_text("#!/bin/sh\nprintf '%s\\n' 'Google Chrome 155.0.8059.85'\n", encoding="utf-8")
        cls.fake_chrome.chmod(cls.fake_chrome.stat().st_mode | stat.S_IXUSR)

    @classmethod
    def tearDownClass(cls):
        cls._temporary.cleanup()

    def run_wrapper(self, stage, *, timeout_seconds=None, stale_receipt=False, interrupt=None, nested=False):
        artifact_root = self.ROOT / ".artifacts" / "phase170"
        artifact_root.mkdir(parents=True, exist_ok=True)
        receipt_dir = Path(tempfile.mkdtemp(prefix="fake-proof-", dir=artifact_root))
        self.addCleanup(shutil.rmtree, receipt_dir)
        if nested:
            receipt_dir = receipt_dir / "new-parent" / "new-output"
        stale_path = receipt_dir / "locked-lockspire.json"
        if stale_receipt:
            stale_path.write_text(self.SENTINEL, encoding="utf-8")

        raw_parent = Path(tempfile.mkdtemp(prefix="proof-raw-parent-", dir=self.tools))
        self.addCleanup(shutil.rmtree, raw_parent)
        environment = os.environ.copy()
        environment.update({
            "TMPDIR": str(raw_parent),
            "LOCKSPIRE_PROOF_TEST_MODE": "true",
            "LOCKSPIRE_PROOF_TEST_MIX_BIN": str(self.fake_mix),
            "LOCKSPIRE_PROOF_TEST_JOURNEY_BIN": str(self.fake_journey),
            "LOCKSPIRE_PROOF_TEST_VALIDATOR_BIN": str(self.fake_validator),
            "LOCKSPIRE_PROOF_TEST_PACKAGE_TEMPLATE": str(self.package_template),
            "LOCKSPIRE_PROOF_FAKE_STAGE": stage,
            "LOCKSPIRE_PROOF_FAKE_SECRET": self.SENTINEL,
            "CHROME_BIN": str(self.fake_chrome),
            "LOCKSPIRE_PROOF_DROP_RECORD": str(receipt_dir / "drop-record"),
            "LOCKSPIRE_PROOF_READY": str(raw_parent / "ready"),
        })
        if timeout_seconds is not None:
            environment["LOCKSPIRE_PROOF_TEST_TIMEOUT_SECONDS"] = str(timeout_seconds)
        else:
            environment.pop("LOCKSPIRE_PROOF_TEST_TIMEOUT_SECONDS", None)
        command = ["bash", str(self.ROOT / "scripts" / "ci" / "run_host_integration_proof.sh"), "--pair", "locked", "--receipt-dir", str(receipt_dir.relative_to(self.ROOT))]
        process = subprocess.Popen(command, cwd=self.ROOT, env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        try:
            if interrupt is not None:
                deadline = time.monotonic() + 10
                while not (raw_parent / "ready").exists() and process.poll() is None and time.monotonic() < deadline:
                    time.sleep(.02)
                self.assertTrue((raw_parent / "ready").exists(), "actual bounded child must start before signal")
                process.send_signal(interrupt)
            output, _ = process.communicate(timeout=45)
            result = subprocess.CompletedProcess(command, process.returncode, output)
        finally:
            if process.poll() is None:
                process.kill()
            process.communicate()
        ready = raw_parent / "ready"
        if ready.exists():
            owned_pid = int(ready.read_text())
            ready.unlink()
            with self.assertRaises(ProcessLookupError):
                os.kill(owned_pid, 0)
        self.assertEqual(list(raw_parent.iterdir()), [], "private logs and raw receipts must be removed")
        drop_record = receipt_dir / "drop-record"
        self.assertTrue(drop_record.exists(), "the wrapper must drop its lifecycle database on every exit")
        self.assertRegex(drop_record.read_text(), r"^lockspire_proof_locked_[a-f0-9]{20}\n$")
        drop_record.unlink()
        return result, receipt_dir

    def assert_staging_redacted(self, receipt_dir):
        for path in receipt_dir.iterdir():
            if path.is_file():
                self.assertNotIn(self.SENTINEL, path.read_text(encoding="utf-8"))

    def test_shared_test_failure_preserves_status_without_printing_child_secret(self):
        result, receipt_dir = self.run_wrapper("shared-failure", stale_receipt=True)

        self.assertEqual(result.returncode, 37)
        self.assertNotIn(self.SENTINEL, result.stdout)
        self.assertFalse((receipt_dir / "locked-lockspire.json").exists())
        self.assert_staging_redacted(receipt_dir)

    def test_signalled_test_process_remains_a_failure_without_printing_child_secret(self):
        result, _receipt_dir = self.run_wrapper("signal")

        self.assertEqual(result.returncode, 143)
        self.assertNotIn(self.SENTINEL, result.stdout)
        self.assert_staging_redacted(_receipt_dir)

    def test_deadline_kills_the_test_process_and_keeps_the_proof_failed(self):
        result, _receipt_dir = self.run_wrapper("timeout", timeout_seconds=8)

        self.assertEqual(result.returncode, 124)
        self.assertIn("bounded child timed out", result.stdout)
        self.assertNotIn(self.SENTINEL, result.stdout)
        self.assert_staging_redacted(_receipt_dir)

    def test_browser_failure_preserves_its_status_and_never_stages_stale_output(self):
        result, receipt_dir = self.run_wrapper("browser-failure", stale_receipt=True)

        self.assertEqual(result.returncode, 41)
        self.assertNotIn(self.SENTINEL, result.stdout)
        self.assertFalse((receipt_dir / "locked-lockspire.json").exists())
        self.assert_staging_redacted(receipt_dir)

    def test_validator_failure_preserves_its_status_and_never_stages_raw_receipt(self):
        result, receipt_dir = self.run_wrapper("validator-failure")

        self.assertEqual(result.returncode, 43)
        self.assertNotIn(self.SENTINEL, result.stdout)
        self.assertFalse((receipt_dir / "locked-lockspire.json").exists())
        self.assert_staging_redacted(receipt_dir)

    def test_signalling_wrapper_stops_owned_child_drops_database_and_removes_logs(self):
        for sig in (signal.SIGTERM, signal.SIGINT):
            with self.subTest(signal=sig):
                result, receipt_dir = self.run_wrapper("wrapper-signal", interrupt=sig)
                self.assertEqual(result.returncode, 128 + sig)
                self.assertNotIn(self.SENTINEL, result.stdout)
                self.assert_staging_redacted(receipt_dir)

    def test_database_cleanup_failure_turns_success_into_failure(self):
        for stage in ("drop-failure", "drop-timeout", "shared-drop-failure"):
            with self.subTest(stage=stage):
                started = time.monotonic()
                result, receipt_dir = self.run_wrapper(stage)
                self.assertLess(time.monotonic() - started, 15)
                self.assertEqual(result.returncode, 37 if stage == "shared-drop-failure" else 1)
                self.assertNotIn(self.SENTINEL, result.stdout)
                self.assert_staging_redacted(receipt_dir)

    def test_successful_validated_staging_contains_no_fake_child_secrets(self):
        result, receipt_dir = self.run_wrapper("success", nested=True)

        self.assertTrue(receipt_dir.is_dir())
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(len(list(receipt_dir.glob("locked-*.json"))), 3)
        self.assert_staging_redacted(receipt_dir)


if __name__ == "__main__":
    unittest.main()
