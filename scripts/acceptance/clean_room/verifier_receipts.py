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
    "contention", "atomicity", "recovery", "issuance", "disclosure", "all",
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
ENDPOINT_OBSERVATION_FIELDS = frozenset({"outcome", "executed", "assertion_passed", "fresh_jti", "http_status"})
CORE_CASE_ID = "VPROOF-02-CORE-FRESH-MAINTENANCE"
CORE_OBSERVATION_FIELDS = frozenset({
    "outcome", "executed", "http_status", "token_issued", "dedicated_verifier_persisted",
    "fresh_signed_assertion", "dry_run_reported", "dry_run_unchanged", "apply_committed",
    "fresh_check_ready", "authority_rejections_before_access", "unknown_material_rejected",
    "partial_inventory_rejected", "delegated_callbacks_observed", "client_hash_preserved",
})


class ReceiptError(ValueError):
    pass


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
        else ENDPOINT_OBSERVATION_FIELDS if receipt["scope"] == "endpoints"
        else TRACER_OBSERVATION_FIELDS
    )
    if receipt["scope"] == "endpoints" and case_ids != ENDPOINT_CASE_IDS:
        raise ReceiptError("endpoint receipt does not contain its finite required case set")
    for result in observations.values():
        if not isinstance(result, dict) or not set(result).issubset(allowed_observation_fields):
            raise ReceiptError("observation fields are outside the allowlist")
        if result.get("outcome") != "pass" or result.get("executed") is not True:
            raise ReceiptError("required installed scenario did not pass")
        if "http_status" in result and (type(result["http_status"]) is not int or not 100 <= result["http_status"] <= 599):
            raise ReceiptError("observation HTTP status is invalid")
        if any(key in result and type(result[key]) is not bool for key in allowed_observation_fields - {"outcome", "executed", "http_status"}):
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
        if receipt["scope"] == "endpoints" and (
            set(result) != ENDPOINT_OBSERVATION_FIELDS
            or result["http_status"] < 100 or result["assertion_passed"] is not True
            or result["fresh_jti"] is not True
        ):
            raise ReceiptError("installed endpoint observation is incomplete")
    if type(receipt["executed_count"]) is not int or receipt["executed_count"] <= 0 or receipt["executed_count"] != len(case_ids):
        raise ReceiptError("receipt has no reconciled execution count")
    return receipt


def receipt_digest(receipt: dict[str, Any]) -> str:
    return hashlib.sha256(json.dumps(receipt, sort_keys=True, separators=(",", ":")).encode()).hexdigest()

