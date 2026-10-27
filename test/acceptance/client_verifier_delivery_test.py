"""Adversarial contracts for bounded verifier-delivery evidence."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys
import shutil
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
CLEAN_ROOM = ROOT / "scripts" / "acceptance" / "clean_room"
sys.path.insert(0, str(ROOT / "scripts" / "acceptance"))
sys.path.insert(0, str(CLEAN_ROOM))

from package_input import PackageInputError, PackageSource, package_tree_digest, prepare_package  # noqa: E402
import clean_room_verifier_upgrade  # noqa: E402
import verifier_delivery  # noqa: E402
import verifier_receipts  # noqa: E402


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

    def test_frozen_owner_overrides_group_checkout_request(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / "lockspire-1.6.1.tar"
            archive.write_bytes(b"owned archive")
            frozen = PackageSource(
                "frozen", str(archive), "a" * 64, "d" * 40, "b" * 64, str(root / "owner.json"),
            )

            def unpack(_archive: Path, package_root: Path) -> None:
                package_root.mkdir(parents=True)
                (package_root / "mix.exs").write_text('version: "1.6.1"\n', encoding="utf-8")
                (package_root / "lib.ex").write_text("candidate\n", encoding="utf-8")

            with patch("package_input.authenticated_frozen_source", return_value=frozen), \
                 patch("package_input.source_revision", return_value="e" * 40), \
                 patch("package_input.validate_local_tarball",
                       return_value=(archive, "1.6.1", "a" * 64)), \
                 patch("package_input.unpack_hex_tarball", side_effect=unpack), \
                 patch("package_input.verify_frozen_source_owner",
                       return_value=("d" * 40, "b" * 64)) as verify_owner, \
                 patch("package_input.verify_candidate_input"):
                _path, _entries, identity = prepare_package(root, PackageSource("checkout"))

            self.assertEqual(identity.kind, "frozen")
            self.assertEqual(identity.source_revision, "d" * 40)
            verify_owner.assert_called_once()

    def test_reviews_need_independent_identity_scope_and_dispositions(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            phase = Path(temporary)
            for name in ("178-REVIEW.md", "178-SECURITY.md", "178-INTEGRATION.md"):
                (phase / name).write_text("# Review\n\nStatus: clean\n", encoding="utf-8")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.validate_reviews(phase)


class ComposedMatrixContracts(unittest.TestCase):
    def _pair_roots(self, parent: Path) -> tuple[Path, Path, str, tuple[str, str, str]]:
        source = ROOT / "test/fixtures/verifier-matrix-26"
        runner = json.loads((source / "core/locked-builtin/receipt.json").read_text())["runner"]
        candidate = json.loads((source / "core/locked-builtin/receipt.json").read_text())["candidate"]
        owner = (candidate["source_revision"], candidate["archive_sha256"], candidate["tree_sha256"])
        roots = []
        for pair in ("locked", "floor"):
            root = parent / pair
            shutil.copytree(source, root)
            with redirect_stdout(StringIO()), redirect_stderr(StringIO()):
                result = clean_room_verifier_upgrade.main([
                    "--pair", pair, "--store", "all", "--group", "all",
                    "--validate-receipts", str(root),
                    "--expected-runner-revision", runner,
                    "--expected-candidate-source-revision", candidate["source_revision"],
                ])
            if result != 0:
                raise AssertionError("portable fixture pair index did not validate")
            roots.append(root)
        return roots[0], roots[1], runner, owner

    def test_two_pair_indexes_compose_to_exact_closed_validator_matrix(self) -> None:
        artifacts = ROOT / ".artifacts" / "phase178"
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            locked, floor, runner, candidate = self._pair_roots(Path(temporary))
            result = verifier_delivery.compose_pair_indexes(
                locked, floor, expected_runner=runner, expected_candidate=candidate,
            )
            self.assertEqual((result["executed_receipt_count"], result["passed_case_count"]), (26, 64))
            self.assertEqual(len(result["origins"]), 26)

    def test_composition_rejects_changed_raw_receipt_bytes(self) -> None:
        artifacts = ROOT / ".artifacts" / "phase178"
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            locked, floor, runner, candidate = self._pair_roots(Path(temporary))
            receipt = locked / "core/locked-builtin/receipt.json"
            receipt.write_bytes(receipt.read_bytes() + b" ")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.compose_pair_indexes(
                    locked, floor, expected_runner=runner, expected_candidate=candidate,
                )

    def test_composition_rejects_forged_green_index_and_mixed_candidate(self) -> None:
        artifacts = ROOT / ".artifacts" / "phase178"
        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            locked, floor, runner, candidate = self._pair_roots(Path(temporary))
            index_path = floor / "validated/index.json"
            index = json.loads(index_path.read_text())
            index["cells"].pop()
            index_path.write_text(json.dumps(index), encoding="utf-8")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.compose_pair_indexes(
                    locked, floor, expected_runner=runner, expected_candidate=candidate,
                )

        with tempfile.TemporaryDirectory(dir=artifacts) as temporary:
            locked, floor, runner, candidate = self._pair_roots(Path(temporary))
            index_path = floor / "validated/index.json"
            index = json.loads(index_path.read_text())
            index["candidate_source_archive_tree"][0] = "f" * 40
            index_path.write_text(json.dumps(index), encoding="utf-8")
            with self.assertRaises(verifier_delivery.DeliveryError):
                verifier_delivery.compose_pair_indexes(
                    locked, floor, expected_runner=runner, expected_candidate=candidate,
                )


if __name__ == "__main__":
    unittest.main()
