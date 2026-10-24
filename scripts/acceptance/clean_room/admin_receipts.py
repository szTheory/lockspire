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
SCENARIO_FIELDS = frozenset({"id", "outcome", "counts", "duration_ms", "observations"})
CLEANUP_FIELDS = frozenset({"processes_stopped", "database_removed", "profile_removed", "run_root_removed"})
REQUIRED = frozenset({"tracer.browser_join_navigation"})
MOUNTS = frozenset({"/lockspire", "/teams/ops/identity", "/"})


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
    for field, expected in (("archive_sha256", expected_archive), ("tree_sha256", expected_tree)):
        if not isinstance(candidate[field], str) or not re.fullmatch(r"[0-9a-f]{64}", candidate[field]):
            raise ValueError(f"receipt candidate {field} is invalid")
        if expected is not None and candidate[field] != expected:
            raise ValueError(f"receipt candidate {field} differs from the expected candidate")
    if receipt["pair"] != "locked" or expected_pair not in (None, "locked"):
        raise ValueError("receipt runtime pair is invalid")
    if receipt["mount"] not in MOUNTS or (expected_mount is not None and receipt["mount"] != expected_mount):
        raise ValueError("receipt mount differs from the expected mount")
    if receipt["evidence_kind"] != "real_browser_cdp":
        raise ValueError("receipt evidence kind is invalid")
    runtime = _exact(receipt["runtime"], RUNTIME_FIELDS, "runtime")
    if any(not isinstance(value, str) or not value for value in runtime.values()):
        raise ValueError("receipt runtime versions are incomplete")
    if not isinstance(receipt["scenarios"], list):
        raise ValueError("receipt scenarios are invalid")
    seen: set[str] = set()
    for scenario_raw in receipt["scenarios"]:
        scenario = _exact(scenario_raw, SCENARIO_FIELDS, "scenario")
        identifier = scenario["id"]
        if identifier not in REQUIRED or identifier in seen:
            raise ValueError("receipt scenario identity is unknown or duplicated")
        seen.add(identifier)
        if scenario["outcome"] not in {"passed", "failed"}:
            raise ValueError("receipt scenario outcome is invalid")
        if type(scenario["duration_ms"]) is not int or scenario["duration_ms"] < 0:
            raise ValueError("receipt scenario duration is invalid")
        counts = _exact(scenario["counts"], frozenset({"assets", "websocket_handshakes", "successful_joins", "navigations"}), "counts")
        if any(type(value) is not int or value < 0 for value in counts.values()):
            raise ValueError("receipt scenario counts are invalid")
        observations = _exact(scenario["observations"], frozenset({"login", "overview", "clients", "authorized_http", "connected_hook"}), "observations")
        if any(type(value) is not bool for value in observations.values()):
            raise ValueError("receipt scenario observations are invalid")
        passed = scenario["outcome"] == "passed"
        if passed and (
            counts["assets"] < 2 or counts["websocket_handshakes"] < 1 or
            counts["successful_joins"] < 1 or counts["navigations"] < 1 or
            not all(observations.values())
        ):
            raise ValueError("receipt scenario does not prove a successful browser join and navigation")
    if expected_scenario_set == "tracer" and seen != REQUIRED:
        raise ValueError("receipt scenario set is incomplete")
    cleanup = _exact(receipt["cleanup"], CLEANUP_FIELDS, "cleanup")
    if any(type(value) is not bool for value in cleanup.values()):
        raise ValueError("receipt cleanup results are invalid")
    expected_result = "passed" if seen == REQUIRED and all(cleanup.values()) and all(item["outcome"] == "passed" for item in receipt["scenarios"]) else "failed"
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
    parser.add_argument("--expected-pair", choices=("locked",), required=True)
    parser.add_argument("--expected-mount", choices=tuple(sorted(MOUNTS)), required=True)
    parser.add_argument("--expected-archive", required=True)
    parser.add_argument("--expected-tree", required=True)
    parser.add_argument("--expected-scenario-set", choices=("tracer",), required=True)
    args = parser.parse_args(argv)
    try:
        validate_receipt(json.loads(args.check.read_text(encoding="utf-8")), expected_run_id=args.expected_run_id, expected_source=args.expected_source, expected_pair=args.expected_pair, expected_mount=args.expected_mount, expected_archive=args.expected_archive, expected_tree=args.expected_tree, expected_scenario_set=args.expected_scenario_set)
    except (OSError, ValueError, json.JSONDecodeError):
        print("receipt validation failed")
        return 1
    print("receipt validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(__import__("sys").argv[1:]))
