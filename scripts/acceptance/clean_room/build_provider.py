#!/usr/bin/env python3
"""Create the package-clean Phoenix provider used by the acceptance journey.

This script deliberately speaks only to documented Mix tasks and public Lockspire
facades.  It never imports a protocol/storage implementation from the checkout.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request
import uuid

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
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env(\"PORT\", \"4100\"))],
  secret_key_base: System.get_env(\"SECRET_KEY_BASE\", \"clean-room-provider-secret-key-base-0123456789-abcdefghijklmnopqrstuvwxyz-0123456789\"),
  live_view: [signing_salt: \"clean-room-provider-live-view-salt\"],
  server: true
config :lockspire,
  repo: CleanRoomProvider.Repo,
  account_resolver: CleanRoomProvider.Lockspire.AccountResolver,
  interaction_handler: CleanRoomProvider.Lockspire.InteractionHandler,
  issuer: System.get_env(\"LOCKSPIRE_ISSUER\", \"http://127.0.0.1:4100/lockspire\"),
  known_scopes: [\"openid\", \"profile\", \"read:billing\", \"offline_access\"],
  mount_path: \"/lockspire\",
  logout_path: \"/logout\",
  storage_prefix: \"lockspire\",
  oban_prefix: \"lockspire\"
config :lockspire, Lockspire.Web.Endpoint,
  secret_key_base: System.get_env(\"LOCKSPIRE_SECRET_KEY_BASE\", \"clean-room-lockspire-secret-key-base-0123456789\")
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
    with {:ok, supervisor} <- Supervisor.start_link(children, strategy: :one_for_one, name: CleanRoomProvider.Supervisor),
         {:ok, _started} <- Application.ensure_all_started(:lockspire) do
      {:ok, supervisor}
    end
  end
end
"""
    )
    (child / "lib" / "clean_room_provider_web" / "endpoint.ex").write_text(
        """defmodule CleanRoomProviderWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :clean_room_provider
  @session [store: :cookie, key: \"_clean_room_provider\", signing_salt: \"clean-room-salt\"]
  plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], pass: ["*/*"], json_decoder: Jason
  plug Plug.Session, @session
  plug :fetch_clean_room_session
  plug CleanRoomProviderWeb.Router

  defp fetch_clean_room_session(conn, _opts), do: Plug.Conn.fetch_session(conn)
end
"""
    )
    (child / "lib" / "clean_room_provider_web.ex").write_text(
        "defmodule CleanRoomProviderWeb do\n  def static_paths, do: []\nend\n"
    )
    # The installer is itself compiled through the child Mix project. Provide a
    # minimal host-owned router so the endpoint can compile before generated
    # Lockspire routing and the acceptance overlay are installed.
    (child / "lib" / "clean_room_provider_web" / "router.ex").write_text(
        "defmodule CleanRoomProviderWeb.Router do\n  use Phoenix.Router\nend\n"
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

    # Generated Lockspire seams are package-owned output and can legitimately
    # route into Lockspire itself. Audit only the acceptance host's runtime and
    # overlay sources, which are the files this fixture owns and may edit.
    host_sources = [
        child / "lib" / "clean_room_provider_web.ex",
        child / "lib" / "clean_room_provider" / "repo.ex",
        child / "lib" / "clean_room_provider" / "application.ex",
        child / "lib" / "clean_room_provider_web" / "endpoint.ex",
        child / "lib" / "clean_room_provider_web" / "router.ex",
    ]

    for source in OVERLAY_ROOT.rglob("*"):
        if source.is_file():
            relative = source.relative_to(OVERLAY_ROOT)
            destination = child / "lib" / relative

            if source.name == "router_patch.exs":
                destination = destination.with_name("router.ex")

            host_sources.append(destination)

    sources = "\n".join(path.read_text() for path in host_sources)
    found = [needle for needle in FORBIDDEN if needle in sources]
    if found:
        raise PackageInputError(f"provider boundary audit found forbidden seam: {found[0]}")


def patch_jose_record_extractors(child: Path, environment: dict[str, str]) -> None:
    """Patch a locked JOSE 1.11.12 compile-time path incompatibility.

    JOSE's Elixir sources use ``Record.extract(..., from_lib: ...)``. Elixir
    1.19 resolves ``from_lib`` through the partially-built app directory,
    before Mix copies the package's headers there. Its immutable package source
    does contain those headers, so the child-local dependency cache is patched
    to resolve them relative to the source file instead. The exact replacements
    make unexpected upstream lock changes fail closed rather than silently
    altering another JOSE release.
    """
    deps_root = Path(environment["MIX_DEPS_PATH"])
    source = deps_root / "jose"

    if not (source / "include" / "jose_jwt.hrl").is_file():
        raise PackageInputError("locked JOSE dependency is missing jose_jwt.hrl")

    extractors = {
        "lib/jose/jwe.ex": "jose_jwe.hrl",
        "lib/jose/jwk.ex": "jose_jwk.hrl",
        "lib/jose/jws.ex": "jose_jws.hrl",
        "lib/jose/jwt.ex": "jose_jwt.hrl",
    }

    for relative, header in extractors.items():
        path = source / relative
        before = f'from_lib: "jose/include/{header}"'
        after = f'from: Path.expand("../../include/{header}", __DIR__)'
        content = path.read_text()

        if before not in content:
            raise PackageInputError(f"locked JOSE extractor shape changed: {relative}")

        path.write_text(content.replace(before, after, 1))


def prepare_provider(run_root: Path, database_url: str, *, install: bool = True, port: int = 4100) -> Path:
    probe_environment()
    package_root, _ = build_package(run_root)
    child = copy_child_template("provider_host", run_root, package_root)
    # The checked-in lib tree is an overlay source, not pre-existing host code:
    # retain only the manifest/lock in the fresh child so the public installer
    # can create its managed and host-owned files without an overwrite refusal.
    shutil.rmtree(child / "lib")
    write_host_runtime(child, database_url)
    verify_child("provider_host", child, run_root / "deps-cache")
    environment = locked_environment(child, "provider_host", run_root / "deps-cache")
    environment.update(
        {
            "DATABASE_URL": database_url,
            "PORT": str(port),
            "LOCKSPIRE_ISSUER": f"http://127.0.0.1:{port}/lockspire",
        }
    )
    if not install:
        audit_boundary(child, package_root)
        return child

    patch_jose_record_extractors(child, environment)

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


def run_child_command(child: Path, environment: dict[str, str], *command: str) -> None:
    completed = subprocess.run(
        ("mix", *command),
        cwd=child,
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )

    if completed.returncode != 0:
        details = completed.stdout.decode(errors="replace").splitlines()[-16:]
        raise PackageInputError(f"provider {' '.join(command)} failed: {' '.join(details)}")


def allocate_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
        listener.bind(("127.0.0.1", 0))
        return int(listener.getsockname()[1])


def assert_live_discovery(child: Path, environment: dict[str, str], issuer: str) -> None:
    process = subprocess.Popen(
        ("mix", "run", "--no-halt"),
        cwd=child,
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    try:
        deadline = time.monotonic() + 12
        url = f"{issuer}/.well-known/openid-configuration"

        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise PackageInputError("provider exited before live discovery became available")

            try:
                with urllib.request.urlopen(url, timeout=0.5) as response:
                    if response.status == 200 and issuer.encode() in response.read():
                        return
            except OSError:
                time.sleep(0.1)

        raise PackageInputError("provider discovery did not become available")
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=5)


def self_test() -> None:
    port = allocate_port()
    database_name = f"lockspire_clean_room_provider_{uuid.uuid4().hex}"
    database_url = f"postgres://postgres:postgres@127.0.0.1/{database_name}"
    issuer = f"http://127.0.0.1:{port}/lockspire"

    with tempfile.TemporaryDirectory(prefix="lockspire-clean-room-provider-") as temporary:
        child = prepare_provider(
            Path(temporary),
            database_url,
            port=port,
        )
        environment = locked_environment(child, "provider_host", Path(temporary) / "deps-cache")
        environment.update({"DATABASE_URL": database_url, "PORT": str(port), "LOCKSPIRE_ISSUER": issuer})

        try:
            run_child_command(child, environment, "ecto.create")
            run_child_command(child, environment, "ecto.migrate")
            run_child_command(child, environment, "compile", "--warnings-as-errors")
            run_child_command(child, environment, "lockspire.verify")
            assert_live_discovery(child, environment, issuer)
        finally:
            run_child_command(child, environment, "ecto.drop")

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
        "plug(Lockspire.Plug.VerifyToken",
        "plug(Lockspire.Plug.EnforceSenderConstraints)",
        "plug(Lockspire.Plug.RequireToken)",
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
