#!/usr/bin/env python3
"""Narrow supervision for the Phase 133 provider/client acceptance lab."""

from __future__ import annotations

import argparse
import http.server
import os
from pathlib import Path
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Sequence


READINESS_SECONDS = 12.0
ROLES = ("provider", "client")


@dataclass
class Child:
    role: str
    process: subprocess.Popen[bytes]
    log_path: Path
    log_handle: object


def allocate_loopback_port(excluding: set[int]) -> int:
    """Reserve a unique loopback port long enough to choose an origin."""
    while True:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
            listener.bind(("127.0.0.1", 0))
            port = int(listener.getsockname()[1])

        if port not in excluding:
            return port


def safe_log_location(path: Path, run_root: Path) -> str:
    """Diagnostics expose a role-local filename, never command output."""
    return str(path.relative_to(run_root))


class ProviderClientSupervisor:
    """Supervise only the provider and client processes used by this acceptance lab."""

    def __init__(self, run_root: Path, readiness_seconds: float = READINESS_SECONDS):
        self.run_root = run_root.resolve()
        self.readiness_seconds = readiness_seconds
        self.children: list[Child] = []
        self.ports: dict[str, int] = {}

    def prepare(self) -> None:
        if not self.run_root.is_dir():
            raise RuntimeError("clean-room run root is unavailable")

        os.chmod(self.run_root, 0o700)
        ports: set[int] = set()

        for role in ROLES:
            port = allocate_loopback_port(ports)
            ports.add(port)
            self.ports[role] = port
            role_root = self.run_root / role
            role_root.mkdir(mode=0o700)
            (role_root / "index.html").write_text(f"{role} probe\n", encoding="utf-8")

    def origin(self, role: str) -> str:
        return f"http://127.0.0.1:{self.ports[role]}"

    def start_probe(self, role: str, fail_startup: bool = False) -> None:
        if role not in ROLES:
            raise ValueError(f"unknown clean-room role: {role}")

        role_root = self.run_root / role
        log_path = role_root / "process.log"
        log_handle = log_path.open("wb")

        if fail_startup:
            command: Sequence[str] = (sys.executable, "-c", "raise SystemExit(1)")
        else:
            command = (
                sys.executable,
                "-m",
                "http.server",
                str(self.ports[role]),
                "--bind",
                "127.0.0.1",
                "--directory",
                str(role_root),
            )

        child = subprocess.Popen(
            command,
            cwd=role_root,
            stdin=subprocess.DEVNULL,
            stdout=log_handle,
            stderr=subprocess.STDOUT,
            close_fds=True,
        )
        self.children.append(Child(role, child, log_path, log_handle))

    def wait_until_ready(self, role: str) -> None:
        child = next(child for child in self.children if child.role == role)
        deadline = time.monotonic() + self.readiness_seconds

        while time.monotonic() < deadline:
            status = child.process.poll()
            if status is not None:
                raise RuntimeError(
                    f"{role} readiness failed (exit status: {status}; "
                    f"log: {safe_log_location(child.log_path, self.run_root)})"
                )

            try:
                with urllib.request.urlopen(self.origin(role), timeout=0.4) as response:
                    if response.status == 200:
                        print(f"{role} ready")
                        return
            except (OSError, urllib.error.URLError):
                pass

            time.sleep(0.05)

        raise RuntimeError(
            f"{role} readiness timed out (exit status: running; "
            f"log: {safe_log_location(child.log_path, self.run_root)})"
        )

    def stop_all(self) -> None:
        for child in reversed(self.children):
            if child.process.poll() is None:
                child.process.terminate()

        for child in reversed(self.children):
            try:
                child.process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                child.process.kill()
                child.process.wait(timeout=3)
            finally:
                child.log_handle.close()


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("--run-root", required=True, type=Path)
    parser.add_argument("--probe", action="store_true")
    parser.add_argument("--fail-provider-startup", action="store_true")
    return parser.parse_args(argv)


def main(argv: Sequence[str]) -> int:
    args = parse_args(argv)
    if not args.probe:
        print("clean-room journey steps have not been installed yet", file=sys.stderr)
        return 2

    supervisor = ProviderClientSupervisor(args.run_root)

    try:
        supervisor.prepare()
        supervisor.start_probe("provider", fail_startup=args.fail_provider_startup)
        supervisor.start_probe("client")
        supervisor.wait_until_ready("provider")
        supervisor.wait_until_ready("client")
        return 0
    except RuntimeError as error:
        print(str(error), file=sys.stderr)
        return 1
    finally:
        supervisor.stop_all()


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
