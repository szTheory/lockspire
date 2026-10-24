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

from admin_receipts import write_receipt
from build_provider import allocate_port, prepare_provider, run_child_command, run_child_command_output
from package_input import PackageInputError, clean_room_database_url, locked_environment, package_source, prepare_package
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
})
BROWSER_STAGES = frozenset({
    "preflight", "chrome_start", "cdp_setup", "login_load", "login_submit", "login_redirect",
    "overview_render", "live_socket_connected", "live_join", "clients_navigation", "clients_render",
})
BROWSER_COUNTS = frozenset({"assets", "websocket_handshakes", "successful_joins", "navigations"})
BROWSER_OBSERVATIONS = frozenset({"login", "overview", "clients", "authorized_http", "connected_hook"})


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
        failure = raw_failure if raw_failure in BROWSER_FAILURES else "failure_unrecognized"
    raw_stage = observed.get("stage")
    stage = raw_stage if isinstance(raw_stage, str) and raw_stage in BROWSER_STAGES else "unknown"
    outcome = observed.get("outcome")
    if not isinstance(outcome, str) or outcome not in {"passed", "failed"}:
        outcome = "unknown"
    raw_counts = observed.get("counts")
    counts = raw_counts if (
        isinstance(raw_counts, dict) and set(raw_counts) == BROWSER_COUNTS and
        all(type(value) is int and value >= 0 for value in raw_counts.values())
    ) else {}
    raw_observations = observed.get("observations")
    observations = raw_observations if (
        isinstance(raw_observations, dict) and set(raw_observations) == BROWSER_OBSERVATIONS and
        all(type(value) is bool for value in raw_observations.values())
    ) else {}
    return {"failure": failure, "stage": stage, "outcome": outcome, "counts": counts, "observations": observations}


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pair", choices=("locked",), required=True)
    parser.add_argument("--mount", choices=("/lockspire", "/teams/ops/identity", "/"), required=True)
    parser.add_argument("--scenario", choices=("tracer",), default="tracer")
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--run-id", default=str(uuid.uuid4()))
    parser.add_argument("--package-tar", type=Path)
    parser.add_argument("--package-sha256")
    parser.add_argument("--hex-version")
    return parser.parse_args(argv)


def runtime_versions(child: Path, env: dict[str, str]) -> dict[str, str]:
    source = (
        'Application.load(:phoenix); Application.load(:phoenix_live_view); '
        'IO.puts([Application.spec(:phoenix, :vsn), Application.spec(:phoenix_live_view, :vsn), '
        'System.version(), :erlang.system_info(:otp_release)] |> Enum.map(&to_string/1) |> Enum.join("|"))'
    )
    output = run_child_command_output(child, env, "run", "--no-start", "-e", source)
    match = re.search(r"(?m)^([0-9][^|\s]*)\|([0-9][^|\s]*)\|([0-9][^|\s]*)\|([0-9][^|\s]*)$", output)
    if not match:
        raise PackageInputError("runtime versions could not be observed")
    return {"phoenix": match.group(1), "live_view": match.group(2), "elixir": match.group(3), "otp": match.group(4)}


def wait_ready(origin: str, process: subprocess.Popen[bytes], timeout: float = 30) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if process.poll() is not None:
            raise PackageInputError("provider host exited before readiness")
        try:
            with urllib.request.urlopen(origin + "/login", timeout=0.5) as response:
                if response.status == 200:
                    return
        except (OSError, urllib.error.URLError):
            pass
        time.sleep(0.05)
    raise PackageInputError("provider host readiness timed out")


def stop_owned(process: subprocess.Popen[bytes] | None) -> bool:
    if process is None:
        return True
    if process.poll() is not None:
        return True
    try:
        os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=5)
        return True
    except (OSError, subprocess.TimeoutExpired):
        try:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)
            return True
        except (OSError, subprocess.TimeoutExpired):
            return False


