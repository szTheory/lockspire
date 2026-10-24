"""Small, allowlisted receipts for the packaged lifetime proof legs."""

from __future__ import annotations

import json
from pathlib import Path
import re
from typing import Iterable


SCENARIO_FIELDS = frozenset({"id", "leg", "contract_case_ids", "outcome", "observations", "event_counts", "audit_counts", "counts"})
RECEIPT_FIELDS = frozenset({"schema_version", "source_revision", "candidate", "scenarios", "counts", "cleanup"})
CANDIDATE_FIELDS = frozenset({"kind", "version", "archive_sha256", "tree_sha256", "source_revision"})
CLEANUP_FIELDS = frozenset({"processes_stopped", "databases_removed", "temporary_roots_removed"})
COUNT_FIELDS = frozenset({"executed", "passed", "failed", "skipped"})
FRESH_SCENARIO_FIELDS = {
    "fresh.register_use": ("access_token_issued",),
    "fresh.secret_expiry_rotate": ("expiry_rejected", "rotation_restored_auth", "unrelated_deadlines_preserved"),
    "fresh.management_put_recover": ("old_credential_rejected", "new_credential_accepted", "host_authorized_recovery", "unrelated_deadlines_preserved"),
    "fresh.app_expiry_disabled": ("expired_get_allowed", "expired_delete_allowed", "expired_put_rejected", "disabled_management_denied", "state_retained"),
}
FRESH_SCENARIO_EVENTS = {
    "fresh.register_use": ("registration_succeeded", "authorization_code_redeemed"),
    "fresh.secret_expiry_rotate": ("secret_expired", "secret_rotated"),
    "fresh.management_put_recover": ("management_token_replaced", "host_recovery"),
    "fresh.app_expiry_disabled": ("app_expired", "disabled_management_denied"),
}
REQUIRED_LIFETIME_SCENARIOS = frozenset({
    *FRESH_SCENARIO_FIELDS,
    "custom.issue_replace",
    "custom.shared_rollback",
    "custom.unsupported",
    "legacy.public",
    "legacy.tenant_auth",
})


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
        if not re.fullmatch(r"[0-9a-f]{40,64}", candidate["source_revision"]):
            raise AssertionError("lifetime receipt candidate source identity is invalid")
        identities.add(tuple(candidate[key] for key in ("kind", "version", "archive_sha256", "tree_sha256")))
    if not identities or len(identities) != 1:
        raise AssertionError("lifetime receipt legs do not share one candidate identity")


