#!/usr/bin/env python3
"""Install one Lockspire candidate and prove its admin LiveView in real Chrome."""

from __future__ import annotations

import argparse
import base64
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
import uuid
from typing import Sequence

CLEAN_ROOM_DIR = Path(__file__).resolve().parent / "clean_room"
sys.path.insert(0, str(CLEAN_ROOM_DIR))

from admin_receipts import FULL_OBSERVATIONS, FULL_REQUIRED, write_receipt
from build_provider import (
    PROOF_PAIR_VERSIONS,
    allocate_port,
    prepare_provider,
    proof_pair_cache_root,
    run_child_command,
    run_child_command_output,
)
from package_input import bounded_run, start_owned_session, stop_process_group, PackageInputError, clean_room_database_url, locked_environment, package_source, prepare_package
from redaction import Redactor, SentinelSet


DEFAULTS = {
    "id": "tracer.browser_join_navigation", "outcome": "failed", "duration_ms": 0,
    "counts": {"assets": 0, "websocket_handshakes": 0, "successful_joins": 0, "navigations": 0},
    "observations": {"login": False, "overview": False, "clients": False, "authorized_http": False, "connected_hook": False},
}
BROWSER_FAILURES = frozenset({
    "chrome_missing", "node_unsupported", "origin_invalid", "mount_invalid", "chrome_spawn_failed",
    "chrome_start_failed", "chrome_target_failed", "browser_timeout", "login_load_timeout",
    "login_response_non_html", "login_response_empty", "login_path_mismatch", "login_form_missing",
    "login_content_type_invalid", "login_response_content_missing", "login_page_status_200",
    "login_page_status_403", "login_page_status_404", "login_page_status_500", "login_redirect_timeout",
    "login_post_not_sent", "login_post_not_observed", "login_post_network_failed", "login_post_no_redirect",
    "login_redirect_status_302", "login_redirect_status_403", "login_redirect_status_404",
    "login_redirect_status_422", "login_redirect_status_500", "overview_render_timeout",
    "live_socket_connected_timeout", "live_join_timeout", "clients_render_timeout", "cdp_connect_failed",
    "cdp_connect_timeout", "cdp_command_failed", "cdp_command_timeout", "page_evaluation_failed",
    "clients_link_missing", "host_observations_failed", "control_capability_missing", "browser_failure",
    "clients_destination_timeout", "clients_content_timeout", "clients_hook_timeout", "document_reload_during_navigation",
    "case_failed", "assets_missing", "http_denial_missing", "cached_static_missing", "denied_join_missing",
    "denied_params_missing", "cross_session_link_missing", "cross_session_admin_denial_missing",
    "public_route_staff_check", "public_protocol_status_invalid",
})
BROWSER_STAGES = frozenset({
    "preflight", "chrome_start", "cdp_setup", "login_load", "login_submit", "login_redirect",
    "overview_render", "live_socket_connected", "live_join", "clients_navigation", "clients_render",
    "clients_destination", "clients_content", "clients_hook", "full_matrix",
})
BROWSER_COUNTS = frozenset({"assets", "websocket_handshakes", "successful_joins", "navigations"})
BROWSER_OBSERVATIONS = frozenset({"login", "overview", "clients", "authorized_http", "connected_hook"})
BROWSER_SUMMARY_FAILURES = BROWSER_FAILURES | {"failure_missing", "failure_non_string", "failure_unrecognized"}
FAILURE_RECORD_SCHEMA = "lockspire-admin-proof-failure-v1"
FAILURE_REASONS = {
    "candidate": frozenset({"candidate_unavailable"}),
    "provider_preparation": frozenset({"provider_preparation_failed"}),
    "database_create": frozenset({"database_creation_failed"}),
    "database_migrate": frozenset({"database_migration_failed"}),
    "runtime_observation": frozenset({"runtime_observation_failed"}),
    "lifecycle": frozenset({"lifecycle_failed"}),
    "host_startup": frozenset({"host_startup_failed"}),
    "browser": frozenset({"browser_proof_failed"}),
    "receipt": frozenset({"receipt_invalid", "receipt_write_failed"}),
    "cleanup": frozenset({"cleanup_failed"}),
    "diagnostics": frozenset({"failure_record_missing", "failure_record_malformed", "output_limit_exceeded"}),
}


