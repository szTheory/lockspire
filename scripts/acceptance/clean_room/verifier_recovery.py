"""Installed verifier custody recovery and authenticated issuance proof groups."""

from __future__ import annotations

import base64
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import uuid

from package_input import (
    PackageInputError, PackageSource, clean_room_database_url, prepare_package,
    sha256, source_revision, verify_candidate_input,
)
from redaction import Redactor, SentinelSet
from build_provider import (
    PROOF_PAIR_LOCKS, allocate_port, prepare_provider, run_child_command,
    run_child_command_output,
)
import clean_room_verifier_upgrade as runner
from verifier_receipts import validate_receipt


RECOVERY_CASES = (
    "VPROOF-02-RECOVERY-PRESERVATION",
    "VPROOF-02-RECOVERY-RETRY-RECONCILIATION",
    "VPROOF-02-RECOVERY-RESTORE-ROTATE",
    "VPROOF-02-RECOVERY-EXPIRED-MIGRATION",
)
ISSUANCE_CASES = (
    "VPROOF-02-ISSUANCE-LOCKED-STALE-IDENTITY",
    "VPROOF-02-ISSUANCE-FLOOR-STALE-IDENTITY",
)
SAFE_FAILURE_STAGES = frozenset({
    "recovery_seed", "recovery_apply", "recovery_repeat", "recovery_interrupt",
    "recovery_indeterminate", "recovery_restore_rotation", "recovery_expired_migration",
    "expired_seed", "expired_legacy_ciphertext", "expired_install_legacy", "expired_apply",
    "expired_http", "expired_metadata",
    "issuance_seed", "issuance_auth_barrier", "issuance_maintenance", "issuance_replay_fresh",
})


def run_recovery_group(*, pair: str, store: str, receipt_dir: Path) -> list[dict[str, object]]:
    return _run_group(scope="recovery", pairs=pair, stores=store, receipt_dir=receipt_dir)


def run_issuance_group(*, pair: str, store: str, receipt_dir: Path) -> list[dict[str, object]]:
    if store not in {"all", "delegated"}:
        raise PackageInputError("installed issuance proof requires delegated PostgreSQL storage")
    return _run_group(scope="issuance", pairs=pair, stores="delegated", receipt_dir=receipt_dir)


def _run_group(*, scope: str, pairs: str, stores: str, receipt_dir: Path) -> list[dict[str, object]]:
    selected_pairs = ("locked", "floor") if pairs == "all" else (pairs,)
    selected_stores = ("builtin", "delegated") if stores == "all" else (stores,)
    if any(item not in {"locked", "floor"} for item in selected_pairs):
        raise PackageInputError("unsupported verifier recovery dependency pair")
    if any(item not in {"builtin", "delegated"} for item in selected_stores):
        raise PackageInputError("unsupported verifier recovery storage composition")
    if scope == "issuance" and selected_stores != ("delegated",):
        raise PackageInputError("installed issuance proof requires delegated PostgreSQL storage")

    receipts = []
    for selected_pair in selected_pairs:
        for selected_store in selected_stores:
            cell = _run_cell(scope, selected_pair, selected_store, receipt_dir / f"{selected_pair}-{selected_store}")
            receipts.append(cell)
    print(json.dumps({"scope": scope, "executed_count": len(receipts), "cells": [
        {"pair": row["pair"], "store": row["store"], "receipt": str(receipt_dir / f"{row['pair']}-{row['store']}" / "receipt.json")}
        for row in receipts
    ]}, sort_keys=True))
    return receipts


