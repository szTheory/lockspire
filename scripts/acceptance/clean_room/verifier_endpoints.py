"""Installed mounted-HTTP verifier endpoints and running-release RPC proofs."""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

HERE = Path(__file__).resolve().parent.parent
import sys
sys.path.insert(0, str(HERE))

import clean_room_verifier_upgrade as runner  # noqa: E402
import verifier_rollout  # noqa: E402
from build_provider import (  # noqa: E402
    PackageInputError, allocate_port, prepare_provider, run_child_command,
    run_child_command_output,
)
from package_input import (  # noqa: E402
    PackageSource, clean_room_database_url, prepare_package, sha256,
    source_revision, verify_candidate_input,
)
from redaction import Redactor, SentinelSet  # noqa: E402
from verifier_receipts import validate_receipt  # noqa: E402


ENDPOINT_CASES = (
    "VPROOF-02-HTTP-TOKEN-JWT",
    "VPROOF-02-HTTP-INTROSPECTION-JWT",
    "VPROOF-02-HTTP-REVOCATION-JWT",
    "VPROOF-02-HTTP-DEVICE-JWT",
    "VPROOF-02-HTTP-CIBA-JWT",
    "VPROOF-02-HTTP-PAR-JWT-REJECTED",
    "VPROOF-02-HTTP-JWT-NEGATIVE-CONTROLS",
    "VPROOF-02-HTTP-BASIC-CONTROL",
    "VPROOF-02-HTTP-POST-CONTROL",
)
RELEASE_CASE = "VPROOF-02-RELEASE-RPC-DRY-RUN"


def run_group(*, pair: str, store: str, receipt_dir: Path) -> list[dict[str, object]]:
    pairs = ("locked", "floor") if pair == "all" else (pair,)
    if any(item not in {"locked", "floor"} for item in pairs) or store != "builtin":
        raise PackageInputError("unsupported endpoint dependency pair or storage composition")
    receipts = [_run_endpoint_cell(item, receipt_dir / f"{item}-builtin") for item in pairs]
    _print_group("endpoints", receipts, receipt_dir)
    return receipts


def run_release_rpc_group(*, pair: str, store: str, receipt_dir: Path) -> list[dict[str, object]]:
    if pair != "locked" or store != "builtin":
        raise PackageInputError("release-rpc supports only locked/builtin selection")
    receipt = _run_release_rpc(receipt_dir / "locked-builtin")
    _print_group("release-rpc", [receipt], receipt_dir)
    return [receipt]


