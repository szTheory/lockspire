#!/usr/bin/env python3
"""Verifies a completed `mix adopter.walk` report against the committed baseline.

The gate is "actual matches the recorded expectation", never "the walk exited 0" --
`.planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md` forbids any gate
asserting the walk exits 0, reaches its final step, or leaves an empty ledger. A RED walk that
matches its baseline exits 0 here; this is that ledger's inversion warning discharged
mechanically, not overridden.

Exit codes:
  0  Every (step_id, occurrence) row's level in the report agrees with the baseline. The
     walk's own exit code is irrelevant.
  1  Usage error, or a precondition violation: the report was produced by a
     `--preflight-only` run, a `--from-step` other than `00`, or contains any row with
     `resumed: true`. The baseline describes a full from-scratch walk; comparing it against a
     partial or resumed run would silently misattribute occurrences.
  2  Infrastructure: the report or baseline file is missing, truncated, unparsable, or
     carries the wrong schema. This is also what a `fail_prerequisite` walk exit (2) looks
     like from here -- that path exits before any `record_result` call, so it never produces
     a report at all, and a missing report is exactly this case.
  3  A real mismatch: at least one REGRESSION, UNRECORDED_FIX, NEW_ROW, or MISSING_ROW.
     UNRECORDED_FIX is a hard failure here, deliberately -- a defect fixing itself without a
     ledger disposition is the exact failure mode phases 127-129 exist to prevent.

Never provides --bless or --update-baseline. --print-baseline-patch prints proposed rows to
stdout for a human to paste into the baseline and annotate with a why -- the copy-paste
friction is the point; the first noisy failure never gets auto-blessed into a decorative gate.

Restricted to the stdlib set test/lockspire/maintainer/adopter_flow_driver_contract_test.exs
already allowlists for the flow driver (argparse, base64, hashlib, http, json, os, re, sys,
time, urllib), so this runs on a bare runner with no pip dependencies.
"""
import argparse
import json
import os
import sys

REPORT_SCHEMA = "lockspire.adopter_walk.report/1"
BASELINE_SCHEMA = "lockspire.adopter_walk.baseline/1"
LEDGER_PATH = ".planning/phases/126-adopter-path-walk-defect-ledger/126-DEFECT-LEDGER.md"

EXIT_MATCH = 0
EXIT_USAGE_OR_PRECONDITION = 1
EXIT_INFRA = 2
EXIT_MISMATCH = 3


class InfraError(Exception):
    """The report or baseline could not be loaded or trusted -- not an adopter-path defect."""


class PreconditionError(Exception):
    """The report cannot be adjudicated against a from-scratch baseline as-is."""


def load_json(path, label):
    if not os.path.isfile(path):
        raise InfraError("{0} not found at {1}".format(label, path))

    try:
        with open(path, "r", encoding="utf-8") as handle:
            return json.load(handle)
    except (ValueError, UnicodeDecodeError) as exc:
        raise InfraError(
            "{0} at {1} is truncated or malformed: {2}".format(label, path, exc)
        )


def load_report(path):
    report = load_json(path, "report")

    if report.get("schema") != REPORT_SCHEMA:
        raise InfraError(
            "report at {0} carries schema {1!r}, expected {2!r}".format(
                path, report.get("schema"), REPORT_SCHEMA
            )
        )

    return report


def load_baseline(path):
    baseline = load_json(path, "baseline")

    if baseline.get("schema") != BASELINE_SCHEMA:
        raise InfraError(
            "baseline at {0} carries schema {1!r}, expected {2!r}".format(
                path, baseline.get("schema"), BASELINE_SCHEMA
            )
        )

    return baseline


def check_preconditions(report):
    invocation = report.get("invocation", {})

    if invocation.get("preflight_only"):
        raise PreconditionError(
            "report was produced by a --preflight-only run; the baseline describes a full "
            "from-scratch walk and cannot adjudicate a preflight-only report"
        )

    from_step = invocation.get("from_step")
    if from_step not in (None, "00"):
        raise PreconditionError(
            "report was produced by --from-step {0!r}; the baseline describes a full "
            "from-scratch walk (--from-step 00) and cannot adjudicate a resumed run".format(
                from_step
            )
        )

    resumed_rows = [row for row in report.get("rows", []) if row.get("resumed")]
    if resumed_rows:
        labels = ", ".join(
            "{0}#{1}".format(row.get("step_id"), row.get("occurrence")) for row in resumed_rows
        )
        raise PreconditionError(
            "report contains {0} resumed row(s) ({1}); comparing a resumed run against a "
            "from-scratch baseline silently misattributes occurrences".format(
                len(resumed_rows), labels
            )
        )


def index_by_key(rows):
    return {(row["step_id"], row["occurrence"]): row for row in rows}


