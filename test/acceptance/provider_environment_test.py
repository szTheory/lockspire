"""Standalone provider consumers retain preparation's selected environment.

The prepared host and external Mix/HTTP processes are controlled fixtures.
The real standalone consumer and discovery control flow runs unchanged.
"""
from __future__ import annotations

import base64
from contextlib import ExitStack, redirect_stderr
from io import StringIO
import os
import shutil
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts/acceptance/clean_room"))
import build_provider as provider  # noqa: E402
sys.path.insert(0, str(ROOT / "scripts/acceptance"))
import clean_room_saas_journey as journey  # noqa: E402

SELECTED = ("MIX_DEPS_PATH", "MIX_BUILD_PATH", "HEX_HOME", "MIX_HOME", "MIX_ENV")


class ProviderEnvironmentContracts(unittest.TestCase):
    def setUp(self):
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        self.stack.enter_context(patch.dict(os.environ, {
            "MIX_ENV": "test", "CLEAN_ROOM_DB_HOST": "127.0.0.1",
            "CLEAN_ROOM_DB_PORT": "64853",
            "LOCKSPIRE_KEY_ENCRYPTION_KEY": "controlled-parent-key",
            "HEX_HOME": "/unselected/parent-hex", "MIX_HOME": "/unselected/parent-mix",
        }, clear=True))
        self.expected = {}
        self.observed = []

    def prepared_host(self, run_root, _database_url, **options):
        """A host already provisioned under the producer's existing selection contract."""
        child = run_root / "provider_host"
        child.mkdir()
        cache = provider.proof_pair_cache_root(options.get("cache_root") or run_root / "deps-cache", "locked")
        selected = provider.locked_environment(child, "provider_host", cache)
        self.expected = {name: selected.get(name) for name in SELECTED}
        for name, directory in (("HEX_HOME", "hex-home"), ("MIX_HOME", "mix-home")):
            path = run_root / directory
            path.mkdir(mode=0o700)
            self.expected[name] = str(path)
        return child

    def observe_environment(self, environment):
        self.observed.append({name: environment.get(name) for name in SELECTED})

    def assert_selected_environment(self):
        self.assertGreater(len(self.observed), 0)
        for observed in self.observed:
            for name in SELECTED:
                self.assertEqual(observed[name], self.expected[name], name)

    def test_self_test_retains_prepared_cache_and_homes_for_every_child_command(self):
        commands = []

        def command(_child, environment, *arguments):
            self.observe_environment(environment)
            commands.append(arguments)

        def discovery(_child, environment, _issuer):
            self.observe_environment(environment)

        with patch.object(provider, "prepare_provider", side_effect=self.prepared_host), \
             patch.object(provider, "allocate_port", return_value=49111), \
             patch.object(provider, "run_child_command", side_effect=command), \
             patch.object(provider, "assert_live_discovery", side_effect=discovery):
            provider.self_test()

        self.assert_selected_environment()
        self.assertEqual(commands[0], ("ecto.create",))
        self.assertEqual(commands[-1], ("ecto.drop",))
        self.assertIn(("ecto.migrate", "--migrations-path", "priv/repo/migrations"), commands)

    def test_cold_key_check_retains_prepared_cache_and_homes_but_removes_parent_key(self):
        commands = []
        cold_key_present = []
        key = base64.b64encode(bytes(range(32))).decode("ascii")

        def command(_child, environment, *_arguments):
            self.observe_environment(environment)

        def jose(_child, environment):
            self.observe_environment(environment)

        def mix(arguments, **options):
            environment = options["env"]
            self.observe_environment(environment)
            cold_key_present.append("LOCKSPIRE_KEY_ENCRYPTION_KEY" in environment)
            commands.append(tuple(arguments[1:]))
            if arguments[1:] == ("lockspire.gen.kek", "--raw"):
                return subprocess.CompletedProcess(arguments, 0, key + "\n", "")
            if arguments[1:] == ("lockspire.gen.kek",):
                return subprocess.CompletedProcess(arguments, 0,
                    "LOCKSPIRE_KEY_ENCRYPTION_KEY=" + key + "\nif config_env() == :prod\n", "")
            self.assertEqual(arguments[1:], ("app.config",))
            return subprocess.CompletedProcess(arguments, 1, "", "LOCKSPIRE_KEY_ENCRYPTION_KEY is missing")

        with patch.object(provider, "prepare_provider", side_effect=self.prepared_host), \
             patch.object(provider, "patch_jose_record_extractors", side_effect=jose), \
             patch.object(provider, "run_child_command", side_effect=command), \
             patch.object(provider, "bounded_run", side_effect=mix):
            provider.check_gen_kek()

        self.assert_selected_environment()
        self.assertEqual(commands, [("lockspire.gen.kek", "--raw"), ("lockspire.gen.kek",), ("app.config",)])
        self.assertEqual(cold_key_present, [False, False, False])

    def discovery_fixture(self, *, exited=False):
        observation = {"owned_cleanup": False}

        class Process:
            def poll(self):
                return 1 if exited else None

            def terminate(self):
                pass

            def wait(self, timeout):
                return 0

        process = Process()

        def start(_command, **options):
            observation["http_flag"] = options["env"].get("CLEAN_ROOM_HTTP_SERVER")
            observation["isolated_session"] = options.get("start_new_session", False)
            return process

        def stop(actual):
            self.assertIs(actual, process)
            observation["owned_cleanup"] = True
            return True

        issuer = "http://127.0.0.1:49111/lockspire"

        class Response:
            status = 200

            def __enter__(self):
                return self

            def __exit__(self, *_arguments):
                return False

            def read(self):
                return issuer.encode("ascii")

        self.stack.enter_context(patch.object(provider.subprocess, "Popen", side_effect=start))
        # create=True lets the pre-fix test reach its existing wrong HTTP flag,
        # rather than failing because the owned factory is not imported yet.
        self.stack.enter_context(patch.object(provider, "start_owned_session", side_effect=start, create=True))
        self.stack.enter_context(patch.object(provider, "stop_process_group", side_effect=stop, create=True))
        self.stack.enter_context(patch.object(provider.urllib.request, "urlopen", return_value=Response()))
        return observation, issuer

    def test_live_discovery_enables_http_only_for_its_owned_child(self):
        observed, issuer = self.discovery_fixture()
        environment = {"MIX_ENV": "test", "CLEAN_ROOM_HTTP_SERVER": "false"}
        provider.assert_live_discovery(Path("/controlled/provider"), environment, issuer)
        self.assertEqual(observed["http_flag"], "true")
        self.assertEqual(environment["CLEAN_ROOM_HTTP_SERVER"], "false")
        self.assertTrue(observed["isolated_session"])
        self.assertTrue(observed["owned_cleanup"])

    def test_live_discovery_stops_its_owned_child_when_the_provider_exits(self):
        observed, issuer = self.discovery_fixture(exited=True)
        with self.assertRaises(provider.PackageInputError):
            provider.assert_live_discovery(Path("/controlled/provider"), {"MIX_ENV": "test"}, issuer)
        self.assertEqual(observed["http_flag"], "true")
        self.assertTrue(observed["owned_cleanup"])

    def test_saas_consumer_retains_prepared_cache_and_homes_before_sql(self):
        class EnvironmentObserved(Exception):
            pass

        cache = Path(self.stack.enter_context(tempfile.TemporaryDirectory(
            prefix="lockspire178-provider-cache-")))
        self.stack.enter_context(patch.dict(os.environ, {"CLEAN_ROOM_CACHE_ROOT": str(cache)}))
        source = "a" * 40

        def package(run_root, _source):
            payload = run_root / "package"
            payload.mkdir()
            identity = SimpleNamespace(source_revision=source, kind="checkout", version="1.6.1",
                                       archive_sha256="b" * 64, tree_sha256="c" * 64)
            return payload, (), identity

        def observe(_child, environment, *_arguments):
            self.observe_environment(environment)
            raise EnvironmentObserved

        with patch.object(journey, "probe_environment"), \
             patch.object(journey, "configure_origins", return_value=(49111, 49112)), \
             patch.object(journey, "prepare_package", side_effect=package), \
             patch.object(journey, "prepare_provider", side_effect=self.prepared_host), \
             patch.object(journey, "run_child_command", side_effect=observe), \
             patch.object(journey, "drop_child_database"), \
             patch.object(journey.subprocess, "check_output", return_value=source + "\n"), \
             patch.object(journey.signal, "signal"), \
             patch.object(journey, "ACTIVE_REDACTOR", None):
            with self.assertRaises(EnvironmentObserved):
                journey.main(["--only", "boundary"])

        self.assert_selected_environment()

    def test_saas_live_boot_enables_http_without_mutating_its_caller(self):
        observed = []
        process = object()

        def start(_command, **options):
            observed.append(options["env"].get("CLEAN_ROOM_HTTP_SERVER"))
            return process

        environment = {"MIX_ENV": "test", "CLEAN_ROOM_HTTP_SERVER": "false"}
        with patch.object(journey, "start_owned_session", side_effect=start):
            actual = journey.start_process(Path("/controlled/provider"), environment, Path("/controlled/log"))
        self.assertIs(actual, process)
        self.assertEqual(observed, ["true"])
        self.assertEqual(environment["CLEAN_ROOM_HTTP_SERVER"], "false")

    def test_failed_mix_command_reports_a_fixed_stage_without_child_output_or_arguments(self):
        cases = [
            (("ecto.create",), "database_create"),
            (("ecto.migrate", "--migrations-path", "priv/repo/migrations"), "database_migrate"),
            (("compile", "--warnings-as-errors"), "compile"),
            (("lockspire.verify",), "verify"),
            (("ecto.drop",), "database_drop"),
            (("unregistered-argument",), "other"),
        ]
        for command, expected in cases:
            result = subprocess.CompletedProcess(command, 1, b"opaque-child-output", b"")
            with patch.object(provider, "bounded_run", return_value=result):
                with self.assertRaises(provider.PackageInputError) as caught:
                    provider._run_mix(Path("/controlled/provider"), {}, command)
            message = str(caught.exception)
            self.assertIn("command_stage=" + expected, message)
            self.assertNotIn("opaque-child-output", message)
            self.assertNotIn("unregistered-argument", message)

    def test_compile_failure_reports_only_byte_matched_tracked_source_locations(self):
        source = "test/clean_room/provider_host/lib/clean_room_provider/bootstrap.ex"
        with tempfile.TemporaryDirectory(prefix="lockspire178-compile-location-") as temporary:
            child = Path(temporary)
            target = child / "lib/clean_room_provider/bootstrap.ex"
            target.parent.mkdir(parents=True)
            target.write_bytes((ROOT / source).read_bytes())

            def run(command, **_options):
                if command[0] == "git":
                    return subprocess.CompletedProcess(command, 0, source.encode() + b"\0", b"")
                output = (b"opaque-private-warning\nlib/clean_room_provider/bootstrap.ex:12: ignored\n"
                          b"lib/unregistered-private-source.ex:1: ignored\n")
                return subprocess.CompletedProcess(command, 1, output, b"")

            with patch.object(provider, "bounded_run", side_effect=run):
                with self.assertRaises(provider.PackageInputError) as caught:
                    provider._run_mix(child, {}, ("compile", "--warnings-as-errors"))
            message = str(caught.exception)
            self.assertIn("source_location=" + source + ":12", message)
            self.assertNotIn("opaque-private-warning", message)
            self.assertNotIn("unregistered-private-source", message)

    def test_preparation_compiles_only_the_selected_verifier_host_fixtures(self):
        for groups in (frozenset(), frozenset({"recovery"})):
            with tempfile.TemporaryDirectory(prefix="lockspire178-provider-selection-") as temporary:
                root = Path(temporary)
                package = root / "package"
                package.mkdir()
                (package / "mix.exs").write_text("controlled package\n")
                child = root / "provider_host"
                compiled = []

                def copy(_role, _root, _package):
                    shutil.copytree(provider.PROVIDER_TEMPLATE, child)
                    shutil.copytree(package, child / "vendor/lockspire")
                    return child

                def compile_host(_command, **_options):
                    host = child / "lib/clean_room_provider"
                    compiled.append((
                        (host / "verifier_disclosure.ex").is_file(),
                        (host / "verifier_recovery.ex").is_file(),
                        (host / "verifier_transactions.ex").is_file(),
                    ))

                with patch.object(provider, "probe_environment"), \
                     patch.object(provider, "copy_child_template", side_effect=copy), \
                     patch.object(provider, "verify_candidate_host"), \
                     patch.object(provider, "verify_child", return_value=child / "vendor/lockspire"), \
                     patch.object(provider, "patch_jose_record_extractors"), \
                     patch.object(provider, "bounded_run", return_value=subprocess.CompletedProcess((), 0, b"", b"")), \
                     patch.object(provider, "run", side_effect=compile_host), \
                     patch.object(provider, "bind_compiled_candidate"):
                    actual = provider.prepare_provider(root, "controlled-database", package_root=package,
                        candidate_identity=object(), scenario_groups=groups)

                self.assertEqual(actual, child)
                self.assertIsInstance(actual, Path)
                self.assertEqual(compiled, [(False, "recovery" in groups, False)])
                required = child / "lib/clean_room_provider_web/controllers/billing_controller.ex"
                content = required.read_bytes()
                required.unlink()
                with self.assertRaises((OSError, provider.PackageInputError)):
                    provider.audit_boundary(child, package, scenario_groups=groups)
                required.write_bytes(content)
                if groups:
                    (child / "lib/clean_room_provider/verifier_recovery.ex").unlink()
                    with self.assertRaises((OSError, provider.PackageInputError)):
                        provider.audit_boundary(child, package, scenario_groups=groups)

    def test_builder_cli_reports_only_fixed_family_and_known_source_for_unexpected_errors(self):
        output = StringIO()
        code = None
        with patch.object(provider, "self_test", side_effect=OSError("opaque-private-error")), \
             redirect_stderr(output):
            try:
                code = provider.main(["--self-test"])
            except OSError:
                pass
        self.assertEqual(code, 1)
        self.assertIn("family=OSError", output.getvalue())
        self.assertIn("source_location=scripts/acceptance/clean_room/build_provider.py:", output.getvalue())
        self.assertNotIn("opaque-private-error", output.getvalue())
        self.assertNotIn("Traceback", output.getvalue())


if __name__ == "__main__":
    unittest.main()
