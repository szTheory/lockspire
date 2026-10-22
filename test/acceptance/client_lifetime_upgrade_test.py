"""Contract checks for packaged legacy HTTP upgrade receipts."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"))

from client_lifetime_upgrade import PackageInputError, validate_receipt  # noqa: E402


class LegacyUpgradeReceiptTest(unittest.TestCase):
    def test_legacy_prefix_requires_http_use_promotion_and_state_preservation(self) -> None:
        receipt = {"schema_version": 1, "scenarios": [self._scenario("public")]}
        with self.assertRaises(PackageInputError):
            validate_receipt(receipt, {"public"})

    @staticmethod
    def _scenario(prefix: str) -> dict[str, object]:
        def process(command: str, output: str = "") -> dict[str, object]:
            return {"pid": 123, "command": command, "exit_code": 0, "output": output}

        return {
            "prefix": prefix,
            "old_package": {
                "schema_version": 1, "source": "hex", "package": "lockspire",
                "version": "1.6.1", "sha256": "a" * 64, "archive_sha256": "a" * 64,
                "tree_sha256": "b" * 64, "source_revision": "c" * 40,
            },
            "candidate_package": {
                "kind": "tar", "version": "1.7.0", "archive_sha256": "d" * 64,
                "tree_sha256": "e" * 64, "source_revision": "f" * 40,
                "vendor_tree_sha256": "e" * 64, "compiled_candidate_sha256": "1" * 64,
                "resolved_dependency_verified": True,
            },
            "historical_migration_checksums_preserved": True,
            "historical_migration_checksum_count": 1,
            "historical_migration_checksums_sha256": "2" * 64,
            "old_processes": [process("lockspire.client.create") for _ in range(5)],
            "expansion_process": process("ecto.migrate"),
            "old_writer_processes_stopped_before_v1": True,
            "old_read_write_count": 5,
            "old_read_observation": process("run", "OLD_EXPANDED_ROWS_READ=5"),
            "v0_legacy_rows_observation": process("run", "V0_LEGACY_ROWS_VERIFIED=5;LEGACY_DATE_KINDS=4;STALE_AFTER_ROTATION_OBSERVED=1"),
            "old_rotation_observation": process("run", "STALE_DATE_SURVIVED_ROTATION=1"),
            "candidate_v1_write_process": process("lockspire.client.create"),
            "v1_state_retained_observation": process("run", "V1_STATE_RETAINED=1"),
            "v1_state_retained": True,
            "database_cleanup_process": process("ecto.drop"),
            "old_binary_after_v1_traffic": False,
            "rollback_boundary": "retain schema and v1 state; fix forward or use lifetime-aware rollback",
        }


if __name__ == "__main__":
    unittest.main()
