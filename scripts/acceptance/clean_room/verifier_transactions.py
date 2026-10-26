"""Installed PostgreSQL contention and atomicity witnesses for verifier maintenance."""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import uuid

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE))

import clean_room_verifier_upgrade as runner  # noqa: E402
from build_provider import PackageInputError, prepare_provider, run_child_command  # noqa: E402
from package_input import (  # noqa: E402
    PackageSource,
    clean_room_database_url,
    prepare_package,
    sha256,
    source_revision,
    verify_candidate_input,
)
from redaction import Redactor, SentinelSet  # noqa: E402
from verifier_receipts import (  # noqa: E402
    ATOMICITY_CASE_IDS,
    CONTENTION_CASE_IDS,
    validate_receipt,
)


def run_contention_group(*, pair: str, store: str, receipt_dir: Path) -> list[dict[str, object]]:
    return _run_group(scope="contention", pair=pair, store=store, receipt_dir=receipt_dir)


def run_atomicity_group(*, pair: str, store: str, receipt_dir: Path) -> list[dict[str, object]]:
    return _run_group(scope="atomicity", pair=pair, store=store, receipt_dir=receipt_dir)


def _run_group(*, scope: str, pair: str, store: str, receipt_dir: Path) -> list[dict[str, object]]:
    if pair not in {"locked", "floor", "all"} or store != "delegated":
        raise PackageInputError(f"{scope} requires a supported pair and delegated storage")
    pairs = ("locked", "floor") if pair == "all" else (pair,)
    receipts = []
    for selected_pair in pairs:
        cell_dir = receipt_dir / f"{selected_pair}-delegated"
        receipts.append(_run_cell(scope=scope, pair=selected_pair, receipt_dir=cell_dir))
    print(
        json.dumps(
            {
                "scope": scope,
                "executed_count": sum(item["executed_count"] for item in receipts),
                "cells": [
                    {"pair": item["pair"], "store": item["store"], "executed_count": item["executed_count"], "receipt": str(cell_dir / "receipt.json")}
                    for item, cell_dir in zip(receipts, (receipt_dir / f"{selected_pair}-delegated" for selected_pair in pairs))
                ],
            },
            sort_keys=True,
        ),
        flush=True,
    )
    return receipts