def validate_failure_record(value: object) -> dict[str, object] | None:
    """Accept only the closed, non-sensitive producer-to-wrapper failure contract."""
    base_fields = {"schema", "stage", "reason"}
    if type(value) is not dict or not base_fields <= set(value):
        return None
    schema, stage, reason = value["schema"], value["stage"], value["reason"]
    if (type(schema) is not str or schema != FAILURE_RECORD_SCHEMA or
            type(stage) is not str or type(reason) is not str or
            stage not in FAILURE_REASONS or reason not in FAILURE_REASONS[stage]):
        return None
    if set(value) == base_fields:
        return {"schema": schema, "stage": stage, "reason": reason}
    if set(value) != base_fields | {"host_startup"} or stage != "host_startup":
        return None
    witness = value["host_startup"]
    if type(witness) is not dict or set(witness) != {"host_exit_status", "readiness_deadline_elapsed"}:
        return None
    host_exit_status = witness["host_exit_status"]
    deadline_elapsed = witness["readiness_deadline_elapsed"]
    if (host_exit_status is not None and
            (type(host_exit_status) is not int or not -255 <= host_exit_status <= 255)):
        return None
    if type(deadline_elapsed) is not bool:
        return None
    if (host_exit_status is None) != deadline_elapsed:
        return None
    return {
        "schema": schema,
        "stage": stage,
        "reason": reason,
        "host_startup": {
            "host_exit_status": host_exit_status,
            "readiness_deadline_elapsed": deadline_elapsed,
        },
    }


def emit_failure_record(
    stage: str,
    reason: str,
    *,
    host_startup_witness: dict[str, object] | None = None,
    supplemental_cleanup: bool = False,
) -> None:
    payload: dict[str, object] = {
        "schema": FAILURE_RECORD_SCHEMA,
        "stage": stage,
        "reason": reason,
    }
    if host_startup_witness is not None:
        payload["host_startup"] = host_startup_witness
    record = validate_failure_record(payload)
    if record is None:
        record = {"schema": FAILURE_RECORD_SCHEMA, "stage": "diagnostics", "reason": "failure_record_malformed"}
    prefix = "admin proof cleanup record: " if supplemental_cleanup else "admin proof failure record: "
    print(prefix + json.dumps(record, sort_keys=True), file=sys.stderr)


def safe_enum(value: object, allowed, fallback: str = "unknown") -> str:
    return value if isinstance(value, str) and value in allowed else fallback


