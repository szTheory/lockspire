"""Semantic delivery checks for bounded Phase 178 evidence artifacts."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from typing import Any

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))

from package_input import PackageInputError, package_tree_digest, sha256, unpack_hex_tarball  # noqa: E402
from build_provider import PROOF_PAIR_LOCKS  # noqa: E402
from verifier_receipts import (  # noqa: E402
    REQUIRED_MATRIX, ReceiptError, expected_case_ids, validate_complete_matrix,
)

ROOT = HERE.parents[2]
PHASE_NAME = "178-packaged-upgrade-proof-delivery-handoff"
PHASE_DEFAULT = ROOT / ".planning" / "phases" / PHASE_NAME
ARTIFACT_DEFAULT = ROOT / ".artifacts" / "phase178"
REVISION = re.compile(r"[0-9a-f]{40,64}\Z")
SHA = re.compile(r"[0-9a-f]{64}\Z")

# Explicitly bounded. Do not replace this with a whole-repository history scan.
COVERED_INPUTS = (
    "scripts/acceptance/clean_room/verifier_delivery.py",
    "scripts/acceptance/clean_room/verifier_receipts.py",
    "scripts/acceptance/clean_room/package_input.py",
    "scripts/acceptance/clean_room_verifier_upgrade.py",
    "scripts/ci/run_verifier_upgrade_proof.sh",
    "scripts/ci/run_owned_source_tests.py",
    "scripts/ci/lint_workflows.sh",
    "test/acceptance/client_verifier_delivery_test.py",
    "test/acceptance/client_verifier_receipts_test.py",
    "test/clean_room/provider_host/mix.exs",
    "test/clean_room/provider_host/mix.lock",
    "test/clean_room/provider_host/lib/clean_room_provider/lifetime_client_store.ex",
    "docs/client-secret-verifier-configuration.md",
    "docs/client-secret-jwt-host-guide.md",
    "docs/install-and-onboard.md",
    "docs/getting-started.md",
    "docs/supported-surface.md",
    "docs/maintainer-release.md",
    ".github/workflows/ci.yml",
    ".planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-10-PLAN.md",
    ".planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-CONTEXT.md",
    ".planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-RESEARCH.md",
    ".planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-PATTERNS.md",
    ".planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-VALIDATION.md",
    ".planning/phases/177-safe-verifier-maintenance-recovery/177-VERIFICATION.md",
    ".planning/phases/177-safe-verifier-maintenance-recovery/177-SECURITY.md",
    ".planning/phases/177-safe-verifier-maintenance-recovery/177-SOURCE-ACCEPTANCE.json",
    ".planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-FINAL-SOURCE.json",
)


class DeliveryError(ValueError):
    """A finite delivery evidence contract failed."""


def _read_json(path: Path, label: str) -> dict[str, Any]:
    if path.is_symlink() or not path.is_file():
        raise DeliveryError(f"{label} is unavailable or unsafe")
    try:
        result = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, ValueError):
        raise DeliveryError(f"{label} is malformed") from None
    if not isinstance(result, dict):
        raise DeliveryError(f"{label} is malformed")
    return result


def _git(*args: str, cwd: Path = ROOT) -> str:
    result = subprocess.run(("git", *args), cwd=cwd, stdin=subprocess.DEVNULL,
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                            check=False, timeout=20)
    if result.returncode:
        raise DeliveryError("required source identity is unavailable")
    return result.stdout.decode("ascii", errors="strict").strip()


def _safe_repo_file(value: str) -> Path:
    path = Path(value)
    if path.is_absolute() or ".." in path.parts or not value:
        raise DeliveryError("covered input path is unsafe")
    full = ROOT
    for part in path.parts:
        full = full / part
        if full.is_symlink():
            raise DeliveryError("covered input is missing or unsafe")
    if not full.is_file():
        raise DeliveryError("covered input is missing or unsafe")
    return full


def _file_manifest(package_root: Path) -> list[dict[str, str]]:
    rows = []
    for path in sorted(package_root.rglob("*")):
        if path.is_symlink():
            raise DeliveryError("candidate package contains a symbolic link")
        if path.is_file():
            rows.append({"path": path.relative_to(package_root).as_posix(), "sha256": sha256(path)})
    if not rows:
        raise DeliveryError("candidate package tree is empty")
    return rows


def _verify_owner_source(owner: dict[str, Any], package_root: Path) -> None:
    revision = owner.get("source_revision")
    if not isinstance(revision, str) or not REVISION.fullmatch(revision):
        raise DeliveryError("candidate source owner revision is invalid")
    if _git("rev-parse", f"{revision}^{{tree}}") != owner.get("source_tree"):
        raise DeliveryError("candidate source tree identity is stale")
    files = owner.get("package_files")
    observed = _file_manifest(package_root)
    if files != observed:
        raise DeliveryError("candidate archive tree does not match its bounded file manifest")
    for row in observed:
        if row["path"] == "hex_metadata.config":
            # Mix generates this archive metadata from the checked source; it
            # is independently reproduced by _rebuild_source_package below.
            continue
        result = subprocess.run(("git", "show", f"{revision}:{row['path']}"), cwd=ROOT,
                                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, check=False, timeout=10)
        if result.returncode or hashlib.sha256(result.stdout).hexdigest() != row["sha256"]:
            raise DeliveryError("candidate archive file is not owned by the selected source commit")


def _rebuild_source_package(revision: str) -> tuple[str, dict[str, Any]]:
    """Rebuild and unpack a local archive from a detached Git source export."""
    with tempfile.TemporaryDirectory(prefix="lockspire-frozen-source-build-") as temporary:
        root = Path(temporary)
        source = root / "source"
        source.mkdir(mode=0o700)
        source_archive = root / "source.tar"
        package_archive = root / "lockspire.tar"
        result = subprocess.run(
            ("git", "archive", "--format=tar", "--output", str(source_archive), revision),
            cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, check=False, timeout=60,
        )
        if result.returncode:
            raise DeliveryError("frozen source export failed")
        result = subprocess.run(("tar", "-xf", str(source_archive), "-C", str(source)),
                                cwd=ROOT, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, check=False, timeout=60)
        if result.returncode:
            raise DeliveryError("frozen source export could not be unpacked")
        built = subprocess.run(("mix", "hex.build", "--output", str(package_archive)),
                               cwd=source, env=os.environ.copy(), stdin=subprocess.DEVNULL,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               check=False, timeout=180)
        if built.returncode or not package_archive.is_file():
            raise DeliveryError("frozen source package build failed")
        extracted = root / "extracted"
        try:
            unpack_hex_tarball(package_archive, extracted)
            tree_digest = package_tree_digest(extracted)
        except PackageInputError:
            raise DeliveryError("frozen source package could not be inspected") from None
        return tree_digest, {
            "command": "git archive <source-revision>; mix hex.build --output <owned-temporary>/lockspire.tar",
            "cwd": "<owned-temporary>/source (git archive of source_revision)",
            "git_archive_exit_code": 0, "package_build_exit_code": 0,
            "package_stdout_bytes": len(built.stdout),
            "package_stdout_sha256": hashlib.sha256(built.stdout).hexdigest(),
            "package_stderr_bytes": len(built.stderr),
            "package_stderr_sha256": hashlib.sha256(built.stderr).hexdigest(),
            "rebuilt_archive_sha256": sha256(package_archive),
            "rebuilt_tree_sha256": tree_digest,
        }


def frozen_owner_document(archive: Path, package_root: Path) -> dict[str, Any]:
    """Build a source-bound owner from an already produced local Hex archive."""
    artifact_root = (ROOT / ".artifacts" / "phase178").resolve(strict=True)
    if archive.is_symlink() or not archive.is_file():
        raise DeliveryError("candidate archive is unavailable or unsafe")
    archive = archive.resolve(strict=True)
    if archive == artifact_root or artifact_root not in archive.parents:
        raise DeliveryError("candidate archive must be inside the owned Phase 178 artifact root")
    if package_root.is_symlink() or not package_root.is_dir():
        raise DeliveryError("candidate extracted tree is unavailable or unsafe")
    package_root = package_root.resolve(strict=True)
    if package_root == artifact_root or artifact_root not in package_root.parents:
        raise DeliveryError("candidate extracted tree must be inside the owned Phase 178 artifact root")
    revision = _git("rev-parse", "HEAD")
    source_tree_digest, source_build = _rebuild_source_package(revision)
    candidate_tree_digest = package_tree_digest(package_root)
    if source_tree_digest != candidate_tree_digest:
        raise DeliveryError("frozen candidate tree differs from package built from its source commit")
    owner: dict[str, Any] = {
        "schema": "lockspire-frozen-candidate-owner-v1",
        "source_revision": revision,
        "source_tree": _git("rev-parse", f"{revision}^{{tree}}"),
        "archive_path": archive.relative_to(ROOT).as_posix(),
        "archive_sha256": sha256(archive),
        "extracted_tree_path": package_root.relative_to(ROOT).as_posix(),
        "tree_sha256": candidate_tree_digest,
        "package_files": _file_manifest(package_root),
        "source_build": source_build,
    }
    _verify_owner_source(owner, package_root)
    owner["owner_sha256"] = hashlib.sha256(
        json.dumps(owner, sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()
    return owner


def create_frozen_manifest(phase_dir: Path, archive: Path, package_root: Path) -> Path:
    owner = frozen_owner_document(archive, package_root)
    rows = []
    for relative in COVERED_INPUTS:
        source = _safe_repo_file(relative)
        if hashlib.sha256(subprocess.run(
                ("git", "show", f"HEAD:{relative}"), cwd=ROOT, stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False, timeout=10,
        ).stdout).hexdigest() != sha256(source):
            raise DeliveryError("covered inputs must be committed before freezing")
        rows.append({"path": relative, "sha256": sha256(source)})
    manifest = {
        "schema": "lockspire-phase178-frozen-inputs-v1",
        "frozen_at": datetime.now(timezone.utc).isoformat(),
        "runner_revision": _git("rev-parse", "HEAD"),
        "runner_tree": _git("rev-parse", "HEAD^{tree}"),
        "candidate_owner": owner,
        "covered_inputs": rows,
    }
    target = phase_dir / "178-FROZEN-INPUTS.json"
    if target.exists() or target.is_symlink():
        raise DeliveryError("frozen input manifest already exists")
    target.write_text(json.dumps(manifest, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    return target


def validate_frozen_manifest(phase_dir: Path) -> dict[str, Any]:
    manifest = _read_json(phase_dir / "178-FROZEN-INPUTS.json", "frozen input manifest")
    if manifest.get("schema") != "lockspire-phase178-frozen-inputs-v1":
        raise DeliveryError("frozen input manifest schema is invalid")
    runner = manifest.get("runner_revision")
    if not isinstance(runner, str) or not REVISION.fullmatch(runner):
        raise DeliveryError("frozen runner identity is invalid")
    if _git("rev-parse", f"{runner}^{{tree}}") != manifest.get("runner_tree"):
        raise DeliveryError("frozen runner tree does not match its commit")
    rows = manifest.get("covered_inputs")
    expected_paths = list(COVERED_INPUTS)
    if not isinstance(rows, list) or [row.get("path") for row in rows if isinstance(row, dict)] != expected_paths:
        raise DeliveryError("frozen input path set differs from the bounded contract")
    for row in rows:
        path = _safe_repo_file(row["path"])
        if not isinstance(row.get("sha256"), str) or sha256(path) != row["sha256"]:
            raise DeliveryError("covered input bytes changed after freeze")
        if hashlib.sha256(subprocess.run(
                ("git", "show", f"{runner}:{row['path']}"), cwd=ROOT, stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False, timeout=10,
        ).stdout).hexdigest() != row["sha256"]:
            raise DeliveryError("frozen input bytes are not owned by the tested runner commit")
    owner = manifest.get("candidate_owner")
    if not isinstance(owner, dict):
        raise DeliveryError("candidate source owner is missing")
    owner_digest = owner.get("owner_sha256")
    if not isinstance(owner_digest, str) or not SHA.fullmatch(owner_digest):
        raise DeliveryError("candidate source owner digest is invalid")
    claim = {key: value for key, value in owner.items() if key != "owner_sha256"}
    if hashlib.sha256(json.dumps(claim, sort_keys=True, separators=(",", ":")).encode()).hexdigest() != owner_digest:
        raise DeliveryError("candidate source owner digest is invalid")
    archive_relative = owner.get("archive_path")
    if not isinstance(archive_relative, str):
        raise DeliveryError("candidate archive path is invalid")
    archive = _safe_repo_file(archive_relative)
    if sha256(archive) != owner.get("archive_sha256"):
        raise DeliveryError("frozen candidate archive bytes changed")
    tree_relative = owner.get("extracted_tree_path")
    if not isinstance(tree_relative, str):
        raise DeliveryError("candidate extracted tree path is invalid")
    tree_relative_path = Path(tree_relative)
    if tree_relative_path.is_absolute() or ".." in tree_relative_path.parts:
        raise DeliveryError("candidate extracted tree path is unsafe")
    tree_root = ROOT
    for part in tree_relative_path.parts:
        tree_root = tree_root / part
        if tree_root.is_symlink():
            raise DeliveryError("candidate extracted tree contains a symbolic path")
    if (tree_root == ARTIFACT_DEFAULT.resolve(strict=True)
            or ARTIFACT_DEFAULT.resolve(strict=True) not in tree_root.resolve(strict=True).parents
            or not tree_root.is_dir()
            or package_tree_digest(tree_root) != owner.get("tree_sha256")):
        raise DeliveryError("frozen candidate extracted tree changed")
    _verify_owner_source(owner, tree_root)
    source_tree_digest, source_build = _rebuild_source_package(owner["source_revision"])
    recorded_build = owner.get("source_build")
    stable_build_fields = (
        "command", "cwd", "git_archive_exit_code", "package_build_exit_code",
        "rebuilt_tree_sha256",
    )
    if (source_tree_digest != owner.get("tree_sha256") or not isinstance(recorded_build, dict)
            or any(recorded_build.get(field) != source_build.get(field) for field in stable_build_fields)):
        raise DeliveryError("frozen archive tree differs from a fresh build of its source commit")
    with tempfile.TemporaryDirectory(prefix="lockspire-frozen-owner-check-") as temporary:
        extracted = Path(temporary) / "lockspire"
        try:
            unpack_hex_tarball(archive, extracted)
        except PackageInputError:
            raise DeliveryError("frozen candidate archive could not be inspected") from None
        if package_tree_digest(extracted) != owner.get("tree_sha256"):
            raise DeliveryError("frozen candidate archive does not produce its selected source tree")
    return manifest


def _receipt_path(root: Path, relative: Any) -> Path:
    if not isinstance(relative, str) or Path(relative).is_absolute() or ".." in Path(relative).parts:
        raise DeliveryError("package receipt origin path is unsafe")
    path = root / relative
    current = root
    for part in Path(relative).parts:
        current = current / part
        if current.is_symlink():
            raise DeliveryError("package receipt origin path contains a symbolic link")
    if not path.is_file():
        raise DeliveryError("package receipt origin bytes are missing")
    return path


def compose_pair_indexes(
    locked_root: Path, floor_root: Path, *, expected_runner: str,
    expected_candidate: tuple[str, str, str], expected_candidate_proof: str | None = None,
) -> dict[str, Any]:
    """Compose only the two fresh fixed-wrapper pair partitions into the closed matrix."""
    from verifier_receipts import validate_receipt, validate_rollout_receipt

    rows: list[dict[str, Any]] = []
    origins: list[dict[str, str]] = []
    for pair, root, expected_receipts, expected_cases in (
        ("locked", locked_root, 14, 33), ("floor", floor_root, 12, 31),
    ):
        if root.is_symlink():
            raise DeliveryError("package pair root is symbolic")
        root = root.resolve(strict=True)
        artifact_root = (ROOT / ".artifacts" / "phase178").resolve(strict=True)
        if root.is_symlink() or root == artifact_root or artifact_root not in root.parents:
            raise DeliveryError("package pair root is outside its owned artifact boundary")
        index_path = root / "validated" / "index.json"
        index = _read_json(index_path, f"{pair} pair index")
        if (index.get("schema") != "lockspire-installed-verifier-pair-v1"
                or index.get("pair") != pair or index.get("runner_revision") != expected_runner
                or index.get("required_receipts") != expected_receipts
                or index.get("executed_receipts") != expected_receipts
                or index.get("required_cases") != expected_cases
                or index.get("passed_cases") != expected_cases or index.get("failed_cases") != 0
                or index.get("candidate_source_archive_tree") != list(expected_candidate)):
            raise DeliveryError(f"{pair} pair index is incomplete or has a substituted identity")
        cells = index.get("cells")
        expected_keys = {key for key in REQUIRED_MATRIX if key[1] == pair}
        if not isinstance(cells, list) or len(cells) != expected_receipts:
            raise DeliveryError(f"{pair} pair index has an incomplete cell set")
        seen: set[tuple[str, str, str]] = set()
        for row in cells:
            if not isinstance(row, dict):
                raise DeliveryError("package cell is malformed")
            key = (row.get("scope"), row.get("pair"), row.get("store"))
            if key not in expected_keys or key in seen:
                raise DeliveryError("package pair contains an extra or duplicate cell")
            seen.add(key)
            path = _receipt_path(root, row.get("receipt_path"))
            raw = path.read_bytes()
            digest = hashlib.sha256(raw).hexdigest()
            if row.get("receipt_sha256") != digest:
                raise DeliveryError("package raw receipt digest does not match its origin bytes")
            try:
                receipt = json.loads(raw)
            except (UnicodeError, ValueError):
                raise DeliveryError("package raw receipt is malformed") from None
            if (not isinstance(receipt, dict) or receipt.get("run_id") != row.get("run_id")
                    or receipt.get("executed_count") != row.get("executed_count")
                    or row.get("outcome") != "pass"
                    or row.get("stable_case_ids") != expected_case_ids(key)
                    or row.get("candidate_source_archive_tree") != list(expected_candidate)
                    or row.get("runner_revision") != expected_runner):
                raise DeliveryError("package index summary is not bound to its receipt")
            if receipt.get("schema") == "lockspire-installed-verifier-rollout-v1":
                validate_rollout_receipt(receipt, expected_pair=pair, expected_store=key[2],
                                          expected_runner=expected_runner,
                                          expected_candidate_source=expected_candidate[0],
                                          expected_scope=key[0])
                candidate = receipt["candidate"]
            else:
                validate_receipt(receipt, expected_pair=pair, expected_store=key[2])
                if receipt.get("runner") != expected_runner:
                    raise DeliveryError("package receipt runner does not match frozen runner pin")
                candidate = receipt["candidate"]
            if (candidate.get("source_revision"), candidate.get("archive_sha256"),
                    candidate.get("tree_sha256")) != expected_candidate:
                raise DeliveryError("package receipt candidate identity differs from frozen owner")
            if expected_candidate_proof is not None and candidate.get("source_proof") != expected_candidate_proof:
                raise DeliveryError("package receipt does not carry the authenticated frozen owner")
            host = receipt.get("host", {})
            compiled = (receipt.get("processes", {}).get("candidate", {}).get("compiled_candidate_sha256")
                        if receipt.get("schema") == "lockspire-installed-verifier-rollout-v1"
                        else host.get("compiled_candidate_sha256"))
            if (host.get("lock_sha256") != row.get("host_lock_sha256")
                    or compiled != row.get("compiled_candidate_sha256")):
                raise DeliveryError("package host or compiled identity differs from the raw receipt")
            expected_lock = sha256(PROOF_PAIR_LOCKS[pair])
            if host.get("lock_sha256") != expected_lock:
                raise DeliveryError("package host lock does not match the selected dependency pair")
            if not isinstance(compiled, str) or not SHA.fullmatch(compiled):
                raise DeliveryError("package compiled candidate identity is invalid")
            rows.append(dict(row))
            origins.append({"pair": pair, "path": path.relative_to(root).as_posix(), "sha256": digest})
        if seen != expected_keys:
            raise DeliveryError(f"{pair} pair omits a required cell")
    matrix = validate_complete_matrix(rows, expected_runner=expected_runner)
    if len(matrix) != 26 or sum(len(row["stable_case_ids"]) for row in matrix) != 64:
        raise DeliveryError("composed package matrix is not the exact 26-cell/64-case contract")
    if {tuple(row["candidate_source_archive_tree"]) for row in matrix} != {expected_candidate}:
        raise DeliveryError("composed package matrix mixes candidate source/archive/tree owners")
    return {
        "schema": "lockspire-installed-verifier-composed-matrix-v1",
        "runner_revision": expected_runner,
        "candidate_source_archive_tree": list(expected_candidate),
        "required_receipt_count": 26, "executed_receipt_count": 26,
        "required_case_count": 64, "passed_case_count": 64, "failed_case_count": 0,
        "origins": origins, "cells": matrix,
    }


def validate_reviews(phase_dir: Path) -> None:
    for filename, expected_lane in (
        ("178-REVIEW.md", "source"), ("178-SECURITY.md", "security"),
        ("178-INTEGRATION.md", "integration"),
    ):
        path = phase_dir / filename
        if path.is_symlink() or not path.is_file():
            raise DeliveryError("independent review output is missing")
        content = path.read_text(encoding="utf-8")
        lower = content.lower()
        for heading in ("reviewer:", "reviewed commit:", "scope:", "date:", "findings", "evidence"):
            if heading not in lower:
                raise DeliveryError("review output omits reviewer scope or evidence")
        if expected_lane not in lower or any(marker in lower for marker in ("todo", "tbd", "the agent", "self-review")):
            raise DeliveryError("review output does not identify its independent review lane")
        if "finding" not in lower or "disposition" not in lower:
            raise DeliveryError("review findings lack an explicit disposition")
        date_match = re.search(r"(?im)^date:\s*(\d{4}-\d{2}-\d{2})\s*$", content)
        if not date_match:
            raise DeliveryError("review observation date is invalid")
        datetime.strptime(date_match.group(1), "%Y-%m-%d")


def _check_frozen(phase_dir: Path) -> dict[str, Any]:
    return validate_frozen_manifest(phase_dir)


def _check_package(phase_dir: Path, locked_root: Path, floor_root: Path) -> dict[str, Any]:
    frozen = validate_frozen_manifest(phase_dir)
    owner = frozen["candidate_owner"]
    matrix = compose_pair_indexes(
        locked_root, floor_root, expected_runner=frozen["runner_revision"],
        expected_candidate=(owner["source_revision"], owner["archive_sha256"], owner["tree_sha256"]),
        expected_candidate_proof=owner["owner_sha256"],
    )
    lines = [
        "# Phase 178 Package Acceptance",
        "",
        "This record composes the two successful fixed-wrapper partitions. It does not represent a third all-scope package producer or hosted CI.",
        "",
        f"- Tested runner: `{matrix['runner_revision']}`",
        f"- Candidate source: `{owner['source_revision']}`",
        f"- Candidate archive SHA-256: `{owner['archive_sha256']}`",
        f"- Candidate extracted tree SHA-256: `{owner['tree_sha256']}`",
        f"- Executed receipts: {matrix['executed_receipt_count']}/26",
        f"- Cases: {matrix['passed_case_count']}/64; failed: {matrix['failed_case_count']}",
        "",
        "| Pair | Scope | Store | Cases | Host lock SHA-256 | Compiled candidate SHA-256 | Origin | Receipt SHA-256 |",
        "|---|---|---|---:|---|---|---|---|",
    ]
    origin_by_key = {}
    for origin, row in zip(matrix["origins"], matrix["cells"], strict=True):
        origin_by_key[(row["scope"], row["pair"], row["store"])] = origin
    for row in matrix["cells"]:
        origin = origin_by_key[(row["scope"], row["pair"], row["store"])]
        lines.append(
            f"| {row['pair']} | {row['scope']} | {row['store']} | {len(row['stable_case_ids'])} | "
            f"`{row['host_lock_sha256']}` | `{row['compiled_candidate_sha256']}` | "
            f"`{origin['path']}` | `{origin['sha256']}` |"
        )
    content = "\n".join(lines) + "\n"
    report = phase_dir / "178-PACKAGE-ACCEPTANCE.md"
    if report.is_symlink():
        raise DeliveryError("package acceptance report path is symbolic")
    if report.exists() and report.read_text(encoding="utf-8") != content:
        raise DeliveryError("a different package acceptance report already exists; preserve the prior attempt")
    if not report.exists():
        report.write_text(content, encoding="utf-8")
    return matrix


def _check_source(phase_dir: Path) -> dict[str, Any]:
    frozen = validate_frozen_manifest(phase_dir)
    record = _read_json(phase_dir / "178-SOURCE-ACCEPTANCE.json", "source acceptance record")
    if record.get("tested_source_revision") != frozen["runner_revision"]:
        raise DeliveryError("source acceptance tested revision differs from frozen runner")
    if record.get("covered_inputs") != frozen["covered_inputs"]:
        raise DeliveryError("source acceptance does not bind the frozen input bytes")
    ci = record.get("canonical_ci")
    if not isinstance(ci, dict) or ci.get("exit_code") != 0 or ci.get("command") != (
            "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' "
            "python3 scripts/ci/run_owned_source_tests.py --ci"):
        raise DeliveryError("canonical guarded source gate is missing or failed")
    stages = ci.get("stages")
    if not isinstance(stages, list) or not stages:
        raise DeliveryError("canonical source gate has no stage observations")
    for stage in stages:
        if (not isinstance(stage, dict) or stage.get("exit_code") != 0
                or type(stage.get("tests")) is not int or stage["tests"] <= 0
                or type(stage.get("failures")) is not int or stage["failures"] != 0
                or not isinstance(stage.get("stdout_sha256"), str)
                or not SHA.fullmatch(stage["stdout_sha256"])):
            raise DeliveryError("canonical source stage is missing actual nonzero test evidence")
    return record


def check(stage: str, phase_dir: Path, locked_root: Path, floor_root: Path) -> dict[str, Any]:
    if stage == "reviews":
        validate_reviews(phase_dir)
        return {"reviews": 3, "runtime_acceptance_inferred": False}
    if stage == "frozen":
        return _check_frozen(phase_dir)
    if stage == "package":
        return _check_package(phase_dir, locked_root, floor_root)
    if stage == "source":
        return _check_source(phase_dir)
    if stage in {"candidate-identity", "candidate", "handoff"}:
        record = _read_json(phase_dir / "178-SOURCE-ACCEPTANCE.json", "source acceptance record")
        observed = record.get(stage.replace("-", "_") + "_observation")
        if not isinstance(observed, dict) or observed.get("available") is not True:
            raise DeliveryError(f"{stage} evidence is unavailable; acceptance cannot be claimed")
        if not isinstance(observed.get("raw_sha256"), str) or not SHA.fullmatch(observed["raw_sha256"]):
            raise DeliveryError(f"{stage} raw evidence is not authenticated")
        raise DeliveryError(f"{stage} validation requires the later workflow evidence owner")
    raise DeliveryError("unknown delivery check")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", choices=("reviews", "frozen", "source", "package",
                                             "candidate-identity", "candidate", "handoff"))
    parser.add_argument("--freeze", action="store_true")
    parser.add_argument("--phase-dir", type=Path, default=PHASE_DEFAULT)
    parser.add_argument("--archive", type=Path)
    parser.add_argument("--extracted-tree", type=Path)
    parser.add_argument("--locked-root", type=Path, default=ARTIFACT_DEFAULT / "final-locked")
    parser.add_argument("--floor-root", type=Path, default=ARTIFACT_DEFAULT / "final-floor")
    parser.add_argument("--expected-runner")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        if args.freeze:
            if args.archive is None or args.extracted_tree is None:
                raise DeliveryError("freeze requires an archive and extracted tree")
            target = create_frozen_manifest(args.phase_dir.resolve(), args.archive.resolve(), args.extracted_tree.resolve())
            print(json.dumps({"frozen": True, "manifest": str(target.relative_to(ROOT)),
                              "manifest_sha256": sha256(target)}, sort_keys=True))
            return 0
        if not args.check:
            raise DeliveryError("a delivery check stage is required")
        result = check(args.check, args.phase_dir.resolve(), args.locked_root, args.floor_root)
        print(json.dumps({"validated": args.check, "result": result}, sort_keys=True))
        return 0
    except (DeliveryError, PackageInputError, ReceiptError, OSError, ValueError, KeyError, TypeError):
        print("delivery evidence rejected; diagnostics withheld", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
