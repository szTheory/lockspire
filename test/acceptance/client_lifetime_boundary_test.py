"""Narrow audit controls for the named packaged lifetime adapter."""

from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

CLEAN_ROOM = Path(__file__).resolve().parents[2] / "scripts" / "acceptance" / "clean_room"
sys.path.insert(0, str(CLEAN_ROOM))

from package_input import PackageIdentity, PackageInputError  # noqa: E402
from build_provider import (  # noqa: E402
    PROOF_PAIR_LOCKS, PROOF_PAIR_MARKER, PROOF_PAIR_VERSIONS,
    audit_boundary, prepare_provider, proof_pair_lock_hash,
)


class LifetimeBoundaryTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.child = self.root / "provider_host"
        self.package = self.root / "package"
        self.overlay = self.root / "overlay"
        (self.child / "vendor" / "lockspire").mkdir(parents=True)
        self.package.mkdir()
        self.overlay.mkdir()
        (self.child / "lib" / "clean_room_provider").mkdir(parents=True)
        (self.child / "lib" / "clean_room_provider_web").mkdir(parents=True)
        for relative in (
            "lib/clean_room_provider_web.ex",
            "lib/clean_room_provider/repo.ex",
            "lib/clean_room_provider/application.ex",
            "lib/clean_room_provider_web/endpoint.ex",
            "lib/clean_room_provider_web/router.ex",
        ):
            path = self.child / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("defmodule HostRuntime do\nend\n")
        self.adapter = self.overlay / "clean_room_provider" / "lifetime_client_store.ex"
        self.adapter.parent.mkdir(parents=True)
        self.adapter.write_text(
            """defmodule CleanRoomProvider.LifetimeClientStore do
  @behaviour Lockspire.Storage.ClientStore
  @behaviour Lockspire.Storage.TransactionStore
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Domain.Client
end
"""
        )
        child_adapter = self.child / "lib" / "clean_room_provider" / self.adapter.name
        child_adapter.write_text(self.adapter.read_text())
        (self.package / "mix.exs").write_text("candidate package\n")
        shutil.copytree(self.package, self.child / "vendor" / "lockspire", dirs_exist_ok=True)
        phoenix, live_view = PROOF_PAIR_VERSIONS["locked"]
        (self.child / "mix.exs").write_text(
            f'{{:phoenix, "== {phoenix}"}}\n{{:phoenix_live_view, "== {live_view}"}}\n',
            encoding="utf-8",
        )
        shutil.copy2(PROOF_PAIR_LOCKS["locked"], self.child / "mix.lock")
        (self.child / PROOF_PAIR_MARKER).write_text(
            f"pair=locked\nlock_sha256={proof_pair_lock_hash('locked')}\n", encoding="utf-8"
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_named_adapter_may_use_only_the_documented_public_storage_seams(self) -> None:
        with patch("build_provider.OVERLAY_ROOT", self.overlay):
            try:
                audit_boundary(self.child, self.package)
            except PackageInputError as error:
                self.fail(f"named public adapter was rejected: {type(error).__name__}")

    def test_named_adapter_may_declare_optional_used_jti_seam_as_a_pair(self) -> None:
        self._append_adapter_refs(
            "Lockspire.Storage.UsedJtiStore",
            "Lockspire.Domain.UsedJti",
        )
        self.assert_public_adapter_allowed()

    def test_optional_used_jti_seam_requires_its_domain_pair(self) -> None:
        self._append_adapter_refs("Lockspire.Storage.UsedJtiStore")

        with patch("build_provider.OVERLAY_ROOT", self.overlay):
            with self.assertRaises(PackageInputError):
                audit_boundary(self.child, self.package)

    def test_protocol_internals_remain_forbidden_in_named_adapter(self) -> None:
        self._reject("Lockspire.Protocol.Internal.ClientStore")

    def test_nested_storage_implementations_remain_forbidden_in_named_adapter(self) -> None:
        self._reject("Lockspire.Storage.Ecto.Repository.ClientStore")

    def test_checkout_test_support_remains_forbidden_in_named_adapter(self) -> None:
        self._reject("test/support/client_lifetime_race_helpers.ex")

    def test_documented_public_seams_are_not_exempt_in_runtime_sources(self) -> None:
        self._reject_runtime_reference("Lockspire.Storage.ClientStore")

    def test_nested_public_seam_names_are_not_exempt_in_runtime_sources(self) -> None:
        self._reject_runtime_reference("Lockspire.Storage.Ecto.Repository.ClientStore")

    def test_reused_provider_is_audited_before_mix_inspects_it(self) -> None:
        identity = PackageIdentity(
            "tar", "1.7.0", "a" * 64, "b" * 64, "c" * 64, "d" * 40
        )
        candidate_marker = self.child / ".lockspire-candidate.json"
        candidate_marker.write_text("candidate bound\n")
        events: list[str] = []

        def verify_child(*_args: object, **_kwargs: object) -> str:
            events.append("mix_probe")
            return str(self.child / "vendor" / "lockspire")

        def observe_audit(child: Path, package: Path) -> None:
            events.append("audit")
            audit_boundary(child, package)

        with (
            patch("build_provider.probe_environment"),
            patch("build_provider.verify_candidate_host"),
            patch("build_provider.verify_child", side_effect=verify_child),
            patch("build_provider.locked_environment", return_value={}),
            patch("build_provider.audit_boundary", side_effect=observe_audit),
            patch("build_provider.OVERLAY_ROOT", self.overlay),
            patch.dict("os.environ", {"LOCKSPIRE_KEY_ENCRYPTION_KEY": "test-key"}),
        ):
            self.assertEqual(
                prepare_provider(
                    self.root,
                    "postgres://provider",
                    package_root=self.package,
                    candidate_identity=identity,
                ),
                self.child,
            )

        self.assertEqual(events, ["audit", "mix_probe"])

    def test_reused_provider_with_forbidden_overlay_is_rejected_before_mix(self) -> None:
        identity = PackageIdentity(
            "tar", "1.7.0", "a" * 64, "b" * 64, "c" * 64, "d" * 40
        )
        candidate_marker = self.child / ".lockspire-candidate.json"
        candidate_marker.write_text("candidate bound\n")
        router = self.child / "lib" / "clean_room_provider_web" / "router.ex"
        router.write_text(
            "defmodule HostRuntime do\n"
            "  alias Lockspire.Protocol.Internal.ClientStore\n"
            "end\n"
        )

        with (
            patch("build_provider.probe_environment"),
            patch("build_provider.verify_candidate_host"),
            patch("build_provider.verify_child") as mix_probe,
            patch("build_provider.OVERLAY_ROOT", self.overlay),
            patch.dict("os.environ", {"LOCKSPIRE_KEY_ENCRYPTION_KEY": "test-key"}),
        ):
            with self.assertRaises(PackageInputError):
                prepare_provider(
                    self.root,
                    "postgres://provider",
                    package_root=self.package,
                    candidate_identity=identity,
                )

        mix_probe.assert_not_called()

    def _reject(self, forbidden: str) -> None:
        source = self.adapter.read_text().replace("end\n", f"  # {forbidden}\nend\n")
        self.adapter.write_text(source)
        (self.child / "lib" / "clean_room_provider" / self.adapter.name).write_text(source)
        with patch("build_provider.OVERLAY_ROOT", self.overlay):
            with self.assertRaises(PackageInputError):
                audit_boundary(self.child, self.package)

    def _reject_runtime_reference(self, reference: str) -> None:
        router = self.child / "lib" / "clean_room_provider_web" / "router.ex"
        router.write_text(f"defmodule HostRuntime do\n  alias {reference}\nend\n")
        with patch("build_provider.OVERLAY_ROOT", self.overlay):
            with self.assertRaises(PackageInputError):
                audit_boundary(self.child, self.package)

    def _append_adapter_refs(self, *references: str) -> None:
        source = self.adapter.read_text().replace(
            "end\n", "".join(f"  alias {reference}\n" for reference in references) + "end\n"
        )
        self.adapter.write_text(source)
        (self.child / "lib" / "clean_room_provider" / self.adapter.name).write_text(source)

    def assert_public_adapter_allowed(self) -> None:
        with patch("build_provider.OVERLAY_ROOT", self.overlay):
            try:
                audit_boundary(self.child, self.package)
            except PackageInputError as error:
                self.fail(f"valid public adapter was rejected: {type(error).__name__}")


if __name__ == "__main__":
    unittest.main()
