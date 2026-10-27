"""Fast actual executables must not exit before their ownership admission."""

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
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
WRAPPER = ROOT / "scripts/ci/run_verifier_upgrade_proof.sh"
CLEAN_ROOM = ROOT / "scripts/acceptance/clean_room"


def absent(pgid):
    try:
        os.killpg(pgid, 0)
    except ProcessLookupError:
        return True
    except PermissionError:
        pass
    return False


class FastLaunchRegistration(unittest.TestCase):
    def exercise(self, command, *, mix_caller=False, missing_target=False, missing_bootstrap=False,
                 target_marker=False, creator_exits=False):
        root = Path(tempfile.mkdtemp(prefix="lockspire-fast-register-")).resolve()
        identity_file = root / "children.json"
        root_pid_file = root / "root.pid"
        layout = root / "probe-custody.json"
        identity_file.write_text("[]", encoding="ascii")
        layout.write_text(json.dumps({"root": str(root), "identity_file": str(identity_file),
                                      "root_pid_file": str(root_pid_file), "cleanup": "not_started"}), encoding="ascii")
        runner = root / "runner.py"
        marker = root / "target-activated"
        register_hook = ""
        if target_marker or creator_exits:
            command = (sys.executable, "-c", "from pathlib import Path;Path(" + repr(str(marker)) + ").touch()")
            if creator_exits:
                register_hook = "p._register_session=lambda process:os._exit(0)\n"
            else:
                register_hook = (
                    "original_register=p._register_session\n"
                    "def observe_registration(process):\n"
                    f"    if pathlib.Path({str(marker)!r}).exists():raise RuntimeError('early_target')\n"
                    "    original_register(process)\n"
                    f"    if pathlib.Path({str(marker)!r}).exists():raise RuntimeError('early_target')\n"
                    "p._register_session=observe_registration\n"
                )
        if missing_target:
            command = (str(root / "missing-command"),)
        operation = (
            "from build_provider import _run_mix\n_run_mix(pathlib.Path(" + repr(str(ROOT)) + "),dict(os.environ),('--version',))\n"
            if mix_caller else
            "completed=p.bounded_run(" + repr(tuple(command)) + ",cwd=pathlib.Path(" + repr(str(ROOT)) + "),stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=8)\n"
            "if completed.returncode: raise SystemExit(7)\n"
        )
        if missing_target or missing_bootstrap:
            expected_file = str(root / ("missing-interpreter" if missing_bootstrap else "missing-command"))
            if missing_bootstrap:
                operation = "p.sys.executable=" + repr(expected_file) + "\n" + operation
            operation = ("try:\n" + "".join("    " + line + "\n" for line in operation.splitlines())
                         + "except FileNotFoundError as error:\n"
                         + "    if error.errno!=2 or error.filename!=" + repr(expected_file) + ": raise SystemExit(9)\n"
                         + "else: raise SystemExit(8)\n")
        runner.write_text(
            "import json,os,pathlib,subprocess,sys\n"
            f"sys.path.insert(0,{str(CLEAN_ROOM)!r})\n"
            "import package_input as p\n"
            "original=p.subprocess.Popen\n"
            "pids=[]\n"
            "def capture(*args,**kwargs):\n"
            "    child=original(*args,**kwargs)\n"
            "    pids.append(child.pid)\n"
            f"    pathlib.Path({str(identity_file)!r}).write_text(json.dumps(pids),encoding='ascii')\n"
            "    return child\n"
            "p.subprocess.Popen=capture\n"
            + register_hook + operation, encoding="ascii",
        )
        environment = dict(os.environ, PYTHONDONTWRITEBYTECODE="1",
            LOCKSPIRE_VERIFIER_TEST_MODE="1", LOCKSPIRE_VERIFIER_TEST_RUNNER=str(runner),
            LOCKSPIRE_VERIFIER_TEST_PYTHON=sys.executable, LOCKSPIRE_VERIFIER_TEST_TIMEOUT="12",
            LOCKSPIRE_VERIFIER_TEST_OVERALL_TIMEOUT="15", LOCKSPIRE_VERIFIER_TEST_PID_FILE=str(root_pid_file))
        wrapper = subprocess.Popen(["bash", str(WRAPPER), "--pair", "locked", "--receipt-dir", str(root / "receipts"), "--test-mode"],
            cwd=ROOT, env=environment, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            start_new_session=True)
        layout.write_text(json.dumps({"root": str(root), "wrapper_pgid": wrapper.pid,
                                      "identity_file": str(identity_file), "root_pid_file": str(root_pid_file)}), encoding="ascii")
        custody = None
        try:
            stdout, stderr = wrapper.communicate(timeout=35)
            prefix = "verifier owned session custody retained: "
            choices = [row[len(prefix):] for row in stderr.decode("ascii", errors="replace").splitlines() if row.startswith(prefix)]
            if choices:
                custody = Path(choices[0]).resolve()
                layout.write_text(json.dumps({"root": str(root), "wrapper_pgid": wrapper.pid,
                    "identity_file": str(identity_file), "root_pid_file": str(root_pid_file), "custody": str(custody)}), encoding="ascii")
            self.assertTrue(wrapper.returncode == (125 if creator_exits else 78), "actual fast command did not complete registered supervision")
            if creator_exits:
                self.assertTrue(bool(choices), "creator exit lost pending custody")
                self.assertFalse(marker.exists(), "unacknowledged target ran after creator death")
            else:
                self.assertFalse(choices, "completed fast child retained a pending launch")
                if target_marker:
                    self.assertTrue(marker.exists(), "acknowledged target never activated")
            self.assertFalse((root / "receipts").exists(), "nonaccepting launch test created package evidence")
            self.assertTrue(b"Traceback" not in stdout + stderr, "raw child diagnostics escaped wrapper")
        finally:
            if wrapper.poll() is None:
                wrapper.send_signal(signal.SIGTERM)
                wrapper.communicate(timeout=22)
            pids = json.loads(identity_file.read_text(encoding="ascii"))
            if root_pid_file.exists():
                pids.append(int(root_pid_file.read_text(encoding="ascii")))
            pids.append(wrapper.pid)
            deadline = time.monotonic() + 3
            while time.monotonic() < deadline and not all(absent(pid) for pid in pids):
                time.sleep(0.02)
            reconciled = all(absent(pid) for pid in pids)
            self.assertTrue(reconciled, "exact fast-launch probe groups unresolved; private custody retained")
            if custody is not None:
                self.assertTrue(custody.parent == Path(tempfile.gettempdir()).resolve()
                                and custody.name.startswith("lockspire-verifier-owned-")
                                and not custody.is_symlink(), "unexpected retained custody path")
                shutil.rmtree(custody)
            shutil.rmtree(root)

    def test_actual_fast_true_completes_cold_supervised_launch(self):
        self.exercise(("/usr/bin/true",))

    def test_actual_fast_git_completes_cold_supervised_launch(self):
        self.exercise(("git", "rev-parse", "HEAD"))

    def test_actual_pg_version_completes_without_any_database_connection(self):
        self.exercise(("pg_isready", "--version"))

    def test_actual_mix_caller_version_preserves_supervised_behavior(self):
        self.exercise(("mix", "--version"), mix_caller=True)

    def test_missing_target_preserves_exec_errno_and_registered_cleanup(self):
        self.exercise((), missing_target=True)

    def test_missing_bootstrap_cancels_only_uncreated_child_reservation(self):
        self.exercise(("/usr/bin/true",), missing_bootstrap=True)

    def test_target_has_no_side_effect_before_registration_ack(self):
        self.exercise((), target_marker=True)

    def test_creator_exit_before_registration_never_activates_target(self):
        self.exercise((), creator_exits=True)