def _run_cell(*, scope: str, pair: str, receipt_dir: Path) -> dict[str, object]:
    run_id = uuid.uuid4().hex
    redactor = Redactor(SentinelSet.for_run())
    key = runner.base64.urlsafe_b64encode(os.urandom(32)).rstrip(b"=").decode("ascii")
    database_url = clean_room_database_url("verifier_transactions")
    redactor.register_material(key)
    redactor.register_material(database_url)
    with tempfile.TemporaryDirectory(prefix=f"lockspire-verifier-{scope}-{pair}-") as temporary:
        run_root = Path(temporary)
        package, _entries, identity = prepare_package(run_root, PackageSource("checkout"))
        archive = package.parent / f"lockspire-{identity.version}.tar"
        verify_candidate_input(archive, package, identity)
        prefix = "vfy" + uuid.uuid4().hex[:14]
        host = prepare_provider(
            run_root,
            database_url,
            package_root=package,
            storage_prefix=prefix,
            candidate_identity=identity,
            custom_lifetime_adapter=True,
            proof_pair=pair,
            scenario_groups={scope},
        )
        runner._configure_verifier_custody(host)
        runner._configure_rewrap_verifier_custody(host)
        _increase_owned_pool_for_contention(host)
        env = runner._mix_env(host, run_root, database_url, 0, "http://127.0.0.1/lockspire", prefix, key, pair)
        attempt_dir = receipt_dir / "attempts" / run_id
        attempt_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
        try:
            run_child_command(host, env, "ecto.create")
            run_child_command(host, env, "ecto.migrate", "--migrations-path", "priv/repo/migrations")
            run_child_command(host, env, "compile")
            runner._provision_signing_key(host, env)
            phoenix, live_view = runner._framework_versions(host, env)
            elixir, otp, pg = runner._actual_runtime(host, env)
            result = _run_witness(host, env, scope, redactor, attempt_dir)
            case_ids = CONTENTION_CASE_IDS if scope == "contention" else ATOMICITY_CASE_IDS
            observations = result["observations"]
            if set(observations) != set(case_ids):
                raise PackageInputError("installed transaction host omitted a required executed witness")
            host_identity = runner.candidate_host_provenance(host)
            receipt = {
                "schema": "lockspire-installed-verifier-v1",
                "scope": scope,
                "run_id": run_id,
                "runner": source_revision(),
                "pair": pair,
                "store": "delegated",
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
                    **host_identity,
                    "lock_sha256": sha256(runner.PROOF_PAIR_LOCKS[pair]),
                    "phoenix": phoenix,
                    "live_view": live_view,
                },
                "runtime": {"elixir": elixir, "otp": otp, "postgresql": pg},
                "stable_case_ids": case_ids,
                "observations": observations,
                "executed_count": len(case_ids),
                "partial": True,
            }
            validate_receipt(receipt, expected_pair=pair, expected_store="delegated")
            redactor.assert_safe(json.dumps(receipt, sort_keys=True))
            receipt_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
            receipt_path = receipt_dir / "receipt.json"
            receipt_path.write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n", encoding="utf-8")
            os.chmod(receipt_path, 0o600)
            receipt["receipt_path"] = str(receipt_path)
            return receipt
        except Exception as error:
            safe = redactor.text(str(error))
            redactor.assert_safe(safe)
            log_path = attempt_dir / "failure.log"
            log_path.write_text(safe[:8000] + "\n", encoding="utf-8")
            os.chmod(log_path, 0o600)
            raise PackageInputError(f"{scope} installed cell failed; redacted details at {log_path}") from None
        finally:
            try:
                run_child_command(host, env, "ecto.drop")
            except PackageInputError:
                pass


def _run_witness(host: Path, env: dict[str, str], scope: str, redactor: Redactor, attempt_dir: Path) -> dict[str, object]:
    function = "run_contention" if scope == "contention" else "run_atomicity"
    code = (
        "{:ok, _} = Application.ensure_all_started(:ecto_sql); "
        "{:ok, _repo} = CleanRoomProvider.Repo.start_link(); "
        f"observations = CleanRoomProvider.VerifierTransactions.{function}(); "
        'IO.puts("TRANSACTION_WITNESS=" <> Jason.encode!(%{"observations" => observations}))'
    )
    completed = subprocess.run(
        ("mix", "run", "-e", code),
        cwd=host,
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
        timeout=150,
    )
    output = completed.stdout.decode(errors="replace")
    safe_output = redactor.text(output)
    redactor.assert_safe(safe_output)
    log_path = attempt_dir / "host-output.log"
    log_path.write_text(safe_output[-12000:], encoding="utf-8")
    os.chmod(log_path, 0o600)
    if completed.returncode != 0:
        raise PackageInputError("installed PostgreSQL witness command failed")
    lines = [line.removeprefix("TRANSACTION_WITNESS=") for line in safe_output.splitlines() if line.startswith("TRANSACTION_WITNESS=")]
    if len(lines) != 1:
        raise PackageInputError("installed PostgreSQL witness result is unavailable")
    try:
        value = json.loads(lines[0])
    except json.JSONDecodeError:
        raise PackageInputError("installed PostgreSQL witness result is malformed") from None
    if not isinstance(value, dict) or set(value) != {"observations"} or not isinstance(value["observations"], dict):
        raise PackageInputError("installed PostgreSQL witness result shape is invalid")
    return value


def _increase_owned_pool_for_contention(host: Path) -> None:
    config = host / "config" / "config.exs"
    content = config.read_text(encoding="utf-8")
    if content.count("pool_size: 2") != 1:
        raise PackageInputError("generated host pool configuration shape changed")
    config.write_text(content.replace("pool_size: 2", "pool_size: 5", 1), encoding="utf-8")

