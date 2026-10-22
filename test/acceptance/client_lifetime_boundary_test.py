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

from package_input import PackageInputError  # noqa: E402
from build_provider import audit_boundary  # noqa: E402


class LifetimeBoundaryTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.child = self.root / "provider"
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

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_named_adapter_may_use_only_the_documented_public_storage_seams(self) -> None:
        with patch("build_provider.OVERLAY_ROOT", self.overlay):
            try:
                audit_boundary(self.child, self.package)
            except PackageInputError as error:
                self.fail(f"named public adapter was rejected: {type(error).__name__}")

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


if __name__ == "__main__":
    unittest.main()
