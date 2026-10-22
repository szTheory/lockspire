"""Boundary tests for retained client-lifetime proof output."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import sys
import unittest


CLEAN_ROOM = Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"
sys.path.insert(0, str(CLEAN_ROOM))
import redaction  # noqa: E402


class LifetimeRedactionTest(unittest.TestCase):
    def test_safe_failure_summary_is_allowlisted(self) -> None:
        summary = getattr(redaction, "safe_failure_summary", None)
        self.assertTrue(callable(summary), "redaction module must expose safe failure summaries")


if __name__ == "__main__":
    unittest.main()
