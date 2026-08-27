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
VERSION_PATTERN = re.compile(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?")
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
    try:
        postgres = command_output("pg_config", "--version")
    except EvidenceError:
        postgres = command_output("psql", "--version")

    values = {
        "elixir": match(r"^Elixir:\s+([^\s]+)", hex_info, "Elixir version"),
        "otp": match(r"^OTP:\s+([^\s]+)", hex_info, "OTP version"),
        "mix": match(r"^Mix\s+([^\s]+)", mix_info, "Mix version"),
        "hex": match(r"^Hex:\s+([^\s]+)", hex_info, "Hex version"),
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
    if payload["schema_version"] != SCHEMA_VERSION or payload["package"] != "lockspire":
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
    if not isinstance(artifact["bytes"], int) or artifact["bytes"] <= 0:
        raise EvidenceError("release artifact size is invalid")

    runtime = payload["runtime"]
    expected_runtime = {"elixir", "otp", "mix", "hex", "phoenix", "phoenix_live_view", "postgresql"}
    if not isinstance(runtime, dict) or set(runtime) != expected_runtime:
        raise EvidenceError("release runtime fields differ from the allowlist")
    safe_version = re.compile(r"[0-9]+(?:\.[0-9]+)+(?:-[0-9A-Za-z.-]+)?")
    if any(not isinstance(value, str) or safe_version.fullmatch(value) is None for value in runtime.values()):
        raise EvidenceError("release runtime value is invalid")


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
            write_json(args.output, {
                "schema_version": SCHEMA_VERSION,
                "stage": args.stage,
                "source_sha": manifest["source_sha"],
                "package": manifest["package"],
                "version": manifest["version"],
                "sha256": artifact["sha256"],
                "status": "verified",
            })
        return 0
    except (EvidenceError, OSError, subprocess.SubprocessError) as error:
        print(f"release evidence failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
