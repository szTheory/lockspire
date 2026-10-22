#!/usr/bin/env python3
"""Create the package-clean Phoenix provider used by the acceptance journey.

This script deliberately speaks only to documented Mix tasks and public Lockspire
facades.  It never imports a protocol/storage implementation from the checkout.
"""

from __future__ import annotations

import argparse
import base64
import inspect
import os
import re
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request

from package_input import (
    PROJECT_ROOT,
    PackageInputError,
    assert_below,
    build_package,
    bind_compiled_candidate,
    clean_room_database_url,
    copy_child_template,
    inventory,
    locked_environment,
    probe_environment,
    PackageIdentity,
    package_tree_digest,
    package_version,
    sha256,
    run,
    source_revision,
    verify_candidate_host,
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


def write_host_runtime(
    child: Path,
    database_url: str,
    storage_prefix: str = "lockspire",
    *,
    custom_lifetime_adapter: bool = False,
) -> None:
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
  storage_prefix: System.get_env(\"LOCKSPIRE_STORAGE_PREFIX\", \"lockspire\"),
  oban_prefix: System.get_env(\"LOCKSPIRE_STORAGE_PREFIX\", \"lockspire\")
config :lockspire, Lockspire.Web.Endpoint,
  secret_key_base: System.get_env(\"LOCKSPIRE_SECRET_KEY_BASE\", \"clean-room-lockspire-secret-key-base-0123456789\")
"""
    )
    if custom_lifetime_adapter:
        with (child / "config" / "config.exs").open("a", encoding="utf-8") as config:
            config.write(
                """
config :lockspire,
  client_store: CleanRoomProvider.LifetimeClientStore,
  transaction_store: CleanRoomProvider.LifetimeClientStore
"""
            )
    # The child runs under the default dev env, so the generator's prod guard is omitted;
    # the body is the fail-closed block `mix lockspire.install` prints.
    (child / "config" / "runtime.exs").write_text(
        """import Config

config :lockspire, :key_encryption,
  keys: [
    {\"clean-room-1\",
     System.get_env(\"LOCKSPIRE_KEY_ENCRYPTION_KEY\") || raise(\"LOCKSPIRE_KEY_ENCRYPTION_KEY is missing. Generate one with: mix lockspire.gen.kek\")}
  ],
  current: \"clean-room-1\",
  legacy_plaintext: :reject
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

    adapter_source = child / "lib" / "clean_room_provider" / "lifetime_client_store.ex"
    adapter_text = adapter_source.read_text() if adapter_source.is_file() else ""
    allowed_refs = {
        "Lockspire.Storage.ClientStore",
        "Lockspire.Storage.TransactionStore",
        "Lockspire.Storage.Ecto.Repository",
        "Lockspire.Domain.Client",
    }
    adapter_refs = set(re.findall(r"Lockspire\.(?:Storage|Domain)(?:\.[A-Za-z0-9_]+)+", adapter_text))
    if adapter_refs - allowed_refs:
        raise PackageInputError("provider boundary audit found forbidden lifetime-adapter reference")
    if adapter_text and adapter_refs != allowed_refs:
        raise PackageInputError("provider lifetime adapter is missing a documented public seam")

    sources = "\n".join(path.read_text() for path in host_sources if path != adapter_source)
    adapter_sources = adapter_text
    for reference in allowed_refs:
        exact_reference = rf"(?<![A-Za-z0-9_.]){re.escape(reference)}(?![A-Za-z0-9_.])"
        adapter_sources = re.sub(exact_reference, "", adapter_sources)

    sources = f"{sources}\n{adapter_sources}"
    found = [needle for needle in FORBIDDEN if needle in sources]
    if found:
        raise PackageInputError(f"provider boundary audit found forbidden seam: {found[0]}")


def patch_jose_record_extractors(child: Path, environment: dict[str, str]) -> None:
    """Patch a locked JOSE 1.11.12 compile-time path incompatibility.

    JOSE's Elixir sources use ``Record.extract(..., from_lib: ...)``. Elixir
    1.19 resolves ``from_lib`` through the partially-built app directory,
    before Mix copies the package's headers there. Its immutable package source
    does contain those headers, so the child-local dependency cache is patched
    to resolve them relative to the source file instead. Dependency caches may
    preserve the patched source between CI runs, so the transformation accepts
    its own exact output. Any third shape still fails closed rather than
    silently altering another JOSE release.
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

        before_count = content.count(before)
        after_count = content.count(after)

        if before_count == 1 and after_count == 0:
            path.write_text(content.replace(before, after, 1))
        elif before_count == 0 and after_count == 1:
            continue
        else:
            raise PackageInputError(f"locked JOSE extractor shape changed: {relative}")


def prepare_provider(
    run_root: Path,
    database_url: str,
    *,
    package_root: Path | None = None,
    install: bool = True,
    port: int = 4100,
    cache_root: Path | None = None,
    storage_prefix: str = "lockspire",
    candidate_identity: PackageIdentity | None = None,
    custom_lifetime_adapter: bool = False,
) -> Path:
    probe_environment()
    if not re.fullmatch(r"[a-z][a-z0-9_]{0,39}", storage_prefix):
        raise PackageInputError("invalid Lockspire storage prefix")
    if package_root is None:
        package_root, _ = build_package(run_root)
    if candidate_identity is None:
        version = package_version(package_root)
        archive = package_root.parent / f"lockspire-{version}.tar"
        candidate_identity = PackageIdentity(
            "checkout", version, sha256(archive) if archive.is_file() else "",
            sha256(archive) if archive.is_file() else None,
            package_tree_digest(package_root), source_revision(),
        )
    child = run_root / "provider_host"
    reuse = child.is_dir()
    if reuse:
        vendor = child / "vendor" / "lockspire"
        if not vendor.is_dir():
            raise PackageInputError("prepared provider package is missing")
    else:
        child = copy_child_template("provider_host", run_root, package_root)
        # The checked-in lib tree is an overlay source, not pre-existing host code:
        # retain only the manifest/lock in the fresh child so the public installer
        # can create its managed and host-owned files without an overwrite refusal.
        shutil.rmtree(child / "lib")
        write_host_runtime(
            child,
            database_url,
            storage_prefix,
            custom_lifetime_adapter=custom_lifetime_adapter,
        )
    vendor = child / "vendor" / "lockspire"
    # Validate all bytes already on disk before Mix is allowed to inspect or load
    # the reusable child. The resolver probe below then confirms the observed path.
    verify_candidate_host(package_root, child, candidate_identity, vendor, vendor)
    # The host's config/runtime.exs raises without a KEK, and verify_child probes with mix,
    # so a standalone caller needs one in the inherited environment before any child runs.
    os.environ.setdefault("LOCKSPIRE_KEY_ENCRYPTION_KEY", base64.b64encode(os.urandom(32)).decode("ascii"))
    dependency_cache = cache_root or run_root / "deps-cache"
    isolated_hex_home = run_root / "hex-home"
    isolated_mix_home = run_root / "mix-home"
    isolated_hex_home.mkdir(mode=0o700, parents=True, exist_ok=True)
    isolated_mix_home.mkdir(mode=0o700, parents=True, exist_ok=True)
    isolated_environment = {
        "HEX_HOME": str(isolated_hex_home),
        "MIX_HOME": str(isolated_mix_home),
    }
    resolved = verify_child("provider_host", child, dependency_cache, isolated_environment)
    print("provider dependency provenance verified")
    verify_candidate_host(package_root, child, candidate_identity, vendor, resolved)
    environment = locked_environment(child, "provider_host", dependency_cache)
    environment.update(isolated_environment)
    environment.setdefault("LOCKSPIRE_KEY_ENCRYPTION_KEY", os.environ["LOCKSPIRE_KEY_ENCRYPTION_KEY"])
    environment.update(
        {
            "DATABASE_URL": database_url,
            "PORT": str(port),
            "LOCKSPIRE_ISSUER": f"http://127.0.0.1:{port}/lockspire",
            "LOCKSPIRE_STORAGE_PREFIX": storage_prefix,
        }
    )
    if not install:
        # No overlay is applied without the installer, so the overlay-based boundary audit does
        # not apply; only the vendored package inventory is checked here.
        vendor = child / "vendor" / "lockspire"
        verify_candidate_host(package_root, child, candidate_identity, vendor, resolved)
        return child

    if reuse:
        if not (child / ".lockspire-candidate.json").exists():
            run(("mix", "compile"), cwd=child, env=environment)
            bind_compiled_candidate(child, candidate_identity, vendor, resolved)
        return child

    patch_jose_record_extractors(child, environment)

    install_result = subprocess.run(
        ("mix", "lockspire.install", "--web", "CleanRoomProviderWeb", "--scope", "CleanRoomProvider.Lockspire", "--path", str(child), "--mount-path", "/lockspire", "--storage-prefix", storage_prefix, "--oban-prefix", storage_prefix),
        cwd=child,
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if install_result.returncode != 0:
        raise PackageInputError("provider installer failed")
    apply_host_overlays(child)
    print("provider host overlays applied")
    audit_boundary(child, package_root)
    print("provider boundary audit complete")
    run(("mix", "compile"), cwd=child, env=environment)
    built_apps = sorted(
        path.name
        for path in (
            *(child / "_build" / "lib").glob("*"),
            *(child / "_build" / "dev" / "lib").glob("*"),
            *(child / "_build" / "test" / "lib").glob("*"),
        )
        if path.is_dir()
    )
    print(
        "provider host compiled; mix env "
        + str(environment.get("MIX_ENV"))
        + "; build root "
        + str(environment.get("MIX_BUILD_PATH"))
        + "; build apps "
        + ",".join(built_apps)
    )
    bind_compiled_candidate(child, candidate_identity, vendor, resolved)
    return child


def _run_mix(child: Path, environment: dict[str, str], command: tuple[str, ...]) -> bytes:
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
        # lockspire.client.create prints client_secret=...; never let it reach an exception message
        # or CI log if the task exits nonzero after printing. Scrub before slicing the tail.
        lines = completed.stdout.decode(errors="replace").splitlines()
        details = [re.sub(r"client_secret=\S*", "client_secret=[REDACTED]", line) for line in lines][-16:]
        raise PackageInputError(f"provider {' '.join(command)} failed: {' '.join(details)}")
    return completed.stdout


def run_child_command(child: Path, environment: dict[str, str], *command: str) -> None:
    _run_mix(child, environment, command)


def run_child_command_output(child: Path, environment: dict[str, str], *command: str) -> str:
    return _run_mix(child, environment, command).decode(errors="replace")


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
    database_url = clean_room_database_url("provider")
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
            run_child_command(
                child,
                environment,
                "ecto.migrate",
                "--migrations-path",
                "priv/repo/migrations",
            )
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
    host_runtime_source = inspect.getsource(write_host_runtime)
    required_runtime = (
        "runtime.exs",
        "config :lockspire, :key_encryption",
        "LOCKSPIRE_KEY_ENCRYPTION_KEY",
        "|| raise(",
        "legacy_plaintext: :reject",
    )
    if any(item not in host_runtime_source for item in required_runtime):
        raise PackageInputError("provider host runtime config is missing the env-sourced key_encryption block under :reject")
    if "key_encryption:" in host_runtime_source or "legacy_plaintext: :allow" in host_runtime_source:
        raise PackageInputError("provider host must not carry key_encryption in compile-time config or allow plaintext rows")
    if re.search(r"[A-Za-z0-9+/]{43}=", host_runtime_source):
        raise PackageInputError("provider host source must not contain a literal key-encryption key")
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

_KEY_PATTERN = re.compile(r"[A-Za-z0-9+/]{43}=")


def _scrub(text: str) -> str:
    return _KEY_PATTERN.sub("[REDACTED]", text)


def _gen_kek_failure(description: str, completed: "subprocess.CompletedProcess[str] | None" = None) -> PackageInputError:
    if completed is None:
        return PackageInputError(description)
    tail = " ".join(_scrub(completed.stderr).splitlines()[-8:])
    return PackageInputError(f"{description} (exit {completed.returncode}): {tail}")


def check_gen_kek() -> None:
    """Prove `mix lockspire.gen.kek` runs cold in a host whose runtime.exs raises without a key."""
    with tempfile.TemporaryDirectory(prefix="lockspire-clean-room-gen-kek-") as temporary:
        child = prepare_provider(Path(temporary), clean_room_database_url("provider"), install=False)
        environment = locked_environment(child, "provider_host", Path(temporary) / "deps-cache")
        patch_jose_record_extractors(child, environment)
        run_child_command(child, environment, "compile")

        cold = dict(environment)
        cold.pop("LOCKSPIRE_KEY_ENCRYPTION_KEY", None)

        def mix(*command: str) -> "subprocess.CompletedProcess[str]":
            return subprocess.run(
                ("mix", *command),
                cwd=child,
                env=cold,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                check=False,
            )

        raw = mix("lockspire.gen.kek", "--raw")
        if raw.returncode != 0:
            raise _gen_kek_failure("gen.kek --raw failed without the key variable", raw)
        lines = raw.stdout.splitlines()
        valid = False
        if len(lines) == 1 and len(lines[0]) == 44:
            try:
                valid = len(base64.b64decode(lines[0], validate=True)) == 32
            except ValueError:
                valid = False
        if not valid:
            raise _gen_kek_failure("gen.kek --raw did not print one valid 44-character key", raw)

        default = mix("lockspire.gen.kek")
        if default.returncode != 0:
            raise _gen_kek_failure("gen.kek failed without the key variable", default)
        key_lines = [line for line in default.stdout.splitlines() if line.startswith("LOCKSPIRE_KEY_ENCRYPTION_KEY=")]
        if len(key_lines) != 1 or "if config_env() == :prod" not in default.stdout:
            raise _gen_kek_failure("gen.kek default output is missing the key line or the prod block", default)

        config = mix("app.config")
        combined = config.stdout + config.stderr
        if config.returncode == 0 or "LOCKSPIRE_KEY_ENCRYPTION_KEY is missing" not in combined:
            raise _gen_kek_failure("host runtime did not fail closed without the key", config)

        print("gen.kek cold run verified")
        print("host runtime fails closed without the key")


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--check-bootstrap", action="store_true")
    parser.add_argument("--check-gen-kek", action="store_true")
    args = parser.parse_args(argv)
    try:
        if args.self_test:
            self_test()
            return 0
        if args.check_bootstrap:
            check_bootstrap()
            return 0
        if args.check_gen_kek:
            check_gen_kek()
            return 0
        raise PackageInputError("choose --self-test, --check-bootstrap or --check-gen-kek")
    except PackageInputError as error:
        print(f"clean-room provider build failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
