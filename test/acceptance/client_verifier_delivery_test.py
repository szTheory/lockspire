"""Adversarial contracts for bounded verifier-delivery evidence."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

CLEAN_ROOM = Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"
sys.path.insert(0, str(CLEAN_ROOM))

from package_input import PackageInputError, PackageSource, package_tree_digest, prepare_package  # noqa: E402


class FrozenSourceOwnerContracts(unittest.TestCase):
    def test_self_reported_source_hash_does_not_authenticate_external_archive(self) -> None:
        """A public digest over caller claims cannot prove source-to-archive ownership."""
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / "lockspire-1.6.1.tar"
            archive.write_bytes(b"archive bytes whose source is not established")
            package = root / "package" / "lockspire"
            package.mkdir(parents=True)
            (package / "mix.exs").write_text('version: "1.6.1"\n', encoding="utf-8")
            (package / "lib.ex").write_text("unowned candidate bytes\n", encoding="utf-8")
            revision = "d" * 40
            archive_sha = "a" * 64
            tree_sha = package_tree_digest(package)
            claim = json.dumps(
                {"archive_sha256": archive_sha, "source_revision": revision, "tree_sha256": tree_sha},
                sort_keys=True, separators=(",", ":"),
            ).encode()
            self_reported_proof = hashlib.sha256(claim).hexdigest()
            with patch("package_input.validate_local_tarball",
                       return_value=(archive, "1.6.1", archive_sha)), \
                 patch("package_input.verify_candidate_input"):
                with self.assertRaises(PackageInputError):
                    prepare_package(
                        root,
                        PackageSource(
                            "tar", str(archive), source_revision=revision,
                            source_proof=self_reported_proof,
                        ),
                    )


if __name__ == "__main__":
    unittest.main()
