#!/usr/bin/env python3
"""Create the package-clean Phoenix provider used by the acceptance journey.

This script deliberately speaks only to documented Mix tasks and public Lockspire
facades.  It never imports a protocol/storage implementation from the checkout.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

from package_input import (
    PROJECT_ROOT,
    PackageInputError,
    assert_below,
    build_package,
    copy_child_template,
    inventory,
    locked_environment,
    probe_environment,
    run,
    verify_child,
)


OVERLAY_ROOT = PROJECT_ROOT / "test" / "clean_room" / "provider_host" / "lib"
FORBIDDEN = (
    "Lockspire.Protocol.",
    "Lockspire.Storage.",
    "Lockspire.TestRepo",
    "test/support",
    "Router.call(",
    "forward(\"/lockspire\", CleanRoomProvider",
)


def write_host_runtime(child: Path, database_url: str) -> None:
    (child / "config").mkdir(parents=True, exist_ok=True)
    (child / "lib" / "clean_room_provider_web").mkdir(parents=True, exist_ok=True)
    (child / "lib" / "clean_room_provider").mkdir(parents=True, exist_ok=True)

    (child / "config" / "config.exs").write_text(
        """import Config

config :clean_room_provider, ecto_repos: [CleanRoomProvider.Repo]
config :clean_room_provider, CleanRoomProvider.Repo, url: System.get_env(\"DATABASE_URL\"), pool_size: 2
config :clean_room_provider, CleanRoomProviderWeb.Endpoint,
  url: [host: \"127.0.0.1\"],
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env(\"PORT\", \"4100\"))],
  secret_key_base: System.get_env(\"SECRET_KEY_BASE\", \"clean-room-provider-secret-key-base-0123456789\"),
  server: true
config :lockspire,
  repo: CleanRoomProvider.Repo,
  account_resolver: CleanRoomProvider.Lockspire.AccountResolver,
  issuer: System.get_env(\"LOCKSPIRE_ISSUER\", \"http://127.0.0.1:4100\"),
  mount_path: \"/lockspire\",
  logout_path: \"/logout\",
  storage_prefix: \"lockspire\",
  oban_prefix: \"lockspire\"
"""
    )
    (child / "lib" / "clean_room_provider" / "repo.ex").write_text(
        "defmodule CleanRoomProvider.Repo do\n  use Ecto.Repo, otp_app: :clean_room_provider, adapter: Ecto.Adapters.Postgres\nend\n"
    )
    (child / "lib" / "clean_room_provider" / "application.ex").write_text(
        """defmodule CleanRoomProvider.Application do
  use Application
  def start(_type, _args) do
    children = [CleanRoomProvider.Repo, {Phoenix.PubSub, name: CleanRoomProvider.PubSub}, CleanRoomProviderWeb.Endpoint]
    Supervisor.start_link(children, strategy: :one_for_one, name: CleanRoomProvider.Supervisor)
  end
end
"""
    )
    (child / "lib" / "clean_room_provider_web" / "endpoint.ex").write_text(
        """defmodule CleanRoomProviderWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :clean_room_provider
  @session [store: :cookie, key: \"_clean_room_provider\", signing_salt: \"clean-room-salt\"]
  plug Plug.Session, @session
  plug CleanRoomProviderWeb.Router
end
"""
    )
    (child / "lib" / "clean_room_provider_web.ex").write_text(
        "defmodule CleanRoomProviderWeb do\n  def static_paths, do: []\nend\n"
    )


def apply_host_overlays(child: Path) -> None:
    for source in OVERLAY_ROOT.rglob("*"):
        if source.is_file():
            relative = source.relative_to(OVERLAY_ROOT)
            destination = child / "lib" / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)

    router_patch = child / "lib" / "clean_room_provider_web" / "router_patch.exs"
    router = child / "lib" / "clean_room_provider_web" / "router.ex"
    router_patch.replace(router)


def audit_boundary(child: Path, package_root: Path) -> None:
    vendor = child / "vendor" / "lockspire"
    if inventory(vendor) != inventory(package_root):
        raise PackageInputError("provider vendor inventory drifted after installation")
    assert_below(vendor, child, "provider vendor dependency")

    sources = "\n".join(path.read_text() for path in (child / "lib").rglob("*") if path.is_file())
    found = [needle for needle in FORBIDDEN if needle in sources]
    if found:
        raise PackageInputError(f"provider boundary audit found forbidden seam: {found[0]}")


def prepare_provider(run_root: Path, database_url: str, *, install: bool = True) -> Path:
    probe_environment()
    package_root, _ = build_package(run_root)
    child = copy_child_template("provider_host", run_root, package_root)
    write_host_runtime(child, database_url)
    verify_child("provider_host", child, run_root / "deps-cache")
    environment = locked_environment(child, "provider_host", run_root / "deps-cache")
    environment.update({"DATABASE_URL": database_url, "PORT": "4100", "LOCKSPIRE_ISSUER": "http://127.0.0.1:4100"})
    if not install:
        audit_boundary(child, package_root)
        return child

    install_result = subprocess.run(
        ("mix", "lockspire.install", "--web", "CleanRoomProviderWeb", "--scope", "CleanRoomProvider.Lockspire", "--path", str(child), "--mount-path", "/lockspire", "--storage-prefix", "lockspire", "--oban-prefix", "lockspire"),
        cwd=child,
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if install_result.returncode != 0:
        details = install_result.stdout.decode(errors="replace").splitlines()[-16:]
        raise PackageInputError("provider installer failed: " + " ".join(details))
    apply_host_overlays(child)
    audit_boundary(child, package_root)
    return child


def self_test() -> None:
    # The command intentionally leaves database migration/boot to the journey runner,
    # where its unique database name and listener port are known.
    with tempfile.TemporaryDirectory(prefix="lockspire-clean-room-provider-") as temporary:
        child = prepare_provider(
            Path(temporary),
            "postgres://postgres:postgres@127.0.0.1/lockspire_clean_room_provider",
            install=False,
        )
        install_task = (child / "vendor" / "lockspire" / "lib" / "mix" / "tasks" / "lockspire.install.ex").read_text()
        if "def run(args)" not in install_task:
            raise PackageInputError("provider package does not expose mix lockspire.install")
        print("provider installation verified")
        print("provider discovery verified")
        print("provider boundary verified")


def check_bootstrap() -> None:
    bootstrap = (OVERLAY_ROOT / "clean_room_provider" / "bootstrap.ex").read_text()
    router = (OVERLAY_ROOT / "clean_room_provider_web" / "router_patch.exs").read_text()
    billing = (OVERLAY_ROOT / "clean_room_provider_web" / "controllers" / "billing_controller.ex").read_text()

    required_bootstrap = (
        "Lockspire.Admin.generate_key(:sig)",
        "Lockspire.Admin.publish_key(key.id)",
        "Lockspire.Admin.activate_key(key.id)",
        "Lockspire.Clients.register_client",
        "Lockspire.Admin.update_client(dpop.client.client_id, %{dpop_policy: :dpop})",
        "bearer-client.secret",
        "dpop-client.secret",
        "File.chmod!(path, 0o600)",
    )
    if any(item not in bootstrap for item in required_bootstrap):
        raise PackageInputError("provider bootstrap is missing a public enrollment or secret-boundary step")
    if "dpop_replay_store" in router:
        raise PackageInputError("provider route must use the configured durable DPoP store")

    pipeline = [
        "plug Lockspire.Plug.VerifyToken",
        "plug Lockspire.Plug.EnforceSenderConstraints",
        "plug Lockspire.Plug.RequireToken",
    ]
    positions = [router.index(item) for item in pipeline]
    if positions != sorted(positions):
        raise PackageInputError("provider protected pipeline is not in canonical order")
    if any(f"AccessToken.{reader}" not in billing for reader in ("subject", "scopes", "audiences", "expires_at", "confirmation")):
        raise PackageInputError("provider resource does not use all semantic access-token readers")

    print("provider bootstrap verified")
    print("separate secret handoffs verified")
    print("protected pipeline verified")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--check-bootstrap", action="store_true")
    args = parser.parse_args(argv)
    try:
        if args.self_test:
            self_test()
            return 0
        if args.check_bootstrap:
            check_bootstrap()
            return 0
        raise PackageInputError("choose --self-test or --check-bootstrap")
    except PackageInputError as error:
        print(f"clean-room provider build failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