def _run_release_rpc(receipt_dir: Path) -> dict[str, object]:
    run_id = uuid.uuid4().hex
    port = allocate_port()
    prefix = "vrp" + run_id[:12]
    issuer = f"http://127.0.0.1:{port}/lockspire"
    database_url = clean_room_database_url("verifier_release_rpc")
    key_encryption = base64.urlsafe_b64encode(os.urandom(32)).rstrip(b"=").decode("ascii")
    task_key = base64.urlsafe_b64encode(os.urandom(32)).rstrip(b"=").decode("ascii")
    release_key = base64.urlsafe_b64encode(os.urandom(32)).rstrip(b"=").decode("ascii")
    redactor = Redactor(SentinelSet.for_run())
    for material in (database_url, key_encryption, task_key, release_key):
        redactor.register_material(material)
    host: Path | None = None
    env: dict[str, str] = {}
    release_env: dict[str, str] = {}
    release_bin: Path | None = None
    release_root: Path | None = None
    release_started = False
    release_pid: str | None = None
    with tempfile.TemporaryDirectory(prefix="lockspire-verifier-release-rpc-") as temporary:
        root = Path(temporary)
        package, _entries, identity = prepare_package(root, PackageSource("checkout"))
        archive = package.parent / f"lockspire-{identity.version}.tar"
        verify_candidate_input(archive, package, identity)
        host = prepare_provider(
            root, database_url, package_root=package, port=port,
            storage_prefix=prefix, candidate_identity=identity, proof_pair="locked",
            scenario_groups={"release-rpc"},
        )
        env = runner._mix_env(host, root, database_url, port, issuer, prefix, key_encryption, "locked")
        env["LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY"] = task_key
        env["LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY_ID"] = "task-local"
        env["CLEAN_ROOM_HTTP_SERVER"] = "false"
        _configure_release_host(host)
        try:
            run_child_command(host, env, "ecto.create")
            run_child_command(host, env, "ecto.migrate", "--migrations-path", "priv/repo/migrations")

            task_result = _run_bare_mix_check(host, env, redactor)
            if not task_result["ready"]:
                raise PackageInputError("task-local Mix custody check did not complete successfully")

            release_env = dict(env)
            release_env.update({
                "MIX_ENV": "prod",
                "MIX_BUILD_PATH": str((host / "_build" / "prod").resolve()),
                "LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY": release_key,
                "LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY_ID": "release-startup",
                "CLEAN_ROOM_HTTP_SERVER": "true",
                "RELEASE_DISTRIBUTION": "name",
                "RELEASE_NODE": "lockspire-verifier-" + run_id[:12] + "@127.0.0.1",
                "RELEASE_COOKIE": base64.urlsafe_b64encode(os.urandom(32)).decode("ascii"),
                "RELEASE_TMP": str(root / "release-tmp"),
            })
            redactor.register_material(release_env["RELEASE_COOKIE"])
            Path(release_env["RELEASE_TMP"]).mkdir(mode=0o700, parents=True)
            assembled = subprocess.run(
                ("mix", "release"), cwd=host, env=release_env, stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False, timeout=240,
            )
            if assembled.returncode != 0:
                safe = redactor.text(assembled.stdout.decode(errors="replace"))[-1200:]
                redactor.assert_safe(safe)
                raise PackageInputError("installed locked host release assembly failed (exit " +
                                        str(assembled.returncode) + "): " + safe)
            release_root = host / "_build" / "prod" / "rel" / "clean_room_provider"
            release_bin = release_root / "bin" / "clean_room_provider"
            if not release_bin.is_file():
                actual_releases = sorted(path.relative_to(host).as_posix()
                                         for path in (host / "_build" / "prod" / "rel").glob("*/bin/*")
                                         if path.is_file())
                safe_build_output = redactor.text(assembled.stdout.decode(errors="replace"))[-900:]
                redactor.assert_safe(safe_build_output)
                raise PackageInputError("assembled installed release executable is missing; found " +
                                        json.dumps(actual_releases) + "; build output: " + safe_build_output)
            start = _release_command(release_bin, release_env, "start", redactor=redactor)
            if start.returncode != 0:
                raise PackageInputError("assembled release did not start (exit " + str(start.returncode) + ")")
            release_started = True
            _wait_release_http(issuer)

            dry_expression = _release_rpc_expression("dry_run")
            dry = _release_command(release_bin, release_env, "rpc", dry_expression, redactor=redactor)
            dry_markers = _parse_rpc_markers(dry.stdout.decode(errors="replace"), redactor)
            if dry.returncode != 0 or not dry_markers.get("RPC_STATUS") == "ok":
                raise PackageInputError("running release dry-run RPC failed (exit " + str(dry.returncode) + ")")
            release_pid = dry_markers.get("PROCESS_PID")

            check_expression = _release_rpc_expression("check")
            checked = _release_command(release_bin, release_env, "rpc", check_expression, redactor=redactor)
            check_markers = _parse_rpc_markers(checked.stdout.decode(errors="replace"), redactor)
            if checked.returncode != 0 or check_markers.get("RPC_STATUS") != "ok":
                raise PackageInputError("running release fresh-check RPC failed (exit " + str(checked.returncode) + ")")

            module_path_text = dry_markers.get("MODULE_PATH", "")
            if not module_path_text:
                raise PackageInputError("release RPC did not report the loaded maintenance module")
            module_path = Path(module_path_text).resolve()
            release_root_real = release_root.resolve()
            if module_path != release_root_real and release_root_real not in module_path.parents:
                raise PackageInputError("release RPC loaded the maintenance module outside the assembled release")
            module_relative = module_path.relative_to(release_root_real).as_posix()
            module_digest = sha256(module_path)
            provenance = runner.candidate_host_provenance(host)
            phoenix, live_view = runner._framework_versions(host, env)
            elixir, otp, pg = runner._actual_runtime(host, env)
            obs = {
                "outcome": "pass", "executed": True, "assembly_succeeded": True,
                "running_process_observed": True, "rpc_executed": True,
                "startup_mode_dedicated": dry_markers.get("STARTUP_WRITE_MODE") == "dedicated",
                "task_local_mode_dedicated": task_result["mode_dedicated"],
                "task_local_check_ready": task_result["ready"],
                "rpc_dry_run_complete": dry_markers.get("RPC_SCAN_COMPLETE") == "true",
                "rpc_fresh_check_ready": check_markers.get("RPC_CUSTODY_READY") == "true",
                "loaded_candidate_verified": True,
                "rpc_exit_code": dry.returncode, "check_exit_code": checked.returncode,
                "task_local_exit_code": task_result["exit_code"], "process_pid": release_pid or "",
                "release_node": release_env["RELEASE_NODE"],
                "rpc_invocation": "bin/clean_room_provider rpc Lockspire.Admin.ClientVerifierMaintenance.run(mode: :dry_run, limit: 100)",
                "check_invocation": "bin/clean_room_provider rpc Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check, limit: 100)",
                "task_local_invocation": "mix lockspire.clients.verifier.rewrap --check --limit 100",
                "compiled_module_relative_path": module_relative,
                "compiled_module_sha256": module_digest,
                "startup_context_source": dry_markers.get("RPC_CONTEXT_SOURCE", ""),
                "task_local_context_source": task_result["context_source"],
                "startup_current_key_id": dry_markers.get("STARTUP_CURRENT_KEY_ID", ""),
                "task_local_current_key_id": "task-local",
                "dry_run_scanned": _safe_int(dry_markers.get("RPC_SCANNED")),
                "dry_run_pending": _safe_int(dry_markers.get("RPC_PENDING")),
                "fresh_check_scanned": _safe_int(check_markers.get("RPC_SCANNED")),
            }
            if not all(value for key, value in obs.items() if key.endswith(("_ready", "_complete", "_succeeded", "_observed", "_verified", "_dedicated", "_executed"))):
                raise PackageInputError("release RPC startup snapshot or safe report assertion failed")
            candidate = _candidate(identity)
            receipt = {
                "schema": "lockspire-installed-verifier-v1", "scope": "release-rpc",
                "run_id": run_id, "runner": source_revision(), "pair": "locked",
                "store": "builtin", "candidate": candidate,
                "host": {**provenance, "lock_sha256": sha256(runner.PROOF_PAIR_LOCKS["locked"]),
                         "phoenix": phoenix, "live_view": live_view},
                "runtime": {"elixir": elixir, "otp": otp, "postgresql": pg},
                "stable_case_ids": ["VPROOF-02-RELEASE-RPC-DRY-RUN"],
                "observations": {"VPROOF-02-RELEASE-RPC-DRY-RUN": obs},
                "executed_count": 1, "partial": True,
            }
            validate_receipt(receipt, expected_pair="locked", expected_store="builtin")
            redactor.assert_safe(json.dumps(receipt, sort_keys=True))
            _write_receipt(receipt_dir, receipt)
            return {"pair": "locked", "store": "builtin", "scope": "release-rpc",
                    "receipt_path": str(receipt_dir / "receipt.json")}
        finally:
            if release_started and release_bin is not None:
                stopped = _release_command(release_bin, release_env, "stop", redactor=redactor)
                if stopped.returncode != 0:
                    raise PackageInputError("owned release cleanup did not stop the run-scoped node")
            if host is not None and host.exists():
                try:
                    run_child_command(host, env, "ecto.drop")
                except PackageInputError:
                    pass


