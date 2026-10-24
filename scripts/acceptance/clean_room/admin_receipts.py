"""Strict, allowlisted receipts for the packaged admin browser proof."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import tempfile
import uuid
from typing import Any, Sequence


ROOT_FIELDS = frozenset({"schema_version", "run_id", "source_revision", "source_dirty", "candidate", "pair", "runtime", "mount", "evidence_kind", "scenarios", "cleanup", "result"})
CANDIDATE_FIELDS = frozenset({"version", "archive_sha256", "tree_sha256"})
RUNTIME_FIELDS = frozenset({"phoenix", "live_view", "elixir", "otp", "node", "chrome"})
RUNTIME_PATTERNS = {
    "phoenix": r"\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?",
    "live_view": r"\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?",
    "elixir": r"\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?",
    "otp": r"\d+",
    "node": r"\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?",
    "chrome": r"Chrome/\d+(?:\.\d+){1,3}",
}
SCENARIO_FIELDS = frozenset({"id", "outcome", "counts", "duration_ms", "observations"})
CLEANUP_FIELDS = frozenset({"processes_stopped", "database_removed", "profile_removed", "run_root_removed"})
REQUIRED = frozenset({"tracer.browser_join_navigation"})
FULL_REQUIRED = frozenset({
    "allowed_entry", "assets", "live_navigation", "params_patch", "detail_task", "allowed_reconnect",
    "anonymous_http_denied", "nonstaff_http_denied", "cached_join_denied", "reconnect_denied",
    "params_denied", "public_session_denied", "consent_session_denied", "public_discovery",
    "public_jwks", "public_protocol_error",
})
FULL_COUNTS = frozenset({"assets", "websocket_handshakes", "successful_joins", "navigations", "params_checks", "http_checks", "staff_checks"})
FULL_OBSERVATIONS = frozenset({
    "static_200", "assets_200", "join_allowed", "protected_content", "live_navigation", "params_patch",
    "detail_task", "socket_closed", "reconnect_join", "interaction_after_reconnect", "anonymous_denied",
    "nonstaff_denied", "cached_join_denied", "reconnect_denied", "params_denied", "public_session_denied",
    "consent_session_denied", "discovery_200", "jwks_200", "protocol_error_shape", "no_staff_checks",
    "protected_content_absent", "prefix_ok",
})
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
MOUNTS = frozenset({"/lockspire", "/teams/ops/identity", "/"})
PAIR_RUNTIME_VERSIONS = {
    "locked": ("1.8.13", "1.2.10"),
    "floor": ("1.8.5", "1.1.28"),
}


def _exact(value: object, fields: frozenset[str], name: str) -> dict[str, Any]:
    if not isinstance(value, dict) or set(value) != fields:
        raise ValueError(f"receipt {name} fields are invalid")
    return value


def validate_receipt(
    raw: object,
    *,
    expected_run_id: str | None = None,
    expected_source: str | None = None,
    expected_pair: str | None = None,
    expected_mount: str | None = None,
    expected_archive: str | None = None,
    expected_tree: str | None = None,
    expected_version: str | None = None,
    expected_scenario_set: str = "tracer",
) -> dict[str, Any]:
    receipt = _exact(raw, ROOT_FIELDS, "root")
    if receipt["schema_version"] != 1:
        raise ValueError("receipt schema version is unsupported")
    try:
        run_id = str(uuid.UUID(receipt["run_id"]))
    except (ValueError, TypeError, AttributeError):
        raise ValueError("receipt run identity is invalid") from None
    if expected_run_id is not None and run_id != str(uuid.UUID(expected_run_id)):
        raise ValueError("receipt run identity differs from the expected run")
    if not isinstance(receipt["source_revision"], str) or not re.fullmatch(r"[0-9a-f]{40,64}", receipt["source_revision"]):
        raise ValueError("receipt source revision is invalid")
    if expected_source is not None and receipt["source_revision"] != expected_source:
        raise ValueError("receipt source revision differs from the expected source")
    if type(receipt["source_dirty"]) is not bool:
        raise ValueError("receipt dirty-source marker is invalid")
    candidate = _exact(receipt["candidate"], CANDIDATE_FIELDS, "candidate")
    if not isinstance(candidate["version"], str) or not candidate["version"]:
        raise ValueError("receipt candidate version is invalid")
    if expected_version is not None and candidate["version"] != expected_version:
        raise ValueError("receipt candidate version differs from the expected candidate")
    for field, expected in (("archive_sha256", expected_archive), ("tree_sha256", expected_tree)):
        if not isinstance(candidate[field], str) or not re.fullmatch(r"[0-9a-f]{64}", candidate[field]):
            raise ValueError(f"receipt candidate {field} is invalid")
        if expected is not None and candidate[field] != expected:
            raise ValueError(f"receipt candidate {field} differs from the expected candidate")
    pair = receipt["pair"]
    if not isinstance(pair, str) or pair not in PAIR_RUNTIME_VERSIONS:
        raise ValueError("receipt runtime pair is invalid")
    if expected_pair is not None and pair != expected_pair:
        raise ValueError("receipt runtime pair differs from the expected pair")
    if not isinstance(receipt["mount"], str) or receipt["mount"] not in MOUNTS or (expected_mount is not None and receipt["mount"] != expected_mount):
        raise ValueError("receipt mount differs from the expected mount")
    if receipt["evidence_kind"] != "real_browser_cdp":
        raise ValueError("receipt evidence kind is invalid")
    runtime = _exact(receipt["runtime"], RUNTIME_FIELDS, "runtime")
    if any(
        not isinstance(value, str) or
        (value != "unknown" and not re.fullmatch(RUNTIME_PATTERNS[key], value))
        for key, value in runtime.items()
    ):
        raise ValueError("receipt runtime versions are incomplete")
    if receipt["result"] == "passed" and any(value == "unknown" for value in runtime.values()):
        raise ValueError("passed receipt runtime versions are incomplete")
    if (runtime["phoenix"], runtime["live_view"]) != PAIR_RUNTIME_VERSIONS[pair]:
        raise ValueError("receipt runtime versions do not match selected pair")
    if not isinstance(receipt["scenarios"], list):
        raise ValueError("receipt scenarios are invalid")
    if expected_scenario_set not in {"tracer", "full"}:
        raise ValueError("receipt scenario set is unsupported")
    scenario_ids = REQUIRED if expected_scenario_set == "tracer" else FULL_REQUIRED
    seen: set[str] = set()
    for scenario_raw in receipt["scenarios"]:
        scenario = _exact(scenario_raw, SCENARIO_FIELDS, "scenario")
        identifier = scenario["id"]
        if not isinstance(identifier, str) or identifier not in scenario_ids or identifier in seen:
            raise ValueError("receipt scenario identity is unknown or duplicated")
        seen.add(identifier)
        if not isinstance(scenario["outcome"], str) or scenario["outcome"] not in {"passed", "failed"}:
            raise ValueError("receipt scenario outcome is invalid")
        if type(scenario["duration_ms"]) is not int or scenario["duration_ms"] < 0:
            raise ValueError("receipt scenario duration is invalid")
        count_fields = frozenset({"assets", "websocket_handshakes", "successful_joins", "navigations"}) if expected_scenario_set == "tracer" else FULL_COUNTS
        counts = _exact(scenario["counts"], count_fields, "counts")
        if any(type(value) is not int or value < 0 for value in counts.values()):
            raise ValueError("receipt scenario counts are invalid")
        observation_fields = frozenset({"login", "overview", "clients", "authorized_http", "connected_hook"}) if expected_scenario_set == "tracer" else FULL_OBSERVATIONS
        observations = _exact(scenario["observations"], observation_fields, "observations")
        if any(type(value) is not bool for value in observations.values()):
            raise ValueError("receipt scenario observations are invalid")
        passed = scenario["outcome"] == "passed"
        if passed and expected_scenario_set == "tracer" and (
            counts["assets"] < 2 or counts["websocket_handshakes"] < 2 or
            counts["successful_joins"] < 2 or counts["navigations"] < 4 or
            not all(observations.values())
        ):
            raise ValueError("receipt scenario does not prove a successful browser join and navigation")
        if passed and expected_scenario_set == "full":
            true_observations = {key for key, value in observations.items() if value}
            if not FULL_CASE_EVIDENCE[identifier].issubset(true_observations):
                raise ValueError("receipt full scenario lacks its required boundary evidence")
            if identifier == "allowed_entry" and (counts["assets"] < 2 or counts["successful_joins"] < 1):
                raise ValueError("receipt allowed entry lacks package assets or a successful join")
            if identifier == "allowed_reconnect" and (counts["websocket_handshakes"] < 2 or counts["successful_joins"] < 2):
                raise ValueError("receipt allowed reconnect lacks a new handshake and successful join")
            if identifier in {"live_navigation", "params_patch", "detail_task"} and counts["navigations"] < 1:
                raise ValueError("receipt native transition lacks a navigation observation")
            required_counts = {
                "anonymous_http_denied": {"http_checks": 1, "staff_checks": 1},
                "nonstaff_http_denied": {"http_checks": 1, "staff_checks": 1},
                "cached_join_denied": {"staff_checks": 1},
                "reconnect_denied": {"staff_checks": 1},
                "params_denied": {"params_checks": 1, "staff_checks": 1},
                "public_session_denied": {"staff_checks": 1},
                "consent_session_denied": {"staff_checks": 1},
            }.get(identifier, {})
            if any(counts[key] < minimum for key, minimum in required_counts.items()):
                raise ValueError("receipt full scenario lacks its required current-authority counter")
            if identifier in {"public_discovery", "public_jwks", "public_protocol_error"} and counts["staff_checks"] != 0:
                raise ValueError("receipt public protocol scenario includes a staff authorization check")
    if seen != scenario_ids:
        raise ValueError("receipt scenario set is incomplete")
    cleanup = _exact(receipt["cleanup"], CLEANUP_FIELDS, "cleanup")
    if any(type(value) is not bool for value in cleanup.values()):
        raise ValueError("receipt cleanup results are invalid")
    expected_result = "passed" if seen == scenario_ids and all(cleanup.values()) and all(item["outcome"] == "passed" for item in receipt["scenarios"]) else "failed"
    if receipt["result"] != expected_result:
        raise ValueError("receipt result contradicts its scenarios or cleanup")
    return receipt


def write_receipt(path: Path, receipt: dict[str, Any], **expected: object) -> None:
    validate_receipt(receipt, **expected)
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(receipt, handle, sort_keys=True, separators=(",", ":"))
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except OSError:
            pass
        raise


def main(argv: Sequence[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", type=Path, required=True)
    parser.add_argument("--expected-run-id", required=True)
    parser.add_argument("--expected-source", required=True)
    parser.add_argument("--expected-pair", choices=("locked", "floor"), required=True)
    parser.add_argument("--expected-mount", choices=tuple(sorted(MOUNTS)), required=True)
    parser.add_argument("--expected-archive", required=True)
    parser.add_argument("--expected-tree", required=True)
    parser.add_argument("--expected-version", required=True)
    parser.add_argument("--expected-scenario-set", choices=("tracer", "full"), required=True)
    args = parser.parse_args(argv)
    try:
        validate_receipt(json.loads(args.check.read_text(encoding="utf-8")), expected_run_id=args.expected_run_id, expected_source=args.expected_source, expected_pair=args.expected_pair, expected_mount=args.expected_mount, expected_archive=args.expected_archive, expected_tree=args.expected_tree, expected_version=args.expected_version, expected_scenario_set=args.expected_scenario_set)
    except (OSError, ValueError, json.JSONDecodeError):
        print("receipt validation failed")
        return 1
    print("receipt validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(__import__("sys").argv[1:]))
