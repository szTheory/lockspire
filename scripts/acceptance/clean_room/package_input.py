#!/usr/bin/env python3
"""Build and audit the local package input for the clean-room acceptance lab."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
from typing import Iterable, Sequence
from urllib.parse import quote
import uuid


PROJECT_ROOT = Path(__file__).resolve().parents[3]
TEMPLATE_ROOT = PROJECT_ROOT / "test" / "clean_room"
ROLES = ("provider_host", "confidential_client")


class PackageInputError(RuntimeError):
    pass


@dataclass(frozen=True)
class PackageSource:
    kind: str
    value: str | None = None
    expected_sha256: str | None = None


@dataclass(frozen=True)
class PackageIdentity:
    kind: str
    version: str
    sha256: str
    archive_sha256: str | None = None
    tree_sha256: str | None = None
    source_revision: str | None = None

    def safe_receipt(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "source": self.kind,
            "package": "lockspire",
            "version": self.version,
            "sha256": self.sha256,
            "archive_sha256": self.archive_sha256 or self.sha256,
            "tree_sha256": self.tree_sha256 or "unavailable",
            "source_revision": self.source_revision or "unavailable",
        }


def require_command(command: str) -> None:
    if shutil.which(command) is None:
        raise PackageInputError(f"required command is unavailable: {command}")


def probe_environment() -> None:
    """Fail before child setup when a required clean-room boundary is unavailable."""
    require_command("mix")
    require_command("pg_isready")
    run(
        (
            "pg_isready",
            "-q",
            "-h",
            os.environ.get("CLEAN_ROOM_DB_HOST", "127.0.0.1"),
            "-p",
            os.environ.get("CLEAN_ROOM_DB_PORT", "5432"),
            "-U",
            os.environ.get("CLEAN_ROOM_DB_USER", "postgres"),
            "-d",
            os.environ.get("CLEAN_ROOM_DB_NAME", "postgres"),
        ),
        cwd=PROJECT_ROOT,
    )

    import socket

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
            listener.bind(("127.0.0.1", 0))
    except OSError as error:
        raise PackageInputError("loopback listener allocation is unavailable") from error


def clean_room_database_url(role: str) -> str:
    """Return an isolated database URL using the same explicit CI/local seam as the probe."""
    if not re.fullmatch(r"[a-z][a-z0-9_]{0,39}", role):
        raise PackageInputError("invalid clean-room database role")

    user = quote(os.environ.get("CLEAN_ROOM_DB_USER", "postgres"), safe="")
    password = quote(os.environ.get("CLEAN_ROOM_DB_PASSWORD", "postgres"), safe="")
    host = os.environ.get("CLEAN_ROOM_DB_HOST", "127.0.0.1")
    port = os.environ.get("CLEAN_ROOM_DB_PORT", "5432")
    database = f"lockspire_clean_room_{role}_{uuid.uuid4().hex}"
    return f"postgres://{user}:{password}@{host}:{port}/{database}"


def run(command: Sequence[str], *, cwd: Path, env: dict[str, str] | None = None) -> None:
    completed = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )

    if completed.returncode != 0:
        rendered = " ".join(command[:3])
        raise PackageInputError(f"{rendered} failed with exit status {completed.returncode}")


def inventory(root: Path) -> tuple[str, ...]:
    entries: list[str] = []

    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            raise PackageInputError(f"package input contains a symlink: {path.name}")
        if path.is_file():
            entries.append(str(path.relative_to(root)))

    if not entries:
        raise PackageInputError("unpacked Lockspire package has no files")

    if any(entry.startswith("test/support/") for entry in entries):
        raise PackageInputError("unpacked Lockspire package contains test support")

    return tuple(entries)


def build_package(run_root: Path) -> tuple[Path, tuple[str, ...]]:
    """Build and unpack one concrete local Hex archive before any child starts."""
    require_command("mix")
    package_root = run_root / "package" / "lockspire"
    package_root.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    archive = run_root / "package" / f"lockspire-{package_version(PROJECT_ROOT)}.tar"
    run(("mix", "hex.build", "--output", str(archive)), cwd=PROJECT_ROOT)
    unpack_hex_tarball(archive, package_root)

    return package_root.resolve(strict=True), inventory(package_root)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def package_tree_digest(root: Path) -> str:
    """Hash sorted relative names and bytes, rejecting links and empty trees."""
    digest = hashlib.sha256()
    paths = sorted(root.rglob("*"))
    for path in paths:
        if path.is_symlink():
            raise PackageInputError("candidate tree contains a symlink")
        if path.is_file():
            digest.update(path.relative_to(root).as_posix().encode("utf-8"))
            digest.update(b"\0")
            with path.open("rb") as handle:
                for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                    digest.update(chunk)
            digest.update(b"\0")
    if not any(path.is_file() for path in paths):
        raise PackageInputError("candidate tree contains no files")
    return digest.hexdigest()


def source_revision() -> str:
    result = subprocess.run(
        ("git", "rev-parse", "HEAD"), cwd=PROJECT_ROOT, stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False,
    )
    value = result.stdout.decode().strip()
    if result.returncode != 0 or not re.fullmatch(r"[0-9a-f]{40,64}", value):
        raise PackageInputError("candidate source revision could not be identified")
    return value


def verify_candidate_input(archive: Path, package_root: Path, identity: PackageIdentity) -> None:
    """Verify the source artifact and extracted tree before any child can reuse them."""
    if not archive.is_file() or sha256(archive) != (identity.archive_sha256 or identity.sha256):
        raise PackageInputError("candidate archive identity mismatch")
    if not package_root.is_dir() or package_tree_digest(package_root) != identity.tree_sha256:
        raise PackageInputError("candidate extracted tree identity mismatch")
    if package_version(package_root) != identity.version:
        raise PackageInputError("candidate package version identity mismatch")


def _compiled_candidate_digest(child_root: Path) -> str | None:
    roots = (child_root / "_build" / "dev" / "lib" / "lockspire", child_root / "_build" / "test" / "lib" / "lockspire")
    existing = [root for root in roots if root.exists()]
    if not existing:
        return None
    digest = hashlib.sha256()
    for root in existing:
        for path in sorted(root.rglob("*")):
            if path.is_symlink():
                raise PackageInputError("compiled candidate contains a symlink")
            if path.is_file():
                digest.update(path.relative_to(child_root).as_posix().encode("utf-8"))
                digest.update(b"\0")
                digest.update(path.read_bytes())
                digest.update(b"\0")
    return digest.hexdigest()


def bind_compiled_candidate(child_root: Path, identity: PackageIdentity, vendor_root: Path, resolved_root: Path) -> None:
    compiled = _compiled_candidate_digest(child_root)
    if compiled is None:
        raise PackageInputError("compiled candidate is missing after host preparation")
    marker = {
        "tree_sha256": identity.tree_sha256,
        "vendor_tree_sha256": package_tree_digest(vendor_root),
        "compiled_candidate_sha256": compiled,
        "resolved_dependency": str(resolved_root.resolve(strict=True)),
    }
    marker_path = child_root / ".lockspire-candidate.json"
    marker_path.write_text(json.dumps(marker, sort_keys=True, separators=(",", ":")) + "\n", encoding="utf-8")


def verify_candidate_host(
    package_root: Path, child_root: Path, identity: PackageIdentity,
    vendor_root: Path, resolved_dependency: Path,
) -> None:
    """Reject package, vendor, resolver, or compiled drift before a host is reused."""
    expected = identity.tree_sha256
    if not expected or package_tree_digest(package_root) != expected:
        raise PackageInputError("candidate source tree identity mismatch")
    if package_tree_digest(vendor_root) != expected:
        raise PackageInputError("candidate vendor tree identity mismatch")
    vendor = vendor_root.resolve(strict=True)
    resolved = resolved_dependency.resolve(strict=True)
    if resolved != vendor:
        raise PackageInputError("candidate resolved dependency identity mismatch")
    compiled = _compiled_candidate_digest(child_root)
    marker_path = child_root / ".lockspire-candidate.json"
    if compiled is None and not marker_path.exists():
        return
    if compiled is None or not marker_path.is_file():
        raise PackageInputError("candidate compiled state identity mismatch")
    try:
        marker = json.loads(marker_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        raise PackageInputError("candidate compiled state identity mismatch") from None
    expected_marker = {
        "tree_sha256": expected,
        "vendor_tree_sha256": expected,
        "compiled_candidate_sha256": compiled,
        "resolved_dependency": str(vendor),
    }
    if marker != expected_marker:
        raise PackageInputError("candidate compiled state identity mismatch")


def exact_version(value: str) -> str:
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?", value):
        raise PackageInputError("Lockspire package version must be exact")
    return value


def package_version(package_root: Path) -> str:
    match = re.search(r'^\s*version:\s*"([^"]+)"', (package_root / "mix.exs").read_text(), re.MULTILINE)
    if match is None:
        raise PackageInputError("unpacked Lockspire package has no exact version")
    return exact_version(match.group(1))


def unpack_hex_tarball(tarball: Path, package_root: Path) -> None:
    """Ask the installed Hex archive to validate and unpack its own package format."""
    require_command("elixir")
    package_root.mkdir(mode=0o700, parents=True, exist_ok=False)
    expression = """