def _configure_release_host(host: Path) -> None:
    runtime = host / "config" / "runtime.exs"
    runtime.write_text(runtime.read_text(encoding="utf-8") + '''
config :clean_room_provider, CleanRoomProviderWeb.Endpoint,
  server: System.get_env("CLEAN_ROOM_HTTP_SERVER", "false") == "true"

config :lockspire, Lockspire.Security.ClientSecretVerifier,
  keys: [{System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY_ID"), System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY")}],
  current: System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY_ID"),
  write_mode: :dedicated,
  legacy_read: :allow
''', encoding="utf-8")


def _run_bare_mix_check(host: Path, env: dict[str, str], redactor: Redactor) -> dict[str, object]:
    completed = subprocess.run(
        ("mix", "lockspire.clients.verifier.rewrap", "--check", "--limit", "100"),
        cwd=host, env=env, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, check=False, timeout=90,
    )
    output = redactor.text(completed.stdout.decode(errors="replace"))
    match = re.search(r"mode=check context_source=(task_local|startup) scan_complete=(true|false)", output)
    return {"exit_code": completed.returncode, "context_source": match.group(1) if match else "",
            "ready": completed.returncode == 0 and "Current-key custody check passed." in output,
            "mode_dedicated": "mode=check" in output and "context_source=task_local" in output}


