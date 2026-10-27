"""Actual-wrapper delayed escalation controls; child diagnostics stay in memory."""

from __future__ import annotations

from contextlib import ExitStack
import importlib.util
import json
import os
from pathlib import Path
import signal
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
WRAPPER = ROOT / "scripts/ci/run_verifier_upgrade_proof.sh"
INPUT = ROOT / "scripts/acceptance/clean_room/package_input.py"


def absent(pgid: int) -> bool:
    try:
        os.killpg(pgid, 0)
        return False
    except ProcessLookupError:
        return True
    except PermissionError:
        return False  # Uncertainty is never group absence.


class ActualWrapperNestedSessions(unittest.TestCase):
    def exercise(self, external_term: bool, *, root_ignores_term: bool = False,
                 children: int = 1, force_group_denial: bool = False) -> None:
        with ExitStack() as stack:
            root = Path(tempfile.mkdtemp(prefix="lockspire-owned-wrapper-")).resolve()
            cleanup_confirmed = False
            stack.callback(lambda: shutil.rmtree(root) if cleanup_confirmed else None)
            ready = root / "ready"
            identities = root / "owned-sessions.json"
            wrapper_pid = root / "root-session.pid"
            # Names and ownership record exist before any launch; only generated
            # exact process/session identities are added, never command arguments.
            identities.write_text("[]", encoding="ascii")
            layout = root / "probe-custody.json"
            layout.write_text(json.dumps({"root": str(root), "identity_file": str(identities),
                                          "root_pid_file": str(wrapper_pid), "cleanup": "not_started"}), encoding="ascii")
            fake = root / "runner.py"
            child = (
                "import pathlib,signal,sys,time; "
                "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
                "pathlib.Path(sys.argv[1]).touch(); time.sleep(60)"
            )
            fake.write_text(
                "import json,os,pathlib,signal,subprocess,sys,time\n"
                f"sys.path.insert(0, {str(INPUT.parent)!r})\n"
                "from package_input import start_owned_session\n"
                f"owned=pathlib.Path({str(identities)!r})\n"
                "pids=[]\n"
                f"for index in range({children}):\n"
                f"    marker=pathlib.Path({str(root)!r}) / ('child-ready-' + str(index))\n"
                f"    process=start_owned_session([sys.executable, '-c', {child!r}, str(marker)], "
                "stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)\n"
                "    pids.append(process.pid)\n"
                "    owned.write_text(json.dumps(pids), encoding='ascii')\n"
                "    while not marker.exists(): time.sleep(0.01)\n"
                + ("signal.signal(signal.SIGTERM, signal.SIG_IGN)\n" if root_ignores_term else "")
                + f"pathlib.Path({str(ready)!r}).touch()\n"
                "time.sleep(60)\n", encoding="utf-8",
            )
            environment = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
            environment.update({
                "LOCKSPIRE_VERIFIER_TEST_MODE": "1",
                "LOCKSPIRE_VERIFIER_TEST_RUNNER": str(fake),
                "LOCKSPIRE_VERIFIER_TEST_TIMEOUT": "9",
                "LOCKSPIRE_VERIFIER_TEST_OVERALL_TIMEOUT": "9" if external_term else "2",
                "LOCKSPIRE_VERIFIER_TEST_PYTHON": sys.executable,
                "LOCKSPIRE_VERIFIER_TEST_PID_FILE": str(wrapper_pid),
            })
            if force_group_denial:
                environment["LOCKSPIRE_VERIFIER_TEST_FORCE_GROUP_DENIAL"] = "1"
            started = time.monotonic()
            wrapper = subprocess.Popen(
                ["bash", str(WRAPPER), "--pair", "locked", "--receipt-dir", str(root / "receipt"), "--test-mode"],
                cwd=ROOT, env=environment, stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True,
            )
            custody = None
            try:
                deadline = time.monotonic() + 5
                while time.monotonic() < deadline and not ready.exists() and wrapper.poll() is None:
                    time.sleep(0.02)
                self.assertTrue(ready.exists(), "owned delayed child did not become ready")
                layout.write_text(json.dumps({"root": str(root), "wrapper_pgid": wrapper.pid,
                    "owned_session_pgids": json.loads(identities.read_text(encoding="ascii")),
                    "root_session_pgid": int(wrapper_pid.read_text(encoding="ascii")),
                    "cleanup": "owned_and_ready"}), encoding="ascii")
                if external_term:
                    wrapper.send_signal(signal.SIGTERM)
                stdout, stderr = wrapper.communicate(timeout=24)
                expected = 125 if force_group_denial else (143 if external_term else 124)
                self.assertTrue(wrapper.returncode == expected, "actual wrapper did not confirm bounded cleanup")
                self.assertTrue(time.monotonic() - started < 23, "wrapper exceeded cleanup bound")
                pids = json.loads(identities.read_text(encoding="ascii"))
                self.assertTrue(len(pids) == children, "nested custody record incomplete")
                root_pid = int(wrapper_pid.read_text(encoding="ascii"))
                if force_group_denial:
                    lines = stderr.decode("ascii").splitlines()
                    prefix = "verifier owned session custody retained: "
                    selected = [line[len(prefix):] for line in lines if line.startswith(prefix)]
                    self.assertTrue(len(selected) == 1, "unconfirmed cleanup lost explicit custody")
                    custody = Path(selected[0]).resolve()
                    self.assertTrue(custody.parent == Path(tempfile.gettempdir()).resolve(), "custody escaped private temporary root")
                    self.assertTrue(not custody.is_symlink() and custody.is_dir(), "custody is unavailable")
                    self.assertTrue(custody.stat().st_mode & 0o077 == 0, "custody directory is not private")
                    rows = [json.loads(path.read_text(encoding="ascii")) for path in custody.iterdir()]
                    self.assertTrue(all(set(row) == {"pid", "parent_pid"} for row in rows), "custody retained unknown fields")
                    self.assertTrue({row["pid"] for row in rows} == set(pids + [root_pid]), "custody omitted owned nested groups")
                else:
                    self.assertTrue(all(absent(pid) for pid in pids), "registered nested group survived wrapper exit")
                    self.assertTrue(absent(root_pid), "root group survived wrapper exit")
                self.assertFalse((root / "receipt").exists(), "test mode created package receipts")
                self.assertTrue(b"Traceback" not in stdout + stderr, "unknown child diagnostics escaped")
            finally:
                # Clean only groups from this probe's predeclared identity files.
                pids = json.loads(identities.read_text(encoding="ascii"))
                if wrapper_pid.is_file():
                    pids.append(int(wrapper_pid.read_text(encoding="ascii")))
                for pid in pids:
                    try:
                        os.killpg(pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                if wrapper.poll() is None:
                    os.killpg(wrapper.pid, signal.SIGKILL)
                wrapper.communicate(timeout=3)
                deadline = time.monotonic() + 3
                while time.monotonic() < deadline and not all(absent(pid) for pid in pids):
                    time.sleep(0.02)
                cleanup_confirmed = all(absent(pid) for pid in pids)
                self.assertTrue(cleanup_confirmed, "exact probe-owned group absence unconfirmed; private probe custody retained")
                if custody is not None:
                    # Exact generated custody, never another run's registry.
                    shutil.rmtree(custody)

    def test_overall_timeout_escalates_registered_term_ignoring_child(self) -> None:
        self.exercise(False)

    def test_external_term_drains_two_registered_term_ignoring_sessions(self) -> None:
        self.exercise(True, children=2)

    def test_permission_uncertainty_returns_125_with_safe_nested_custody(self) -> None:
        self.exercise(False, force_group_denial=True)


class ProcessEscalationBranch(unittest.TestCase):
    def load_input(self):
        spec = importlib.util.spec_from_file_location("owned_input_probe", INPUT)
        assert spec and spec.loader
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        return module

    def test_post_kill_wait_and_group_absence_are_required(self) -> None:
        module = self.load_input()
        process = mock.Mock(pid=43210)
        process.wait.side_effect = [subprocess.TimeoutExpired("owned", 0), -9]
        with mock.patch.object(module.os, "killpg", side_effect=[None, None, None, ProcessLookupError]):
            try:
                stopped = module.stop_process_group(process, grace=0)
            except Exception:
                self.fail("escalation raised instead of verifying owned group absence")
        self.assertTrue(stopped, "post-kill group absence was not confirmed")
        self.assertEqual(process.wait.call_count, 2, "killed child was not reaped")

    def test_group_permission_denial_keeps_custody_without_direct_child_fallback(self) -> None:
        module = self.load_input()
        process = mock.Mock(pid=43210)
        module._OWNED_SESSIONS[process.pid] = process
        with mock.patch.object(module.os, "killpg", side_effect=PermissionError):
            self.assertFalse(module.stop_process_group(process), "permission uncertainty was accepted")
        self.assertTrue(process.pid in module._OWNED_SESSIONS, "unconfirmed owned group lost custody")
        self.assertTrue(not process.terminate.called and not process.kill.called,
                        "group uncertainty used a direct-child fallback")

    def test_invalid_registry_is_rejected_before_launch(self) -> None:
        module = self.load_input()
        with tempfile.TemporaryDirectory(prefix="lockspire-registry-control-") as temporary:
            root = Path(temporary)
            target = root / "registry"
            target.mkdir(mode=0o700)
            link = root / "registry-link"
            link.symlink_to(target, target_is_directory=True)
            with mock.patch.dict(os.environ, {"LOCKSPIRE_OWNED_SESSION_REGISTRY": str(link)}), \
                 mock.patch.object(module.subprocess, "Popen") as launch:
                with self.assertRaises(module.PackageInputError):
                    module.start_owned_session([sys.executable, "-c", "pass"])
            self.assertFalse(launch.called, "invalid custody launched a child")


if __name__ == "__main__":
    unittest.main()
