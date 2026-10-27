"""Finite Phase 178 input selection over a selected Git commit's tracked tree.

Directory rules deliberately cover the complete shipped/build/test and executable
documentation dependency surfaces. Generated evidence is excluded; the planning
inputs are enumerated separately by the delivery contract. No history or current
filesystem glob is used as selection authority.
"""
from __future__ import annotations

from pathlib import Path
from functools import lru_cache
import hashlib
import subprocess

RULE = "lockspire-phase178-tracked-input-closure-v1"
PREFIXES = ("lib/", "config/", "priv/", "test/", "scripts/", ".github/",
            "compatibility/", "docs/", "examples/", "tools/", "brandbook/")


def selected_path(path: str, planning_inputs: tuple[str, ...]) -> bool:
    return "/" not in path or path.startswith(PREFIXES) or path in planning_inputs


def tracked_inputs(root: Path, revision: str, planning_inputs: tuple[str, ...]) -> tuple[str, ...]:
    result = subprocess.run(("git", "ls-tree", "-r", "-z", "--name-only", revision), cwd=root,
                            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.DEVNULL, timeout=20, check=False)
    if result.returncode:
        raise ValueError("selected tracked input tree is unavailable")
    paths = tuple(part.decode("utf-8", errors="strict") for part in result.stdout.split(b"\0") if part)
    selected = tuple(sorted(path for path in paths if selected_path(path, planning_inputs)))
    if not selected:
        raise ValueError("selected tracked input tree is empty")
    return selected


def assert_worktree_selection(root: Path, expected: tuple[str, ...], planning_inputs: tuple[str, ...]) -> None:
    # Includes staged additions/deletions. Untracked selected files are not allowed
    # to silently enter a build or test run either.
    result = subprocess.run(("git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"),
                            cwd=root, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.DEVNULL, timeout=20, check=False)
    if result.returncode:
        raise ValueError("selected working input tree is unavailable")
    current = {p.decode("utf-8", errors="strict") for p in result.stdout.split(b"\0") if p}
    selected = {p for p in current if selected_path(p, planning_inputs)}
    if selected != set(expected):
        raise ValueError("selected working input path set differs from reviewed commit")


@lru_cache(maxsize=16)
def committed_hashes(root: Path, revision: str, planning_inputs: tuple[str, ...]) -> dict[str, str]:
    result = subprocess.run(("git", "ls-tree", "-r", "-z", revision), cwd=root,
                            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                            stderr=subprocess.DEVNULL, timeout=20, check=False)
    if result.returncode:
        raise ValueError("selected committed tree is unavailable")
    objects = {}
    for row in result.stdout.split(b"\0"):
        if not row:
            continue
        metadata, raw_path = row.split(b"\t", 1)
        mode, kind, oid = metadata.split()
        path = raw_path.decode("utf-8", errors="strict")
        if selected_path(path, planning_inputs):
            if mode not in {b"100644", b"100755"} or kind != b"blob":
                raise ValueError("selected committed input is not a regular file")
            objects[path] = oid
    result = subprocess.run(("git", "cat-file", "--batch"), cwd=root,
                            input=b"\n".join(objects.values()) + b"\n", stdout=subprocess.PIPE,
                            stderr=subprocess.DEVNULL, timeout=30, check=False)
    if result.returncode:
        raise ValueError("selected committed blobs are unavailable")
    output, cursor, hashes = result.stdout, 0, {}
    for path, expected_oid in objects.items():
        newline = output.index(b"\n", cursor)
        oid, kind, size = output[cursor:newline].split()
        length = int(size)
        start = newline + 1
        end = start + length
        if oid != expected_oid or kind != b"blob" or output[end:end + 1] != b"\n":
            raise ValueError("selected committed blob framing is invalid")
        hashes[path] = hashlib.sha256(output[start:end]).hexdigest()
        cursor = end + 1
    if cursor != len(output):
        raise ValueError("selected committed blob response is incomplete")
    return hashes
