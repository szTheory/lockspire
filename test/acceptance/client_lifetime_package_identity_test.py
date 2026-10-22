"""Fail-closed checks for reusable packaged lifetime proof inputs."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"))

from package_input import (  # noqa: E402
    PackageIdentity,
    PackageInputError,
    package_tree_digest,
    sha256,
    verify_candidate_host,
    verify_candidate_input,
)
from lifetime_receipts import validate_candidate_identity_agreement  # noqa: E402


class CandidateIdentityTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.archive = self.root / "lockspire-1.7.0.tar"
        self.archive.write_bytes(b"candidate archive one")
        self.package = self.root / "extracted"
        self.package.mkdir()
        (self.package / "mix.exs").write_text('version: "1.7.0"\n')
        (self.package / "lib.ex").write_text("candidate one\n")
        self.identity = PackageIdentity(
            "tar", "1.7.0", "a" * 64,
            archive_sha256=sha256(self.archive),
            tree_sha256=package_tree_digest(self.package),
            source_revision="b" * 40,
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_matching_candidate_passes_before_use(self) -> None:
        with patch("package_input.unpack_hex_tarball", side_effect=self._extract_matching_archive):
            verify_candidate_input(self.archive, self.package, self.identity)

    def test_same_filename_changed_archive_bytes_rejected(self) -> None:
        self.archive.write_bytes(b"candidate archive two")
        with self.assertRaises(PackageInputError):
            verify_candidate_input(self.archive, self.package, self.identity)

    def test_stale_extracted_tree_rejected(self) -> None:
        (self.package / "lib.ex").write_text("stale candidate\n")
        with patch("package_input.unpack_hex_tarball", side_effect=self._extract_matching_archive):
            with self.assertRaises(PackageInputError):
                verify_candidate_input(self.archive, self.package, self.identity)

    def test_stale_vendor_tree_rejected(self) -> None:
        child, vendor = self._host()
        (vendor / "lib.ex").write_text("stale vendor\n")
        with self.assertRaises(PackageInputError):
            verify_candidate_host(self.package, child, self.identity, vendor, vendor)

    def test_stale_compiled_candidate_rejected(self) -> None:
        child, vendor = self._host()
        build = child / "_build" / "dev" / "lib" / "lockspire"
        build.mkdir(parents=True)
        (build / "lockspire.app").write_bytes(b"stale compiled candidate")
        marker = child / ".lockspire-candidate.json"
        marker.write_text('{"tree_sha256":"' + self.identity.tree_sha256 + '"}')
        with self.assertRaises(PackageInputError):
            verify_candidate_host(self.package, child, self.identity, vendor, vendor)

    def test_exact_mix_build_path_compiled_candidate_is_observed(self) -> None:
        child, vendor = self._host()
        build = child / "_build" / "lib" / "lockspire"
        build.mkdir(parents=True)
        (build / "lockspire.app").write_bytes(b"stale direct build-path candidate")
        marker = child / ".lockspire-candidate.json"
        marker.write_text('{"tree_sha256":"' + self.identity.tree_sha256 + '"}')
        with self.assertRaises(PackageInputError):
            verify_candidate_host(self.package, child, self.identity, vendor, vendor)

    def test_resolved_dependency_mismatch_rejected(self) -> None:
        child, vendor = self._host()
        other = self.root / "other-dependency"
        other.mkdir()
        with self.assertRaises(PackageInputError):
            verify_candidate_host(self.package, child, self.identity, vendor, other)

    def test_replaced_candidate_is_checked_before_scenario_commands(self) -> None:
        child, vendor = self._host()
        stale_identity = PackageIdentity(
            "tar", "1.7.0", "a" * 64, archive_sha256="c" * 64,
            tree_sha256="d" * 64, source_revision="b" * 40,
        )
        run_calls: list[object] = []
        with patch("package_input.run", side_effect=lambda *args, **kwargs: run_calls.append(args)):
            with self.assertRaises(PackageInputError):
                verify_candidate_host(self.package, child, stale_identity, vendor, vendor)
        self.assertEqual(run_calls, [])

    def test_receipt_candidate_identity_must_agree_across_legs(self) -> None:
        candidate = {
            "kind": "tar", "version": "1.7.0", "archive_sha256": "a" * 64,
            "tree_sha256": self.identity.tree_sha256,
        }
        validate_candidate_identity_agreement([candidate, dict(candidate)])
        changed = dict(candidate, archive_sha256="c" * 64)
        with self.assertRaises(AssertionError):
            validate_candidate_identity_agreement([candidate, changed])

    def _host(self) -> tuple[Path, Path]:
        child = self.root / "provider"
        child.mkdir(exist_ok=True)
        vendor = child / "vendor" / "lockspire"
        vendor.parent.mkdir(parents=True, exist_ok=True)
        if not vendor.exists():
            import shutil

            shutil.copytree(self.package, vendor)
        return child, vendor

    def _extract_matching_archive(self, _archive: Path, destination: Path) -> None:
        import shutil

        shutil.copytree(self.package, destination)


if __name__ == "__main__":
    unittest.main()