def _release_rpc_expression(mode: str) -> str:
    return (
        "result = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :" + mode + ", limit: 100); "
        "report = case result do {:ok, value} -> IO.puts(\"RPC_STATUS=ok\"); value; "
        "{:error, value} when is_map(value) -> IO.puts(\"RPC_STATUS=error\"); value; "
        "_ -> IO.puts(\"RPC_STATUS=error\"); %{} end; "
        "IO.puts(\"RPC_MODE=\" <> to_string(Map.get(report, :mode))); "
        "IO.puts(\"RPC_CONTEXT_SOURCE=\" <> to_string(Map.get(report, :context_source))); "
        "IO.puts(\"RPC_SCAN_COMPLETE=\" <> to_string(Map.get(report, :scan_complete?))); "
        "IO.puts(\"RPC_CUSTODY_READY=\" <> to_string(Map.get(report, :custody_condition_met?))); "
        "IO.puts(\"RPC_SCANNED=\" <> Integer.to_string(Map.get(report, :scanned, 0))); "
        "IO.puts(\"RPC_PENDING=\" <> Integer.to_string(Map.get(report, :pending, 0))); "
        "IO.puts(\"PROCESS_PID=\" <> System.pid()); "
        "IO.puts(\"MODULE_PATH=\" <> List.to_string(:code.which(Lockspire.Admin.ClientVerifierMaintenance))); "
        "config = Application.get_env(:lockspire, Lockspire.Security.ClientSecretVerifier, []); "
        "IO.puts(\"STARTUP_WRITE_MODE=\" <> to_string(Keyword.get(config, :write_mode))); "
        "IO.puts(\"STARTUP_CURRENT_KEY_ID=\" <> to_string(Keyword.get(config, :current)))"
    )


def _release_command(release_bin: Path, env: dict[str, str], *args: str,
                     redactor: Redactor | None = None) -> subprocess.CompletedProcess[bytes]:
    try:
        result = subprocess.run((str(release_bin), *args), cwd=release_bin.parents[1], env=env,
                                stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, check=False, timeout=90)
    except subprocess.TimeoutExpired:
        raise PackageInputError("run-owned release command exceeded its bounded time limit") from None
    if redactor is not None:
        text_output = redactor.text(result.stdout.decode(errors="replace"))
        redactor.assert_safe(text_output)
        if result.returncode != 0:
            safe_tail = text_output[-1000:]
            raise PackageInputError("run-owned release command failed (exit " + str(result.returncode) +"): " + safe_tail)
    return result


def _wait_release_http(issuer: str) -> None:
    deadline = time.monotonic() + 35
    while time.monotonic() < deadline:
        try:
            with urllib.request.urlopen(issuer + "/.well-known/openid-configuration", timeout=1) as response:
                if response.status == 200:
                    return
        except OSError:
            time.sleep(0.15)
    raise PackageInputError("assembled release did not become HTTP ready")


