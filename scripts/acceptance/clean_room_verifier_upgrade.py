#!/usr/bin/env python3
"""Run bounded, source-bound installed verifier proof groups."""

from __future__ import annotations

import argparse
import base64
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
import secrets
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "clean_room"))

from build_provider import (  # noqa: E402
    PROOF_PAIR_LOCKS, PROOF_PAIR_VERSIONS, allocate_port, prepare_provider,
    run_child_command, run_child_command_output,
)
from package_input import (  # noqa: E402
    PackageIdentity, PackageInputError, PackageSource, bind_compiled_candidate,
    candidate_host_provenance, clean_room_database_url, locked_environment,
    package_tree_digest, prepare_package, run, sha256, source_revision,
    verify_candidate_input, verify_candidate_host,
)
from redaction import Redactor, SentinelSet  # noqa: E402
import clean_room_saas_journey as browser_support  # noqa: E402
from verifier_receipts import (  # noqa: E402
    GROUPS, REQUIRED_MATRIX, ReceiptError, expected_case_ids, load_receipt,
    validate_complete_matrix, validate_receipt, validate_rollout_receipt,
)


MODULES = {
    "tracer": ("verifier_tracer", "run_tracer"),
    "core": ("verifier_core", "run_group"),
    "rollout": ("verifier_rollout", "run_rollout_group"),
    "legacy-control": ("verifier_rollout", "run_legacy_control_group"),
    "endpoints": ("verifier_endpoints", "run_group"),
    "release-rpc": ("verifier_endpoints", "run_release_rpc_group"),
    "contention": ("verifier_transactions", "run_contention_group"),
    "atomicity": ("verifier_transactions", "run_atomicity_group"),
    "recovery": ("verifier_recovery", "run_recovery_group"),
    "issuance": ("verifier_recovery", "run_issuance_group"),
    "disclosure": ("verifier_disclosure", "run_group"),
}
SENSITIVE_OUTPUT = re.compile(
    r"(?i)(?:client_secret|registration_access_token|access_token|refresh_token|authorization_code|"
    r"pkce_verifier|verifier|private_key|cookie|secret|token|hash)\s*[:=]\s*[\"']?([^\s,;\"'}]+)"
)
SAFE_OAUTH_DESCRIPTIONS = frozenset({
    "Client authentication failed", "Client application has expired", "Client application is disabled",
    "Unable to validate client lifetime state", "Unable to validate client secret lifetime state",
    "Unable to determine client application eligibility", "Unable to determine client secret eligibility",
    "Unable to persist request", "Unable to validate client", "Invalid authorization request",
})


