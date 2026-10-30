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
from contextlib import contextmanager
from functools import lru_cache
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
CONTEXT_PINS = {}
TEMPLATE_SOURCE_REVISION = "2da528fba3ca894cda4e5776b47eb6ccaf12f93c"
PUBLISHED_TEMPLATE_DESCENDANT = "4d512ae2c6a042e2b4557750eca2d49e57fb7189"
EPOCH_LOCK_PATHS = {
    "locked": "test/clean_room/provider_host/mix.lock",
    "floor": "compatibility/phoenix_1_8_live_view_1_1/mix.lock",
}


@lru_cache(maxsize=1)
def _epoch_lock_bytes():
    from package_input import bounded_run
    # These synthetic templates belong to their immutable published epoch,
    # independently of today's checkout. A squash removes HEAD ancestry but
    # does not change the pinned objects or their lock-byte identities.
    relation = bounded_run(("git", "merge-base", "--is-ancestor", TEMPLATE_SOURCE_REVISION,
                            PUBLISHED_TEMPLATE_DESCENDANT),
                           cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, timeout=15)
    if relation.returncode:
        raise AssertionError("pinned fixture epoch requires published branch history")
    rows = {}
    for pair, relative in EPOCH_LOCK_PATHS.items():
        result = bounded_run(("git", "show", f"{TEMPLATE_SOURCE_REVISION}:{relative}"), cwd=ROOT,
                             stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
        if result.returncode or not result.stdout:
            raise AssertionError("pinned fixture lock history is unavailable")
        rows[pair] = result.stdout
    return rows


def check_template_epoch(template):
    if (template.get("runner", template.get("runner_revision")) != TEMPLATE_SOURCE_REVISION
            or template["candidate"].get("source_revision") != TEMPLATE_SOURCE_REVISION):
        raise AssertionError("retained template does not belong to the pinned fixture epoch")
    expected = _epoch_lock_bytes().get(template.get("pair"))
    if expected is None or template["host"].get("lock_sha256") != hashlib.sha256(expected).hexdigest():
        raise AssertionError("retained template lock differs from its pinned source epoch")


def materialize_epoch_locks(root: Path, *, repository_layout=False):
    """Private inputs from immutable Git objects; never rewrite retained evidence."""
    if root.resolve() == ROOT.resolve() or root.is_symlink():
        raise AssertionError("fixture lock context requires a private root")
    paths = {}
    for pair, content in _epoch_lock_bytes().items():
        path = root / (EPOCH_LOCK_PATHS[pair] if repository_layout else f".fixture-lock-epoch/{pair}.lock")
        path.parent.mkdir(parents=True, exist_ok=True)
        if path.is_symlink():
            raise AssertionError("private fixture lock input is unsafe")
        if repository_layout:
            # The full chain owns these newly copied fixture source files.
            path.write_bytes(content)
        elif path.exists():
            if not path.is_file() or path.read_bytes() != content:
                raise AssertionError("private fixture lock differs from its pinned source epoch")
        else:
            with path.open("xb") as output:
                output.write(content)
            path.chmod(0o600)
        paths[pair] = path
    return paths


@contextmanager
def retained_lock_context(root: Path):
    import build_provider
    paths = materialize_epoch_locks(root)
    with patch.dict(build_provider.PROOF_PAIR_LOCKS, paths):
        yield paths


@contextmanager
def retained_workflow_context(root: Path):
    """Select template authority from its original immutable workflow epoch."""
    import verifier_receipt_owner
    from package_input import bounded_run
    if root.resolve() == ROOT.resolve() or root.is_symlink():
        raise AssertionError("fixture workflow context requires a private root")
    _epoch_lock_bytes()  # Authenticate the same immutable published epoch.
    result = bounded_run(("git", "show", TEMPLATE_SOURCE_REVISION + ":.github/workflows/ci.yml"),
                         cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE, timeout=15)
    if result.returncode or not result.stdout:
        raise AssertionError("pinned fixture workflow is unavailable")
    selection = root / ".fixture-workflow-epoch"
    workflow = selection / ".github/workflows/ci.yml"
    for path in (selection, selection / ".github", workflow.parent, workflow):
        if path.is_symlink():
            raise AssertionError("private fixture workflow is unsafe")
    workflow.parent.mkdir(parents=True, exist_ok=True)
    if workflow.exists():
        if not workflow.is_file() or workflow.read_bytes() != result.stdout:
            raise AssertionError("private fixture workflow differs from its pinned epoch")
    else:
        with workflow.open("xb") as output:
            output.write(result.stdout)
        workflow.chmod(0o600)
    with patch.object(verifier_receipt_owner, "ROOT", selection):
        yield selection


def context_for_template(template: dict, *, selection_root: Path = ROOT) -> dict:
    from verifier_receipt_owner import selected_runtime
    from package_input import bounded_run
    check_template_epoch(template)
    candidate = template["candidate"]
    result = bounded_run(("git", "show", candidate["source_revision"] + ":mix.exs"), cwd=ROOT,
                         stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
    if result.returncode:
        raise AssertionError("template source package version unavailable")
    source = result.stdout.decode()
    match = re.search(r'^\s*version:\s*"([^"]+)"', source, re.MULTILINE)
    if match is None:
        raise AssertionError("template source package version unavailable")
    elixir, otp, digest = selected_runtime(selection_root, "local-current")
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
