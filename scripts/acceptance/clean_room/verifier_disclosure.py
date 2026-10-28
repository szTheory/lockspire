"""Installed verifier disclosure proof across Lockspire-owned diagnostic channels."""

from __future__ import annotations

import base64
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import tempfile
import time
import urllib.parse
import urllib.request
import uuid

from build_provider import PROOF_PAIR_LOCKS, PackageInputError, allocate_port, prepare_provider, run_child_command
from package_input import PackageSource, bounded_run, clean_room_database_url, prepare_package, sha256, source_revision, start_owned_session, stop_process_group, verify_candidate_input
from redaction import Redactor, SentinelSet
import clean_room_verifier_upgrade as runner
import verifier_endpoints
import verifier_receipts
from verifier_receipts import ReceiptError, validate_receipt


CAPTURE_FIELDS = frozenset({
    "channel_attribution", "operation_result", "logger_event_count", "query_event_count",
    "logger_control_event_count", "logger_operation_event_count",
    "query_control_event_count", "query_operation_event_count",
    "logger_leak_count", "query_leak_count", "nested_inspection_redacted",
    "audit_after_count", "ciphertext_changed",
})
FAILURE_CAPTURE_FIELDS = verifier_receipts.DISCLOSURE_FAILURE_CAPTURE_FIELDS
RESOURCE_CLEANUP: list[dict[str, object]] = []


def run_group(*, pair: str, store: str, receipt_dir: Path) -> list[dict[str, object]]:
    if store not in {"delegated", "all"}:
        raise PackageInputError("installed disclosure proof requires delegated PostgreSQL storage")
    pairs = ("locked", "floor") if pair == "all" else (pair,)
    if any(item not in {"locked", "floor"} for item in pairs):
        raise PackageInputError("unsupported disclosure dependency pair")
    receipts = [_run_cell(item, receipt_dir / f"{item}-delegated") for item in pairs]
    failure_receipts = [
        json.loads((receipt_dir / f"{item}-delegated" / "failure-receipt.json").read_text())
        for item in pairs
    ]
    print(json.dumps({
        "scope": "disclosure",
        "executed_count": len(receipts),
        "failure_executed_count": sum(row["executed_count"] for row in failure_receipts),
        "resources": RESOURCE_CLEANUP,
        "cells": [{
            "pair": row["pair"], "store": row["store"], "executed_count": row["executed_count"],
            "receipt": str(receipt_dir / f"{row['pair']}-delegated" / "receipt.json"),
            "failure_receipt": str(receipt_dir / f"{row['pair']}-delegated" / "failure-receipt.json"),
        } for row in receipts],
    }, sort_keys=True))
    return receipts


