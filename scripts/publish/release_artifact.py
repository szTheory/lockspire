#!/usr/bin/env python3
"""Create and verify Lockspire's bounded release artifact evidence."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import urllib.request


SCHEMA_VERSION = 1
SHA_PATTERN = re.compile(r"[0-9a-f]{64}")
SOURCE_PATTERN = re.compile(r"[0-9a-f]{40}")
DECIMAL_ID_PATTERN = re.compile(r"[0-9]+")
VERSION_PATTERN = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?")
CREDENTIAL_PATTERN = re.compile(
    r"(?i)(?:gh[pousr]_[a-z0-9_]{20,}|github_pat_[a-z0-9_]{20,}|"
    r"hex_[a-z0-9]{20,}|bearer\s+[a-z0-9._~+/=-]+|"
    r"(?:api[_-]?key|token|secret|password)\s*[:=]\s*\S+)"
)
RELEASE_STAGES = (
    "candidate",
    "artifact",
    "prepublish",
    "hex_publish",
    "github_release",
    "tag",
    "docs",
    "install",
)
STAGE_STATES = {"passed", "failed", "not_run", "unknown"}
ROOT = Path(__file__).resolve().parents[2]


class EvidenceError(RuntimeError):
    pass


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def command_output(*command: str) -> str:
    completed = subprocess.run(
        command,
        cwd=ROOT,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        raise EvidenceError(f"required release tool failed: {command[0]}")
    return completed.stdout


def match(pattern: str, text: str, label: str) -> str:
    found = re.search(pattern, text, re.MULTILINE)
    if found is None:
        raise EvidenceError(f"could not determine {label}")
    return found.group(1)


def locked_version(package: str) -> str:
    lock = (ROOT / "mix.lock").read_text()
    value = match(rf'^\s*"{re.escape(package)}": \{{:hex, :{re.escape(package)}, "([^"]+)"', lock, package)
    if VERSION_PATTERN.fullmatch(value) is None:
        raise EvidenceError(f"invalid locked {package} version")
    return value


def runtime_versions() -> dict[str, str]:
    hex_info = command_output("mix", "hex.info")
    mix_info = command_output("mix", "--version")
    hex_version = match(r"^Hex:\s+([^\s]+)", hex_info, "Hex version")
    try:
        postgres = command_output("pg_config", "--version")
    except EvidenceError:
        postgres = command_output("psql", "--version")

    values = {
        "elixir": match(r"^Elixir:\s+([^\s]+)", hex_info, "Elixir version"),
        "otp": match(r"^OTP:\s+([^\s]+)", hex_info, "OTP version"),
        "mix": match(r"^Mix\s+([^\s]+)", mix_info, "Mix version"),
        "hex": hex_version,
        "publisher_hex": hex_version,
        "phoenix": locked_version("phoenix"),
        "phoenix_live_view": locked_version("phoenix_live_view"),
        "postgresql": match(r"(?:PostgreSQL\)?\s+)([0-9]+(?:\.[0-9]+)+)", postgres, "PostgreSQL version"),
    }
    if any(re.fullmatch(r"[0-9]+(?:\.[0-9]+)+(?:-[0-9A-Za-z.-]+)?", value) is None for value in values.values()):
        raise EvidenceError("runtime version contains an unexpected value")
    return values


def package_version(tarball: Path) -> str:
    found = re.fullmatch(r"lockspire-([0-9A-Za-z.-]+)\.tar", tarball.name)
    if found is None or VERSION_PATTERN.fullmatch(found.group(1)) is None:
        raise EvidenceError("release tar has an unexpected package/version name")
    declared = match(r'^\s*version:\s*"([^"]+)"', (ROOT / "mix.exs").read_text(), "project version")
    if found.group(1) != declared:
        raise EvidenceError("release tar version differs from mix.exs")
    return declared


def regular_tar(path: Path) -> Path:
    resolved = path.resolve(strict=True)
    if not resolved.is_file() or resolved.is_symlink():
        raise EvidenceError("release tar must be a regular file")
    return resolved


def create_manifest(tarball: Path, source_sha: str) -> dict[str, object]:
    if SOURCE_PATTERN.fullmatch(source_sha) is None:
        raise EvidenceError("source SHA must be an exact lowercase commit")
    tarball = regular_tar(tarball)
    version = package_version(tarball)
    return {
        "schema_version": SCHEMA_VERSION,
        "package": "lockspire",
        "version": version,
        "source_sha": source_sha,
        "artifact": {
            "filename": tarball.name,
            "sha256": sha256(tarball),
            "bytes": tarball.stat().st_size,
        },
        "runtime": runtime_versions(),
    }


def read_manifest(path: Path) -> dict[str, object]:
    if not path.is_file() or path.is_symlink():
        raise EvidenceError("release manifest must be a regular file")
    try:
        payload = json.loads(path.read_text())
    except json.JSONDecodeError as error:
        raise EvidenceError("release manifest is not valid JSON") from error
    validate_manifest(payload)
    return payload


def validate_manifest(payload: object) -> None:
    if not isinstance(payload, dict) or set(payload) != {
        "schema_version", "package", "version", "source_sha", "artifact", "runtime"
    }:
        raise EvidenceError("release manifest fields differ from the allowlist")
    if type(payload["schema_version"]) is not int or payload["schema_version"] != SCHEMA_VERSION:
        raise EvidenceError("release manifest schema version is invalid")
    if payload["package"] != "lockspire":
        raise EvidenceError("release manifest identity is invalid")
    if VERSION_PATTERN.fullmatch(str(payload["version"])) is None:
        raise EvidenceError("release manifest version is invalid")
    if SOURCE_PATTERN.fullmatch(str(payload["source_sha"])) is None:
        raise EvidenceError("release manifest source SHA is invalid")

    artifact = payload["artifact"]
    if not isinstance(artifact, dict) or set(artifact) != {"filename", "sha256", "bytes"}:
        raise EvidenceError("release artifact fields differ from the allowlist")
    if artifact["filename"] != f"lockspire-{payload['version']}.tar":
        raise EvidenceError("release artifact filename is invalid")
    if SHA_PATTERN.fullmatch(str(artifact["sha256"])) is None:
        raise EvidenceError("release artifact checksum is invalid")
    if type(artifact["bytes"]) is not int or artifact["bytes"] <= 0:
        raise EvidenceError("release artifact size is invalid")

    runtime = payload["runtime"]
    expected_runtime = {
        "elixir",
        "otp",
        "mix",
        "hex",
        "publisher_hex",
        "phoenix",
        "phoenix_live_view",
        "postgresql",
    }
    if not isinstance(runtime, dict) or set(runtime) != expected_runtime:
        raise EvidenceError("release runtime fields differ from the allowlist")
    safe_version = re.compile(r"[0-9]+(?:\.[0-9]+)+(?:-[0-9A-Za-z.-]+)?")
    if any(not isinstance(value, str) or safe_version.fullmatch(value) is None for value in runtime.values()):
        raise EvidenceError("release runtime value is invalid")
    if runtime["publisher_hex"] != runtime["hex"]:
        raise EvidenceError("publisher Hex version differs from builder Hex version")


def verify_local(tarball: Path, manifest: dict[str, object], source_sha: str) -> None:
    tarball = regular_tar(tarball)
    artifact = manifest["artifact"]
    assert isinstance(artifact, dict)
    if manifest["source_sha"] != source_sha or SOURCE_PATTERN.fullmatch(source_sha) is None:
        raise EvidenceError("release source SHA mismatch")
    if tarball.name != artifact["filename"] or tarball.stat().st_size != artifact["bytes"]:
        raise EvidenceError("release artifact identity mismatch")
    if sha256(tarball) != artifact["sha256"]:
        raise EvidenceError("release artifact checksum mismatch")


def release_response(manifest: dict[str, object], response_path: Path | None) -> dict[str, object]:
    if response_path is None:
        url = f"https://hex.pm/api/packages/lockspire/releases/{manifest['version']}"
        with urllib.request.urlopen(url, timeout=15) as response:
            body = response.read()
    else:
        body = response_path.read_bytes()
    try:
        payload = json.loads(body)
    except json.JSONDecodeError as error:
        raise EvidenceError("Hex release response is invalid JSON") from error
    if not isinstance(payload, dict):
        raise EvidenceError("Hex release response is not an object")
    if payload.get("version") != manifest["version"]:
        raise EvidenceError("Hex release version mismatch")
    artifact = manifest["artifact"]
    assert isinstance(artifact, dict)
    if payload.get("checksum") != artifact["sha256"]:
        raise EvidenceError("Hex release checksum mismatch")
    return payload


def write_json(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n")


def contains_credential(value: object) -> bool:
    if isinstance(value, str):
        return CREDENTIAL_PATTERN.search(value) is not None
    if isinstance(value, dict):
        return any(contains_credential(key) or contains_credential(item) for key, item in value.items())
    if isinstance(value, list):
        return any(contains_credential(item) for item in value)
    return False


def nullable_identifier(value: object, pattern: re.Pattern[str], label: str) -> str | None:
    if value is None:
        return None
    if not isinstance(value, str) or pattern.fullmatch(value) is None:
        raise EvidenceError(f"terminal receipt {label} is invalid")
    return value


def terminal_receipt(state_path: Path, manifest_path: Path | None, expected_run_id: str) -> dict[str, object]:
    if DECIMAL_ID_PATTERN.fullmatch(expected_run_id) is None:
        raise EvidenceError("terminal receipt workflow run identity is invalid")
    if not state_path.is_file() or state_path.is_symlink():
        raise EvidenceError("terminal receipt state must be a regular file")
    try:
        state = json.loads(state_path.read_text())
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise EvidenceError("terminal receipt state is invalid JSON") from error

    expected_keys = {
        "schema_version",
        "workflow_run_id",
        "source_sha",
        "ci_run_id",
        "package",
        "version",
        "stages",
        "observations",
    }
    if not isinstance(state, dict) or set(state) != expected_keys:
        raise EvidenceError("terminal receipt state fields differ from the allowlist")
    if contains_credential(state):
        raise EvidenceError("terminal receipt state contains a credential-like value")
    if type(state["schema_version"]) is not int or state["schema_version"] != SCHEMA_VERSION or state["package"] != "lockspire":
        raise EvidenceError("terminal receipt state identity is invalid")
    run_id = nullable_identifier(state["workflow_run_id"], DECIMAL_ID_PATTERN, "workflow run identity")
    if run_id != expected_run_id:
        raise EvidenceError("terminal receipt workflow run identity mismatch")
    source_sha = nullable_identifier(state["source_sha"], SOURCE_PATTERN, "source SHA")
    ci_run_id = nullable_identifier(state["ci_run_id"], DECIMAL_ID_PATTERN, "CI run identity")
    version = state["version"]
    if not isinstance(version, str) or VERSION_PATTERN.fullmatch(version) is None:
        raise EvidenceError("terminal receipt package version is invalid")

    stages = state["stages"]
    if not isinstance(stages, dict) or set(stages) != set(RELEASE_STAGES):
        raise EvidenceError("terminal receipt stage fields differ from the allowlist")
    if any(not isinstance(value, str) or value not in STAGE_STATES for value in stages.values()):
        raise EvidenceError("terminal receipt stage state is invalid")

    observations = state["observations"]
    observation_keys = {
        "hex_presence",
        "hex_checksum",
        "public_latest_version",
        "github_release_presence",
        "tag_target_sha",
        "docs_presence",
        "install_result",
    }
    if not isinstance(observations, dict) or set(observations) != observation_keys:
        raise EvidenceError("terminal receipt observation fields differ from the allowlist")
    if not isinstance(observations["hex_presence"], str) or observations["hex_presence"] not in {
        "present", "absent", "unknown"
    }:
        raise EvidenceError("terminal receipt Hex presence is invalid")
    if not isinstance(observations["github_release_presence"], str) or observations["github_release_presence"] not in {
        "present", "absent", "unknown"
    }:
        raise EvidenceError("terminal receipt GitHub release presence is invalid")
    if not isinstance(observations["docs_presence"], str) or observations["docs_presence"] not in {
        "present", "absent", "unknown"
    }:
        raise EvidenceError("terminal receipt documentation presence is invalid")
    if not isinstance(observations["install_result"], str) or observations["install_result"] not in STAGE_STATES:
        raise EvidenceError("terminal receipt install result is invalid")
    hex_checksum = nullable_identifier(observations["hex_checksum"], SHA_PATTERN, "Hex checksum")
    tag_target_sha = nullable_identifier(observations["tag_target_sha"], SOURCE_PATTERN, "tag target SHA")
    latest_version = observations["public_latest_version"]
    if latest_version is not None and (
        not isinstance(latest_version, str) or VERSION_PATTERN.fullmatch(latest_version) is None
    ):
        raise EvidenceError("terminal receipt public version is invalid")

    manifest_digest: str | None = None
    manifest_state = "not_run" if stages["artifact"] == "not_run" else "unknown"
    artifact_digest: str | None = None
    if manifest_path is not None:
        if manifest_path.is_symlink() or not manifest_path.is_file():
            manifest_state = "failed"
        else:
            manifest_bytes = manifest_path.read_bytes()
            manifest_digest = hashlib.sha256(manifest_bytes).hexdigest()
            try:
                manifest_payload = json.loads(manifest_bytes)
                validate_manifest(manifest_payload)
            except (EvidenceError, UnicodeDecodeError, json.JSONDecodeError):
                manifest_state = "failed"
            else:
                manifest_artifact = manifest_payload["artifact"]
                assert isinstance(manifest_artifact, dict)
                artifact_digest = manifest_artifact["sha256"]
                if (
                    manifest_payload["source_sha"] == source_sha
                    and manifest_payload["package"] == state["package"]
                    and manifest_payload["version"] == version
                ):
                    manifest_state = "passed"
                else:
                    manifest_state = "failed"

    normalized_stages = dict(stages)
    if manifest_state == "failed" and normalized_stages["artifact"] == "passed":
        normalized_stages["artifact"] = "failed"
    elif manifest_state != "passed" and normalized_stages["artifact"] == "passed":
        normalized_stages["artifact"] = "unknown"

    if observations["hex_presence"] == "present":
        if artifact_digest is None or hex_checksum is None:
            normalized_stages["hex_publish"] = "unknown"
        elif hex_checksum == artifact_digest:
            normalized_stages["hex_publish"] = "passed"
        else:
            normalized_stages["hex_publish"] = "failed"
    elif observations["hex_presence"] == "absent":
        if normalized_stages["hex_publish"] == "not_run":
            normalized_stages["hex_publish"] = "not_run"
        elif normalized_stages["hex_publish"] == "passed":
            normalized_stages["hex_publish"] = "unknown"
        else:
            normalized_stages["hex_publish"] = "failed"
    elif observations["hex_presence"] == "unknown" and normalized_stages["hex_publish"] == "passed":
        normalized_stages["hex_publish"] = "unknown"

    if observations["github_release_presence"] == "present":
        normalized_stages["github_release"] = "passed"
    elif observations["github_release_presence"] == "unknown":
        if normalized_stages["github_release"] == "passed":
            normalized_stages["github_release"] = "unknown"
    elif observations["github_release_presence"] == "absent":
        normalized_stages["github_release"] = (
            "not_run" if normalized_stages["github_release"] == "not_run" else "failed"
        )

    if tag_target_sha is not None:
        normalized_stages["tag"] = (
            "passed" if source_sha is not None and tag_target_sha == source_sha else "failed"
        )

    if observations["docs_presence"] == "present":
        normalized_stages["docs"] = "passed"
    elif observations["docs_presence"] == "absent":
        normalized_stages["docs"] = "failed"
    elif normalized_stages["docs"] == "passed":
        normalized_stages["docs"] = "unknown"

    normalized_stages["install"] = observations["install_result"]
    release_verified = (
        manifest_state == "passed"
        and artifact_digest is not None
        and all(normalized_stages[name] == "passed" for name in RELEASE_STAGES)
        and observations["hex_presence"] == "present"
        and hex_checksum == artifact_digest
        and observations["github_release_presence"] == "present"
        and tag_target_sha == source_sha
        and observations["docs_presence"] == "present"
        and observations["install_result"] == "passed"
    )

    blocker = "none"
    next_safe_action = "none"
    if not release_verified:
        if normalized_stages["candidate"] == "failed" or source_sha is None or ci_run_id is None:
            blocker, next_safe_action = "candidate_not_accepted", "repair_candidate_and_reauthorize"
        elif manifest_state == "failed" or normalized_stages["artifact"] == "failed":
            blocker, next_safe_action = "artifact_integrity_failed", "stop_and_escalate"
        elif (
            artifact_digest is not None
            and observations["hex_presence"] == "present"
            and hex_checksum is not None
            and hex_checksum != artifact_digest
        ):
            blocker, next_safe_action = "hex_checksum_mismatch", "stop_and_escalate_checksum_mismatch"
        elif manifest_state != "passed" or normalized_stages["artifact"] in {"unknown", "not_run"}:
            blocker, next_safe_action = "artifact_unavailable", "inspect_retained_prepublication_artifact"
        elif normalized_stages["prepublish"] != "passed":
            blocker, next_safe_action = "prepublish_not_complete", "inspect_release_run"
        elif observations["hex_presence"] == "present" and hex_checksum is None:
            blocker, next_safe_action = "hex_checksum_unknown", "query_public_release_state_again"
        elif observations["hex_presence"] == "unknown":
            blocker, next_safe_action = "hex_public_state_unknown", "query_public_release_state_again"
        elif observations["hex_presence"] == "absent":
            blocker, next_safe_action = "hex_not_public", "inspect_release_run_before_retry"
        elif normalized_stages["github_release"] == "failed" or observations["github_release_presence"] == "absent":
            blocker, next_safe_action = "github_release_missing", "retry_same_artifact_before_expiry"
        elif observations["github_release_presence"] == "unknown":
            blocker, next_safe_action = "github_release_state_unknown", "query_public_release_state_again"
        elif normalized_stages["tag"] == "failed":
            blocker, next_safe_action = "tag_target_mismatch", "stop_and_escalate_tag_mismatch"
        elif normalized_stages["tag"] != "passed" or tag_target_sha is None:
            blocker, next_safe_action = "tag_target_unknown", "query_public_release_state_again"
        elif normalized_stages["docs"] != "passed" or normalized_stages["install"] != "passed":
            blocker, next_safe_action = "public_verification_incomplete", "retry_same_artifact_before_expiry"
        else:
            blocker, next_safe_action = "release_proof_incomplete", "inspect_release_run"

    return {
        "schema_version": SCHEMA_VERSION,
        "workflow_run_id": run_id,
        "package": "lockspire",
        "version": version,
        "public_latest_version": latest_version,
        "source_sha": source_sha,
        "ci_run_id": ci_run_id,
        "manifest": {"sha256": manifest_digest, "state": manifest_state},
        "artifact": {"sha256": artifact_digest, "state": normalized_stages["artifact"]},
        "stages": normalized_stages,
        "observations": {
            "hex_presence": observations["hex_presence"],
            "hex_checksum": hex_checksum,
            "github_release_presence": observations["github_release_presence"],
            "tag_target_sha": tag_target_sha,
            "docs_presence": observations["docs_presence"],
            "install_result": observations["install_result"],
        },
        "release_verified": release_verified,
        "blocker": blocker,
        "next_safe_action": next_safe_action,
    }


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser()
    commands = root.add_subparsers(dest="command", required=True)

    create = commands.add_parser("create")
    create.add_argument("--tar", required=True, type=Path)
    create.add_argument("--source-sha", required=True)
    create.add_argument("--output", required=True, type=Path)

    local = commands.add_parser("verify-local")
    local.add_argument("--tar", required=True, type=Path)
    local.add_argument("--manifest", required=True, type=Path)
    local.add_argument("--source-sha", required=True)

    remote = commands.add_parser("verify-hex")
    remote.add_argument("--manifest", required=True, type=Path)
    remote.add_argument("--response", type=Path)

    receipt = commands.add_parser("receipt")
    receipt.add_argument("--manifest", required=True, type=Path)
    receipt.add_argument("--stage", required=True, choices=("prepublish", "postpublish"))
    receipt.add_argument("--output", required=True, type=Path)
    receipt.add_argument("--publisher-hex-version")
    receipt.add_argument("--publisher-api-export", choices=("true", "false"))
    receipt.add_argument("--exact-byte-fixture", choices=("true", "false"))

    terminal = commands.add_parser("terminal-receipt")
    terminal.add_argument("--input", required=True, type=Path)
    terminal.add_argument("--output", required=True, type=Path)
    terminal.add_argument("--manifest", type=Path)
    terminal.add_argument("--workflow-run-id", required=True)
    return root


def main(argv: list[str]) -> int:
    args = parser().parse_args(argv)
    try:
        if args.command == "create":
            write_json(args.output, create_manifest(args.tar, args.source_sha))
        elif args.command == "verify-local":
            manifest = read_manifest(args.manifest)
            verify_local(args.tar, manifest, args.source_sha)
        elif args.command == "verify-hex":
            manifest = read_manifest(args.manifest)
            release_response(manifest, args.response)
        elif args.command == "receipt":
            manifest = read_manifest(args.manifest)
            artifact = manifest["artifact"]
            assert isinstance(artifact, dict)
            compatibility_args = (
                args.publisher_hex_version,
                args.publisher_api_export,
                args.exact_byte_fixture,
            )
            publisher_compatibility = None
            if args.stage == "prepublish":
                if any(value is None for value in compatibility_args):
                    raise EvidenceError("prepublish receipt requires publisher compatibility proof")
                runtime = manifest["runtime"]
                assert isinstance(runtime, dict)
                if args.publisher_hex_version != runtime["hex"] or args.publisher_hex_version != runtime["publisher_hex"]:
                    raise EvidenceError("publisher compatibility version differs from the manifest")
                if args.publisher_api_export != "true":
                    raise EvidenceError("Hex.API.Release.publish/5 compatibility was not proven")
                if args.exact_byte_fixture != "true":
                    raise EvidenceError("exact-byte upload fixture did not pass")
                publisher_compatibility = {
                    "hex_version": args.publisher_hex_version,
                    "api_export": True,
                    "exact_byte_fixture": True,
                }
            elif any(value is not None for value in compatibility_args):
                raise EvidenceError("publisher compatibility proof belongs only to prepublish receipts")

            payload = {
                "schema_version": SCHEMA_VERSION,
                "stage": args.stage,
                "source_sha": manifest["source_sha"],
                "package": manifest["package"],
                "version": manifest["version"],
                "sha256": artifact["sha256"],
                "status": "verified",
            }
            if publisher_compatibility is not None:
                payload["publisher_compatibility"] = publisher_compatibility
            write_json(args.output, payload)
        elif args.command == "terminal-receipt":
            write_json(
                args.output,
                terminal_receipt(args.input, args.manifest, args.workflow_run_id),
            )
        return 0
    except (EvidenceError, OSError, subprocess.SubprocessError) as error:
        print(f"release evidence failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
