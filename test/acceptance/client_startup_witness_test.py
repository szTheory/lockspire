"""Actual generated startup producer through the owned listener/reader seam.

Only child command/HTTP/runtime getter are controlled external boundaries. The
exact generated startup block and its context projection run in an owned Elixir
VM; stdout/stderr always remain DEVNULL.
"""
from __future__ import annotations
import ast
import base64
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts/acceptance/clean_room"))
sys.path.insert(0, str(ROOT / "scripts/acceptance"))
import package_input
import verifier_rollout
import verifier_recovery
import startup_witness
RUNTIME_FAILURES = []
RUNTIME_CUSTODY = []


def application_source():
    tree = ast.parse((ROOT / "scripts/acceptance/clean_room/build_provider.py").read_text())
    for node in ast.walk(tree):
        if (isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
                and node.func.attr == "write_text" and "application.ex" in ast.unparse(node.func.value)):
            return ast.literal_eval(node.args[0])
    raise RuntimeError("generated_application_source_missing")


class StartupWitnessContracts(unittest.TestCase):
    def cleanup_runtime(self, process, identity):
        if package_input.owned_session_state(identity) != "absent":
            package_input.stop_process_group(process)
        self.assertTrue(package_input.owned_session_state(identity) == "absent", "controlled runtime session cleanup unconfirmed")

    def launch(self, root, has_new=False, unknown_output=None):
        ready = root / "runtime-ready"
        # The controlled runtime boundary has no Repo, endpoint or SQL. It runs
        # the exact generated application with minimal supervised host services.
        application = application_source()
        first = application.index('      if System.get_env("LOCKSPIRE_RECOVERY_CONTEXT_WITNESS")')
        last = application.index('      {:ok, supervisor}', first)
        producer = application[first:last]
        program = '''
defmodule Lockspire.Config do
  def client_secret_verifier_context(), do: %{state: :valid, keys: Map.get(%{"true" => %{"verifier-new" => :fixture}}, System.get_env("FIXTURE_HAS_NEW"), %{})}
end
''' + producer + '''
IO.puts(System.get_env("FIXTURE_UNKNOWN_OUTPUT", ""))
IO.warn(System.get_env("FIXTURE_UNKNOWN_OUTPUT", ""))
File.write!(System.fetch_env!("FIXTURE_READY"), "ready", [:exclusive])
Process.sleep(:infinity)
'''
        failure_path = root / "runtime-failure"
        wrapper = '''
try do
  Code.eval_string(Base.decode64!(System.fetch_env!("FIXTURE_PROGRAM")))
rescue
  error ->
    family = case error.__struct__ do
      SyntaxError -> "SyntaxError"
      CompileError -> "CompileError"
      MatchError -> "MatchError"
      ArgumentError -> "ArgumentError"
      RuntimeError -> "RuntimeError"
      UndefinedFunctionError -> "UndefinedFunctionError"
      FunctionClauseError -> "FunctionClauseError"
      KeyError -> "KeyError"
      ErlangError -> "ErlangError"
      System.EnvError -> "EnvError"
      TokenMissingError -> "TokenMissingError"
      BadMapError -> "BadMapError"
      Protocol.UndefinedError -> "ProtocolError"
      _ -> "other"
    end
    line = Map.get(error, :line, 0)
    File.write!(System.fetch_env!("FIXTURE_FAILURE"), family <> ":" <> to_string(line), [:exclusive])
    File.chmod!(System.fetch_env!("FIXTURE_FAILURE"), 0o600)
end
'''
        def start(_command, **kwargs):
            self.assertTrue(kwargs["stdout"] == subprocess.DEVNULL and kwargs["stderr"] == subprocess.DEVNULL,
                            "raw runtime output transport changed")
            kwargs["env"] = dict(kwargs["env"], FIXTURE_PROGRAM=base64.b64encode(program.encode()).decode(), FIXTURE_FAILURE=str(failure_path))
            ledger = root / "custody.json"
            ledger.write_text(json.dumps({"mode": "controlled-startup-only", "parent_pid": os.getpid()}))
            ledger.chmod(0o600)
            process = package_input.start_owned_session(("elixir", "-e", wrapper), **kwargs)
            identity = package_input._OWNED_IDENTITIES[process.pid]
            RUNTIME_CUSTODY.append(identity)
            ledger.write_text(json.dumps(identity.safe_record()))
            self.addCleanup(self.cleanup_runtime, process, identity)
            return process
        class Response:
            status = 200
            def __enter__(self): return self
            def __exit__(self, *_): return None
        def http_ready(*_args, **_kwargs):
            if not ready.exists(): raise OSError("controlled_runtime_not_ready")
            return Response()
        env = dict(os.environ, LOCKSPIRE_RECOVERY_CONTEXT_WITNESS="true", FIXTURE_READY=str(ready),
                   FIXTURE_HAS_NEW="true" if has_new else "false")
        if unknown_output is not None:
            env["FIXTURE_UNKNOWN_OUTPUT"] = unknown_output
        try:
            with patch.object(verifier_rollout, "start_owned_session", side_effect=start), \
                 patch.object(verifier_rollout.urllib.request, "urlopen", side_effect=http_ready):
                return verifier_rollout._start_server(root, env, root / "startup-witness", "http://127.0.0.1:1")
        finally:
            if failure_path.exists():
                family, _, line = failure_path.read_text().partition(":")
                RUNTIME_FAILURES.append(family if family in {"SyntaxError", "CompileError", "MatchError", "ArgumentError", "RuntimeError", "UndefinedFunctionError", "FunctionClauseError", "KeyError", "ErlangError", "EnvError", "TokenMissingError", "BadMapError", "ProtocolError"} else "other")
                if line.isdecimal():
                    RUNTIME_FAILURES.append(int(line))

    def test_actual_startup_producer_reaches_reader_without_raw_log(self):
        with tempfile.TemporaryDirectory(prefix="lockspire-startup-witness-") as temporary:
            root = Path(temporary)
            process = None
            accepted = False
            try:
                process, _ = self.launch(root)
                try:
                    accepted = verifier_recovery._read_startup_context(root / "startup-witness") == (True, False)
                except package_input.PackageInputError:
                    accepted = False
                self.assertTrue(accepted, "actual startup witness transport did not reach its reader")
            finally:
                if process is not None:
                    verifier_rollout._stop_owned_server(process)

    def test_actual_producer_restored_key_and_output_privacy(self):
        with tempfile.TemporaryDirectory(prefix="lockspire-startup-witness-") as temporary:
            root = Path(temporary)
            marker = os.urandom(24).hex()
            encoded = base64.b64encode(marker.encode()).decode()
            process = None
            try:
                process, _ = self.launch(root, has_new=True, unknown_output=marker + encoded)
                channel = process._lockspire_startup_witness
                self.assertTrue(channel.directory.stat().st_mode & 0o777 == 0o700, "witness directory permissions differ")
                self.assertTrue(channel.payload.stat().st_mode & 0o777 == 0o600, "witness payload permissions differ")
                safe = all(marker.encode() not in path.read_bytes() and encoded.encode() not in path.read_bytes()
                           for path in root.rglob("*") if path.is_file())
                self.assertTrue(safe, "unknown runtime output reached durable witness storage")
                self.assertTrue(not (root / "startup-witness").exists(), "legacy raw log path was created")
                self.assertTrue(verifier_recovery._read_startup_context(root / "startup-witness") == (True, True),
                                "restored startup context differs")
                with self.assertRaises(package_input.PackageInputError):
                    verifier_recovery._read_startup_context(root / "startup-witness")
            finally:
                if process is not None:
                    verifier_rollout._stop_owned_server(process)

    def test_closed_payload_rejects_wrong_vm_nonce_and_sensitive_memory_values(self):
        with tempfile.TemporaryDirectory(prefix="lockspire-startup-witness-") as temporary:
            root = Path(temporary)
            process = None
            try:
                process, _ = self.launch(root)
                channel = process._lockspire_startup_witness
                valid = channel.payload.read_bytes()
                marker = os.urandom(24).hex().encode()
                mutations = [valid.replace(channel.nonce.encode(), b"0" * 64),
                             valid.replace(str(process.pid).encode(), str(process.pid + 1).encode()),
                             valid.replace(b"context_valid=true", b"context_valid=1"),
                             valid.replace(b"protecting_key=false", b"protecting_key=" + marker),
                             valid + b"unknown=" + marker + b"\n", marker * 16]
                original_fdopen = startup_witness.os.fdopen
                rejected = 0
                class Reader:
                    def __init__(self, descriptor, mode): self.original = original_fdopen(descriptor, mode)
                    def __enter__(self): self.original.__enter__(); return self
                    def __exit__(self, *args): return self.original.__exit__(*args)
                    def fileno(self): return self.original.fileno()
                    def read(self, _limit): return mutated
                for mutated in mutations:
                    with patch.object(startup_witness.os, "fdopen", side_effect=Reader):
                        try: verifier_recovery._read_startup_context(root / "startup-witness")
                        except package_input.PackageInputError: rejected += 1
                self.assertTrue(rejected == len(mutations), "unsafe or unbound startup payload was accepted")
                with patch.object(startup_witness, "owned_session_state", return_value="unconfirmed"):
                    with self.assertRaises(package_input.PackageInputError):
                        verifier_recovery._read_startup_context(root / "startup-witness")
                self.assertTrue(verifier_recovery._read_startup_context(root / "startup-witness") == (True, False),
                                "valid actual producer payload failed after rejected mutations")
            finally:
                if process is not None:
                    verifier_rollout._stop_owned_server(process)

    def test_stale_or_symlink_paths_fail_before_listener_launch(self):
        with tempfile.TemporaryDirectory(prefix="lockspire-startup-witness-") as temporary:
            root = Path(temporary)
            existing = root / "existing"
            existing.write_bytes(b"preserved existing bytes")
            stale = root / "stale"
            stale.symlink_to(existing)
            with patch.object(verifier_rollout, "start_owned_session") as launch:
                for path in (existing, stale):
                    with self.assertRaises(package_input.PackageInputError):
                        verifier_rollout._start_server(root, {"LOCKSPIRE_RECOVERY_CONTEXT_WITNESS": "true"}, path, "http://127.0.0.1:1")
                self.assertTrue(launch.call_count == 0, "unsafe witness path launched a listener")
            self.assertTrue(existing.read_bytes() == b"preserved existing bytes", "existing witness path was overwritten")


if __name__ == "__main__": unittest.main()
