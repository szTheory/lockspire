"""Fail-closed contracts for the pair-scoped installed verifier CI wrapper."""

from __future__ import annotations

import os
from pathlib import Path
import re
import signal
import shutil
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
WRAPPER = ROOT / "scripts" / "ci" / "run_verifier_upgrade_proof.sh"


class VerifierCiWrapperContracts(unittest.TestCase):
    def test_ci_installs_the_reviewed_package_builder_before_using_mix(self) -> None:
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        self.assertIn('  HEX_VERSION: "2.6.0"\n', workflow)
        jobs = re.split(r"(?m)^  ([a-z][a-z0-9_-]*):\n", workflow.split("\njobs:\n", 1)[1])
        beam_jobs = []
        for name, body in zip(jobs[1::2], jobs[2::2]):
            steps = body.split("\n      - name: ")
            for index, step in enumerate(steps):
                if "uses: erlef/setup-beam@" not in step:
                    continue
                beam_jobs.append(name)
                self.assertIn("install-hex: false", step, name)
                self.assertLess(index + 1, len(steps), name)
                self.assertIn('run: mix local.hex "$HEX_VERSION" --force', steps[index + 1], name)
        self.assertCountEqual(beam_jobs, ["dialyzer", "fast", "compatibility", "integration", "coverage-aggregate", "adoption-demo"])

    def test_existing_pair_jobs_provision_explicit_pins_and_upload_validated_raw_receipts(self) -> None:
        workflow = (ROOT / ".github/workflows/ci.yml").read_text(encoding="utf-8")
        wrapper = WRAPPER.read_text(encoding="utf-8")
        self.assertEqual(workflow.count("- name: Provision authenticated verifier candidate inputs"), 2)
        self.assertIn("EXPECTED_RUNNER_REVISION: ${{ github.sha }}", workflow)
        self.assertIn("--expected-candidate-source \"$EXPECTED_CANDIDATE_SOURCE\"", workflow)
        for flag in ("--expected-runner", "--expected-candidate-source", "--expected-archive-sha256",
                     "--expected-tree-sha256", "--expected-manifest-sha256"):
            self.assertIn(flag, workflow)
        self.assertEqual(workflow.count("path: .artifacts/phase178/ci-"), 2)
        self.assertEqual(workflow.count("/validated/**"), 2)
        self.assertIn('"lockspire-validated-raw-copies-v1"', wrapper)
        self.assertIn('digest != cell["receipt_sha256"]', wrapper)

    def test_wrapper_is_an_executable_maintained_entrypoint(self) -> None:
        self.assertTrue(WRAPPER.is_file(), "pair proof wrapper must exist")
        self.assertTrue(os.access(WRAPPER, os.X_OK), "pair proof wrapper must be executable")

    def invoke(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ("bash", str(WRAPPER), *arguments), cwd=ROOT, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
        )

    def temporary_repo(self):
        temporary = tempfile.TemporaryDirectory(prefix="lockspire-verifier-wrapper-repo-")
        root = Path(temporary.name)
        subprocess.run(("git", "init", "--quiet"), cwd=root, check=True)
        subprocess.run(("git", "-c", "user.name=Lockspire Test", "-c", "user.email=lockspire-test@example.invalid",
                        "commit", "--allow-empty", "--quiet", "-m", "wrapper test root"), cwd=root, check=True)
        wrapper = root / "scripts" / "ci" / WRAPPER.name
        wrapper.parent.mkdir(parents=True)
        shutil.copy2(WRAPPER, wrapper)
        (root / "scripts" / "acceptance").mkdir(parents=True)
        (root / "scripts" / "acceptance" / "clean_room_verifier_upgrade.py").write_text("# test sentinel\n", encoding="utf-8")
        return temporary, root

    def fake_invocation(self, body: str, *, timeout: int = 2, overall_timeout: int = 10,
                        pid_file: Path | None = None, grandchild_pid_file: Path | None = None,
                        force_group_denial: bool = False):
        temporary = tempfile.TemporaryDirectory(prefix="lockspire-verifier-fake-")
        root = Path(temporary.name).resolve()
        fake = root / "fake-runner.py"
        fake.write_text("#!/usr/bin/env python3\n" + body, encoding="utf-8")
        fake.chmod(0o700)
        receipt_dir = root / "phase178" / "test-only"
        environment = dict(os.environ)
        environment.update({
            "LOCKSPIRE_VERIFIER_TEST_MODE": "1",
            "LOCKSPIRE_VERIFIER_TEST_RUNNER": str(fake),
            "LOCKSPIRE_VERIFIER_TEST_TIMEOUT": str(timeout),
            "LOCKSPIRE_VERIFIER_TEST_OVERALL_TIMEOUT": str(overall_timeout),
            "LOCKSPIRE_VERIFIER_TEST_PYTHON": sys.executable,
        })
        if pid_file is not None:
            environment["LOCKSPIRE_VERIFIER_TEST_PID_FILE"] = str(pid_file)
        if grandchild_pid_file is not None:
            environment["LOCKSPIRE_VERIFIER_TEST_GRANDCHILD_PID_FILE"] = str(grandchild_pid_file)
        if force_group_denial:
            environment["LOCKSPIRE_VERIFIER_TEST_FORCE_GROUP_DENIAL"] = "1"
        process = subprocess.Popen(
            ("bash", str(WRAPPER), "--pair", "locked", "--receipt-dir", str(receipt_dir), "--test-mode"),
            cwd=ROOT, env=environment, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
        return temporary, process, receipt_dir

    def test_wrong_pair_fails_before_creating_any_receipt_path(self) -> None:
        with tempfile.TemporaryDirectory(prefix="lockspire-verifier-ci-") as temporary:
            destination = Path(temporary) / "receipts"
            result = self.invoke("--pair", "mystery", "--receipt-dir", str(destination))
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(destination.exists())
            self.assertTrue("client_secret" not in result.stdout + result.stderr,
                            "captured child output must remain private")

    def test_unsafe_and_stale_production_paths_fail_before_mutation(self) -> None:
        temporary, root = self.temporary_repo()
        try:
            traversal = subprocess.run(
                ("bash", str(root / "scripts/ci" / WRAPPER.name), "--pair", "locked",
                 "--receipt-dir", ".artifacts/phase178/../escape"), cwd=root, text=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
            )
            self.assertNotEqual(traversal.returncode, 0)
            destination = root / ".artifacts/phase178/ci-locked"
            destination.mkdir(mode=0o700, parents=True)
            marker = destination / "preserve-me"
            marker.write_text("existing", encoding="utf-8")
            stale = subprocess.run(
                ("bash", str(root / "scripts/ci" / WRAPPER.name), "--pair", "locked",
                 "--receipt-dir", ".artifacts/phase178/ci-locked"), cwd=root, text=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
            )
            self.assertNotEqual(stale.returncode, 0)
            self.assertEqual(marker.read_text(encoding="utf-8"), "existing")
        finally:
            temporary.cleanup()

    def test_symlink_destination_is_rejected_and_left_untouched(self) -> None:
        temporary, root = self.temporary_repo()
        try:
            destination = root / ".artifacts/phase178/ci-locked"
            destination.parent.mkdir(parents=True)
            target = root / "owned-target"
            target.mkdir()
            destination.symlink_to(target, target_is_directory=True)
            result = subprocess.run(
                ("bash", str(root / "scripts/ci" / WRAPPER.name), "--pair", "locked",
                 "--receipt-dir", ".artifacts/phase178/ci-locked"), cwd=root, text=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(list(target.iterdir()), [])
        finally:
            temporary.cleanup()

    def test_fake_child_failure_is_redacted_and_never_creates_receipts(self) -> None:
        temporary, process, receipt_dir = self.fake_invocation("import sys\nprint('SECRET_SENTINEL', file=sys.stderr)\nsys.exit(7)\n")
        try:
            stdout, stderr = process.communicate(timeout=8)
            self.assertNotEqual(process.returncode, 0)
            self.assertTrue("SECRET_SENTINEL" not in stdout + stderr,
                            "captured child output must remain private")
            self.assertFalse(receipt_dir.exists())
        finally:
            temporary.cleanup()

    def test_fake_child_timeout_and_signal_report_group_cleanup_status(self) -> None:
        temporary, process, receipt_dir = self.fake_invocation("import time\ntime.sleep(15)\n", timeout=1)
        try:
            _stdout, stderr = process.communicate(timeout=8)
            self.assertTrue(process.returncode in {124, 125}, "timeout exit code must be bounded")
            if process.returncode == 124:
                self.assertTrue("timeout" in stderr, "timeout failure should be identified")
            else:
                self.assertTrue("cleanup unconfirmed" in stderr, "cleanup failure should be identified")
            self.assertFalse(receipt_dir.exists())
        finally:
            temporary.cleanup()

        with tempfile.TemporaryDirectory(prefix="lockspire-verifier-signal-") as signal_root:
            pid_file = Path(signal_root) / "child.pid"
            temporary, process, receipt_dir = self.fake_invocation(
                "import time\ntime.sleep(15)\n", timeout=9, pid_file=pid_file,
            )
            try:
                deadline = time.monotonic() + 5
                while time.monotonic() < deadline and not pid_file.is_file():
                    time.sleep(0.05)
                self.assertTrue(pid_file.is_file(), "test child should start")
                child_pid = int(pid_file.read_text(encoding="ascii"))
                process.send_signal(signal.SIGTERM)
                _stdout, signal_stderr = process.communicate(timeout=8)
                self.assertIn(process.returncode, {125, 143})
                if process.returncode == 125:
                    self.assertTrue("cleanup unconfirmed" in signal_stderr,
                                    "signal cleanup failure should be identified")
                with self.assertRaises(ProcessLookupError):
                    os.kill(child_pid, 0)
                self.assertFalse(receipt_dir.exists())
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait(timeout=2)
                temporary.cleanup()

    def test_fake_success_cannot_satisfy_package_or_ci_receipt_acceptance(self) -> None:
        temporary, process, receipt_dir = self.fake_invocation("print('fake success')\n")
        try:
            stdout, stderr = process.communicate(timeout=8)
            self.assertEqual(process.returncode, 78)
            self.assertTrue("fake success" not in stdout + stderr,
                            "captured child output must remain private")
            self.assertTrue("cannot create or validate" in stderr,
                            "invalid receipt destination should be rejected")
            self.assertFalse(receipt_dir.exists())
        finally:
            temporary.cleanup()

    def test_overall_deadline_bounds_child_below_its_individual_limit(self) -> None:
        temporary, process, receipt_dir = self.fake_invocation(
            "import time\ntime.sleep(15)\n", timeout=2, overall_timeout=1,
        )
        started = time.monotonic()
        try:
            _stdout, stderr = process.communicate(timeout=6)
            elapsed = time.monotonic() - started
            self.assertTrue(process.returncode in {124, 125}, "overall timeout exit code must be bounded")
            self.assertTrue("overall" in stderr, "overall timeout should be identified")
            if process.returncode == 125:
                self.assertTrue("cleanup unconfirmed" in stderr, "cleanup failure should be identified")
            self.assertLess(elapsed, 1.8)
            self.assertFalse(receipt_dir.exists())
        finally:
            if process.poll() is None:
                process.kill()
                process.wait(timeout=2)
            temporary.cleanup()

    def test_unconfirmed_process_group_cleanup_fails_even_after_direct_child_exit(self) -> None:
        with tempfile.TemporaryDirectory(prefix="lockspire-verifier-grandchild-") as temporary_root:
            grandchild_pid_file = Path(temporary_root) / "grandchild.pid"
            root_pid_file = Path(temporary_root) / "wrapper-root.pid"
            body = (
                "import os, subprocess, sys, time\n"
                "grandchild = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(15)'])\n"
                "open(os.environ['LOCKSPIRE_VERIFIER_TEST_GRANDCHILD_PID_FILE'], 'w').write(str(grandchild.pid))\n"
                "time.sleep(15)\n"
            )
            temporary, process, receipt_dir = self.fake_invocation(
                body, timeout=1, overall_timeout=10, grandchild_pid_file=grandchild_pid_file,
                pid_file=root_pid_file, force_group_denial=True,
            )
            try:
                _stdout, stderr = process.communicate(timeout=8)
                self.assertTrue(process.returncode == 125, "forced process-group denial must fail closed")
                self.assertTrue("cleanup unconfirmed" in stderr, "cleanup failure should be identified")
                self.assertFalse(receipt_dir.exists())
                wrapper_root_pid = int(root_pid_file.read_text(encoding="ascii"))
                grandchild_pid = int(grandchild_pid_file.read_text(encoding="ascii"))
                custody_prefix = "verifier owned session custody retained: "
                custody_line = next((line for line in stderr.splitlines()
                                     if line.startswith(custody_prefix)), None)
                self.assertTrue(custody_line is not None, "retained cleanup custody should be identified")
                custody_registry = Path(custody_line[len(custody_prefix):])
                self.assertTrue(
                    custody_registry.parent == Path(tempfile.gettempdir())
                    and custody_registry.name.startswith("lockspire-verifier-owned-")
                    and custody_registry.is_dir(),
                    "retained cleanup custody must be a private test-owned registry",
                )
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait(timeout=2)
                for owned_pid in (locals().get("grandchild_pid"), locals().get("wrapper_root_pid")):
                    if owned_pid is not None:
                        try:
                            os.kill(owned_pid, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                deadline = time.monotonic() + 2
                while time.monotonic() < deadline:
                    live = []
                    for owned_pid in (locals().get("grandchild_pid"), locals().get("wrapper_root_pid")):
                        if owned_pid is None:
                            continue
                        try:
                            os.kill(owned_pid, 0)
                            live.append(owned_pid)
                        except ProcessLookupError:
                            pass
                    if not live:
                        break
                    time.sleep(0.05)
                else:
                    self.fail("test-owned wrapper and descendant did not stop after exact-PID cleanup")
                if locals().get("custody_registry") is not None:
                    for record in custody_registry.iterdir():
                        self.assertTrue(record.name.removesuffix(".json").isdecimal(),
                                        "private custody registry must contain numeric PID records")
                    shutil.rmtree(custody_registry)
                temporary.cleanup()


if __name__ == "__main__":
    unittest.main()
