"""Contracts for installed verifier recovery and stale-identity issuance proofs."""

from __future__ import annotations

import sys
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))

import clean_room_verifier_upgrade  # noqa: E402
import verifier_recovery  # noqa: E402
from package_input import PackageInputError  # noqa: E402


class RecoveryDispatchTest(unittest.TestCase):
    def test_recovery_and_issuance_groups_share_the_owned_recovery_runner(self) -> None:
        self.assertEqual(
            clean_room_verifier_upgrade.MODULES["issuance"][0],
            clean_room_verifier_upgrade.MODULES["recovery"][0],
        )
        self.assertNotEqual(
            clean_room_verifier_upgrade.MODULES["issuance"][1],
            clean_room_verifier_upgrade.MODULES["recovery"][1],
        )

    def test_child_failure_reduces_nested_secret_bearing_exception_to_fixed_reason(self) -> None:
        child_code = (
            "import secrets,sys; "
            "secret='child-'+secrets.token_hex(16); "
            "print('CHILD_GENERATED_SENTINEL='+secret); "
            "print('CHILD_STDERR_SENTINEL='+secret,file=sys.stderr); "
            "raise RuntimeError(repr({'client': {'client_secret': secret, 'metadata': {'secret': secret}}}))"
        )
        generated_secrets: list[str] = []
        child_streams: list[str] = []

        def child_failure() -> str:
            completed = subprocess.run(
                [sys.executable, "-c", child_code],
                text=True,
                capture_output=True,
                check=False,
            )
            child_streams.extend((completed.stdout, completed.stderr))
            generated_secrets.extend(
                line.removeprefix("CHILD_GENERATED_SENTINEL=")
                for line in completed.stdout.splitlines()
                if line.startswith("CHILD_GENERATED_SENTINEL=")
            )
            generated_secrets.extend(
                line.removeprefix("CHILD_STDERR_SENTINEL=")
                for line in completed.stderr.splitlines()
                if line.startswith("CHILD_STDERR_SENTINEL=")
            )
            raise RuntimeError(repr({"child_stdout": completed.stdout, "child_stderr": completed.stderr}))

        with tempfile.TemporaryDirectory() as owned_output:
            with self.assertRaises(PackageInputError) as caught:
                verifier_recovery._capture_child_output(child_failure)
            self.assertEqual(list(Path(owned_output).iterdir()), [])

        self.assertEqual(
            str(caught.exception),
            "installed verifier host scenario failed; child diagnostics withheld",
        )
        self.assertEqual(len(generated_secrets), 2)
        self.assertTrue(all(secret not in str(caught.exception) for secret in generated_secrets))
        self.assertIn("CHILD_GENERATED_SENTINEL=", child_streams[0])
        self.assertIn("CHILD_STDERR_SENTINEL=", child_streams[1])


if __name__ == "__main__":
    unittest.main()
