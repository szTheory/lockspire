"""Exercise the real admin failure producer and its shell proof consumer."""
from __future__ import annotations

import json
import hashlib
import os
from pathlib import Path
import selectors
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
import clean_room_admin_journey as journey  # noqa: E402
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))
from package_input import (  # noqa: E402
    OwnedSessionSupervisor, owned_process_identity, owned_session_state,
    signal_owned_session, start_owned_session, stop_process_group,
)


SCHEMA = journey.FAILURE_RECORD_SCHEMA
SENTINEL = "opaque-admin-transport-canary-78c1"
UNCONFIRMED_CUSTODY = False
PROBE_RECORDS = []


def run_wrapper(journey_source: str, *, timeout: int = 10,
                deny_group_probe: bool = False, direct_term: bool = False,
                extra_env: dict[str, str] | None = None) -> tuple[int, bytes, bytes, bool]:
    """Run the actual shell consumer with bounded output and owned cleanup."""
    global UNCONFIRMED_CUSTODY
    if UNCONFIRMED_CUSTODY:
        raise AssertionError("earlier transport custody remains unconfirmed; further probes refused")
    wrapper = ROOT / "scripts/ci/run_host_integration_proof.sh"
    embedded = wrapper.read_text().split('  python3 - "$remaining"', 1)[1].split("<<'PY' &\n", 1)[1].split("\nPY\n", 1)[0]
    compile(embedded, str(wrapper), "exec")
    work = Path(tempfile.mkdtemp(prefix="lockspire-admin-transport-" )).resolve()
    work.chmod(0o700)
    ledger = (work / "custody.jsonl").open("x", encoding="ascii")
    os.chmod(ledger.name, 0o600)
    identities = {}

    def record(event, identity=None, **facts):
        row = {"event": event, **facts}
        if identity is not None:
            row["identity"] = identity.safe_record()
        PROBE_RECORDS.append(row)
        ledger.write(json.dumps(row, sort_keys=True) + "\n")
        ledger.flush()
        os.fsync(ledger.fileno())

    class Custody(OwnedSessionSupervisor):
        def _record(self, identity):
            super()._record(identity)
            identities[identity.pid] = identity
            # service() cannot acknowledge register (and permit exec) until
            # this parent-owned numeric-only journal is durable.
            record("admitted_before_exec", identity)

    custody = work / "sessions"
    custody.mkdir(mode=0o700)
    supervisor = Custody(custody)
    record("owner", owned_process_identity(os.getpid()))
    record("source", wrapper_sha256=hashlib.sha256((ROOT / "scripts/ci/run_host_integration_proof.sh").read_bytes()).hexdigest(),
           producer_sha256=hashlib.sha256((ROOT / "scripts/acceptance/clean_room_admin_journey.py").read_bytes()).hexdigest(),
           test_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
           forced_os_probe_denial=deny_group_probe, direct_term=direct_term)
    executable = work / "journey.py"
    executable.write_text(f"#!{sys.executable}\n" + journey_source, encoding="utf-8")
    executable.chmod(0o700)
    receipt_dir = Path(".artifacts") / f"admin-transport-{os.getpid()}-{time.monotonic_ns()}"
    env = dict(os.environ)
    env.update({
        "LOCKSPIRE_PROOF_TEST_MODE": "true",
        "LOCKSPIRE_PROOF_TEST_TRANSPORT": "true",
        "LOCKSPIRE_PROOF_TEST_TIMEOUT_SECONDS": str(timeout),
        "LOCKSPIRE_PROOF_TEST_MIX_BIN": "/usr/bin/true",
        "LOCKSPIRE_PROOF_TEST_JOURNEY_BIN": str(executable),
        "LOCKSPIRE_PROOF_TEST_VALIDATOR_BIN": "/usr/bin/true",
        "LOCKSPIRE_OWNED_SESSION_SOCKET": str(supervisor.endpoint),
        "PYTHONDONTWRITEBYTECODE": "1",
        "LOCKSPIRE_PROOF_TEST_READY_FILE": str(work / "ready"),
    })
    if extra_env:
        env.update(extra_env)
    if deny_group_probe:
        # Narrow fake external OS boundary. Registration, producer, parser,
        # capture and consumer stay real. The independent parent is unpatched.
        hooks = work / "hooks"
        hooks.mkdir(mode=0o700)
        (hooks / "sitecustomize.py").write_text(
            "import errno,os\n"
            "original=os.killpg\n"
            "def deny_zero(pgid,number):\n"
            "    if number == 0: raise PermissionError(errno.EPERM, 'fixed denial')\n"
            "    return original(pgid,number)\n"
            "os.killpg=deny_zero\n", encoding="ascii")
        env["PYTHONPATH"] = str(hooks)
    gate_read, gate_write = os.pipe()
    # The trusted bootstrap waits while its parent admits and journals the
    # factory-owned root. No shell/producer executes before that acknowledgement.
    bootstrap = (
        "import os,sys\n"
        "gate=int(sys.argv[1])\n"
        "token=os.read(gate,1);os.close(gate)\n"
        "if token != b'1': os._exit(125)\n"
        "os.execvpe(sys.argv[2],sys.argv[2:],os.environ)\n"
    )
    process = start_owned_session(
        (sys.executable, "-I", "-S", "-B", "-c", bootstrap, str(gate_read),
         "bash", str(ROOT / "scripts" / "ci" / "run_host_integration_proof.sh"),
         "--pair", "locked", "--receipt-dir", str(receipt_dir)),
        cwd=ROOT, env=env, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, close_fds=True, pass_fds=(gate_read,),
    )
    os.close(gate_read)
    supervisor.admit_root(process)
    os.write(gate_write, b"1")
    os.close(gate_write)
    stdout = bytearray()
    stderr = bytearray()
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ, stdout)
    selector.register(process.stderr, selectors.EVENT_READ, stderr)
    deadline = time.monotonic() + timeout + 16
    output_limit = 256 * 1024
    stopped = True
    interrupted_at = None
    try:
        while selector.get_map():
            supervisor.service()
            if direct_term and interrupted_at is None and (work / "ready").is_file():
                pinned = identities[process.pid]
                if not pinned.same_process(owned_process_identity(process.pid)):
                    raise AssertionError("direct TERM root identity changed")
                record("direct_term", pinned)
                os.kill(process.pid, signal.SIGTERM)
                interrupted_at = time.monotonic()
            remaining = deadline - time.monotonic()
            if remaining <= 0 or len(stdout) + len(stderr) > output_limit:
                stopped = stop_process_group(process, grace=1)
                break
            for key, _ in selector.select(min(remaining, 0.2)):
                chunk = os.read(key.fileobj.fileno(), 65536)
                if not chunk:
                    selector.unregister(key.fileobj)
                else:
                    key.data.extend(chunk)
                    if len(stdout) + len(stderr) > output_limit:
                        stopped = stop_process_group(process, grace=1)
                        break
        if stopped:
            process.wait(timeout=2)
    finally:
        selector.close()
        # The factory-owned outer session is reaped independently. An outer
        # absence result never establishes any registered inner group's state.
        stopped = stop_process_group(process, grace=1) and stopped
        deadline = time.monotonic() + 3
        states = {}
        while time.monotonic() < deadline:
            supervisor.service()
            states = {pid: owned_session_state(identity) for pid, identity in identities.items()}
            if states and all(state == "absent" for state in states.values()):
                break
            time.sleep(0.02)
        for pid, identity in identities.items():
            try:
                os.killpg(identity.pgid, 0)
                probe_errno = 0
            except OSError as error:
                probe_errno = error.errno
            record("closure", identity, state=states.get(pid, "unconfirmed"), kernel_probe_errno=probe_errno)
        stopped = stopped and bool(states) and all(state == "absent" for state in states.values())
        UNCONFIRMED_CUSTODY = not stopped
        supervisor.close()
        ledger.close()
        # Remove only the exact receipt directory created by this invocation.
        target = ROOT / receipt_dir
        if target.exists() and target.is_dir() and not target.is_symlink():
            for entry in target.iterdir():
                if entry.is_file() and not entry.is_symlink():
                    entry.unlink()
            target.rmdir()
        if stopped:
            shutil.rmtree(work)
        else:
            # Diagnostic path cannot become signal authority. The in-memory
            # supervisor/factory identity is the sole authority for this run.
            print("transport_custody_retained=" + str(work))
    status = process.returncode if process.returncode is not None else 125
    safe_record = None
    for line in bytes(stderr).decode("utf-8", "replace").splitlines():
        prefix = "host integration failure record: "
        if line.startswith(prefix):
            try:
                value = json.loads(line[len(prefix):])
            except (json.JSONDecodeError, TypeError):
                continue
            safe_record = journey.validate_failure_record(value)
            if safe_record is not None:
                break
    stage = safe_record["stage"] if safe_record else "unknown"
    reason = safe_record["reason"] if safe_record else "unknown"
    print(f"transport_observation status={status} stopped={str(stopped).lower()} stage={stage} reason={reason} groups={len(identities)}")
    # A deliberately denied group probe composes the existing signal drain5,
    # explicit stop7 and atexit drain5 bounds; it cannot use the normal5 bound.
    interrupt_bound = 20 if deny_group_probe else 5
    if direct_term and (interrupted_at is None or time.monotonic() - interrupted_at >= interrupt_bound):
        raise AssertionError("direct TERM did not complete within its cleanup bound")
    return status, bytes(stdout), bytes(stderr), stopped


