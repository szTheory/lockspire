#!/usr/bin/env python3
"""Emit a strictly allowlisted OIDF failure summary without retaining raw output."""

import argparse
import json
import re
from pathlib import Path

ANSI = re.compile(r"\x1b\[[0-9;]*m")
MODULE_PREFIX = re.compile(r"Test \[\d+:\d+\] (?P<name>\S{1,180})")
MODULE_RESULT = re.compile(r"(?P<status>[A-Z_]{2,30}) - result (?P<result>[A-Z_]{2,30})\.")
CONDITION = re.compile(r"Block name: '(?P<block>[^']{1,240})' - Condition: '(?P<condition>[^']{1,240})'")
TOTALS = re.compile(
    r"Overall totals: ran (?P<modules>\d{1,4}) test modules\. Conditions: "
    r"(?P<successes>\d{1,6}) successes, (?P<failures>\d{1,6}) failures, "
    r"(?P<warnings>\d{1,6}) warnings\."
)
EXCEPTION = re.compile(r"(?:^|\s)(?P<name>[A-Za-z_][A-Za-z0-9_.]*(?:Error|Exception))(?::|\s)")
SAFE_NAME = re.compile(r"[A-Za-z0-9_.\[\]=,/-]{1,180}")
SAFE_LABEL = re.compile(r"[A-Za-z0-9 ._:/()$-]{1,240}")


def summarize(path: Path) -> dict[str, object]:
    source = ANSI.sub("", path.read_text(encoding="utf-8", errors="replace"))
    modules = []
    conditions = []

    for line in source.splitlines():
        prefix = MODULE_PREFIX.search(line)
        result = MODULE_RESULT.search(line)
        if prefix and result and SAFE_NAME.fullmatch(prefix.group("name")):
            modules.append({"name": prefix.group("name"), **result.groupdict()})

        condition = CONDITION.search(line)
        if condition and all(SAFE_LABEL.fullmatch(value) for value in condition.groupdict().values()):
            conditions.append(condition.groupdict())

    totals = [
        {key: int(value) for key, value in match.groupdict().items()}
        for match in TOTALS.finditer(source)
    ][:20]
    exceptions = sorted({match.group("name") for match in EXCEPTION.finditer(source)})[:30]
    http_statuses = sorted({int(value) for value in re.findall(r"HTTP(?: Error)? (\d{3})", source)})
    return {
        "conditions": conditions[:200],
        "exceptions": exceptions,
        "http_statuses": http_statuses,
        "modules": modules[:200],
        "totals": totals,
    }


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
