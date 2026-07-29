#!/usr/bin/env python3
"""Converts adopter_path_walk.sh's NUL-delimited record stream into a machine-readable
JSON report.

scripts/maintainer/adopter_path_walk.sh's `record_result` appends
`level\\0label\\0detail\\0` to a NUL-delimited stream for every step it records -- NUL is
the one byte that cannot appear in the payload, so it is injection-proof even though detail
strings carry quotes, section signs, percent signs, and interpolated `mix compile` output
that can contain newlines and backslashes. This script is the only place that stream is ever
turned into JSON; no JSON is ever constructed in bash.

Every field beyond (level, step_id, detail) is derived here from the detail text alone, with
no call-site changes required in the shell harness:
  - occurrence  -- 1-based index of this row within its own step_id (step_id is not a unique
                   row key: step-00a-preflight emits multiple rows per run, and so does
                   step-06a-client)
  - guide_section -- the first `§(\\d+)` found in detail, else null
  - defect_ids  -- every `ADOPT-D\\d+` found in detail
  - resumed     -- true when detail is exactly "skipped (already done)"

Restricted to the stdlib set test/lockspire/maintainer/adopter_flow_driver_contract_test.exs
already allowlists for the flow driver (argparse, base64, hashlib, http, json, os, re, sys,
time, urllib), so this runs on a bare runner with no pip dependencies.
"""
import argparse
import json
import os
import re
import sys
import time

SCHEMA = "lockspire.adopter_walk.report/1"
GUIDE_SECTION_RE = re.compile(r"§(\d+)")
DEFECT_ID_RE = re.compile(r"ADOPT-D\d+")
RESUMED_DETAIL = "skipped (already done)"


def parse_records(records_path):
    """Reads the NUL-delimited record stream back into (level, step_id, detail) triples."""
    if not os.path.isfile(records_path):
        return []

    with open(records_path, "rb") as handle:
        raw = handle.read()

    parts = raw.split(b"\x00")

    # A well-formed stream is a sequence of NUL-terminated fields grouped in threes
    # (level, label, detail); the trailing split element after the final NUL is always empty.
    if parts and parts[-1] == b"":
        parts = parts[:-1]

    fields = [part.decode("utf-8", errors="replace") for part in parts]

    complete_len = len(fields) - (len(fields) % 3)

    records = []
    for index in range(0, complete_len, 3):
        level, step_id, detail = fields[index : index + 3]
        records.append((level, step_id, detail))

    return records


def build_rows(records):
    """Derives occurrence, guide_section, defect_ids, and resumed from each record's detail."""
    occurrence_counts = {}
    rows = []

    for level, step_id, detail in records:
        occurrence_counts[step_id] = occurrence_counts.get(step_id, 0) + 1
        occurrence = occurrence_counts[step_id]

        guide_section_match = GUIDE_SECTION_RE.search(detail)
        guide_section = guide_section_match.group(1) if guide_section_match else None

        rows.append(
            {
                "step_id": step_id,
                "occurrence": occurrence,
                "level": level,
                "detail": detail,
                "guide_section": guide_section,
                "defect_ids": DEFECT_ID_RE.findall(detail),
                "resumed": detail == RESUMED_DETAIL,
            }
        )

    return rows


def str_to_bool(value):
    return str(value).strip().lower() in ("1", "true", "yes")


def coerce_port(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return value


def coerce_optional(value):
    return value if value else None


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--records", required=True, help="Path to the NUL-delimited record stream."
    )
    parser.add_argument("--output", required=True, help="Path to write the JSON report to.")
    parser.add_argument("--workdir", required=True)
    parser.add_argument("--from-step", required=True)
    parser.add_argument("--force", required=True)
    parser.add_argument("--keep", required=True)
    parser.add_argument("--port", required=True)
    parser.add_argument("--preflight-only", required=True)
    parser.add_argument("--elixir", default="")
    parser.add_argument("--otp", default="")
    parser.add_argument("--postgresql", default="")
    parser.add_argument("--phx-new", default="")
    return parser.parse_args(argv)


def build_report(args):
    records = parse_records(args.records)
    rows = build_rows(records)

    pass_count = sum(1 for row in rows if row["level"] == "PASS")
    fail_count = sum(1 for row in rows if row["level"] == "FAIL")
    verdict = "RED" if fail_count > 0 else "GREEN"

    return {
        "schema": SCHEMA,
        "walk_date": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "invocation": {
            "workdir": args.workdir,
            "from_step": args.from_step,
            "force": str_to_bool(args.force),
            "keep": str_to_bool(args.keep),
            "port": coerce_port(args.port),
            "preflight_only": str_to_bool(args.preflight_only),
        },
        "resolved_versions": {
            "elixir": coerce_optional(args.elixir),
            "otp": coerce_optional(args.otp),
            "postgresql": coerce_optional(args.postgresql),
            "phx_new": coerce_optional(args.phx_new),
        },
        "pass_count": pass_count,
        "fail_count": fail_count,
        "verdict": verdict,
        "summary_line": "Summary: {0} PASS, {1} FAIL".format(pass_count, fail_count),
        "result_line": "Result: adopter path is {0}".format(verdict),
        "rows": rows,
    }


def main(argv=None):
    args = parse_args(argv)
    report = build_report(args)

    output_dir = os.path.dirname(args.output)
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)

    with open(args.output, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, sort_keys=True)
        handle.write("\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
