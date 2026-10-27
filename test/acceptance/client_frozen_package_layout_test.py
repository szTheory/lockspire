"""Frozen inputs preserve the adjacent archive contract of installed callers.

Git/source owner and archive/tree/digest validators run unchanged. Only the
external Hex unpack boundary uses a deterministic test archive reader.
"""
from __future__ import annotations

from contextlib import ExitStack
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts/acceptance/clean_room"))
import package_input as package  # noqa: E402


class FrozenPackageLayoutContracts(unittest.TestCase):
    def setUp(self):
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        self.repo = Path(self.stack.enter_context(tempfile.TemporaryDirectory(
            prefix="lockspire178-core-source-fixture-", dir="/private/tmp"))).resolve()
        self.stack.enter_context(patch.object(tempfile, "tempdir", str(self.repo)))
        self.payload = {"mix.exs": b'version: "1.6.1"\n', "lib/lockspire.ex": b"defmodule Lockspire do end\n"}
        for name, content in self.payload.items():
            path = self.repo / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
        for arguments in (("init", "-q"), ("config", "user.name", "Fixture"),
                          ("config", "user.email", "fixture@example.invalid"),
                          ("add", "mix.exs", "lib/lockspire.ex"), ("commit", "-qm", "fixture source")):
            self.git(*arguments)
        self.revision = self.git("rev-parse", "HEAD")
        artifact = self.repo / ".artifacts/phase178/candidate"
        artifact.mkdir(parents=True)
        self.archive = artifact / "lockspire-1.6.1.tar"
        with tarfile.open(self.archive, "w") as output:
            for name, content in self.payload.items():
                entry = tarfile.TarInfo(name)
                entry.size = len(content)
                output.addfile(entry, io.BytesIO(content))
        self.extracted = artifact / "lockspire"
        self.unpack(self.archive, self.extracted)
        self.archive_digest = package.sha256(self.archive)
        tree_digest = package.package_tree_digest(self.extracted)
        owner = {"schema": "lockspire-frozen-candidate-owner-v1", "source_revision": self.revision,
                 "source_tree": self.git("rev-parse", "HEAD^{tree}"),
                 "archive_path": self.archive.relative_to(self.repo).as_posix(),
                 "archive_sha256": self.archive_digest,
                 "extracted_tree_path": self.extracted.relative_to(self.repo).as_posix(),
                 "tree_sha256": tree_digest,
                 "package_files": [{"path": name, "sha256": hashlib.sha256(content).hexdigest()}
                                   for name, content in sorted(self.payload.items())],
                 "source_build": {"git_archive_exit_code": 0, "package_build_exit_code": 0,
                                  "rebuilt_tree_sha256": tree_digest, "package_stdout_bytes": 0,
                                  "package_stderr_bytes": 0, "package_stdout_sha256": hashlib.sha256(b"").hexdigest(),
                                  "package_stderr_sha256": hashlib.sha256(b"").hexdigest(),
                                  "rebuilt_archive_sha256": self.archive_digest}}
        owner["owner_sha256"] = hashlib.sha256(json.dumps(owner, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        manifest = artifact / "178-FROZEN-INPUTS.json"
        manifest.write_text(json.dumps({"runner_revision": self.revision, "candidate_owner": owner}))
        authenticate = package.authenticated_frozen_source
        verify_owner = package.verify_frozen_source_owner
        self.stack.enter_context(patch.object(package, "PROJECT_ROOT", self.repo))
        self.stack.enter_context(patch.object(package, "authenticated_frozen_source", side_effect=lambda: authenticate(self.repo)))
        self.stack.enter_context(patch.object(package, "verify_frozen_source_owner", side_effect=lambda *args: verify_owner(*args, project_root=self.repo)))
        self.stack.enter_context(patch.object(package, "unpack_hex_tarball", side_effect=self.unpack))
        self.stack.enter_context(patch.dict(os.environ, {
            "LOCKSPIRE_FROZEN_INPUTS": str(manifest),
            "LOCKSPIRE_EXPECTED_FROZEN_RUNNER_REVISION": self.revision,
            "LOCKSPIRE_EXPECTED_CANDIDATE_SOURCE_REVISION": self.revision,
            "LOCKSPIRE_EXPECTED_CANDIDATE_ARCHIVE_SHA256": self.archive_digest,
            "LOCKSPIRE_EXPECTED_CANDIDATE_TREE_SHA256": tree_digest,
            "LOCKSPIRE_EXPECTED_FROZEN_MANIFEST_SHA256": package.sha256(manifest),
        }))
        self.run_root = self.repo / "consumer"

    def git(self, *args):
        result = subprocess.run(("git", *args), cwd=self.repo, capture_output=True, timeout=10)
        if result.returncode:
            raise RuntimeError("fixture_git_failed")
        return result.stdout.decode("ascii").strip()

    def unpack(self, archive, destination):
        destination.mkdir(parents=True)
        with tarfile.open(archive, "r") as source:
            for name in self.payload:
                content = source.extractfile(name).read()
                path = destination / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content)

    def select_and_verify_as_installed_caller(self):
        root, entries, identity = package.prepare_package(self.run_root, package.PackageSource("checkout"))
        adjacent = root.parent / f"lockspire-{identity.version}.tar"
        self.assertTrue(adjacent.is_file(), "frozen package lacks required adjacent archive")
        self.assertTrue(package.sha256(adjacent) == self.archive_digest, "private archive digest differs")
        package.verify_candidate_input(adjacent, root, identity)
        self.assertTrue(identity.kind == "frozen" and identity.source_revision == self.revision,
                        "frozen source owner changed")
        self.assertTrue(package.sha256(self.archive) == self.archive_digest, "retained archive changed")
        return adjacent

    def test_frozen_selection_materializes_verified_adjacent_archive_for_callers(self):
        adjacent = self.select_and_verify_as_installed_caller()
        self.assertTrue(adjacent.stat().st_mode & 0o077 == 0, "private archive permissions differ")

    def test_cached_frozen_selection_reuses_exact_copy_and_restores_missing_copy(self):
        adjacent = self.select_and_verify_as_installed_caller()
        before = adjacent.stat()
        self.select_and_verify_as_installed_caller()
        after = adjacent.stat()
        self.assertTrue((before.st_ino, before.st_mtime_ns) == (after.st_ino, after.st_mtime_ns),
                        "existing exact archive was replaced")
        adjacent.unlink()
        self.select_and_verify_as_installed_caller()

    def test_conflicting_or_symlink_private_paths_fail_without_overwrite(self):
        for variant in ("file", "directory", "symlink", "parent-symlink"):
            with self.subTest(variant=variant):
                self.run_root = self.repo / ("consumer-" + variant)
                parent = self.run_root / "package"
                parent.mkdir(parents=True)
                adjacent = parent / "lockspire-1.6.1.tar"
                existing = self.repo / ("existing-" + variant)
                existing.write_bytes(b"preserved unrelated fixture bytes")
                if variant == "file":
                    adjacent.write_bytes(existing.read_bytes())
                elif variant == "directory":
                    adjacent.mkdir()
                elif variant == "symlink":
                    adjacent.symlink_to(existing)
                else:
                    parent.rmdir()
                    external = self.repo / "external-directory"
                    external.mkdir()
                    parent.symlink_to(external, target_is_directory=True)
                with self.assertRaises(package.PackageInputError):
                    package.prepare_package(self.run_root, package.PackageSource("checkout"))
                self.assertTrue(existing.read_bytes() == b"preserved unrelated fixture bytes", "existing file changed")
                self.assertTrue(package.sha256(self.archive) == self.archive_digest, "retained archive changed")
                self.assertTrue(not (parent / "lockspire").exists(), "unsafe destination was used")
                if variant == "file":
                    self.assertTrue(adjacent.read_bytes() == existing.read_bytes(), "conflicting archive was overwritten")

    def test_tampered_cached_archive_or_tree_is_rejected_without_replacement(self):
        adjacent = self.select_and_verify_as_installed_caller()
        adjacent.write_bytes(b"tampered private archive")
        with self.assertRaises(package.PackageInputError):
            package.prepare_package(self.run_root, package.PackageSource("checkout"))
        self.assertTrue(adjacent.read_bytes() == b"tampered private archive", "stale file was overwritten")
        adjacent.unlink()
        self.select_and_verify_as_installed_caller()
        (self.run_root / "package/lockspire/lib/lockspire.ex").write_bytes(b"tampered private tree")
        with self.assertRaises(package.PackageInputError):
            package.prepare_package(self.run_root, package.PackageSource("checkout"))
        self.assertTrue(package.sha256(adjacent) == self.archive_digest, "existing archive changed")
        self.assertTrue(package.sha256(self.archive) == self.archive_digest, "retained archive changed")

    def test_retained_archive_tamper_fails_before_private_copy(self):
        self.archive.write_bytes(b"tampered retained fixture archive")
        with self.assertRaises(package.PackageInputError):
            package.prepare_package(self.run_root, package.PackageSource("checkout"))
        self.assertTrue(not self.run_root.exists(), "private output preceded archive authentication")

    def test_real_core_entrypoint_reaches_original_provider_signature_before_body(self):
        sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts/acceptance"))
        import clean_room_verifier_upgrade as runner
        import verifier_core as core
        import inspect
        signature = inspect.signature(core.prepare_provider)
        reached = []
        class ProviderBoundary(BaseException):
            pass
        def stop_before_provider(*args, **kwargs):
            signature.bind(*args, **kwargs)
            reached.append(kwargs["proof_pair"])
            raise ProviderBoundary()
        with patch.object(core, "allocate_port", return_value=4100), \
             patch.object(core, "prepare_provider", side_effect=stop_before_provider):
            for pair in ("locked", "floor"):
                with self.assertRaises(ProviderBoundary):
                    runner.main(["--group", "core", "--pair", pair, "--store", "builtin",
                                 "--receipt-dir", str(self.repo / "nonaccepting")])
        self.assertTrue(reached == ["locked", "floor"], "core did not reach pre-provider boundary")


if __name__ == "__main__":
    unittest.main()