def _parse_rpc_markers(output: str, redactor: Redactor) -> dict[str, str]:
    safe = redactor.text(output)
    markers = {}
    for line in safe.splitlines():
        match = re.fullmatch(r"(RPC_STATUS|RPC_MODE|RPC_CONTEXT_SOURCE|RPC_SCAN_COMPLETE|RPC_CUSTODY_READY|RPC_SCANNED|RPC_PENDING|PROCESS_PID|MODULE_PATH|STARTUP_WRITE_MODE|STARTUP_CURRENT_KEY_ID)=(.*)", line.strip())
        if match:
            markers[match.group(1)] = match.group(2)
    return markers


def _safe_int(value: str | None) -> int:
    return int(value) if isinstance(value, str) and re.fullmatch(r"[0-9]+", value) else -1


def _run_endpoint_cell(pair: str, receipt_dir: Path) -> dict[str, object]:
    run_id = uuid.uuid4().hex
    port = allocate_port()
    prefix = "vep" + run_id[:12]
    issuer = f"http://127.0.0.1:{port}/lockspire"
    key = base64.urlsafe_b64encode(os.urandom(32)).rstrip(b"=").decode("ascii")
    database_url = clean_room_database_url("verifier_endpoints")
    redactor = Redactor(SentinelSet.for_run())
    for material in (key, database_url):
        redactor.register_material(material)
    server = None
    env: dict[str, str] = {}
    host: Path | None = None
    with tempfile.TemporaryDirectory(prefix=f"lockspire-verifier-endpoints-{pair}-") as temporary:
        root = Path(temporary)
        package, _entries, identity = prepare_package(root, PackageSource("checkout"))
        archive = package.parent / f"lockspire-{identity.version}.tar"
        verify_candidate_input(archive, package, identity)
        host = prepare_provider(
            root, database_url, package_root=package, port=port,
            storage_prefix=prefix, candidate_identity=identity, proof_pair=pair,
            scenario_groups={"endpoints"},
        )
        env = runner._mix_env(host, root, database_url, port, issuer, prefix, key, pair)
        env["CLEAN_ROOM_HTTP_SERVER"] = "false"
        verifier_rollout._configure(host=host, mode="dedicated", legacy_read="reject", key=key)
        try:
            run_child_command(host, env, "ecto.create")
            run_child_command(host, env, "ecto.migrate", "--migrations-path", "priv/repo/migrations")
            runner._provision_signing_key(host, env)
            clients = _register_clients(host, env, redactor, run_id)
            server, process = verifier_rollout._start_server(host, env, root / "provider.log", issuer)

            jwt = clients["jwt"]
            discovered_issuer = _discover_issuer(issuer)
            token = _issue_token(issuer, jwt, redactor)
            introspection = _endpoint_post(
                issuer, issuer + "/introspect", jwt, {"token": token["access_token"]}, redactor
            )
            revocation = _endpoint_post(
                issuer, issuer + "/revoke", jwt, {"token": token["access_token"]}, redactor
            )
            device = _endpoint_post(issuer, issuer + "/device/code", jwt, {"scope": "openid"}, redactor)
            ciba = _endpoint_post(
                issuer, issuer + "/bc-authorize", jwt,
                {"scope": "openid", "login_hint": "valid-user"}, redactor,
            )
            par = _endpoint_post(
                issuer, issuer + "/par", jwt,
                {"response_type": "code", "client_id": jwt["client_id"],
                 "redirect_uri": "https://client.example/callback", "scope": "openid"}, redactor,
            )
            negatives = _negative_assertions(issuer, jwt, redactor)
            basic = _issue_token(issuer, clients["basic"], redactor, method="basic")
            post = _issue_token(issuer, clients["post"], redactor, method="post")

            results = {
                ENDPOINT_CASES[0]: _positive(token["status"] == 200 and token["token_issued"], token["status"], configured_issuer=issuer, discovered_issuer=discovered_issuer),
                ENDPOINT_CASES[1]: _positive(introspection["status"] == 200 and introspection["active"] is True, introspection["status"], configured_issuer=issuer, discovered_issuer=discovered_issuer),
                ENDPOINT_CASES[2]: _positive(revocation["status"] == 200, revocation["status"], configured_issuer=issuer, discovered_issuer=discovered_issuer),
                ENDPOINT_CASES[3]: _positive(device["status"] == 200 and device["result"], device["status"], device.get("safe_error"), device.get("safe_description"), configured_issuer=issuer, discovered_issuer=discovered_issuer),
                ENDPOINT_CASES[4]: _positive(ciba["status"] == 200 and ciba["result"], ciba["status"], ciba.get("safe_error"), ciba.get("safe_description"), configured_issuer=issuer, discovered_issuer=discovered_issuer),
                ENDPOINT_CASES[5]: _positive(par["status"] in (400, 401) and not par["success"], par["status"], par.get("safe_error"), par.get("safe_description"), configured_issuer=issuer, discovered_issuer=discovered_issuer),
                ENDPOINT_CASES[6]: _positive(all(negatives.values()), 400 if all(negatives.values()) else 200, configured_issuer=issuer, discovered_issuer=discovered_issuer),
                ENDPOINT_CASES[7]: _positive(basic["status"] == 200 and basic["token_issued"], basic["status"], configured_issuer=issuer, discovered_issuer=discovered_issuer),
                ENDPOINT_CASES[8]: _positive(post["status"] == 200 and post["token_issued"], post["status"], configured_issuer=issuer, discovered_issuer=discovered_issuer),
            }
            if not all(item["outcome"] == "pass" for item in results.values()):
                safe_results = {case: {"http_status": item["http_status"],
                                       "assertion_passed": item["assertion_passed"],
                                       "oauth_error": item.get("safe_error"),
                                       "safe_description": item.get("safe_description")}
                                for case, item in results.items()}
                raise PackageInputError("one or more installed endpoint assertions failed: " +
                                        json.dumps(safe_results, sort_keys=True))
            candidate = _candidate(identity)
            provenance = runner.candidate_host_provenance(host)
            phoenix, live_view = runner._framework_versions(host, env)
            elixir, otp, pg = runner._actual_runtime(host, env)
            receipt = {
                "schema": "lockspire-installed-verifier-v1", "scope": "endpoints",
                "run_id": run_id, "runner": source_revision(), "pair": pair,
                "store": "builtin", "candidate": candidate,
                "host": {**provenance, "lock_sha256": sha256(runner.PROOF_PAIR_LOCKS[pair]),
                         "phoenix": phoenix, "live_view": live_view},
                "runtime": {"elixir": elixir, "otp": otp, "postgresql": pg},
                "stable_case_ids": list(ENDPOINT_CASES),
                "observations": {case: {key: value for key, value in item.items()
                                        if key not in {"safe_error", "safe_description"}}
                                 for case, item in results.items()},
                "executed_count": len(results), "partial": True,
            }
            validate_receipt(receipt, expected_pair=pair, expected_store="builtin")
            redactor.assert_safe(json.dumps(receipt, sort_keys=True))
            _write_receipt(receipt_dir, receipt)
            return {"pair": pair, "store": "builtin", "scope": "endpoints",
                    "receipt_path": str(receipt_dir / "receipt.json")}
        finally:
            if server is not None:
                verifier_rollout._stop_owned_server(server)
            if host is not None and host.exists():
                try:
                    run_child_command(host, env, "ecto.drop")
                except PackageInputError:
                    pass