def producer_source(failure_stage: str, *, cleanup_failed: bool = False) -> str:
    """Real main/emission with only external app/package/browser IO replaced."""
    return (
        "import contextlib,json,secrets,sys\n"
        "from pathlib import Path\n"
        "from types import SimpleNamespace\n"
        "from unittest.mock import patch\n"
        f"sys.path.insert(0,{str(ROOT / 'scripts/acceptance')!r})\n"
        "import clean_room_admin_journey as j\n"
        f"failure_stage={failure_stage!r};cleanup_failed={cleanup_failed!r}\n"
        "fake_process=SimpleNamespace(pid=424242);fake_identity=object()\n"
        # This value exists only in child memory, never in generated source.
        "opaque='opaque-admin-transport-canary-78c1'+secrets.token_urlsafe(40)\n"
        "def boundary(stage,value=None):\n"
        "    def call(*args,**kwargs):\n"
        "        if failure_stage == stage: raise RuntimeError(opaque)\n"
        "        return value(*args,**kwargs) if callable(value) else value\n"
        "    return call\n"
        "def command(child,env,task,*args):\n"
        "    if failure_stage == ('database_create' if task == 'ecto.create' else 'database_migrate'): raise RuntimeError(opaque)\n"
        "def receipt(*args,**kwargs):\n"
        "    if failure_stage == 'receipt': raise ValueError(opaque)\n"
        "def external(command,**kwargs):\n"
        "    if command[0] == 'mix': return SimpleNamespace(returncode=1 if cleanup_failed else 0)\n"
        "    passed=failure_stage != 'browser'\n"
        "    observed={'id':'full','outcome':'passed' if passed else 'failed','profile_removed':True,\n"
        "      'failure':'browser_timeout','stage':'cdp_setup','opaque':opaque,\n"
        "      'scenarios':[{'id':key,'outcome':'passed' if passed else 'failed','duration_ms':1,'counts':{},'observations':{}} for key in j.FULL_REQUIRED]}\n"
        "    return SimpleNamespace(returncode=0 if passed else 1,stdout=json.dumps(observed))\n"
        "def readiness(*args):\n"
        "    if failure_stage == 'host_startup_exit': raise j.HostStartupFailure(host_exit_status=1,readiness_deadline_elapsed=False)\n"
        "    if failure_stage == 'host_startup_deadline': raise j.HostStartupFailure(host_exit_status=None,readiness_deadline_elapsed=True)\n"
        "def host_start(*args,**kwargs):\n"
        "    if failure_stage == 'host_startup': raise RuntimeError(opaque)\n"
        "    return fake_process\n"
        "with contextlib.ExitStack() as stack:\n"
        "    replacements={\n"
        "      'package_source':boundary('candidate'),\n"
        "      'prepare_package':lambda base,source:(base,(),SimpleNamespace(source_revision='1'*40,version='0.1.0',archive_sha256='2'*64,tree_sha256='3'*64)),\n"
        "      'clean_room_database_url':lambda role:'postgres://test:unused@127.0.0.1:1/unused',\n"
        "      'allocate_port':lambda:1,\n"
        "      'prepare_provider':boundary('provider_preparation',lambda base,*args,**kwargs:base),\n"
        "      'run_child_command':command,\n"
        "      'runtime_versions':boundary('runtime_observation',{'phoenix':'1.8.13','live_view':'1.2.10','elixir':'1.19.5','otp':'28'}),\n"
        "      'start_owned_session':host_start,\n"
        "      '_OWNED_IDENTITIES':{fake_process.pid:fake_identity},\n"
        "      'stop_owned':lambda process,identity: process is fake_process and identity is fake_identity,\n"
        "      'wait_ready':readiness,\n"
        "      'bounded_run':external,\n"
        "      'write_receipt':receipt}\n"
        "    for name,value in replacements.items(): stack.enter_context(patch.object(j,name,value))\n"
        "    result=j.main(['--pair','locked','--mount','/lockspire','--scenario','full','--receipt','unused.json','--run-id','68f0ea0f-a4ec-4e4a-81da-befc30c99b33'])\n"
        "sys.stderr.write('opaque-browser-canary\\n')\n"
        "raise SystemExit(23 if result == 1 else 79)\n"
    )