def _run_cell(scope: str, pair: str, store: str, destination: Path) -> dict[str, object]:
    port = allocate_port()
    prefix = "vfy" + uuid.uuid4().hex[:14]
    database_url = clean_room_database_url("verifier_recovery")
    issuer = f"http://127.0.0.1:{port}/lockspire"
    old_key = base64.b64encode(os.urandom(32)).decode("ascii")
    new_key = base64.b64encode(os.urandom(32)).decode("ascii")
    redactor = Redactor(SentinelSet.for_run())
    redactor.register_material(old_key)
    redactor.register_material(new_key)
    host = None

    with tempfile.TemporaryDirectory(prefix=f"lockspire-verifier-{scope}-{pair}-{store}-") as temporary:
        root = Path(temporary)
        package, _entries, identity = prepare_package(root, PackageSource("checkout"))
        archive = package.parent / f"lockspire-{identity.version}.tar"
        verify_candidate_input(archive, package, identity)
        host = prepare_provider(
            root, database_url, package_root=package, port=port,
            storage_prefix=prefix, candidate_identity=identity,
            custom_lifetime_adapter=store == "delegated", proof_pair=pair,
            scenario_groups={scope}, mount_path="/lockspire",
        )
        runner._configure_verifier_custody(host)
        runner._configure_rewrap_verifier_custody(host)
        if scope == "recovery":
            _allow_legacy_custody_rewrap(host)
        env = runner._mix_env(host, root, database_url, port, issuer, prefix, old_key, pair)
        env["LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY_NEXT"] = new_key
        redactor.register_material(database_url)
        try:
            _safe_host_call(lambda: run_child_command(host, env, "ecto.create"))
            _safe_host_call(lambda: run_child_command(host, env, "ecto.migrate", "--migrations-path", "priv/repo/migrations"))
            _safe_host_call(lambda: runner._provision_signing_key(host, env))
            lock_hash = sha256(PROOF_PAIR_LOCKS[pair])
            phoenix, live_view = _safe_host_call(lambda: runner._framework_versions(host, env))
            elixir, otp, postgres = _safe_host_call(lambda: runner._actual_runtime(host, env))
            command = "recovery" if scope == "recovery" else "issuance"
            env["LOCKSPIRE_PROOF_PAIR"] = pair
            expression = (
                f"result = CleanRoomProvider.VerifierRecovery.run_{command}(:{store}, {json.dumps(issuer)}); "
                'IO.puts("VERIFIER_PROOF_JSON=" <> Jason.encode!(result))'
            )
            output = _capture_child_output(
                lambda: run_child_command_output(host, env, "run", "-e", expression)
            )
            observations = _parse_observations(output, redactor)
            case_ids = list(RECOVERY_CASES if scope == "recovery" else (f"VPROOF-02-ISSUANCE-{pair.upper()}-STALE-IDENTITY",))
            if set(observations) != set(case_ids):
                raise PackageInputError("installed verifier group omitted a required scenario")
            candidate = {
                "kind": identity.kind, "version": identity.version,
                "archive_sha256": identity.archive_sha256, "tree_sha256": identity.tree_sha256,
                "source_revision": identity.source_revision, "runner_revision": identity.runner_revision,
                "source_proof": identity.source_proof,
            }
            receipt = {
                "schema": "lockspire-installed-verifier-v1", "scope": scope,
                "run_id": uuid.uuid4().hex, "runner": source_revision(), "pair": pair,
                "store": store, "candidate": candidate,
                "host": {**runner.candidate_host_provenance(host), "lock_sha256": lock_hash,
                         "phoenix": phoenix, "live_view": live_view},
                "runtime": {"elixir": elixir, "otp": otp, "postgresql": postgres},
                "stable_case_ids": case_ids, "observations": observations,
                "executed_count": len(case_ids), "partial": True,
            }
            validate_receipt(receipt, expected_pair=pair, expected_store=store)
            redactor.assert_safe(json.dumps(receipt, sort_keys=True))
            destination.mkdir(mode=0o700, parents=True, exist_ok=True)
            (destination / "receipt.json").write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n", encoding="utf-8")
            return receipt
        finally:
            try:
                run_child_command(host, env, "ecto.drop")
            except PackageInputError:
                pass


def _parse_observations(output: str, redactor: Redactor) -> dict[str, object]:
    safe = redactor.text(output)
    redactor.assert_safe(safe)
    matches = re.findall(r"^VERIFIER_PROOF_JSON=(\{.*\})$", safe, re.MULTILINE)
    if len(matches) != 1:
        raise PackageInputError("installed verifier group returned no unique safe outcome object")
    try:
        return json.loads(matches[0])
    except json.JSONDecodeError:
        raise PackageInputError("installed verifier group outcome object is malformed") from None


def _allow_legacy_custody_rewrap(host: Path) -> None:
    runtime_config = host / "config" / "runtime.exs"
    content = runtime_config.read_text(encoding="utf-8")
    marker = 'config :lockspire, Lockspire.Security.ClientSecretVerifier,'
    if content.count(marker) != 1 or content.count("legacy_read: :reject") != 1:
        raise PackageInputError("recovery host verifier configuration shape changed")
    runtime_config.write_text(content.replace("legacy_read: :reject", "legacy_read: :allow", 1), encoding="utf-8")


def _capture_child_output(operation) -> str:
    try:
        return operation()
    except Exception as error:
        safe_stage = next(
            (stage for stage in SAFE_FAILURE_STAGES if f"SAFE_FAILURE_STAGE={stage}" in str(error)),
            None,
        )
        reason = "installed verifier host scenario failed"
        if safe_stage is not None:
            reason += f" at {safe_stage}"
        raise PackageInputError(reason + "; child diagnostics withheld") from None


def _safe_host_call(operation):
    try:
        return operation()
    except Exception:
        raise PackageInputError("installed verifier host setup failed; child diagnostics withheld") from None


def _validate_group_receipt(receipt: dict[str, object]) -> None:
    case_ids = RECOVERY_CASES if receipt.get("scope") == "recovery" else (f"VPROOF-02-ISSUANCE-{receipt.get('pair', '').upper()}-STALE-IDENTITY",)
    if receipt.get("stable_case_ids") != list(case_ids):
        raise PackageInputError("installed verifier receipt case set is invalid")
    observations = receipt.get("observations")
    if not isinstance(observations, dict) or set(observations) != set(case_ids):
        raise PackageInputError("installed verifier receipt observations are incomplete")
    for observation in observations.values():
        if not isinstance(observation, dict) or observation.get("outcome") != "pass" or observation.get("executed") is not True:
            raise PackageInputError("installed verifier scenario did not pass")
