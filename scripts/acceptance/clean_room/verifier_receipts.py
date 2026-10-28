"""Finite, strict evidence contract for installed verifier scenario groups."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import subprocess
from typing import Any


SCHEMA = "lockspire-installed-verifier-v1"
GROUPS = frozenset({
    "tracer", "core", "rollout", "legacy-control", "endpoints", "release-rpc",
    "contention", "atomicity", "recovery", "issuance", "disclosure",
    "disclosure-failure", "all",
})
ROOT_FIELDS = frozenset({
    "schema", "scope", "run_id", "runner", "pair", "store", "candidate", "host",
    "runtime", "stable_case_ids", "observations", "executed_count", "partial",
})
IDENTITY_FIELDS = frozenset({"kind", "version", "archive_sha256", "tree_sha256", "source_revision", "runner_revision", "source_proof"})
CASE_ID = re.compile(r"[A-Z0-9][A-Z0-9._-]{2,95}\Z")
SHA = re.compile(r"[0-9a-f]{64}\Z")
REVISION = re.compile(r"[0-9a-f]{40,64}\Z")
PREDECESSOR_SOURCE = "173059a166e9ade0f5f57c9980b7b2400a98538c"
PREDECESSOR_ARCHIVE_SHA256 = "792967609e41d216fc0178ef069570c39350c9bb5ee481da4e2852993267e758"
PREDECESSOR_TREE_SHA256 = "2dcf7705bd5651e853a02a931a1e0c595639438b3bd0a36a9c330017eab98315"
PREDECESSOR_SOURCE_ARCHIVE_SHA256 = "67a9daf5a54cb104e5647e3de3a7372b0eeee896189c2c043409e2497784f5a6"
PREDECESSOR_COMMIT_TREE = "127c8d480223cd4474447a73c7a80066be6fc2be"
PUBLIC_SOURCE = "d04be40262e975a4eb8d8567eb0d1458a9c23181"
PUBLIC_ARCHIVE_SHA256 = "629abdc1b6721620f3d9084dbbe78da1e254650da5c552d0cc0f5b0c00f1cc6d"
PUBLIC_TREE_SHA256 = "64211d4d9d7e4d20520a0f68141e01c5493b57e3bbf014a8cc8cb22ec328ed46"
ROLLOUT_OBSERVATION_FIELDS = frozenset({
    "outcome", "executed", "old_process_exit_observed", "legacy_write_read_shared_store",
    "dedicated_write_after_drain", "switch_back_legacy_write_preserves_dedicated",
    "old_code_rejects_dedicated", "rollback_retains_dedicated_reads",
    "old_code_legacy_control_succeeded", "legacy_hash_preserved", "dedicated_hash_present",
    "fleet_parity_proven", "quiescence_proven", "backup_proven",
    "candidate_legacy_overlap_pid", "candidate_dedicated_activation_pid",
    "candidate_compatible_rollback_pid", "isolated_old_process_pid", "legacy_writer_pid",
})
PUBLIC_OBSERVATION_FIELDS = frozenset({
    "outcome", "executed", "public_pin_verified", "verifier_specific_adoption_executed",
    "http_authentication_succeeded", "http_auth_failure", "authenticated_deadline_preserved",
    "client_hash_preserved", "lifetime_prerequisite_migrated", "legacy_format_before",
    "dedicated_format_after", "authenticated_age_kind_before", "authenticated_age_kind_after",
    "release_source_evidence", "coverage",
})
OBSERVATION_FIELDS = frozenset({
    "outcome", "executed", "http_status", "token_issued",
    "dedicated_verifier_persisted", "fresh_signed_assertion",
    "dry_run_reported", "dry_run_unchanged", "apply_committed", "fresh_check_ready",
    "authority_rejections_before_access", "unknown_material_rejected",
    "partial_inventory_rejected", "delegated_callbacks_observed", "client_hash_preserved",
})
TRACER_OBSERVATION_FIELDS = frozenset({
    "outcome", "executed", "http_status", "token_issued",
    "dedicated_verifier_persisted", "fresh_signed_assertion",
})
ENDPOINT_CASE_IDS = [
    "VPROOF-02-HTTP-TOKEN-JWT",
    "VPROOF-02-HTTP-INTROSPECTION-JWT",
    "VPROOF-02-HTTP-REVOCATION-JWT",
    "VPROOF-02-HTTP-DEVICE-JWT",
    "VPROOF-02-HTTP-CIBA-JWT",
    "VPROOF-02-HTTP-PAR-JWT-REJECTED",
    "VPROOF-02-HTTP-JWT-NEGATIVE-CONTROLS",
    "VPROOF-02-HTTP-BASIC-CONTROL",
    "VPROOF-02-HTTP-POST-CONTROL",
]
ENDPOINT_OBSERVATION_FIELDS = frozenset({
    "outcome", "executed", "assertion_passed", "fresh_jti", "http_status",
    "configured_issuer", "discovered_issuer", "assertion_audience", "rejected_audience_uri",
})
ENDPOINT_LIFECYCLE_FIELDS = frozenset({"revoked_token_inactive"})
ENDPOINT_FAPI_FIELDS = frozenset({"fapi_security_excluded", "fapi_message_signing_excluded"})
RELEASE_RPC_CASE_ID = "VPROOF-02-RELEASE-RPC-DRY-RUN"
# Exact descriptions emitted by verifier_endpoints.run_release_rpc. These are
# evidence labels, never a channel for command output or caller-supplied text.
RELEASE_RPC_INVOCATIONS = {
    "rpc_invocation": "bin/clean_room_provider rpc Lockspire.Admin.ClientVerifierMaintenance.run(mode: :dry_run, limit: 100)",
    "check_invocation": "bin/clean_room_provider rpc Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check, limit: 100)",
    "task_local_invocation": "mix lockspire.clients.verifier.rewrap --check --limit 100",
}
RELEASE_RPC_OBSERVATION_FIELDS = frozenset({
    "outcome", "executed", "assembly_succeeded", "running_process_observed", "rpc_executed",
    "startup_mode_dedicated", "task_local_mode_dedicated", "task_local_check_ready",
    "rpc_dry_run_complete", "rpc_fresh_check_ready", "loaded_candidate_verified",
    "rpc_exit_code", "check_exit_code", "task_local_exit_code", "process_pid",
    "release_node", "rpc_invocation", "check_invocation", "task_local_invocation",
    "compiled_module_relative_path", "compiled_module_sha256", "startup_context_source",
    "task_local_context_source", "startup_current_key_id", "task_local_current_key_id",
    "dry_run_scanned", "dry_run_pending", "fresh_check_scanned",
})
CORE_CASE_ID = "VPROOF-02-CORE-FRESH-MAINTENANCE"
CONTENTION_CASE_IDS = [
    "VPROOF-02-CONTENTION-ROTATION-FIRST",
    "VPROOF-02-CONTENTION-MAINTENANCE-FIRST",
]
ATOMICITY_CASE_IDS = [
    "VPROOF-02-ATOMICITY-AUDIT-INSERT-ROLLBACK",
    "VPROOF-02-ATOMICITY-OUTER-ROLLBACK",
    "VPROOF-02-ATOMICITY-NESTED-REPORT-AND-COMMIT-ORDER",
]
CONTENTION_OBSERVATION_FIELDS = frozenset({
    "outcome", "executed", "holder_backend_pid", "contender_backend_pid",
    "blocker_observed", "material_conflict", "credential_pair_coherent",
    "durable_state_verified",
})
ATOMICITY_OBSERVATION_FIELDS = {
    ATOMICITY_CASE_IDS[0]: frozenset({
        "outcome", "executed", "reached_insert", "unchanged_ciphertext",
        "absent_committed_audit",
    }),
    ATOMICITY_CASE_IDS[1]: frozenset({
        "outcome", "executed", "provisional_change_observed", "outer_rollback_observed",
        "unchanged_ciphertext", "absent_committed_audit",
    }),
    ATOMICITY_CASE_IDS[2]: frozenset({
        "outcome", "executed", "nested_report_rejected", "mutation_absent",
        "success_report_after_commit", "report_absent_before_commit",
    }),
}
RECOVERY_CASE_IDS = [
    "VPROOF-02-RECOVERY-PRESERVATION",
    "VPROOF-02-RECOVERY-RETRY-RECONCILIATION",
    "VPROOF-02-RECOVERY-RESTORE-ROTATE",
    "VPROOF-02-RECOVERY-EXPIRED-MIGRATION",
]
RECOVERY_OBSERVATION_FIELDS = frozenset({
    "outcome", "executed", "hash_preserved", "partner_secret_preserved",
    "client_fields_preserved", "age_metadata_preserved", "ciphertext_changed", "audit_inserted",
    "repeat_no_change", "partial_not_ready", "interruption_not_ready",
    "indeterminate_not_claimed_rollback", "fresh_complete_check_ready",
    "missing_key_rejected", "affected_status_redacted", "basic_usable", "post_usable",
    "original_secret_preserved", "rotation_secret_changed", "one_time_handoff",
    "missing_startup_context_bound", "missing_startup_context_has_protecting_key",
    "restored_startup_context_has_protecting_key", "missing_key_http_status",
    "missing_key_error_code", "basic_http_status", "post_http_status",
    "restored_http_status", "old_secret_after_rotation_http_status",
    "old_secret_after_rotation_error_code", "new_secret_after_rotation_http_status",
    "new_secret_after_rotation_error_code", "expired_http_status",
    "expired_rewrap_committed", "expired_http_auth_rejected", "deadline_preserved",
})
ISSUANCE_OBSERVATION_FIELDS = frozenset({
    "outcome", "executed", "server_ready", "discovery_http_status", "auth_barrier_reached",
    "jti_consumption_observed", "pre_guard_barrier_reached", "maintenance_committed",
    "backend_pids_distinct", "stale_identity_rejected", "stale_http_status", "stale_error_code",
    "no_token_issued", "no_grant_created", "no_code_redemption", "same_jti_replay_rejected",
    "replay_http_status", "replay_error_code", "fresh_jti_succeeded", "fresh_http_status",
    "fresh_error_code",
})
ISSUANCE_CASE_IDS = {
    "locked": "VPROOF-02-ISSUANCE-LOCKED-STALE-IDENTITY",
    "floor": "VPROOF-02-ISSUANCE-FLOOR-STALE-IDENTITY",
}
DISCLOSURE_CASE_IDS = {
    "locked": ["VPROOF-02-DISCLOSURE-LOCKED-SUCCESS"],
    "floor": ["VPROOF-02-DISCLOSURE-FLOOR-SUCCESS"],
}
DISCLOSURE_CHANNEL_ATTRIBUTION = "operation_process_phase_v1"
DISCLOSURE_FAILURE_CASE_IDS = {
    "locked": [
        "VPROOF-02-DISCLOSURE-LOCKED-MALFORMED-CRYPTO",
        "VPROOF-02-DISCLOSURE-LOCKED-UNKNOWN-KEY-CRYPTO",
        "VPROOF-02-DISCLOSURE-LOCKED-STORAGE-FAILURE",
    ],
    "floor": [
        "VPROOF-02-DISCLOSURE-FLOOR-MALFORMED-CRYPTO",
        "VPROOF-02-DISCLOSURE-FLOOR-UNKNOWN-KEY-CRYPTO",
        "VPROOF-02-DISCLOSURE-FLOOR-STORAGE-FAILURE",
    ],
}
DISCLOSURE_SUCCESS_FIELDS = frozenset({
    "outcome", "executed", "channel_attribution", "logger_event_count", "query_event_count",
    "logger_control_event_count", "logger_operation_event_count",
    "query_control_event_count", "query_operation_event_count",
    "logger_leak_count", "query_leak_count", "output_leak_count",
    "cli_output_checked", "audit_projection_safe", "nested_inspection_redacted",
    "one_time_handoff_usable", "maintenance_changed", "http_status",
})
HISTORICAL_DISCLOSURE_SUCCESS_FIELDS = DISCLOSURE_SUCCESS_FIELDS - {"channel_attribution"}
DISCLOSURE_FAILURE_FIELDS = frozenset({
    "outcome", "executed", "channel_attribution", "scenario", "reason", "forced_failure_observed",
    "operation_result", "failure_detail_count", "storage_failure_witness",
    "logger_event_count", "logger_control_event_count", "logger_operation_event_count",
    "logger_leak_count", "query_event_count", "query_control_event_count",
    "query_operation_event_count", "query_leak_count", "cli_output_checked",
    "report_redacted", "audit_projection_safe", "audit_unchanged", "ciphertext_unchanged",
    "http_status", "http_error_code", "http_outcome_safe", "output_leak_count",
})
HISTORICAL_DISCLOSURE_FAILURE_FIELDS = DISCLOSURE_FAILURE_FIELDS - {"channel_attribution"}
CORE_OBSERVATION_FIELDS = frozenset({
    "outcome", "executed", "http_status", "token_issued", "dedicated_verifier_persisted",
    "fresh_signed_assertion", "dry_run_reported", "dry_run_unchanged", "apply_committed",
    "fresh_check_ready", "authority_rejections_before_access", "unknown_material_rejected",
    "partial_inventory_rejected", "delegated_callbacks_observed", "client_hash_preserved",
})


class ReceiptError(ValueError):
    pass


DISCLOSURE_CAPTURE_REJECTION_PREDICATES = frozenset({
    "capture_fields_invalid", "capture_scenario_unsupported", "capture_count_invalid",
    "channel_attribution_unsupported", "capture_controls_invalid", "capture_totals_invalid",
    "capture_channel_leak_observed", "capture_redaction_invalid", "capture_operation_invalid",
    "capture_domain_witness_invalid",
})
DISCLOSURE_CAPTURE_FACT_COUNT_FIELDS = (
    "logger_event_count", "logger_control_event_count", "logger_operation_event_count",
    "query_event_count", "query_control_event_count", "query_operation_event_count",
    "logger_leak_count", "query_leak_count",
)


def _disclosure_capture_facts(payload: object) -> dict[str, Any]:
    facts: dict[str, Any] = {}
    if isinstance(payload, dict):
        for field in DISCLOSURE_CAPTURE_FACT_COUNT_FIELDS:
            value = payload.get(field)
            facts[field] = value if type(value) is int and 0 <= value <= 2**31 - 1 else None
        facts.update({
            "channel_attribution_matches": payload.get("channel_attribution") == DISCLOSURE_CHANNEL_ATTRIBUTION,
            "logger_controls_exact": payload.get("logger_control_event_count") == 2,
            "query_controls_exact": payload.get("query_control_event_count") == 1,
            "logger_total_covers_attribution": (
                type(payload.get("logger_event_count")) is int
                and type(payload.get("logger_control_event_count")) is int
                and type(payload.get("logger_operation_event_count")) is int
                and payload["logger_event_count"] >= payload["logger_control_event_count"] + payload["logger_operation_event_count"]
            ),
            "query_total_covers_attribution": (
                type(payload.get("query_event_count")) is int
                and type(payload.get("query_control_event_count")) is int
                and type(payload.get("query_operation_event_count")) is int
                and payload["query_event_count"] >= payload["query_control_event_count"] + payload["query_operation_event_count"]
            ),
            "channel_leaks_zero": (
                payload.get("logger_leak_count") == 0 and payload.get("query_leak_count") == 0
            ),
            "forced_failure_observed": payload.get("forced_failure_observed") is True,
            "operation_result_failed": payload.get("operation_result") == "failed",
            "storage_failure_witness": payload.get("storage_failure_witness") is True,
            "audit_unchanged": payload.get("audit_unchanged") is True,
            "ciphertext_unchanged": payload.get("ciphertext_unchanged") is True,
        })
    else:
        facts.update({
            "channel_attribution_matches": False,
            "logger_controls_exact": False,
            "query_controls_exact": False,
            "logger_total_covers_attribution": False,
            "query_total_covers_attribution": False,
            "channel_leaks_zero": False,
            "forced_failure_observed": False,
            "operation_result_failed": False,
            "storage_failure_witness": False,
            "audit_unchanged": False,
            "ciphertext_unchanged": False,
        })
    return facts


class DisclosureCaptureRejected(ReceiptError):
    def __init__(self, predicate: str, payload: object):
        if predicate not in DISCLOSURE_CAPTURE_REJECTION_PREDICATES:
            raise ValueError("disclosure capture rejection predicate is outside its fixed enum")
        self.witness = {"predicate": predicate, "facts": _disclosure_capture_facts(payload)}
        super().__init__("disclosure capture rejected by finite predicate")


DISCLOSURE_FAILURE_CAPTURE_FIELDS = frozenset({
    "channel_attribution", "scenario", "reason", "forced_failure_observed", "operation_result",
    "failure_detail_count", "storage_failure_witness", "logger_event_count",
    "logger_control_event_count", "logger_operation_event_count", "logger_leak_count",
    "query_event_count", "query_control_event_count", "query_operation_event_count",
    "query_leak_count", "cli_output_checked", "report_redacted", "audit_projection_safe",
    "audit_unchanged", "ciphertext_unchanged", "http_status", "http_error_code",
    "http_outcome_safe", "output_leak_count",
})
HISTORICAL_DISCLOSURE_FAILURE_CAPTURE_FIELDS = DISCLOSURE_FAILURE_CAPTURE_FIELDS - {"channel_attribution"}

# This map is the package acceptance boundary.  The two disclosure files are
# separate receipt inputs because their producers deliberately preserve that
# historical success/failure schema split.
REQUIRED_MATRIX = (
    *(("core", pair, store) for pair in ("locked", "floor") for store in ("builtin", "delegated")),
    *(("rollout", pair, store) for pair in ("locked", "floor") for store in ("builtin", "delegated")),
    *(("recovery", pair, store) for pair in ("locked", "floor") for store in ("builtin", "delegated")),
    *(("endpoints", pair, "builtin") for pair in ("locked", "floor")),
    *((group, pair, "delegated") for group in ("contention", "atomicity", "issuance", "disclosure", "disclosure-failure") for pair in ("locked", "floor")),
    ("legacy-control", "locked", "builtin"),
    ("release-rpc", "locked", "builtin"),
)
ROLLOUT_CASE_IDS = {
    ("rollout", pair, store): [f"VPROOF-02-ROLLOUT-READER-FIRST-{pair.upper()}-{store.upper()}"]
    for pair in ("locked", "floor") for store in ("builtin", "delegated")
}
ROLLOUT_CASE_IDS[("legacy-control", "locked", "builtin")] = ["VPROOF-02-PUBLIC-LEGACY-CONTROL"]


def required_receipt_keys() -> tuple[tuple[str, str, str], ...]:
    return REQUIRED_MATRIX


def expected_case_ids(key: tuple[str, str, str]) -> list[str]:
    scope, pair, _store = key
    if key in ROLLOUT_CASE_IDS:
        return ROLLOUT_CASE_IDS[key]
    if scope == "core":
        return [CORE_CASE_ID]
    if scope == "rollout":
        return ROLLOUT_CASE_IDS[key]
    if scope == "endpoints":
        return ENDPOINT_CASE_IDS
    if scope == "release-rpc":
        return [RELEASE_RPC_CASE_ID]
    if scope == "contention":
        return CONTENTION_CASE_IDS
    if scope == "atomicity":
        return ATOMICITY_CASE_IDS
    if scope == "recovery":
        return RECOVERY_CASE_IDS
    if scope == "issuance":
        return [ISSUANCE_CASE_IDS[pair]]
    if scope == "disclosure":
        return DISCLOSURE_CASE_IDS[pair]
    if scope == "disclosure-failure":
        return DISCLOSURE_FAILURE_CASE_IDS[pair]
    raise ReceiptError("matrix scope is outside the finite contract")


def validate_matrix_links(
    rows: list[dict[str, Any]], *, expected_runner: str,
    required_keys: tuple[tuple[str, str, str], ...] | None = None,
) -> list[dict[str, Any]]:
    """Validate the closed matrix index independently of its raw receipt bytes."""
    if not REVISION.fullmatch(expected_runner):
        raise ReceiptError("matrix runner identity is invalid")
    expected = set(REQUIRED_MATRIX if required_keys is None else required_keys)
    seen: set[tuple[str, str, str]] = set()
    run_ids: dict[str, dict[str, Any]] = {}
    candidate_bindings: set[tuple[str, str, str]] = set()
    normalized = []
    for row in rows:
        if not isinstance(row, dict):
            raise ReceiptError("matrix link is malformed")
        key = (row.get("scope"), row.get("pair"), row.get("store"))
        if key not in expected or key in seen:
            raise ReceiptError("matrix link is unknown or duplicated")
        seen.add(key)
        if row.get("runner_revision") != expected_runner:
            raise ReceiptError("matrix runner identity does not match the current execution")
        if not isinstance(row.get("run_id"), str) or not re.fullmatch(r"[0-9a-f]{32}", row["run_id"]):
            raise ReceiptError("matrix run identity is invalid")
        prior_run = run_ids.get(row["run_id"])
        if prior_run is not None:
            same_disclosure_run = (
                (prior_run["scope"], key[0]) in {
                    ("disclosure", "disclosure-failure"),
                    ("disclosure-failure", "disclosure"),
                }
                and (prior_run["pair"], prior_run["store"]) == key[1:]
                and key[2] == "delegated"
                and prior_run["candidate_source_archive_tree"] == row.get("candidate_source_archive_tree")
                and prior_run["host_lock_sha256"] == row.get("host_lock_sha256")
                and prior_run["compiled_candidate_sha256"] == row.get("compiled_candidate_sha256")
            )
            if not same_disclosure_run:
                raise ReceiptError("matrix run identity is duplicated outside one disclosure capture")
        else:
            run_ids[row["run_id"]] = row
        if not isinstance(row.get("receipt_sha256"), str) or not SHA.fullmatch(row["receipt_sha256"]):
            raise ReceiptError("matrix raw receipt digest is invalid")
        if row.get("outcome") != "pass" or type(row.get("executed_count")) is not int or row["executed_count"] <= 0:
            raise ReceiptError("matrix contains a failed or zero-execution receipt")
        candidate = row.get("candidate_source_archive_tree")
        if (not isinstance(candidate, list) or len(candidate) != 3
                or not REVISION.fullmatch(candidate[0])
                or any(not isinstance(value, str) or not SHA.fullmatch(value) for value in candidate[1:])):
            raise ReceiptError("matrix candidate source/archive/tree binding is incomplete")
        candidate_bindings.add(tuple(candidate))
        for field in ("host_lock_sha256", "compiled_candidate_sha256"):
            if not isinstance(row.get(field), str) or not SHA.fullmatch(row[field]):
                raise ReceiptError("matrix host lock or compiled identity is invalid")
        cases = row.get("stable_case_ids")
        if cases != expected_case_ids(key):
            raise ReceiptError("matrix case mapping is omitted, duplicated, or unexpected")
        normalized.append(row)
    if seen != expected:
        raise ReceiptError("complete installed verifier matrix is missing required receipts")
    if len(candidate_bindings) != 1:
        raise ReceiptError("matrix candidate source/archive/tree identities differ")
    return normalized


def validate_complete_matrix(rows: list[dict[str, Any]], *, expected_runner: str) -> list[dict[str, Any]]:
    """Named entrypoint used by the aggregate producer and offline contracts."""
    if not rows:
        raise ReceiptError("complete installed verifier matrix has no executed receipts")
    return validate_matrix_links(rows, expected_runner=expected_runner)


_OBSERVATION_STRINGS = frozenset({
    "outcome", "configured_issuer", "discovered_issuer", "assertion_audience", "rejected_audience_uri",
    "stale_error_code", "replay_error_code", "fresh_error_code", "missing_key_error_code",
    "old_secret_after_rotation_error_code", "new_secret_after_rotation_error_code",
    "channel_attribution", "scenario", "reason", "operation_result", "http_error_code", "process_pid", "release_node",
    "rpc_invocation", "check_invocation", "task_local_invocation", "compiled_module_relative_path",
    "compiled_module_sha256", "startup_context_source", "task_local_context_source",
    "startup_current_key_id", "task_local_current_key_id",
    "authenticated_age_kind_before", "authenticated_age_kind_after", "coverage",
    "dedicated_format_after", "legacy_format_before", "release_source_evidence", "http_auth_failure",
})
_OBSERVATION_COUNTS = frozenset({
    "rpc_exit_code", "check_exit_code", "task_local_exit_code", "dry_run_scanned", "dry_run_pending",
    "fresh_check_scanned", "failure_detail_count",
})


def _validate_value_types(receipt: Any, *, rollout: bool) -> None:
    """Close known value channels before any equality, hashing or copying.

    Structural key sets and semantic outcomes remain checked below. This layer
    makes every selected scalar's type explicit, including fields whose values
    are nullable. No exception includes an input value or representation.
    """
    if not isinstance(receipt, dict):
        raise ReceiptError("receipt root type is invalid")
    for field, value in receipt.items():
        if field in {"candidate", "host", "runtime", "predecessor", "source_proof", "processes", "observations"}:
            if not isinstance(value, dict):
                raise ReceiptError("receipt object type is invalid")
        elif field in {"fleet_limits", "stable_case_ids"}:
            if not isinstance(value, list) or any(type(item) is not str for item in value):
                raise ReceiptError("receipt string-list type is invalid")
        elif field == "partial":
            if type(value) is not bool:
                raise ReceiptError("receipt boolean type is invalid")
        elif field == "executed_count":
            if type(value) is not int or value <= 0:
                raise ReceiptError("receipt execution count is invalid")
        elif type(value) is not str:
            raise ReceiptError("receipt scalar type is invalid")
    for field in ("candidate", "host", "runtime", "predecessor", "source_proof"):
        if field not in receipt:
            continue
        for key, value in receipt[field].items():
            expected = bool if key == "resolved_dependency_verified" else str
            if type(value) is not expected:
                raise ReceiptError("receipt identity scalar type is invalid")
            if key == "version" and (len(value) > 96 or not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?", value)):
                raise ReceiptError("receipt package version is invalid")
            if field == "runtime" and (len(value) > 128 or not re.fullmatch(r"[0-9]+(?:\.[0-9]+)*(?:[-+ .(][A-Za-z0-9.+() _-]{0,100})?", value)):
                raise ReceiptError("receipt runtime version is invalid")
    for process in receipt.get("processes", {}).values():
        if not isinstance(process, dict):
            raise ReceiptError("receipt process object type is invalid")
        for key, value in process.items():
            if key == "pid":
                if type(value) is not int or value <= 0:
                    raise ReceiptError("receipt process PID type is invalid")
            elif type(value) is not str:
                raise ReceiptError("receipt process digest type is invalid")
    observations = receipt.get("observations", {})
    selected = [observations] if rollout else list(observations.values())
    for observation in selected:
        if not isinstance(observation, dict):
            raise ReceiptError("receipt observation object type is invalid")
        for key, value in observation.items():
            if key in _OBSERVATION_STRINGS:
                # The failure capture schema deliberately emits null when no
                # HTTP request or operation result exists.
                if value is None and key in {"http_error_code", "operation_result", "http_auth_failure"}:
                    continue
                if type(value) is not str:
                    raise ReceiptError("receipt observation string type is invalid")
                if key == "process_pid" and (not re.fullmatch(r"[1-9][0-9]{0,9}", value) or int(value) > 2**31 - 1):
                    raise ReceiptError("release process PID is invalid")
            elif key.endswith(("_count", "_pid", "_http_status")) or key in _OBSERVATION_COUNTS | {"http_status"}:
                if value is None and key == "http_status" and receipt.get("scope") == "disclosure-failure":
                    continue
                if type(value) is not int or value < 0 or (key.endswith("_pid") and value == 0):
                    raise ReceiptError("receipt observation integer type is invalid")
            elif type(value) is not bool:
                raise ReceiptError("receipt observation boolean type is invalid")


def _validate_rollout_structure(
    receipt: dict[str, Any], *, expected_pair: str, expected_store: str,
    expected_runner: str, expected_candidate_source: str, expected_scope: str,
) -> dict[str, Any]:
    """Validate the established rollout/public schema without restamping it."""
    _validate_value_types(receipt, rollout=True)
    required = {
        "schema", "scope", "run_id", "runner_revision", "pair", "store", "candidate",
        "predecessor", "source_proof", "host", "runtime", "processes", "observations",
        "executed_count", "partial", "fleet_limits",
    }
    if set(receipt) != required or receipt.get("schema") != "lockspire-installed-verifier-rollout-v1":
        raise ReceiptError("rollout receipt does not match its established schema")
    if (receipt.get("scope") != expected_scope or receipt.get("pair") != expected_pair
            or receipt.get("store") != expected_store or receipt.get("runner_revision") != expected_runner
            or receipt.get("partial") is not True or receipt.get("executed_count") != 1
            or not isinstance(receipt.get("run_id"), str)
            or not re.fullmatch(r"[0-9a-f]{32}", receipt["run_id"])):
        raise ReceiptError("rollout receipt scope or runner identity is invalid")
    candidate = receipt.get("candidate")
    if not isinstance(candidate, dict):
        raise ReceiptError("rollout candidate identity is missing")
    candidate_fields = {
        "kind", "version", "archive_sha256", "tree_sha256", "source_revision", "runner_revision",
        "source_proof", "vendor_tree_sha256", "compiled_candidate_sha256", "resolved_dependency_verified",
    }
    if set(candidate) != candidate_fields:
        raise ReceiptError("rollout candidate fields are outside the finite provenance contract")
    if (candidate.get("kind") not in {"checkout", "frozen"} or candidate.get("source_revision") != expected_candidate_source
            or candidate.get("runner_revision") != expected_runner
            or not isinstance(candidate.get("version"), str)
            or any(not isinstance(candidate.get(field), str) or not SHA.fullmatch(candidate[field])
                   for field in ("archive_sha256", "tree_sha256", "source_proof", "vendor_tree_sha256",
                                 "compiled_candidate_sha256"))
            or candidate.get("vendor_tree_sha256") != candidate.get("tree_sha256")
            or candidate.get("resolved_dependency_verified") is not True):
        raise ReceiptError("rollout candidate source binding is invalid")
    if candidate["kind"] == "checkout":
        proof = json.dumps({"archive_sha256": candidate["archive_sha256"],
                            "source_revision": candidate["source_revision"],
                            "tree_sha256": candidate["tree_sha256"]}, sort_keys=True, separators=(",", ":")).encode()
        if hashlib.sha256(proof).hexdigest() != candidate["source_proof"]:
            raise ReceiptError("rollout candidate digest does not bind source and package tree")
    predecessor = receipt.get("predecessor")
    source_proof = receipt.get("source_proof")
    if receipt.get("fleet_limits") != [
            "fleet parity", "fleet quiescence", "backup availability", "rollback safety"]:
        raise ReceiptError("fleet limitation declarations are outside the fixed contract")
    if expected_scope == "rollout":
        if not isinstance(predecessor, dict) or set(predecessor) != {
                "kind", "version", "archive_sha256", "tree_sha256", "source_revision", "compiled_candidate_sha256"}:
            raise ReceiptError("rollout predecessor fields are outside the finite provenance contract")
        if (predecessor.get("kind") != "accepted-git-source" or predecessor.get("version") != "1.6.1"
                or predecessor.get("source_revision") != PREDECESSOR_SOURCE
                or predecessor.get("archive_sha256") != PREDECESSOR_ARCHIVE_SHA256
                or predecessor.get("tree_sha256") != PREDECESSOR_TREE_SHA256
                or not isinstance(predecessor.get("compiled_candidate_sha256"), str)
                or not SHA.fullmatch(predecessor["compiled_candidate_sha256"])):
            raise ReceiptError("rollout predecessor identity is not the independently pinned source owner")
        if not isinstance(source_proof, dict) or set(source_proof) != {"commit_tree", "source_archive_sha256"}:
            raise ReceiptError("rollout predecessor source proof fields are incomplete")
        if (source_proof.get("commit_tree") != PREDECESSOR_COMMIT_TREE
                or source_proof.get("source_archive_sha256") != PREDECESSOR_SOURCE_ARCHIVE_SHA256):
            raise ReceiptError("rollout predecessor source proof differs from the pinned Git export")
        observed_tree = subprocess.run(
            ("git", "rev-parse", f"{PREDECESSOR_SOURCE}^{{tree}}"),
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False, timeout=10,
        )
        if (observed_tree.returncode != 0
                or observed_tree.stdout.decode("ascii", errors="strict").strip() != PREDECESSOR_COMMIT_TREE):
            raise ReceiptError("rollout predecessor Git source tree is unavailable or changed")
    host, runtime = receipt.get("host"), receipt.get("runtime")
    if (not isinstance(host, dict) or set(host) != {"lock_sha256", "phoenix", "live_view"}
            or not isinstance(runtime, dict)):
        raise ReceiptError("rollout host identity is missing")
    if (not isinstance(host.get("lock_sha256"), str) or not SHA.fullmatch(host["lock_sha256"])
            or (host.get("phoenix"), host.get("live_view")) != {
                "locked": ("1.8.13", "1.2.10"), "floor": ("1.8.5", "1.1.28")
            }[expected_pair]
            or set(runtime) != {"elixir", "otp", "postgresql"}
            or any(not isinstance(runtime[k], str) or not runtime[k] for k in runtime)):
        raise ReceiptError("rollout host lock or runtime identity is invalid")
    if expected_scope == "rollout":
        if (expected_pair, expected_store) not in {(p, s) for p in ("locked", "floor") for s in ("builtin", "delegated")}:
            raise ReceiptError("rollout pair/store is outside the supported matrix")
        observations = receipt.get("observations")
        if not isinstance(observations, dict) or set(observations) != ROLLOUT_OBSERVATION_FIELDS:
            raise ReceiptError("rollout observation fields are outside the finite contract")
        if receipt.get("fleet_limits") != [
                "fleet parity", "fleet quiescence", "backup availability", "rollback safety"]:
            raise ReceiptError("rollout fleet limitation declarations are outside the fixed contract")
        pid_fields = {field for field in ROLLOUT_OBSERVATION_FIELDS if field.endswith("_pid")}
        pids = [observations[field] for field in sorted(pid_fields)]
        if (any(type(pid) is not int or pid <= 0 for pid in pids)
                or len(set(pids)) != len(pids)
                or receipt["processes"].get("predecessor", {}).get("pid") == receipt["processes"].get("candidate", {}).get("pid")):
            raise ReceiptError("rollout process observations do not bind distinct owned roles")
        truth_fields = {
            "old_process_exit_observed", "legacy_write_read_shared_store", "dedicated_write_after_drain",
            "switch_back_legacy_write_preserves_dedicated", "old_code_rejects_dedicated",
            "rollback_retains_dedicated_reads", "old_code_legacy_control_succeeded",
            "legacy_hash_preserved", "dedicated_hash_present",
        }
        if (not isinstance(observations, dict) or observations.get("outcome") != "pass"
                or observations.get("executed") is not True
                or any(observations.get(field) is not True for field in truth_fields)
                or any(observations.get(field) is not False for field in
                       ("fleet_parity_proven", "quiescence_proven", "backup_proven"))):
            raise ReceiptError("rollout observations are incomplete")
        processes = receipt.get("processes")
        if not isinstance(processes, dict) or set(processes) != {"predecessor", "candidate"}:
            raise ReceiptError("rollout process role set is invalid")
        for role in ("predecessor", "candidate"):
            process = processes.get(role) if isinstance(processes, dict) else None
            if (not isinstance(process, dict) or set(process) != {"pid", "compiled_candidate_sha256"}
                    or type(process.get("pid")) is not int or process["pid"] <= 0):
                raise ReceiptError("rollout process identity is missing")
            if not isinstance(process.get("compiled_candidate_sha256"), str) or not SHA.fullmatch(process["compiled_candidate_sha256"]):
                raise ReceiptError("rollout compiled package identity is missing")
            expected_compiled = candidate["compiled_candidate_sha256"] if role == "candidate" else predecessor["compiled_candidate_sha256"]
            if process["compiled_candidate_sha256"] != expected_compiled:
                raise ReceiptError("rollout process compiled identity differs from its source owner")
    else:
        if expected_pair != "locked" or expected_store != "builtin":
            raise ReceiptError("public legacy control is restricted to locked/builtin")
        observations = receipt.get("observations")
        proof = receipt.get("source_proof")
        predecessor = receipt["predecessor"]
        if (predecessor.get("kind") != "public-hex" or predecessor.get("version") != "1.6.1"
                or predecessor.get("source_revision") != PUBLIC_SOURCE
                or predecessor.get("archive_sha256") != PUBLIC_ARCHIVE_SHA256
                or predecessor.get("tree_sha256") != PUBLIC_TREE_SHA256
                or set(predecessor) != {"kind", "version", "archive_sha256", "tree_sha256",
                                        "source_revision", "compiled_candidate_sha256"}):
            raise ReceiptError("public predecessor identity is not the independently pinned artifact")
        if not isinstance(observations, dict) or set(observations) != PUBLIC_OBSERVATION_FIELDS:
            raise ReceiptError("public control observation fields are outside the finite contract")
        required_public = {"public_pin_verified", "verifier_specific_adoption_executed", "http_authentication_succeeded",
                           "authenticated_deadline_preserved", "client_hash_preserved", "lifetime_prerequisite_migrated"}
        if any(observations.get(key) != value for key, value in {
            "release_source_evidence": "documented-public-release-source",
            "legacy_format_before": "legacy", "dedicated_format_after": "dedicated",
            "authenticated_age_kind_before": "migrated", "authenticated_age_kind_after": "migrated",
            "http_auth_failure": None, "coverage": "locked-only bounded public legacy producer/adopter control",
        }.items()):
            raise ReceiptError("public control fixed scalar observations are invalid")
        if (not isinstance(observations, dict) or observations.get("outcome") != "pass"
                or observations.get("executed") is not True
                or any(observations.get(field) is not True for field in required_public)
                or not isinstance(proof, dict)
                or set(proof) != {"public_source", "release_record_sha256", "release_evidence_sha256",
                                  "terminal_receipt_sha256", "archive_sha256", "package_tree_sha256",
                                  "source_commit_tree", "source_claim"}
                or proof.get("public_source") != PUBLIC_SOURCE
                or proof.get("archive_sha256") != PUBLIC_ARCHIVE_SHA256
                or proof.get("package_tree_sha256") != PUBLIC_TREE_SHA256
                or proof.get("source_claim") != "public package files byte-match independently exported source commit"
                or any(not isinstance(proof.get(field), str) or not SHA.fullmatch(proof[field])
                       for field in ("release_record_sha256", "release_evidence_sha256", "terminal_receipt_sha256"))):
            raise ReceiptError("public legacy control attribution or witness is incomplete")
        root = Path(__file__).resolve().parents[3]
        artifacts = (
            root / ".planning/RELEASE-TRAIN.md",
            root / ".planning/releases/1.6.1-EVIDENCE.md",
            root / ".planning/releases/1.6.1-terminal-receipt.json",
        )
        if any(not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != proof[field]
               for path, field in zip(artifacts, ("release_record_sha256", "release_evidence_sha256", "terminal_receipt_sha256"), strict=True)):
            raise ReceiptError("public control release evidence bytes are unavailable or changed")
        public_tree = subprocess.run(
            ("git", "rev-parse", f"{PUBLIC_SOURCE}^{{tree}}"),
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False, timeout=10,
        )
        if (public_tree.returncode != 0
                or public_tree.stdout.decode("ascii", errors="strict").strip() != proof.get("source_commit_tree")):
            raise ReceiptError("public predecessor source tree is unavailable or mismatched")
        processes = receipt.get("processes")
        if not isinstance(processes, dict) or set(processes) != {"predecessor", "candidate"}:
            raise ReceiptError("public control process roles are invalid")
        for role in ("predecessor", "candidate"):
            process = processes[role]
            if (not isinstance(process, dict) or set(process) != {"pid", "compiled_candidate_sha256"}
                    or type(process.get("pid")) is not int or process["pid"] <= 0
                    or not isinstance(process.get("compiled_candidate_sha256"), str)
                    or not SHA.fullmatch(process["compiled_candidate_sha256"])):
                raise ReceiptError("public control process identity is incomplete")
            owner = receipt["candidate"] if role == "candidate" else predecessor
            if process["compiled_candidate_sha256"] != owner.get("compiled_candidate_sha256"):
                raise ReceiptError("public control process does not match its independently pinned owner")
    return receipt


def _validate_historical_failure_capture(payload: object) -> dict[str, Any]:
    if not isinstance(payload, dict) or set(payload) != HISTORICAL_DISCLOSURE_FAILURE_CAPTURE_FIELDS:
        raise ReceiptError("historical disclosure failure fields do not match the retained contract")
    expected = {
        "malformed_crypto": ("malformed_verifier", 401, "invalid_client", False),
        "unknown_key_crypto": ("unknown_key", 401, "invalid_client", False),
        "storage_failure": ("maintenance_failed", 200, "other", True),
    }
    scenario = payload["scenario"]
    if type(scenario) is not str or scenario not in expected:
        raise ReceiptError("historical disclosure failure scenario is unsupported")
    reason, http_status, http_error_code, requires_storage_witness = expected[scenario]
    count_fields = (
        "failure_detail_count", "logger_event_count", "logger_control_event_count",
        "logger_operation_event_count", "logger_leak_count", "query_event_count",
        "query_control_event_count", "query_operation_event_count", "query_leak_count",
        "output_leak_count",
    )
    if any(type(payload[field]) is not int or payload[field] < 0 for field in count_fields):
        raise ReceiptError("historical disclosure failure count is invalid")
    if (
        payload["reason"] != reason
        or payload["operation_result"] != "failed"
        or payload["forced_failure_observed"] is not True
        or payload["failure_detail_count"] <= 0
        or payload["logger_event_count"] <= 0
        or payload["logger_control_event_count"] <= 0
        or payload["logger_event_count"] < payload["logger_control_event_count"]
        or payload["query_event_count"] <= 0
        or payload["query_control_event_count"] <= 0
        or payload["query_operation_event_count"] <= 0
        or payload["query_event_count"] < payload["query_control_event_count"]
        or any(payload[field] != 0 for field in ("logger_leak_count", "query_leak_count", "output_leak_count"))
        or payload["storage_failure_witness"] is not requires_storage_witness
        or type(payload["http_status"]) is not int
        or payload["http_status"] != http_status
        or payload["http_error_code"] != http_error_code
        or any(payload[field] is not True for field in (
            "cli_output_checked", "report_redacted", "audit_projection_safe",
            "audit_unchanged", "ciphertext_unchanged", "http_outcome_safe",
        ))
    ):
        raise ReceiptError("historical disclosure failure evidence is incomplete or unsafe")
    return payload


def validate_failure_capture(payload: object) -> dict[str, Any]:
    if not isinstance(payload, dict) or set(payload) != DISCLOSURE_FAILURE_CAPTURE_FIELDS:
        raise DisclosureCaptureRejected("capture_fields_invalid", payload)
    expected = {
        "malformed_crypto": ("malformed_verifier", 401, "invalid_client", False),
        "unknown_key_crypto": ("unknown_key", 401, "invalid_client", False),
        "storage_failure": ("maintenance_failed", 200, "other", True),
    }
    scenario = payload["scenario"]
    if type(scenario) is not str or scenario not in expected:
        raise DisclosureCaptureRejected("capture_scenario_unsupported", payload)
    reason, http_status, http_error_code, requires_storage_witness = expected[scenario]
    count_fields = (
        "failure_detail_count", "logger_event_count", "logger_control_event_count",
        "logger_operation_event_count", "logger_leak_count", "query_event_count",
        "query_control_event_count", "query_operation_event_count", "query_leak_count",
        "output_leak_count",
    )
    if any(type(payload[field]) is not int or payload[field] < 0 for field in count_fields):
        raise DisclosureCaptureRejected("capture_count_invalid", payload)
    if payload["channel_attribution"] != DISCLOSURE_CHANNEL_ATTRIBUTION:
        raise DisclosureCaptureRejected("channel_attribution_unsupported", payload)
    if payload["logger_control_event_count"] != 2 or payload["query_control_event_count"] != 1:
        raise DisclosureCaptureRejected("capture_controls_invalid", payload)
    if (
        payload["logger_event_count"] < payload["logger_control_event_count"] + payload["logger_operation_event_count"]
        or payload["query_event_count"] < payload["query_control_event_count"] + payload["query_operation_event_count"]
    ):
        raise DisclosureCaptureRejected("capture_totals_invalid", payload)
    if payload["logger_leak_count"] != 0 or payload["query_leak_count"] != 0 or payload["output_leak_count"] != 0:
        raise DisclosureCaptureRejected("capture_channel_leak_observed", payload)
    if (
        payload["reason"] != reason
        or payload["operation_result"] != "failed"
        or payload["forced_failure_observed"] is not True
        or payload["failure_detail_count"] <= 0
        or payload["logger_event_count"] <= 0
        or payload["query_event_count"] <= 0
        or payload["storage_failure_witness"] is not requires_storage_witness
        or type(payload["http_status"]) is not int
        or payload["http_status"] != http_status
        or payload["http_error_code"] != http_error_code
    ):
        raise DisclosureCaptureRejected("capture_domain_witness_invalid", payload)
    if any(payload[field] is not True for field in (
        "cli_output_checked", "report_redacted", "audit_projection_safe",
        "audit_unchanged", "ciphertext_unchanged", "http_outcome_safe",
    )):
        raise DisclosureCaptureRejected("capture_redaction_invalid", payload)
    return payload


def _unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ReceiptError("duplicate receipt field")
        result[key] = value
    return result


def load_receipt(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object)
    except (OSError, UnicodeError, json.JSONDecodeError, ReceiptError):
        raise ReceiptError("receipt is unavailable or malformed") from None
    if not isinstance(value, dict):
        raise ReceiptError("receipt root must be an object")
    return value


def _validate_receipt_structure(
    receipt: dict[str, Any], *, expected_pair: str | None = None,
    expected_store: str | None = None, historical_structure_only: bool = False,
) -> dict[str, Any]:
    _validate_value_types(receipt, rollout=False)
    if set(receipt) != ROOT_FIELDS:
        raise ReceiptError("receipt fields do not match the finite contract")
    if receipt["schema"] != SCHEMA or not isinstance(receipt["scope"], str) or receipt["scope"] not in GROUPS - {"all"}:
        raise ReceiptError("receipt schema or scope is unsupported")
    if receipt["partial"] is not True:
        raise ReceiptError("scenario group receipt must remain explicitly partial")
    if not isinstance(receipt["run_id"], str) or not re.fullmatch(r"[0-9a-f]{32}", receipt["run_id"]):
        raise ReceiptError("receipt run identity is invalid")
    if receipt["pair"] not in {"locked", "floor"} or (expected_pair and receipt["pair"] != expected_pair):
        raise ReceiptError("receipt dependency pair is invalid")
    if receipt["store"] not in {"builtin", "delegated"} or (expected_store and receipt["store"] != expected_store):
        raise ReceiptError("receipt storage composition is invalid")
    if not isinstance(receipt["runner"], str) or not REVISION.fullmatch(receipt["runner"]):
        raise ReceiptError("runner revision is missing")
    candidate = receipt["candidate"]
    if not isinstance(candidate, dict) or set(candidate) != IDENTITY_FIELDS:
        raise ReceiptError("candidate identity fields are incomplete")
    if candidate["kind"] not in {"checkout", "frozen"} or not isinstance(candidate["version"], str):
        raise ReceiptError("candidate source identity is untrusted")
    for key in ("archive_sha256", "tree_sha256", "source_proof"):
        if not isinstance(candidate[key], str) or not SHA.fullmatch(candidate[key]):
            raise ReceiptError("candidate byte binding is invalid")
    if not isinstance(candidate["source_revision"], str) or not REVISION.fullmatch(candidate["source_revision"]):
        raise ReceiptError("candidate source revision is unavailable")
    binding = json.dumps(
        {
            "archive_sha256": candidate["archive_sha256"],
            "source_revision": candidate["source_revision"],
            "tree_sha256": candidate["tree_sha256"],
        }, sort_keys=True, separators=(",", ":"),
    ).encode()
    if candidate["kind"] == "checkout" and candidate["source_proof"] != hashlib.sha256(binding).hexdigest():
        raise ReceiptError("candidate source proof does not bind the artifact and extracted tree")
    if candidate["runner_revision"] != receipt["runner"]:
        raise ReceiptError("runner identity does not match package preparation")
    host = receipt["host"]
    if not isinstance(host, dict) or set(host) != {"vendor_tree_sha256", "compiled_candidate_sha256", "resolved_dependency_verified", "lock_sha256", "phoenix", "live_view"}:
        raise ReceiptError("host dependency identity is incomplete")
    for key in ("vendor_tree_sha256", "compiled_candidate_sha256", "lock_sha256"):
        if not isinstance(host[key], str) or not SHA.fullmatch(host[key]):
            raise ReceiptError("host byte binding is invalid")
    if host["vendor_tree_sha256"] != candidate["tree_sha256"] or host["resolved_dependency_verified"] is not True:
        raise ReceiptError("installed vendor binding does not match candidate")
    if not isinstance(host["phoenix"], str) or not isinstance(host["live_view"], str):
        raise ReceiptError("resolved framework versions are missing")
    framework_versions = {
        "locked": ("1.8.13", "1.2.10"),
        "floor": ("1.8.5", "1.1.28"),
    }
    if (host["phoenix"], host["live_view"]) != framework_versions[receipt["pair"]]:
        raise ReceiptError("resolved framework versions do not match the selected pair")
    runtime = receipt["runtime"]
    if not isinstance(runtime, dict) or set(runtime) != {"elixir", "otp", "postgresql"} or any(not isinstance(runtime[k], str) or not runtime[k] for k in runtime):
        raise ReceiptError("runtime identity is incomplete")
    case_ids = receipt["stable_case_ids"]
    if not isinstance(case_ids, list) or not case_ids or any(not isinstance(item, str) or not CASE_ID.fullmatch(item) for item in case_ids):
        raise ReceiptError("stable case identity set is empty or malformed")
    if len(set(case_ids)) != len(case_ids):
        raise ReceiptError("stable case identity is duplicated")
    if receipt["scope"] == "core" and case_ids != [CORE_CASE_ID]:
        raise ReceiptError("core receipt does not contain its finite required case")
    observations = receipt["observations"]
    if not isinstance(observations, dict) or set(observations) != set(case_ids):
        raise ReceiptError("receipt outcomes omit or add a case")
    allowed_observation_fields = (
        CORE_OBSERVATION_FIELDS if receipt["scope"] == "core"
        else ENDPOINT_OBSERVATION_FIELDS | ENDPOINT_LIFECYCLE_FIELDS | ENDPOINT_FAPI_FIELDS
        if receipt["scope"] == "endpoints"
        else RELEASE_RPC_OBSERVATION_FIELDS if receipt["scope"] == "release-rpc"
        else CONTENTION_OBSERVATION_FIELDS if receipt["scope"] == "contention"
        else frozenset().union(*ATOMICITY_OBSERVATION_FIELDS.values()) if receipt["scope"] == "atomicity"
        else RECOVERY_OBSERVATION_FIELDS if receipt["scope"] == "recovery"
        else ISSUANCE_OBSERVATION_FIELDS if receipt["scope"] == "issuance"
        else (HISTORICAL_DISCLOSURE_SUCCESS_FIELDS if historical_structure_only else DISCLOSURE_SUCCESS_FIELDS)
        if receipt["scope"] == "disclosure"
        else (HISTORICAL_DISCLOSURE_FAILURE_FIELDS if historical_structure_only else DISCLOSURE_FAILURE_FIELDS)
        if receipt["scope"] == "disclosure-failure"
        else TRACER_OBSERVATION_FIELDS
    )
    if receipt["scope"] == "endpoints" and case_ids != ENDPOINT_CASE_IDS:
        raise ReceiptError("endpoint receipt does not contain its finite required case set")
    if receipt["scope"] == "release-rpc" and case_ids != [RELEASE_RPC_CASE_ID]:
        raise ReceiptError("release RPC receipt does not contain its finite required case")
    if receipt["scope"] == "contention" and case_ids != CONTENTION_CASE_IDS:
        raise ReceiptError("contention receipt omits a required lock order")
    if receipt["scope"] == "atomicity" and case_ids != ATOMICITY_CASE_IDS:
        raise ReceiptError("atomicity receipt omits a required rollback or commit-order case")
    if receipt["scope"] == "recovery" and case_ids != RECOVERY_CASE_IDS:
        raise ReceiptError("recovery receipt omits a required preservation or recovery case")
    if receipt["scope"] == "issuance" and case_ids != [ISSUANCE_CASE_IDS[receipt["pair"]]]:
        raise ReceiptError("issuance receipt does not match its selected dependency pair")
    if receipt["scope"] == "disclosure" and case_ids != DISCLOSURE_CASE_IDS[receipt["pair"]]:
        raise ReceiptError("disclosure receipt does not contain its success scenario")
    if receipt["scope"] == "disclosure-failure" and case_ids != DISCLOSURE_FAILURE_CASE_IDS[receipt["pair"]]:
        raise ReceiptError("disclosure failure receipt does not contain its finite scenario set")
    for case_id, result in observations.items():
        if not isinstance(result, dict) or not set(result).issubset(allowed_observation_fields):
            raise ReceiptError("observation fields are outside the allowlist")
        if result.get("outcome") != "pass" or result.get("executed") is not True:
            raise ReceiptError("required installed scenario did not pass")
        if "http_status" in result and (type(result["http_status"]) is not int or not 100 <= result["http_status"] <= 599):
            raise ReceiptError("observation HTTP status is invalid")
        boolean_fields = (
            {"assertion_passed", "fresh_jti", *ENDPOINT_LIFECYCLE_FIELDS, *ENDPOINT_FAPI_FIELDS}
            if receipt["scope"] == "endpoints"
            else {"executed", "assembly_succeeded", "running_process_observed", "rpc_executed",
                  "startup_mode_dedicated", "task_local_mode_dedicated", "task_local_check_ready",
                  "rpc_dry_run_complete", "rpc_fresh_check_ready", "loaded_candidate_verified"}
            if receipt["scope"] == "release-rpc"
            else CONTENTION_OBSERVATION_FIELDS - {"outcome", "executed", "holder_backend_pid", "contender_backend_pid"}
            if receipt["scope"] == "contention"
            else ISSUANCE_OBSERVATION_FIELDS - {
                "outcome", "executed", "stale_http_status", "stale_error_code", "replay_http_status",
                "replay_error_code", "fresh_http_status", "fresh_error_code", "discovery_http_status"
            }
            if receipt["scope"] == "issuance"
            else DISCLOSURE_SUCCESS_FIELDS - {
                "outcome", "executed", "http_status", "logger_event_count", "query_event_count",
                "logger_control_event_count", "logger_operation_event_count",
                "query_control_event_count", "query_operation_event_count",
                "logger_leak_count", "query_leak_count", "output_leak_count", "channel_attribution",
            }
            if receipt["scope"] == "disclosure"
            else frozenset()
            if receipt["scope"] == "disclosure-failure"
            else RECOVERY_OBSERVATION_FIELDS - {
                "outcome", "executed", "missing_key_http_status", "missing_key_error_code",
                "basic_http_status", "post_http_status", "restored_http_status",
                "old_secret_after_rotation_http_status", "old_secret_after_rotation_error_code",
                "new_secret_after_rotation_http_status", "new_secret_after_rotation_error_code",
                "expired_http_status",
            }
            if receipt["scope"] == "recovery"
            else allowed_observation_fields - {"outcome", "executed", "http_status"}
        )
        if any(key in result and type(result[key]) is not bool for key in boolean_fields):
            raise ReceiptError("observation boolean field is invalid")
        if receipt["scope"] == "tracer" and (
            set(result) != TRACER_OBSERVATION_FIELDS
            or result["http_status"] != 200
            or result["token_issued"] is not True
            or result["dedicated_verifier_persisted"] is not True
            or result["fresh_signed_assertion"] is not True
        ):
            raise ReceiptError("installed tracer outcome is incomplete")
        if receipt["scope"] == "core":
            if set(result) != CORE_OBSERVATION_FIELDS:
                raise ReceiptError("installed core outcome is incomplete")
            required_true = CORE_OBSERVATION_FIELDS - {
                "outcome", "executed", "http_status", "authority_rejections_before_access",
                "delegated_callbacks_observed",
            }
            if any(result.get(field) is not True for field in required_true):
                raise ReceiptError("installed core maintenance outcome did not pass")
            if receipt["store"] == "delegated":
                if result["authority_rejections_before_access"] is not True or result["delegated_callbacks_observed"] is not True:
                    raise ReceiptError("delegated core authority witness is incomplete")
            elif result["authority_rejections_before_access"] is not False or result["delegated_callbacks_observed"] is not False:
                raise ReceiptError("built-in core receipt contains delegated adapter claims")
            if result["http_status"] != 200:
                raise ReceiptError("installed core token flow did not return HTTP 200")
        if receipt["scope"] == "contention":
            if (set(result) != CONTENTION_OBSERVATION_FIELDS
                    or type(result["holder_backend_pid"]) is not int
                    or type(result["contender_backend_pid"]) is not int
                    or result["holder_backend_pid"] <= 0
                    or result["contender_backend_pid"] <= 0
                    or result["holder_backend_pid"] == result["contender_backend_pid"]
                    or result["blocker_observed"] is not True
                    or result["credential_pair_coherent"] is not True
                    or result["durable_state_verified"] is not True
                    or result["material_conflict"] is not (case_id == CONTENTION_CASE_IDS[0])):
                raise ReceiptError("contention witness lacks the exact blocker or durable row outcome")
        if receipt["scope"] == "atomicity":
            required_fields = ATOMICITY_OBSERVATION_FIELDS[case_id]
            if set(result) != required_fields or any(
                type(result.get(field)) is not bool or result[field] is not True
                for field in required_fields - {"outcome", "executed"}
            ):
                raise ReceiptError("atomicity receipt lacks a reached rollback or commit-order witness")
        if receipt["scope"] == "recovery":
            required = {
                RECOVERY_CASE_IDS[0]: {"hash_preserved", "partner_secret_preserved", "client_fields_preserved", "age_metadata_preserved", "ciphertext_changed", "audit_inserted"},
                RECOVERY_CASE_IDS[1]: {"repeat_no_change", "partial_not_ready", "interruption_not_ready", "indeterminate_not_claimed_rollback", "fresh_complete_check_ready"},
                RECOVERY_CASE_IDS[2]: {
                    "missing_key_rejected", "affected_status_redacted", "basic_usable", "post_usable",
                    "original_secret_preserved", "rotation_secret_changed", "one_time_handoff",
                    "missing_startup_context_bound", "missing_startup_context_has_protecting_key",
                    "restored_startup_context_has_protecting_key", "missing_key_http_status",
                    "missing_key_error_code", "basic_http_status", "post_http_status",
                    "restored_http_status", "old_secret_after_rotation_http_status",
                    "old_secret_after_rotation_error_code", "new_secret_after_rotation_http_status",
                    "new_secret_after_rotation_error_code",
                },
                RECOVERY_CASE_IDS[3]: {"expired_rewrap_committed", "expired_http_auth_rejected", "deadline_preserved", "expired_http_status"},
            }[case_id]
            if set(result) != required | {"outcome", "executed"}:
                raise ReceiptError("recovery receipt omits preservation or independent recovery evidence")
            boolean_requirements = {
                "missing_startup_context_has_protecting_key": False,
                "restored_startup_context_has_protecting_key": True,
            }
            if any(
                (result.get(field) is not expected)
                for field, expected in boolean_requirements.items()
                if field in required
            ) or any(
                result.get(field) is not True
                for field in required
                if field not in boolean_requirements
                and not field.endswith(("_http_status", "_error_code"))
            ):
                raise ReceiptError("recovery receipt omits preservation or independent recovery evidence")
            expected_statuses = {
                RECOVERY_CASE_IDS[2]: {
                    "missing_key_http_status": 401, "basic_http_status": 200,
                    "post_http_status": 200, "restored_http_status": 200,
                    "old_secret_after_rotation_http_status": 401,
                    "new_secret_after_rotation_http_status": 200,
                },
                RECOVERY_CASE_IDS[3]: {"expired_http_status": 401},
            }.get(case_id, {})
            if any(type(result.get(field)) is not int or result[field] != status for field, status in expected_statuses.items()):
                raise ReceiptError("recovery receipt HTTP status does not match its source-owned outcome")
            expected_errors = {
                "missing_key_error_code": "invalid_client",
                "old_secret_after_rotation_error_code": "invalid_client",
                "new_secret_after_rotation_error_code": "other",
            } if case_id == RECOVERY_CASE_IDS[2] else {}
            if any(result.get(field) != value for field, value in expected_errors.items()):
                raise ReceiptError("recovery receipt OAuth error category is invalid")
        if receipt["scope"] == "issuance":
            required = ISSUANCE_OBSERVATION_FIELDS - {
                "outcome", "executed", "stale_http_status", "stale_error_code", "replay_http_status",
                "replay_error_code", "fresh_http_status", "fresh_error_code", "discovery_http_status"
            }
            if (set(result) != ISSUANCE_OBSERVATION_FIELDS
                    or any(type(result.get(field)) is not bool or result[field] is not True for field in required)
                    or type(result["discovery_http_status"]) is not int or result["discovery_http_status"] != 200
                    or type(result["stale_http_status"]) is not int or result["stale_http_status"] != 401
                    or type(result["replay_http_status"]) is not int or result["replay_http_status"] != 401
                    or type(result["fresh_http_status"]) is not int or result["fresh_http_status"] != 200):
                raise ReceiptError("issuance receipt lacks a committed stale-identity or fresh-JTI HTTP witness")
            if any(result.get(field) != expected for field, expected in {
                "stale_error_code": "invalid_client",
                "replay_error_code": "invalid_client",
                "fresh_error_code": "other",
            }.items()):
                raise ReceiptError("issuance receipt OAuth error category does not match its source-owned outcome")
        if receipt["scope"] == "disclosure":
            count_fields = {
                "logger_event_count", "query_event_count", "logger_leak_count",
                "query_leak_count", "output_leak_count", "logger_control_event_count",
                "logger_operation_event_count", "query_control_event_count", "query_operation_event_count",
            }
            historical_invalid = (
                historical_structure_only
                and (
                    set(result) != HISTORICAL_DISCLOSURE_SUCCESS_FIELDS
                    or result["logger_control_event_count"] == 0
                    or result["query_control_event_count"] == 0
                    or result["query_operation_event_count"] == 0
                )
            )
            current_invalid = (
                not historical_structure_only
                and (
                    set(result) != DISCLOSURE_SUCCESS_FIELDS
                    or result["channel_attribution"] != DISCLOSURE_CHANNEL_ATTRIBUTION
                    or result["logger_control_event_count"] != 2
                    or result["query_control_event_count"] != 1
                    or result["logger_event_count"] < result["logger_control_event_count"] + result["logger_operation_event_count"]
                    or result["query_event_count"] < result["query_control_event_count"] + result["query_operation_event_count"]
                )
            )
            if (
                historical_invalid or current_invalid
                or any(type(result[field]) is not int or result[field] < 0 for field in count_fields)
                or result["logger_event_count"] == 0
                or result["query_event_count"] == 0
                or (not historical_structure_only and result["channel_attribution"] != DISCLOSURE_CHANNEL_ATTRIBUTION)
                or any(result[field] != 0 for field in ("logger_leak_count", "query_leak_count", "output_leak_count"))
                or any(result[field] is not True for field in (
                    "cli_output_checked", "audit_projection_safe", "nested_inspection_redacted",
                    "one_time_handoff_usable", "maintenance_changed",
                ))
                or result["http_status"] != 200
            ):
                raise ReceiptError("disclosure success channel evidence is incomplete or unsafe")
        if receipt["scope"] == "disclosure-failure":
            expected_failure_fields = (
                HISTORICAL_DISCLOSURE_FAILURE_FIELDS if historical_structure_only else DISCLOSURE_FAILURE_FIELDS
            )
            if set(result) != expected_failure_fields:
                raise ReceiptError("disclosure failure observation fields are incomplete")
            scenario_by_case = dict(zip(DISCLOSURE_FAILURE_CASE_IDS[receipt["pair"]], (
                "malformed_crypto", "unknown_key_crypto", "storage_failure"
            )))
            if result.get("scenario") != scenario_by_case[case_id]:
                raise ReceiptError("disclosure failure case ID does not match its scenario")
            capture = {key: value for key, value in result.items() if key not in {"outcome", "executed"}}
            if historical_structure_only:
                _validate_historical_failure_capture(capture)
            else:
                validate_failure_capture(capture)
        endpoint_expected_fields = ENDPOINT_OBSERVATION_FIELDS
        if receipt["scope"] == "endpoints" and case_id == "VPROOF-02-HTTP-REVOCATION-JWT":
            endpoint_expected_fields |= ENDPOINT_LIFECYCLE_FIELDS
        elif receipt["scope"] == "endpoints" and case_id == "VPROOF-02-HTTP-JWT-NEGATIVE-CONTROLS":
            endpoint_expected_fields |= ENDPOINT_FAPI_FIELDS
        if receipt["scope"] == "endpoints" and (
            set(result) != endpoint_expected_fields
            or result["http_status"] < 100 or result["assertion_passed"] is not True
            or result["fresh_jti"] is not True
            or result["configured_issuer"] != result["discovered_issuer"]
            or result["assertion_audience"] != result["configured_issuer"]
            or result["rejected_audience_uri"] == result["configured_issuer"]
            or not isinstance(result["configured_issuer"], str)
            or not re.fullmatch(r"http://127\.0\.0\.1:[1-9][0-9]{0,4}/lockspire", result["configured_issuer"])
            or int(result["configured_issuer"].split(":")[2].split("/")[0]) > 65535
            or result["rejected_audience_uri"] != result["configured_issuer"] + "/wrong"
        ):
            raise ReceiptError("installed endpoint observation is incomplete")
        if receipt["scope"] == "endpoints" and (
            (ENDPOINT_LIFECYCLE_FIELDS & set(result) and result["revoked_token_inactive"] is not True)
            or (ENDPOINT_FAPI_FIELDS & set(result) and any(result[field] is not True for field in ENDPOINT_FAPI_FIELDS))
        ):
            raise ReceiptError("installed endpoint lifecycle or FAPI exclusion evidence is incomplete")
        if receipt["scope"] == "release-rpc":
            bool_fields = {
                "executed", "assembly_succeeded", "running_process_observed", "rpc_executed",
                "startup_mode_dedicated", "task_local_mode_dedicated", "task_local_check_ready",
                "rpc_dry_run_complete", "rpc_fresh_check_ready", "loaded_candidate_verified",
            }
            int_fields = {"rpc_exit_code", "check_exit_code", "task_local_exit_code", "dry_run_scanned",
                          "dry_run_pending", "fresh_check_scanned"}
            string_fields = {"process_pid", "release_node", "rpc_invocation", "check_invocation",
                             "task_local_invocation", "compiled_module_relative_path",
                             "compiled_module_sha256", "startup_context_source", "task_local_context_source",
                             "startup_current_key_id", "task_local_current_key_id"}
            if (set(result) != RELEASE_RPC_OBSERVATION_FIELDS
                    or any(type(result.get(key)) is not bool for key in bool_fields)
                    or any(type(result.get(key)) is not int for key in int_fields)
                    or any(not isinstance(result.get(key), str) or not result[key] for key in string_fields)):
                raise ReceiptError("running-release RPC observation is incomplete")
            if any(result[field] != literal for field, literal in RELEASE_RPC_INVOCATIONS.items()):
                raise ReceiptError("running-release RPC invocation labels differ from the producer contract")
            if (result["rpc_exit_code"] != 0 or result["check_exit_code"] != 0
                    or result["task_local_exit_code"] != 0 or result["compiled_module_sha256"] is None
                    or not SHA.fullmatch(result["compiled_module_sha256"])
                    or result["compiled_module_relative_path"] != (
                        f"lib/lockspire-{candidate['version']}/ebin/Elixir.Lockspire.Admin.ClientVerifierMaintenance.beam")
                    or result["release_node"] != f"lockspire-verifier-{receipt['run_id'][:12]}@127.0.0.1"
                    or result["startup_context_source"] != "startup"
                    or result["task_local_context_source"] != "task_local"
                    or result["startup_current_key_id"] != "release-startup"
                    or result["task_local_current_key_id"] != "task-local"
                    or not all(result[key] for key in bool_fields)):
                raise ReceiptError("running-release RPC proof did not bind the assembled candidate")
    if type(receipt["executed_count"]) is not int or receipt["executed_count"] <= 0 or receipt["executed_count"] != len(case_ids):
        raise ReceiptError("receipt has no reconciled execution count")
    return receipt


def receipt_digest(receipt: dict[str, Any]) -> str:
    return hashlib.sha256(json.dumps(receipt, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def _verify_receipt_owner(receipt, owner):
    from verifier_receipt_owner import selected_owner, OwnerError
    try:
        (owner or selected_owner()).validate(receipt)
    except (OwnerError, OSError, ValueError, TypeError, KeyError):
        raise ReceiptError("receipt lacks matching independent package/runtime authority") from None


def validate_receipt(receipt, *, expected_pair=None, expected_store=None, owner=None):
    _validate_receipt_structure(receipt, expected_pair=expected_pair, expected_store=expected_store)
    _verify_receipt_owner(receipt, owner)
    return receipt


def validate_rollout_receipt(receipt, *, expected_pair, expected_store, expected_runner,
                             expected_candidate_source, expected_scope, owner=None):
    _validate_rollout_structure(receipt, expected_pair=expected_pair, expected_store=expected_store,
        expected_runner=expected_runner, expected_candidate_source=expected_candidate_source, expected_scope=expected_scope)
    _verify_receipt_owner(receipt, owner)
    return receipt