def records(stderr: bytes, prefix: str) -> list[dict]:
    """Assertions consume real wrapper output; no opaque assertion reprs."""
    selected = []
    for line in stderr.decode("utf-8", "strict").splitlines():
        if line.startswith(prefix):
            selected.append(json.loads(line[len(prefix):]))
    return selected


class ClientAdminFailureTransport(unittest.TestCase):
    def test_typed_host_startup_witness_crosses_the_actual_wrapper(self):
        expected = {
            "host_startup_exit": {"host_exit_status": 1, "readiness_deadline_elapsed": False},
            "host_startup_deadline": {"host_exit_status": None, "readiness_deadline_elapsed": True},
        }
        for case, witness in expected.items():
            status, _stdout, stderr, stopped = run_wrapper(producer_source(case))
            primary = records(stderr, "host integration failure record: ")
            self.assertEqual(status, 23)
            self.assertTrue(stopped)
            self.assertEqual(len(primary), 1)
            self.assertEqual(primary[0]["stage"], "host_startup")
            self.assertEqual(primary[0]["reason"], "host_startup_failed")
            self.assertEqual(primary[0]["host_startup"], witness)

    def test_invalid_tool_configuration_removes_early_raw_capture_directory(self):
        temp_root = Path(tempfile.mkdtemp(prefix="lockspire-admin-invalid-config-")).resolve()
        temp_root.chmod(0o700)
        try:
            record_start = len(PROBE_RECORDS)
            status, stdout, stderr, stopped = run_wrapper(
                producer_source("browser"),
                extra_env={
                    "TMPDIR": str(temp_root),
                    "LOCKSPIRE_PROOF_TEST_TIMEOUT_SECONDS": "invalid",
                },
            )
            self.assertTrue(status == 64, "invalid tool configuration status changed")
            self.assertTrue(stopped, "wrapper parent cleanup was not confirmed")
            self.assertTrue(stdout == b"" and b"usage:" in stderr, "invalid configuration output was not fixed usage text")
            self.assertTrue(list(temp_root.iterdir()) == [], "early raw capture directory remained after validation exit")
            admitted = {
                (row["identity"]["pid"], row["identity"]["pgid"], row["identity"]["sid"], tuple(row["identity"]["start"]))
                for row in PROBE_RECORDS[record_start:]
                if row.get("event") == "admitted_before_exec"
            }
            self.assertTrue(len(admitted) == 1, "invalid configuration launched a nested owned child")
        finally:
            shutil.rmtree(temp_root)

    def test_startup_witness_distinguishes_observed_host_exit_from_readiness_deadline(self):
        exited = type("ExitedProcess", (), {"returncode": 1, "poll": lambda self: 1})()
        with self.assertRaises(journey.HostStartupFailure) as caught_exit:
            journey.wait_ready("http://127.0.0.1:1", exited, timeout=1)
        self.assertEqual(
            caught_exit.exception.host_startup_witness,
            {"host_exit_status": 1, "readiness_deadline_elapsed": False},
        )

        waiting = type("WaitingProcess", (), {"returncode": None, "poll": lambda self: None})()
        with self.assertRaises(journey.HostStartupFailure) as caught_deadline:
            journey.wait_ready("http://127.0.0.1:1", waiting, timeout=0)
        self.assertEqual(
            caught_deadline.exception.host_startup_witness,
            {"host_exit_status": None, "readiness_deadline_elapsed": True},
        )

    def test_failure_record_accepts_only_consistent_typed_startup_witness(self):
        base = {"schema": SCHEMA, "stage": "host_startup", "reason": "host_startup_failed"}
        exited = {**base, "host_startup": {
            "host_exit_status": 1, "readiness_deadline_elapsed": False,
        }}
        deadline = {**base, "host_startup": {
            "host_exit_status": None, "readiness_deadline_elapsed": True,
        }}
        self.assertIsNotNone(journey.validate_failure_record(exited))
        self.assertIsNotNone(journey.validate_failure_record(deadline))
        self.assertIsNone(journey.validate_failure_record({**base, "host_startup": {
            "host_exit_status": 1, "readiness_deadline_elapsed": True,
        }}))
        self.assertIsNone(journey.validate_failure_record({**base, "host_startup": {
            "host_exit_status": "1", "readiness_deadline_elapsed": False,
        }}))

    def producer_record(self) -> str:
        stderr = []

        class Capture:
            def write(self, value):
                stderr.append(value)

            def flush(self):
                pass

        def fail_source(*_args, **_kwargs):
            raise RuntimeError(SENTINEL)

        args = [
            "--pair", "locked", "--mount", "/lockspire", "--scenario", "full",
            "--receipt", str(Path(tempfile.gettempdir()) / "unused-admin-transport-receipt.json"),
            "--run-id", "68f0ea0f-a4ec-4e4a-81da-befc30c99b33",
        ]
        with patch.object(journey, "package_source", side_effect=fail_source), \
             patch.object(sys, "stderr", Capture()):
            status = journey.main(args)
        output = "".join(stderr)
        self.assertTrue(status == 1, "producer did not preserve candidate failure")
        self.assertTrue(SENTINEL not in output, "producer exposed opaque exception data")
        prefix = "admin proof failure record: "
        lines = [line[len(prefix):] for line in output.splitlines() if line.startswith(prefix)]
        self.assertTrue(len(lines) == 1, "producer did not emit one closed failure record")
        record = json.loads(lines[0])
        self.assertTrue(journey.validate_failure_record(record) is not None, "producer record failed schema validation")
        return lines[0]

    def test_actual_producer_record_crosses_actual_wrapper_and_preserves_failure(self):
        record = self.producer_record()
        source = producer_source("candidate").replace("raise SystemExit(23 if result == 1 else 79)\n", "") + (
            "sys.stderr.write('browser proof failed: ' + json.dumps({'failure':'browser_timeout','stage':'cdp_setup','outcome':'failed','counts':{},'opaque':'" + SENTINEL + "'}) + '\\n')\n"
            "sys.stderr.write('opaque-browser-canary\\n')\n"
            "raise SystemExit(23)\n"
        )
        status, stdout, stderr, stopped = run_wrapper(source)
        combined = stdout + stderr
        self.assertTrue(status == 23, "wrapper changed the producer child exit status")
        self.assertTrue(stopped, "wrapper child process cleanup was not confirmed")
        self.assertTrue(b"opaque-browser-canary" not in combined, "wrapper exposed opaque browser output")
        self.assertTrue(("host integration failure record: " + record).encode() in combined,
                        "wrapper did not forward the actual validated producer record")
        self.assertTrue(b'"failure": "browser_timeout"' in combined,
                        "wrapper did not retain its allowlisted browser diagnostic")
        command = records(stderr, "host integration command status: ")
        self.assertTrue(len(command) == 1 and command[0]["native_exit"] == 23 and
                        command[0]["status"] == 23 and command[0]["cleanup"] == "stopped",
                        "wrapper lost independent native or cleanup status")

    def test_actual_producer_setup_browser_and_receipt_failures_keep_their_stage(self):
        cases = {
            "provider_preparation": "provider_preparation_failed",
            "database_create": "database_creation_failed",
            "database_migrate": "database_migration_failed",
            "runtime_observation": "runtime_observation_failed",
            "host_startup": "host_startup_failed",
            "browser": "browser_proof_failed",
            "receipt": "receipt_invalid",
        }
        for stage, reason in cases.items():
            status, stdout, stderr, stopped = run_wrapper(producer_source(stage))
            primary = records(stderr, "host integration failure record: ")
            self.assertTrue(status == 23 and stopped, "source failure changed native exit or lost group closure")
            self.assertTrue(len(primary) == 1 and primary[0]["stage"] == stage and primary[0]["reason"] == reason,
                            "actual producer failure stage did not reach actual wrapper")
            self.assertTrue(SENTINEL.encode() not in stdout + stderr and b"opaque-browser-canary" not in stdout + stderr,
                            "actual source exception or child stream escaped")
            if stage == "browser":
                diagnostic = records(stderr, "host integration browser diagnostic: ")
                self.assertTrue(len(diagnostic) == 1 and "first_case" in diagnostic[0] and "failed_cases" in diagnostic[0],
                                "wrapper discarded validated legacy case diagnostics")

    def test_actual_producer_secondary_cleanup_does_not_conflict_with_primary(self):
        status, _stdout, stderr, stopped = run_wrapper(producer_source("browser", cleanup_failed=True))
        primary = records(stderr, "host integration failure record: ")
        cleanup = records(stderr, "host integration cleanup record: ")
        self.assertTrue(status == 23 and stopped, "producer cleanup report changed native child exit")
        self.assertTrue(len(primary) == 1 and primary[0]["stage"] == "browser",
                        "supplemental cleanup replaced or invalidated the primary")
        self.assertTrue(len(cleanup) == 1 and cleanup[0]["stage"] == "cleanup",
                        "producer supplemental cleanup was omitted")

    def test_wrapper_rejects_malformed_or_opaque_records_and_missing_record(self):
        for child_line in (
            'admin proof failure record: {"schema":"lockspire-admin-proof-failure-v1","stage":"browser","reason":"browser_proof_failed","extra":"' + SENTINEL + '"}',
            'admin proof failure record: {"schema":false,"stage":"browser","reason":"browser_proof_failed"}',
            'admin proof failure record: {"schema":"lockspire-admin-proof-failure-v1","stage":"forged","reason":"browser_proof_failed"}',
            'admin proof failure record: {"schema":"lockspire-admin-proof-failure-v1","stage":"browser","reason":"' + SENTINEL + '"}',
            'admin proof failure record: {"schema":"lockspire-admin-proof-failure-v1","stage":[],"reason":"browser_proof_failed"}',
            'admin proof failure record: {"schema":"lockspire-admin-proof-failure-v1","stage":"browser","reason":"browser_proof_failed","reason":"browser_proof_failed"}',
            'admin proof failure record: {"schema":"lockspire-admin-proof-failure-v1","stage":"browser","reason":"browser_proof_failed"',
            'admin proof failure record: {"schema":"lockspire-admin-proof-failure-v1","stage":"browser","reason":"browser_proof_failed"}\nadmin proof failure record: {"schema":"lockspire-admin-proof-failure-v1","stage":"receipt","reason":"receipt_invalid"}',
            "opaque child text " + SENTINEL,
        ):
            source = f"import sys\nsys.stderr.write({child_line!r} + '\\n')\nraise SystemExit(23)\n"
            status, _stdout, stderr, stopped = run_wrapper(source)
            self.assertTrue(status == 23, "wrapper changed invalid-record child status")
            self.assertTrue(stopped, "wrapper cleanup was not confirmed for invalid record")
            self.assertTrue(b"failure_record_malformed" in stderr or b"failure_record_missing" in stderr,
                            "wrapper accepted or omitted a fixed malformed-record diagnosis")
            self.assertTrue(SENTINEL.encode() not in stderr, "wrapper forwarded opaque record data")

        source = (
            "import os\n"
            "os.write(2, b'admin proof failure record: ' + bytes([255]) + b'\\n')\n"
            "raise SystemExit(23)\n"
        )
        status, _stdout, stderr, stopped = run_wrapper(source)
        self.assertTrue(status == 23, "wrapper changed invalid-UTF-8 child status")
        self.assertTrue(stopped, "wrapper cleanup was not confirmed after invalid UTF-8")
        self.assertTrue(b"failure_record_malformed" in stderr, "wrapper did not withhold invalid-UTF-8 record")
        self.assertTrue(b"opaque" not in stderr, "wrapper forwarded invalid-UTF-8 payload")

    def test_wrapper_discards_bounded_capture_when_output_limit_is_exceeded(self):
        source = (
            "import sys\n"
            f"sys.stderr.write({SENTINEL!r} + '\\n')\n"
            "sys.stderr.flush()\n"
            "sys.stderr.write('x' * (4 * 1024 * 1024 + 128))\n"
            "sys.stderr.flush()\n"
        )
        status, stdout, stderr, stopped = run_wrapper(source)
        combined = stdout + stderr
        self.assertTrue(status == 125, "wrapper did not fail closed at the byte limit")
        self.assertTrue(stopped, "wrapper did not confirm output-limit child cleanup")
        self.assertTrue(b"output_limit_exceeded" in stderr, "wrapper omitted fixed output-limit reason")
        command = records(stderr, "host integration command status: ")
        self.assertTrue(len(command) == 1 and command[0]["reason"] == "output_limit_exceeded" and
                        type(command[0]["native_exit"]) is int and command[0]["cleanup"] == "stopped",
                        "byte limit lost its independent native exit or cleanup result")
        self.assertTrue(SENTINEL.encode() not in combined and b"x" * 128 not in combined,
                        "wrapper retained partial child output after the byte limit")

    def test_wrapper_enforces_time_limit_and_cleans_up_the_child_group(self):
        source = "import time\ntime.sleep(30)\n"
        status, stdout, stderr, stopped = run_wrapper(source, timeout=1)
        self.assertTrue(status == 124, "wrapper did not preserve timeout failure status")
        self.assertTrue(stopped, "wrapper did not confirm timed-out child cleanup")
        self.assertTrue(b"failure_record_missing" in stderr, "wrapper omitted fixed timeout failure record")
        command = records(stderr, "host integration command status: ")
        self.assertTrue(len(command) == 1 and command[0]["reason"] == "timeout" and
                        type(command[0]["native_exit"]) is int and command[0]["cleanup"] == "stopped",
                        "timeout lost its independent native exit or cleanup result")
        self.assertTrue(not stdout, "timed-out child produced unexpected stdout")

    def test_actual_os_boundary_denial_keeps_primary_native_exit_and_cleanup_independent(self):
        status, stdout, stderr, stopped = run_wrapper(producer_source("candidate"), deny_group_probe=True)
        primary = records(stderr, "host integration failure record: ")
        command = records(stderr, "host integration command status: ")
        cleanup = records(stderr, "host integration cleanup record: ")
        self.assertTrue(status == 125 and stopped, "forced child cleanup denial was accepted or parent could not prove closure")
        self.assertTrue(len(primary) == 1 and primary[0]["stage"] == "candidate",
                        "cleanup failure masked primary producer evidence")
        self.assertTrue(len(command) == 1 and command[0]["native_exit"] == 23 and command[0]["status"] == 23 and
                        command[0]["cleanup"] == "unconfirmed" and command[0]["reason"] == "native_exit",
                        "cleanup failure overwrote actual native child exit")
        self.assertTrue(len(cleanup) == 1 and cleanup[0]["reason"] == "cleanup_failed",
                        "cleanup refusal was omitted")
        self.assertTrue(SENTINEL.encode() not in stdout + stderr, "denial path exposed opaque child output")

    def test_direct_term_preserves_async_wait_and_closes_every_registered_group(self):
        source = (
            "import os,time\nfrom pathlib import Path\n"
            "Path(os.environ['LOCKSPIRE_PROOF_TEST_READY_FILE']).touch()\n"
            "time.sleep(30)\n"
        )
        status, stdout, stderr, stopped = run_wrapper(source, direct_term=True)
        self.assertTrue(status == 143 and stopped, "direct TERM lost the original status or an owned group")
        self.assertTrue(not stdout and SENTINEL.encode() not in stderr, "direct TERM exposed child output")

    def test_direct_term_does_not_hide_unconfirmed_cleanup_or_primary_record(self):
        record = json.dumps({"schema": SCHEMA, "stage": "browser", "reason": "browser_proof_failed"}, sort_keys=True)
        source = (
            "import os,sys,time\nfrom pathlib import Path\n"
            f"sys.stderr.write('admin proof failure record: '+{record!r}+'\\n');sys.stderr.flush()\n"
            "Path(os.environ['LOCKSPIRE_PROOF_TEST_READY_FILE']).touch()\n"
            "time.sleep(30)\n"
        )
        status, _stdout, stderr, stopped = run_wrapper(source, direct_term=True, deny_group_probe=True)
        primary = records(stderr, "host integration failure record: ")
        command = records(stderr, "host integration command status: ")
        cleanup = records(stderr, "host integration cleanup record: ")
        self.assertTrue(status == 125 and stopped, "interrupted cleanup uncertainty was accepted")
        self.assertTrue(len(primary) == 1 and primary[0]["stage"] == "browser",
                        "interruption cleanup masked the primary record")
        self.assertTrue(len(command) == 1 and command[0]["native_exit"] == -15 and
                        command[0]["cleanup"] == "unconfirmed", "interruption lost actual native exit or cleanup state")
        self.assertTrue(len(cleanup) == 1 and cleanup[0]["reason"] == "cleanup_failed", "interrupted cleanup refusal omitted")

    def test_native_125_and_success_are_distinct_from_capture_or_cleanup_failure(self):
        source = producer_source("candidate").replace("raise SystemExit(23 if result == 1 else 79)",
                                                      "raise SystemExit(125 if result == 1 else 79)")
        status, _stdout, stderr, stopped = run_wrapper(source)
        primary = records(stderr, "host integration failure record: ")
        command = records(stderr, "host integration command status: ")
        self.assertTrue(status == 125 and stopped and len(primary) == 1 and primary[0]["stage"] == "candidate",
                        "native125 discarded the producer record")
        self.assertTrue(len(command) == 1 and command[0]["native_exit"] == 125 and command[0]["reason"] == "native_exit" and
                        command[0]["cleanup"] == "stopped", "native125 was confused with cleanup failure")
        status, stdout, stderr, stopped = run_wrapper("raise SystemExit(0)\n")
        self.assertTrue(status == 0 and stopped and not stdout and not stderr, "successful command invented failure evidence")

    def test_byte_cap_boundary_neighbors_remain_memory_only(self):
        record = json.dumps({"schema": SCHEMA, "stage": "browser", "reason": "browser_proof_failed"}, sort_keys=True)
        line = "admin proof failure record: " + record + "\n"
        for total in (4 * 1024 * 1024 - 1, 4 * 1024 * 1024):
            source = ("import os\n" + f"os.write(2,{line.encode()!r})\n" +
                      f"data=b'x'*({total}-len({line.encode()!r}))\n" +
                      "while data:\n    count=os.write(1,data[:65536]);data=data[count:]\n" +
                      "raise SystemExit(23)\n")
            status, stdout, stderr, stopped = run_wrapper(source)
            primary = records(stderr, "host integration failure record: ")
            self.assertTrue(status == 23 and stopped and not stdout and len(primary) == 1 and primary[0]["stage"] == "browser",
                            "byte-cap neighbor was rejected or exposed child data")
            self.assertTrue(b"x" * 128 not in stderr, "bounded child stdout escaped at the byte boundary")

    def test_baseline_protocol_counterfactual_loses_stage_without_opening_raw_logs(self):
        # Post-draft counterfactual, not an invented pre-edit RED. Execute only
        # the exact baseline protocol consumer, with its read boundary in RAM;
        # never execute the old wrapper's raw-log capture or launch path.
        actual = producer_source("candidate")
        source = (
            "import contextlib,io,subprocess,sys\n"
            "from pathlib import Path\n"
            "from unittest.mock import patch\n"
            f"sys.path.insert(0,{str(ROOT / 'scripts/acceptance/clean_room')!r})\n"
            "from package_input import bounded_run\n"
            "memory=io.StringIO()\n"
            "with contextlib.redirect_stderr(memory),contextlib.redirect_stdout(io.StringIO()):\n"
            "    try:\n"
            f"        exec(compile({actual!r},'actual-producer','exec'),{{'__name__':'__main__'}})\n"
            "    except SystemExit: pass\n"
            "blob=bounded_run(('git','show','781b6e2a9c11e11c2bcb0608bc1efb212562350e:scripts/ci/run_host_integration_proof.sh'),timeout=10,stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE)\n"
            "if blob.returncode != 0 or len(blob.stdout) > 65536: raise SystemExit(79)\n"
            "legacy=blob.stdout.decode('utf-8').split('emit_browser_diagnostic() {',1)[1].split(\"<<'PY' || {\\n\",1)[1].split('\\nPY\\n',1)[0]\n"
            "legacy_memory=io.StringIO()\n"
            "with patch.object(sys,'argv',['baseline-protocol','memory-only']),patch.object(Path,'read_text',return_value=memory.getvalue()),patch('builtins.open',side_effect=AssertionError('raw log open forbidden')),contextlib.redirect_stderr(legacy_memory):\n"
            "    exec(compile(legacy,'baseline-protocol-consumer','exec'),{'__name__':'__main__'})\n"
            "prefix='host integration browser diagnostic: '\n"
            "line=legacy_memory.getvalue().strip()\n"
            "if not line.startswith(prefix): raise SystemExit(79)\n"
            "sys.stderr.write('browser proof failed: '+line[len(prefix):]+'\\n')\n"
            "raise SystemExit(23)\n"
        )
        status, _stdout, stderr, stopped = run_wrapper(source)
        primary = records(stderr, "host integration failure record: ")
        legacy = records(stderr, "host integration browser diagnostic: ")
        self.assertTrue(status == 23 and stopped, "bounded baseline protocol control did not execute")
        self.assertTrue(len(primary) == 1 and primary[0]["reason"] == "failure_record_missing" and
                        len(legacy) == 1 and legacy[0]["failure"] == "failure_missing",
                        "baseline consumer unexpectedly retained actual producer setup stage")


if __name__ == "__main__":
    unittest.main()
