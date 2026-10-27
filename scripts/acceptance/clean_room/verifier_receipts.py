"""Finite, strict evidence contract for installed verifier scenario groups."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
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
    "outcome", "executed", "logger_event_count", "query_event_count",
    "logger_control_event_count", "logger_operation_event_count",
    "query_control_event_count", "query_operation_event_count",
    "logger_leak_count", "query_leak_count", "output_leak_count",
    "cli_output_checked", "audit_projection_safe", "nested_inspection_redacted",
    "one_time_handoff_usable", "maintenance_changed", "http_status",
})
DISCLOSURE_FAILURE_FIELDS = frozenset({
    "outcome", "executed", "scenario", "reason", "forced_failure_observed",
    "operation_result", "failure_detail_count", "storage_failure_witness",
    "logger_event_count", "logger_control_event_count", "logger_operation_event_count",
    "logger_leak_count", "query_event_count", "query_control_event_count",
    "query_operation_event_count", "query_leak_count", "cli_output_checked",
    "report_redacted", "audit_projection_safe", "audit_unchanged", "ciphertext_unchanged",
    "http_status", "http_error_code", "http_outcome_safe", "output_leak_count",
})
CORE_OBSERVATION_FIELDS = frozenset({
    "outcome", "executed", "http_status", "token_issued", "dedicated_verifier_persisted",
    "fresh_signed_assertion", "dry_run_reported", "dry_run_unchanged", "apply_committed",
    "fresh_check_ready", "authority_rejections_before_access", "unknown_material_rejected",
    "partial_inventory_rejected", "delegated_callbacks_observed", "client_hash_preserved",
})


class ReceiptError(ValueError):
    pass


DISCLOSURE_FAILURE_CAPTURE_FIELDS = frozenset({
    "scenario", "reason", "forced_failure_observed", "operation_result",
    "failure_detail_count", "storage_failure_witness", "logger_event_count",
    "logger_control_event_count", "logger_operation_event_count", "logger_leak_count",
    "query_event_count", "query_control_event_count", "query_operation_event_count",
    "query_leak_count", "cli_output_checked", "report_redacted", "audit_projection_safe",
    "audit_unchanged", "ciphertext_unchanged", "http_status", "http_error_code",
    "http_outcome_safe", "output_leak_count",
})


def validate_failure_capture(payload: object) -> dict[str, Any]:
    if not isinstance(payload, dict) or set(payload) != DISCLOSURE_FAILURE_CAPTURE_FIELDS:
        raise ReceiptError("disclosure failure fields do not match the finite contract")
    expected = {
        "malformed_crypto": ("malformed_verifier", 401, "invalid_client", False),
        "unknown_key_crypto": ("unknown_key", 401, "invalid_client", False),
        "storage_failure": ("maintenance_failed", 200, "other", True),
    }
    scenario = payload["scenario"]
    if type(scenario) is not str or scenario not in expected:
        raise ReceiptError("disclosure failure scenario is outside the finite contract")
    reason, http_status, http_error_code, requires_storage_witness = expected[scenario]
    count_fields = (
        "failure_detail_count", "logger_event_count", "logger_control_event_count",
        "logger_operation_event_count", "logger_leak_count", "query_event_count",
        "query_control_event_count", "query_operation_event_count", "query_leak_count",
        "output_leak_count",
    )
    if any(type(payload[field]) is not int or payload[field] < 0 for field in count_fields):
        raise ReceiptError("disclosure failure count is invalid")
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
        or payload["logger_leak_count"] != 0
        or payload["query_leak_count"] != 0
        or payload["output_leak_count"] != 0
        or payload["storage_failure_witness"] is not requires_storage_witness
        or type(payload["http_status"]) is not int
        or payload["http_status"] != http_status
        or payload["http_error_code"] != http_error_code
        or any(payload[field] is not True for field in (
            "cli_output_checked", "report_redacted", "audit_projection_safe",
            "audit_unchanged", "ciphertext_unchanged", "http_outcome_safe",
        ))
    ):
        raise ReceiptError("disclosure forced-failure evidence is incomplete or unsafe")
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


def validate_receipt(receipt: dict[str, Any], *, expected_pair: str | None = None, expected_store: str | None = None) -> dict[str, Any]:
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
    if candidate["kind"] != "checkout" or not isinstance(candidate["version"], str):
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
        },
        sort_keys=True,
        separators=(",", ":"),
    ).encode()
    if candidate["source_proof"] != hashlib.sha256(binding).hexdigest():
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
        else DISCLOSURE_SUCCESS_FIELDS if receipt["scope"] == "disclosure"
        else DISCLOSURE_FAILURE_FIELDS if receipt["scope"] == "disclosure-failure"
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
                "logger_leak_count", "query_leak_count", "output_leak_count",
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
            if (
                set(result) != DISCLOSURE_SUCCESS_FIELDS
                or any(type(result[field]) is not int or result[field] < 0 for field in count_fields)
                or result["logger_event_count"] == 0
                or result["query_event_count"] == 0
                or result["logger_control_event_count"] == 0
                or result["query_control_event_count"] == 0
                or result["query_operation_event_count"] == 0
                or any(result[field] != 0 for field in ("logger_leak_count", "query_leak_count", "output_leak_count"))
                or any(result[field] is not True for field in (
                    "cli_output_checked", "audit_projection_safe", "nested_inspection_redacted",
                    "one_time_handoff_usable", "maintenance_changed",
                ))
                or result["http_status"] != 200
            ):
                raise ReceiptError("disclosure success channel evidence is incomplete or unsafe")
        if receipt["scope"] == "disclosure-failure":
            if set(result) != DISCLOSURE_FAILURE_FIELDS:
                raise ReceiptError("disclosure failure observation fields are incomplete")
            scenario_by_case = dict(zip(DISCLOSURE_FAILURE_CASE_IDS[receipt["pair"]], (
                "malformed_crypto", "unknown_key_crypto", "storage_failure"
            )))
            if result.get("scenario") != scenario_by_case[case_id]:
                raise ReceiptError("disclosure failure case ID does not match its scenario")
            validate_failure_capture({key: value for key, value in result.items() if key not in {"outcome", "executed"}})
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
            or not result["configured_issuer"].startswith(("http://", "https://"))
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
            if (result["rpc_exit_code"] != 0 or result["check_exit_code"] != 0
                    or result["task_local_exit_code"] != 0 or result["compiled_module_sha256"] is None
                    or not SHA.fullmatch(result["compiled_module_sha256"])
                    or result["compiled_module_relative_path"].startswith("/")
                    or "../" in result["compiled_module_relative_path"]
                    or not result["compiled_module_relative_path"].startswith("lib/lockspire-")
                    or result["release_node"].startswith("-")
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