def _run_cell(pair: str, destination: Path) -> dict[str, object]:
    run_id = uuid.uuid4().hex
    port = allocate_port()
    prefix = "vfy" + run_id[:14]
    issuer = f"http://127.0.0.1:{port}/lockspire"
    database_url = clean_room_database_url("verifier_disclosure")
    database_name = urllib.parse.urlparse(database_url).path.removeprefix("/")
    old_key = base64.b64encode(secrets.token_bytes(32)).decode("ascii")
    new_key = base64.b64encode(secrets.token_bytes(32)).decode("ascii")
    unknown_key = base64.b64encode(secrets.token_bytes(32)).decode("ascii")
    redactor = Redactor(SentinelSet.for_run())
    for value in (old_key, new_key, database_url):
        redactor.register_material(value)
    server: subprocess.Popen[bytes] | None = None
    host: Path | None = None
    env: dict[str, str] = {}
    database_created = False
    resource: dict[str, object] = {
        "run_id": run_id, "pair": pair, "database": database_name,
        "listener_port": port, "child_state": "not_started", "database_created": False,
        "failure_capture_stage": "not_started",
    }
    RESOURCE_CLEANUP.append(resource)
    temp_cleanup = None
    failure_path: Path | None = None
    stage = "package"
    try:
        temporary_owner = tempfile.TemporaryDirectory(prefix=f"lockspire-verifier-disclosure-{pair}-")
        temp_cleanup = temporary_owner.cleanup
        temporary_owner.cleanup = lambda: None  # cleanup waits until the owned database is dropped
        with temporary_owner as temporary:
            root = Path(temporary)
            os.chmod(root, 0o700)
            _persist_resource(destination, resource)
            package, _entries, identity = prepare_package(root, PackageSource("checkout"))
            archive = package.parent / f"lockspire-{identity.version}.tar"
            verify_candidate_input(archive, package, identity)
            resource.update({
                "runner": source_revision(),
                "candidate_archive_sha256": identity.archive_sha256,
                "candidate_tree_sha256": identity.tree_sha256,
                "candidate_source_revision": identity.source_revision,
                "candidate_version": identity.version,
            })
            _persist_resource(destination, resource)
            stage = "provider"
            host = prepare_provider(
                root, database_url, package_root=package, port=port, storage_prefix=prefix,
                candidate_identity=identity, custom_lifetime_adapter=True, proof_pair=pair,
                scenario_groups={"disclosure"},
            )
            stage = "custody_config"
            runner._configure_verifier_custody(host)
            stage = "host_environment"
            env = runner._mix_env(host, root, database_url, port, issuer, prefix, old_key, pair)
            env["LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY_NEXT"] = new_key
            env["LOCKSPIRE_DISCLOSURE_UNKNOWN_KEY"] = unknown_key
            env["CLEAN_ROOM_HTTP_SERVER"] = "false"
            _register_key_material(redactor, env["LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY"])
            _register_key_material(redactor, env["LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY_NEXT"])
            _register_key_material(redactor, unknown_key)

            stage = "database"
            run_child_command(host, env, "ecto.create")
            database_created = True
            resource["database_created"] = True
            _persist_resource(destination, resource)
            run_child_command(host, env, "ecto.migrate", "--migrations-path", "priv/repo/migrations")
            runner._provision_signing_key(host, env)
            phoenix, live_view = runner._framework_versions(host, env)
            runtime, otp, postgres = runner._actual_runtime(host, env)

            client_a = "vfy-disclosure-a-" + run_id[:12]
            client_b = "vfy-disclosure-b-" + run_id[:12]
            handoff = root / "registration-handoff.json"
            _private_path(handoff)
            stage = "registration"
            output, error = _private_mix(
                host, env, "run", "--no-start", "-e",
                _seed_expression([client_a, client_b], handoff),
                resource=resource, destination=destination, label="registration",
            )
            clients = _read_handoff(handoff, redactor)
            output, error = _decode_channels(output, error, redactor)
            _assert_safe_channels(output, error, redactor)
            if set(clients) != {client_a, client_b}:
                raise PackageInputError("installed disclosure registration handoff is incomplete")

            runner._configure_rewrap_verifier_custody(host)
            rotation = root / "rotation-handoff.json"
            _private_path(rotation)
            stage = "rotation"
            output, error = _private_mix(
                host, env, "run", "-e",
                "CleanRoomProvider.VerifierDisclosure.rotate(" + json.dumps(client_a) + ", " + json.dumps(str(rotation)) + ")",
                resource=resource, destination=destination, label="rotation",
            )
            rotated = _read_private_json(rotation, redactor)
            output, error = _decode_channels(output, error, redactor)
            _assert_safe_channels(output, error, redactor)
            if rotated.get("client_id") != client_a or rotated.get("nested_inspection_redacted") is not True:
                raise PackageInputError("installed disclosure rotation handoff is incomplete")
            clients[client_a]["secret_before_rotation"] = clients[client_a]["secret"]
            clients[client_a]["secret"] = rotated["secret"]
            clients[client_a]["ciphertext_after_rotation"] = rotated["ciphertext"]
            clients[client_a]["nested_inspection_redacted"] &= rotated["nested_inspection_redacted"]
            env["LOCKSPIRE_DISCLOSURE_SENTINELS"] = json.dumps(list(redactor._values))
            env["CLEAN_ROOM_HTTP_SERVER"] = "false"

            stage = "server"
            resource["server_state"] = "starting"
            _persist_resource(destination, resource)
            server = _start_server(
                host, env, issuer,
                on_started=lambda child: _record_server_started(destination, resource, child),
            )
            resource.update({
                "server_pid": server.pid,
                "process_group": getattr(server, "lockspire_process_group", None),
                "started_at": getattr(server, "lockspire_started_at", None),
            })
            resource["server_state"] = "running"
            _persist_resource(destination, resource)
            stage = "http"
            good_http = verifier_endpoints._issue_token(issuer, clients[client_a], redactor)
            old_http = verifier_endpoints._issue_token(
                issuer, {"client_id": client_a, "secret": clients[client_a]["secret_before_rotation"]}, redactor
            )
            if good_http["status"] != 200 or not good_http["token_issued"] or old_http["status"] != 401:
                raise PackageInputError("installed disclosure one-time handoff or rotation control failed")

            stage = "maintenance"
            capture_handoff = root / "capture-handoff.json"
            _private_path(capture_handoff)
            _write_private_json(capture_handoff, {
                "client_id": client_b,
                "ciphertext": clients[client_b]["ciphertext"],
            })
            expression = (
                "CleanRoomProvider.VerifierDisclosure.capture_success_from_file("
                + json.dumps(str(capture_handoff))
                + ", System.fetch_env!(\"LOCKSPIRE_DISCLOSURE_SENTINELS\") |> Jason.decode!())"
            )
            output, error = _private_mix(host, env, "run", "-e", expression,
                                         resource=resource, destination=destination, label="maintenance")
            output, error = _decode_channels(output, error, redactor)
            _assert_safe_channels(output, error, redactor)
            capture = _one_json(output, "VERIFIER_DISCLOSURE_CAPTURE_JSON=")
            try:
                capture = validate_capture_payload(capture)
            except verifier_receipts.DisclosureCaptureRejected as rejection:
                resource["capture_rejection"] = rejection.witness
                _persist_resource(destination, resource)
                persist_capture_rejection(destination / "capture-rejection.json", rejection)
                raise PackageInputError("installed disclosure capture rejected by finite predicate") from None
            audit_handoff = root / "audit-handoff.json"
            _private_path(audit_handoff)
            _write_private_json(audit_handoff, {
                "client_id": client_b,
                "audit_before": clients[client_b]["audit_before"],
                "ciphertext": clients[client_b]["ciphertext"],
            })
            audit_expression = (
                "CleanRoomProvider.VerifierDisclosure.audit_projection_from_file("
                + json.dumps(str(audit_handoff)) + ")"
            )
            audit_output, audit_error = _private_mix(host, env, "run", "-e", audit_expression,
                                                     resource=resource, destination=destination, label="audit")
            audit_output, audit_error = _decode_channels(audit_output, audit_error, redactor)
            _assert_safe_channels(audit_output, audit_error, redactor)
            audit = _one_json(audit_output, "VERIFIER_DISCLOSURE_AUDIT_JSON=")
            if set(audit) != {"audit_projection_safe", "audit_inserted", "ciphertext_changed"} or any(type(item) is not bool for item in audit.values()):
                raise PackageInputError("installed disclosure audit projection is malformed")
            if (
                capture["operation_result"] != "ok"
                or capture["channel_attribution"] != verifier_receipts.DISCLOSURE_CHANNEL_ATTRIBUTION
                or capture["ciphertext_changed"] is not True
                or audit["audit_inserted"] is not True
                or audit["ciphertext_changed"] is not True
                or audit["audit_projection_safe"] is not True
                or capture["logger_event_count"] <= 0
                or capture["query_event_count"] <= 0
                or capture["logger_leak_count"] != 0
                or capture["query_leak_count"] != 0
                or capture["nested_inspection_redacted"] is not True
            ):
                raise PackageInputError("installed disclosure success channel evidence is incomplete")

            observation = {
                "outcome": "pass", "executed": True,
                "channel_attribution": capture["channel_attribution"],
                "logger_event_count": capture["logger_event_count"],
                "query_event_count": capture["query_event_count"],
                "logger_control_event_count": capture["logger_control_event_count"],
                "logger_operation_event_count": capture["logger_operation_event_count"],
                "query_control_event_count": capture["query_control_event_count"],
                "query_operation_event_count": capture["query_operation_event_count"],
                "logger_leak_count": capture["logger_leak_count"],
                "query_leak_count": capture["query_leak_count"],
                "output_leak_count": 0, "cli_output_checked": True,
                "audit_projection_safe": audit["audit_projection_safe"],
                "nested_inspection_redacted": capture["nested_inspection_redacted"],
                "one_time_handoff_usable": good_http["status"] == 200 and good_http["token_issued"],
                "maintenance_changed": audit["ciphertext_changed"] and capture["ciphertext_changed"],
                "http_status": good_http["status"],
            }
            receipt = {
                "schema": verifier_receipts.SCHEMA, "scope": "disclosure", "run_id": run_id,
                "runner": source_revision(), "pair": pair, "store": "delegated",
                "candidate": {
                    "kind": identity.kind, "version": identity.version,
                    "archive_sha256": identity.archive_sha256, "tree_sha256": identity.tree_sha256,
                    "source_revision": identity.source_revision, "runner_revision": identity.runner_revision,
                    "source_proof": identity.source_proof,
                },
                "host": {
                    **runner.candidate_host_provenance(host),
                    "lock_sha256": sha256(PROOF_PAIR_LOCKS[pair]),
                    "phoenix": phoenix, "live_view": live_view,
                },
                "runtime": {"elixir": runtime, "otp": otp, "postgresql": postgres},
                "stable_case_ids": verifier_receipts.DISCLOSURE_CASE_IDS[pair],
                "observations": {verifier_receipts.DISCLOSURE_CASE_IDS[pair][0]: observation},
                "executed_count": 1, "partial": True,
            }
            validate_receipt(receipt, expected_pair=pair, expected_store="delegated")
            redactor.assert_safe(json.dumps(receipt, sort_keys=True))
            destination.mkdir(mode=0o700, parents=True, exist_ok=True)
            path = destination / "receipt.json"
            path.write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n", encoding="utf-8")
            os.chmod(path, 0o600)
            _run_failure_proof(
                pair=pair, host=host, env=env, issuer=issuer, identity=identity,
                phoenix=phoenix, live_view=live_view, runtime=runtime, otp=otp,
                postgres=postgres, run_id=run_id, root=root, destination=destination,
                resource=resource, redactor=redactor,
            )
            resource.update(_stop_owned_server(server, port))
            resource["server_state"] = (
                "stopped" if resource["process_group_stop_confirmed"] else "cleanup_unconfirmed"
            )
            server = None
            run_child_command(host, env, "ecto.drop")
            if _database_exists(database_name):
                raise PackageInputError("owned disclosure database remains after ecto.drop")
            database_created = False
            resource["database_absent"] = True
            return receipt
    except Exception as error:
        destination.mkdir(mode=0o700, parents=True, exist_ok=True)
        safe_reason = {
            "installed disclosure seed failed at registration": "registration_rejected",
            "installed disclosure seed failed at nested_inspection": "inspection_failed",
            "installed disclosure seed failed at audit_projection": "audit_projection_failed",
            "installed disclosure seed failed at host_setup": "host_setup_failed",
        }.get(str(error), "stage_failed")
        failure = {
            "schema": "lockspire-installed-verifier-disclosure-failure-v1",
            "pair": pair, "store": "delegated",
            "database": database_name,
            "stage": stage if stage in {"package", "provider", "custody_config", "host_environment", "database", "registration", "rotation", "server", "http", "maintenance"} else "unknown",
            "reason": safe_reason, "runner": source_revision(),
            "failure_capture_stage": resource.get("failure_capture_stage", "not_started"),
            "capture_rejection": resource.get("capture_rejection"),
        }
        failure_path = destination / "failed-attempt.json"
        failure_path.write_text(json.dumps(failure, sort_keys=True, indent=2) + "\n", encoding="utf-8")
        os.chmod(failure_path, 0o600)
        raise PackageInputError(f"installed disclosure {failure['stage']} stage failed ({safe_reason}); child diagnostics withheld") from None
    finally:
        if server is not None:
            resource.update(_stop_owned_server(server, port))
            resource["server_state"] = (
                "stopped" if resource["process_group_stop_confirmed"] else "cleanup_unconfirmed"
            )
        if database_created and host is not None:
            try:
                run_child_command(host, env, "ecto.drop")
                if _database_exists(database_name):
                    raise PackageInputError("owned disclosure database remains after cleanup")
                database_created = False
                resource["database_absent"] = True
            except Exception:
                if failure_path is not None and failure_path.is_file():
                    failure = json.loads(failure_path.read_text(encoding="utf-8"))
                    failure["database"] = database_name
                    failure["database_absent"] = False
                    failure_path.write_text(json.dumps(failure, sort_keys=True, indent=2) + "\n", encoding="utf-8")
                if temp_cleanup is not None:
                    temp_cleanup()
                raise PackageInputError("owned disclosure database cleanup could not be confirmed") from None
        elif not database_created:
            resource["database_absent"] = not _database_exists(database_name)
        if failure_path is not None and failure_path.is_file():
            failure = json.loads(failure_path.read_text(encoding="utf-8"))
            failure["database"] = database_name
            failure["database_absent"] = resource.get("database_absent", False)
            failure_path.write_text(json.dumps(failure, sort_keys=True, indent=2) + "\n", encoding="utf-8")
        if temp_cleanup is not None:
            temp_cleanup()
        _persist_resource(destination, resource)


