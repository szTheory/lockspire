#!/usr/bin/env python3
"""Derive Phase 140 CI-06/CI-07 status from committed records and one receipt.

This verifier never edits the checkout. Its only output is a new mode-0600 JSON
file beneath /private/tmp/lockspire-140-plan. A successful result is valid only
for the exact synchronized SHA supplied on the command line.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile


SCHEMA = "lockspire-phase-140-read-only-closure-v1"
PROOF_SCHEMA = "lockspire-phase-140-read-only-closure-proof-v1"
RECEIPT_SCHEMA = "lockspire-phase-139-acceptance-v1"
VERSION = "1"
SCRIPT_PATH = "scripts/maintainer/verify_phase140_read_only_closure.py"
PROOF_PATH = ".planning/phases/140-bounded-operational-loose-end-triage/140-17-read-only-closure-proof.json"
PRIVATE_DIR = Path("/private/tmp/lockspire-140-plan")

CI_JOBS = {
    "Dialyzer": "success",
    "Release Hygiene Drift": "success",
    "Fast Checks": "success",
    "Minimum Supported Elixir/OTP": "success",
    "Integration Checks": "success",
    "Complete Coverage Evidence": "success",
    "Adoption Demo Smoke": "success",
}
RELEASE_JOBS = {
    "Maintain Release Please PR": "success",
    "Validate exact main head and CI evidence": "skipped",
    "Prove exact package before publication": "skipped",
    "Publish verified release to Hex": "skipped",
    "Verify public install truth": "skipped",
}
PROTECTED_HASHES = {
    ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md": "b200d2491cffd55c5334e03a25f3410945a6df77e43c57172972e61f8c93c10f",
    ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-UAT.md": "adebfc5edc5d5671b4776b6c6495643a43123768907635c8905bd7045abd517b",
    ".planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md": "a38ba1062de64e990bd05381cacd1a044abefad1e5d1a6320b72413a7a55cc10",
    "docs/lockspire-milestone-roadmap-ratchet-prompt.txt": "8cba24252908e0de1a9c64198b0644579970c5c9c1bfa0ab26d733d720ca3b05",
}
CONDITIONAL_RECORDS = (
    ".planning/phases/140-bounded-operational-loose-end-triage/140-17-SUMMARY.md",
    ".planning/phases/140-bounded-operational-loose-end-triage/140-VERIFICATION.md",
    ".planning/REQUIREMENTS.md",
    ".planning/STATE.md",
    ".planning/ROADMAP.md",
)
PENDING_MARKER = "<!-- lockspire-phase-140-closure-status-v1 CI-06=pending CI-07=pending -->"
OID_RE = re.compile(r"^[0-9a-f]{40}$")


class ClosureError(Exception):
    pass


def fail(message: str) -> None:
    raise ClosureError(message)


def run_git(root: Path, *args: str, check: bool = True) -> bytes:
    result = subprocess.run(
        ["git", "-C", str(root), *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if check and result.returncode != 0:
        fail(f"git {' '.join(args[:2])} failed")
    return result.stdout


def strict_json(data: bytes, label: str):
    def no_duplicate_keys(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                fail(f"{label} contains a duplicate key")
            result[key] = value
        return result

    try:
        return json.loads(
            data.decode("utf-8"),
            object_pairs_hook=no_duplicate_keys,
            parse_constant=lambda _value: fail(f"{label} contains a non-JSON number"),
        )
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ClosureError(f"{label} is not valid UTF-8 JSON") from exc


def exact_keys(value, expected: set[str], label: str) -> None:
    if not isinstance(value, dict) or set(value) != expected:
        fail(f"{label} keys do not match the required schema")


def positive_int(value, label: str) -> None:
    if type(value) is not int or value <= 0:
        fail(f"{label} must be a positive integer")


def nonnegative_int(value, label: str) -> None:
    if type(value) is not int or value < 0:
        fail(f"{label} must be a nonnegative integer")


def validate_job_run(run, label: str, expected_jobs: dict[str, str], outcome=None) -> None:
    keys = {"status", "run_id", "event", "conclusion", "url", "jobs"}
    if outcome is not None:
        keys.add("outcome")
    exact_keys(run, keys, label)
    if run["status"] != "pass" or run["event"] != "push" or run["conclusion"] != "success":
        fail(f"{label} is not a successful push run")
    if outcome is not None and run["outcome"] != outcome:
        fail(f"{label} outcome is not {outcome}")
    positive_int(run["run_id"], f"{label} run id")
    if not isinstance(run["url"], str) or not re.fullmatch(r"https://[^\s]+", run["url"]):
        fail(f"{label} URL is malformed")
    jobs = run["jobs"]
    if not isinstance(jobs, list) or len(jobs) != len(expected_jobs):
        fail(f"{label} job count is wrong")
    observed = {}
    for job in jobs:
        exact_keys(job, {"name", "status", "conclusion"}, f"{label} job")
        name = job["name"]
        if not isinstance(name, str) or name in observed or job["status"] != "completed":
            fail(f"{label} contains a duplicate or incomplete job")
        observed[name] = job["conclusion"]
    if observed != expected_jobs:
        fail(f"{label} job graph is not the required graph")


def validate_receipt(receipt_path: Path, sha: str) -> tuple[dict, str]:
    if not receipt_path.is_absolute():
        fail("receipt path must be absolute")
    if receipt_path.parent != PRIVATE_DIR:
        fail("receipt must be stored beneath /private/tmp/lockspire-140-plan")
    if receipt_path.name != f"140-17-final-acceptance.{sha}.json":
        fail("receipt filename must be bound to the full candidate SHA")
    if PRIVATE_DIR.is_symlink():
        fail("private receipt directory must not be a symlink")
    try:
        directory_stat = PRIVATE_DIR.lstat()
    except OSError as exc:
        raise ClosureError("private receipt directory is unavailable") from exc
    if not stat.S_ISDIR(directory_stat.st_mode) or stat.S_IMODE(directory_stat.st_mode) != 0o700:
        fail("private receipt directory must be a real mode-0700 directory")
    try:
        file_stat = receipt_path.lstat()
    except OSError as exc:
        raise ClosureError("receipt is unavailable") from exc
    if (not stat.S_ISREG(file_stat.st_mode) or file_stat.st_uid != os.getuid()
            or stat.S_IMODE(file_stat.st_mode) != 0o600
            or file_stat.st_size <= 0 or file_stat.st_size > 1024 * 1024):
        fail("receipt must be a regular mode-0600 file no larger than 1 MiB")
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    fd = os.open(receipt_path, flags)
    try:
        opened_stat = os.fstat(fd)
        if (not stat.S_ISREG(opened_stat.st_mode) or opened_stat.st_uid != os.getuid()
                or stat.S_IMODE(opened_stat.st_mode) != 0o600
                or (opened_stat.st_dev, opened_stat.st_ino) != (file_stat.st_dev, file_stat.st_ino)):
            fail("receipt changed while being opened")
        with os.fdopen(fd, "rb") as stream:
            fd = -1
            data = stream.read(1024 * 1024 + 1)
    finally:
        if fd >= 0:
            os.close(fd)
    if len(data) > 1024 * 1024:
        fail("receipt exceeds 1 MiB")
    receipt = strict_json(data, "receipt")
    exact_keys(
        receipt,
        {"schema", "baseline_sha", "local_gate", "hygiene", "required_ci",
         "release_no_publish", "warn_dispositions", "supplemental_oidf"},
        "receipt",
    )
    if receipt["schema"] != RECEIPT_SCHEMA or receipt["baseline_sha"] != sha:
        fail("receipt schema or SHA does not match the requested candidate")

    local_gate = receipt["local_gate"]
    exact_keys(local_gate, {"status", "exunit_tests"}, "local gate")
    if local_gate["status"] != "pass":
        fail("local gate did not pass")
    positive_int(local_gate["exunit_tests"], "local gate test count")

    hygiene = receipt["hygiene"]
    exact_keys(hygiene, {"status", "pass", "warn", "block"}, "hygiene")
    if hygiene["status"] != "pass" or hygiene["block"] != 0:
        fail("hygiene did not pass without BLOCK findings")
    positive_int(hygiene["pass"], "hygiene PASS count")
    nonnegative_int(hygiene["warn"], "hygiene WARN count")
    nonnegative_int(hygiene["block"], "hygiene BLOCK count")

    validate_job_run(receipt["required_ci"], "required CI", CI_JOBS)
    validate_job_run(receipt["release_no_publish"], "Release no-publish", RELEASE_JOBS, "no_publish")

    dispositions = receipt["warn_dispositions"]
    if not isinstance(dispositions, list) or len(dispositions) != hygiene["warn"]:
        fail("WARN disposition count does not match the hygiene receipt")
    labels = set()
    for disposition in dispositions:
        exact_keys(disposition, {"label", "disposition"}, "WARN disposition")
        label, value = disposition["label"], disposition["disposition"]
        if (not isinstance(label, str)
                or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9 ._/-]{0,127}", label)
                or label in labels
                or not isinstance(value, str)
                or not re.fullmatch(r"[a-z0-9][a-z0-9._-]{0,63}", value)):
            fail("WARN disposition is malformed or duplicated")
        labels.add(label)
    if receipt["supplemental_oidf"] != {
        "classification": "supplemental_non_certifying", "required_gate": False
    }:
        fail("supplemental OIDF evidence has an invalid classification")
    return receipt, hashlib.sha256(data).hexdigest()


def read_committed_blob(root: Path, sha: str, path: str) -> bytes:
    return run_git(root, "show", f"{sha}:{path}")


def validate_proof(root: Path, sha: str, script_file: Path) -> tuple[dict, str]:
    tree_entry = run_git(root, "ls-tree", sha, "--", SCRIPT_PATH).decode("ascii").strip()
    if not re.fullmatch(r"100755 blob [0-9a-f]{40}\tscripts/maintainer/verify_phase140_read_only_closure\.py", tree_entry):
        fail("committed verifier is not an executable regular Git file")
    script_bytes = read_committed_blob(root, sha, SCRIPT_PATH)
    script_digest = hashlib.sha256(script_bytes).hexdigest()
    if script_file.read_bytes() != script_bytes:
        fail("running executable bytes differ from the committed executable")
    proof = strict_json(read_committed_blob(root, sha, PROOF_PATH), "independent review proof")
    exact_keys(
        proof,
        {"schema", "executable_sha256", "independently_reviewed", "read_only",
         "reviewer_identity", "proof_identity", "reviewed_head", "review_head_before",
         "review_head_after", "review_worktree_clean_before", "review_worktree_clean_after",
         "no_tracked_write_during_review", "no_head_movement_during_review", "verdict"},
        "independent review proof",
    )
    if (proof["schema"] != PROOF_SCHEMA or proof["executable_sha256"] != script_digest
            or proof["independently_reviewed"] is not True or proof["read_only"] is not True
            or proof["no_tracked_write_during_review"] is not True
            or proof["no_head_movement_during_review"] is not True
            or proof["review_worktree_clean_before"] is not True
            or proof["review_worktree_clean_after"] is not True
            or proof["verdict"] != "PASS"):
        fail("independent review proof does not certify this executable")
    for key in ("reviewer_identity", "proof_identity"):
        if not isinstance(proof[key], str) or not proof[key].strip():
            fail(f"independent review proof is missing {key}")
    for key in ("reviewed_head", "review_head_before", "review_head_after"):
        if not isinstance(proof[key], str) or not OID_RE.fullmatch(proof[key]):
            fail(f"independent review proof has an invalid {key}")
    if proof["reviewed_head"] != proof["review_head_before"] or proof["reviewed_head"] != proof["review_head_after"]:
        fail("independent review did not observe a stable HEAD")
    # `merge-base --is-ancestor` returns no stdout in either case; use its
    # status rather than inferring ancestry from output.
    ancestry = subprocess.run(
        ["git", "-C", str(root), "merge-base", "--is-ancestor", proof["reviewed_head"], sha],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if ancestry.returncode != 0:
        fail("reviewed executable commit is not an ancestor of the record head")
    return proof, script_digest


def validate_pending_records(root: Path, sha: str) -> None:
    for path in CONDITIONAL_RECORDS:
        data = read_committed_blob(root, sha, path)
        try:
            content = data.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise ClosureError(f"conditional record is not UTF-8: {path}") from exc
        if content.count(PENDING_MARKER) != 1:
            fail(f"conditional record must contain exactly one pending marker: {path}")
        for requirement in ("CI-06", "CI-07"):
            if not re.search(rf"^.*\b{requirement}: pending\b.*$", content, re.MULTILINE):
                fail(f"{requirement} must have an explicit pending line in {path}")
    requirements = read_committed_blob(root, sha, ".planning/REQUIREMENTS.md").decode("utf-8")
    for requirement in ("CI-06", "CI-07"):
        if not re.search(rf"^- \[ \] \*\*{requirement}\*\*:", requirements, re.MULTILINE):
            fail(f"{requirement} is not pending in REQUIREMENTS.md")
        if re.search(rf"^- \[x\] \*\*{requirement}\*\*:", requirements, re.MULTILINE | re.IGNORECASE):
            fail(f"{requirement} is marked complete in REQUIREMENTS.md")
    verification_path = ".planning/phases/140-bounded-operational-loose-end-triage/140-VERIFICATION.md"
    verification = read_committed_blob(root, sha, verification_path).decode("utf-8")
    if "status: gaps_found" not in verification or "score: 30/32 must-haves verified" not in verification:
        fail("verification record does not preserve the two pending gaps")
    for requirement in ("CI-06", "CI-07"):
        if not re.search(rf"^  - truth: \"{requirement} ", verification, re.MULTILINE):
            fail(f"verification record is missing the {requirement} gap")


def resolve_ref(root: Path, ref: str, label: str) -> str:
    value = run_git(root, "rev-parse", "--verify", ref).decode("ascii").strip()
    if not OID_RE.fullmatch(value):
        fail(f"{label} is not a full SHA-1 object ID")
    return value


def validate_protected_hashes(root: Path, sha: str) -> dict[str, str]:
    observed = {}
    for path, expected in PROTECTED_HASHES.items():
        digest = hashlib.sha256(read_committed_blob(root, sha, path)).hexdigest()
        if digest != expected:
            fail(f"protected hash changed for {path}")
        observed[path] = digest
    return observed


def atomic_private_output(path: Path, body: bytes, root: Path) -> None:
    if path.parent != PRIVATE_DIR:
        fail("output must be directly inside /private/tmp/lockspire-140-plan")
    try:
        path.resolve(strict=False).relative_to(root.resolve())
    except ValueError:
        pass
    else:
        fail("output must be outside the repository")
    if path.exists() or path.is_symlink():
        fail("output already exists; refusing to overwrite private evidence")
    if PRIVATE_DIR.is_symlink():
        fail("private output directory must not be a symlink")
    PRIVATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    directory_stat = PRIVATE_DIR.lstat()
    if not stat.S_ISDIR(directory_stat.st_mode) or stat.S_IMODE(directory_stat.st_mode) != 0o700:
        fail("private output directory must be a real mode-0700 directory")
    fd, temporary_name = tempfile.mkstemp(prefix=".140-17-closure.", dir=PRIVATE_DIR)
    temporary = Path(temporary_name)
    linked = False
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "wb") as stream:
            stream.write(body)
            stream.flush()
            os.fsync(stream.fileno())
        os.link(temporary, path)
        linked = True
        temporary.unlink()
    except Exception:
        if linked:
            try:
                path.unlink()
            except OSError:
                pass
        try:
            temporary.unlink()
        except OSError:
            pass
        raise


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sha", required=True, help="full candidate SHA")
    parser.add_argument("--receipt", required=True, help="private mode-0600 terminal receipt JSON")
    parser.add_argument("--record-head", required=True, help="full SHA containing all conditional records")
    parser.add_argument("--output", required=True, help="new private JSON path under /private/tmp/lockspire-140-plan")
    args = parser.parse_args()

    if not OID_RE.fullmatch(args.sha) or not OID_RE.fullmatch(args.record_head):
        fail("--sha and --record-head must be full lowercase 40-character object IDs")
    if args.sha != args.record_head:
        fail("candidate SHA and conditional-record head must be identical")

    script_file = Path(__file__).resolve()
    root_text = subprocess.check_output(
        ["git", "-C", str(script_file.parent), "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL
    ).decode("utf-8").strip()
    root = Path(root_text).resolve()
    if script_file != (root / SCRIPT_PATH).resolve():
        fail("run the committed maintainer verifier from this repository")

    head_before = resolve_ref(root, "HEAD", "HEAD")
    local_before = resolve_ref(root, "refs/heads/main", "local main")
    if head_before != args.sha or local_before != args.sha:
        fail("HEAD and local main must already equal the requested candidate before fetch")
    porcelain_before = run_git(root, "status", "--porcelain=v1", "--untracked-files=all", "-z")
    if porcelain_before:
        fail("worktree must be completely clean before closure")

    proof, executable_digest = validate_proof(root, args.record_head, script_file)
    validate_pending_records(root, args.record_head)
    receipt, receipt_digest = validate_receipt(Path(args.receipt), args.sha)
    protected = validate_protected_hashes(root, args.record_head)

    # Refresh only origin/main; this is metadata-only and must converge on the
    # already selected SHA. Read the server advertisement independently.
    subprocess.run(
        ["git", "-C", str(root), "fetch", "--no-tags", "origin",
         "refs/heads/main:refs/remotes/origin/main"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        check=True,
    )
    fetched = resolve_ref(root, "refs/remotes/origin/main", "fetched origin/main")
    advertised_bytes = run_git(root, "ls-remote", "--exit-code", "origin", "refs/heads/main")
    advertised_lines = advertised_bytes.decode("ascii").splitlines()
    if len(advertised_lines) != 1 or not re.fullmatch(r"[0-9a-f]{40}\trefs/heads/main", advertised_lines[0]):
        fail("origin/main advertisement is missing or ambiguous")
    advertised = advertised_lines[0].split("\t", 1)[0]

    head_after = resolve_ref(root, "HEAD", "HEAD")
    local_after = resolve_ref(root, "refs/heads/main", "local main")
    porcelain_after = run_git(root, "status", "--porcelain=v1", "--untracked-files=all", "-z")
    if (head_after != head_before or local_after != local_before or head_after != args.sha
            or local_after != args.sha or fetched != args.sha or advertised != args.sha
            or porcelain_after != porcelain_before):
        fail("refs or worktree changed or do not all match the accepted SHA")
    diff = run_git(root, "diff", "--binary", "origin/main...HEAD")
    if diff:
        fail("candidate contains a diff from synchronized origin/main")
    if resolve_ref(root, "HEAD", "HEAD") != args.sha:
        fail("HEAD moved during closure derivation")

    output = Path(args.output)
    if not output.is_absolute():
        fail("--output must be an absolute path")
    if output.name != f"140-17-read-only-closure.{args.sha}.json":
        fail("output filename must be bound to the full candidate SHA")
    result = {
        "schema": SCHEMA,
        "sha": args.sha,
        "record_head_sha": args.record_head,
        "receipt_sha256": receipt_digest,
        "receipt_schema": receipt["schema"],
        "conditional_records_pending": True,
        "refs_and_worktree": "pass",
        "refs": {
            "head": head_after,
            "local_main": local_after,
            "fetched_origin_main": fetched,
            "advertised_origin_main": advertised,
            "porcelain": "",
            "binary_diff_sha256": hashlib.sha256(diff).hexdigest(),
        },
        "protected_hashes": protected,
        "requirements": {"CI-06": "pass", "CI-07": "pass"},
        "read_only": True,
        "method": {
            "version": VERSION,
            "invocation": [
                SCRIPT_PATH, "--sha", args.sha, "--receipt", str(Path(args.receipt)),
                "--record-head", args.record_head, "--output", str(output),
            ],
            "executable_sha256": executable_digest,
            "proof_identity": proof["proof_identity"],
        },
    }
    body = (json.dumps(result, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")
    atomic_private_output(output, body, root)

    # The evidence file is outside the checkout. Confirm no tracked state or
    # object identity changed after writing it.
    if (resolve_ref(root, "HEAD", "HEAD") != args.sha
            or resolve_ref(root, "refs/heads/main", "local main") != args.sha
            or run_git(root, "status", "--porcelain=v1", "--untracked-files=all", "-z")):
        try:
            output.unlink()
        except OSError:
            pass
        fail("checkout changed while writing the private closure result")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ClosureError, OSError, subprocess.CalledProcessError) as exc:
        print(f"phase140-read-only-closure: {exc}", file=sys.stderr)
        raise SystemExit(1)
