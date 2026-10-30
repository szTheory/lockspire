"""Installed fresh-host and verifier maintenance proof for the supported core cells."""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import subprocess
import sys
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
    PackageSource,
    bounded_run,
    clean_room_database_url,
    prepare_package,
    sha256,
    source_revision,
    start_owned_session,
    verify_candidate_input,
)
from redaction import Redactor, SentinelSet  # noqa: E402
from verifier_receipts import validate_receipt  # noqa: E402


CORE_CASE_ID = "VPROOF-02-CORE-FRESH-MAINTENANCE"
CORE_OBSERVATION_FIELDS = {
    "outcome",
    "executed",
    "http_status",
    "token_issued",
    "dedicated_verifier_persisted",
    "fresh_signed_assertion",
    "dry_run_reported",
    "dry_run_unchanged",
    "apply_committed",
    "fresh_check_ready",
    "authority_rejections_before_access",
    "unknown_material_rejected",
    "partial_inventory_rejected",
    "delegated_callbacks_observed",
    "client_hash_preserved",
}


def run_group(*, pair: str, store: str, receipt_dir: Path) -> list[dict[str, object]]:
    pairs = ("locked", "floor") if pair == "all" else (pair,)
    stores = ("builtin", "delegated") if store == "all" else (store,)
    if any(item not in {"locked", "floor"} for item in pairs):
        raise PackageInputError("unsupported core dependency pair")
    if any(item not in {"builtin", "delegated"} for item in stores):
        raise PackageInputError("unsupported core storage composition")

    receipts = []
    for selected_pair in pairs:
        for selected_store in stores:
            destination = receipt_dir / f"{selected_pair}-{selected_store}"
            receipts.append(
                _run_cell(pair=selected_pair, store=selected_store, receipt_dir=destination)
            )
    print(
        json.dumps(
            {
                "scope": "core",
                "executed_count": len(receipts),
                "cells": [
                    {"pair": item["pair"], "store": item["store"], "receipt": str(receipt_dir / f"{item['pair']}-{item['store']}" / "receipt.json")}
                    for item in receipts
                ],
            },
            sort_keys=True,
        )
    )
    return receipts