def safe_browser_failure_summary(observed: object) -> dict[str, object]:
    """Reduce untrusted Node output to fixed failure codes, counters, and booleans."""
    if not isinstance(observed, dict):
        observed = {}
    raw_failure = observed.get("failure")
    if raw_failure is None:
        failure = "failure_missing"
    elif not isinstance(raw_failure, str):
        failure = "failure_non_string"
    else:
        failure = raw_failure if raw_failure in BROWSER_SUMMARY_FAILURES else "failure_unrecognized"
    raw_stage = observed.get("stage")
    stage = raw_stage if isinstance(raw_stage, str) and raw_stage in BROWSER_STAGES else "unknown"
    outcome = observed.get("outcome")
    if not isinstance(outcome, str) or outcome not in {"passed", "failed"}:
        outcome = "unknown"
    raw_counts = observed.get("counts")
    counts = raw_counts if (
        isinstance(raw_counts, dict) and set(raw_counts) == BROWSER_COUNTS and
        all(type(value) is int and 0 <= value <= 2**31 - 1 for value in raw_counts.values())
    ) else {}
    raw_observations = observed.get("observations")
    observations = raw_observations if (
        isinstance(raw_observations, dict) and set(raw_observations) == BROWSER_OBSERVATIONS and
        all(type(value) is bool for value in raw_observations.values())
    ) else {}
    result = {"failure": failure, "stage": stage, "outcome": outcome, "counts": counts, "observations": observations}
    scenarios = observed.get("scenarios")
    if isinstance(scenarios, list) and scenarios and isinstance(scenarios[0], dict):
        first = scenarios[0]
        raw_case_counts = first.get("counts")
        raw_case_observations = first.get("observations")
        result["first_case"] = {
            "id": safe_enum(first.get("id"), FULL_REQUIRED),
            "failure": safe_enum(first.get("failure"), BROWSER_FAILURES, "failure_unrecognized"),
            "outcome": safe_enum(first.get("outcome"), {"passed", "failed"}),
            "count_fields": sorted(key for key in raw_case_counts if isinstance(key, str) and key in BROWSER_COUNTS | {"params_checks", "http_checks", "staff_checks"}) if isinstance(raw_case_counts, dict) else [],
            "observation_fields": sorted(key for key in raw_case_observations if isinstance(key, str) and key in FULL_OBSERVATIONS) if isinstance(raw_case_observations, dict) else [],
        }
        issues = []
        for item in scenarios:
            if not isinstance(item, dict):
                issues.append({"id": "unknown", "problem": "case_not_object"})
                continue
            obs = item.get("observations")
            if not isinstance(obs, dict):
                issues.append({"id": safe_enum(item.get("id"), FULL_REQUIRED), "problem": "observations_not_object"})
                continue
            keys = set(obs)
            if keys != set(FULL_OBSERVATIONS):
                issues.append({
                    "id": safe_enum(item.get("id"), FULL_REQUIRED),
                    "missing": sorted(set(FULL_OBSERVATIONS) - keys),
                    "unknown_field_count": len(keys - set(FULL_OBSERVATIONS)),
                })
            elif any(type(value) is not bool for value in obs.values()):
                issues.append({"id": safe_enum(item.get("id"), FULL_REQUIRED), "problem": "observation_not_boolean"})
        if issues:
            result["scenario_shape_issues"] = issues[:8]
        failed_cases = []
        for item in scenarios:
            if isinstance(item, dict) and item.get("outcome") != "passed":
                obs = item.get("observations")
                failed_cases.append({
                    "id": safe_enum(item.get("id"), FULL_REQUIRED),
                    "failure": safe_enum(item.get("failure"), BROWSER_FAILURES, "failure_unrecognized"),
                    "false_evidence": sorted(key for key, value in obs.items() if value is False and key in FULL_OBSERVATIONS) if isinstance(obs, dict) else [],
                })
        if failed_cases:
            result["failed_cases"] = failed_cases[:8]
    # The shell also consumes this producer's already-reduced legacy summary.
    # Revalidate that representation with the same finite vocabulary.
    def safe_fields(value: object, allowed) -> list[str]:
        if not isinstance(value, list):
            return []
        return sorted({item for item in value if isinstance(item, str) and item in allowed})

    first = observed.get("first_case")
    if "first_case" not in result and isinstance(first, dict):
        result["first_case"] = {
            "id": safe_enum(first.get("id"), FULL_REQUIRED),
            "failure": safe_enum(first.get("failure"), BROWSER_FAILURES, "failure_unrecognized"),
            "outcome": safe_enum(first.get("outcome"), {"passed", "failed"}),
            "count_fields": safe_fields(first.get("count_fields"), BROWSER_COUNTS | {"params_checks", "http_checks", "staff_checks"}),
            "observation_fields": safe_fields(first.get("observation_fields"), FULL_OBSERVATIONS),
        }
    published_cases = observed.get("failed_cases")
    if "failed_cases" not in result and isinstance(published_cases, list):
        retained = [{
            "id": safe_enum(item.get("id"), FULL_REQUIRED),
            "failure": safe_enum(item.get("failure"), BROWSER_FAILURES, "failure_unrecognized"),
            "false_evidence": safe_fields(item.get("false_evidence"), FULL_OBSERVATIONS),
        } for item in published_cases[:8] if isinstance(item, dict)]
        if retained:
            result["failed_cases"] = retained
    return result


