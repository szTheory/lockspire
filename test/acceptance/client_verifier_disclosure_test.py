"""Contracts for installed verifier disclosure evidence."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))

import clean_room_verifier_upgrade as runner  # noqa: E402
import verifier_receipts  # noqa: E402
from build_provider import PROVIDER_TEMPLATE  # noqa: E402


class VerifierDisclosureContracts(unittest.TestCase):
    def test_disclosure_group_owns_a_real_host_capture_fixture(self) -> None:
        self.assertEqual(
            runner.MODULES["disclosure"],
            ("verifier_disclosure", "run_group"),
        )
        fixture = (
            PROVIDER_TEMPLATE
            / "lib"
            / "clean_room_provider"
            / "verifier_disclosure.ex"
        )
        self.assertTrue(
            fixture.is_file(),
            "disclosure proof must capture owned runtime channels in the generated host",
        )

    def test_disclosure_receipt_requires_nonempty_pair_specific_channel_witnesses(self) -> None:
        case_ids = getattr(verifier_receipts, "DISCLOSURE_CASE_IDS", None)
        self.assertEqual(
            case_ids,
            {
                "locked": [
                    "VPROOF-02-DISCLOSURE-LOCKED-SUCCESS",
                    "VPROOF-02-DISCLOSURE-LOCKED-CRYPTO-FAILURE",
                    "VPROOF-02-DISCLOSURE-LOCKED-STORAGE-FAILURE",
                ],
                "floor": [
                    "VPROOF-02-DISCLOSURE-FLOOR-SUCCESS",
                    "VPROOF-02-DISCLOSURE-FLOOR-CRYPTO-FAILURE",
                    "VPROOF-02-DISCLOSURE-FLOOR-STORAGE-FAILURE",
                ],
            },
        )


if __name__ == "__main__":
    unittest.main()