def main(argv: Sequence[str]) -> int:
    args = parse_args(argv)
    try:
        run_id = str(uuid.UUID(args.run_id))
    except (ValueError, AttributeError):
        print("invalid run id")
        return 2

    redactor = Redactor(SentinelSet.for_run())
    capability = secrets.token_urlsafe(48)
    redactor.register_material(capability)
    started = time.monotonic()
    base = Path(tempfile.mkdtemp(prefix="lockspire-admin-proof-"))
    os.chmod(base, 0o700)
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
        child = prepare_provider(
            base, database_url, package_root=package_root, candidate_identity=identity,
            port=port, admin_proof=True, mount_path=args.mount,
        )
        environment = locked_environment(child, "provider_host", base / "deps-cache")
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
        stage = "host_start"
        port = int(environment["PORT"])
        origin = f"http://127.0.0.1:{port}"
        log = base / "provider.log"
        with log.open("wb") as handle:
            process = subprocess.Popen(("mix", "run", "--no-halt"), cwd=child, env=environment, stdin=subprocess.DEVNULL, stdout=handle, stderr=subprocess.STDOUT, start_new_session=True, close_fds=True)
            wait_ready(origin, process)
        stage = "browser"
        browser_script = Path(__file__).resolve().parents[2] / "test" / "browser" / "packaged_admin_proof.mjs"
        request = json.dumps({"capability": capability, "origin": origin, "mount": args.mount, "runRoot": str(base)})
        browser = subprocess.run(("node", str(browser_script), "--origin", origin, "--mount", args.mount, "--scenario", args.scenario, "--run-root", str(base)), input=request, text=True, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=100, check=False)
        try:
            observed = json.loads(browser.stdout.strip().splitlines()[-1])
        except (json.JSONDecodeError, IndexError):
            observed = {}
        if not isinstance(observed, dict) or observed.get("id") != scenario["id"]:
            print("browser proof failed: observation_malformed", file=sys.stderr)
        if isinstance(observed, dict) and observed.get("id") == scenario["id"]:
            scenario.update({key: observed.get(key, scenario[key]) for key in ("outcome", "duration_ms", "counts", "observations")})
            if observed.get("runtime", {}).get("node"):
                runtime["node"] = observed["runtime"]["node"]
            if observed.get("runtime", {}).get("chrome"):
                runtime["chrome"] = observed["runtime"]["chrome"]
        if (browser.returncode != 0 or scenario["outcome"] != "passed") and isinstance(observed, dict):
            summary = safe_browser_failure_summary(observed)
            print("browser proof failed: " + json.dumps(summary, sort_keys=True), file=sys.stderr)
        cleanup["profile_removed"] = observed.get("profile_removed") is True if isinstance(observed, dict) else False
        if browser.returncode != 0 or scenario["outcome"] != "passed":
            failed = True
    except BaseException as error:
        failed = True
        # Do not retain exception strings; known stage names are the only diagnostics.
        detail = redactor.text(error)
        safe_errors = (
            "provider installer failed", "generated admin route authorization seam changed",
            "provider router proof-control insertion point changed", "admin proof host source is missing",
            "admin proof browser initializer is missing", "provider boundary audit found forbidden seam",
            "provider boundary audit found forbidden lifetime-adapter reference",
            "provider lifetime adapter is missing a documented public seam",
            "provider vendor inventory drifted after installation", "provider package installer failed",
        )
        safe_detail = next((candidate for candidate in safe_errors if detail.startswith(candidate)), "unknown")
        if safe_detail == "unknown" and re.fullmatch(r"[A-Za-z0-9_.-]+ failed with exit status [0-9]+", detail):
            safe_detail = detail
        if safe_detail == "unknown" and stage.startswith("database_"):
            lowered = detail.lower()
            safe_detail = next((label for needle, label in (
                ("password authentication failed", "database_authentication_failed"),
                ("connection refused", "database_connection_refused"),
                ("no such file or directory", "database_socket_unavailable"),
                ("no migrations", "migration_files_missing"),
                ("migration path", "migration_path_invalid"),
                ("migration failed", "migration_failed"),
            ) if needle in lowered), "database_command_failed")
        print(f"admin browser proof failed at {stage} {type(error).__name__} ({safe_detail})", file=sys.stderr)
    finally:
        cleanup["processes_stopped"] = stop_owned(process)
        if child is not None and database_created:
            completed = subprocess.run(("mix", "ecto.drop"), cwd=child, env=environment, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30, check=False)
            cleanup["database_removed"] = completed.returncode == 0
        else:
            cleanup["database_removed"] = not database_created
        try:
            shutil.rmtree(base)
            cleanup["run_root_removed"] = not base.exists()
        except OSError:
            cleanup["run_root_removed"] = False

    source_dirty = bool(subprocess.run(("git", "status", "--porcelain", "--untracked-files=no"), cwd=Path(__file__).resolve().parents[2], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False).stdout.strip())
    candidate = {
        "version": getattr(identity, "version", "unknown"),
        "archive_sha256": getattr(identity, "archive_sha256", None) or getattr(identity, "sha256", "0" * 64),
        "tree_sha256": getattr(identity, "tree_sha256", None) or "0" * 64,
    }
    if not source_revision:
        # A receipt without a source identity cannot be validated or treated as evidence.
        print("admin browser proof failed before candidate identity was available", file=sys.stderr)
        return 1
    scenario["duration_ms"] = max(0, int(scenario.get("duration_ms", round((time.monotonic() - started) * 1000))))
    if failed or not all(cleanup.values()):
        scenario["outcome"] = "failed"
    receipt = {
        "schema_version": 1, "run_id": run_id, "source_revision": source_revision,
        "source_dirty": source_dirty, "candidate": candidate, "pair": args.pair,
        "runtime": runtime, "mount": args.mount, "evidence_kind": "real_browser_cdp",
        "scenarios": [scenario], "cleanup": cleanup,
        "result": "passed" if not failed and all(cleanup.values()) and scenario["outcome"] == "passed" else "failed",
    }
    try:
        write_receipt(args.receipt, receipt, expected_run_id=run_id, expected_source=source_revision, expected_pair=args.pair, expected_mount=args.mount, expected_archive=candidate["archive_sha256"], expected_tree=candidate["tree_sha256"], expected_scenario_set="tracer")
    except (OSError, ValueError):
        print("admin browser proof receipt validation failed", file=sys.stderr)
        return 1
    print(json.dumps({"result": receipt["result"], "scenario_count": 1, "cleanup": cleanup}, sort_keys=True))
    return 0 if receipt["result"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
