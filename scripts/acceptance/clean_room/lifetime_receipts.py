"""Small, allowlisted receipts for the packaged lifetime proof legs."""

from __future__ import annotations

import json
from pathlib import Path
import re
from typing import Iterable


SCENARIO_FIELDS = frozenset({"id", "leg", "contract_case_ids", "outcome", "observations", "event_counts", "audit_counts", "counts"})
RECEIPT_FIELDS = frozenset({"schema_version", "source_revision", "candidate", "scenarios", "counts", "cleanup"})
CANDIDATE_FIELDS = frozenset({"kind", "version", "archive_sha256", "tree_sha256"})
CLEANUP_FIELDS = frozenset({"processes_stopped", "databases_removed", "temporary_roots_removed"})
COUNT_FIELDS = frozenset({"executed", "passed", "failed", "skipped"})


def _exact_keys(value: object, expected: frozenset[str], label: str) -> dict[str, object]:
    if not isinstance(value, dict) or set(value) != expected:
        raise AssertionError(f"lifetime receipt {label} fields are invalid")
    return value


def _counts(value: object, label: str) -> dict[str, int]:
    counts = _exact_keys(value, COUNT_FIELDS, label)
    if any(type(item) is not int or item < 0 for item in counts.values()):
        raise AssertionError(f"lifetime receipt {label} counts are invalid")
    if counts["executed"] != counts["passed"] + counts["failed"] + counts["skipped"]:
        raise AssertionError(f"lifetime receipt {label} counts do not reconcile")
    return counts  # type: ignore[return-value]


def validate_candidate_identity_agreement(candidates: Iterable[dict[str, object]]) -> None:
    """Require all proof legs to name one archive and one unpacked candidate."""
    identities: set[tuple[str, str, str, str]] = set()
    for candidate in candidates:
        if not isinstance(candidate, dict) or any(not isinstance(candidate.get(key), str) for key in CANDIDATE_FIELDS):
            raise AssertionError("lifetime receipt candidate identity is incomplete")
        if any(not re.fullmatch(r"[0-9a-f]{64}", candidate[key]) for key in ("archive_sha256", "tree_sha256")):
            raise AssertionError("lifetime receipt candidate digest is invalid")
        identities.add(tuple(candidate[key] for key in ("kind", "version", "archive_sha256", "tree_sha256")))
    if not identities or len(identities) != 1:
        raise AssertionError("lifetime receipt legs do not share one candidate identity")


