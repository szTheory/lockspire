#!/usr/bin/env python3
"""Build the allowlisted receipt retained from a conformance run."""

import argparse
import hashlib
import json
import platform
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

FORBIDDEN = re.compile(r"(?i)(authorization|cookie|token|secret|password|provider-config|raw log|https?://)")
ALLOWED_STATUSES = {"passed", "failed", "integration_only"}
ALLOWED_CLASSIFICATIONS = {"success", "suite_failure", "infrastructure_failure", "integration_only"}


def fail(message):
    raise ValueError(message)


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def allowlisted(lock, profile, plan, status, classification, started, finished):
    if status not in ALLOWED_STATUSES or classification not in ALLOWED_CLASSIFICATIONS:
        fail("invalid result classification")
    if not re.fullmatch(r"[a-z0-9_]{1,40}", profile):
        fail("invalid profile")

    plan_data = json.loads(Path(plan).read_text(encoding="utf-8"))
    result_names = [str(item.get("name", ""))[:80] for item in plan_data.get("plans", [])]
    if any(not re.fullmatch(r"[A-Za-z0-9 ._/,=-]{1,80}", name) for name in result_names):
        fail("unsafe result name")

    receipt = {
        "schema_version": 1,
        "allowlisted": True,
        "profile": profile,
        "suite": {"tag": lock["suite"]["tag"], "commit": lock["suite"]["commit"]},
        "input_hashes": {
            "archive": lock["suite"]["archive"]["sha256"],
            "helpers": {name: item["sha256"] for name, item in lock["helpers"].items()},
            "images": {name: item["digest"] for name, item in lock["images"].items()},
        },
        "plan": {"name": Path(plan).name, "sha256": digest(plan)},
        "runtime": {"python": platform.python_version()},
        "result": {"status": status, "classification": classification, "result_names": result_names},
        "timestamps": {"started_at": started, "finished_at": finished},
    }
    rendered = json.dumps(receipt, sort_keys=True)
    if FORBIDDEN.search(rendered):
        fail("unsafe receipt content")
    return receipt


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--lock", required=True)
    parser.add_argument("--profile", required=True)
    parser.add_argument("--plan", required=True)
    parser.add_argument("--status", required=True)
    parser.add_argument("--classification", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    try:
        lock = json.loads(Path(args.lock).read_text(encoding="utf-8"))
        now = datetime.now(timezone.utc).isoformat()
        receipt = allowlisted(lock, args.profile, args.plan, args.status, args.classification, now, now)
        output = Path(args.output)
        output.mkdir(parents=True, exist_ok=True)
        if any(output.iterdir()):
            fail("retained evidence directory must be empty")
        (output / "receipt.json").write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    except (OSError, json.JSONDecodeError, ValueError) as error:
        print(f"conformance evidence failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
