"""Installed mixed-version verifier rollout and pinned public legacy controls.

Each cell owns its database, host exports, package archives, ports, and process
groups. Receipt values are safe observations only; credentials and persisted
verifier bytes never leave the child process.
"""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
import urllib.request
import uuid

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE))

import clean_room_verifier_upgrade as runner  # noqa: E402
from build_provider import (  # noqa: E402
    PackageInputError,
    allocate_port,
    prepare_provider,
    run_child_command,
    run_child_command_output,
)
from package_input import (  # noqa: E402
    PackageIdentity,
    PackageSource,
    bounded_run,
    clean_room_database_url,
    prepare_package,
    package_tree_digest,
    package_version,
    sha256,
    start_owned_session,
    stop_process_group,
    unpack_hex_tarball,
    verify_candidate_input,
)
from redaction import Redactor, SentinelSet  # noqa: E402


PREDECESSOR = "173059a166e9ade0f5f57c9980b7b2400a98538c"
PUBLIC_SOURCE = "d04be40262e975a4eb8d8567eb0d1458a9c23181"
PUBLIC_SHA256 = "629abdc1b6721620f3d9084dbbe78da1e254650da5c552d0cc0f5b0c00f1cc6d"
PROJECT_ROOT = HERE.parents[1]
PUBLIC_TARBALL = PROJECT_ROOT / "lockspire-1.6.1.tar"
PUBLIC_RELEASE_RECORD = PROJECT_ROOT / ".planning" / "RELEASE-TRAIN.md"
PUBLIC_RELEASE_EVIDENCE = PROJECT_ROOT / ".planning" / "releases" / "1.6.1-EVIDENCE.md"
PUBLIC_TERMINAL_RECEIPT = PROJECT_ROOT / ".planning" / "releases" / "1.6.1-terminal-receipt.json"


def run_rollout_group(*, pair: str, store: str, receipt_dir: Path) -> list[dict[str, object]]:
    if pair not in {"all", "locked", "floor"} or store not in {"all", "builtin", "delegated"}:
        raise PackageInputError("unsupported rollout selection")
    return _run_selected_group(scope="rollout", pair=pair, store=store, receipt_dir=receipt_dir)


def run_legacy_control_group(*, pair: str, store: str, receipt_dir: Path) -> list[dict[str, object]]:
    if pair != "locked" or store != "builtin":
        raise PackageInputError("legacy-control supports only locked/builtin selection")
    return _run_selected_group(scope="legacy-control", pair=pair, store=store, receipt_dir=receipt_dir)


def _run_selected_group(*, scope: str, pair: str, store: str, receipt_dir: Path) -> list[dict[str, object]]:
    if scope == "rollout":
        pairs = ("locked", "floor") if pair == "all" else (pair,)
        stores = ("builtin", "delegated") if store == "all" else (store,)
        receipts = []
        for selected_pair in pairs:
            for selected_store in stores:
                receipts.append(_run_rollout_cell(selected_pair, selected_store, receipt_dir / f"{selected_pair}-{selected_store}"))
    else:
        receipts = [_run_public_control(receipt_dir / "locked-builtin")]
    print(json.dumps({"scope": scope, "executed_count": len(receipts), "cells": [
        {"pair": row["pair"], "store": row["store"], "scope": row["scope"], "receipt": row["receipt_path"]}
        for row in receipts
    ]}, sort_keys=True), flush=True)
    return receipts