def _register_clients(host: Path, env: dict[str, str], redactor: Redactor, run_id: str) -> dict[str, dict[str, str]]:
    completed = subprocess.run(
        ("mix", "run", "test/clean_room/verifier_endpoints.exs", run_id),
        cwd=host, env=env, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, check=False, timeout=90,
    )
    output = completed.stdout.decode(errors="replace")
    clients: dict[str, dict[str, str]] = {}
    for line in output.splitlines():
        match = re.fullmatch(r"CLIENT=" + re.escape(run_id) + r":([^:]+):(.+)", line.strip())
        if not match:
            continue
        client_id, secret = match.groups()
        redactor.register_material(client_id)
        redactor.register_material(secret)
        label = "jwt" if client_id.endswith("jwt-" + run_id) else "basic" if "-basic-" in client_id else "post"
        clients[label] = {"client_id": client_id, "secret": secret}
    if completed.returncode != 0 or set(clients) != {"jwt", "basic", "post"}:
        redactor.register_material(output)
        safe = redactor.text(output)[-1000:]
        redactor.assert_safe(safe)
        raise PackageInputError("host-owned endpoint client fixture failed: " + safe)
    return clients


def _issue_token(issuer: str, client: dict[str, str], redactor: Redactor, *, method: str = "jwt") -> dict[str, object]:
    redirect_uri, verifier, code = runner._authorization_code(
        issuer, int(urllib.parse.urlparse(issuer).port), client["client_id"], redactor, remember=False
    )
    fields: dict[str, str] = {
        "grant_type": "authorization_code", "code": code, "redirect_uri": redirect_uri,
        "code_verifier": verifier,
    }
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    if method == "jwt":
        fields.update(_assertion_fields(issuer, client, redactor))
    elif method == "basic":
        encoded = base64.b64encode(f'{client["client_id"]}:{client["secret"]}'.encode()).decode("ascii")
        redactor.register_material(encoded)
        headers["Authorization"] = "Basic " + encoded
    else:
        fields["client_id"] = client["client_id"]
        fields["client_secret"] = client["secret"]
    status, payload = _post(issuer + "/token", fields, headers)
    token = payload.get("access_token")
    if isinstance(token, str):
        redactor.register_material(token)
    return {"status": status, "token_issued": isinstance(token, str) and bool(token),
            "access_token": token if isinstance(token, str) else ""}