def compare(report_rows, baseline_rows):
    """Returns a list of finding dicts, one per (step_id, occurrence) mismatch."""
    actual = index_by_key(report_rows)
    expected = index_by_key(baseline_rows)

    findings = []

    for key, expected_row in expected.items():
        if key not in actual:
            findings.append(
                {
                    "class": "MISSING_ROW",
                    "step_id": key[0],
                    "occurrence": key[1],
                    "expected_level": expected_row["level"],
                    "actual_level": None,
                    "defect": expected_row.get("defect"),
                    "why": expected_row.get("why"),
                }
            )

    for key, actual_row in actual.items():
        expected_row = expected.get(key)

        if expected_row is None:
            findings.append(
                {
                    "class": "NEW_ROW",
                    "step_id": key[0],
                    "occurrence": key[1],
                    "expected_level": None,
                    "actual_level": actual_row["level"],
                    "detail": actual_row.get("detail"),
                }
            )
            continue

        expected_level = expected_row["level"]
        actual_level = actual_row["level"]

        if expected_level == actual_level:
            continue

        if expected_level == "PASS" and actual_level == "FAIL":
            findings.append(
                {
                    "class": "REGRESSION",
                    "step_id": key[0],
                    "occurrence": key[1],
                    "expected_level": expected_level,
                    "actual_level": actual_level,
                    "defect": expected_row.get("defect"),
                    "detail": actual_row.get("detail"),
                }
            )
        elif expected_level == "FAIL" and actual_level == "PASS":
            findings.append(
                {
                    "class": "UNRECORDED_FIX",
                    "step_id": key[0],
                    "occurrence": key[1],
                    "expected_level": expected_level,
                    "actual_level": actual_level,
                    "defect": expected_row.get("defect"),
                    "why": expected_row.get("why"),
                }
            )

    findings.sort(key=lambda finding: (finding["step_id"], finding["occurrence"]))
    return findings


def format_finding(finding):
    step = finding["step_id"]
    occurrence = finding["occurrence"]
    kind = finding["class"]

    if kind == "REGRESSION":
        defect = finding.get("defect") or "no recorded defect ID"
        detail = finding.get("detail") or ""
        return (
            "REGRESSION  {0}#{1}: expected PASS, observed FAIL ({2}). {3}\n"
            "  See {4}."
        ).format(step, occurrence, defect, detail, LEDGER_PATH)

    if kind == "UNRECORDED_FIX":
        defect = finding.get("defect") or "no recorded defect ID"
        why = finding.get("why") or ""
        return (
            "UNRECORDED_FIX  {0}#{1}: expected FAIL ({2}), observed PASS. Nice work -- a "
            "defect fixed itself, but without a ledger disposition it can't be trusted yet. "
            "Please record the fix in {3} before this can go green. {4}"
        ).format(step, occurrence, defect, LEDGER_PATH, why)

    if kind == "NEW_ROW":
        return (
            "NEW_ROW  {0}#{1}: observed {2}, no baseline row exists for this occurrence."
        ).format(step, occurrence, finding["actual_level"])

    if kind == "MISSING_ROW":
        return (
            "MISSING_ROW  {0}#{1}: baseline expects {2}, no such row was observed in this "
            "run's report."
        ).format(step, occurrence, finding["expected_level"])

    return "{0}  {1}#{2}".format(kind, step, occurrence)


def build_baseline_patch_row(finding):
    level = finding.get("actual_level") or finding.get("expected_level")

    return {
        "step_id": finding["step_id"],
        "occurrence": finding["occurrence"],
        "level": level,
        "defect": finding.get("defect"),
        "why": None if level == "PASS" else "TODO: explain why this row is expected to FAIL",
    }


def print_baseline_patch(findings):
    proposable = [f for f in findings if f["class"] in ("NEW_ROW", "REGRESSION", "UNRECORDED_FIX")]

    if not proposable:
        print("# no proposed rows -- report matches the baseline for every proposable class")
        return

    print(
        "# Proposed rows for scripts/maintainer/adopter_walk_baseline.json -- paste by hand "
        "and write a real \"why\" for every FAIL row. There is no --bless flag; this is the "
        "friction on purpose."
    )

    for finding in proposable:
        print(json.dumps(build_baseline_patch_row(finding), indent=2))


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--report", required=True, help="Path to the walk's report.json")
    parser.add_argument(
        "--baseline", required=True, help="Path to scripts/maintainer/adopter_walk_baseline.json"
    )
    parser.add_argument(
        "--print-baseline-patch",
        action="store_true",
        help="Print proposed baseline rows for any mismatch, for a human to paste and annotate.",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)

    try:
        report = load_report(args.report)
        baseline = load_baseline(args.baseline)
    except InfraError as exc:
        print("INFRA: {0}".format(exc), file=sys.stderr)
        return EXIT_INFRA

    try:
        check_preconditions(report)
    except PreconditionError as exc:
        print("PRECONDITION: {0}".format(exc), file=sys.stderr)
        return EXIT_USAGE_OR_PRECONDITION

    findings = compare(report.get("rows", []), baseline.get("rows", []))

    expected_pass = baseline.get("expected_pass_count")
    expected_fail = baseline.get("expected_fail_count")
    actual_pass = report.get("pass_count")
    actual_fail = report.get("fail_count")

    if (expected_pass, expected_fail) != (actual_pass, actual_fail):
        # Count drift is reported but is never the sole cause of failure -- the per-row
        # comparison above is the real gate; this is diagnostic context only.
        print(
            "NOTE: count drift -- baseline expects {0} PASS / {1} FAIL, report has {2} PASS "
            "/ {3} FAIL.".format(expected_pass, expected_fail, actual_pass, actual_fail),
            file=sys.stderr,
        )

    if not findings:
        print("MATCH: every (step_id, occurrence) row's level agrees with the baseline.")

        if args.print_baseline_patch:
            print_baseline_patch(findings)

        return EXIT_MATCH

    for finding in findings:
        print(format_finding(finding), file=sys.stderr)

    if args.print_baseline_patch:
        print_baseline_patch(findings)

    return EXIT_MISMATCH


if __name__ == "__main__":
    sys.exit(main())
