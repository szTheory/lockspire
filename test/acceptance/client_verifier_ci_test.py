"""Fail-closed contracts for the pair-scoped installed verifier CI wrapper."""

from __future__ import annotations

import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
WRAPPER = ROOT / "scripts" / "ci" / "run_verifier_upgrade_proof.sh"


class VerifierCiWrapperContracts(unittest.TestCase):
    def test_wrapper_is_an_executable_maintained_entrypoint(self) -> None:
        self.assertTrue(WRAPPER.is_file(), "pair proof wrapper must exist")
        self.assertTrue(os.access(WRAPPER, os.X_OK), "pair proof wrapper must be executable")

    def invoke(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ("bash", str(WRAPPER), *arguments), cwd=ROOT, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
        )

    def fake_invocation(self, body: str, *, timeout: int = 2, pid_file: Path | None = None):
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
            "LOCKSPIRE_VERIFIER_TEST_PYTHON": sys.executable,
        })
        if pid_file is not None:
            environment["LOCKSPIRE_VERIFIER_TEST_PID_FILE"] = str(pid_file)
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
            self.assertNotIn("client_secret", result.stdout + result.stderr)

    def test_unsafe_and_stale_production_paths_fail_before_mutation(self) -> None:
        traversal = self.invoke("--pair", "locked", "--receipt-dir", ".artifacts/phase178/../escape")
        self.assertNotEqual(traversal.returncode, 0)
        destination = ROOT / ".artifacts/phase178/ci-locked"
        if destination.exists() or destination.is_symlink():
            self.skipTest("the canonical local locked proof destination is already owned")
        destination.mkdir(mode=0o700)
        marker = destination / "preserve-me"
        marker.write_text("existing", encoding="utf-8")
        try:
            stale = self.invoke("--pair", "locked", "--receipt-dir", ".artifacts/phase178/ci-locked")
            self.assertNotEqual(stale.returncode, 0)
            self.assertEqual(marker.read_text(encoding="utf-8"), "existing")
        finally:
            marker.unlink()
            destination.rmdir()

    def test_symlink_destination_is_rejected_and_left_untouched(self) -> None:
        destination = ROOT / ".artifacts/phase178/ci-locked"
        if destination.exists() or destination.is_symlink():
            self.skipTest("the canonical local locked proof destination is already owned")
        target = Path(tempfile.mkdtemp(prefix="lockspire-verifier-link-target-"))
        try:
            destination.symlink_to(target, target_is_directory=True)
            result = self.invoke("--pair", "locked", "--receipt-dir", ".artifacts/phase178/ci-locked")
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(list(target.iterdir()), [])
        finally:
            if destination.is_symlink():
                destination.unlink()
            target.rmdir()

    def test_fake_child_failure_is_redacted_and_never_creates_receipts(self) -> None:
        temporary, process, receipt_dir = self.fake_invocation("import sys\nprint('SECRET_SENTINEL', file=sys.stderr)\nsys.exit(7)\n")
        try:
            stdout, stderr = process.communicate(timeout=8)
            self.assertNotEqual(process.returncode, 0)
            self.assertNotIn("SECRET_SENTINEL", stdout + stderr)
            self.assertFalse(receipt_dir.exists())
        finally:
            temporary.cleanup()

    def test_fake_child_timeout_and_signal_stop_its_process_group(self) -> None:
        temporary, process, receipt_dir = self.fake_invocation("import time\ntime.sleep(15)\n", timeout=1)
        try:
            _stdout, stderr = process.communicate(timeout=8)
            self.assertEqual(process.returncode, 124, stderr)
            self.assertIn("timeout", stderr)
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
                process.communicate(timeout=8)
                self.assertEqual(process.returncode, 143)
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
            self.assertNotIn("fake success", stdout + stderr)
            self.assertIn("cannot create or validate", stderr)
            self.assertFalse(receipt_dir.exists())
        finally:
            temporary.cleanup()


if __name__ == "__main__":
    unittest.main()