def _endpoint_post(issuer: str, url: str, client: dict[str, str], fields: dict[str, str],
                   redactor: Redactor) -> dict[str, object]:
    body = dict(fields)
    body.update(_assertion_fields(issuer, client, redactor))
    status, payload = _post(url, body, {"Content-Type": "application/x-www-form-urlencoded"})
    for name in ("access_token", "refresh_token", "device_code", "auth_req_id", "user_code"):
        value = payload.get(name)
        if isinstance(value, str):
            redactor.register_material(value)
    safe_errors = {"invalid_client", "invalid_request", "invalid_grant", "invalid_scope", "unauthorized_client"}
    safe_description = payload.get("error_description")
    if safe_description not in runner.SAFE_OAUTH_DESCRIPTIONS:
        safe_description = None
    return {"status": status, "active": payload.get("active"),
            "success": status in (200, 201) and not isinstance(payload.get("error"), str),
            "result": bool(set(payload) - {"error", "error_description"}),
            "safe_error": payload.get("error") if payload.get("error") in safe_errors else None,
            "safe_description": safe_description}


def _assertion_fields(issuer: str, client: dict[str, str], redactor: Redactor, *, alg: str = "HS256",
                      aud: str | None = None, iss: str | None = None, exp_delta: int = 300,
                      jti: str | None = None) -> dict[str, str]:
    assertion_id = jti or uuid.uuid4().hex
    redactor.register_material(assertion_id)
    now = int(time.time())
    header = runner._b64(json.dumps({"alg": alg, "typ": "JWT"}, separators=(",", ":")).encode())
    claims = runner._b64(json.dumps({"iss": iss or client["client_id"], "sub": client["client_id"],
                                     "aud": aud or issuer, "jti": assertion_id, "iat": now,
                                     "exp": now + exp_delta}, separators=(",", ":")).encode())
    digest = hashlib.sha384 if alg == "HS384" else hashlib.sha256
    signature = runner._b64(hmac.new(client["secret"].encode(), f"{header}.{claims}".encode(), digest).digest())
    assertion = f"{header}.{claims}.{signature}"
    redactor.register_material(assertion)
    return {"client_id": client["client_id"],
            "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
            "client_assertion": assertion}


