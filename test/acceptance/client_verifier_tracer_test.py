"""Fast contracts for installed verifier provenance and receipt acceptance."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

CLEAN_ROOM = Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"
sys.path.insert(0, str(CLEAN_ROOM))

from package_input import PackageIdentity, PackageInputError, PackageSource, prepare_package  # noqa: E402
from build_provider import PROOF_PAIR_MARKER, configure_proof_pair  # noqa: E402


class PackageAttributionTest(unittest.TestCase):
    def test_external_archive_does_not_claim_runner_revision_as_source(self) -> None:
        identity = PackageIdentity("tar", "1.6.1", "a" * 64, "a" * 64, "b" * 64, None, "runner-sha")
        self.assertIsNone(identity.source_revision)
        self.assertEqual(getattr(identity, "runner_revision", None), "runner-sha")
        self.assertIsNone(getattr(identity, "source_proof", None))

    def test_source_label_without_independent_binding_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / "lockspire-1.6.1.tar"
            archive.write_bytes(b"external bytes")
            package = root / "package" / "lockspire"
            package.mkdir(parents=True)
            (package / "mix.exs").write_text('version: "1.6.1"\n')
            (package / "lib.ex").write_text("package tree\n")
            with patch("package_input.validate_local_tarball", return_value=(archive, "1.6.1", "a" * 64)), \
                 patch("package_input.verify_candidate_input"):
                _path, _entries, identity = prepare_package(root, PackageSource("tar", str(archive)))
            self.assertIsNone(identity.source_revision)

    def test_legacy_safe_receipt_shape_is_preserved(self) -> None:
        identity = PackageIdentity("tar", "1.6.1", "a" * 64, "a" * 64, "b" * 64, None)
        self.assertEqual(set(identity.safe_receipt()), {
            "schema_version", "source", "package", "version", "sha256",
            "archive_sha256", "tree_sha256", "source_revision",
        })
        self.assertEqual(identity.safe_receipt()["source_revision"], "unavailable")


class PairSelectionTest(unittest.TestCase):
    def test_floor_pair_is_generic_and_does_not_request_admin_overlays(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            child = Path(temporary)
            manifest = child / "mix.exs"
            manifest.write_text('{:phoenix, "== 1.8.13"}\n{:phoenix_live_view, "== 1.2.10"}\n')
            lock = child / "mix.lock"
            lock.write_bytes(b"lock")
            configure_proof_pair(child, "floor", admin_proof=False, reused=False)
            self.assertIn('"== 1.8.5"', manifest.read_text())
            self.assertIn('"== 1.1.28"', manifest.read_text())
            self.assertTrue((child / PROOF_PAIR_MARKER).is_file())
            self.assertFalse((child / "lib" / "clean_room_provider_web" / "admin_proof.ex").exists())


if __name__ == "__main__":
    unittest.main()