def _build_predecessor(run_root: Path) -> tuple[Path, Path, PackageIdentity, dict[str, str]]:
    root = PROJECT_ROOT
    if not _git_commit_exists(PREDECESSOR):
        raise PackageInputError("accepted predecessor source commit is unavailable")
    exported = run_root / "predecessor-source"
    exported.mkdir(mode=0o700)
    archive_tar = run_root / "predecessor-source.tar"
    completed = subprocess.run(
        ("git", "archive", "--format=tar", "--output", str(archive_tar), PREDECESSOR),
        cwd=root, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        check=False, timeout=60,
    )
    if completed.returncode:
        raise PackageInputError("accepted predecessor source export failed")
    unpacked = subprocess.run(
        ("tar", "-xf", str(archive_tar), "-C", str(exported)), cwd=root,
        stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        check=False, timeout=60,
    )
    if unpacked.returncode:
        raise PackageInputError("accepted predecessor source archive could not be unpacked")
    package_tar = run_root / "predecessor-package.tar"
    env = os.environ.copy()
    # Hex's installed Mix archive is runtime tooling, not package input. Keep
    # the process-local configured Mix home so `mix hex.build` can load it.
    built = bounded_run(("mix", "hex.build", "--output", str(package_tar)), cwd=exported, env=env,
                        stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if built.returncode or not package_tar.is_file():
        raise PackageInputError(f"accepted predecessor package build failed (exit {built.returncode})")
    package = run_root / "predecessor-package"
    unpack_hex_tarball(package_tar, package)
    for path in package.rglob("*"):
        if not path.is_file():
            continue
        relative = path.relative_to(package)
        if relative.as_posix() == "hex_metadata.config":
            # Mix generates this archive manifest from the exported mix.exs.
            continue
        source_path = exported / relative
        if not source_path.is_file() or source_path.read_bytes() != path.read_bytes():
            raise PackageInputError("accepted predecessor archive does not match its exported source tree")
    version = package_version(package)
    tree = package_tree_digest(package)
    archive_sha = sha256(package_tar)
    binding = json.dumps({"archive_sha256": archive_sha, "source_revision": PREDECESSOR,
                          "tree_sha256": tree}, sort_keys=True, separators=(",", ":"))
    identity = PackageIdentity("accepted-git-source", version, archive_sha, archive_sha,
                               tree, PREDECESSOR, runner.source_revision(),
                               hashlib.sha256(binding.encode()).hexdigest())
    verify_candidate_input(package_tar, package, identity)
    commit_tree = subprocess.check_output(("git", "rev-parse", f"{PREDECESSOR}^{{tree}}"), cwd=root, text=True).strip()
    return package, package_tar, identity, {"commit_tree": commit_tree, "source_archive_sha256": sha256(archive_tar)}


def _run_rollout_cell(pair: str, store: str, receipt_dir: Path) -> dict[str, object]:
    run_id = uuid.uuid4().hex
    port_old, port_new = allocate_port(), allocate_port()
    port_legacy = allocate_port()
    prefix = "vrr" + run_id[:12]
    database_url = clean_room_database_url("verifier_rollout")
    key = runner.base64.b64encode(os.urandom(32)).decode("ascii")
    key_next = runner.base64.urlsafe_b64encode(os.urandom(32)).rstrip(b"=").decode("ascii")
    redactor = Redactor(SentinelSet.for_run())
    redactor.register_material(key)
    redactor.register_material(key_next)
    old_server = new_server = legacy_server = None
    with tempfile.TemporaryDirectory(prefix=f"lockspire-verifier-rollout-{pair}-{store}-") as temporary:
        root = Path(temporary)
        old_package, old_archive, old_identity, old_proof = _build_predecessor(root)
        candidate, _entries, candidate_identity = prepare_package(root / "candidate", PackageSource("checkout"))
        candidate_archive = candidate.parent / f"lockspire-{candidate_identity.version}.tar"
        verify_candidate_input(candidate_archive, candidate, candidate_identity)
        old_host = prepare_provider(root / "old", database_url, package_root=old_package,
                                    port=port_old, storage_prefix=prefix,
                                    candidate_identity=old_identity, proof_pair=pair,
                                    scenario_groups={"rollout"})
        new_host = prepare_provider(root / "new", database_url, package_root=candidate,
                                    port=port_new, storage_prefix=prefix,
                                    candidate_identity=candidate_identity, custom_lifetime_adapter=store == "delegated",
                                    proof_pair=pair, scenario_groups={"rollout"})
        legacy_host = prepare_provider(root / "legacy-writer", database_url, package_root=candidate,
                                       port=port_legacy, storage_prefix=prefix,
                                       candidate_identity=candidate_identity,
                                       custom_lifetime_adapter=store == "delegated", proof_pair=pair,
                                       scenario_groups={"rollout"})
        _configure(host=old_host, mode="legacy", legacy_read="allow", key=key)
        _configure(host=new_host, mode="legacy", legacy_read="allow", key=key)
        old_env = runner._mix_env(old_host, root / "old", database_url, port_old, f"http://127.0.0.1:{port_old}/lockspire", prefix, key, pair)
        new_env = runner._mix_env(new_host, root / "new", database_url, port_new, f"http://127.0.0.1:{port_new}/lockspire", prefix, key, pair)
        legacy_env = runner._mix_env(legacy_host, root / "legacy-writer", database_url, port_legacy,
                                    f"http://127.0.0.1:{port_legacy}/lockspire", prefix, key, pair)
        for environment in (old_env, new_env, legacy_env):
            environment["CLEAN_ROOM_HTTP_SERVER"] = "false"
        redactor.register_material(database_url)
        try:
            run_child_command(old_host, old_env, "ecto.create")
            run_child_command(old_host, old_env, "ecto.migrate")
            run_child_command(new_host, new_env, "ecto.migrate")
            runner._provision_signing_key(new_host, new_env)
            old_server, old_pid = _start_server(old_host, old_env, root / "old.log", old_env["LOCKSPIRE_ISSUER"])
            new_server, new_pid = _start_server(new_host, new_env, root / "new.log", new_env["LOCKSPIRE_ISSUER"])
            overlap_candidate_pid = new_pid
            legacy_id = "rollout-legacy-" + run_id
            legacy_id, legacy_secret = runner._capture_secret(old_host, old_env, redactor, legacy_id)
            legacy_format, legacy_hash = _safe_row(new_host, new_env, prefix, legacy_id)
            old_read = _http_auth(old_env["LOCKSPIRE_ISSUER"], port_old, legacy_id, legacy_secret)
            new_read = _http_auth(new_env["LOCKSPIRE_ISSUER"], port_new, legacy_id, legacy_secret)
            if legacy_format != "legacy" or not old_read or not new_read:
                raise PackageInputError("shared-store legacy write/read controls failed")
            old_server.terminate()
            old_server.wait(timeout=10)
            old_drain = old_server.poll() is not None
            if not old_drain:
                raise PackageInputError("accepted predecessor process did not exit before activation")
            _stop_owned_server(new_server)
            new_server = None
            _configure(host=new_host, mode="dedicated", legacy_read="allow", key=key)
            new_server, new_pid = _start_server(new_host, new_env, root / "new.log", new_env["LOCKSPIRE_ISSUER"])
            dedicated_candidate_pid = new_pid
            dedicated_id = "rollout-dedicated-" + run_id
            dedicated_id, dedicated_secret = runner._capture_secret(new_host, new_env, redactor, dedicated_id)
            dedicated_format, dedicated_hash = _safe_row(new_host, new_env, prefix, dedicated_id)
            dedicated_read = _http_auth(new_env["LOCKSPIRE_ISSUER"], port_new, dedicated_id, dedicated_secret)
            _stop_owned_server(new_server)
            new_server = None
            _configure(host=new_host, mode="legacy", legacy_read="allow", key=key)
            new_server, new_pid = _start_server(new_host, new_env, root / "new-rollback.log", new_env["LOCKSPIRE_ISSUER"])
            rollback_candidate_pid = new_pid
            rollback_status = _http_auth(new_env["LOCKSPIRE_ISSUER"], port_new, dedicated_id, dedicated_secret)
            if not rollback_status:
                raise PackageInputError("compatible-reader rollback could not read dedicated verifier")
            # A separate candidate process switches writers back to legacy while preserving the dedicated row.
            run_child_command(legacy_host, legacy_env, "ecto.migrate")
            _configure(host=legacy_host, mode="legacy", legacy_read="allow", key=key)
            dedicated_hash_before_switchback = _safe_row(new_host, new_env, prefix, dedicated_id)[1]
            legacy_write_id, _legacy_write_secret = runner._capture_secret(legacy_host, legacy_env, redactor, "rollout-switchback-" + run_id)
            legacy_write_format, legacy_write_hash = _safe_row(legacy_host, legacy_env, prefix, legacy_write_id)
            legacy_server, legacy_pid = _start_server(legacy_host, legacy_env, root / "legacy.log", legacy_env["LOCKSPIRE_ISSUER"])
            legacy_read = _http_auth(legacy_env["LOCKSPIRE_ISSUER"], port_legacy, legacy_write_id, _legacy_write_secret)
            candidate_reads_switchback_legacy = _http_auth(new_env["LOCKSPIRE_ISSUER"], port_new, legacy_write_id, _legacy_write_secret)
            dedicated_hash_after_switchback = _safe_row(new_host, new_env, prefix, dedicated_id)[1]
            legacy_server.terminate()
            legacy_server.wait(timeout=10)
            legacy_server = None
            _stop_owned_server(new_server)
            new_server = None
            _configure(host=new_host, mode="dedicated", legacy_read="allow", key=key)
            new_server, new_pid = _start_server(new_host, new_env, root / "new-dedicated-rollback.log", new_env["LOCKSPIRE_ISSUER"])
            if (legacy_write_format != "legacy" or not legacy_write_hash or not legacy_read or
                    not candidate_reads_switchback_legacy or dedicated_hash_before_switchback != dedicated_hash_after_switchback):
                raise PackageInputError("legacy writer switch-back did not preserve dedicated row material")
            # Old-code rejection is isolated: the predecessor host process was already drained.
            _configure(host=old_host, mode="legacy", legacy_read="allow", key=key)
            old_server, isolated_old_pid = _start_server(old_host, old_env, root / "old-isolated.log", old_env["LOCKSPIRE_ISSUER"])
            old_legacy_control = _http_auth(old_env["LOCKSPIRE_ISSUER"], port_old, legacy_id, legacy_secret)
            isolated_old_status = _old_code_probe(old_host, old_env, dedicated_id, dedicated_secret)
            old_server.terminate()
            old_server.wait(timeout=10)
            old_server = None
            if dedicated_format != "dedicated" or not dedicated_read or isolated_old_status != 401 or not old_legacy_control or not rollback_status:
                raise PackageInputError("dedicated activation, isolated old-code rejection, or rollback read failed")
            observation = {
                "outcome": "pass", "executed": True, "old_process_exit_observed": old_drain,
                "legacy_write_read_shared_store": legacy_format == "legacy" and old_read and new_read,
                "dedicated_write_after_drain": dedicated_format == "dedicated" and dedicated_read,
                "switch_back_legacy_write_preserves_dedicated": legacy_write_format == "legacy" and legacy_read and candidate_reads_switchback_legacy and dedicated_hash_before_switchback == dedicated_hash_after_switchback,
                "old_code_rejects_dedicated": isolated_old_status == 401,
                "rollback_retains_dedicated_reads": rollback_status,
                "old_code_legacy_control_succeeded": old_legacy_control,
                "legacy_hash_preserved": bool(legacy_hash), "dedicated_hash_present": bool(dedicated_hash),
                "old_process_pid": old_pid, "candidate_process_pid": new_pid,
                "candidate_legacy_overlap_pid": overlap_candidate_pid,
                "candidate_dedicated_activation_pid": dedicated_candidate_pid,
                "candidate_compatible_rollback_pid": rollback_candidate_pid,
                "legacy_writer_pid": legacy_pid, "isolated_old_process_pid": isolated_old_pid,
                "fleet_parity_proven": False, "quiescence_proven": False, "backup_proven": False,
            }
            receipt = _receipt("rollout", pair, store, run_id, candidate_identity, candidate, new_host,
                               new_env, old_identity, old_package, old_host, old_env, old_proof, observation)
            return _write_receipt(receipt_dir, receipt, redactor)
        except Exception as error:
            _write_failure_attempt(receipt_dir, "rollout", pair, store, run_id, error, redactor,
                                   candidate_identity=locals().get("candidate_identity"),
                                   predecessor_identity=locals().get("old_identity"),
                                   log_paths=list(root.glob("*.log")))
            raise
        finally:
            for process in (old_server, new_server, legacy_server):
                if process is not None and process.poll() is None:
                    process.terminate()
                    try: process.wait(timeout=5)
                    except subprocess.TimeoutExpired: process.kill(); process.wait()
            for host, env in ((old_host, old_env), (new_host, new_env), (legacy_host, legacy_env)):
                try: run_child_command(host, env, "ecto.drop")
                except (PackageInputError, UnboundLocalError): pass


def _run_public_control(receipt_dir: Path) -> dict[str, object]:
    run_id = uuid.uuid4().hex
    port_old, port_new = allocate_port(), allocate_port()
    prefix = "vrp" + run_id[:12]
    database_url = clean_room_database_url("verifier_public")
    key = runner.base64.b64encode(os.urandom(32)).decode("ascii")
    redactor = Redactor(SentinelSet.for_run())
    redactor.register_material(key)
    old_server = new_server = None
    with tempfile.TemporaryDirectory(prefix="lockspire-public-verifier-control-") as temporary:
        root = Path(temporary)
        public_tarball = PUBLIC_TARBALL if PUBLIC_TARBALL.is_file() and sha256(PUBLIC_TARBALL) == PUBLIC_SHA256 else root / "public-1.6.1.tar"
        if public_tarball != PUBLIC_TARBALL:
            try:
                with urllib.request.urlopen("https://repo.hex.pm/tarballs/lockspire-1.6.1.tar", timeout=30) as response:
                    public_tarball.write_bytes(response.read())
            except (OSError, urllib.error.URLError):
                raise PackageInputError("pinned public Lockspire 1.6.1 artifact is unavailable or changed") from None
        if not public_tarball.is_file() or sha256(public_tarball) != PUBLIC_SHA256:
            raise PackageInputError("pinned public Lockspire 1.6.1 artifact is unavailable or changed")
        if not verify_public_artifact(public_tarball, PUBLIC_SHA256, PUBLIC_SOURCE):
            raise PackageInputError("retained public release source evidence is unavailable")
        old_package = root / "public-package"
        unpack_hex_tarball(public_tarball, old_package)
        if package_version(old_package) != "1.6.1":
            raise PackageInputError("pinned public archive is not Lockspire 1.6.1")
        public_tree = package_tree_digest(old_package)
        old_identity = PackageIdentity("public-hex", "1.6.1", PUBLIC_SHA256, PUBLIC_SHA256,
                                       public_tree, PUBLIC_SOURCE, runner.source_revision(), None)
        candidate, _entries, candidate_identity = prepare_package(root / "candidate", PackageSource("checkout"))
        candidate_archive = candidate.parent / f"lockspire-{candidate_identity.version}.tar"
        verify_candidate_input(candidate_archive, candidate, candidate_identity)
        old_host = prepare_provider(root / "public", database_url, package_root=old_package,
                                    port=port_old, storage_prefix=prefix, candidate_identity=old_identity,
                                    scenario_groups={"legacy-control"})
        new_host = prepare_provider(root / "adopter", database_url, package_root=candidate,
                                    port=port_new, storage_prefix=prefix, candidate_identity=candidate_identity,
                                    scenario_groups={"legacy-control"})
        _configure(host=old_host, mode="legacy", legacy_read="allow", key=key)
        _configure(host=new_host, mode="dedicated", legacy_read="allow", key=key)
        old_env = runner._mix_env(old_host, root / "public", database_url, port_old, f"http://127.0.0.1:{port_old}/lockspire", prefix, key, "locked")
        new_env = runner._mix_env(new_host, root / "adopter", database_url, port_new, f"http://127.0.0.1:{port_new}/lockspire", prefix, key, "locked")
        old_env["CLEAN_ROOM_HTTP_SERVER"] = "false"
        new_env["CLEAN_ROOM_HTTP_SERVER"] = "false"
        redactor.register_material(database_url)
        try:
            run_child_command(old_host, old_env, "ecto.create")
            run_child_command(old_host, old_env, "ecto.migrate")
            old_server, old_pid = _start_server(old_host, old_env, root / "public.log", old_env["LOCKSPIRE_ISSUER"])
            client_id = "public-legacy-" + run_id
            client_id, secret = runner._capture_secret(old_host, old_env, redactor, client_id)
            _stop_owned_server(old_server)
            old_server = None
            run_child_command(new_host, new_env, "ecto.migrate")
            legacy_format, old_hash = _safe_row(new_host, new_env, prefix, client_id)
            old_deadline = _safe_deadline(new_host, new_env, prefix, client_id)
            old_age_kind = _projection(new_host, new_env, prefix, client_id)["age_kind"]
            _configure(host=new_host, mode="dedicated", legacy_read="allow", key=key)
            run_child_command(new_host, new_env, "lockspire.clients.verifier.rewrap", "--limit", "100")
            runner._provision_signing_key(new_host, new_env)
            new_server, candidate_pid = _start_server(new_host, new_env, root / "adopter.log", new_env["LOCKSPIRE_ISSUER"])
            http_ok, http_failure = _http_auth_result(new_env["LOCKSPIRE_ISSUER"], port_new, client_id, secret)
            promoted_format, new_hash = _safe_row(new_host, new_env, prefix, client_id)
            new_deadline = _safe_deadline(new_host, new_env, prefix, client_id)
            new_age_kind = _projection(new_host, new_env, prefix, client_id)["age_kind"]
            observation = {
                "outcome": "pass", "executed": True, "public_pin_verified": True,
                "release_source_evidence": "documented-public-release-source",
                "lifetime_prerequisite_migrated": True, "verifier_specific_adoption_executed": True,
                "http_authentication_succeeded": http_ok,
                "http_auth_failure": http_failure,
                "legacy_format_before": legacy_format, "dedicated_format_after": promoted_format,
                "authenticated_age_kind_before": old_age_kind, "authenticated_age_kind_after": new_age_kind,
                "authenticated_deadline_preserved": old_deadline is not None and old_deadline == new_deadline,
                "client_hash_preserved": bool(old_hash) and old_hash == new_hash,
                "old_process_pid": old_pid, "candidate_process_pid": candidate_pid,
                "coverage": "locked-only bounded public legacy producer/adopter control",
            }
            if not (http_ok and legacy_format == "legacy" and promoted_format == "dedicated" and
                    old_age_kind == "migrated" and new_age_kind == "migrated" and
                    observation["authenticated_deadline_preserved"] and observation["client_hash_preserved"]):
                raise PackageInputError(
                    "public legacy verifier adoption or preservation observation failed "
                    f"(http_auth={str(http_ok).lower()};http_failure={http_failure or 'none'};"
                    f"before_format={legacy_format};after_format={promoted_format};"
                    f"before_age={old_age_kind};after_age={new_age_kind};"
                    f"deadline_preserved={str(observation['authenticated_deadline_preserved']).lower()};"
                    f"hash_preserved={str(observation['client_hash_preserved']).lower()})"
                )
            proof = {"public_source": PUBLIC_SOURCE, "release_record_sha256": sha256(PUBLIC_RELEASE_RECORD),
                     "release_evidence_sha256": sha256(PUBLIC_RELEASE_EVIDENCE),
                     "terminal_receipt_sha256": sha256(PUBLIC_TERMINAL_RECEIPT),
                     "archive_sha256": sha256(public_tarball), "package_tree_sha256": public_tree,
                     "source_commit_tree": _git_commit_tree(PUBLIC_SOURCE),
                     "source_claim": "public package files byte-match independently exported source commit"}
            receipt = _receipt("legacy-control", "locked", "builtin", run_id, candidate_identity,
                               candidate, new_host, new_env, old_identity, old_package, old_host,
                               old_env, proof, observation)
            return _write_receipt(receipt_dir, receipt, redactor)
        except Exception as error:
            _write_failure_attempt(receipt_dir, "legacy-control", "locked", "builtin", run_id, error,
                                   redactor, candidate_identity=locals().get("candidate_identity"),
                                   predecessor_identity=locals().get("old_identity"),
                                   log_paths=list(root.glob("*.log")))
            raise
        finally:
            for process in (old_server, new_server):
                if process is not None and process.poll() is None:
                    process.terminate()
                    try: process.wait(timeout=5)
                    except subprocess.TimeoutExpired: process.kill(); process.wait()
            for host, env in ((old_host, old_env), (new_host, new_env)):
                try: run_child_command(host, env, "ecto.drop")
                except (PackageInputError, UnboundLocalError): pass


def _configure(*, host: Path, mode: str, legacy_read: str, key: str) -> None:
    runtime = host / "config" / "runtime.exs"
    original = runtime.read_text(encoding="utf-8")
    markers = (
        "config :clean_room_provider, CleanRoomProviderWeb.Endpoint,\n  server: System.get_env(\"CLEAN_ROOM_HTTP_SERVER\", \"false\") == \"true\"",
        "config :lockspire, Lockspire.Security.ClientSecretVerifier,",
    )
    positions = [original.index(marker) for marker in markers if marker in original]
    if positions:
        original = original[:min(positions)].rstrip() + "\n"
    runtime.write_text(original + f'''\nconfig :clean_room_provider, CleanRoomProviderWeb.Endpoint,
  server: System.get_env("CLEAN_ROOM_HTTP_SERVER", "false") == "true"

config :lockspire, Lockspire.Security.ClientSecretVerifier,
  keys: [{{"verifier-old", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY")}}],
  current: "verifier-old",
  write_mode: :{mode},
  legacy_read: :{legacy_read}
''', encoding="utf-8")


def _start_server(host: Path, env: dict[str, str], log_path: Path | None, issuer: str):
    server_env = _server_environment(env)
    process = None
    try:
        process = start_owned_session(("mix", "run", "--no-halt"), cwd=host, env=server_env,
                                      stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                                      stderr=subprocess.DEVNULL)
        deadline = time.monotonic() + 35
        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise PackageInputError("installed process exited before HTTP readiness")
            try:
                with urllib.request.urlopen(issuer + "/.well-known/openid-configuration", timeout=1) as response:
                    if response.status == 200:
                        return process, process.pid
            except OSError:
                time.sleep(0.15)
        raise PackageInputError("installed process did not become HTTP ready")
    except BaseException:
        if process is not None and process.poll() is None:
            _stop_owned_server(process)
        raise


def _stop_owned_server(process) -> None:
    if process is None:
        return
    if not stop_process_group(process, grace=10):
        raise PackageInputError("installed process group cleanup could not be confirmed")


def _server_environment(env: dict[str, str]) -> dict[str, str]:
    server_env = dict(env)
    server_env["CLEAN_ROOM_HTTP_SERVER"] = "true"
    return server_env


def _safe_row(host: Path, env: dict[str, str], prefix: str, client_id: str) -> tuple[str, str | None]:
    values = _projection(host, env, prefix, client_id)
    return values["format"], values["hash_digest"]


def _safe_deadline(host: Path, env: dict[str, str], prefix: str, client_id: str) -> str | None:
    return _projection(host, env, prefix, client_id)["deadline"]


def _projection(host: Path, env: dict[str, str], prefix: str, client_id: str) -> dict[str, str | None]:
    output = run_child_command_output(
        host, env, "run", "--no-start", "test/clean_room/verifier_rollout.exs", "--", prefix, client_id
    )
    return _parse_projection_output(output)


def _parse_projection_output(output: str) -> dict[str, str | None]:
    marker = next((line for line in output.splitlines() if line.startswith("ROW_FORMAT=")), None)
    if marker is None:
        raise PackageInputError("safe persisted row projection unavailable")
    fields = dict(part.split("=", 1) for part in marker.split(";") if "=" in part)
    row_format = fields.get("format", fields.get("ROW_FORMAT"))
    hash_digest = fields.get("hash_digest", fields.get("HASH_DIGEST"))
    deadline = fields.get("deadline_ms", fields.get("DEADLINE_MS"))
    if row_format not in {"legacy", "dedicated"} or not hash_digest or not re.fullmatch(r"[0-9a-f]{64}", hash_digest):
        age_kind = fields.get("age_kind", fields.get("AGE_KIND", "unavailable"))
        age_error = fields.get("age_error", fields.get("AGE_ERROR", "unavailable"))
        digest_present = bool(hash_digest and re.fullmatch(r"[0-9a-f]{64}", hash_digest))
        raise PackageInputError(
            "persisted rollout row is missing a safe hash witness "
            f"(format={row_format or 'unavailable'};hash_digest_present={str(digest_present).lower()};"
            f"age_kind={age_kind};age_error={age_error})"
        )
    age_kind = fields.get("age_kind", fields.get("AGE_KIND"))
    signed_at = fields.get("signed_at_ms", fields.get("SIGNED_AT_MS"))
    return {"format": row_format, "hash_digest": hash_digest, "age_kind": age_kind,
            "signed_at_ms": None if signed_at in {None, "nil", "missing", "unavailable"} else signed_at,
            "deadline": None if deadline in {None, "nil", "missing", "unavailable"} else deadline}


def _http_auth(issuer: str, port: int, client_id: str, secret: str) -> bool:
    passed, _failure = _http_auth_result(issuer, port, client_id, secret)
    return passed


def _http_auth_result(issuer: str, port: int, client_id: str, secret: str) -> tuple[bool, str | None]:
    try:
        _redirect_uri, verifier, code = runner._authorization_code(
            issuer, port, client_id, Redactor(SentinelSet.for_run()), remember=False
        )
        ok, status, _ = runner._token_request(issuer, client_id, secret, _redirect_uri, verifier, code, Redactor(SentinelSet.for_run()))
        return (True, None) if status == 200 and ok else (False, f"token-http-{status}")
    except PackageInputError as error:
        match = re.search(r"installed token http returned status ([0-9]{3})(?: \((invalid_client|invalid_grant|invalid_request|server_error|temporarily_unavailable)\))?", str(error), re.IGNORECASE)
        if match:
            failure = f"token-http-{match.group(1)}" + (f"-{match.group(2).lower()}" if match.group(2) else "")
            for description, suffix in {
                "Client authentication failed": "client-authentication-failed",
                "Client application has expired": "client-application-expired",
                "Client application is disabled": "client-application-disabled",
                "Unable to validate client lifetime state": "client-lifetime-state-unavailable",
                "Unable to validate client secret lifetime state": "client-secret-lifetime-state-unavailable",
                "Unable to persist request": "request-persistence-failed",
                "Unable to validate client": "client-validation-failed",
            }.items():
                if description in str(error) and description in runner.SAFE_OAUTH_DESCRIPTIONS:
                    failure += "-" + suffix
                    break
            return False, failure
        return False, "authorization-flow-failed"
    except OSError:
        return False, "http-transport-failed"


def _old_code_probe(host: Path, env: dict[str, str], client_id: str, secret: str) -> int:
    # The old compiled host uses its installed package and cannot decode LSCV1.
    try:
        _uri, verifier, code = runner._authorization_code(
            env["LOCKSPIRE_ISSUER"], int(env["PORT"]), client_id,
            Redactor(SentinelSet.for_run()), remember=False
        )
        runner._token_request(env["LOCKSPIRE_ISSUER"], client_id, secret, _uri, verifier, code, Redactor(SentinelSet.for_run()))
        return 200
    except PackageInputError as error:
        return _classify_old_code_rejection(str(error))


def _classify_old_code_rejection(error: str) -> int:
    message = error.lower()
    return 401 if "installed token http returned status 401" in message and "invalid_client" in message else 0


def verify_public_artifact(archive: Path, expected_sha256: str, source_revision: str) -> bool:
    """Bind the pinned public tarball's packaged files to its independently named source commit."""
    if not archive.is_file() or sha256(archive) != expected_sha256:
        return False
    if not all(path.is_file() for path in (PUBLIC_RELEASE_RECORD, PUBLIC_RELEASE_EVIDENCE, PUBLIC_TERMINAL_RECEIPT)):
        return False
    try:
        evidence = PUBLIC_RELEASE_EVIDENCE.read_text(encoding="utf-8")
        release = PUBLIC_RELEASE_RECORD.read_text(encoding="utf-8")
        terminal = json.loads(PUBLIC_TERMINAL_RECEIPT.read_text(encoding="utf-8"))
        if source_revision not in evidence or source_revision not in release:
            return False
        if terminal.get("source_sha") != source_revision or terminal.get("artifact", {}).get("sha256") != expected_sha256:
            return False
        with tempfile.TemporaryDirectory(prefix="lockspire-public-source-proof-") as temporary:
            root = Path(temporary)
            package = root / "package"
            source = root / "source"
            unpack_hex_tarball(archive, package)
            source.mkdir(mode=0o700)
            exported = subprocess.run(("git", "archive", "--format=tar", source_revision), cwd=PROJECT_ROOT,
                                      stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                      check=False, timeout=60)
            if exported.returncode:
                return False
            tar_path = root / "source.tar"
            tar_path.write_bytes(exported.stdout)
            unpacked = subprocess.run(("tar", "-xf", str(tar_path), "-C", str(source)), cwd=PROJECT_ROOT,
                                      stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                      check=False, timeout=60)
            if unpacked.returncode:
                return False
            for path in package.rglob("*"):
                if not path.is_file() or path.relative_to(package).as_posix() == "hex_metadata.config":
                    continue
                source_path = source / path.relative_to(package)
                if not source_path.is_file() or source_path.read_bytes() != path.read_bytes():
                    return False
        return True
    except (OSError, ValueError, PackageInputError, subprocess.SubprocessError):
        return False


def _git_commit_tree(revision: str) -> str:
    return subprocess.check_output(("git", "rev-parse", f"{revision}^{{tree}}"), cwd=PROJECT_ROOT, text=True).strip()


def _receipt(scope, pair, store, run_id, candidate_identity, candidate, new_host, new_env,
             old_identity, old_package, old_host, old_env, source_proof, observations):
    return {
        "schema": "lockspire-installed-verifier-rollout-v1", "scope": scope, "run_id": run_id,
        "runner_revision": runner.source_revision(), "pair": pair, "store": store,
        "candidate": {"kind": candidate_identity.kind, "version": candidate_identity.version,
                      "archive_sha256": candidate_identity.archive_sha256, "tree_sha256": candidate_identity.tree_sha256,
                      "source_revision": candidate_identity.source_revision, "runner_revision": candidate_identity.runner_revision,
                      "source_proof": candidate_identity.source_proof,
        **runner.candidate_host_provenance(new_host)},
        "predecessor": {"kind": old_identity.kind, "version": old_identity.version,
                        "archive_sha256": old_identity.archive_sha256, "tree_sha256": old_identity.tree_sha256,
                        "source_revision": old_identity.source_revision,
                        **({"compiled_candidate_sha256": _compiled_identity(old_host)} if (old_host / ".lockspire-candidate.json").is_file() else {})},
        "source_proof": source_proof, "host": {"lock_sha256": sha256(runner.PROOF_PAIR_LOCKS[pair]),
        "phoenix": runner._framework_versions(new_host, new_env)[0], "live_view": runner._framework_versions(new_host, new_env)[1]},
        "runtime": {"elixir": runner._actual_runtime(new_host, new_env)[0], "otp": runner._actual_runtime(new_host, new_env)[1],
                    "postgresql": runner._actual_runtime(new_host, new_env)[2]},
        "processes": {"predecessor": {"pid": observations.pop("old_process_pid", None), "compiled_candidate_sha256": _compiled_identity(old_host)},
                      "candidate": {"pid": observations.pop("candidate_process_pid", None), "compiled_candidate_sha256": _compiled_identity(new_host)}},
        "observations": observations, "executed_count": 1, "partial": True,
        "fleet_limits": ["fleet parity", "fleet quiescence", "backup availability", "rollback safety"],
    }


def _compiled_identity(host: Path) -> str | None:
    try: return json.loads((host / ".lockspire-candidate.json").read_text())["compiled_candidate_sha256"]
    except (OSError, ValueError, KeyError): return None


def _write_receipt(receipt_dir: Path, receipt: dict[str, object], redactor: Redactor):
    redactor.assert_safe(json.dumps(receipt, sort_keys=True))
    receipt_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    path = receipt_dir / "receipt.json"
    path.write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    receipt["receipt_path"] = str(path)
    print(json.dumps({"scope": receipt["scope"], "pair": receipt["pair"], "store": receipt["store"],
                      "executed_count": 1, "receipt": str(path)}, sort_keys=True), flush=True)
    return receipt


def _write_failure_attempt(receipt_dir: Path, scope: str, pair: str, store: str, run_id: str,
                           error: Exception, redactor: Redactor, *, candidate_identity=None,
                           predecessor_identity=None, log_paths: list[Path] | None = None) -> None:
    """Retain each new failed cell with redacted command, exit and artifact identities."""
    # Keep child diagnostics private. A redactor cannot recognize every
    # generated credential or application-specific secret, so durable
    # failures contain only byte counts and hashes.
    log_summaries = []
    for log_path in log_paths or []:
        try:
            raw = log_path.read_bytes()
        except OSError:
            continue
        log_summaries.append({"name": log_path.name, "bytes": len(raw),
                              "sha256": hashlib.sha256(raw).hexdigest()})
    record = {
        "schema": "lockspire-installed-verifier-rollout-failure-v1",
        "scope": scope, "pair": pair, "store": store, "run_id": run_id,
        "runner_revision": runner.source_revision(),
        "candidate_source_revision": getattr(candidate_identity, "source_revision", None),
        "candidate_archive_sha256": getattr(candidate_identity, "archive_sha256", None),
        "predecessor_source_revision": getattr(predecessor_identity, "source_revision", None),
        "command": ["python3", "scripts/acceptance/clean_room_verifier_upgrade.py", "--pair", pair,
                    "--store", store, "--group", scope],
        "exit_code": 1, "error_type": type(error).__name__,
        "process_logs": log_summaries,
        "attempted_at_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
    }
    rendered = json.dumps(record, sort_keys=True, indent=2) + "\n"
    receipt_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    path = receipt_dir / f"{scope}-{pair}-{store}-{run_id}.failure.json"
    path.write_text(rendered, encoding="utf-8")
    os.chmod(path, 0o600)


def _git_commit_exists(revision: str) -> bool:
    completed = subprocess.run(("git", "cat-file", "-e", revision + "^{commit}"), cwd=PROJECT_ROOT,
                               stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                               check=False)
    return completed.returncode == 0
