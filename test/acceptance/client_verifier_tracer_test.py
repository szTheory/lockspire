"""Fast contracts for installed verifier provenance and receipt acceptance."""

from __future__ import annotations

import sys
import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

CLEAN_ROOM = Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"
sys.path.insert(0, str(CLEAN_ROOM))

from package_input import PackageIdentity, PackageInputError, PackageSource, prepare_package  # noqa: E402
from build_provider import PROOF_PAIR_MARKER, configure_proof_pair  # noqa: E402
from verifier_receipts import ReceiptError, load_receipt, validate_receipt  # noqa: E402


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


class InstalledReceiptTest(unittest.TestCase):
    def test_real_tracer_receipt_passes_with_installed_outcomes(self) -> None:
        self.assertEqual(validate_receipt(self.receipt(), expected_pair="locked", expected_store="builtin")["executed_count"], 1)

    def test_locked_receipt_rejects_framework_versions_from_floor_pair(self) -> None:
        receipt = self.receipt()
        receipt["host"]["phoenix"] = "1.8.5"
        with self.assertRaises(ReceiptError):
            validate_receipt(receipt, expected_pair="locked", expected_store="builtin")

    def test_tracer_rejects_missing_token_and_assertion_outcomes(self) -> None:
        receipt = self.receipt()
        receipt["observations"]["VPROOF-02-INSTALLED-TOKEN"]["token_issued"] = False
        with self.assertRaises(ReceiptError):
            validate_receipt(receipt)

    def test_tracer_rejects_unsafe_observation_fields(self) -> None:
        receipt = self.receipt()
        receipt["observations"]["VPROOF-02-INSTALLED-TOKEN"]["client_secret"] = "sentinel"
        with self.assertRaises(ReceiptError):
            validate_receipt(receipt)

    def test_source_binding_rejects_tampered_tree_identity(self) -> None:
        receipt = self.receipt()
        receipt["candidate"]["tree_sha256"] = "f" * 64
        with self.assertRaises(ReceiptError):
            validate_receipt(receipt)

    def test_duplicate_json_keys_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "duplicate.json"
            path.write_text('{"schema":"first","schema":"second"}', encoding="utf-8")
            with self.assertRaises(ReceiptError):
                load_receipt(path)

    @staticmethod
    def receipt() -> dict[str, object]:
        archive, tree, source = "a" * 64, "b" * 64, "c" * 40
        binding = json.dumps(
            {"archive_sha256": archive, "source_revision": source, "tree_sha256": tree},
            sort_keys=True, separators=(",", ":"),
        ).encode()
        return {
            "schema": "lockspire-installed-verifier-v1", "scope": "tracer",
            "run_id": "d" * 32, "runner": source, "pair": "locked", "store": "builtin",
            "candidate": {
                "kind": "checkout", "version": "1.6.1", "archive_sha256": archive,
                "tree_sha256": tree, "source_revision": source, "runner_revision": source,
                "source_proof": hashlib.sha256(binding).hexdigest(),
            },
            "host": {
                "vendor_tree_sha256": tree, "compiled_candidate_sha256": "e" * 64,
                "resolved_dependency_verified": True, "lock_sha256": "f" * 64,
                "phoenix": "1.8.13", "live_view": "1.2.10",
            },
            "runtime": {"elixir": "1.19.5", "otp": "28", "postgresql": "14.17"},
            "stable_case_ids": ["VPROOF-02-INSTALLED-TOKEN"],
            "observations": {"VPROOF-02-INSTALLED-TOKEN": {
                "outcome": "pass", "executed": True, "http_status": 200,
                "token_issued": True, "dedicated_verifier_persisted": True,
                "fresh_signed_assertion": True,
            }},
            "executed_count": 1, "partial": True,
        }


if __name__ == "__main__":
    unittest.main()
