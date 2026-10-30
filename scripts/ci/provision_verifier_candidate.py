#!/usr/bin/env python3
"""Build and authenticate this job's frozen verifier candidate before pair execution."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts" / "acceptance" / "clean_room"))
import verifier_delivery  # noqa: E402
from package_input import package_tree_digest, package_version, sha256, unpack_hex_tarball  # noqa: E402

REVISION = re.compile(r"[0-9a-f]{40,64}\Z")


def _git(*args: str) -> str:
    result = subprocess.run(("git", *args), cwd=ROOT, stdin=subprocess.DEVNULL,
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                            check=False, timeout=20)
    if result.returncode:
        raise ValueError("source identity unavailable")
    return result.stdout.decode("ascii", errors="strict").strip()


def covered_input_relation(repo_root: Path, runner_revision: str,
                           package_source_revision: str, paths: list[str]) -> list[dict[str, str]]:
    """Bind separate runner/source revisions through exact, finite package input bytes."""
    if (not REVISION.fullmatch(runner_revision) or not REVISION.fullmatch(package_source_revision)
            or not paths or len(paths) != len(set(paths))):
        raise ValueError("covered source identity is malformed")
    rows = []
    runner_hashes = verifier_delivery.committed_hashes(repo_root, runner_revision, verifier_delivery.PLANNING_INPUTS)
    package_hashes = verifier_delivery.committed_hashes(repo_root, package_source_revision, verifier_delivery.PLANNING_INPUTS)
    for relative in paths:
        path = Path(relative)
        if path.is_absolute() or ".." in path.parts or not relative:
            raise ValueError("covered input path is unsafe")
        values = [runner_hashes.get(relative), package_hashes.get(relative)]
        if any(value is None for value in values):
            raise ValueError("covered input is absent from a selected source")
        if values[0] != values[1]:
            raise ValueError("runner and package source bytes differ")
        rows.append({"path": relative, "runner_sha256": values[0], "package_sha256": values[1]})
    return rows


def validate_checkout_pins(repo_root: Path, expected_runner: str,
                           expected_candidate_source: str) -> None:
    if not REVISION.fullmatch(expected_runner) or not REVISION.fullmatch(expected_candidate_source):
        raise ValueError("workflow source pins are malformed")
    current = subprocess.run(("git", "rev-parse", "HEAD"), cwd=repo_root,
                             stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                             stderr=subprocess.DEVNULL, check=False, timeout=20)
    candidate = subprocess.run(("git", "cat-file", "-e", f"{expected_candidate_source}^{{commit}}"),
                               cwd=repo_root, stdin=subprocess.DEVNULL,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                               check=False, timeout=20)
    status = subprocess.run(("git", "status", "--porcelain", "--untracked-files=no"), cwd=repo_root,
                            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.DEVNULL, check=False, timeout=20)
    if (current.returncode or current.stdout.decode("ascii", errors="strict").strip() != expected_runner
            or candidate.returncode or status.returncode or status.stdout):
        raise ValueError("workflow pins do not identify this clean job checkout")


def provision(expected_runner: str, expected_candidate_source: str,
              manifest_path: Path | None = None) -> dict[str, str]:
    validate_checkout_pins(ROOT, expected_runner, expected_candidate_source)
    covered_input_relation(ROOT, expected_runner, expected_candidate_source,
                           list(verifier_delivery.covered_inputs(expected_candidate_source)))
    if verifier_delivery.covered_inputs(expected_runner) != verifier_delivery.covered_inputs(expected_candidate_source):
        raise ValueError("runner and package selected input path sets differ")

    artifact_root = ROOT / ".artifacts" / "phase178" / "ci-candidate"
    if artifact_root.is_symlink() or artifact_root.exists():
        raise ValueError("job candidate artifact path is stale or unsafe")
    artifact_root.mkdir(parents=True, mode=0o700)
    archive = artifact_root / f"lockspire-{package_version(ROOT)}.tar"
    extracted = artifact_root / "lockspire"
    with tempfile.TemporaryDirectory(prefix="lockspire-ci-candidate-") as temporary:
        temp_root = Path(temporary)
        source_archive = temp_root / "source.tar"
        source = temp_root / "source"
        source.mkdir(mode=0o700)
        exported = subprocess.run(("git", "archive", "--format=tar", "--output", str(source_archive),
                                   expected_candidate_source), cwd=ROOT,
                                  stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, check=False, timeout=60)
        if exported.returncode:
            raise ValueError("candidate source export failed")
        unpacked = subprocess.run(("tar", "-xf", str(source_archive), "-C", str(source)), cwd=ROOT,
                                  stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, check=False, timeout=60)
        if unpacked.returncode:
            raise ValueError("candidate source export could not be unpacked")
        build = subprocess.run(("mix", "hex.build", "--output", str(archive)), cwd=source,
                               env=os.environ.copy(), stdin=subprocess.DEVNULL,
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               check=False, timeout=180)
        if build.returncode or not archive.is_file() or archive.is_symlink():
            raise ValueError("checked-in candidate package could not be built")
    unpack_hex_tarball(archive, extracted)
    archive_digest = sha256(archive)
    tree_digest = package_tree_digest(extracted)
    selected_manifest = manifest_path or (artifact_root / "178-FROZEN-INPUTS.json")
    manifest = verifier_delivery.create_frozen_manifest(
        ROOT / ".planning" / "phases" / verifier_delivery.PHASE_NAME,
        archive, extracted,
        expected_runner=expected_runner,
        expected_candidate_source=expected_candidate_source,
        expected_archive_sha256=archive_digest,
        expected_tree_sha256=tree_digest,
        manifest_path=selected_manifest,
    )
    pins = {
        "expected_runner": expected_runner,
        "expected_candidate_source": expected_candidate_source,
        "expected_archive_sha256": archive_digest,
        "expected_tree_sha256": tree_digest,
        "expected_manifest_sha256": sha256(manifest),
    }
    verifier_delivery.validate_frozen_manifest(
        ROOT / ".planning" / "phases" / verifier_delivery.PHASE_NAME,
        manifest_path=manifest, **pins,
    )
    return pins


def reviewed_candidate_source(expected_runner: str) -> str:
    """Select preserved frozen C while the workflow executes merge checkout H."""
    path = ROOT / ".planning/phases" / verifier_delivery.PHASE_NAME / "178-FROZEN-INPUTS.json"
    frozen = verifier_delivery._read_json(path, "reviewed candidate input")
    tested = frozen.get("runner_revision")
    owner = frozen.get("candidate_owner")
    if (frozen.get("schema") != "lockspire-phase178-frozen-inputs-v1"
            or frozen.get("closure_rule") != verifier_delivery.CLOSURE_RULE
            or not isinstance(owner, dict) or not isinstance(tested, str)
            or not REVISION.fullmatch(tested)
            or not verifier_delivery._metadata_only_difference(tested, expected_runner)):
        raise ValueError("reviewed frozen source does not apply to this workflow checkout")
    source = owner.get("source_revision")
    if not isinstance(source, str) or not REVISION.fullmatch(source):
        raise ValueError("reviewed package source is unavailable")
    expected = [{"path": path, "sha256": verifier_delivery._blob_sha(tested, path)}
                for path in verifier_delivery.covered_inputs(tested)]
    if frozen.get("covered_inputs") != expected:
        raise ValueError("reviewed frozen closure is incomplete")
    covered_input_relation(ROOT, expected_runner, source, [row["path"] for row in expected])
    return source


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected-runner", required=True)
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument("--expected-candidate-source")
    selection.add_argument("--reviewed-candidate-source", action="store_true")
    parser.add_argument("--github-output", type=Path)
    parser.add_argument("--manifest-path", type=Path,
                        default=Path(".artifacts/phase178/ci-candidate/178-FROZEN-INPUTS.json"))
    args = parser.parse_args(argv)
    try:
        candidate_source = reviewed_candidate_source(args.expected_runner) if args.reviewed_candidate_source else args.expected_candidate_source
        pins = provision(args.expected_runner, candidate_source,
                         args.manifest_path if args.manifest_path.is_absolute()
                         else ROOT / args.manifest_path)
        rows = {key: pins[key] for key in (
            "expected_runner", "expected_candidate_source", "expected_archive_sha256",
            "expected_tree_sha256", "expected_manifest_sha256",
        )}
        if args.github_output:
            with args.github_output.open("a", encoding="utf-8") as output:
                for key, value in rows.items():
                    output.write(f"{key}={value}\n")
        else:
            print(json.dumps(rows, sort_keys=True))
        return 0
    except (OSError, ValueError, verifier_delivery.DeliveryError):
        print("verifier candidate provisioning failed; diagnostics withheld", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