def _run_cell(*, pair: str, store: str, receipt_dir: Path) -> dict[str, object]:
    port = allocate_port()
    prefix = "vfy" + uuid.uuid4().hex[:14]
    key = runner.base64.b64encode(os.urandom(32)).decode("ascii")
    database_url = clean_room_database_url("verifier_core")
    issuer = f"http://127.0.0.1:{port}/lockspire"
    redactor = Redactor(SentinelSet.for_run())
    redactor.register_material(key)
    server = None
    host: Path | None = None
    env: dict[str, str] = {}

    import tempfile

    with tempfile.TemporaryDirectory(prefix=f"lockspire-verifier-core-{pair}-{store}-") as temporary:
        run_root = Path(temporary)
        package, _entries, identity = prepare_package(run_root, PackageSource("checkout"))
        archive = package.parent / f"lockspire-{identity.version}.tar"
        verify_candidate_input(archive, package, identity)
        host = prepare_provider(
            run_root,
            database_url,
            package_root=package,
            port=port,
            storage_prefix=prefix,
            candidate_identity=identity,
            custom_lifetime_adapter=store == "delegated",
            proof_pair=pair,
            scenario_groups={"core"},
        )
        runner._configure_verifier_custody(host)
        env = runner._mix_env(host, run_root, database_url, port, issuer, prefix, key, pair)
        redactor.register_material(database_url)

        try:
            run_child_command(host, env, "ecto.create")
            run_child_command(host, env, "ecto.migrate", "--migrations-path", "priv/repo/migrations")
            runner._provision_signing_key(host, env)
            lock_hash = sha256(runner.PROOF_PAIR_LOCKS[pair])
            phoenix, live_view = runner._framework_versions(host, env)
            elixir, otp, pg = runner._actual_runtime(host, env)

            client_id = "verifier-core-" + uuid.uuid4().hex
            client_id, client_secret = runner._capture_secret(host, env, redactor, client_id)
            listener_env = runner.owned_listener_environment(env)
            server = start_owned_session(
                ("mix", "run", "--no-halt"), cwd=host, env=listener_env,
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
            _wait_ready(server, issuer)
            redirect_uri, verifier, code = runner._authorization_code(issuer, port, client_id, redactor)
            try:
                issued, http_status, _jti_digest = runner._token_request(
                    issuer, client_id, client_secret, redirect_uri, verifier, code, redactor
                )
            except PackageInputError as error:
                raise PackageInputError("installed core token flow failed; provider diagnostics withheld") from None
            persisted, _persisted_projection = runner._persisted_verifier(host, env, prefix, client_id)
            if not issued or not persisted:
                raise PackageInputError("installed core token or dedicated-verifier proof failed")

            _create_no_material_client(host, env)
            runner._configure_rewrap_verifier_custody(host)
            if store == "delegated":
                env["LOCKSPIRE_CORE_INVENTORY_MODE"] = "partial"
                partial_status, partial_output = _run_task(
                    host, env, ("--check", "--limit", "100"), redactor
                )
                partial_rejected = partial_status != 0 and _is_nonready_report(partial_output)
            else:
                partial_status, partial_output = _run_task(
                    host, env, ("--dry-run", "--after-client-id", client_id, "--limit", "100"), redactor
                )
                partial_rejected = (
                    partial_status == 0
                    and "progress_only=true" in partial_output
                    and "custody_condition_met=false" in partial_output
                )
            if not partial_rejected:
                raise PackageInputError("partial installed verifier run did not withhold readiness")
            env.pop("LOCKSPIRE_CORE_INVENTORY_MODE", None)

            before_hash = _client_hash(host, env, prefix, client_id)
            dry_status, dry_output = _run_task(host, env, ("--dry-run", "--limit", "100"), redactor)
            dry_run_reported = dry_status == 0 and "mode=dry_run" in dry_output and "pending=1" in dry_output
            dry_run_unchanged = before_hash == _client_hash(host, env, prefix, client_id)
            if not dry_run_reported or not dry_run_unchanged:
                raise PackageInputError("installed verifier preview did not preserve the client row")

            apply_status, apply_output = _run_task(host, env, ("--limit", "100"), redactor)
            apply_committed = apply_status == 0 and "mode=apply" in apply_output and "committed_changed=1" in apply_output
            after_hash = _client_hash(host, env, prefix, client_id)
            client_hash_preserved = before_hash == after_hash
            if not apply_committed or not client_hash_preserved:
                raise PackageInputError("installed verifier apply did not preserve the partner client-secret hash")

            check_status, check_output = _run_task(host, env, ("--check", "--limit", "100"), redactor)
            fresh_check_ready = check_status == 0 and "mode=check" in check_output and "custody_condition_met=true" in check_output
            if not fresh_check_ready:
                raise PackageInputError("fresh installed verifier custody check did not establish readiness")

            unknown_material_rejected = _exercise_unknown_material(host, env, prefix, client_id, redactor)
            if not unknown_material_rejected:
                raise PackageInputError("unknown verifier material did not fail installed readiness")

            authority_rejections_before_access = False
            delegated_callbacks_observed = False
            if store == "delegated":
                authority_rejections_before_access = _exercise_invalid_authorities(host, env, redactor)
                callback_counts = _callback_counts(dry_output + apply_output + check_output)
                delegated_callbacks_observed = (
                    authority_rejections_before_access
                    and callback_counts["verifier_inventory_page"] >= 3
                    and callback_counts["compare_and_rewrap"] >= 1
                )
                if not delegated_callbacks_observed:
                    raise PackageInputError("delegated verifier callbacks or authority rejection witness is incomplete")

            if server is not None and server.poll() is None:
                server.terminate()
                server.wait(timeout=5)
                server = None

            host_provenance = runner.candidate_host_provenance(host)
            receipt = {
                "schema": "lockspire-installed-verifier-v1",
                "scope": "core",
                "run_id": uuid.uuid4().hex,
                "runner": source_revision(),
                "pair": pair,
                "store": store,
                "candidate": {
                    "kind": identity.kind,
                    "version": identity.version,
                    "archive_sha256": identity.archive_sha256,
                    "tree_sha256": identity.tree_sha256,
                    "source_revision": identity.source_revision,
                    "runner_revision": identity.runner_revision,
                    "source_proof": identity.source_proof,
                },
                "host": {
                    **host_provenance,
                    "lock_sha256": lock_hash,
                    "phoenix": phoenix,
                    "live_view": live_view,
                },
                "runtime": {"elixir": elixir, "otp": otp, "postgresql": pg},
                "stable_case_ids": [CORE_CASE_ID],
                "observations": {
                    CORE_CASE_ID: {
                        "outcome": "pass",
                        "executed": True,
                        "http_status": http_status,
                        "token_issued": issued,
                        "dedicated_verifier_persisted": persisted,
                        "fresh_signed_assertion": True,
                        "dry_run_reported": dry_run_reported,
                        "dry_run_unchanged": dry_run_unchanged,
                        "apply_committed": apply_committed,
                        "fresh_check_ready": fresh_check_ready,
                        "authority_rejections_before_access": authority_rejections_before_access,
                        "unknown_material_rejected": unknown_material_rejected,
                        "partial_inventory_rejected": partial_rejected,
                        "delegated_callbacks_observed": delegated_callbacks_observed,
                        "client_hash_preserved": client_hash_preserved,
                    }
                },
                "executed_count": 1,
                "partial": True,
            }
            validate_receipt(receipt, expected_pair=pair, expected_store=store)
            redactor.assert_safe(json.dumps(receipt, sort_keys=True))
            receipt_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
            (receipt_dir / "receipt.json").write_text(
                json.dumps(receipt, sort_keys=True, indent=2) + "\n", encoding="utf-8"
            )
            print(
                json.dumps(
                    {"scope": "core", "pair": pair, "store": store, "executed_count": 1, "receipt": str(receipt_dir / "receipt.json")},
                    sort_keys=True,
                ),
                flush=True,
            )
            return receipt
        finally:
            if server is not None and server.poll() is None:
                server.terminate()
                try:
                    server.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait()
            if host is not None and host.exists():
                try:
                    run_child_command(host, env, "ecto.drop")
                except PackageInputError:
                    pass


def _wait_ready(server: subprocess.Popen, issuer: str) -> None:
    deadline = time.monotonic() + 25
    while time.monotonic() < deadline:
        if server.poll() is not None:
            raise PackageInputError("installed core host stopped before HTTP readiness")
        try:
            with urllib.request.urlopen(issuer + "/.well-known/openid-configuration", timeout=1) as response:
                if response.status == 200:
                    return
        except OSError:
            time.sleep(0.1)
    raise PackageInputError("installed core host did not become HTTP ready")


def _create_no_material_client(host: Path, env: dict[str, str]) -> None:
    code = (
        "{:ok, _apps} = Application.ensure_all_started(:ecto_sql); "
        "{:ok, _repo} = CleanRoomProvider.Repo.start_link(); "
        'attrs = %{client_id: "verifier-core-no-material", client_type: "public", '
        'name: "Core inventory control", redirect_uris: ["https://client.example/callback"], '
        'allowed_scopes: ["openid"], allowed_grant_types: ["authorization_code"], '
        'token_endpoint_auth_method: "none"}; '
        'case Lockspire.Clients.register_client(attrs) do '
        '{:ok, _result} -> IO.puts("NO_MATERIAL_CONTROL=created"); '
        '{:error, errors} -> Mix.raise("core control registration rejected: " <> Enum.map_join(errors, ",", &Atom.to_string(&1.reason))) end'
    )
    output = run_child_command_output(host, env, "run", "--no-start", "-e", code)
    if "NO_MATERIAL_CONTROL=created" not in output.splitlines():
        raise PackageInputError("installed non-JWT no-material inventory control was not created")


def _run_task(host: Path, env: dict[str, str], args: tuple[str, ...], redactor: Redactor) -> tuple[int, str]:
    completed = bounded_run(
        ("mix", "lockspire.clients.verifier.rewrap", *args),
        cwd=host,
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    output = completed.stdout.decode(errors="replace")
    safe_output = redactor.text(output)
    redactor.assert_safe(safe_output)
    return completed.returncode, safe_output


def _is_nonready_report(output: str) -> bool:
    return (
        "--check failed:" in output
        and "uninspected=" in output
        and "Current-key custody check passed." not in output
    )


def _client_hash(host: Path, env: dict[str, str], prefix: str, client_id: str) -> str:
    code = (
        "{:ok, _apps} = Application.ensure_all_started(:ecto_sql); "
        "{:ok, _repo} = CleanRoomProvider.Repo.start_link(); "
        f'result = Ecto.Adapters.SQL.query!(CleanRoomProvider.Repo, "SELECT client_secret_hash FROM {prefix}.lockspire_clients WHERE client_id = $1", ["{client_id}"]); '
        'case result.rows do [[value]] when is_binary(value) -> IO.puts("CLIENT_HASH_PRESENT=true"); '
        'IO.puts("CLIENT_HASH_LOCAL=" <> Base.encode64(:crypto.hash(:sha256, value))); '
        '_ -> Mix.raise("installed client hash projection missing") end'
    )
    output = run_child_command_output(host, env, "run", "--no-start", "-e", code)
    match = re.search(r"^CLIENT_HASH_LOCAL=([A-Za-z0-9+/=]+)$", output, re.MULTILINE)
    if not match:
        raise PackageInputError("installed client hash projection is incomplete")
    return match.group(1)


def _exercise_unknown_material(host: Path, env: dict[str, str], prefix: str, client_id: str, redactor: Redactor) -> bool:
    code = (
        "{:ok, _apps} = Application.ensure_all_started(:ecto_sql); "
        "{:ok, _repo} = CleanRoomProvider.Repo.start_link(); "
        f'Ecto.Adapters.SQL.query!(CleanRoomProvider.Repo, "UPDATE {prefix}.lockspire_clients SET client_secret_jwt_verifier_encrypted = $1 WHERE client_id = $2", ["LSCV1.unknown-key.AAAAAAAAAAAAAAAAAAAAAA", "{client_id}"]); '
        'IO.puts("UNKNOWN_MATERIAL_CONTROL=installed")'
    )
    run_child_command_output(host, env, "run", "--no-start", "-e", code)
    status, output = _run_task(host, env, ("--check", "--limit", "100"), redactor)
    return status != 0 and "classification=unknown_key" in output and "--check failed:" in output


def _exercise_invalid_authorities(host: Path, env: dict[str, str], redactor: Redactor) -> bool:
    code = (
        "{:ok, _apps} = Application.ensure_all_started(:ecto_sql); "
        "{:ok, _repo} = CleanRoomProvider.Repo.start_link(); "
        'for mode <- [:unsupported, :mismatch, :participant_mismatch] do '
        'Application.put_env(:clean_room_provider, :maintenance_declaration_mode, mode); '
        'result = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :dry_run, limit: 100); '
        'counts = CleanRoomProvider.LifetimeClientStore.callback_counts(); '
        'inventory = Map.get(counts, :verifier_inventory_page, 0); '
        'fetch = Map.get(counts, :fetch_client_by_id, 0); '
        'writes = Map.get(counts, :compare_and_rewrap, 0); '
        'rejected = match?({:error, _}, result); '
        'IO.puts("AUTHORITY_CONTROL=" <> Atom.to_string(mode) <> ":" <> to_string(rejected) <> ":" <> Integer.to_string(inventory) <> ":" <> Integer.to_string(fetch) <> ":" <> Integer.to_string(writes)); '
        'unless rejected and inventory == 0 and fetch == 0 and writes == 0, do: Mix.raise("authority control was not rejected before data access") '
        'end'
    )
    output = run_child_command_output(host, env, "run", "--no-start", "-e", code)
    safe = redactor.text(output)
    redactor.assert_safe(safe)
    expected = {
        "AUTHORITY_CONTROL=unsupported:true:0:0:0",
        "AUTHORITY_CONTROL=mismatch:true:0:0:0",
        "AUTHORITY_CONTROL=participant_mismatch:true:0:0:0",
    }
    return expected.issubset(set(safe.splitlines()))


def _callback_counts(output: str) -> dict[str, int]:
    return {
        name: output.count("LIFETIME_ADAPTER_CALLBACK " + name)
        for name in ("verifier_inventory_page", "compare_and_rewrap")
    }