def validate_capture_payload(payload: object) -> dict[str, object]:
    if not isinstance(payload, dict) or set(payload) != CAPTURE_FIELDS:
        raise verifier_receipts.DisclosureCaptureRejected("capture_fields_invalid", payload)
    for field in (
        "logger_event_count", "query_event_count", "logger_control_event_count",
        "logger_operation_event_count", "query_control_event_count", "query_operation_event_count",
        "logger_leak_count", "query_leak_count", "audit_after_count",
    ):
        if type(payload[field]) is not int or not 0 <= payload[field] <= verifier_receipts.DISCLOSURE_COUNT_MAX:
            raise verifier_receipts.DisclosureCaptureRejected("capture_count_invalid", payload)
    if payload["logger_event_count"] <= 0 or payload["query_event_count"] <= 0:
        raise verifier_receipts.DisclosureCaptureRejected("capture_controls_invalid", payload)
    if payload["channel_attribution"] != verifier_receipts.DISCLOSURE_CHANNEL_ATTRIBUTION:
        raise verifier_receipts.DisclosureCaptureRejected("channel_attribution_unsupported", payload)
    if payload["logger_control_event_count"] != 2 or payload["query_control_event_count"] != 1:
        raise verifier_receipts.DisclosureCaptureRejected("capture_controls_invalid", payload)
    if (
        payload["logger_event_count"] < payload["logger_control_event_count"] + payload["logger_operation_event_count"]
        or payload["query_event_count"] < payload["query_control_event_count"] + payload["query_operation_event_count"]
    ):
        raise verifier_receipts.DisclosureCaptureRejected("capture_totals_invalid", payload)
    if payload["logger_leak_count"] or payload["query_leak_count"]:
        raise verifier_receipts.DisclosureCaptureRejected("capture_channel_leak_observed", payload)
    if type(payload["nested_inspection_redacted"]) is not bool or not payload["nested_inspection_redacted"]:
        raise verifier_receipts.DisclosureCaptureRejected("capture_redaction_invalid", payload)
    if type(payload["ciphertext_changed"]) is not bool or payload["operation_result"] != "ok":
        raise verifier_receipts.DisclosureCaptureRejected("capture_operation_invalid", payload)
    return payload