def _b64(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def signed_assertion(secret: str, client_id: str, issuer: str, jti: str, now: int | None = None) -> str:
    issued = int(time.time()) if now is None else now
    header = _b64(b'{"alg":"HS256","typ":"JWT"}')
    claims = json.dumps({"iss": client_id, "sub": client_id, "aud": issuer, "jti": jti, "iat": issued, "exp": issued + 300}, separators=(",", ":")).encode()
    payload = _b64(claims)
    signature = _b64(hmac.new(secret.encode(), f"{header}.{payload}".encode(), hashlib.sha256).digest())
    return f"{header}.{payload}.{signature}"


def _mix_env(host: Path, run_root: Path, database_url: str, port: int, issuer: str, prefix: str, key: str, pair: str) -> dict[str, str]:
    from build_provider import proof_pair_cache_root

    cache_root = proof_pair_cache_root(run_root / "deps-cache", pair)
    env = locked_environment(host, "provider_host", cache_root)
    hex_home = run_root / "hex-home"
    mix_home = run_root / "mix-home"
    verifier_key = base64.urlsafe_b64encode(os.urandom(32)).rstrip(b"=").decode("ascii")
    hex_home.mkdir(mode=0o700, parents=True, exist_ok=True)
    mix_home.mkdir(mode=0o700, parents=True, exist_ok=True)
    env.update({
        "HEX_HOME": str(hex_home), "MIX_HOME": str(mix_home), "MIX_ENV": "dev",
        "DATABASE_URL": database_url, "PORT": str(port), "LOCKSPIRE_ISSUER": issuer,
        "LOCKSPIRE_STORAGE_PREFIX": prefix, "LOCKSPIRE_KEY_ENCRYPTION_KEY": key,
        "LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY": verifier_key,
        "LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY_NEXT": base64.urlsafe_b64encode(os.urandom(32)).rstrip(b"=").decode("ascii"),
        "SECRET_KEY_BASE": "lockspire-installed-verifier-secret-key-base-0123456789abcdefghijklmnopqrstuvwxyz",
    })
    return env


def _configure_verifier_custody(host: Path) -> None:
    runtime_config = host / "config" / "runtime.exs"
    content = runtime_config.read_text(encoding="utf-8")
    marker = "config :lockspire, Lockspire.Security.ClientSecretVerifier,"
    if marker in content:
        raise PackageInputError("generated host already configures client secret verifier custody")
    runtime_config.write_text(
        content
        + """

config :lockspire, Lockspire.Security.ClientSecretVerifier,
  keys: [{"verifier-old", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY")}],
  current: "verifier-old",
  write_mode: :dedicated,
  legacy_read: :reject
""",
        encoding="utf-8",
    )


def _configure_rewrap_verifier_custody(host: Path) -> None:
    runtime_config = host / "config" / "runtime.exs"
    content = runtime_config.read_text(encoding="utf-8")
    old = '''config :lockspire, Lockspire.Security.ClientSecretVerifier,
  keys: [{"verifier-old", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY")}],
  current: "verifier-old",
  write_mode: :dedicated,
  legacy_read: :reject
'''
    new = '''config :lockspire, Lockspire.Security.ClientSecretVerifier,
  keys: [
    {"verifier-old", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY")},
    {"verifier-new", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY_NEXT")}
  ],
  current: "verifier-new",
  write_mode: :dedicated,
  legacy_read: :reject
'''
    if content.count(old) != 1:
        raise PackageInputError("generated host verifier configuration shape changed")
    runtime_config.write_text(content.replace(old, new, 1), encoding="utf-8")


def _capture_secret(child: Path, env: dict[str, str], redactor: Redactor, client_id: str) -> tuple[str, str]:
    quoted_client_id = json.dumps(client_id)
    code = (
        "attrs = %{client_id: " + quoted_client_id + ", client_type: \"confidential\", "
        "name: \"Installed verifier tracer\", redirect_uris: [\"https://client.example/callback\"], "
        "allowed_scopes: [\"openid\"], allowed_grant_types: [\"authorization_code\"], "
        "token_endpoint_auth_method: \"client_secret_jwt\", token_endpoint_auth_signing_alg: \"HS256\"}; "
        "case Lockspire.Clients.register_client(attrs) do "
        "{:ok, %{client: client, client_secret: secret}} -> IO.puts(\"client_id=\" <> client.client_id); IO.puts(\"client_secret=\" <> secret); "
        "{:error, errors} -> Mix.raise(\"client registration rejected: \" <> Enum.map_join(errors, \",\", &Atom.to_string(&1.reason))) end"
    )
    completed = subprocess.run(("mix", "run", "-e", code), cwd=child, env=env, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False, timeout=90)
    output = completed.stdout.decode(errors="replace")
    for match in SENSITIVE_OUTPUT.finditer(output):
        redactor.register_material(match.group(1))
    if completed.returncode != 0:
        safe = redactor.text(output)
        raise PackageInputError("installed client registration failed: " + safe[-1200:])
    values = dict(line.split("=", 1) for line in output.splitlines() if "=" in line)
    client_id, client_secret = values.get("client_id"), values.get("client_secret")
    if not client_id or not client_secret:
        redactor.register_material(output)
        raise PackageInputError("installed client one-time credential handoff is incomplete")
    redactor.register(client_secret)
    redactor.register(output)
    return client_id, client_secret


def _actual_runtime(child: Path, env: dict[str, str]) -> tuple[str, str, str]:
    code = 'IO.puts("RUNTIME=" <> System.version()); IO.puts("OTP=" <> System.otp_release()); {:ok, result} = Ecto.Adapters.SQL.query(CleanRoomProvider.Repo, "SHOW server_version", []); IO.puts("PG=" <> hd(hd(result.rows)))'
    output = run_child_command_output(child, env, "run", "-e", code)
    values = dict(line.split("=", 1) for line in output.splitlines() if line.startswith(("RUNTIME=", "OTP=", "PG=")) and "=" in line)
    if not all(key in values for key in ("RUNTIME", "OTP", "PG")):
        raise PackageInputError("installed host runtime identity is incomplete")
    return values["RUNTIME"], values["OTP"], values["PG"]


def _framework_versions(child: Path, env: dict[str, str]) -> tuple[str, str]:
    code = 'IO.puts("PHOENIX=" <> to_string(Application.spec(:phoenix, :vsn))); IO.puts("LIVE_VIEW=" <> to_string(Application.spec(:phoenix_live_view, :vsn)))'
    output = run_child_command_output(child, env, "run", "--no-start", "-e", code)
    values = dict(line.split("=", 1) for line in output.splitlines() if line.startswith(("PHOENIX=", "LIVE_VIEW=")) and "=" in line)
    if not all(key in values for key in ("PHOENIX", "LIVE_VIEW")):
        raise PackageInputError("installed framework resolution is unavailable")
    return values["PHOENIX"], values["LIVE_VIEW"]


def _authorization_code(
    issuer: str, port: int, client_id: str, redactor: Redactor, *, remember: bool = True
) -> tuple[str, str, str]:
    browser_support.ACTIVE_REDACTOR = redactor
    browser = browser_support.Browser(f"http://127.0.0.1:{port}")
    redirect_uri = "https://client.example/callback"
    verifier = secrets.token_urlsafe(48)
    challenge = _b64(hashlib.sha256(verifier.encode()).digest())
    state, nonce = uuid.uuid4().hex, uuid.uuid4().hex
    redactor.register_material(verifier)
    redactor.register_material(state)
    redactor.register_material(nonce)
    response_type = {
        "response_type": "code", "client_id": client_id, "redirect_uri": redirect_uri,
        "scope": "openid", "state": state, "nonce": nonce,
        "code_challenge": challenge, "code_challenge_method": "S256",
    }
    started = browser.request("GET", "/lockspire/authorize?" + urllib.parse.urlencode(response_type))
    if started["status"] not in (302, 303):
        raise PackageInputError("installed authorization request did not reach host login")
    login_location = browser_support.redirect(started, "installed authorization")
    login = browser.request("GET", login_location)
    if login["status"] != 200:
        raise PackageInputError("installed host login did not render")
    login_body = str(login["body"])
    return_to = re.search(r'name="return_to" value="([^"]*)"', login_body)
    interaction_id = re.search(r'name="interaction_id" value="([^"]*)"', login_body)
    if not return_to or not interaction_id:
        raise PackageInputError("installed host login omitted interaction fields")
    resumed = browser.request("POST", "/login", {
        "_csrf_token": browser_support.csrf(login_body), "return_to": return_to.group(1),
        "interaction_id": interaction_id.group(1), "account_id": "valid-user",
    })
    login_resume = browser_support.redirect(resumed, "installed host login")
    interaction = browser.request("GET", login_resume)
    if interaction["status"] != 302:
        raise PackageInputError("installed host login did not resume authorization")
    consent_location = browser_support.redirect(interaction, "installed authorization")
    consent = browser.request("GET", consent_location)
    if consent["status"] != 200:
        raise PackageInputError("installed consent interaction did not render")
    consent_id = urllib.parse.urlparse(consent_location).path.rsplit("/", 1)[-1]
    approval = {"decision": "approve", "remember": "true" if remember else "false"}
    try:
        approval["_csrf_token"] = browser_support.csrf(consent["body"])
    except AssertionError:
        pass
    completed = browser.request("POST", f"/lockspire/interactions/{consent_id}/complete", approval)
    if completed["status"] not in (302, 303):
        raise PackageInputError("installed consent approval failed")
    callback = browser_support.redirect(completed, "installed consent approval")
    query = urllib.parse.parse_qs(urllib.parse.urlparse(callback).query)
    code = query.get("code", [None])[0]
    if not isinstance(code, str) or query.get("state", [None])[0] != state:
        raise PackageInputError("installed authorization callback omitted its fresh code or state")
    redactor.register_material(code)
    return redirect_uri, verifier, code


def _token_request(issuer: str, client_id: str, secret: str, redirect_uri: str, verifier: str, code: str, redactor: Redactor) -> tuple[bool, int, str]:
    discovery_url = issuer.rstrip("/") + "/.well-known/openid-configuration"
    with urllib.request.urlopen(discovery_url, timeout=10) as response:
        discovery = json.loads(response.read())
    endpoint = discovery.get("token_endpoint")
    if not isinstance(endpoint, str) or not endpoint.startswith(issuer):
        raise PackageInputError("installed discovery returned an unexpected token endpoint")
    jti = uuid.uuid4().hex
    redactor.register_material(jti)
    assertion = signed_assertion(secret, client_id, issuer, jti)
    redactor.register(assertion)
    params = urllib.parse.urlencode({
        "grant_type": "authorization_code", "code": code,
        "redirect_uri": redirect_uri, "code_verifier": verifier,
        "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion": assertion,
    }).encode()
    request = urllib.request.Request(endpoint, data=params, headers={"Content-Type": "application/x-www-form-urlencoded"}, method="POST")
    try:
        response = urllib.request.urlopen(request, timeout=15)
    except urllib.error.HTTPError as error:
        try:
            error_body = error.read()
            error_payload = json.loads(error_body)
        except (ValueError, UnicodeError):
            error_payload = {}
        oauth_error = error_payload.get("error") if error_payload.get("error") in {"invalid_client", "invalid_grant", "invalid_request", "server_error", "temporarily_unavailable"} else None
        description = error_payload.get("error_description") if error_payload.get("error_description") in SAFE_OAUTH_DESCRIPTIONS else None
        details = ", ".join(value for value in (oauth_error, description) if value)
        diagnostic = ""
        if error_body and error.code >= 500:
            rendered = error_body.decode(errors="replace")
            for match in SENSITIVE_OUTPUT.finditer(rendered):
                redactor.register_material(match.group(1))
            safe_text = redactor.text(rendered)
            safe = safe_text[:2600] + "\n[...redacted diagnostic middle omitted...]\n" + safe_text[-1800:]
            redactor.assert_safe(safe)
            diagnostic = "; installed error response: " + safe
        raise PackageInputError(
            f"installed token HTTP returned status {error.code}"
            + (f" ({details})" if details else "")
            + diagnostic
        ) from None
    with response:
        payload = json.loads(response.read())
        for name in ("access_token", "refresh_token", "id_token"):
            if isinstance(payload.get(name), str):
                redactor.register(payload[name])
        if response.status != 200 or not isinstance(payload.get("access_token"), str):
            raise PackageInputError("installed token request did not issue an access token")
        return True, response.status, hashlib.sha256(jti.encode()).hexdigest()


def _persisted_verifier(host: Path, env: dict[str, str], prefix: str, client_id: str) -> tuple[bool, str]:
    escaped = client_id.replace("'", "''")
    code = (
        '{:ok, _apps} = Application.ensure_all_started(:ecto_sql); '
        '{:ok, _repo} = CleanRoomProvider.Repo.start_link(); '
        f'repo = CleanRoomProvider.Repo; result = Ecto.Adapters.SQL.query!(repo, '
        f'"SELECT client_secret_jwt_verifier_encrypted FROM {prefix}.lockspire_clients WHERE client_id = $1", ["{escaped}"]); '
        'IO.puts("CLIENT_ROW_COUNT=" <> Integer.to_string(length(result.rows))); '
        'case result.rows do [[value]] when is_binary(value) -> IO.puts("VERIFIER_FORMAT=" <> if(String.starts_with?(value, "LSCV1."), do: "dedicated", else: "other")); [[nil]] -> IO.puts("VERIFIER_FORMAT=missing"); _ -> IO.puts("VERIFIER_FORMAT=invalid") end'
    )
    output = run_child_command_output(host, env, "run", "--no-start", "-e", code)
    projection = [line for line in output.splitlines() if re.fullmatch(r"(?:CLIENT_ROW_COUNT=[0-9]+|VERIFIER_FORMAT=(?:dedicated|other|missing|invalid))", line)]
    return "VERIFIER_FORMAT=dedicated" in projection, ";".join(projection)


def _provision_signing_key(host: Path, env: dict[str, str]) -> None:
    code = (
        "{:ok, %{key: key}} = Lockspire.Admin.generate_key(:sig); "
        "{:ok, _} = Lockspire.Admin.publish_key(key.id); "
        "{:ok, _} = Lockspire.Admin.activate_key(key.id); IO.puts(\"SIGNING_KEY_ACTIVE=true\")"
    )
    output = run_child_command_output(host, env, "run", "-e", code)
    if "SIGNING_KEY_ACTIVE=true" not in output.splitlines():
        raise PackageInputError("installed provider signing-key setup did not complete")


def run_tracer(*, pair: str, store: str, receipt_dir: Path) -> dict[str, object]:
    if store != "builtin":
        raise PackageInputError("tracer currently supports only the installed built-in store")
    port = allocate_port()
    prefix = "vfy" + uuid.uuid4().hex[:14]
    key = base64.b64encode(os.urandom(32)).decode("ascii")
    sentinels = SentinelSet.for_run()
    redactor = Redactor(sentinels)
    redactor.register_material(key)
    database_url = clean_room_database_url("verifier")
    issuer = f"http://127.0.0.1:{port}/lockspire"
    runner = source_revision()
    server = None
    with tempfile.TemporaryDirectory(prefix="lockspire-verifier-tracer-") as temporary:
        run_root = Path(temporary)
        package, _entries, identity = prepare_package(run_root, PackageSource("checkout"))
        archive = package.parent / f"lockspire-{identity.version}.tar"
        verify_candidate_input(archive, package, identity)
        host = prepare_provider(
            run_root, database_url, package_root=package, port=port,
            storage_prefix=prefix, candidate_identity=identity, proof_pair=pair,
            admin_proof=False, mount_path="/lockspire",
        )
        _configure_verifier_custody(host)
        env = _mix_env(host, run_root, database_url, port, issuer, prefix, key, pair)
        redactor.register_material(database_url)
        try:
            run_child_command(host, env, "ecto.create")
            run_child_command(host, env, "ecto.migrate", "--migrations-path", "priv/repo/migrations")
            _provision_signing_key(host, env)
            lock_hash = sha256(PROOF_PAIR_LOCKS[pair])
            phoenix, live_view = _framework_versions(host, env)
            elixir, otp, pg = _actual_runtime(host, env)
            client_id = "verifier-" + uuid.uuid4().hex
            client_id, client_secret = _capture_secret(host, env, redactor, client_id)
            server_log_path = run_root / "provider.log"
            with server_log_path.open("wb") as server_log:
                os.chmod(server_log_path, 0o600)
                server = subprocess.Popen(("mix", "run", "--no-halt"), cwd=host, env=env, stdin=subprocess.DEVNULL, stdout=server_log, stderr=subprocess.STDOUT, start_new_session=True)
            deadline = time.monotonic() + 20
            while time.monotonic() < deadline:
                if server.poll() is not None:
                    raise PackageInputError("installed provider stopped before HTTP readiness")
                try:
                    with urllib.request.urlopen(issuer + "/.well-known/openid-configuration", timeout=1) as response:
                        if response.status == 200:
                            break
                except OSError:
                    time.sleep(0.1)
            else:
                raise PackageInputError("installed provider did not become HTTP ready")
            redirect_uri, verifier, code = _authorization_code(issuer, port, client_id, redactor)
            try:
                issued, status, _jti_digest = _token_request(
                    issuer, client_id, client_secret, redirect_uri, verifier, code, redactor
                )
            except PackageInputError as error:
                server_log = server_log_path.read_text(encoding="utf-8", errors="replace")
                for match in SENSITIVE_OUTPUT.finditer(server_log):
                    redactor.register_material(match.group(1))
                safe_log = redactor.text(server_log)[-1600:]
                redactor.assert_safe(safe_log)
                raise PackageInputError(f"{error}; installed server log: {safe_log}") from None
            persisted, persisted_projection = _persisted_verifier(host, env, prefix, client_id)
            if not issued or not persisted:
                raise PackageInputError(
                    "installed issuance or dedicated verifier persistence assertion failed: "
                    + persisted_projection
                )
            if server.poll() is None:
                server.terminate()
                server.wait(timeout=5)
                server = None
            host_provenance = candidate_host_provenance(host)
            runtime = {"elixir": elixir, "otp": otp, "postgresql": pg}
            candidate = {
                "kind": identity.kind, "version": identity.version,
                "archive_sha256": identity.archive_sha256, "tree_sha256": identity.tree_sha256,
                "source_revision": identity.source_revision, "runner_revision": identity.runner_revision,
                "source_proof": identity.source_proof,
            }
            receipt = {
                "schema": "lockspire-installed-verifier-v1", "scope": "tracer", "run_id": uuid.uuid4().hex,
                "runner": runner, "pair": pair, "store": store, "candidate": candidate,
                "host": {
                    **host_provenance, "lock_sha256": lock_hash,
                    "phoenix": phoenix, "live_view": live_view,
                },
                "runtime": runtime,
                "stable_case_ids": ["VPROOF-02-INSTALLED-TOKEN"],
                "observations": {"VPROOF-02-INSTALLED-TOKEN": {
                    "outcome": "pass", "executed": True, "http_status": status,
                    "token_issued": True, "dedicated_verifier_persisted": True,
                    "fresh_signed_assertion": True,
                }},
                "executed_count": 1, "partial": True,
            }
            validate_receipt(receipt, expected_pair=pair, expected_store=store)
            redactor.assert_safe(json.dumps(receipt, sort_keys=True))
            receipt_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
            (receipt_dir / "receipt.json").write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n", encoding="utf-8")
            print(json.dumps({"scope": "tracer", "executed_count": 1, "receipt": str(receipt_dir / "receipt.json")}, sort_keys=True))
            return receipt
        finally:
            if server is not None and server.poll() is None:
                server.terminate()
                try:
                    server.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait()
            if host.exists():
                try:
                    run_child_command(host, env, "ecto.drop")
                except PackageInputError:
                    pass


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pair", choices=("locked", "floor", "all"), default="locked")
    parser.add_argument("--store", choices=("builtin", "delegated", "all"), default="builtin")
    parser.add_argument("--group", choices=sorted(GROUPS), default="tracer")
    parser.add_argument("--receipt-dir", type=Path, default=Path(".artifacts/phase178/tracer"))
    parser.add_argument("--validate-receipts", type=Path)
    parser.add_argument("--self-test", action="store_true")
    return parser.parse_args(argv)


def _complete_matrix(*, receipt_dir: Path, pair: str, store: str) -> dict[str, object]:
    if (pair, store) != ("all", "all"):
        raise PackageInputError("all-scope acceptance requires --pair all --store all")
    root = receipt_dir.resolve()
    project = Path(__file__).resolve().parents[2]
    artifact_root = (project / ".artifacts").resolve()
    if not root.is_relative_to(artifact_root) or root == artifact_root:
        raise PackageInputError("all-scope receipt path must be a dedicated child of .artifacts")
    if root.exists():
        if root.is_symlink() or any(root.iterdir()):
            raise PackageInputError("all-scope receipt path must be fresh and empty")
    else:
        root.mkdir(mode=0o700, parents=True)

    # Run each established group at the single committed harness revision.
    # The narrow selection is fixed here; caller-supplied group names cannot
    # reduce the required matrix.
    selections = (
        ("core", "all", "all"), ("rollout", "all", "all"),
        ("recovery", "all", "all"), ("endpoints", "all", "builtin"),
        ("contention", "all", "delegated"), ("atomicity", "all", "delegated"),
        ("issuance", "all", "delegated"), ("disclosure", "all", "delegated"),
        ("legacy-control", "locked", "builtin"), ("release-rpc", "locked", "builtin"),
    )
    for scope, selected_pair, selected_store in selections:
        module_name, function_name = MODULES[scope]
        module = __import__(module_name)
        function = getattr(module, function_name)
        function(pair=selected_pair, store=selected_store, receipt_dir=root / scope)

    records: list[dict[str, object]] = []
    anchors: set[tuple[str, str, str]] = set()
    for scope, selected_pair, selected_store in REQUIRED_MATRIX:
        filename = "failure-receipt.json" if scope == "disclosure-failure" else "receipt.json"
        path = root / scope / f"{selected_pair}-{selected_store}" / filename
        raw = path.read_bytes()
        receipt = load_receipt(path)
        if scope in {"rollout", "legacy-control"}:
            validate_rollout_receipt(
                receipt, expected_pair=selected_pair, expected_store=selected_store,
                expected_runner=source_revision(), expected_scope=scope,
            )
            runner_revision = receipt["runner_revision"]
            candidate = receipt["candidate"]
            candidate_identity = (candidate["source_revision"], candidate["archive_sha256"], candidate["tree_sha256"])
            compiled_candidate = receipt["processes"]["candidate"]["compiled_candidate_sha256"]
        else:
            validate_receipt(receipt, expected_pair=selected_pair, expected_store=selected_store)
            runner_revision = receipt["runner"]
            candidate = receipt["candidate"]
            candidate_identity = (candidate["source_revision"], candidate["archive_sha256"], candidate["tree_sha256"])
            compiled_candidate = receipt["host"]["compiled_candidate_sha256"]
        if runner_revision != source_revision():
            raise ReceiptError("group receipt belongs to a different committed harness revision")
        if candidate_identity[0] != source_revision():
            raise ReceiptError("candidate package is not bound to the committed harness source")
        expected_lock = sha256(PROOF_PAIR_LOCKS[selected_pair])
        host_lock = receipt["host"]["lock_sha256"]
        if host_lock != expected_lock or not re.fullmatch(r"[0-9a-f]{64}", compiled_candidate or ""):
            raise ReceiptError("host lock or compiled candidate identity does not match its dependency pair")
        anchors.add(candidate_identity)
        cases = expected_case_ids((scope, selected_pair, selected_store))
        records.append({
            "scope": scope, "pair": selected_pair, "store": selected_store,
            "run_id": receipt["run_id"], "runner_revision": runner_revision,
            "receipt_path": path.relative_to(root).as_posix(),
            "receipt_sha256": hashlib.sha256(raw).hexdigest(),
            "stable_case_ids": cases, "executed_count": receipt["executed_count"],
            "outcome": "pass", "candidate_source_archive_tree": list(candidate_identity),
            "host_lock_sha256": host_lock, "compiled_candidate_sha256": compiled_candidate,
        })
    if len(anchors) != 1:
        raise ReceiptError("candidate source/archive/tree identities differ across required groups")
    validated = validate_complete_matrix(records, expected_runner=source_revision())
    total_cases = sum(len(row["stable_case_ids"]) for row in validated)
    aggregate = {
        "schema": "lockspire-installed-verifier-matrix-v1",
        "runner_revision": source_revision(),
        "candidate_source_archive_tree": list(next(iter(anchors))),
        "required_receipt_count": len(REQUIRED_MATRIX),
        "executed_receipt_count": len(validated),
        "required_case_count": total_cases,
        "executed_case_count": total_cases,
        "passed_case_count": total_cases,
        "failed_case_count": 0,
        "cells": validated,
    }
    target = root / "aggregate.json"
    target.write_text(json.dumps(aggregate, sort_keys=True, indent=2) + "\n", encoding="utf-8")
    os.chmod(target, 0o600)
    print(json.dumps({"scope": "all", "required_receipts": len(REQUIRED_MATRIX),
                      "executed_receipts": len(validated), "required_cases": total_cases,
                      "passed_cases": total_cases, "failed_cases": 0,
                      "runner_revision": source_revision(), "aggregate_sha256": hashlib.sha256(target.read_bytes()).hexdigest()}, sort_keys=True))
    return aggregate


def self_test() -> int:
    command = [sys.executable, "-m", "unittest", "discover", "-s", "test/acceptance", "-p", "client_verifier_tracer_test.py"]
    result = subprocess.run(command, cwd=Path(__file__).resolve().parents[2], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=False)
    print(result.stdout, end="")
    match = re.search(r"Ran (\d+) tests?", result.stdout)
    count = int(match.group(1)) if match else 0
    if result.returncode or count <= 0:
        return 1
    print(json.dumps({"self_test": "pass", "contract_tests": count, "installed_acceptance": False}, sort_keys=True))
    return 0


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        if args.self_test:
            return self_test()
        if args.validate_receipts:
            receipt = validate_receipt(load_receipt(args.validate_receipts), expected_pair=args.pair, expected_store=args.store)
            print(json.dumps({"validated": True, "scope": receipt["scope"], "executed_count": receipt["executed_count"]}, sort_keys=True))
            return 0
        if args.group == "tracer":
            run_tracer(pair=args.pair, store=args.store, receipt_dir=args.receipt_dir)
            return 0
        if args.group == "all":
            _complete_matrix(receipt_dir=args.receipt_dir, pair=args.pair, store=args.store)
            return 0
        selected = MODULES.get(args.group)
        if selected is None:
            raise PackageInputError(f"scenario group is not implemented: {args.group}")
        module_name, function_name = selected
        try:
            module = __import__(module_name)
        except ModuleNotFoundError:
            raise PackageInputError(f"scenario group is not implemented: {args.group}") from None
        function = getattr(module, function_name, None)
        if not callable(function):
            raise PackageInputError(f"scenario group is not implemented: {args.group}")
        function(pair=args.pair, store=args.store, receipt_dir=args.receipt_dir)
        return 0
    except (PackageInputError, ReceiptError, OSError, subprocess.SubprocessError):
        # Child exceptions and diagnostic text can contain generated verifier
        # keys that are unknown to this process. Report only a fixed stage.
        group = args.group if args.group in GROUPS else "unknown"
        print(f"installed verifier proof failed during {group}; child diagnostics withheld", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