def full_scenarios_from_observation(observed: object) -> list[dict[str, object]]:
    if not isinstance(observed, dict) or not isinstance(observed.get("scenarios"), list):
        return []
    scenarios = observed["scenarios"]
    if len(scenarios) != len(FULL_REQUIRED):
        return []
    return [
        {key: item.get(key) for key in ("id", "outcome", "duration_ms", "counts", "observations")}
        for item in scenarios if isinstance(item, dict)
    ]


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pair", choices=("locked", "floor"), required=True)
    parser.add_argument("--mount", choices=("/lockspire", "/teams/ops/identity", "/"), required=True)
    parser.add_argument("--scenario", choices=("full", "tracer"), default="full")
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--run-id", default=str(uuid.uuid4()))
    parser.add_argument("--package-tar", type=Path)
    parser.add_argument("--package-sha256")
    parser.add_argument("--hex-version")
    return parser.parse_args(argv)


def runtime_versions(child: Path, env: dict[str, str]) -> dict[str, str]:
    source = (
        'Application.load(:phoenix); Application.load(:phoenix_live_view); '
        'Code.ensure_loaded!(Phoenix.Router); Code.ensure_loaded!(Phoenix.LiveView); '
        'paths = [:code.which(Phoenix.Router), :code.which(Phoenix.LiveView), '
        'Application.app_dir(:phoenix, "priv/static/phoenix.js"), '
        'Application.app_dir(:phoenix_live_view, "priv/static/phoenix_live_view.js")]; '
        'IO.puts("RUNTIME_PROOF|" <> Enum.join([Application.spec(:phoenix, :vsn), '
        'Application.spec(:phoenix_live_view, :vsn), System.version(), '
        ':erlang.system_info(:otp_release)] ++ Enum.map(paths, &to_string/1), "|"))'
    )
    output = run_child_command_output(child, env, "run", "--no-start", "-e", source)
    match = re.search(r"(?m)^RUNTIME_PROOF\|(.+)$", output)
    fields = match.group(1).split("|") if match else []
    if len(fields) != 8 or any(not value for value in fields):
        raise PackageInputError("runtime versions could not be observed")
    allowed_roots = [child.resolve()]
    dependency_root = env.get("MIX_DEPS_PATH")
    if dependency_root:
        allowed_roots.append(Path(dependency_root).resolve())
    for source_path in fields[4:]:
        resolved_source = Path(source_path).resolve()
        if not resolved_source.is_file() or not any(
            resolved_source.is_relative_to(allowed_root) for allowed_root in allowed_roots
        ):
            raise PackageInputError("compiled runtime or asset source escaped the isolated provider host")
    return {"phoenix": fields[0], "live_view": fields[1], "elixir": fields[2], "otp": fields[3]}


def validate_pair_runtime(proof_pair: str, runtime: dict[str, str]) -> None:
    expected = PROOF_PAIR_VERSIONS.get(proof_pair)
    if expected is None:
        raise PackageInputError("unsupported admin proof dependency pair")
    if (runtime.get("phoenix"), runtime.get("live_view")) != expected:
        raise PackageInputError("observed Phoenix and LiveView versions do not match selected pair")


def wait_ready(origin: str, process: subprocess.Popen[bytes], timeout: float = 30) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise HostStartupFailure(
                host_exit_status=process.returncode,
                readiness_deadline_elapsed=False,
            )
        try:
            with urllib.request.urlopen(origin + "/login", timeout=0.5) as response:
                if response.status == 200:
                    return
        except (OSError, urllib.error.URLError):
            pass
        time.sleep(0.05)
    raise HostStartupFailure(host_exit_status=None, readiness_deadline_elapsed=True)


