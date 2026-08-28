#!/usr/bin/env python3
"""Emit a strictly allowlisted OIDF failure summary without retaining raw output."""

import argparse
import json
import re
from pathlib import Path

ANSI = re.compile(r"\x1b\[[0-9;]*m")
MODULE_RESULT = re.compile(
    r"Test \[\d+:\d+\] "
    r"(?P<name>[A-Za-z0-9_.\[\]=,-]{1,180}) "
    r"[0-9a-f-]{8,80} (?P<status>[A-Z_]{2,30}) - result "
    r"(?P<result>[A-Z_]{2,30})\."
)
CONDITION = re.compile(
    r"Block name: '(?P<block>[A-Za-z0-9 ._/-]{1,120})' - "
    r"Condition: '(?P<condition>[A-Za-z0-9_.$]{1,180})'"
)
TOTALS = re.compile(
    r"Overall totals: ran (?P<modules>\d{1,4}) test modules\. Conditions: "
    r"(?P<successes>\d{1,6}) successes, (?P<failures>\d{1,6}) failures, "
    r"(?P<warnings>\d{1,6}) warnings\."
)


def summarize(path: Path) -> dict[str, object]:
    source = ANSI.sub("", path.read_text(encoding="utf-8", errors="replace"))
    modules = [match.groupdict() for match in MODULE_RESULT.finditer(source)][:200]
    conditions = [match.groupdict() for match in CONDITION.finditer(source)][:200]
    totals = [
        {key: int(value) for key, value in match.groupdict().items()}
        for match in TOTALS.finditer(source)
    ][:20]
    return {"conditions": conditions, "modules": modules, "totals": totals}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("log")
    args = parser.parse_args()

    path = Path(args.log)
    if not path.is_file():
        return 1

    print("OIDF_SAFE_DIAGNOSTICS " + json.dumps(summarize(path), sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
