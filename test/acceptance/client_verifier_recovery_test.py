"""Contracts for installed verifier recovery and stale-identity issuance proofs."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))

import clean_room_verifier_upgrade  # noqa: E402


class RecoveryDispatchTest(unittest.TestCase):
    def test_recovery_and_issuance_groups_share_the_owned_recovery_runner(self) -> None:
        self.assertEqual(
            clean_room_verifier_upgrade.MODULES["issuance"],
            clean_room_verifier_upgrade.MODULES["recovery"],
        )


if __name__ == "__main__":
    unittest.main()
