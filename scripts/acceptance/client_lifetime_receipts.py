#!/usr/bin/env python3
"""Validate and reduce packaged lifetime leg outputs to safe CI receipts."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent / "clean_room"))

from lifetime_receipts import combine_lifetime_receipts  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fresh", type=Path, required=True)
    parser.add_argument("--custom", type=Path, required=True)
    parser.add_argument("--legacy", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--validation", type=Path, required=True)
    parser.add_argument("--expected-source", required=True)
    args = parser.parse_args()
    try:
        summary = combine_lifetime_receipts(
            args.fresh, args.custom, args.legacy, args.receipt, args.validation,
            expected_source_revision=args.expected_source,
        )
    except (AssertionError, OSError, ValueError) as error:
        print(f"lifetime CI receipt validation failed: {type(error).__name__}", file=sys.stderr)
        return 1
    print(
        "lifetime CI receipt verified "
        f"scenarios={summary['passed']}/{len(summary['expected_scenarios'])} "
        f"source={summary['source_revision']} candidate={summary['candidate_digest']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
