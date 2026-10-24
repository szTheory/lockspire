import copy
import inspect
import tempfile
import sys
import unittest
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"))
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance"))
import clean_room_admin_journey as admin_journey
from admin_receipts import validate_receipt, write_receipt
import build_provider as provider_builder

FULL_CASE_IDS = (
    "allowed_entry", "assets", "live_navigation", "params_patch", "detail_task",
    "allowed_reconnect", "anonymous_http_denied", "nonstaff_http_denied",
    "cached_join_denied", "reconnect_denied", "params_denied", "public_session_denied",
    "consent_session_denied", "public_discovery", "public_jwks", "public_protocol_error",
)
FULL_CASE_EVIDENCE = {
    "allowed_entry": {"static_200", "join_allowed", "protected_content", "prefix_ok"},
    "assets": {"assets_200"},
    "live_navigation": {"live_navigation", "prefix_ok"},
    "params_patch": {"params_patch", "prefix_ok"},
    "detail_task": {"detail_task", "prefix_ok"},
    "allowed_reconnect": {"socket_closed", "reconnect_join", "interaction_after_reconnect"},
    "anonymous_http_denied": {"anonymous_denied", "protected_content_absent", "prefix_ok"},
    "nonstaff_http_denied": {"nonstaff_denied", "protected_content_absent", "prefix_ok"},
    "cached_join_denied": {"static_200", "cached_join_denied", "protected_content_absent"},
    "reconnect_denied": {"reconnect_denied", "protected_content_absent"},
    "params_denied": {"params_denied", "protected_content_absent"},
    "public_session_denied": {"public_session_denied", "protected_content_absent"},
    "consent_session_denied": {"consent_session_denied", "protected_content_absent"},
    "public_discovery": {"discovery_200", "no_staff_checks"},
    "public_jwks": {"jwks_200", "no_staff_checks"},
    "public_protocol_error": {"protocol_error_shape", "no_staff_checks"},
}
FULL_OBSERVATIONS = frozenset().union(*FULL_CASE_EVIDENCE.values()) | {"assets_200"}


def full_scenario(case_id):
    flags = {name: name in FULL_CASE_EVIDENCE[case_id] for name in FULL_OBSERVATIONS}
    counts = {name: 0 for name in ("assets", "websocket_handshakes", "successful_joins", "navigations", "params_checks", "http_checks", "staff_checks")}
    if case_id == "allowed_entry":
        counts.update(assets=2, successful_joins=1, http_checks=1, staff_checks=1)
    elif case_id == "assets":
        counts.update(assets=2)
    elif case_id == "allowed_reconnect":
        counts.update(websocket_handshakes=2, successful_joins=2, staff_checks=2)
    elif case_id in {"live_navigation", "params_patch", "detail_task"}:
        counts.update(navigations=1, params_checks=1, staff_checks=1)
    elif case_id in {"anonymous_http_denied", "nonstaff_http_denied"}:
        counts.update(http_checks=1, staff_checks=1)
    elif case_id in {"cached_join_denied", "reconnect_denied", "params_denied", "public_session_denied", "consent_session_denied"}:
        counts.update(staff_checks=1)
        if case_id == "params_denied":
            counts["params_checks"] = 1
    return {"id": case_id, "outcome": "passed", "duration_ms": 20, "counts": counts, "observations": flags}


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
                "counts": {"assets": 2, "websocket_handshakes": 2, "successful_joins": 2, "navigations": 4},
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

    def test_floor_pair_accepts_only_the_exact_floor_runtime(self):
        floor_receipt = copy.deepcopy(self.receipt)
        floor_receipt["pair"] = "floor"
        floor_receipt["runtime"]["phoenix"] = "1.8.5"
        floor_receipt["runtime"]["live_view"] = "1.1.28"

        validated = validate_receipt(floor_receipt, expected_pair="floor")

        self.assertEqual(validated["pair"], "floor")

    def test_runner_and_provider_expose_explicit_floor_pair_selection(self):
        args = admin_journey.parse_args(
            ["--pair", "floor", "--mount", "/lockspire", "--receipt", "receipt.json"]
        )

        self.assertEqual(args.pair, "floor")
        self.assertIn("proof_pair", inspect.signature(provider_builder.prepare_provider).parameters)

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
        self.assertEqual(sum(name.startswith("test_") for name in dir(type(self))), 15)

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

    def test_full_receipt_accepts_all_sixteen_named_boundary_cases(self):
        full = copy.deepcopy(self.receipt)
        full["scenarios"] = [full_scenario(case_id) for case_id in FULL_CASE_IDS]
        try:
            validated = validate_receipt(full, expected_scenario_set="full")
        except ValueError as error:
            self.fail(f"complete full case-set receipt should validate: {error}")
        self.assertEqual(validated["result"], "passed")
        self.assertEqual({item["id"] for item in validated["scenarios"]}, set(FULL_CASE_IDS))

    def test_full_scenario_extraction_preserves_each_case_outcome(self):
        observed = {"scenarios": [full_scenario(case_id) for case_id in FULL_CASE_IDS]}
        observed["scenarios"][-1]["outcome"] = "failed"
        extracted = admin_journey.full_scenarios_from_observation(observed)
        self.assertEqual(len(extracted), 16)
        self.assertEqual([item["outcome"] for item in extracted].count("passed"), 15)
        self.assertEqual(extracted[-1]["outcome"], "failed")

    def test_full_receipt_rejects_missing_duplicate_and_unknown_case_ids(self):
        for label, ids in (
            ("missing", FULL_CASE_IDS[:-1]),
            ("duplicate", FULL_CASE_IDS[:-1] + (FULL_CASE_IDS[0], FULL_CASE_IDS[0])),
            ("unknown", FULL_CASE_IDS[:-1] + ("secret_cookie",)),
        ):
            with self.subTest(label=label):
                malformed = copy.deepcopy(self.receipt)
                malformed["scenarios"] = [
                    full_scenario(case_id) if case_id in FULL_CASE_EVIDENCE
                    else {**full_scenario(FULL_CASE_IDS[0]), "id": case_id}
                    for case_id in ids
                ]
                with self.assertRaises(ValueError):
                    validate_receipt(malformed, expected_scenario_set="full")

    def test_full_receipt_requires_live_boundary_counters_before_and_after_mutation(self):
        for case_id, counter in (("cached_join_denied", "staff_checks"), ("reconnect_denied", "staff_checks"), ("params_denied", "params_checks")):
            with self.subTest(case_id=case_id):
                full = copy.deepcopy(self.receipt)
                full["scenarios"] = [full_scenario(item) for item in FULL_CASE_IDS]
                selected = next(item for item in full["scenarios"] if item["id"] == case_id)
                selected["counts"][counter] = 0
                with self.assertRaises(ValueError):
                    validate_receipt(full, expected_scenario_set="full")


if __name__ == "__main__":
    unittest.main()
