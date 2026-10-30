"""Offline guard/custody tests: no Mix command or database connection is run."""

from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "ci"))
import run_owned_source_tests as guard  # noqa: E402


class FakeProcesses:
    """A stateful fake catalog proves ordering and ownership, not real SQL behavior."""

    def __init__(self):
        self.owner = None
        self.calls = []
        self.exists = False
        self.oid = 12345
        self.preflight_override = {}
        self.existing = False
        self.create_output = guard.CREATED + b"\n"
        self.failure_stage = None
        self.raw = b"unregistered-child-secret-and-exception-map"
        self.test_output = b"9 tests, 0 failures\n"
        self.ci_output = b"15 tests, 0 failures\n2 properties, 2138 tests, 0 failures\n270 tests, 0 failures\n"
        self.change_after_migrate = None
        self.change_after_test = None
        self.identity_override = {}
        self.mutate_child_env = False

    def __call__(self, command, *, env, cwd, timeout, started):
        owner = self.owner
        stage = owner.manifest["commands"][-1]["stage"]
        self.calls.append((stage, command, dict(env)))
        # The manifest must already exist before the first possible mutation.
        durable = json.loads(owner.manifest_path.read_text())
        if stage == "create":
            assert durable["state"] == "create_intent"
        if stage == "drop":
            assert durable["state"] == "drop_intent" and durable["owned_oid"] == self.oid
        started(9000 + len(self.calls))
        if self.mutate_child_env:
            env["MIX_ENV"] = "dev"
            env["LOCKSPIRE_TEST_DB_NAME"] = "lockspire_dev"
        if stage == "source":
            return guard.Result(0, b"a" * 40 + b"\n" if command[1] == "rev-parse" else b"")
        if stage == "preflight":
            payload = {
                "env": "test", "repo": guard.REPO, "ecto_repos": [guard.REPO],
                "database": owner.target.database, "hostname": owner.target.hostname,
                "port": owner.target.port, "credentials_match": True,
            }
            payload.update(self.preflight_override)
            return guard.Result(0, (guard.MARKER + json.dumps(payload) + "\n").encode())
        if stage == "catalog":
            return guard.Result(0, str(self.oid).encode() + b"\n" if self.exists or self.existing else b"")
        if stage == "identity":
            payload = {
                "database": owner.target.database, "oid": self.oid,
                "server_address": "127.0.0.1", "server_port": owner.target.port,
            }
            payload.update(self.identity_override)
            return guard.Result(0, json.dumps(payload).encode())
        if stage == "create":
            self.exists = True
            return guard.Result(0, self.create_output)
        if stage == "migrate":
            if self.change_after_migrate:
                self.change_after_migrate(self)
        if stage == "drop":
            self.exists = False
        if stage == self.failure_stage:
            return guard.Result(2, self.raw, self.raw)
        if stage == "test":
            if self.change_after_test:
                self.change_after_test(self)
            return guard.Result(0, self.test_output)
        if stage == "ci":
            return guard.Result(0, self.ci_output)
        return guard.Result(0)


class OwnedSourceGuardTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.root = Path(self.directory.name)
        (self.root / "test" / "integration").mkdir(parents=True)
        (self.root / "test" / "integration" / "owned_test.exs").write_text("# offline fixture\n")
        self.runners = []

    def tearDown(self):
        for runner in self.runners:
            shutil.rmtree(runner.directory)
        self.directory.cleanup()

    def runner(self, fake=None, *, ci=False, inherited=None):
        fake = fake or FakeProcesses()
        runner = guard.OwnedSourceTests(
            [] if ci else ["test/integration/owned_test.exs"], root=self.root,
            include_integration=not ci, ci=ci, process_runner=fake,
            inherited={} if inherited is None else inherited,
        )
        fake.owner = runner
        self.runners.append(runner)
        return runner, fake

    def test_every_command_has_forced_same_test_environment_and_explicit_ecto_repo(self):
        runner, fake = self.runner(inherited={
            "MIX_ENV": "dev", "MIX_EXS": "/unowned/mix.exs", "DATABASE_URL": "secret-url",
            "LOCKSPIRE_TEST_DB_NAME": "lockspire_test", "LOCKSPIRE_DB_NAME": "lockspire_dev",
            "PGDATABASE": "shared", "PGOPTIONS": "-c dangerous", "PGSERVICE": "remote",
            "PGSERVICEFILE": "private", "PGHOSTADDR": "198.51.100.2",
            "LOCKSPIRE_TEST_DB_HOST": "localhost", "LOCKSPIRE_TEST_DB_PASSWORD": "",
            "PGPASSWORD": "fallback-must-not-win",
        })
        fake.mutate_child_env = True
        self.assertEqual(runner.run(), 0)
        self.assertRegex(runner.target.database, guard.DB_PATTERN)
        self.assertLessEqual(len(runner.target.database), 63)
        for stage, command, env in fake.calls:
            self.assertEqual(env["MIX_ENV"], "test")
            self.assertEqual(env["LOCKSPIRE_TEST_DB_NAME"], runner.target.database)
            self.assertEqual(env["LOCKSPIRE_DB_NAME"], runner.target.database)
            self.assertEqual(env["PGDATABASE"], runner.target.database)
            self.assertEqual(env["PGPASSWORD"], "")
            self.assertEqual(env["PGHOST"], "127.0.0.1")
            for removed in ("PGSERVICE", "PGSERVICEFILE", "PGHOSTADDR", "DATABASE_URL", "MIX_EXS"):
                self.assertNotIn(removed, env)
            if stage in {"catalog", "identity"}:
                self.assertEqual(env["PGOPTIONS"], "-c default_transaction_read_only=on")
            else:
                self.assertNotIn("PGOPTIONS", env)
            if stage in {"create", "migrate", "drop"}:
                self.assertEqual(command, ("mix", "ecto." + stage, "-r", guard.REPO))
                self.assertNotIn("--force", command)
                self.assertNotIn("--force-drop", command)
        self.assertEqual(runner.manifest["source_sha"], "a" * 40)
        self.assertTrue(runner.manifest["checkout_clean_before"])
        self.assertEqual(runner.manifest["cleanup"], "independently_absent")
        stages = [stage for stage, _, _ in fake.calls]
        for index, stage in enumerate(stages):
            if stage == "create":
                self.assertEqual(stages[index - 2:index], ["preflight", "catalog"])
            elif stage in {"migrate", "test", "drop"}:
                self.assertEqual(stages[index - 3:index], ["preflight", "catalog", "identity"])
        self.assertEqual(stat.S_IMODE(runner.directory.stat().st_mode), 0o700)
        self.assertEqual(stat.S_IMODE(runner.manifest_path.stat().st_mode), 0o600)

    def test_rejects_dev_shared_repo_host_port_and_credential_mismatches_before_create(self):
        for mismatch in (
            {"env": "dev"}, {"database": "lockspire_dev"}, {"database": "lockspire_test"},
            {"repo": "Other.Repo"}, {"ecto_repos": [guard.REPO, "Other.Repo"]},
            {"hostname": "remote"}, {"port": 5433}, {"port": True},
            {"credentials_match": False}, {"credentials_match": 1},
        ):
            with self.subTest(fields=list(mismatch)):
                runner, fake = self.runner()
                fake.preflight_override = mismatch
                self.assertEqual(runner.run(), 1)
                self.assertFalse(any(stage in {"create", "migrate", "test", "drop"} for stage, _, _ in fake.calls))

    def test_existing_database_is_never_created_or_cleaned(self):
        runner, fake = self.runner()
        fake.existing = True
        self.assertEqual(runner.run(), 1)
        self.assertEqual(runner.manifest["failure"]["reason"], "database_already_exists")
        self.assertFalse(any(stage in {"create", "drop"} for stage, _, _ in fake.calls))

    def test_exit_zero_without_exact_new_create_witness_does_not_authorize_drop(self):
        for output in (guard.ALREADY_CREATED + b"\n", b"", guard.CREATED + b"\n" + guard.ALREADY_CREATED):
            runner, fake = self.runner()
            fake.create_output = output
            self.assertEqual(runner.run(), 1)
            self.assertTrue(fake.exists)
            self.assertIsNone(runner.owned_oid)
            self.assertFalse(any(stage in {"migrate", "test", "drop"} for stage, _, _ in fake.calls))

    def test_test_failure_cleans_only_proven_owned_database_and_withholds_raw_output(self):
        runner, fake = self.runner()
        fake.failure_stage = "test"
        with redirect_stdout(io.StringIO()) as visible:
            self.assertEqual(runner.run(), 1)
        self.assertEqual(visible.getvalue(), "")
        self.assertFalse(fake.exists)
        self.assertEqual(runner.manifest["cleanup"], "independently_absent")
        manifest_bytes = runner.manifest_path.read_bytes()
        self.assertTrue(fake.raw not in manifest_bytes)
        entry = next(row for row in runner.manifest["commands"] if row["stage"] == "test")
        self.assertEqual(entry["stdout_bytes"], len(fake.raw))
        self.assertEqual(len(entry["stdout_sha256"]), 64)

    def test_config_is_revalidated_before_test_and_cleanup_refuses_changed_config(self):
        runner, fake = self.runner()
        fake.change_after_migrate = lambda state: state.preflight_override.update(database="lockspire_dev")
        self.assertEqual(runner.run(), 1)
        self.assertTrue(fake.exists)
        self.assertFalse(any(stage in {"test", "drop"} for stage, _, _ in fake.calls))
        self.assertEqual(runner.manifest["cleanup"], "refused_or_unconfirmed")

    def test_connected_identity_is_checked_before_migrate_and_oid_change_refuses_cleanup(self):
        runner, fake = self.runner()
        fake.identity_override = {"database": "lockspire_dev"}
        self.assertEqual(runner.run(), 1)
        self.assertFalse(any(stage in {"migrate", "test", "drop"} for stage, _, _ in fake.calls))
        runner, fake = self.runner()
        fake.change_after_migrate = lambda state: setattr(state, "oid", 54321)
        self.assertEqual(runner.run(), 1)
        self.assertFalse(any(stage in {"test", "drop"} for stage, _, _ in fake.calls))

    def test_connected_server_must_be_loopback_and_expected_port(self):
        for override in ({"server_address": "198.51.100.1"}, {"server_port": 9999}):
            runner, fake = self.runner()
            fake.identity_override = override
            self.assertEqual(runner.run(), 1)
            self.assertFalse(any(stage in {"migrate", "test", "drop"} for stage, _, _ in fake.calls))

    def test_drop_revalidates_connected_identity_after_tests(self):
        runner, fake = self.runner()
        fake.change_after_test = lambda state: state.identity_override.update(oid=54321)
        self.assertEqual(runner.run(), 1)
        self.assertTrue(fake.exists)
        self.assertFalse(any(stage == "drop" for stage, _, _ in fake.calls))
        self.assertEqual(runner.manifest["cleanup"], "refused_or_unconfirmed")

    def test_canonical_ci_is_fixed_and_has_per_suite_nonzero_counts(self):
        runner, fake = self.runner(ci=True)
        self.assertEqual(runner.run(), 0)
        commands = [command for stage, command, _ in fake.calls if stage == "ci"]
        self.assertEqual(commands, [("mix", "ci")])
        entry = next(row for row in runner.manifest["commands"] if row["stage"] == "ci")
        self.assertEqual([row["tests"] for row in entry["exunit_counts"]], [15, 2138, 270])
        self.assertEqual(entry["exunit_counts"][1]["properties"], 2)
        runner, fake = self.runner(ci=True)
        fake.ci_output = b"0 tests, 0 failures\n"
        self.assertEqual(runner.run(), 1)
        self.assertEqual(runner.manifest["failure"]["reason"], "nonzero_test_evidence_missing")
        self.assertEqual(runner.manifest["cleanup"], "independently_absent")

    def test_cli_rejects_arbitrary_tasks_targets_options_and_mixed_ci_before_execution(self):
        for arguments in (
            ["--database", "lockspire_dev"], ["ecto.drop"], ["--ci", "test/a_test.exs"],
            ["--ci", "--include", "integration"], ["--include", "all"], ["../outside_test.exs"],
        ):
            with patch.object(guard, "PrivateProcessRunner") as process:
                with redirect_stdout(io.StringIO()) as visible:
                    self.assertEqual(guard.main(arguments), 1)
                process.assert_not_called()
                self.assertEqual(json.loads(visible.getvalue())["status"], "failed")

    def test_remote_inherited_host_is_rejected_without_child(self):
        with self.assertRaises(guard.GuardFailure):
            self.runner(inherited={"PGHOST": "db.example.test"})

    def test_timeout_exception_diagnostics_never_escape_and_uncertain_create_is_not_dropped(self):
        runner, fake = self.runner()
        original = fake.__call__

        def timed_out(command, **kwargs):
            if runner.manifest["commands"][-1]["stage"] == "create":
                raise subprocess.TimeoutExpired(["secret-command"], 1, output=fake.raw, stderr=fake.raw)
            return original(command, **kwargs)

        runner.process_runner = timed_out
        self.assertEqual(runner.run(), 1)
        self.assertTrue(fake.raw not in runner.manifest_path.read_bytes())
        self.assertFalse(any(stage == "drop" for stage, _, _ in fake.calls))
        self.assertEqual(runner.manifest["failure"], {"stage": "create", "reason": "timeout"})

    def test_real_child_generated_unknown_output_stays_private(self):
        runner, _fake = self.runner()
        runner.process_runner = guard.PrivateProcessRunner()
        expression = (
            "import secrets,sys; token='PRIVATE_CHILD_'+secrets.token_hex(24); "
            "print(token); print({'nested':token},file=sys.stderr); "
            "raise RuntimeError({'secret':token})"
        )
        with redirect_stdout(io.StringIO()) as visible:
            result = runner._invoke("test", [sys.executable, "-c", expression], timeout=10)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(result.stdout.startswith(b"PRIVATE_CHILD_"))
        self.assertEqual(visible.getvalue(), "")
        self.assertTrue(b"PRIVATE_CHILD_" not in runner.manifest_path.read_bytes())
        self.assertTrue(result.process_group_stopped)

    def test_real_source_child_has_owned_authority_before_started_callback(self):
        observed = {}
        owner_module = sys.modules[guard.stop_process_group.__module__]

        def started(pid):
            observed["pid"] = pid
            observed["registered"] = pid in owner_module._OWNED_IDENTITIES

        result = guard.PrivateProcessRunner()(
            [sys.executable, "-c", "pass"], env=os.environ, cwd=self.root,
            timeout=10, started=started,
        )
        self.assertTrue(observed.get("registered") is True,
                        "source child launch bypassed owned session authority")
        self.assertTrue(result.returncode == 0 and result.process_group_stopped,
                        "source child cleanup was not independently confirmed")
        self.assertTrue(observed["pid"] not in owner_module._OWNED_IDENTITIES,
                        "source child authority remained after confirmed cleanup")

    def test_unconfirmed_worker_cleanup_prevents_database_drop(self):
        runner, fake = self.runner()
        original = fake.__call__

        def unconfirmed(command, **kwargs):
            if runner.manifest["commands"][-1]["stage"] == "test":
                kwargs["started"](9001)
                raise guard.ProcessFailure("timeout", False)
            return original(command, **kwargs)

        runner.process_runner = unconfirmed
        self.assertEqual(runner.run(), 1)
        self.assertTrue(fake.exists)
        self.assertFalse(any(stage == "drop" for stage, _, _ in fake.calls))
        self.assertEqual(runner.manifest["cleanup"], "refused_or_unconfirmed")


if __name__ == "__main__":
    unittest.main()
