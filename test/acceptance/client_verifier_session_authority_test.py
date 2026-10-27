"""Actual-wrapper process custody must not confer authority from PID claims."""

from contextlib import ExitStack
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
WRAPPER = ROOT / "scripts/ci/run_verifier_upgrade_proof.sh"


def absent(pgid):
    try:
        os.killpg(pgid, 0)
    except ProcessLookupError:
        return True
    except PermissionError:
        pass
    return False


class ActualWrapperSessionAuthority(unittest.TestCase):
    def test_injected_sibling_registry_row_never_authorizes_signalling(self):
        with ExitStack() as stack:
            root = Path(tempfile.mkdtemp(prefix="lockspire-authority-probe-")).resolve()
            reconciled = False
            stack.callback(lambda: shutil.rmtree(root) if reconciled else None)
            ledger = root / "probe-custody.json"
            root_pid_file = root / "runner.pid"
            sibling_ready = root / "sibling-ready"
            sibling_term = root / "sibling-term"
            ledger.write_text(json.dumps({"root": str(root), "root_pid_file": str(root_pid_file),
                                          "cleanup": "not_started"}), encoding="ascii")
            sibling = subprocess.Popen(
                [sys.executable, "-c", "import pathlib,signal,sys,time; "
                 "signal.signal(signal.SIGTERM,lambda s,f:pathlib.Path(sys.argv[2]).touch()); "
                 "pathlib.Path(sys.argv[1]).touch(); time.sleep(60)", str(sibling_ready), str(sibling_term)],
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
            ledger.write_text(json.dumps({"root": str(root), "sibling_pgid": sibling.pid,
                                          "root_pid_file": str(root_pid_file)}), encoding="ascii")
            runner = root / "runner.py"
            runner.write_text(
                "import json,os,pathlib,socket,time\n"
                "if os.environ.get('LOCKSPIRE_OWNED_SESSION_REGISTRY'):\n"
                "    registry=pathlib.Path(os.environ['LOCKSPIRE_OWNED_SESSION_REGISTRY'])\n"
                f"    (registry / '{sibling.pid}.json').write_text(json.dumps({{'pid':{sibling.pid},'parent_pid':os.getpid()}}))\n"
                "if os.environ.get('LOCKSPIRE_OWNED_SESSION_SOCKET'):\n"
                "    registry=pathlib.Path(os.environ['LOCKSPIRE_OWNED_SESSION_SOCKET']).parent\n"
                f"    (registry / '{sibling.pid}.json').write_text(json.dumps({{'pid':{sibling.pid},'parent_pid':os.getpid()}}))\n"
                "    connection=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM)\n"
                "    connection.settimeout(2)\n"
                "    connection.connect(os.environ['LOCKSPIRE_OWNED_SESSION_SOCKET'])\n"
                f"    connection.sendall(json.dumps({{'action':'register','pid':{sibling.pid}}}).encode()+b'\\n')\n"
                "    connection.recv(32)\n"
                "    connection.close()\n"
                "time.sleep(0.1)\n", encoding="ascii",
            )
            env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1",
                       LOCKSPIRE_VERIFIER_TEST_MODE="1", LOCKSPIRE_VERIFIER_TEST_RUNNER=str(runner),
                       LOCKSPIRE_VERIFIER_TEST_PYTHON=sys.executable,
                       LOCKSPIRE_VERIFIER_TEST_TIMEOUT="2", LOCKSPIRE_VERIFIER_TEST_OVERALL_TIMEOUT="3",
                       LOCKSPIRE_VERIFIER_TEST_PID_FILE=str(root_pid_file))
            wrapper = None
            custody = None
            try:
                deadline = time.monotonic() + 3
                while not sibling_ready.exists() and time.monotonic() < deadline:
                    time.sleep(0.01)
                self.assertTrue(sibling_ready.exists(), "owned sibling readiness failed")
                wrapper = subprocess.Popen(
                    ["bash", str(WRAPPER), "--pair", "locked", "--receipt-dir", str(root / "receipts"), "--test-mode"],
                    cwd=ROOT, env=env, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE, start_new_session=True,
                )
                ledger.write_text(json.dumps({"root": str(root), "sibling_pgid": sibling.pid,
                                              "wrapper_pgid": wrapper.pid,
                                              "root_pid_file": str(root_pid_file)}), encoding="ascii")
                stdout, stderr = wrapper.communicate(timeout=24)
                prefix = "verifier owned session custody retained: "
                paths = [line[len(prefix):] for line in stderr.decode("ascii").splitlines() if line.startswith(prefix)]
                if paths:
                    custody = Path(paths[0]).resolve()
                    ledger.write_text(json.dumps({"root": str(root), "sibling_pgid": sibling.pid,
                        "wrapper_pgid": wrapper.pid, "root_pid_file": str(root_pid_file),
                        "retained_custody": str(custody)}), encoding="ascii")
                self.assertTrue(sibling.poll() is None, "caller-written sibling PID authorized a foreign group signal")
                self.assertFalse(sibling_term.exists(), "wrapper sent TERM outside its process ownership")
                if custody is not None:
                    rows = [json.loads(path.read_text(encoding="ascii")) for path in custody.iterdir()]
                    self.assertTrue(all(set(row) == {"pid", "parent_pid", "pgid", "sid", "start"}
                                        and row["pid"] != sibling.pid for row in rows),
                                    "retained custody adopted caller-written foreign authority")
                self.assertTrue(wrapper.returncode in {78, 125}, "wrapper authority refusal changed test-mode boundary")
                self.assertFalse((root / "receipts").exists(), "injection probe created accepted package evidence")
                self.assertTrue(b"Traceback" not in stdout + stderr, "unknown child diagnostics escaped")
            finally:
                groups = [sibling.pid]
                if root_pid_file.is_file():
                    groups.append(int(root_pid_file.read_text(encoding="ascii")))
                if wrapper is not None:
                    groups.append(wrapper.pid)
                for pgid in groups:
                    try:
                        os.killpg(pgid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                sibling.wait(timeout=3)
                if wrapper is not None:
                    wrapper.communicate(timeout=3)
                deadline = time.monotonic() + 3
                while not all(absent(pgid) for pgid in groups) and time.monotonic() < deadline:
                    time.sleep(0.02)
                reconciled = all(absent(pgid) for pgid in groups)
                self.assertTrue(reconciled, "exact owned probe groups unresolved; custody retained")
                if custody is not None:
                    self.assertTrue(custody.name.startswith("lockspire-verifier-owned-")
                                    and custody.parent == Path(tempfile.gettempdir()).resolve()
                                    and not custody.is_symlink(), "probe custody path mismatch")
                    shutil.rmtree(custody)


if __name__ == "__main__":
    unittest.main()
