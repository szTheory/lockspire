"""Keep historical verifier proof immutable while active planning advances."""
from pathlib import Path
import hashlib
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts/acceptance/clean_room"))
import verifier_delivery as delivery
from verifier_input_closure import tracked_inputs, committed_hashes, assert_worktree_selection

LIVE = ".planning/phases/177-safe-verifier-maintenance-recovery/177-VERIFICATION.md"
SNAPSHOT = ".planning/phases/177-safe-verifier-maintenance-recovery/history/177-SOURCE-VERIFICATION.md"
ORIGINAL_SHA = "e452a2145d31c41ac766c6fc7c95ea4e75c57884e40b2272fe48213baab9f1ef"


class PlanningEvidenceLifecycle(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lockspire-proof-lifecycle-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.git("init", "-q")
        self.git("config", "user.name", "Lockspire Fixture")
        self.git("config", "user.email", "fixture@example.invalid")
        # Read the authenticated original object, never today's mutable report.
        self.original = subprocess.check_output(
            ("git", "show", "dc3969302152028e2132759eb9edf5a7d260ac39:" + LIVE), cwd=ROOT)
        self.assertEqual(hashlib.sha256(self.original).hexdigest(), ORIGINAL_SHA)
        self.write(LIVE, self.original)
        self.write("lib/provider.ex", b"provider-source\n")
        self.legacy = self.commit()

    def git(self, *args):
        result = subprocess.run(("git", *args), cwd=self.root, stdin=subprocess.DEVNULL,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20)
        self.assertEqual(result.returncode, 0, "private Git fixture failed")
        return result.stdout.decode().strip()

    def write(self, relative, content):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)

    def commit(self):
        self.git("add", "--all")
        self.git("commit", "-qm", "explicit fixture epoch")
        return self.git("rev-parse", "HEAD")

    def migrate(self):
        self.write(SNAPSHOT, self.original)
        self.write(LIVE, b"fresh current report; old execution is not restamped\n")
        return self.commit()

    def test_original_execution_keeps_its_original_path_and_bytes(self):
        self.migrate()
        paths = tracked_inputs(self.root, self.legacy, delivery.PLANNING_INPUTS)
        self.assertIn(LIVE, paths)
        self.assertNotIn(SNAPSHOT, paths)
        hashes = committed_hashes(self.root, self.legacy, delivery.PLANNING_INPUTS)
        self.assertEqual(hashes[LIVE], ORIGINAL_SHA)

    def test_new_source_uses_immutable_snapshot_instead_of_active_report(self):
        current = self.migrate()
        paths = tracked_inputs(self.root, current, delivery.PLANNING_INPUTS)
        self.assertIn(SNAPSHOT, paths)
        self.assertNotIn(LIVE, paths)
        hashes = committed_hashes(self.root, current, delivery.PLANNING_INPUTS)
        self.assertEqual(hashes[SNAPSHOT], ORIGINAL_SHA)
        assert_worktree_selection(self.root, paths, delivery.PLANNING_INPUTS)

    def test_active_report_refresh_is_metadata_but_source_change_is_not(self):
        current = self.migrate()
        self.write(LIVE, b"later verification; still no runtime restamping\n")
        refreshed = self.commit()
        with patch.object(delivery, "ROOT", self.root):
            self.assertTrue(delivery._metadata_only_difference(current, refreshed))
            self.assertFalse(delivery._metadata_only_difference(self.legacy, current))
        self.write("lib/provider.ex", b"changed provider-source\n")
        changed = self.commit()
        with patch.object(delivery, "ROOT", self.root):
            self.assertFalse(delivery._metadata_only_difference(refreshed, changed))

    def test_substituted_snapshot_is_rejected_even_when_committed(self):
        self.migrate()
        self.write(SNAPSHOT, b"substituted historical verdict\n")
        changed = self.commit()
        with self.assertRaises(ValueError):
            committed_hashes(self.root, changed, delivery.PLANNING_INPUTS)

    def test_missing_selected_snapshot_cannot_match_existing_frozen_path_set(self):
        current = self.migrate()
        paths = tracked_inputs(self.root, current, delivery.PLANNING_INPUTS)
        (self.root / SNAPSHOT).unlink()
        self.git("add", "--all")
        with self.assertRaises(ValueError):
            assert_worktree_selection(self.root, paths, delivery.PLANNING_INPUTS)


if __name__ == "__main__":
    unittest.main()