def validate_lifetime_receipt(path: Path, *, expected_scenarios: Iterable[str]) -> dict[str, object]:
    expected_scenarios = set(expected_scenarios)
    receipt = _exact_keys(json.loads(path.read_text(encoding="utf-8")), RECEIPT_FIELDS, "root")
    if receipt["schema_version"] != 1 or not isinstance(receipt["source_revision"], str) or not re.fullmatch(r"[0-9a-f]{40,64}", receipt["source_revision"]):
        raise AssertionError("lifetime receipt source identity is invalid")
    candidate = _exact_keys(receipt["candidate"], CANDIDATE_FIELDS, "candidate")
    if not isinstance(candidate["kind"], str) or not isinstance(candidate["version"], str):
        raise AssertionError("lifetime receipt candidate metadata is invalid")
    if any(not isinstance(candidate[key], str) or not re.fullmatch(r"[0-9a-f]{64}", candidate[key]) for key in ("archive_sha256", "tree_sha256")):
        raise AssertionError("lifetime receipt candidate digest is invalid")
    if not isinstance(candidate["source_revision"], str) or not re.fullmatch(r"[0-9a-f]{40,64}", candidate["source_revision"]):
        raise AssertionError("lifetime receipt candidate source identity is invalid")
    if candidate["source_revision"] != receipt["source_revision"]:
        raise AssertionError("lifetime receipt source and candidate identities differ")
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
        if scenario["id"].startswith("legacy."):
            if (
                scenario["leg"] != "legacy"
                or scenario["outcome"] != "passed"
                or not isinstance(scenario["observations"], dict)
                or not scenario["observations"]
                or any(value is not True for value in scenario["observations"].values())
                or not isinstance(scenario["event_counts"], dict)
                or not scenario["event_counts"]
                or any(type(value) is not int or value <= 0 for value in scenario["event_counts"].values())
                or not isinstance(scenario["audit_counts"], dict)
                or not scenario["audit_counts"]
                or any(type(value) is not int or value <= 0 for value in scenario["audit_counts"].values())
            ):
                raise AssertionError("lifetime receipt legacy HTTP and promotion evidence is incomplete")
    if seen != expected_scenarios:
        raise AssertionError("lifetime receipt required scenario set is incomplete")
    if expected_scenarios == REQUIRED_LIFETIME_SCENARIOS and any(
        scenario["outcome"] != "passed"
        or scenario["counts"]["executed"] <= 0
        or scenario["counts"]["passed"] <= 0
        or scenario["counts"]["failed"] != 0
        or scenario["counts"]["skipped"] != 0
        for scenario in scenarios
    ):
        raise AssertionError("lifetime receipt has a failed, skipped, or empty required scenario")
    fresh_seen = seen & set(FRESH_SCENARIO_FIELDS)
    if fresh_seen:
        if fresh_seen != set(FRESH_SCENARIO_FIELDS):
            raise AssertionError("lifetime receipt fresh scenario set is incomplete")
        by_id = {scenario["id"]: scenario for scenario in scenarios}
        for identifier, required_observations in FRESH_SCENARIO_FIELDS.items():
            scenario = by_id[identifier]
            if scenario["leg"] != "fresh" or scenario["outcome"] != "passed":
                raise AssertionError("lifetime receipt fresh scenario did not pass")
            if _counts(scenario["counts"], "fresh scenario")["skipped"] != 0:
                raise AssertionError("lifetime receipt skipped a required fresh scenario")
            observations = scenario["observations"]
            if not isinstance(observations, dict) or any(observations.get(name) is not True for name in required_observations):
                raise AssertionError("lifetime receipt fresh route observations are incomplete")
            if identifier == "fresh.register_use" and (
                observations.get("registration_http_status") != 201
                or observations.get("token_http_status") != 200
                or observations.get("pkce_method") != "S256"
            ):
                raise AssertionError("lifetime receipt fresh registration or S256 use is incomplete")
            events = scenario["event_counts"]
            audits = scenario["audit_counts"]
            if not isinstance(events, dict) or any(type(events.get(name)) is not int or events[name] <= 0 for name in FRESH_SCENARIO_EVENTS[identifier]):
                raise AssertionError("lifetime receipt fresh event observations are incomplete")
            if identifier != "fresh.register_use" and (
                not isinstance(audits, dict)
                or not audits
                or any(type(value) is not int or value <= 0 for value in audits.values())
            ):
                raise AssertionError("lifetime receipt fresh audit observations are incomplete")
    if any(identifier.startswith("custom.") for identifier in seen):
        by_id = {scenario["id"]: scenario for scenario in scenarios}
        if {identifier for identifier in by_id if identifier.startswith("custom.")} != {"custom.issue_replace", "custom.shared_rollback", "custom.unsupported"}:
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
    candidate = {**candidate, "source_revision": source_revision}
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


