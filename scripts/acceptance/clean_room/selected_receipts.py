"""Strict receipts for bounded, package-bound selected authorization proof."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
from typing import Iterable


SELECTED_CASE_IDS = (
    "A171-001", "A171-002", "A171-003", "A171-004", "A171-005", "A171-006",
    "P171-001", "P171-002", "P171-003", "P171-004", "P171-005", "P171-006",
)
COUNT_FIELDS = frozenset({"executed", "passed", "failed", "skipped"})
ROOT_FIELDS = frozenset({
    "schema_version", "selection", "expected_case_ids", "source_revision", "candidate",
    "scenarios", "counts", "cleanup", "redaction",
})
CANDIDATE_FIELDS = frozenset({
    "kind", "version", "source_revision", "archive_sha256", "tree_sha256",
    "vendor_tree_sha256", "compiled_candidate_sha256", "resolved_dependency_verified",
})
SCENARIO_FIELDS = frozenset({"id", "outcome", "observations", "counts"})
CLEANUP_FIELDS = frozenset({"processes_stopped", "databases_removed", "temporary_roots_removed"})
REDACTION_FIELDS = frozenset({"sentinel_check_passed", "evidence_scan_passed"})
SELECTED_OBSERVATION_FIELDS: dict[str, frozenset[str]] = {
    "A171-001": frozenset({"control_status", "control_callback_exact", "mismatch_status", "mismatch_no_location"}),
    "A171-002": frozenset({
        "callback_status", "callback_exact_registered", "foo_preserved", "trusted_state_only",
        "error_invalid_request", "no_duplicate_state",
    }),
    "A171-003": frozenset({
        "control_status", "control_reached_host_handoff", "unsupported_status", "html_content_type",
        "no_location", "no_oauth_error_parameters",
    }),
    "A171-004": frozenset({"callback_status", "login_required", "state_matches", "no_host_login_redirect"}),
    "A171-005": frozenset({"callback_status", "login_required", "state_matches", "no_host_login_redirect", "stale_auth_time_used"}),
    "A171-006": frozenset({
        "max_age_token_status", "max_age_signature_valid", "max_age_issuer_audience_nonce_valid",
        "max_age_auth_time_integer", "max_age_auth_time_equal", "claims_token_status",
        "claims_signature_valid", "claims_issuer_audience_nonce_valid", "claims_auth_time_integer",
        "claims_auth_time_equal",
    }),
}


def _exact_keys(value: object, expected: frozenset[str], label: str) -> dict[str, object]:
    if not isinstance(value, dict) or set(value) != expected:
        raise AssertionError(f"selected receipt {label} fields are invalid")
    return value


def _counts(value: object, label: str) -> dict[str, int]:
    counts = _exact_keys(value, COUNT_FIELDS, label)
    if any(type(item) is not int or item < 0 for item in counts.values()):
        raise AssertionError(f"selected receipt {label} counts are invalid")
    if counts["executed"] != counts["passed"] + counts["failed"] + counts["skipped"]:
        raise AssertionError(f"selected receipt {label} counts do not reconcile")
    return counts  # type: ignore[return-value]


def validate_selected_receipt(
    path: Path,
    *,
    expected_case_ids: Iterable[str],
    expected_source_revision: str,
    expected_receipt_sha256: str | None = None,
    expected_binding: dict[str, object] | None = None,
) -> dict[str, object]:
    """Validate exact selection, observations, package provenance, and owned cleanup."""
    raw = path.read_bytes()
    if expected_receipt_sha256 is not None:
        if not re.fullmatch(r"[0-9a-f]{64}", expected_receipt_sha256):
            raise AssertionError("selected receipt expected digest is invalid")
        if hashlib.sha256(raw).hexdigest() != expected_receipt_sha256:
            raise AssertionError("selected receipt bytes differ from the externally supplied digest")
    try:
        receipt = _exact_keys(json.loads(raw), ROOT_FIELDS, "root")
    except (UnicodeDecodeError, json.JSONDecodeError):
        raise AssertionError("selected receipt JSON is invalid") from None
    if type(receipt["schema_version"]) is not int or receipt["schema_version"] != 1:
        raise AssertionError("selected receipt schema version is invalid")

    if expected_case_ids is None or isinstance(expected_case_ids, (str, bytes)):
        raise AssertionError("selected receipt requested case set is invalid")
    try:
        expected = tuple(expected_case_ids)
    except TypeError:
        raise AssertionError("selected receipt requested case set is invalid") from None
    if not expected or len(expected) != len(set(expected)) or any(item not in SELECTED_CASE_IDS for item in expected):
        raise AssertionError("selected receipt requested case set is invalid")
    actual_expected = receipt["expected_case_ids"]
    if not isinstance(actual_expected, list) or actual_expected != list(expected):
        raise AssertionError("selected receipt does not match the requested case set")
    complete = expected == SELECTED_CASE_IDS
    if receipt["selection"] != ("complete" if complete else "partial"):
        raise AssertionError("selected receipt complete/partial identity is invalid")
    if not isinstance(receipt["source_revision"], str) or not re.fullmatch(r"[0-9a-f]{40,64}", receipt["source_revision"]):
        raise AssertionError("selected receipt source revision is invalid")
    if receipt["source_revision"] != expected_source_revision:
        raise AssertionError("selected receipt source revision differs from the expected revision")

    candidate = _exact_keys(receipt["candidate"], CANDIDATE_FIELDS, "candidate")
    if not isinstance(candidate["kind"], str) or not candidate["kind"] or not isinstance(candidate["version"], str) or not candidate["version"]:
        raise AssertionError("selected receipt candidate metadata is invalid")
    for key in ("archive_sha256", "tree_sha256", "vendor_tree_sha256", "compiled_candidate_sha256"):
        if not isinstance(candidate[key], str) or not re.fullmatch(r"[0-9a-f]{64}", candidate[key]):
            raise AssertionError("selected receipt candidate digest is invalid")
    if not isinstance(candidate["source_revision"], str) or candidate["source_revision"] != receipt["source_revision"]:
        raise AssertionError("selected receipt candidate source revision differs")
    if candidate["tree_sha256"] != candidate["vendor_tree_sha256"]:
        raise AssertionError("selected receipt package and vendor tree identities differ")
    if candidate["resolved_dependency_verified"] is not True:
        raise AssertionError("selected receipt resolved dependency was not verified")
    if expected_binding is not None:
        if set(expected_binding) != CANDIDATE_FIELDS or candidate != expected_binding:
            raise AssertionError("selected receipt candidate differs from the independently captured binding")

    scenarios = receipt["scenarios"]
    if not isinstance(scenarios, list) or not scenarios:
        raise AssertionError("selected receipt scenarios are empty or invalid")
    seen: set[str] = set()
    totals = {key: 0 for key in COUNT_FIELDS}
    for raw_scenario in scenarios:
        scenario = _exact_keys(raw_scenario, SCENARIO_FIELDS, "scenario")
        identifier = scenario["id"]
        if not isinstance(identifier, str) or identifier not in expected or identifier in seen:
            raise AssertionError("selected receipt scenario identity is missing, duplicate, or unknown")
        seen.add(identifier)
        observation_fields = SELECTED_OBSERVATION_FIELDS.get(identifier)
        if observation_fields is None:
            raise AssertionError(f"selected receipt case is not implemented: {identifier}")
        observations = _exact_keys(scenario["observations"], observation_fields, "observations")
        bool_fields = observation_fields - {
            key for key in observation_fields if key.endswith("_status")
        }
        if any(observations[key] is not True for key in bool_fields):
            raise AssertionError(f"selected {identifier} boolean observations are incomplete")
        for key in observation_fields - bool_fields:
            if type(observations[key]) is not int or observations[key] < 100 or observations[key] > 599:
                raise AssertionError(f"selected {identifier} HTTP status observation is invalid")
        if identifier == "A171-001":
            if observations["control_status"] not in (302, 303) or observations["mismatch_status"] != 400:
                raise AssertionError("selected A171-001 HTTP observations are invalid")
        elif identifier == "A171-002":
            if observations["callback_status"] not in (302, 303):
                raise AssertionError("selected A171-002 callback status is invalid")
        elif identifier in {"A171-004", "A171-005"}:
            if observations["callback_status"] not in (302, 303):
                raise AssertionError(f"selected {identifier} callback status is invalid")
        elif identifier == "A171-006":
            if observations["max_age_token_status"] != 200 or observations["claims_token_status"] != 200:
                raise AssertionError("selected A171-006 token status is invalid")
        if identifier == "A171-003":
            if type(observations["control_status"]) is not int or observations["control_status"] not in (302, 303):
                raise AssertionError("selected A171-003 valid query control is invalid")
            if type(observations["unsupported_status"]) is not int or observations["unsupported_status"] != 400:
                raise AssertionError("selected A171-003 unsupported response status is invalid")
            if observations["control_reached_host_handoff"] is not True or any(
                observations[key] is not True
                for key in ("html_content_type", "no_location", "no_oauth_error_parameters")
            ):
                raise AssertionError("selected A171-003 HTTP observations are incomplete")
        counts = _counts(scenario["counts"], "scenario")
        if scenario["outcome"] != "passed" or counts["executed"] <= 0 or counts["passed"] <= 0 or counts["failed"] or counts["skipped"]:
            raise AssertionError("selected receipt scenario is failed, skipped, or empty")
        for key, value in counts.items():
            totals[key] += value
    if seen != set(expected):
        raise AssertionError("selected receipt is missing one or more requested scenarios")
    if _counts(receipt["counts"], "aggregate") != totals:
        raise AssertionError("selected receipt aggregate counts differ from scenario totals")

    cleanup = _exact_keys(receipt["cleanup"], CLEANUP_FIELDS, "cleanup")
    redaction = _exact_keys(receipt["redaction"], REDACTION_FIELDS, "redaction")
    if any(value is not True for value in cleanup.values()):
        raise AssertionError("selected receipt owned cleanup is incomplete")
    if any(value is not True for value in redaction.values()):
        raise AssertionError("selected receipt redaction is incomplete")
    return receipt


def write_selected_receipt(
    path: Path,
    *,
    selection: str,
    expected_case_ids: Iterable[str],
    source_revision: str,
    candidate: dict[str, object],
    scenarios: list[dict[str, object]],
    cleanup: dict[str, bool],
    redaction: dict[str, bool],
) -> None:
    """Write a canonical compact receipt; validation is always done by the caller."""
    ids = list(expected_case_ids)
    aggregate = {key: 0 for key in COUNT_FIELDS}
    for scenario in scenarios:
        counts = _counts(scenario.get("counts"), "scenario")
        for key, value in counts.items():
            aggregate[key] += value
    receipt = {
        "schema_version": 1, "selection": selection, "expected_case_ids": ids,
        "source_revision": source_revision, "candidate": candidate, "scenarios": scenarios,
        "counts": aggregate, "cleanup": cleanup, "redaction": redaction,
    }
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(receipt, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
    temporary.replace(path)