def validate_lifetime_receipt(path: Path, *, expected_scenarios: Iterable[str]) -> dict[str, object]:
    receipt = _exact_keys(json.loads(path.read_text(encoding="utf-8")), RECEIPT_FIELDS, "root")
    if receipt["schema_version"] != 1 or not isinstance(receipt["source_revision"], str) or not re.fullmatch(r"[0-9a-f]{40,64}", receipt["source_revision"]):
        raise AssertionError("lifetime receipt source identity is invalid")
    candidate = _exact_keys(receipt["candidate"], CANDIDATE_FIELDS, "candidate")
    if not isinstance(candidate["kind"], str) or not isinstance(candidate["version"], str):
        raise AssertionError("lifetime receipt candidate metadata is invalid")
    if any(not isinstance(candidate[key], str) or not re.fullmatch(r"[0-9a-f]{64}", candidate[key]) for key in ("archive_sha256", "tree_sha256")):
        raise AssertionError("lifetime receipt candidate digest is invalid")
    scenarios = receipt["scenarios"]
    if not isinstance(scenarios, list):
        raise AssertionError("lifetime receipt scenarios are invalid")
    seen: set[str] = set()
    aggregate = {key: 0 for key in COUNT_FIELDS}
    for raw in scenarios:
        scenario = _exact_keys(raw, SCENARIO_FIELDS, "scenario")
        if not isinstance(scenario["id"], str) or scenario["id"] in seen:
            raise AssertionError("lifetime receipt scenario identity is invalid")
        seen.add(scenario["id"])
        if scenario["outcome"] not in {"passed", "failed", "skipped"}:
            raise AssertionError("lifetime receipt scenario outcome is invalid")
        counts = _counts(scenario["counts"], "scenario")
        if scenario["outcome"] == "passed" and (counts["executed"] <= 0 or counts["passed"] <= 0 or counts["failed"] or counts["skipped"]):
            raise AssertionError("lifetime receipt passed scenario has no positive, clean evidence")
        for key, value in counts.items():
            aggregate[key] += value
        for key in ("contract_case_ids", "observations", "event_counts", "audit_counts"):
            if not isinstance(scenario[key], (list, dict)):
                raise AssertionError("lifetime receipt observation shape is invalid")
    if seen != set(expected_scenarios):
        raise AssertionError("lifetime receipt required scenario set is incomplete")
    if any(identifier.startswith("custom.") for identifier in seen):
        by_id = {scenario["id"]: scenario for scenario in scenarios}
        if set(by_id) != {"custom.issue_replace", "custom.shared_rollback", "custom.unsupported"}:
            raise AssertionError("lifetime receipt custom scenario set is incomplete")
        if any(
            by_id[identifier]["outcome"] != "passed"
            or _counts(by_id[identifier]["counts"], "custom scenario")["skipped"] != 0
            for identifier in by_id
        ):
            raise AssertionError("lifetime receipt custom scenario was not executed successfully")
        issue = by_id["custom.issue_replace"]["observations"]
        rollback = by_id["custom.shared_rollback"]["observations"]
        unsupported = by_id["custom.unsupported"]["observations"]
        if (
            not isinstance(issue, dict)
            or type(issue.get("callbacks_executed")) is not int
            or issue["callbacks_executed"] <= 0
            or issue.get("authority_shared") is not True
            or issue.get("management_credential_replaced") is not True
            or issue.get("example_executed") is not True
        ):
            raise AssertionError("lifetime receipt custom issuance evidence is incomplete")
        if (
            not isinstance(rollback, dict)
            or any(rollback.get(key) is not True for key in (
                "independent_observer", "rollback_preserved", "replacement_observed", "issuance_observed"
            ))
        ):
            raise AssertionError("lifetime receipt independent rollback evidence is incomplete")
        if (
            not isinstance(unsupported, dict)
            or unsupported.get("unsupported_rejected") is not True
            or unsupported.get("example_executed") is not True
        ):
            raise AssertionError("lifetime receipt unsupported-state evidence is incomplete")
    if _counts(receipt["counts"], "aggregate") != aggregate:
        raise AssertionError("lifetime receipt aggregate counts differ from scenario totals")
    cleanup = _exact_keys(receipt["cleanup"], CLEANUP_FIELDS, "cleanup")
    if any(value is not True for value in cleanup.values()):
        raise AssertionError("lifetime receipt cleanup was not fully observed")
    return receipt


def write_lifetime_receipt(
    path: Path,
    *,
    source_revision: str,
    candidate: dict[str, str],
    scenarios: list[dict[str, object]],
    cleanup: dict[str, bool],
) -> None:
    counts = {key: 0 for key in COUNT_FIELDS}
    for scenario in scenarios:
        scenario_counts = _counts(scenario.get("counts"), "scenario")
        for key, value in scenario_counts.items():
            counts[key] += value
    receipt = {
        "schema_version": 1,
        "source_revision": source_revision,
        "candidate": candidate,
        "scenarios": scenarios,
        "counts": counts,
        "cleanup": cleanup,
    }
    _exact_keys(receipt, RECEIPT_FIELDS, "root")
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(receipt, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
    temporary.replace(path)
    if all(scenario.get("outcome") == "passed" for scenario in scenarios):
        validate_lifetime_receipt(path, expected_scenarios=(scenario["id"] for scenario in scenarios))
