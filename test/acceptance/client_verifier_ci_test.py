"""Fail-closed contracts for the pair-scoped installed verifier CI wrapper."""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
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


if __name__ == "__main__":
    unittest.main()