class HostStartupFailure(PackageInputError):
    """Finite startup witness captured before owned-process cleanup."""

    def __init__(self, *, host_exit_status: int | None, readiness_deadline_elapsed: bool):
        self.host_startup_witness = {
            "host_exit_status": host_exit_status,
            "readiness_deadline_elapsed": readiness_deadline_elapsed,
        }
        super().__init__("provider host startup did not become ready")


def stop_owned(process: subprocess.Popen[bytes] | None) -> bool:
    return process is None or stop_process_group(process, grace=2)


class ProofInterrupted(BaseException):
    pass


def interrupt_run(signum, _frame):
    raise ProofInterrupted("proof_interrupted")


def main(argv: Sequence[str]) -> int:
    args = parse_args(argv)
    try:
        run_id = str(uuid.UUID(args.run_id))
    except (ValueError, AttributeError):
        emit_failure_record("diagnostics", "failure_record_malformed")
        return 2

    redactor = Redactor(SentinelSet.for_run())
    capability = secrets.token_urlsafe(48)
    redactor.register_material(capability)
    started = time.monotonic()
    base = Path(tempfile.mkdtemp(prefix="lockspire-admin-proof-"))
    os.chmod(base, 0o700)
    previous_handlers = {sig: signal.signal(sig, interrupt_run) for sig in (signal.SIGTERM, signal.SIGINT)}
    source_revision = ""
    package_root: Path | None = None
    identity = None
    child: Path | None = None
    environment: dict[str, str] = {}
    process: subprocess.Popen[bytes] | None = None
    database_url = ""
    database_created = False
    scenario = dict(DEFAULTS)
    runtime: dict[str, str] = {"phoenix": "unknown", "live_view": "unknown", "elixir": "unknown", "otp": "unknown", "node": "unknown", "chrome": "unknown"}
    cleanup = {"processes_stopped": True, "database_removed": False, "profile_removed": True, "run_root_removed": False}
    stage = "candidate"
    failed = False
    scenario_passed = False
    full_scenarios: list[dict[str, object]] = []
    primary_failure: tuple[str, str, dict[str, object] | None] | None = None

    def record_failure(
        failure_stage: str,
        reason: str,
        host_startup_witness: dict[str, object] | None = None,
    ) -> None:
        nonlocal primary_failure
        if primary_failure is None:
            primary_failure = (failure_stage, reason, host_startup_witness)

    def publish_failure() -> None:
        if primary_failure is not None:
            failure_stage, reason, witness = primary_failure
            emit_failure_record(failure_stage, reason, host_startup_witness=witness)
        if not all(cleanup.values()):
            emit_failure_record("cleanup", "cleanup_failed", supplemental_cleanup=primary_failure is not None)

    try:
        selected_source = package_source(args.package_tar, args.hex_version, args.package_sha256)
        package_root, _entries, identity = prepare_package(base, selected_source)
        source_revision = identity.source_revision or ""
        database_url = clean_room_database_url("admin")
        redactor.register_material(database_url)
        redactor.register_material(os.environ.get("CLEAN_ROOM_DB_PASSWORD", "postgres"))
        port = allocate_port()
        mount = "" if args.mount == "/" else args.mount
        admin_path = f"{mount}/admin" or "/admin"
        os.environ["LOCKSPIRE_KEY_ENCRYPTION_KEY"] = base64.b64encode(secrets.token_bytes(32)).decode("ascii")
        redactor.register_material(os.environ["LOCKSPIRE_KEY_ENCRYPTION_KEY"])
        stage = "provider_preparation"
        child = prepare_provider(
            base, database_url, package_root=package_root, candidate_identity=identity,
            port=port, cache_root=Path(os.environ["CLEAN_ROOM_CACHE_ROOT"]) if os.environ.get("CLEAN_ROOM_CACHE_ROOT") else None,
            admin_proof=True, proof_pair=args.pair, mount_path=args.mount,
        )
        configured_cache = Path(os.environ["CLEAN_ROOM_CACHE_ROOT"]) if os.environ.get("CLEAN_ROOM_CACHE_ROOT") else base / "deps-cache"
        dependency_cache = proof_pair_cache_root(configured_cache, args.pair, os.environ.get("MIX_ENV"))
        environment = locked_environment(child, "provider_host", dependency_cache)
        environment.update({
            "DATABASE_URL": database_url,
            "PORT": str(port),
            "LOCKSPIRE_ISSUER": f"http://127.0.0.1:{port}{mount}",
            "LOCKSPIRE_PROOF_CAPABILITY": capability,
            "LOCKSPIRE_PROOF_ADMIN_PATH": admin_path,
            "SECRET_KEY_BASE": secrets.token_urlsafe(48),
        })
        stage = "database_create"
        database_created = True
        run_child_command(child, environment, "ecto.create")
        stage = "database_migrate"
        run_child_command(child, environment, "ecto.migrate", "--migrations-path", "priv/repo/migrations")
        stage = "runtime_versions"
        runtime.update(runtime_versions(child, environment))
        validate_pair_runtime(args.pair, runtime)
        stage = "host_start"
        port = int(environment["PORT"])
        origin = f"http://127.0.0.1:{port}"
        live_environment = dict(environment, CLEAN_ROOM_HTTP_SERVER="true")
        process = start_owned_session(("mix", "run", "--no-halt"), cwd=child, env=live_environment,
                                      stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                                      stderr=subprocess.DEVNULL, close_fds=True)
        wait_ready(origin, process)
        stage = "browser"
        browser_script = Path(__file__).resolve().parents[2] / "test" / "browser" / "packaged_admin_proof.mjs"
        request = json.dumps({"capability": capability, "origin": origin, "mount": args.mount, "scenario": args.scenario, "runRoot": str(base)})
        browser = bounded_run(("node", str(browser_script), "--origin", origin, "--mount", args.mount, "--scenario", args.scenario, "--run-root", str(base)), input=request, stdin=subprocess.PIPE, text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=180, check=False)
        try:
            observed = json.loads(browser.stdout.strip().splitlines()[-1])
        except (json.JSONDecodeError, IndexError):
            observed = {}
        if args.scenario == "tracer":
            if not isinstance(observed, dict) or observed.get("id") != scenario["id"]:
                print("browser proof failed: observation_malformed", file=sys.stderr)
            if isinstance(observed, dict) and observed.get("id") == scenario["id"]:
                scenario.update({key: observed.get(key, scenario[key]) for key in ("outcome", "duration_ms", "counts", "observations")})
                if isinstance(observed.get("runtime"), dict):
                    if observed["runtime"].get("node"):
                        runtime["node"] = observed["runtime"]["node"]
                    if observed["runtime"].get("chrome"):
                        runtime["chrome"] = observed["runtime"]["chrome"]
        else:
            if not isinstance(observed, dict) or observed.get("id") != "full" or not isinstance(observed.get("scenarios"), list):
                print("browser proof failed: observation_malformed", file=sys.stderr)
            else:
                full_scenarios = full_scenarios_from_observation(observed)
            if isinstance(observed, dict) and isinstance(observed.get("runtime"), dict):
                if observed["runtime"].get("node"):
                    runtime["node"] = observed["runtime"]["node"]
                if observed["runtime"].get("chrome"):
                    runtime["chrome"] = observed["runtime"]["chrome"]
        cleanup["profile_removed"] = observed.get("profile_removed") is True if isinstance(observed, dict) else False
        scenario_passed = scenario["outcome"] == "passed" if args.scenario == "tracer" else (
            isinstance(observed, dict) and observed.get("outcome") == "passed" and
            len(full_scenarios) == len(FULL_REQUIRED) and all(item.get("outcome") == "passed" for item in full_scenarios)
        )
        if (browser.returncode != 0 or not scenario_passed) and isinstance(observed, dict):
            summary = safe_browser_failure_summary(observed)
            print("browser proof failed: " + json.dumps(summary, sort_keys=True), file=sys.stderr)
        if browser.returncode != 0 or not scenario_passed:
            record_failure("browser", "browser_proof_failed")
            failed = True
    except BaseException as error:
        failed = True
        # Do not retain exception strings; known stage names are the only diagnostics.
        failure_stage, reason = {
            "candidate": ("candidate", "candidate_unavailable"),
            "provider_preparation": ("provider_preparation", "provider_preparation_failed"),
            "database_create": ("database_create", "database_creation_failed"),
            "database_migrate": ("database_migrate", "database_migration_failed"),
            "runtime_versions": ("runtime_observation", "runtime_observation_failed"),
            "host_start": ("host_startup", "host_startup_failed"),
            "browser": ("browser", "browser_proof_failed"),
        }.get(stage, ("candidate", "candidate_unavailable"))
        startup_witness = (
            error.host_startup_witness
            if failure_stage == "host_startup" and isinstance(error, HostStartupFailure)
            else None
        )
        record_failure(failure_stage, reason, startup_witness)
    finally:
        # Ignore repeated interruption while independent bounded cleanup actions run.
        for sig in previous_handlers:
            signal.signal(sig, signal.SIG_IGN)
        try:
            cleanup["processes_stopped"] = stop_owned(process)
        except Exception:
            cleanup["processes_stopped"] = False
        cleanup["database_removed"] = not database_created
        if child is not None and database_created:
            try:
                completed = bounded_run(("mix", "ecto.drop"), cwd=child, env=environment, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=4, stop_grace=0.5)
                cleanup["database_removed"] = completed.returncode == 0
            except Exception:
                cleanup["database_removed"] = False
        try:
            shutil.rmtree(base)
            cleanup["run_root_removed"] = not base.exists()
        except OSError:
            cleanup["run_root_removed"] = False
        cleanup["profile_removed"] = cleanup["profile_removed"] or cleanup["run_root_removed"]
        for sig, handler in previous_handlers.items():
            signal.signal(sig, handler)

    source_dirty = bool(subprocess.run(("git", "status", "--porcelain"), cwd=Path(__file__).resolve().parents[2], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False, timeout=10).stdout.strip())
    candidate = {
        "version": getattr(identity, "version", "unknown"),
        "archive_sha256": getattr(identity, "archive_sha256", None) or getattr(identity, "sha256", "0" * 64),
        "tree_sha256": getattr(identity, "tree_sha256", None) or "0" * 64,
    }
    if not source_revision:
        # A receipt without a source identity cannot be validated or treated as evidence.
        if not failed:
            record_failure("candidate", "candidate_unavailable")
        publish_failure()
        return 1
    duration_ms = scenario.get("duration_ms", int((time.monotonic() - started) * 1000))
    if type(duration_ms) is not int or duration_ms < 0:
        failed = True
        scenario["outcome"] = "failed"
        duration_ms = 0
        record_failure("browser", "browser_proof_failed")
    scenario["duration_ms"] = duration_ms
    if failed or not all(cleanup.values()):
        scenario["outcome"] = "failed"
    receipt = {
        "schema_version": 1, "run_id": run_id, "source_revision": source_revision,
        "source_dirty": source_dirty, "candidate": candidate, "pair": args.pair,
        "runtime": runtime, "mount": args.mount, "evidence_kind": "real_browser_cdp",
        "scenarios": full_scenarios if args.scenario == "full" else [scenario], "cleanup": cleanup,
        "result": "passed" if not failed and all(cleanup.values()) and scenario_passed else "failed",
    }
    try:
        write_receipt(args.receipt, receipt, expected_run_id=run_id, expected_source=source_revision, expected_pair=args.pair, expected_mount=args.mount, expected_archive=candidate["archive_sha256"], expected_tree=candidate["tree_sha256"], expected_scenario_set=args.scenario)
    except (OSError, ValueError) as error:
        reason = "receipt_invalid" if isinstance(error, ValueError) else "receipt_write_failed"
        record_failure("receipt", reason)
        publish_failure()
        return 1
    publish_failure()
    print(json.dumps({"result": receipt["result"], "scenario_count": len(receipt["scenarios"]), "cleanup": cleanup}, sort_keys=True))
    return 0 if receipt["result"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
