"""Installed verifier custody recovery and authenticated issuance proof groups."""

from __future__ import annotations

import base64
import hashlib
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
import verifier_endpoints
import verifier_rollout
from verifier_receipts import validate_receipt


RECOVERY_CASES = (
    "VPROOF-02-RECOVERY-PRESERVATION",
    "VPROOF-02-RECOVERY-RETRY-RECONCILIATION",
    "VPROOF-02-RECOVERY-RESTORE-ROTATE",
    "VPROOF-02-RECOVERY-EXPIRED-MIGRATION",
)
RECOVERY_REQUIRED_FIELDS = {
    RECOVERY_CASES[0]: (
        "hash_preserved", "partner_secret_preserved", "client_fields_preserved",
        "age_metadata_preserved", "ciphertext_changed", "audit_inserted",
    ),
    RECOVERY_CASES[1]: (
        "repeat_no_change", "partial_not_ready", "interruption_not_ready",
        "indeterminate_not_claimed_rollback", "fresh_complete_check_ready",
    ),
    RECOVERY_CASES[2]: (
        "missing_key_rejected", "affected_status_redacted", "basic_usable", "post_usable",
        "original_secret_preserved", "rotation_secret_changed", "one_time_handoff",
        "missing_startup_context_bound",
        "restored_startup_context_has_protecting_key",
    ),
    RECOVERY_CASES[3]: (
        "expired_rewrap_committed", "expired_http_auth_rejected", "deadline_preserved",
    ),
}
RECOVERY_EXPECTED_STATUSES = {
    RECOVERY_CASES[2]: {
        "missing_key_http_status": 401,
        "basic_http_status": 200,
        "post_http_status": 200,
        "restored_http_status": 200,
        "old_secret_after_rotation_http_status": 401,
        "new_secret_after_rotation_http_status": 200,
    },
    RECOVERY_CASES[3]: {"expired_http_status": 401},
}
RECOVERY_EXPECTED_ERRORS = {
    RECOVERY_CASES[2]: {
        "missing_key_error_code": "invalid_client",
        "old_secret_after_rotation_error_code": "invalid_client",
        "new_secret_after_rotation_error_code": "other",
    }
}
RECOVERY_EXPECTED_STATUSES = {
    RECOVERY_CASES[2]: {
        "missing_key_http_status": 401,
        "basic_http_status": 200,
        "post_http_status": 200,
        "restored_http_status": 200,
        "old_secret_after_rotation_http_status": 401,
        "new_secret_after_rotation_http_status": 200,
    },
    RECOVERY_CASES[3]: {"expired_http_status": 401},
}
RECOVERY_EXPECTED_ERRORS = {
    RECOVERY_CASES[2]: {
        "missing_key_error_code": "invalid_client",
        "old_secret_after_rotation_error_code": "invalid_client",
        "new_secret_after_rotation_error_code": "other",
    }
}
ISSUANCE_CASES = (
    "VPROOF-02-ISSUANCE-LOCKED-STALE-IDENTITY",
    "VPROOF-02-ISSUANCE-FLOOR-STALE-IDENTITY",
)
SAFE_FAILURE_STAGES = frozenset({
    "recovery_seed", "recovery_apply", "recovery_repeat", "recovery_interrupt",
    "recovery_indeterminate", "recovery_restore_rotation", "recovery_expired_migration",
    "recovery_interrupt_lock_start", "recovery_interrupt_lock_held",
    "recovery_interrupt_apply_start", "recovery_interrupt_blocked",
    "recovery_interrupt_not_blocked", "recovery_interrupt_kill",
    "recovery_interrupt_lock_release", "recovery_interrupt_observe",
    "recovery_interrupt_cleanup",
    "expired_seed", "expired_migrated_ciphertext", "expired_install_migrated", "expired_apply",
    "expired_http", "expired_http_connect", "expired_http_timeout", "expired_http_transport",
    "expired_code_interaction", "expired_code_token", "expired_assertion", "expired_request",
    "expired_request_argument", "expired_request_case", "expired_request_function_clause",
    "expired_request_match", "expired_request_erlang", "expired_request_error",
    "expired_request_undefined_httpc", "expired_request_undefined", "expired_request_runtime",
    "expired_request_key", "expired_request_bad_map", "expired_request_bad_arity",
    "expired_request_system_limit",
    "expired_metadata",
    "issuance_endpoint_ready", "issuance_seed", "issuance_auth_barrier", "issuance_maintenance",
    "issuance_replay_fresh",
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
        _increase_recovery_pool_for_concurrency(host)
        runner._configure_verifier_custody(host)
        runner._configure_rewrap_verifier_custody(host)
        _configure_http_and_recovery_keys(host, include_new=True)
        env = runner._mix_env(host, root, database_url, port, issuer, prefix, old_key, pair)
        env["LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY_NEXT"] = new_key
        env["CLEAN_ROOM_HTTP_SERVER"] = "false"
        env["LOCKSPIRE_PROOF_PAIR"] = pair
        env["LOCKSPIRE_RECOVERY_CONTEXT_WITNESS"] = "true" if scope == "recovery" else "false"
        redactor.register_material(database_url)
        server = None
        try:
            _safe_host_call("ecto_create", lambda: run_child_command(host, env, "ecto.create"))
            _safe_host_call(
                "ecto_migrate",
                lambda: run_child_command(host, env, "ecto.migrate", "--migrations-path", "priv/repo/migrations"),
            )
            _safe_host_call("signing_key", lambda: runner._provision_signing_key(host, env))
            lock_hash = sha256(PROOF_PAIR_LOCKS[pair])
            phoenix, live_view = _safe_host_call("framework_versions", lambda: runner._framework_versions(host, env))
            elixir, otp, postgres = _safe_host_call("runtime", lambda: runner._actual_runtime(host, env))
            command = "recovery" if scope == "recovery" else "issuance"
            if scope == "recovery":
                server, _server_pid = verifier_rollout._start_server(
                    host, env, root / "provider-initial.log", issuer
                )
                handoff_path = root / "recovery-handoff.json"
                handoff_path.touch(mode=0o600)
                os.chmod(handoff_path, 0o600)
                env["LOCKSPIRE_RECOVERY_HANDOFF_PATH"] = str(handoff_path)
                expression = (
                    f"result = CleanRoomProvider.VerifierRecovery.run_recovery(:{store}, {json.dumps(issuer)}); "
                    'IO.puts("VERIFIER_PROOF_JSON=" <> Jason.encode!(result))'
                )
                output = _capture_child_output(
                    lambda: run_child_command_output(host, env, "run", "-e", expression)
                )
                observations = _parse_observations(output, redactor)
                handoff = _read_private_handoff(handoff_path, redactor)
                verifier_rollout._stop_owned_server(server)
                server = None
                observations[RECOVERY_CASES[2]] = _verify_restore_and_rotation(
                    host, env, root, issuer, handoff, redactor
                )
            else:
                # Keep the real HTTP request and delegated callback controls in
                # one owned Mix VM so the barrier is observed by the serving host.
                env["CLEAN_ROOM_HTTP_SERVER"] = "true"
                expression = (
                    f"result = CleanRoomProvider.VerifierRecovery.run_issuance(:{store}, {json.dumps(issuer)}); "
                    'IO.puts("VERIFIER_PROOF_JSON=" <> Jason.encode!(result))'
                )
                output = _capture_child_output(
                    lambda: run_child_command_output(host, env, "run", "-e", expression)
                )
                observations = _parse_observations(output, redactor)
            case_ids = list(RECOVERY_CASES if scope == "recovery" else (f"VPROOF-02-ISSUANCE-{pair.upper()}-STALE-IDENTITY",))
            if set(observations) != set(case_ids):
                raise PackageInputError("installed verifier group omitted a required scenario")
            if scope == "recovery":
                failed = _failed_recovery_fields(observations)
                if failed:
                    summary = ";".join(
                        f"{case_id}={','.join(fields)}" for case_id, fields in failed
                    )
                    raise PackageInputError(
                        "installed recovery observations incomplete; failed=" + summary
                    )
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
            if server is not None:
                verifier_rollout._stop_owned_server(server)
            handoff_path = locals().get("handoff_path")
            if handoff_path is not None:
                try:
                    handoff_path.unlink()
                except FileNotFoundError:
                    pass
            try:
                run_child_command(host, env, "ecto.drop")
            except PackageInputError:
                pass


def _configure_http_and_recovery_keys(host: Path, *, include_new: bool) -> str:
    runtime = host / "config" / "runtime.exs"
    content = runtime.read_text(encoding="utf-8")
    marker = "config :lockspire, Lockspire.Security.ClientSecretVerifier,"
    if content.count(marker) != 1:
        raise PackageInputError("recovery host verifier startup configuration is ambiguous")
    content = content[:content.index(marker)].rstrip()
    content += '\n\nconfig :clean_room_provider, CleanRoomProviderWeb.Endpoint,\n'
    content += '  server: System.get_env("CLEAN_ROOM_HTTP_SERVER", "false") == "true"\n\n'
    content += marker + "\n"
    if include_new:
        content += '''  keys: [
    {"verifier-old", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY")},
    {"verifier-new", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY_NEXT")}
  ],
  current: "verifier-new",
'''
    else:
        content += '''  keys: [{"verifier-old", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY")}],
  current: "verifier-old",
'''
    content += "  write_mode: :dedicated,\n  legacy_read: :reject\n"
    runtime.write_text(content, encoding="utf-8")
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def _increase_recovery_pool_for_concurrency(host: Path) -> None:
    config = host / "config" / "config.exs"
    content = config.read_text(encoding="utf-8")
    if content.count("pool_size: 2") != 1:
        raise PackageInputError("generated recovery host pool configuration shape changed")
    config.write_text(content.replace("pool_size: 2", "pool_size: 6", 1), encoding="utf-8")


def _read_private_handoff(path: Path, redactor: Redactor) -> dict[str, dict[str, str]]:
    try:
        os.chmod(path, 0o600)
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        raise PackageInputError("recovery private handoff is unavailable") from None
    finally:
        try:
            path.unlink()
        except FileNotFoundError:
            pass
    if not isinstance(value, dict) or set(value) != {"jwt", "basic", "post"}:
        raise PackageInputError("recovery private handoff shape is invalid")
    for name, client in value.items():
        if not isinstance(client, dict) or set(client) != {"client_id", "secret"}:
            raise PackageInputError("recovery private credential entry is invalid")
        if not all(isinstance(item, str) and item for item in client.values()):
            raise PackageInputError("recovery private credential entry is incomplete")
        redactor.register_material(client["client_id"])
        redactor.register_material(client["secret"])
    safe_handoff = redactor.text(json.dumps(value, sort_keys=True))
    redactor.assert_safe(safe_handoff)
    return value


def _verify_restore_and_rotation(
    host: Path,
    env: dict[str, str],
    root: Path,
    issuer: str,
    clients: dict[str, dict[str, str]],
    redactor: Redactor,
) -> dict[str, object]:
    old_only_fingerprint = _configure_http_and_recovery_keys(host, include_new=False)
    missing_env = dict(env)
    missing_env["CLEAN_ROOM_HTTP_SERVER"] = "true"
    missing_server, missing_pid = verifier_rollout._start_server(
        host, missing_env, root / "provider-missing-key.log", issuer
    )
    try:
        missing_context_valid, missing_has_key = _read_startup_context(
            root / "provider-missing-key.log"
        )
        missing = verifier_endpoints._issue_token(issuer, clients["jwt"], redactor)
        basic = verifier_endpoints._issue_token(issuer, clients["basic"], redactor, method="basic")
        post = verifier_endpoints._issue_token(issuer, clients["post"], redactor, method="post")
        missing_rejected = missing["status"] == 401 and not missing["token_issued"]
        controls_usable = basic["status"] == 200 and basic["token_issued"] and post["status"] == 200 and post["token_issued"]
    finally:
        verifier_rollout._stop_owned_server(missing_server)

    full_fingerprint = _configure_http_and_recovery_keys(host, include_new=True)
    restored_env = dict(env)
    restored_env["CLEAN_ROOM_HTTP_SERVER"] = "true"
    restored_server, restored_pid = verifier_rollout._start_server(
        host, restored_env, root / "provider-restored-key.log", issuer
    )
    try:
        restored_context_valid, restored_has_key = _read_startup_context(
            root / "provider-restored-key.log"
        )
        restored = verifier_endpoints._issue_token(issuer, clients["jwt"], redactor)
        original_preserved = restored["status"] == 200 and restored["token_issued"]

        rotation_path = root / "rotation-handoff.json"
        rotation_path.touch(mode=0o600)
        os.chmod(rotation_path, 0o600)
        rotate_expression = (
            "{:ok, %{client_secret: secret}} = Lockspire.Admin.Clients.rotate_client_secret("
            + json.dumps(clients["jwt"]["client_id"])
            + ', actor: %{type: :operator, id: "phase178-recovery"}); '
            "path = System.fetch_env!(\"LOCKSPIRE_ROTATION_HANDOFF_PATH\"); "
            "File.write!(path, Jason.encode!(%{secret: secret}), [:binary]); File.chmod!(path, 0o600)"
        )
        rotation_env = dict(env)
        rotation_env["CLEAN_ROOM_HTTP_SERVER"] = "false"
        rotation_env["LOCKSPIRE_ROTATION_HANDOFF_PATH"] = str(rotation_path)
        _capture_child_output(lambda: run_child_command_output(host, rotation_env, "run", "-e", rotate_expression))
        replacement = _read_rotation_handoff(rotation_path, redactor)
        new_client = {"client_id": clients["jwt"]["client_id"], "secret": replacement}
        old_after_rotation = verifier_endpoints._issue_token(issuer, clients["jwt"], redactor)
        new_after_rotation = verifier_endpoints._issue_token(issuer, new_client, redactor)
    finally:
        verifier_rollout._stop_owned_server(restored_server)

    return {
        "outcome": "pass",
        "executed": True,
        "missing_key_rejected": missing_rejected,
        "missing_key_http_status": missing["status"],
        "missing_key_error_code": missing["safe_error_code"],
        "affected_status_redacted": (
            missing["status"] == 401
            and missing["safe_error_code"] == "invalid_client"
            and not missing["token_issued"]
        ),
        "basic_usable": basic["status"] == 200 and basic["token_issued"],
        "basic_http_status": basic["status"],
        "post_usable": post["status"] == 200 and post["token_issued"],
        "post_http_status": post["status"],
        "original_secret_preserved": original_preserved,
        "restored_http_status": restored["status"],
        "rotation_secret_changed": replacement != clients["jwt"]["secret"] and old_after_rotation["status"] == 401 and old_after_rotation["safe_error_code"] == "invalid_client" and new_after_rotation["status"] == 200 and new_after_rotation["token_issued"],
        "old_secret_after_rotation_http_status": old_after_rotation["status"],
        "old_secret_after_rotation_error_code": old_after_rotation["safe_error_code"],
        "new_secret_after_rotation_http_status": new_after_rotation["status"],
        "new_secret_after_rotation_error_code": new_after_rotation["safe_error_code"],
        "one_time_handoff": bool(replacement),
        "missing_startup_context_bound": (
            old_only_fingerprint != full_fingerprint
            and missing_pid != restored_pid
            and missing_context_valid
            and restored_context_valid
        ),
        "missing_startup_context_has_protecting_key": missing_has_key,
        "restored_startup_context_has_protecting_key": restored_has_key,
    }


def _read_startup_context(log_path: Path) -> tuple[bool, bool]:
    found: dict[str, bool] = {}
    try:
        with log_path.open("r", encoding="utf-8", errors="replace") as handle:
            for line in handle:
                for field in ("SAFE_RECOVERY_CONTEXT_VALID", "SAFE_RECOVERY_PROTECTING_KEY"):
                    marker = field + "="
                    if line.startswith(marker):
                        value = line[len(marker):].strip()
                        if value in {"true", "false"}:
                            found[field] = value == "true"
    except OSError:
        raise PackageInputError("owned recovery startup context witness is unavailable") from None
    if set(found) != {"SAFE_RECOVERY_CONTEXT_VALID", "SAFE_RECOVERY_PROTECTING_KEY"}:
        raise PackageInputError("owned recovery startup context witness is incomplete")
    return found["SAFE_RECOVERY_CONTEXT_VALID"], found["SAFE_RECOVERY_PROTECTING_KEY"]


def _read_rotation_handoff(path: Path, redactor: Redactor) -> str:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        raise PackageInputError("rotation private handoff is unavailable") from None
    finally:
        try:
            path.unlink()
        except FileNotFoundError:
            pass
    secret = value.get("secret") if isinstance(value, dict) else None
    if not isinstance(secret, str) or not secret:
        raise PackageInputError("rotation private handoff is incomplete")
    redactor.register_material(secret)
    return secret


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


def _failed_recovery_fields(observations: dict[str, object]) -> list[tuple[str, list[str]]]:
    failures: list[tuple[str, list[str]]] = []
    for case_id, fields in RECOVERY_REQUIRED_FIELDS.items():
        observation = observations.get(case_id)
        if not isinstance(observation, dict):
            failures.append((case_id, list(fields)))
            continue
        failed = [field for field in fields if observation.get(field) is not True]
        if case_id == RECOVERY_CASES[2]:
            if observation.get("missing_startup_context_has_protecting_key") is not False:
                failed.append("missing_startup_context_has_protecting_key_expected_false")
            if observation.get("restored_startup_context_has_protecting_key") is not True:
                failed.append("restored_startup_context_has_protecting_key_expected_true")
        for field, expected in RECOVERY_EXPECTED_STATUSES.get(case_id, {}).items():
            actual = observation.get(field)
            if actual != expected:
                label = actual if type(actual) is int and actual in {200, 400, 401, 500} else "other"
                failed.append(f"{field}_{label}")
        for field, expected in RECOVERY_EXPECTED_ERRORS.get(case_id, {}).items():
            actual = observation.get(field)
            if actual != expected:
                label = actual if actual in {
                    "invalid_client", "invalid_grant", "invalid_request", "invalid_scope",
                    "unauthorized_client", "server_error", "temporarily_unavailable", "other",
                } else "other"
                failed.append(f"{field}_{label}")
        if case_id == RECOVERY_CASES[2]:
            if observation.get("missing_startup_context_has_protecting_key") is not False:
                failed.append("missing_startup_context_has_protecting_key_expected_false")
            if observation.get("restored_startup_context_has_protecting_key") is not True:
                failed.append("restored_startup_context_has_protecting_key_expected_true")
        for field, expected in RECOVERY_EXPECTED_STATUSES.get(case_id, {}).items():
            actual = observation.get(field)
            if actual != expected:
                label = actual if type(actual) is int and actual in {200, 400, 401, 500} else "other"
                failed.append(f"{field}_{label}")
        for field, expected in RECOVERY_EXPECTED_ERRORS.get(case_id, {}).items():
            if observation.get(field) != expected:
                actual = observation.get(field)
                label = actual if actual in {
                    "invalid_client", "invalid_grant", "invalid_request", "invalid_scope",
                    "unauthorized_client", "server_error", "temporarily_unavailable", "other",
                } else "other"
                failed.append(f"{field}_{label}")
        if failed:
            failures.append((case_id, failed))
    return failures


def _capture_child_output(operation) -> str:
    try:
        return operation()
    except Exception as error:
        safe_stage = next((
            stage for stage in re.findall(r"\bSAFE_FAILURE_STAGE=([^\s;]+)", str(error))
            if stage in SAFE_FAILURE_STAGES
        ), None)
        reason = "installed verifier host scenario failed"
        if safe_stage is not None:
            reason += f" at {safe_stage}"
        raise PackageInputError(reason + "; child diagnostics withheld") from None


def _safe_host_call(stage: str, operation):
    try:
        return operation()
    except Exception:
        if stage not in {"ecto_create", "ecto_migrate", "signing_key", "framework_versions", "runtime"}:
            stage = "other"
        raise PackageInputError(
            f"installed verifier host setup failed at {stage}; child diagnostics withheld"
        ) from None


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