def persist_capture_rejection(
    path: Path, rejection: verifier_receipts.DisclosureCaptureRejected,
) -> dict[str, object]:
    if not isinstance(rejection, verifier_receipts.DisclosureCaptureRejected):
        raise ReceiptError("disclosure capture rejection is not finite")
    record = {
        "schema": "lockspire-disclosure-capture-rejection-v1",
        "predicate": rejection.witness["predicate"],
        "facts": rejection.witness["facts"],
    }
    if path.exists() or path.is_symlink():
        raise ReceiptError("disclosure capture rejection path is already occupied")
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(record, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    os.chmod(temporary, 0o600)
    os.replace(temporary, path)
    return record


def _run_failure_proof(
    *, pair: str, host: Path, env: dict[str, str], issuer: str, identity: object,
    phoenix: str, live_view: str, runtime: str, otp: str, postgres: str,
    run_id: str, root: Path, destination: Path, resource: dict[str, object],
    redactor: Redactor,
) -> dict[str, object]:
    scenarios = ("malformed_crypto", "unknown_key_crypto", "storage_failure")
    case_ids = verifier_receipts.DISCLOSURE_FAILURE_CASE_IDS[pair]
    observations: dict[str, dict[str, object]] = {}
    for scenario, case_id in zip(scenarios, case_ids):
        resource["failure_capture_stage"] = "seed"
        _persist_resource(destination, resource)
        client_id = f"vfy-disclosure-failure-{scenario}-{run_id[:8]}"
        handoff = root / f"{scenario}-handoff.json"
        seed_input = root / f"{scenario}-seed-input.json"
        _private_path(handoff)
        _write_private_json(seed_input, {
            "scenario": scenario, "client_id": client_id, "handoff_path": str(handoff),
        })
        seed_expression = (
            "try do\n"
            "  {:ok, _started} = Application.ensure_all_started(:clean_room_provider)\n"
            "  CleanRoomProvider.VerifierDisclosure.seed_failure_from_file("
            + json.dumps(str(seed_input)) + ")\n"
            "rescue\n"
            "  _error -> IO.puts(\"VERIFIER_DISCLOSURE_FAILURE_SEED_FAILED=true\")\n"
            "end"
        )
        output, error = _private_mix(
            host, env, "run", "--no-start", "-e", seed_expression,
            resource=resource, destination=destination, label=f"failure_seed_{scenario}",
        )
        private_handoff = _read_private_json(handoff, redactor)
        resource["failure_capture_stage"] = "seed_handoff_registered"
        _persist_resource(destination, resource)
        output, error = _decode_channels(output, error, redactor)
        _assert_safe_channels(output, error, redactor)
        if "VERIFIER_DISCLOSURE_FAILURE_SEEDED=true" not in output or private_handoff.get("scenario") != scenario:
            raise PackageInputError("installed disclosure failure seed was incomplete")
        env["LOCKSPIRE_DISCLOSURE_SENTINELS"] = json.dumps(list(redactor._values))

        capture_path = root / f"{scenario}-capture-input.json"
        _private_path(capture_path)
        _write_private_json(capture_path, {"scenario": scenario, "handoff_path": str(handoff)})
        # The seeding helper consumed its own input handoff; write the sensitive
        # capture handoff again from the already-registered private values.
        _write_private_json(handoff, private_handoff)
        resource["failure_capture_stage"] = "capture_child"
        _persist_resource(destination, resource)
        capture_expression = (
            "CleanRoomProvider.VerifierDisclosure.capture_failure_from_file("
            + json.dumps(str(handoff))
            + ", System.fetch_env!(\"LOCKSPIRE_DISCLOSURE_SENTINELS\") |> Jason.decode!())"
        )
        output, error = _private_mix(
            host, env, "run", "-e", capture_expression,
            resource=resource, destination=destination, label=f"failure_capture_{scenario}",
        )
        output, error = _decode_channels(output, error, redactor)
        _assert_safe_channels(output, error, redactor)
        resource["failure_capture_stage"] = "capture_output_scanned"
        _persist_resource(destination, resource)
        capture = _one_json(output, "VERIFIER_DISCLOSURE_FAILURE_CAPTURE_JSON=")
        client = {"client_id": client_id, "secret": private_handoff["secret"]}
        resource["failure_capture_stage"] = "http_probe"
        _persist_resource(destination, resource)
        http = verifier_endpoints._issue_token(issuer, client, redactor)
        capture.update({
            "http_status": http["status"],
            "http_error_code": http["safe_error_code"],
            "http_outcome_safe": http["status"] in (200, 401)
                and (http["status"] != 401 or http["safe_error_code"] == "invalid_client"),
        })
        capture["output_leak_count"] = 0
        resource["failure_capture_stage"] = "capture_validation"
        _persist_resource(destination, resource)
        try:
            capture = validate_failure_capture(capture)
        except verifier_receipts.DisclosureCaptureRejected as rejection:
            resource["capture_rejection"] = rejection.witness
            _persist_resource(destination, resource)
            persist_capture_rejection(destination / f"failure-{scenario}-capture-rejection.json", rejection)
            raise PackageInputError("installed disclosure failure capture rejected by finite predicate") from None
        safe_case = {"capture": capture}
        resource["failure_capture_stage"] = "artifact_write"
        _persist_resource(destination, resource)
        persist_safe_failure_artifact(destination / f"failure-{scenario}.json", safe_case, redactor)
        observations[case_id] = {"outcome": "pass", "executed": True, **capture}
        resource["failure_capture_stage"] = "scenario_complete"
        _persist_resource(destination, resource)

    receipt = {
        "schema": verifier_receipts.SCHEMA, "scope": "disclosure-failure", "run_id": run_id,
        "runner": source_revision(), "pair": pair, "store": "delegated",
        "candidate": {
            "kind": identity.kind, "version": identity.version,
            "archive_sha256": identity.archive_sha256, "tree_sha256": identity.tree_sha256,
            "source_revision": identity.source_revision, "runner_revision": identity.runner_revision,
            "source_proof": identity.source_proof,
        },
        "host": {
            **runner.candidate_host_provenance(host),
            "lock_sha256": sha256(PROOF_PAIR_LOCKS[pair]),
            "phoenix": phoenix, "live_view": live_view,
        },
        "runtime": {"elixir": runtime, "otp": otp, "postgresql": postgres},
        "stable_case_ids": case_ids, "observations": observations,
        "executed_count": len(observations), "partial": True,
    }
    validate_receipt(receipt, expected_pair=pair, expected_store="delegated")
    redactor.assert_safe(json.dumps(receipt, sort_keys=True))
    path = destination / "failure-receipt.json"
    path.write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    os.chmod(path, 0o600)
    resource["failure_capture_stage"] = "complete"
    _persist_resource(destination, resource)
    return receipt


def validate_failure_capture(payload: object) -> dict[str, object]:
    return verifier_receipts.validate_failure_capture(payload)


def persist_safe_failure_artifact(path: Path, payload: object, redactor: Redactor) -> None:
    if not isinstance(payload, dict) or not isinstance(payload.get("capture"), dict):
        raise ReceiptError("disclosure failure artifact has no capture")
    validate_failure_capture(payload["capture"])
    rendered = json.dumps(payload, sort_keys=True, separators=(",", ":"))
    try:
        redactor.assert_safe(rendered)
    except RuntimeError:
        raise ReceiptError("disclosure failure artifact contains registered material") from None
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    os.chmod(temporary, 0o600)
    os.replace(temporary, path)


def _one_json(output: str, marker: str) -> dict[str, object]:
    lines = [line[len(marker):] for line in output.splitlines() if line.startswith(marker)]
    if len(lines) != 1:
        raise PackageInputError("installed disclosure safe result is missing or duplicated")
    try:
        result = json.loads(lines[0])
    except json.JSONDecodeError:
        raise PackageInputError("installed disclosure safe result is malformed") from None
    if not isinstance(result, dict):
        raise PackageInputError("installed disclosure safe result has the wrong shape")
    return result


def _private_path(path: Path) -> None:
    path.touch(mode=0o600)
    os.chmod(path, 0o600)


def _write_private_json(path: Path, value: dict[str, object]) -> None:
    path.write_text(json.dumps(value, sort_keys=True), encoding="utf-8")
    os.chmod(path, 0o600)


def _register_key_material(redactor: Redactor, encoded_key: str) -> None:
    redactor.register_material(encoded_key)
    try:
        raw = base64.urlsafe_b64decode(encoded_key + "=" * (-len(encoded_key) % 4))
    except (ValueError, base64.binascii.Error):
        raise PackageInputError("installed disclosure verifier-key configuration is invalid") from None
    redactor.register_material("<<" + ", ".join(str(byte) for byte in raw) + ">>")


def _persist_resource(destination: Path, resource: dict[str, object]) -> None:
    destination.mkdir(mode=0o700, parents=True, exist_ok=True)
    path = destination / "resource-state.json"
    path.write_text(json.dumps(resource, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    os.chmod(path, 0o600)


def _read_handoff(path: Path, redactor: Redactor) -> dict[str, dict[str, object]]:
    value = _read_private_json(path, redactor)
    if set(value) == {"failure_stage"} and value["failure_stage"] in {
        "registration", "nested_inspection", "audit_projection", "host_setup",
    }:
        raise PackageInputError("installed disclosure seed failed at " + str(value["failure_stage"]))
    if set(value) != {"clients"} or not isinstance(value["clients"], dict):
        raise PackageInputError("installed disclosure handoff shape is invalid")
    return value["clients"]


def _read_private_json(path: Path, redactor: Redactor) -> dict[str, object]:
    try:
        if path.stat().st_mode & 0o777 != 0o600:
            raise PackageInputError("installed disclosure handoff mode is invalid")
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        raise PackageInputError("installed disclosure private handoff is unavailable") from None
    finally:
        try:
            path.unlink()
        except FileNotFoundError:
            pass
    if not isinstance(value, dict):
        raise PackageInputError("installed disclosure private handoff is malformed")
    _register_tree(redactor, value)
    # This private, already-unlinked payload intentionally carries credentials.
    # Register its material before examining child diagnostics; never render the
    # transport itself as evidence or mistake allowed client IDs for secrets.
    return value


def _register_tree(redactor: Redactor, value: object) -> None:
    if isinstance(value, dict):
        for key, item in value.items():
            if key in {"secret", "client_secret", "ciphertext", "secret_before_rotation", "ciphertext_after_rotation"}:
                redactor.register_material(item)
            else:
                _register_tree(redactor, item)
    elif isinstance(value, list):
        for item in value:
            _register_tree(redactor, item)


def _private_mix(
    host: Path, env: dict[str, str], *args: str,
    resource: dict[str, object], destination: Path, label: str,
) -> tuple[bytes, bytes]:
    resource["child_state"] = "running"
    resource["child_label"] = label
    resource["child_session"] = "bounded-owned-process-group"
    _persist_resource(destination, resource)
    try:
        result = bounded_run(
            ("mix", *args), cwd=host, env=env, stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=180, check=False,
        )
    except subprocess.TimeoutExpired:
        resource["child_state"] = "timed_out_and_stopped"
        _persist_resource(destination, resource)
        raise PackageInputError("installed disclosure child command exceeded its bounded timeout") from None
    except BaseException:
        resource["child_state"] = "interrupted_and_stopped"
        _persist_resource(destination, resource)
        raise
    resource["child_state"] = "exited"
    resource["child_exit_code"] = result.returncode
    _persist_resource(destination, resource)
    if result.returncode:
        raise PackageInputError("installed disclosure child command failed; diagnostics withheld")
    return result.stdout, result.stderr


def _decode_channels(stdout: bytes, stderr: bytes, redactor: Redactor) -> tuple[str, str]:
    rendered_stdout = stdout.decode(errors="replace")
    rendered_stderr = stderr.decode(errors="replace")
    redactor.assert_safe(rendered_stdout)
    redactor.assert_safe(rendered_stderr)
    return rendered_stdout, rendered_stderr


def _seed_expression(client_ids: list[str], handoff: Path) -> str:
    ids = json.dumps(client_ids)
    path = json.dumps(str(handoff))
    return (
        "try do\n"
        "  {:ok, _started} = Application.ensure_all_started(:clean_room_provider)\n"
        f"  CleanRoomProvider.VerifierDisclosure.seed({ids}, {path})\n"
        "rescue\n"
        "  _error ->\n"
        f"    File.write!({path}, Jason.encode!(%{{failure_stage: \"host_setup\"}}), [:binary])\n"
        f"    File.chmod!({path}, 0o600)\n"
        "    IO.puts(\"VERIFIER_DISCLOSURE_SEED_FAILURE=host_setup\")\n"
        "end"
    )


def _assert_safe_channels(stdout: str, stderr: str, redactor: Redactor) -> None:
    redactor.assert_safe(stdout)
    redactor.assert_safe(stderr)


def _record_server_started(destination: Path, resource: dict[str, object], process: subprocess.Popen[bytes]) -> None:
    resource.update({
        "server_pid": process.pid,
        "process_group": getattr(process, "lockspire_process_group", process.pid),
        "started_at": getattr(process, "lockspire_started_at", None),
        "server_state": "starting",
    })
    _persist_resource(destination, resource)


def _start_server(
    host: Path,
    env: dict[str, str],
    issuer: str,
    *,
    on_started,
) -> subprocess.Popen[bytes]:
    server_env = dict(env)
    server_env["CLEAN_ROOM_HTTP_SERVER"] = "true"
    # Caller persists the server PID immediately after Popen returns; startup output is discarded.
    process = start_owned_session(
        ("mix", "run", "--no-halt"), cwd=host, env=server_env,
        stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    process.lockspire_process_group = process.pid  # type: ignore[attr-defined]
    process.lockspire_started_at = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())  # type: ignore[attr-defined]
    on_started(process)
    deadline = time.monotonic() + 25
    while time.monotonic() < deadline:
        if process.poll() is not None:
            stop_process_group(process)
            raise PackageInputError("installed disclosure host stopped before HTTP readiness")
        try:
            with urllib.request.urlopen(issuer + "/.well-known/openid-configuration", timeout=1) as response:
                if response.status == 200:
                    return process
        except OSError:
            time.sleep(0.1)
    stop_process_group(process)
    raise PackageInputError("installed disclosure host did not reach HTTP readiness")


def _stop_owned_server(process: subprocess.Popen[bytes], port: int) -> dict[str, object]:
    process_group = getattr(process, "lockspire_process_group", process.pid)
    stop_ok = stop_process_group(process)
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        stop_ok = False
    return_code = process.poll()
    return {
        "stop_requested": True,
        "process_group_stop_confirmed": stop_ok and return_code is not None,
        "process_exit_code": return_code,
        "listener_port": port,
        "listener_bindable_after_stop": _listener_bindable(port),
        "listener_accepting_after_stop": _listener_accepting(port),
    }


def _listener_bindable(port: int) -> bool:
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
            listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            listener.bind(("127.0.0.1", port))
        return True
    except OSError:
        return False


def _listener_accepting(port: int) -> bool:
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=0.5):
            return True
    except OSError:
        return False


def _database_exists(name: str) -> bool:
    command = [
        "psql", "-h", os.environ.get("CLEAN_ROOM_DB_HOST", "127.0.0.1"),
        "-p", os.environ.get("CLEAN_ROOM_DB_PORT", "5432"),
        "-U", os.environ.get("CLEAN_ROOM_DB_USER", "postgres"),
        "-d", "postgres",
        "-Atc", "SELECT 1 FROM pg_database WHERE datname = '" + name.replace("'", "''") + "'",
    ]
    env = os.environ.copy()
    if "CLEAN_ROOM_DB_PASSWORD" in env:
        env["PGPASSWORD"] = env["CLEAN_ROOM_DB_PASSWORD"]
    try:
        result = subprocess.run(command, env=env, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False, timeout=15)
    except (OSError, subprocess.SubprocessError):
        raise PackageInputError("owned disclosure database cleanup could not be verified") from None
    if result.returncode:
        raise PackageInputError("owned disclosure database cleanup check failed")
    return bool(result.stdout.decode(errors="replace").strip())

