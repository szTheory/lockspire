"""Explicit synthetic observation context for component tests, never real proof.

The complete chain separately captures authority from an actual archive and
external OS/DB observation boundaries. These immutable template facts let
component tests exercise raw/index relationships without claiming that old
receipts acquired new runtime authority.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
CONTEXT_PINS = {}


def context_for_template(template: dict) -> dict:
    from verifier_receipt_owner import selected_runtime
    candidate = template["candidate"]
    source = subprocess.run(("git", "show", candidate["source_revision"] + ":mix.exs"), cwd=ROOT,
                            capture_output=True, timeout=15, check=True).stdout.decode()
    match = re.search(r'^\s*version:\s*"([^"]+)"', source, re.MULTILINE)
    if match is None:
        raise AssertionError("template source package version unavailable")
    elixir, otp, digest = selected_runtime(ROOT, "local-current")
    return {"schema": "lockspire-verifier-receipt-owner-v1", "profile": "local-current",
        "runner_revision": template.get("runner", template.get("runner_revision")),
        "candidate_source_archive_tree": [candidate["source_revision"], candidate["archive_sha256"], candidate["tree_sha256"]],
        "candidate_owner_sha256": candidate["source_proof"], "package_version": match.group(1),
        "selection_source_sha256": digest, "runtime": {"elixir": elixir, "otp": otp, "postgresql": "14.17"},
        "server_version_num": "140017", "observations": {
            "beam_sha256": hashlib.sha256((elixir + "\n" + otp + "\n").encode()).hexdigest(),
            "server_sha256": hashlib.sha256(b"140017\n").hexdigest()}}


def write_context(root: Path, document: dict) -> dict[str, str]:
    path = root / "receipt-owner.json"
    raw = json.dumps(document, sort_keys=True).encode() + b"\n"
    path.write_bytes(raw)
    path.chmod(0o600)
    result = {"LOCKSPIRE_RECEIPT_OWNER": str(path), "LOCKSPIRE_EXPECTED_RECEIPT_OWNER_SHA256": hashlib.sha256(raw).hexdigest()}
    CONTEXT_PINS[str(root)] = result
    return result
