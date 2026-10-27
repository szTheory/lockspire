"""Adversarial control for nested independently sessioned children."""

from __future__ import annotations

import os
from pathlib import Path
import signal
import subprocess
import sys
import unittest


ROOT = Path(__file__).resolve().parents[2]


class NestedSessionSupervisionTest(unittest.TestCase):
    def test_parent_signal_drains_registered_child_in_its_own_session(self) -> None:
        clean_room = ROOT / "scripts/acceptance/clean_room"
        child_code = "import time; time.sleep(60)"
        parent_code = (
            "import subprocess,sys,time; from package_input import start_owned_session; "
            f"child=start_owned_session([sys.executable, '-c', {child_code!r}], "
            "stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL); "
            "print(child.pid, flush=True); time.sleep(60)"
        )
        environment = dict(os.environ)
        environment["PYTHONPATH"] = str(clean_room)
        parent = subprocess.Popen(
            [sys.executable, "-c", parent_code], cwd=ROOT, env=environment,
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            start_new_session=True, text=True,
        )
        child_pid = None
        try:
            assert parent.stdout is not None
            line = parent.stdout.readline().strip()
            self.assertTrue(line.isdecimal(), "nested child identity was not reported")
            child_pid = int(line)
            parent.stdout.close()
            os.killpg(parent.pid, signal.SIGTERM)
            self.assertEqual(parent.wait(timeout=5), 143)
            with self.assertRaises(ProcessLookupError):
                os.kill(child_pid, 0)
        finally:
            if parent.poll() is None:
                os.killpg(parent.pid, signal.SIGKILL)
                parent.wait(timeout=2)
            if child_pid is not None:
                try:
                    os.killpg(child_pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass


if __name__ == "__main__":
    unittest.main()
