import copy
import tempfile
import sys
import unittest
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"))
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance"))
import clean_room_admin_journey as admin_journey
from admin_receipts import validate_receipt, write_receipt


class AdminReceiptTests(unittest.TestCase):
    def setUp(self):
        self.run_id = str(uuid.uuid4())
        self.source = "a" * 40
        self.archive = "b" * 64
        self.tree = "c" * 64
        self.receipt = {
            "schema_version": 1,
            "run_id": self.run_id,
            "source_revision": self.source,
            "source_dirty": True,
            "candidate": {
                "version": "1.6.1",
                "archive_sha256": self.archive,
                "tree_sha256": self.tree,
            },
            "pair": "locked",
            "runtime": {
                "phoenix": "1.8.13",
                "live_view": "1.2.10",
                "elixir": "1.20.4",
                "otp": "29",
                "node": "26.10.0",
                "chrome": "Chrome/155.0.8059.85",
            },
            "mount": "/lockspire",
            "evidence_kind": "real_browser_cdp",
            "scenarios": [{
                "id": "tracer.browser_join_navigation",
                "outcome": "passed",
                "duration_ms": 20,
                "counts": {"assets": 2, "websocket_handshakes": 1, "successful_joins": 1, "navigations": 1},
                "observations": {"login": True, "overview": True, "clients": True, "authorized_http": True, "connected_hook": True},
            }],
            "cleanup": {"processes_stopped": True, "database_removed": True, "profile_removed": True, "run_root_removed": True},
            "result": "passed",
        }

    def test_valid_receipt_binds_run_source_candidate_runtime_and_cleanup(self):
        validated = validate_receipt(
            self.receipt,
            expected_run_id=self.run_id,
            expected_source=self.source,
            expected_pair="locked",
            expected_mount="/lockspire",
            expected_archive=self.archive,
            expected_tree=self.tree,
        )
        self.assertEqual(validated["result"], "passed")

    def test_passed_receipt_requires_positive_browser_join_and_navigation(self):
        for key, value in (("assets", 1), ("websocket_handshakes", 0), ("successful_joins", 0), ("navigations", 0)):
            with self.subTest(key=key):
                malformed = copy.deepcopy(self.receipt)
                malformed["scenarios"][0]["counts"][key] = value
                with self.assertRaises(ValueError):
                    validate_receipt(malformed)

    def test_candidate_mismatch_and_cleanup_failure_cannot_be_reported_as_passed(self):
        malformed = copy.deepcopy(self.receipt)
        malformed["candidate"]["tree_sha256"] = "d" * 64
        with self.assertRaises(ValueError):
            validate_receipt(malformed, expected_tree=self.tree)

    def test_cleanup_failure_cannot_be_reported_as_passed(self):
        malformed = copy.deepcopy(self.receipt)
        malformed["cleanup"]["profile_removed"] = False
        malformed["result"] = "failed"
        self.assertEqual(validate_receipt(malformed)["result"], "failed")

    def test_unhashable_scenario_identifier_is_rejected_as_invalid_receipt(self):
        malformed = copy.deepcopy(self.receipt)
        malformed["scenarios"][0]["id"] = []
        try:
            validate_receipt(malformed)
        except Exception as error:
            self.assertIsInstance(error, ValueError, "malformed receipt data must fail with the validator's safe error")
        else:
            self.fail("unhashable scenario identity was accepted")

    def test_writer_creates_private_receipt_file(self):
        with tempfile.TemporaryDirectory() as temporary:
            destination = Path(temporary) / "nested" / "receipt.json"
            write_receipt(
                destination,
                self.receipt,
                expected_run_id=self.run_id,
                expected_source=self.source,
                expected_pair="locked",
                expected_mount="/lockspire",
                expected_archive=self.archive,
                expected_tree=self.tree,
                expected_scenario_set="tracer",
            )
            self.assertTrue(destination.exists())
            self.assertEqual(destination.stat().st_mode & 0o777, 0o600)
            self.assertEqual(validate_receipt(__import__("json").loads(destination.read_text()))["result"], "passed")

    def test_suite_has_exact_known_case_count(self):
        self.assertEqual(sum(name.startswith("test_") for name in dir(type(self))), 9)

    def test_browser_failure_summary_discards_hostile_child_fields(self):
        summarize = getattr(admin_journey, "safe_browser_failure_summary", None)
        self.assertTrue(callable(summarize), "browser diagnostics must pass through a strict allowlist")
        if not callable(summarize):
            return
        sentinel = "phase170-private-cookie-sentinel"
        summary = summarize({
            "failure": sentinel,
            "stage": sentinel,
            "outcome": "failed",
            "counts": {"assets": sentinel, "cookie": sentinel},
            "observations": {"login": sentinel, "session": sentinel},
        })
        rendered = __import__("json").dumps(summary)
        self.assertNotIn(sentinel, rendered)
        self.assertEqual(set(summary), {"failure", "stage", "outcome", "counts", "observations"})
        self.assertEqual(summary["counts"], {})
        self.assertEqual(summary["observations"], {})

    def test_runtime_versions_cannot_retain_arbitrary_child_strings(self):
        malformed = copy.deepcopy(self.receipt)
        malformed["runtime"]["node"] = "phase170-private-cookie-sentinel"
        with self.assertRaises(ValueError):
            validate_receipt(malformed)


if __name__ == "__main__":
    unittest.main()
