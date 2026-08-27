#!/usr/bin/env python3
"""Build and audit the local package input for the clean-room acceptance lab."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from typing import Iterable, Sequence


PROJECT_ROOT = Path(__file__).resolve().parents[3]
TEMPLATE_ROOT = PROJECT_ROOT / "test" / "clean_room"
ROLES = ("provider_host", "confidential_client")


class PackageInputError(RuntimeError):
    pass


def require_command(command: str) -> None:
    if shutil.which(command) is None:
        raise PackageInputError(f"required command is unavailable: {command}")


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
    """Build a local Hex-style unpacked tree before any child app is started."""
    require_command("mix")
    package_root = run_root / "package" / "lockspire"
    package_root.parent.mkdir(mode=0o700, parents=True, exist_ok=True)

    run(
        ("mix", "hex.build", "--unpack", "--output", str(package_root)),
        cwd=PROJECT_ROOT,
    )

    return package_root.resolve(strict=True), inventory(package_root)


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

        role_deps = cache_realpath / role / "deps"
        role_deps.mkdir(mode=0o700, parents=True, exist_ok=True)
        environment["MIX_DEPS_PATH"] = str(role_deps)

    return environment


def verify_child(role: str, child_root: Path, cache_root: Path | None) -> None:
    before_manifest = (child_root / "mix.exs").read_bytes()
    before_lock = (child_root / "mix.lock").read_bytes()
    environment = locked_environment(child_root, role, cache_root)

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


def prepare_children(run_root: Path, cache_root: Path | None = None) -> None:
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


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--update-locks", action="store_true")
    parser.add_argument("--cache-root", type=Path)
    return parser.parse_args(argv)


def main(argv: Sequence[str]) -> int:
    args = parse_args(argv)

    try:
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
