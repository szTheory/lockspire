#!/usr/bin/env python3
"""Derive Phase 140 CI-06/CI-07 status from committed records and one receipt.

This verifier never edits tracked files or moves HEAD/local main. It refreshes
only origin/main and FETCH_HEAD through a no-tags fetch, then checks the server's
advertisement separately; Git may also add fetched objects to its local object
database. Its only explicit result file is a new mode-0600 JSON beneath
/private/tmp/lockspire-140-plan. A successful result is valid only for the
exact synchronized SHA supplied on the command line. The receipt's local gate
and hygiene fields are trusted owner-only local evidence; GitHub workflow claims
are re-queried through the authenticated CLI before either requirement passes.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import sys
import tempfile
from urllib.parse import urlsplit


SCHEMA = "lockspire-phase-140-read-only-closure-v1"
REVIEW_SCHEMA = "lockspire-phase-140-external-review-v1"
RECEIPT_SCHEMA = "lockspire-phase-139-acceptance-v1"
VERSION = "1"
SCRIPT_PATH = "scripts/maintainer/verify_phase140_read_only_closure.py"
PRIVATE_DIR = Path("/private/tmp/lockspire-140-plan")
REVIEW_NAMESPACE = "lockspire-phase140-review"
REVIEW_SCOPE = [
    "read-only tracked/ref behavior",
    "receipt validation",
    "workflow identity",
    "no-publish classification",
]
SUMMARY_PATH = ".planning/phases/140-bounded-operational-loose-end-triage/140-18-SUMMARY.md"
VERIFICATION_PATH = ".planning/phases/140-bounded-operational-loose-end-triage/140-VERIFICATION.md"
ACCEPTANCE_PATH = ".planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md"
REQUIREMENTS_PATH = ".planning/REQUIREMENTS.md"
ROADMAP_PATH = ".planning/ROADMAP.md"
STATE_PATH = ".planning/STATE.md"

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
    SUMMARY_PATH,
    VERIFICATION_PATH,
    REQUIREMENTS_PATH,
    ROADMAP_PATH,
    STATE_PATH,
    ACCEPTANCE_PATH,
)
OID_RE = re.compile(r"^[0-9a-f]{40}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
PRINCIPAL_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._@+-]{0,127}$")
FINGERPRINT_RE = re.compile(r"^SHA256:[A-Za-z0-9+/]{43}$")


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


def gh_json(args: list[str], label: str):
    if shutil.which("gh") is None:
        fail("authenticated GitHub CLI is required for independent workflow verification")
    command = ["gh", *args]
    if args and args[0] == "api":
        command[2:2] = ["--hostname", "github.com"]
    result = subprocess.run(
        command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False
    )
    if result.returncode != 0:
        fail(f"GitHub API request failed while verifying {label}")
    return strict_json(result.stdout, label)


def validate_live_workflow(
    repository: str, sha: str, receipt_run: dict, workflow_file: str,
    workflow_name: str, expected_jobs: dict[str, str], outcome=None,
) -> dict:
    workflow_meta = gh_json(
        ["api", f"repos/{repository}/actions/workflows/{workflow_file}"],
        f"{workflow_name} workflow metadata",
    )
    workflow_id = workflow_meta.get("id") if isinstance(workflow_meta, dict) else None
    if (type(workflow_id) is not int or workflow_id <= 0
            or workflow_meta.get("name") != workflow_name
            or workflow_meta.get("path") != f".github/workflows/{workflow_file}"
            or workflow_meta.get("state") != "active"):
        fail(f"{workflow_name} workflow identity is unavailable or unexpected")

    run_id = receipt_run["run_id"]
    selected = gh_json(
        ["api", f"repos/{repository}/actions/workflows/{workflow_file}/runs?branch=main&event=push&head_sha={sha}&per_page=100"],
        f"{workflow_name} exact-SHA run selection",
    )
    if not isinstance(selected, dict):
        fail(f"{workflow_name} exact-SHA run selection is malformed")
    runs = selected.get("workflow_runs")
    if (type(selected.get("total_count")) is not int or selected["total_count"] < 1
            or not isinstance(runs, list) or len(runs) < 1):
        fail(f"{workflow_name} has no exact-SHA push run")
    selected_runs = [
        run for run in runs
        if isinstance(run, dict) and run.get("id") == run_id
    ]
    if len(selected_runs) != 1:
        fail(f"{workflow_name} receipt run is absent or duplicated in the exact-SHA run list")
    selected_run = selected_runs[0]
    if (selected_run.get("head_sha") != sha or selected_run.get("head_branch") != "main"
            or selected_run.get("event") != "push"
            or selected_run.get("workflow_id") != workflow_id):
        fail(f"{workflow_name} selected run list entry is not bound to main and the exact SHA")

    live_run = gh_json(
        ["api", f"repos/{repository}/actions/runs/{run_id}"], f"{workflow_name} run"
    )
    if (not isinstance(live_run, dict)
            or live_run.get("id") != run_id
            or live_run.get("name") != workflow_name
            or live_run.get("path") != f".github/workflows/{workflow_file}"
            or live_run.get("workflow_id") != workflow_id
            or not isinstance(live_run.get("repository"), dict)
            or live_run["repository"].get("full_name") != repository
            or live_run.get("event") != "push"
            or live_run.get("head_branch") != "main"
            or live_run.get("head_sha") != sha
            or live_run.get("status") != "completed"
            or live_run.get("conclusion") != "success"
            or live_run.get("html_url") != receipt_run["url"]):
        fail(f"{workflow_name} live run is not bound to the receipt's repository, workflow, and SHA")

    jobs_page = gh_json(
        ["api", f"repos/{repository}/actions/runs/{run_id}/jobs?per_page=100&page=1"],
        f"{workflow_name} jobs",
    )
    if not isinstance(jobs_page, dict):
        fail(f"{workflow_name} live jobs response is malformed")
    jobs = jobs_page.get("jobs")
    if (type(jobs_page.get("total_count")) is not int
            or jobs_page["total_count"] != len(expected_jobs)
            or not isinstance(jobs, list) or len(jobs) != len(expected_jobs)):
        fail(f"{workflow_name} live job list is incomplete or has unexpected jobs")
    observed = {}
    for job in jobs:
        if not isinstance(job, dict):
            fail(f"{workflow_name} live job entry is malformed")
        name = job.get("name")
        status = job.get("status")
        conclusion = job.get("conclusion")
        if not isinstance(name, str) or name in observed or status != "completed":
            fail(f"{workflow_name} live job entry is duplicated or incomplete")
        observed[name] = conclusion
    if observed != expected_jobs:
        fail(f"{workflow_name} live job graph differs from the required graph")
    return {"workflow_id": workflow_id, "run_id": run_id, "head_sha": sha}


def repository_from_origin(root: Path) -> str:
    remote = run_git(root, "remote", "get-url", "origin").decode("utf-8").strip()
    if remote.startswith("git@github.com:"):
        path = remote.removeprefix("git@github.com:")
    else:
        parsed = urlsplit(remote)
        if parsed.scheme not in {"https", "ssh"} or parsed.hostname != "github.com":
            fail("origin is not a GitHub repository URL")
        path = parsed.path.lstrip("/")
    path = path.removesuffix(".git")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", path):
        fail("origin repository path is malformed")
    return path


def validate_private_directory() -> None:
    if PRIVATE_DIR.is_symlink():
        fail("private evidence directory must not be a symlink")
    try:
        directory_stat = PRIVATE_DIR.lstat()
    except OSError as exc:
        raise ClosureError("private evidence directory is unavailable") from exc
    if (not stat.S_ISDIR(directory_stat.st_mode)
            or directory_stat.st_uid != os.getuid()
            or stat.S_IMODE(directory_stat.st_mode) != 0o700):
        fail("private evidence directory must be an owner-only mode-0700 directory")


def read_private_file(path: Path, label: str, limit: int) -> bytes:
    if not path.is_absolute() or path.parent != PRIVATE_DIR:
        fail(f"{label} must be stored directly beneath /private/tmp/lockspire-140-plan")
    validate_private_directory()
    try:
        file_stat = path.lstat()
    except OSError as exc:
        raise ClosureError(f"{label} is unavailable") from exc
    if (not stat.S_ISREG(file_stat.st_mode) or file_stat.st_uid != os.getuid()
            or stat.S_IMODE(file_stat.st_mode) != 0o600
            or file_stat.st_size <= 0 or file_stat.st_size > limit):
        fail(f"{label} must be a regular owner-only mode-0600 file within its size limit")
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0)
    fd = os.open(path, flags)
    try:
        opened_stat = os.fstat(fd)
        if (not stat.S_ISREG(opened_stat.st_mode) or opened_stat.st_uid != os.getuid()
                or stat.S_IMODE(opened_stat.st_mode) != 0o600
                or (opened_stat.st_dev, opened_stat.st_ino)
                != (file_stat.st_dev, file_stat.st_ino)):
            fail(f"{label} changed while being opened")
        with os.fdopen(fd, "rb") as stream:
            fd = -1
            data = stream.read(limit + 1)
    finally:
        if fd >= 0:
            os.close(fd)
    if len(data) > limit:
        fail(f"{label} exceeds its size limit")
    return data


def validate_live_github_evidence(root: Path, sha: str, receipt: dict) -> dict:
    if shutil.which("gh") is None:
        fail("authenticated GitHub CLI is required for independent workflow verification")
    origin_repository = repository_from_origin(root)
    github_env = os.environ.copy()
    github_env["GH_HOST"] = "github.com"
    github_env["GH_REPO"] = origin_repository
    auth = subprocess.run(
        ["gh", "auth", "status", "--hostname", "github.com"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False,
        env=github_env,
    )
    if auth.returncode != 0:
        fail("GitHub CLI authentication is unavailable")
    repository_result = subprocess.run(
        ["gh", "repo", "view", origin_repository, "--json", "nameWithOwner"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False, env=github_env,
    )
    if repository_result.returncode != 0:
        fail("GitHub repository identity is unavailable")
    repository_doc = strict_json(repository_result.stdout, "GitHub repository identity")
    repository = repository_doc.get("nameWithOwner") if isinstance(repository_doc, dict) else None
    if not isinstance(repository, str) or not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        fail("GitHub repository identity is malformed")
    if repository.casefold() != origin_repository.casefold():
        fail("github.com repository identity does not match origin")
    ci = validate_live_workflow(
        repository, sha, receipt["required_ci"], "ci.yml", "CI", CI_JOBS
    )
    release = validate_live_workflow(
        repository, sha, receipt["release_no_publish"], "release.yml", "Release", RELEASE_JOBS,
        "no_publish",
    )
    return {"repository": repository, "required_ci": ci, "release_no_publish": release}


def validate_receipt(receipt_path: Path, sha: str) -> tuple[dict, str]:
    if receipt_path.name != f"140-18-final-acceptance.{sha}.json":
        fail("receipt filename must be bound to the full candidate SHA")
    data = read_private_file(receipt_path, "receipt", 1024 * 1024)
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


def committed_executable(root: Path, sha: str, script_file: Path) -> tuple[bytes, str]:
    entry = run_git(root, "ls-tree", sha, "--", SCRIPT_PATH).decode("ascii").strip()
    if not re.fullmatch(
        r"100755 blob [0-9a-f]{40}\tscripts/maintainer/verify_phase140_read_only_closure\.py",
        entry,
    ):
        fail("committed verifier is not an executable regular Git file")
    script_bytes = read_committed_blob(root, sha, SCRIPT_PATH)
    if script_file.read_bytes() != script_bytes:
        fail("running executable bytes differ from the committed executable")
    return script_bytes, hashlib.sha256(script_bytes).hexdigest()


def parse_allowed_signer(data: bytes, principal: str) -> tuple[str, bytes]:
    try:
        text = data.decode("ascii")
    except UnicodeDecodeError as exc:
        raise ClosureError("allowed-signers file is not ASCII") from exc
    entries = [line for line in text.splitlines() if line.strip() and not line.lstrip().startswith("#")]
    if len(entries) != 1:
        fail("allowed-signers file must contain exactly one signer entry")
    match = re.fullmatch(
        r'([A-Za-z0-9][A-Za-z0-9._@+-]{0,127}) namespaces="([A-Za-z0-9_,.-]+)" '
        r'([A-Za-z0-9@._+-]+) ([A-Za-z0-9+/]+={0,2})(?: [^\r\n]*)?',
        entries[0],
    )
    if not match or match.group(1) != principal or match.group(2) != REVIEW_NAMESPACE:
        fail("allowed-signers entry does not bind the requested principal and namespace")
    try:
        key_blob = base64.b64decode(match.group(4), validate=True)
    except ValueError as exc:
        raise ClosureError("allowed-signers public key is malformed") from exc
    if len(key_blob) < 4:
        fail("allowed-signers public key is truncated")
    key_type_size = int.from_bytes(key_blob[:4], "big")
    key_type = key_blob[4 : 4 + key_type_size]
    if key_type_size == 0 or key_type.decode("ascii", errors="ignore") != match.group(3):
        fail("allowed-signers key type does not match its public-key blob")
    fingerprint = "SHA256:" + base64.b64encode(hashlib.sha256(key_blob).digest()).decode("ascii").rstrip("=")
    return fingerprint, key_blob


def write_private_temp(path: Path, data: bytes) -> None:
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0)
    fd = os.open(path, flags, 0o600)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "wb") as stream:
            fd = -1
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
    finally:
        if fd >= 0:
            os.close(fd)


def verify_ssh_signature(statement: bytes, signature: bytes, allowed_signers: bytes, principal: str) -> None:
    ssh_keygen = shutil.which("ssh-keygen")
    if ssh_keygen is None:
        fail("ssh-keygen is required to verify the external review signature")
    with tempfile.TemporaryDirectory(prefix="140-18-review-", dir=PRIVATE_DIR) as temporary_dir:
        directory = Path(temporary_dir)
        os.chmod(directory, 0o700)
        signers_path = directory / "allowed-signers"
        signature_path = directory / "review.sig"
        write_private_temp(signers_path, allowed_signers)
        write_private_temp(signature_path, signature)
        result = subprocess.run(
            [
                ssh_keygen,
                "-Y",
                "verify",
                "-f",
                str(signers_path),
                "-I",
                principal,
                "-n",
                REVIEW_NAMESPACE,
                "-s",
                str(signature_path),
            ],
            input=statement,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
    if result.returncode != 0:
        fail("external review signature is invalid")


def validate_signed_review(
    root: Path,
    record_sha: str,
    script_file: Path,
    statement_path: Path,
    signature_path: Path,
    allowed_signers_path: Path,
    reviewer_principal: str,
    trusted_fingerprint: str,
) -> dict:
    if not PRINCIPAL_RE.fullmatch(reviewer_principal):
        fail("reviewer principal is malformed")
    if not FINGERPRINT_RE.fullmatch(trusted_fingerprint):
        fail("trusted signer fingerprint is malformed")
    script_bytes, script_digest = committed_executable(root, record_sha, script_file)
    statement_bytes = read_private_file(statement_path, "review statement", 64 * 1024)
    signature_bytes = read_private_file(signature_path, "review signature", 64 * 1024)
    allowed_signers_bytes = read_private_file(allowed_signers_path, "allowed-signers file", 64 * 1024)
    statement = strict_json(statement_bytes, "review statement")
    exact_keys(
        statement,
        {"schema", "reviewed_commit", "executable_sha256", "reviewer_principal", "verdict", "review_scope"},
        "review statement",
    )
    canonical = (json.dumps(statement, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")
    if statement_bytes != canonical:
        fail("review statement is not in canonical UTF-8 JSON form")
    if (statement["schema"] != REVIEW_SCHEMA or statement["verdict"] != "PASS"
            or statement["review_scope"] != REVIEW_SCOPE):
        fail("review statement schema, verdict, or exact scope is invalid")
    reviewed_commit = statement["reviewed_commit"]
    reviewed_digest = statement["executable_sha256"]
    if not isinstance(reviewed_commit, str) or not OID_RE.fullmatch(reviewed_commit):
        fail("review statement has an invalid full reviewed commit OID")
    if not isinstance(reviewed_digest, str) or not SHA256_RE.fullmatch(reviewed_digest):
        fail("review statement has an invalid executable digest")
    if statement["reviewer_principal"] != reviewer_principal:
        fail("review statement principal differs from the independently supplied principal")
    if reviewed_digest != script_digest:
        fail("review statement does not bind the exact committed executable bytes")
    reviewed_script, reviewed_script_digest = committed_executable(root, reviewed_commit, script_file)
    if reviewed_script_digest != script_digest or reviewed_script != script_bytes:
        fail("reviewed commit does not contain the exact committed executable bytes")
    ancestry = subprocess.run(
        ["git", "-C", str(root), "merge-base", "--is-ancestor", reviewed_commit, record_sha],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if ancestry.returncode != 0:
        fail("reviewed commit is not an ancestor of the record SHA")
    observed_fingerprint, _key_blob = parse_allowed_signer(allowed_signers_bytes, reviewer_principal)
    if observed_fingerprint != trusted_fingerprint:
        fail("allowed-signers key fingerprint differs from the independently confirmed fingerprint")
    verify_ssh_signature(statement_bytes, signature_bytes, allowed_signers_bytes, reviewer_principal)
    return {
        "reviewed_commit": reviewed_commit,
        "executable_sha256": script_digest,
        "reviewer_principal": reviewer_principal,
        "trusted_fingerprint": trusted_fingerprint,
        "statement_sha256": hashlib.sha256(statement_bytes).hexdigest(),
        "signature_sha256": hashlib.sha256(signature_bytes).hexdigest(),
    }


def validate_pending_records(root: Path, sha: str) -> None:
    records = {}
    for path in CONDITIONAL_RECORDS:
        entry = run_git(root, "ls-tree", sha, "--", path).decode("ascii").strip()
        if not (entry.startswith("100644 blob ") and entry.endswith(chr(9) + path)):
            fail(f"conditional record is not a regular committed file: {path}")
        data = read_committed_blob(root, sha, path)
        try:
            content = data.decode("utf-8")
        except UnicodeDecodeError as exc:
            raise ClosureError(f"conditional record is not UTF-8: {path}") from exc
        records[path] = content

    summary = records[SUMMARY_PATH]
    if (not re.search(r"(?m)^phase: 140-bounded-operational-loose-end-triage\s*$", summary)
            or not re.search(r'(?m)^plan: "?18"?\s*$', summary)):
        fail("140-18 summary identity is missing or malformed")
    if not re.search(r"(?m)^status: complete\s*$", summary):
        fail("140-18 summary is not a committed complete plan summary")
    if re.search(r"(?m)^requirements-completed:.*\bCI-0[67]\b", summary):
        fail("140-18 summary incorrectly marks a pending CI requirement complete")

    requirements = records[REQUIREMENTS_PATH]
    for requirement in ("CI-06", "CI-07"):
        rows = re.findall(rf"(?m)^- \[([ xX])\] \*\*{requirement}\*\*:", requirements)
        if rows != [" "]:
            fail(f"{requirement} is not pending in REQUIREMENTS.md")
    verification = records[VERIFICATION_PATH]
    if "status: gaps_found" not in verification or "score: 30/32 must-haves verified" not in verification:
        fail("verification record does not preserve the two pending gaps")
    for requirement in ("CI-06", "CI-07"):
        if not re.search(
            rf"(?ms)^  - truth: \"{requirement} .*?^    status: failed\s*$",
            verification,
        ):
            fail(f"verification record is missing the {requirement} gap")

    roadmap = records[ROADMAP_PATH]
    phase_rows = re.findall(r"(?m)^- \[([ xX])\] \*\*Phase 140:", roadmap)
    if phase_rows != [" "]:
        fail("Phase 140 is not still open in ROADMAP.md")
    state = records[STATE_PATH]
    if (not re.search(r"(?m)^current_phase: 140\s*$", state)
            or not re.search(r"(?m)^status: (?!complete\s*$)[a-z_-]+\s*$", state)):
        fail("Phase 140 is not still open in STATE.md")

    acceptance = records[ACCEPTANCE_PATH]
    for requirement in ("CI-06", "CI-07"):
        if not re.search(rf"(?is){requirement}.{{0,180}}\bpending\b", acceptance):
            fail(f"acceptance contract does not retain pending status for {requirement}")

    for path, content in records.items():
        if re.search(
            r"(?im)^\s*(?:\*\*)?CI-0[67](?:\*\*)?\s*:\s*(?:pass(?:ed)?|complete(?:d)?|success)\b",
            content,
        ):
            fail(f"conditional record claims terminal CI success: {path}")


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
    PRIVATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    validate_private_directory()
    directory_fd = os.open(
        PRIVATE_DIR,
        os.O_RDONLY | getattr(os, "O_DIRECTORY", 0) | getattr(os, "O_NOFOLLOW", 0),
    )
    directory_stat = os.fstat(directory_fd)
    if (not stat.S_ISDIR(directory_stat.st_mode) or directory_stat.st_uid != os.getuid()
            or stat.S_IMODE(directory_stat.st_mode) != 0o700):
        os.close(directory_fd)
        fail("private output directory changed while being opened")
    if path.name in os.listdir(directory_fd):
        os.close(directory_fd)
        fail("output already exists; refusing to overwrite private evidence")
    fd, temporary_name = tempfile.mkstemp(prefix=".140-18-closure.", dir=PRIVATE_DIR)
    temporary = Path(temporary_name)
    linked = False
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "wb") as stream:
            stream.write(body)
            stream.flush()
            os.fsync(stream.fileno())
        os.link(temporary.name, path.name, src_dir_fd=directory_fd, dst_dir_fd=directory_fd)
        linked = True
        os.unlink(temporary.name, dir_fd=directory_fd)
        os.fsync(directory_fd)
    except Exception:
        if linked:
            try:
                os.unlink(path.name, dir_fd=directory_fd)
            except OSError:
                pass
        try:
            os.unlink(temporary.name, dir_fd=directory_fd)
        except OSError:
            pass
        raise
    finally:
        os.close(directory_fd)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify-review-only", action="store_true", help="verify the external review before candidate capture")
    parser.add_argument("--sha", help="full candidate SHA")
    parser.add_argument("--receipt", help="private mode-0600 terminal receipt JSON")
    parser.add_argument("--record-head", help="full SHA containing all conditional records")
    parser.add_argument("--output", help="new private JSON path under /private/tmp/lockspire-140-plan")
    parser.add_argument("--review-statement", required=True, help="private canonical UTF-8 external review statement")
    parser.add_argument("--review-signature", required=True, help="private detached SSH signature")
    parser.add_argument("--allowed-signers", required=True, help="private OpenSSH allowed-signers file")
    parser.add_argument("--reviewer-principal", required=True, help="independently confirmed reviewer principal")
    parser.add_argument("--trusted-fingerprint", required=True, help="independently confirmed SHA256 SSH key fingerprint")
    args = parser.parse_args()

    script_file = Path(__file__).resolve()
    root_text = subprocess.check_output(
        ["git", "-C", str(script_file.parent), "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL
    ).decode("utf-8").strip()
    root = Path(root_text).resolve()
    if script_file != (root / SCRIPT_PATH).resolve():
        fail("run the committed maintainer verifier from this repository")

    if args.verify_review_only:
        if args.sha or args.receipt or args.record_head or args.output:
            fail("review-only mode accepts review inputs only, without a receipt or output")
        head = resolve_ref(root, "HEAD", "HEAD")
        review = validate_signed_review(
            root,
            head,
            script_file,
            Path(args.review_statement),
            Path(args.review_signature),
            Path(args.allowed_signers),
            args.reviewer_principal,
            args.trusted_fingerprint,
        )
        if resolve_ref(root, "HEAD", "HEAD") != head:
            fail("HEAD moved during review-only preflight")
        result = {"review_preflight": "PASS", **review}
        print(json.dumps(result, sort_keys=True, separators=(",", ":")))
        return 0

    if not args.sha or not args.record_head or not args.receipt or not args.output:
        fail("full closure mode requires --sha, --record-head, --receipt, and --output")
    if not OID_RE.fullmatch(args.sha) or not OID_RE.fullmatch(args.record_head):
        fail("--sha and --record-head must be full lowercase 40-character object IDs")
    if args.sha != args.record_head:
        fail("candidate SHA and conditional-record head must be identical")

    head_before = resolve_ref(root, "HEAD", "HEAD")
    local_before = resolve_ref(root, "refs/heads/main", "local main")
    if head_before != args.sha or local_before != args.sha:
        fail("HEAD and local main must already equal the requested candidate before fetch")
    porcelain_before = run_git(root, "status", "--porcelain=v1", "--untracked-files=all", "-z")
    if porcelain_before:
        fail("worktree must be completely clean before closure")

    review = validate_signed_review(
        root,
        args.record_head,
        script_file,
        Path(args.review_statement),
        Path(args.review_signature),
        Path(args.allowed_signers),
        args.reviewer_principal,
        args.trusted_fingerprint,
    )
    executable_digest = review["executable_sha256"]
    validate_pending_records(root, args.record_head)
    receipt, receipt_digest = validate_receipt(Path(args.receipt), args.sha)
    github_evidence = validate_live_github_evidence(root, args.sha, receipt)
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
    if output.name != f"140-18-read-only-closure.{args.sha}.json":
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
        "github_evidence": github_evidence,
        "local_evidence_trust": "owner-only-mode-0600-receipt",
        "requirements": {"CI-06": "pass", "CI-07": "pass"},
        "read_only": True,
        "read_only_boundary": "tracked-files-and-HEAD/local-main-unchanged; origin/main-tracking-ref-and-FETCH_HEAD-refreshed; fetched-objects-may-enter-local-object-database",
        "receipt_trust": "owner-only mode-0600 local gate and hygiene evidence; live GitHub workflows re-queried",
        "method": {
            "version": VERSION,
            "invocation": [
                SCRIPT_PATH, "--sha", args.sha, "--record-head", args.record_head,
                "--receipt", str(Path(args.receipt)), "--review-statement", str(Path(args.review_statement)),
                "--review-signature", str(Path(args.review_signature)),
                "--allowed-signers", str(Path(args.allowed_signers)),
                "--reviewer-principal", args.reviewer_principal,
                "--trusted-fingerprint", args.trusted_fingerprint, "--output", str(output),
            ],
            "executable_sha256": executable_digest,
            "external_review": review,
        },
    }
    body = (json.dumps(result, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")
    atomic_private_output(output, body, root)

    # The evidence file is outside the checkout. Confirm no tracked state or
    # object identity changed after writing it.
    try:
        final_head = resolve_ref(root, "HEAD", "HEAD")
        final_local = resolve_ref(root, "refs/heads/main", "local main")
        final_fetched = resolve_ref(root, "refs/remotes/origin/main", "fetched origin/main")
        final_advertised = run_git(
            root, "ls-remote", "--exit-code", "origin", "refs/heads/main"
        ).decode("ascii").strip()
        final_porcelain = run_git(root, "status", "--porcelain=v1", "--untracked-files=all", "-z")
    except (ClosureError, OSError, subprocess.CalledProcessError):
        try:
            output.unlink()
        except OSError:
            pass
        raise
    if (final_head != args.sha or final_local != args.sha or final_fetched != args.sha
            or final_advertised != args.sha + chr(9) + "refs/heads/main" or final_porcelain):
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