def combine_lifetime_receipts(
    fresh_path: Path,
    custom_path: Path,
    legacy_path: Path,
    receipt_path: Path,
    validation_path: Path,
    *,
    expected_source_revision: str | None = None,
) -> dict[str, object]:
    """Reduce three package-leg receipts to the exact safe CI allowlist."""
    fresh_ids = set(FRESH_SCENARIO_FIELDS)
    custom_ids = {"custom.issue_replace", "custom.shared_rollback", "custom.unsupported"}
    fresh = validate_lifetime_receipt(fresh_path, expected_scenarios=fresh_ids)
    custom = validate_lifetime_receipt(custom_path, expected_scenarios=custom_ids)
    legacy = json.loads(legacy_path.read_text(encoding="utf-8"))
    if not isinstance(legacy, dict) or set(legacy) != {"schema_version", "scenarios"} or legacy["schema_version"] != 1:
        raise AssertionError("lifetime upgrade receipt fields are invalid")
    legacy_rows = legacy["scenarios"]
    if not isinstance(legacy_rows, list) or {row.get("prefix") for row in legacy_rows if isinstance(row, dict)} != {"public", "tenant_auth"}:
        raise AssertionError("lifetime upgrade receipt prefix set is incomplete")

    fresh_candidate = fresh["candidate"]
    custom_candidate = custom["candidate"]
    assert isinstance(fresh_candidate, dict) and isinstance(custom_candidate, dict)
    identity_fields = ("kind", "version", "archive_sha256", "tree_sha256", "source_revision")
    identities = {tuple(value.get(key) for key in identity_fields) for value in (fresh_candidate, custom_candidate)}
    if len(identities) != 1 or fresh["source_revision"] != custom["source_revision"]:
        raise AssertionError("fresh and custom receipts do not share one candidate identity")
    source_revision = str(fresh["source_revision"])
    for row in legacy_rows:
        package = row.get("candidate_package") if isinstance(row, dict) else None
        if not isinstance(package, dict) or tuple(package.get(key) for key in identity_fields) != next(iter(identities)):
            raise AssertionError("legacy receipt does not share the packaged candidate identity")
        if row.get("database_cleanup_process", {}).get("exit_code") != 0:
            raise AssertionError("legacy package scenario cleanup did not succeed")

    scenarios = [*fresh["scenarios"], *custom["scenarios"]]
    for row in sorted(legacy_rows, key=lambda item: str(item["prefix"])):
        prefix = row["prefix"]
        scenarios.append({
            "id": f"legacy.{prefix}",
            "leg": "legacy",
            "contract_case_ids": ["C-LEG-01", "C-LEG-05", "C-PROOF-02"],
            "outcome": "passed",
            "observations": {
                "legacy_http_use": row["legacy_http_use_observation"]["access_token_issued"] is True,
                "v0_unlimited": "LEGACY_V0_UNLIMITED=1" in row["v0_legacy_rows_observation"]["output"],
                "http_promotion": row["legacy_promotion_observation"]["management_put_http_status"] == 200,
                "whole_row_preserved": row["legacy_promotion_observation"]["unrelated_authority_preserved"] is True,
                "old_writer_drained": row["old_writer_processes_stopped_before_v1"] is True,
                "migration_checksums_preserved": row["historical_migration_checksums_preserved"] is True,
                "no_old_binary_after_v1": row["old_binary_after_v1_traffic"] is False,
            },
            "event_counts": {"legacy_http_use": 1, "legacy_http_promotion": 1},
            "audit_counts": {"legacy_promotion": 1 if row["legacy_promotion_observation"]["audit_persisted"] else 0},
            "counts": {"executed": 1, "passed": 1, "failed": 0, "skipped": 0},
        })

    cleanup = {
        "processes_stopped": True,
        "databases_removed": all(row["database_cleanup_process"]["exit_code"] == 0 for row in legacy_rows),
        "temporary_roots_removed": all(value["cleanup"]["temporary_roots_removed"] is True for value in (fresh, custom)),
    }
    write_lifetime_receipt(
        receipt_path,
        source_revision=source_revision,
        candidate={key: str(fresh_candidate[key]) for key in identity_fields if key != "source_revision"},
        scenarios=scenarios,
        cleanup=cleanup,
    )
    return validate_ci_receipts(receipt_path, validation_path, expected_source_revision=expected_source_revision)


def validate_ci_receipts(receipt_path: Path, validation_path: Path, *, expected_source_revision: str | None = None) -> dict[str, object]:
    """Validate the exact retained receipt pair and return its sanitized summary."""
    receipt = validate_lifetime_receipt(receipt_path, expected_scenarios=REQUIRED_LIFETIME_SCENARIOS)
    if expected_source_revision and receipt["source_revision"] != expected_source_revision:
        raise AssertionError("lifetime receipt source revision does not match the CI candidate")
    candidate = receipt["candidate"]
    assert isinstance(candidate, dict)
    identity = ":".join(str(candidate[key]) for key in ("kind", "version", "archive_sha256", "tree_sha256", "source_revision"))
    import hashlib

    summary = {
        "schema_version": 1,
        "source_revision": receipt["source_revision"],
        "candidate_digest": hashlib.sha256(identity.encode("utf-8")).hexdigest(),
        "expected_scenarios": sorted(REQUIRED_LIFETIME_SCENARIOS),
        "executed": receipt["counts"]["executed"],
        "passed": receipt["counts"]["passed"],
        "failed": receipt["counts"]["failed"],
        "skipped": receipt["counts"]["skipped"],
        "valid": True,
    }
    validation_path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = validation_path.with_suffix(validation_path.suffix + ".tmp")
    temporary.write_text(json.dumps(summary, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")
    temporary.replace(validation_path)
    return summary