class GatedLaunchSemantics(unittest.TestCase):
    def test_untrusted_preexec_callback_is_rejected_before_launch(self):
        sys.path.insert(0, str(CLEAN_ROOM))
        import package_input as package
        with mock.patch.object(package.subprocess, "Popen") as launch:
            with self.assertRaises(package.PackageInputError):
                package.start_owned_session(("/usr/bin/true",), preexec_fn=lambda: None)
        self.assertFalse(launch.called, "preexec callback entered the trusted launcher")

    def test_restore_signals_preserves_sigpipe_behavior(self):
        sys.path.insert(0, str(CLEAN_ROOM))
        import package_input as package
        previous = signal.getsignal(signal.SIGPIPE)
        signal.signal(signal.SIGPIPE, signal.SIG_IGN)
        try:
            for restore, expected in ((True, -signal.SIGPIPE), (False, 7)):
                process = package.start_owned_session(("/bin/sh", "-c", "kill -PIPE $$; exit 7"),
                    stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                    restore_signals=restore)
                try:
                    self.assertTrue(process.wait(timeout=3) == expected, "exec gate changed restore_signals behavior")
                finally:
                    self.assertTrue(package.stop_process_group(process), "signal-semantics probe cleanup unconfirmed")
        finally:
            signal.signal(signal.SIGPIPE, previous)

    def test_stdio_cwd_env_passed_fd_and_kernel_identity_survive_exec(self):
        sys.path.insert(0, str(CLEAN_ROOM))
        import package_input as package
        with tempfile.TemporaryDirectory(prefix="lockspire-launch-semantics-") as temporary:
            reader, writer = os.pipe()
            os.write(writer, b"fd-input")
            os.close(writer)
            command = (sys.executable, "-c",
                "import json,os,sys;print(json.dumps({'stdin':sys.stdin.read()=='stdin-input',"
                "'cwd':os.getcwd()==sys.argv[1],'env':os.environ['LOCKSPIRE_LAUNCH_MARKER']=='environment-input',"
                "'fd':os.read(int(sys.argv[2]),32)==b'fd-input','session':os.getsid(0)==os.getpid(),"
                "'group':os.getpgrp()==os.getpid()}));print('stderr-output',file=sys.stderr)",
                str(Path(temporary).resolve()), str(reader))
            process = package.start_owned_session(command, cwd=temporary,
                env=dict(os.environ, LOCKSPIRE_LAUNCH_MARKER="environment-input"),
                stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                text=True, pass_fds=(reader,))
            try:
                self.assertTrue(process.args == command, "Popen args changed at the exec gate")
                original = package._OWNED_IDENTITIES[process.pid]
                self.assertTrue(original.same_process(package.owned_process_identity(process.pid)),
                                "exec changed admitted PID/session/creation identity")
                stdout, stderr = process.communicate("stdin-input", timeout=5)
                facts = json.loads(stdout)
                self.assertTrue(all(facts.values()), "exec gate changed requested launch semantics")
                self.assertTrue(stderr == "stderr-output\n", "stderr transport changed")
                self.assertTrue(process.returncode == 0, "semantic child did not complete")
            finally:
                os.close(reader)
                self.assertTrue(package.stop_process_group(process), "semantic probe cleanup unconfirmed")


if __name__ == "__main__":
    unittest.main()
