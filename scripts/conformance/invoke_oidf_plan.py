#!/usr/bin/env python3
"""Translate a Lockspire profile into the pinned OIDF runner CLI."""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

IDENTIFIER = re.compile(r"[A-Za-z0-9_-]{1,100}")
VALUE = re.compile(r"[A-Za-z0-9_./=-]{1,200}")


def fail(message):
    raise ValueError(message)


def load_json(path, label):
    source = Path(path).resolve()
    if not source.is_file():
        fail(f"{label} must be a regular file")
    try:
        return source, json.loads(source.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        fail(f"{label} is not valid JSON: {error.msg}")


def render_plan(item):
    if not isinstance(item, dict):
        fail("each profile plan must be an object")
    suite_plan = item.get("suite_plan")
    if not isinstance(suite_plan, str) or not IDENTIFIER.fullmatch(suite_plan):
        fail("invalid suite plan name")

    variants = item.get("variants", {})
    if not isinstance(variants, dict):
        fail("plan variants must be an object")
    rendered = suite_plan
    for name, value in sorted(variants.items()):
        if not isinstance(name, str) or not IDENTIFIER.fullmatch(name):
            fail("invalid suite variant name")
        if not isinstance(value, str) or not VALUE.fullmatch(value):
            fail("invalid suite variant value")
        rendered += f"[{name}={value}]"

    modules = item.get("modules", [])
    if not isinstance(modules, list) or any(
        not isinstance(module, str) or not IDENTIFIER.fullmatch(module) for module in modules
    ):
        fail("invalid suite module list")
    if modules:
        rendered += ":" + ",".join(modules)
    return rendered


def command(runner, plan_path, config_path, export_dir):
    runner_path = Path(runner).resolve()
    if not runner_path.is_file():
        fail("pinned OIDF runner must be a regular file")
    plan_source, plan = load_json(plan_path, "profile plan")
    config_source, config = load_json(config_path, "provider configuration")
    if not isinstance(config, dict):
        fail("provider configuration must be a JSON object")

    entries = plan.get("plans") if isinstance(plan, dict) else None
    if not isinstance(entries, list) or not entries:
        fail("profile plan must contain at least one plan")

    destination = Path(export_dir).resolve()
    destination.mkdir(mode=0o700, parents=True, exist_ok=False)
    args = [sys.executable, str(runner_path), "--verbose", "--export-dir", str(destination)]
    for entry in entries:
        args.extend([render_plan(entry), str(config_source)])
    return args, runner_path.parent.parent, plan_source


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--runner", required=True)
    parser.add_argument("--plan", required=True)
    parser.add_argument("--provider-config", required=True)
    parser.add_argument("--export-dir", required=True)
    args = parser.parse_args()

    try:
        invocation, cwd, _plan = command(
            args.runner, args.plan, args.provider_config, args.export_dir
        )
        preflight = invocation[:2] + ["--list"] + invocation[2:]
        if subprocess.run(preflight, cwd=cwd, check=False).returncode != 0:
            print("OIDF runner preflight failed", file=sys.stderr)
            return 70
        return subprocess.run(invocation, cwd=cwd, check=False).returncode
    except (OSError, ValueError) as error:
        print(f"OIDF plan invocation failed: {error}", file=sys.stderr)
        return 70


if __name__ == "__main__":
    sys.exit(main())