def _negative_assertions(issuer: str, client: dict[str, str], redactor: Redactor) -> dict[str, bool]:
    checks: dict[str, bool] = {}
    for label, options in (
        ("algorithm", {"alg": "HS384"}),
        ("audience", {"aud": issuer + "/wrong"}),
        ("issuer", {"iss": "wrong-issuer"}),
        ("expiry", {"exp_delta": -300}),
    ):
        redirect_uri, verifier, code = runner._authorization_code(
            issuer, int(urllib.parse.urlparse(issuer).port), client["client_id"], redactor, remember=False
        )
        fields = {"grant_type": "authorization_code", "code": code,
                  "redirect_uri": redirect_uri, "code_verifier": verifier,
                  **_assertion_fields(issuer, client, redactor, **options)}
        status, payload = _post(issuer + "/token", fields, {"Content-Type": "application/x-www-form-urlencoded"})
        checks[label] = status in (400, 401) and payload.get("error") == "invalid_client"
    assertion = _assertion_fields(issuer, client, redactor)
    device_form = {"scope": "openid", **assertion}
    first = _post(issuer + "/device/code", device_form, {"Content-Type": "application/x-www-form-urlencoded"})
    replay = _post(issuer + "/device/code", device_form, {"Content-Type": "application/x-www-form-urlencoded"})
    checks["replay"] = first[0] == 200 and replay[0] in (400, 401) and replay[1].get("error") == "invalid_client"
    return checks


def _post(url: str, fields: dict[str, str], headers: dict[str, str]) -> tuple[int, dict[str, object]]:
    request = urllib.request.Request(url, data=urllib.parse.urlencode(fields).encode(), headers=headers, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return response.status, _json_body(response.read())
    except urllib.error.HTTPError as error:
        return error.code, _json_body(error.read())
    except OSError:
        return 0, {}


def _json_body(data: bytes) -> dict[str, object]:
    try:
        payload = json.loads(data)
    except (ValueError, UnicodeError):
        return {}
    return payload if isinstance(payload, dict) else {}


def _positive(passed: bool, status: int, safe_error: str | None = None,
              safe_description: str | None = None, *, configured_issuer: str,
              discovered_issuer: str) -> dict[str, object]:
    return {"outcome": "pass" if passed else "fail", "executed": True,
            "assertion_passed": bool(passed), "fresh_jti": True, "http_status": status,
            "safe_error": safe_error, "safe_description": safe_description,
            "configured_issuer": configured_issuer, "discovered_issuer": discovered_issuer,
            "assertion_audience": configured_issuer,
            "rejected_audience_uri": configured_issuer.rstrip("/") + "/wrong"}


def _discover_issuer(issuer: str) -> str:
    with urllib.request.urlopen(issuer.rstrip("/") + "/.well-known/openid-configuration", timeout=10) as response:
        metadata = _json_body(response.read())
    discovered = metadata.get("issuer")
    if not isinstance(discovered, str) or discovered != issuer:
        raise PackageInputError("installed discovery issuer does not match the configured issuer")
    return discovered


def _candidate(identity: object) -> dict[str, str]:
    return {"kind": identity.kind, "version": identity.version,
            "archive_sha256": identity.archive_sha256, "tree_sha256": identity.tree_sha256,
            "source_revision": identity.source_revision, "runner_revision": identity.runner_revision,
            "source_proof": identity.source_proof}


def _write_receipt(receipt_dir: Path, receipt: dict[str, object]) -> None:
    receipt_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    (receipt_dir / "receipt.json").write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def _print_group(scope: str, receipts: list[dict[str, object]], receipt_dir: Path) -> None:
    print(json.dumps({"scope": scope, "executed_count": len(receipts), "cells": [
        {"pair": row["pair"], "store": row["store"], "scope": scope, "receipt": row["receipt_path"]}
        for row in receipts
    ]}, sort_keys=True), flush=True)