Mix.start()
Mix.Local.append_archives()
tarball = File.read!(Enum.at(System.argv(), 0))
destination = Enum.at(System.argv(), 1) |> String.to_charlist()
case :mix_hex_tarball.unpack(tarball, destination) do
  {:ok, _metadata} -> :ok
  {:error, reason} -> raise "Hex package validation failed: #{inspect(reason)}"
end
"""
    run(("elixir", "-e", expression, str(tarball), str(package_root)), cwd=PROJECT_ROOT)


def validate_local_tarball(path: Path, allowed_root: Path, expected_sha256: str | None) -> tuple[Path, str, str]:
    resolved = path.resolve(strict=True)
    allowed = allowed_root.resolve(strict=True)
    if not resolved.is_file() or resolved.is_symlink():
        raise PackageInputError("Lockspire package tar must be a regular file")
    if resolved.parent != allowed and allowed not in resolved.parents:
        raise PackageInputError("Lockspire package tar escapes its declared root")
    match = re.fullmatch(r"lockspire-([0-9A-Za-z.-]+)\.tar", resolved.name)
    if match is None:
        raise PackageInputError("Lockspire package tar has an unexpected name")
    version = exact_version(match.group(1))
    checksum = sha256(resolved)
    if expected_sha256 is not None:
        if not re.fullmatch(r"[0-9a-f]{64}", expected_sha256) or checksum != expected_sha256:
            raise PackageInputError("Lockspire package tar checksum mismatch")
    return resolved, version, checksum


def prepare_package(run_root: Path, source: PackageSource | None = None) -> tuple[Path, tuple[str, ...], PackageIdentity]:
    source = source or PackageSource("checkout")
    package_root = run_root / "package" / "lockspire"

    if source.kind == "checkout":
        package_root, entries = build_package(run_root)
        version = package_version(package_root)
        tarball = run_root / "package" / f"lockspire-{version}.tar"
        checksum = sha256(tarball)
        tree = package_tree_digest(package_root)
        return package_root, entries, PackageIdentity("checkout", version, checksum, checksum, tree, source_revision())

    if source.kind == "hex":
        version = exact_version(source.value or "")
        downloads = run_root / "package" / "downloads"
        downloads.mkdir(mode=0o700, parents=True, exist_ok=True)
        tarball = downloads / f"lockspire-{version}.tar"
        run(("mix", "hex.package", "fetch", "lockspire", version, "--output", str(downloads)), cwd=run_root)
        allowed_root = downloads
    elif source.kind == "tar":
        tarball = Path(source.value or "")
        configured_root = os.environ.get("LOCKSPIRE_PACKAGE_ROOT")
        allowed_root = Path(configured_root) if configured_root else PROJECT_ROOT
    else:
        raise PackageInputError("unknown Lockspire package source")

    tarball, version, checksum = validate_local_tarball(tarball, allowed_root, source.expected_sha256)
    unpack_hex_tarball(tarball, package_root)
    unpacked_version = package_version(package_root)
    if unpacked_version != version:
        raise PackageInputError("Lockspire package filename and metadata versions differ")

    entries = inventory(package_root)
    package_root = package_root.resolve(strict=True)
    return package_root, entries, PackageIdentity(
        source.kind, version, checksum, checksum, package_tree_digest(package_root), source_revision()
    )


def assert_below(path: Path, root: Path, label: str) -> Path:
    resolved = path.resolve(strict=True)
    root_resolved = root.resolve(strict=True)

    if resolved == root_resolved or root_resolved not in resolved.parents:
        raise PackageInputError(f"{label} escapes its child root")

    return resolved


def copy_child_template(role: str, run_root: Path, package_root: Path) -> Path:
    template = TEMPLATE_ROOT / role
    if not (template / "mix.exs").is_file() or not (template / "mix.lock").is_file():
        raise PackageInputError(f"{role} template must contain checked-in mix.exs and mix.lock")

    child_root = run_root / role
    shutil.copytree(template, child_root, ignore=shutil.ignore_patterns("vendor", "_build", "deps"))
    vendor_root = child_root / "vendor" / "lockspire"
    vendor_root.parent.mkdir(mode=0o700, parents=True)
    shutil.copytree(package_root, vendor_root, symlinks=False)

    package_inventory = inventory(package_root)
    if inventory(vendor_root) != package_inventory:
        raise PackageInputError(f"{role} package inventory differs from unpacked input")

    vendor_realpath = assert_below(vendor_root, child_root, f"{role} Lockspire dependency")
    checkout = PROJECT_ROOT.resolve()
    if vendor_realpath == checkout or checkout in vendor_realpath.parents:
        raise PackageInputError(f"{role} Lockspire dependency resolves to the live checkout")

    return child_root


def locked_environment(child_root: Path, role: str, cache_root: Path | None) -> dict[str, str]:
    environment = os.environ.copy()
    environment["MIX_BUILD_PATH"] = str(child_root / "_build")

    if cache_root is not None:
        cache_realpath = cache_root.resolve()
        allowed_root = cache_root.parent.resolve()
        if cache_realpath != allowed_root and allowed_root not in cache_realpath.parents:
            raise PackageInputError("external dependency cache escapes its declared root")

        cache_role = "provider" if role == "provider_host" else "client"
        role_deps = cache_realpath / cache_role / "deps"
        role_deps.mkdir(mode=0o700, parents=True, exist_ok=True)
        environment["MIX_DEPS_PATH"] = str(role_deps)

    return environment


def verify_child(
    role: str, child_root: Path, cache_root: Path | None, extra_environment: dict[str, str] | None = None
) -> Path:
    before_manifest = (child_root / "mix.exs").read_bytes()
    before_lock = (child_root / "mix.lock").read_bytes()
    environment = locked_environment(child_root, role, cache_root)
    if extra_environment:
        environment.update(extra_environment)

    run(("mix", "deps.get", "--check-locked"), cwd=child_root, env=environment)
    run(("mix", "deps"), cwd=child_root, env=environment)

    dependency_path = subprocess.run(
        (
            "mix",
            "run",
            "--no-compile",
            "--no-deps-check",
            "--no-start",
            "-e",
            'IO.puts("LOCKSPIRE_DEPS_PATH=" <> Mix.Project.deps_paths()[:lockspire])',
        ),
        cwd=child_root,
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )

    if dependency_path.returncode != 0:
        raise PackageInputError(f"{role} dependency provenance probe failed")

    marker = b"LOCKSPIRE_DEPS_PATH="
    observed = next(
        (line[len(marker) :] for line in dependency_path.stdout.splitlines() if line.startswith(marker)),
        None,
    )

    if observed is None:
        raise PackageInputError(f"{role} dependency provenance probe returned no path")

    if before_manifest != (child_root / "mix.exs").read_bytes():
        raise PackageInputError(f"{role} manifest changed during locked dependency resolution")
    if before_lock != (child_root / "mix.lock").read_bytes():
        raise PackageInputError(f"{role} lock changed during locked dependency resolution")

    vendor_root = child_root / "vendor" / "lockspire"
    resolved = assert_below(vendor_root, child_root, f"{role} Lockspire dependency")
    if resolved != vendor_root.resolve(strict=True) or Path(observed.decode()).resolve() != resolved:
        raise PackageInputError(f"{role} Lockspire provenance does not match its vendor path")

    label = "provider" if role == "provider_host" else "client"
    print(f"{label} provenance verified")
    return resolved


def prepare_children(run_root: Path, cache_root: Path | None = None) -> None:
    probe_environment()
    package_root, _package_inventory = build_package(run_root)

    for role in ROLES:
        child_root = copy_child_template(role, run_root, package_root)
        verify_child(role, child_root, cache_root)


def update_locks() -> None:
    with tempfile.TemporaryDirectory(prefix="lockspire-clean-room-locks-") as temporary:
        run_root = Path(temporary)
        package_root, _package_inventory = build_package(run_root)

        for role in ROLES:
            template = TEMPLATE_ROOT / role
            child_root = run_root / role
            shutil.copytree(template, child_root, ignore=shutil.ignore_patterns("vendor", "_build", "deps"))
            vendor_root = child_root / "vendor" / "lockspire"
            vendor_root.parent.mkdir(mode=0o700, parents=True)
            shutil.copytree(package_root, vendor_root, symlinks=False)
            run(("mix", "deps.get"), cwd=child_root)
            shutil.copy2(child_root / "mix.lock", template / "mix.lock")


def package_source(package_tar: Path | None, hex_version: str | None, expected_sha256: str | None = None) -> PackageSource:
    if package_tar is not None and hex_version is not None:
        raise PackageInputError("choose either a local package tar or exact Hex version")
    if package_tar is not None:
        return PackageSource("tar", str(package_tar), expected_sha256)
    if hex_version is not None:
        return PackageSource("hex", exact_version(hex_version), expected_sha256)
    if expected_sha256 is not None:
        raise PackageInputError("--package-sha256 requires --package-tar or --hex-version")
    return PackageSource("checkout")


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--update-locks", action="store_true")
    parser.add_argument("--cache-root", type=Path)
    parser.add_argument("--package-tar", type=Path)
    parser.add_argument("--package-sha256")
    parser.add_argument("--hex-version")
    parser.add_argument("--inspect", action="store_true")
    return parser.parse_args(argv)


def main(argv: Sequence[str]) -> int:
    args = parse_args(argv)

    try:
        if args.package_tar and args.hex_version:
            raise PackageInputError("choose either --package-tar or --hex-version")

        if args.inspect:
            source = package_source(args.package_tar, args.hex_version, args.package_sha256)
            with tempfile.TemporaryDirectory(prefix="lockspire-clean-room-inspect-") as temporary:
                _root, _entries, identity = prepare_package(Path(temporary), source)
            print(json.dumps(identity.safe_receipt(), sort_keys=True, separators=(",", ":")))
            return 0

        if args.update_locks:
            update_locks()
            return 0

        if args.self_test:
            with tempfile.TemporaryDirectory(prefix="lockspire-clean-room-input-") as temporary:
                prepare_children(Path(temporary), args.cache_root)
            return 0

        raise PackageInputError("choose --self-test or --update-locks")
    except PackageInputError as error:
        print(f"clean-room package input failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
