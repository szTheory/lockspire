#!/usr/bin/env python3
"""Exercise the supported pre-lifetime to authoritative maintenance cutover."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time
from urllib.parse import parse_qs, urlencode, urlparse
from urllib.request import urlopen

from build_provider import prepare_provider
from package_input import (
    candidate_host_provenance,
    PackageInputError,
    PackageIdentity,
    PackageSource,
    clean_room_database_url,
    prepare_package,
    verify_candidate_input,
)
from lifetime_receipts import validate_candidate_identity_agreement
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from clean_room_saas_journey import Browser, _run_host_control, basic, csrf, redirect, safe_oauth_error_code, s256, start_process, stop_process, wait_ready
from redaction import Redactor, SentinelSet, safe_failure_summary
from processes import allocate_loopback_port


OLD_VERSION = "1.6.1"
OLD_SHA256 = "629abdc1b6721620f3d9084dbbe78da1e254650da5c552d0cc0f5b0c00f1cc6d"
SCENARIOS = {"public": "public", "tenant_auth": "tenant_auth"}
DATES = ("nil", "creation", "past", "future", "stale_after_rotation")
UPGRADE_RECEIPT_FIELDS = frozenset({"schema_version", "scenarios"})
UPGRADE_SCENARIO_FIELDS = frozenset({
    "prefix", "old_package", "candidate_package", "historical_migration_checksums_preserved",
    "historical_migration_checksum_count", "historical_migration_checksums_sha256",
    "old_processes", "expansion_process", "old_writer_processes_stopped_before_v1",
    "old_read_write_count", "old_read_observation", "v0_legacy_rows_observation",
    "old_rotation_observation", "candidate_v1_write_process", "v1_state_retained_observation",
    "legacy_http_use_observation", "legacy_http_use_process", "legacy_promotion_observation",
    "legacy_promotion_process", "v1_state_retained",
    "database_cleanup_process", "old_binary_after_v1_traffic",
    "rollback_boundary",
})
LEGACY_PROMOTION_FIELDS = frozenset({
    "old_secret_http_status", "replacement_secret_http_status", "management_put_http_status",
    "old_management_http_status", "replacement_management_http_status", "lifetime_version",
    "app_unlimited", "secret_current_policy_deadline", "management_current_policy_deadline",
    "whole_row_promoted", "unrelated_authority_preserved", "audit_persisted",
    "wire_client_expires_at", "wire_registration_access_token_expires_at",
})
SAFE_OAUTH_DESCRIPTIONS = frozenset({
    "Client authentication failed", "Client application has expired", "Client application is disabled",
    "Unable to validate client lifetime state", "Unable to validate client secret lifetime state",
    "Unable to determine client application eligibility", "Unable to determine client secret eligibility",
    "Unable to persist request", "Unable to validate client", "Invalid authorization request",
    "request_uri from the PAR endpoint is required", "redirect_uri must match a registered URI",
})
PROCESS_FIELDS = frozenset({"pid", "command", "exit_code", "output"})
OLD_PACKAGE_FIELDS = frozenset({
    "schema_version", "source", "package", "version", "sha256", "archive_sha256",
    "tree_sha256", "source_revision",
})
SAFE_COMMANDS = frozenset({"ecto.create", "ecto.migrate", "run", "lockspire.client.create", "ecto.drop"})


SENSITIVE_OUTPUT = re.compile(
    r"(?i)(?:client_secret|registration_access_token|access_token|refresh_token|authorization_code|"
    r"pkce_verifier|verifier|private_key|cookie|secret|token|hash)\s*[:=]\s*[\"']?([^\s,;\"'}]+)"
)
SAFE_MARKER = re.compile(r"(?:[A-Z][A-Z0-9_]*=\d+)(?:;[A-Z][A-Z0-9_]*=\d+)*\Z")


def _register_output_material(redactor: Redactor, output: str) -> None:
    for match in SENSITIVE_OUTPUT.finditer(output):
        redactor.register_material(match.group(1))
    for line in output.splitlines():
        try:
            parsed = json.loads(line)
        except (json.JSONDecodeError, TypeError):
            continue
        _register_structured_material(redactor, parsed)


def _register_structured_material(redactor: Redactor, value: object, key: str = "") -> None:
    if isinstance(value, dict):
        for child_key, child_value in value.items():
            _register_structured_material(redactor, child_value, str(child_key))
    elif isinstance(value, (list, tuple)):
        for child_value in value:
            _register_structured_material(redactor, child_value, key)
    elif isinstance(value, str) and re.search(
        r"(?i)(secret|token|code|verifier|private.?key|cookie|hash)", key
    ):
        redactor.register_material(value)


def _safe_process_output(output: str) -> str:
    return "\n".join(line for line in output.splitlines() if SAFE_MARKER.fullmatch(line))[-3000:]


def run_process(
    child: Path, env: dict[str, str], args: tuple[str, ...], redactor: Redactor,
    *, stage: str, scenario: str, timeout: int = 180,
) -> dict[str, object]:
    try:
        redactor.assert_safe("\0".join(args))
    except RuntimeError:
        raise PackageInputError(str(safe_failure_summary(
            stage=stage, scenario=scenario, event="child_start", field="argv", count=1
        ))) from None
    try:
        process = subprocess.Popen(
            ("mix", *args), cwd=child, env=env, stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
    except OSError:
        raise PackageInputError(str(safe_failure_summary(
            stage=stage, scenario=scenario, event="child_start", field="exception", count=1
        ))) from None
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        process.kill()
        process.communicate()
        raise PackageInputError(str(safe_failure_summary(
            stage=stage, scenario=scenario, event="child_timeout", field="process", count=1
        ))) from None
    output = (stdout or b"").decode(errors="replace")
    error_output = (stderr or b"").decode(errors="replace")
    _register_output_material(redactor, output + "\n" + error_output)
    command = args[0] if args and args[0] in SAFE_COMMANDS else "child"
    if process.returncode != 0:
        summary = safe_failure_summary(
            stage=stage, scenario=scenario, event="child_exit", field="stdout_stderr",
            count=len(output.splitlines()) + len(error_output.splitlines()),
        )
        raise PackageInputError(str(summary))
    return {
        "pid": process.pid,
        "command": command,
        "exit_code": process.returncode,
        "output": _safe_process_output(output),
    }


def mix_env(child: Path, run_root: Path, database_url: str, storage_prefix: str) -> dict[str, str]:
    env = os.environ.copy()
    dependency_root = run_root / "deps-cache" / "provider" / "deps"
    hex_home = run_root / "hex-home"
    mix_home = run_root / "mix-home"
    dependency_root.mkdir(mode=0o700, parents=True, exist_ok=True)
    hex_home.mkdir(mode=0o700, parents=True, exist_ok=True)
    mix_home.mkdir(mode=0o700, parents=True, exist_ok=True)
    env.update({
        "MIX_ENV": "dev",
        "MIX_BUILD_PATH": str(child / "_build"),
        "MIX_DEPS_PATH": str(dependency_root),
        "HEX_HOME": str(hex_home),
        "MIX_HOME": str(mix_home),
        "DATABASE_URL": database_url,
        "LOCKSPIRE_STORAGE_PREFIX": storage_prefix,
        "LOCKSPIRE_KEY_ENCRYPTION_KEY": os.environ.get("LOCKSPIRE_KEY_ENCRYPTION_KEY", "") or "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
    })
    return env


def migration_checksums(root: Path) -> dict[str, str]:
    migration_root = root / "priv" / "repo" / "migrations"
    return {
        path.name: hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(migration_root.glob("*.exs"))
    }


def exercise_legacy_http_use(origin: str, client_id: str, client_secret: str, redactor: Redactor) -> dict[str, object]:
    """Redeem a real S256 authorization code using the pinned-old-package credential."""
    browser = Browser(origin)
    discovery_response = browser.request("GET", "/lockspire/.well-known/openid-configuration")
    if discovery_response["status"] != 200:
        raise PackageInputError("candidate HTTP discovery was unavailable during legacy credential use")
    discovery = json.loads(str(discovery_response["body"]))
    token_endpoint = discovery.get("token_endpoint")
    if not isinstance(token_endpoint, str):
        raise PackageInputError("candidate HTTP discovery omitted its token endpoint")
    token_path = "/" + "/".join(token_endpoint.split("/", 3)[3:])
    redirect_uri = "https://client.example/callback"
    state, nonce = os.urandom(16).hex(), os.urandom(16).hex()
    verifier = os.urandom(32).hex() + os.urandom(32).hex()
    redactor.register_material(verifier)
    request_params = {
        "response_type": "code", "client_id": client_id, "redirect_uri": redirect_uri,
        "scope": "openid", "state": state, "nonce": nonce,
        "code_challenge": s256(verifier), "code_challenge_method": "S256",
    }
    par = browser.request("POST", "/lockspire/par", request_params, {
        "authorization": basic(client_id, client_secret),
    })
    if par["status"] != 201:
        raise PackageInputError(
            "candidate rejected the past-dated legacy client at PAR"
            + safe_oauth_error_code(par)
            + safe_static_oauth_description(par)
        )
    par_payload = json.loads(str(par["body"]))
    request_uri = par_payload.get("request_uri")
    if not isinstance(request_uri, str) or not request_uri:
        raise PackageInputError("candidate PAR omitted the legacy authorization request URI")
    authorize = browser.request("GET", "/lockspire/authorize?" + urlencode({
        "client_id": client_id, "request_uri": request_uri,
    }))
    if authorize["status"] != 302:
        raise PackageInputError("candidate rejected the legacy client at the authorization endpoint")
    login = browser.request("GET", redirect(authorize, "legacy upgrade authorization"))
    if login["status"] != 200:
        raise PackageInputError("candidate host login did not render for the legacy client")
    rendered = str(login["body"])
    return_to = re.search(r'name="return_to" value="([^"]*)"', rendered)
    interaction_id = re.search(r'name="interaction_id" value="([^"]*)"', rendered)
    if not return_to or not interaction_id:
        raise PackageInputError("candidate host login omitted the authorization interaction fields")
    login_redirect = redirect(browser.request("POST", "/login", {
        "_csrf_token": csrf(rendered), "return_to": return_to.group(1),
        "interaction_id": interaction_id.group(1), "account_id": "clean-room-user",
    }), "legacy upgrade host login")
    interaction = browser.request("GET", login_redirect)
    if interaction["status"] != 302:
        raise PackageInputError("candidate host login did not resume the legacy authorization request")
    consent = browser.request("GET", redirect(interaction, "legacy upgrade interaction"))
    if consent["status"] != 200:
        raise PackageInputError("candidate host consent did not render for the legacy client")
    approved = browser.request("POST", f"/lockspire/interactions/{interaction_id.group(1)}/complete", {
        "decision": "approve", "remember": "false",
    })
    if approved["status"] != 302:
        raise PackageInputError("candidate host consent did not approve the legacy authorization request")
    callback = urlparse(redirect(approved, "legacy upgrade approval"))
    query = parse_qs(callback.query)
    code = query.get("code", [None])[0]
    if query.get("state") != [state] or not isinstance(code, str):
        raise PackageInputError("candidate authorization callback did not preserve legacy client state")
    redactor.register_material(code)
    token = browser.request("POST", token_path, {
        "grant_type": "authorization_code", "code": code,
        "redirect_uri": redirect_uri, "code_verifier": verifier,
    }, {"authorization": basic(client_id, client_secret)})
    if token["status"] != 200:
        raise PackageInputError(
            "candidate rejected the past-dated legacy client credential at token exchange"
            + safe_oauth_error_code(token)
        )
    payload = json.loads(str(token["body"]))
    access_token = payload.get("access_token")
    if not isinstance(access_token, str) or not access_token:
        raise PackageInputError("candidate legacy token exchange did not issue an access token")
    redactor.register_material(access_token)
    return {
        "par_http_status": par["status"], "authorize_http_status": authorize["status"], "login_http_status": login["status"],
        "token_http_status": token["status"], "lifetime_version": 0,
        "client_secret_date_kind": "past", "access_token_issued": True,
    }


def safe_static_oauth_description(response: dict[str, object]) -> str:
    """Expose only a known static protocol description for local failure diagnosis."""
    try:
        payload = json.loads(str(response["body"]))
        description = payload.get("error_description")
    except (AttributeError, TypeError, json.JSONDecodeError):
        return ""
    return f" ({description})" if description in SAFE_OAUTH_DESCRIPTIONS else ""


def replace_legacy_authorities(
    origin: str, child: Path, environment: dict[str, str], client_id: str,
    old_secret: str, old_rat: str, run_root: Path, redactor: Redactor,
) -> tuple[dict[str, object], str]:
    """Promote one pinned-old DCR row through production HTTP management and secret replacement."""
    discovery_response = Browser(origin).request("GET", "/lockspire/.well-known/openid-configuration")
    if discovery_response["status"] != 200:
        raise PackageInputError("candidate discovery failed before legacy replacement")
    discovery = json.loads(str(discovery_response["body"]))
    registration_endpoint = discovery.get("registration_endpoint")
    introspection_endpoint = discovery.get("introspection_endpoint")
    if not isinstance(registration_endpoint, str) or not isinstance(introspection_endpoint, str):
        raise PackageInputError("candidate discovery omitted management or introspection routes")
    registration_path = urlparse(registration_endpoint).path.rstrip("/") + "/" + client_id
    introspection_path = urlparse(introspection_endpoint).path
    snapshot_path = run_root / f"promoted-row-{client_id}.bin"
    provider = Browser(origin)
    redactor.register_material(old_rat)
    snapshot_expr = (
        f"{{:ok, before}} = Lockspire.Admin.Clients.get_client({json.dumps(client_id)}); "
        "snapshot = {before.id, before.client_id, before.client_secret_hash, before.client_secret_jwt_verifier_encrypted, "
        "before.client_type, before.redirect_uris, before.post_logout_redirect_uris, before.allowed_scopes, "
        "before.allowed_grant_types, before.allowed_response_types, before.token_endpoint_auth_method, "
        "before.active, before.created_by, before.metadata}; "
        f"File.write!({json.dumps(str(snapshot_path))}, :erlang.term_to_binary(snapshot)); File.chmod!({json.dumps(str(snapshot_path))}, 0o600); "
        "IO.puts(\"LEGACY_V0_ROW_SNAPSHOTTED=#{if before.lifetime_version == 0, do: 1, else: 0}\")"
    )
    if "LEGACY_V0_ROW_SNAPSHOTTED=1" not in _run_host_control(child, environment, snapshot_expr):
        raise PackageInputError("candidate host could not snapshot the v0 row before HTTP promotion")
    management_uri = origin + registration_path
    metadata = {
        "client_id": client_id, "client_name": "Legacy promoted through current policy",
        "redirect_uris": ["https://client.example/callback"],
        "grant_types": ["authorization_code"], "response_types": ["code"],
        "token_endpoint_auth_method": "client_secret_basic", "scope": "openid",
    }
    put = provider.request("PUT", management_uri, metadata, {
        "content-type": "application/json", "authorization": f"Bearer {old_rat}",
    })
    if put["status"] != 200:
        raise PackageInputError("candidate HTTP management PUT rejected the promoted legacy row")
    updated = json.loads(str(put["body"]))
    new_rat = updated.get("registration_access_token")
    if not isinstance(new_rat, str) or not new_rat:
        raise PackageInputError("candidate HTTP management PUT omitted its replacement credential")
    redactor.register_material(new_rat)
    old_management = provider.request("GET", management_uri, extra_headers={"authorization": f"Bearer {old_rat}"})
    new_management = provider.request("GET", management_uri, extra_headers={"authorization": f"Bearer {new_rat}"})
    if old_management["status"] != 401 or new_management["status"] != 200:
        raise PackageInputError("candidate HTTP management PUT did not rotate its management credential")
    app_wire = updated.get("lockspire_client_expires_at")
    management_wire = updated.get("lockspire_registration_access_token_expires_at")
    if app_wire != 0 or type(management_wire) is not int or management_wire <= int(time.time()):
        raise PackageInputError("candidate HTTP management PUT omitted current-policy lifetime wire values")
    storage_prefix = environment["LOCKSPIRE_STORAGE_PREFIX"]
    if not re.fullmatch(r"[a-z][a-z0-9_]{0,62}", storage_prefix):
        raise PackageInputError("candidate host reported an invalid storage prefix")
    verify_expr = (
        f"{{:ok, current_after}} = Lockspire.Admin.Clients.get_client({json.dumps(client_id)}); "
        f"snapshot = :erlang.binary_to_term(File.read!({json.dumps(str(snapshot_path))})); "
        "{id, original_id, secret_hash, verifier, type, redirects, logout_redirects, scopes, grants, responses, auth, active, created_by, metadata} = snapshot; "
        "preserved = current_after.id == id and current_after.client_id == original_id and current_after.client_secret_hash == secret_hash and "
        "current_after.client_secret_jwt_verifier_encrypted == verifier and current_after.client_type == type and "
        "current_after.redirect_uris == redirects and current_after.post_logout_redirect_uris == logout_redirects and "
        "current_after.allowed_scopes == scopes and current_after.allowed_grant_types == grants and current_after.allowed_response_types == responses and "
        "current_after.token_endpoint_auth_method == auth and current_after.active == active and current_after.created_by == created_by and "
        "current_after.metadata == metadata and is_nil(current_after.client_expires_at) and "
        "is_nil(current_after.client_secret_expires_at) and current_after.lifetime_version == 1; "
        f"{{:ok, count}} = Ecto.Adapters.SQL.query(Lockspire.Config.repo!(), \"SELECT count(*) FROM {storage_prefix}.lockspire_audit_events WHERE resource_id = $1 AND action = 'dcr_management_updated'\", [{json.dumps(client_id)}]); "
        "[[audit_count]] = count.rows; "
        "IO.puts(\"LEGACY_WHOLE_ROW_PROMOTED=#{if current_after.lifetime_version == 1 and is_nil(current_after.client_expires_at), do: 1, else: 0};LEGACY_MANAGEMENT_AUTHORITY_PRESERVED=#{if preserved, do: 1, else: 0};LEGACY_MANAGEMENT_POLICY_DEADLINE=#{if current_after.registration_access_token_expires_at && DateTime.to_unix(current_after.registration_access_token_expires_at) == " + str(management_wire) + ", do: 1, else: 0};LEGACY_MANAGEMENT_AUDIT=#{if audit_count > 0, do: 1, else: 0}\")"
    )
    verified = _run_host_control(child, environment, verify_expr)
    expected_markers = (
        "LEGACY_WHOLE_ROW_PROMOTED=1", "LEGACY_MANAGEMENT_AUTHORITY_PRESERVED=1",
        "LEGACY_MANAGEMENT_POLICY_DEADLINE=1", "LEGACY_MANAGEMENT_AUDIT=1",
    )
    if any(marker not in verified for marker in expected_markers):
        raise PackageInputError("candidate HTTP management replacement lost unrelated authority or current-policy state")
    secret_path = run_root / f"promoted-secret-{client_id}"
    secret_expr = (
        f"{{:ok, before}} = Lockspire.Admin.Clients.get_client({json.dumps(client_id)}); "
        f"{{:ok, result}} = Lockspire.Admin.Clients.rotate_client_secret({json.dumps(client_id)}, %{{actor: %{{type: :operator, id: \"legacy-upgrade-proof\"}}}}); "
        "promoted = result.client; rat_preserved = before.registration_access_token_expires_at == promoted.registration_access_token_expires_at; "
        "identity_preserved = before.id == promoted.id and before.client_id == promoted.client_id and before.active == promoted.active; "
        "auth_preserved = before.redirect_uris == promoted.redirect_uris and before.allowed_scopes == promoted.allowed_scopes and before.allowed_grant_types == promoted.allowed_grant_types and before.token_endpoint_auth_method == promoted.token_endpoint_auth_method; preserved = rat_preserved and identity_preserved and auth_preserved; "
        f"File.write!({json.dumps(str(secret_path))}, result.client_secret); File.chmod!({json.dumps(str(secret_path))}, 0o600); "
        "deadline = if promoted.client_secret_expires_at, do: Integer.to_string(DateTime.to_unix(promoted.client_secret_expires_at)), else: \"0\"; "
        "IO.puts(\"LEGACY_SECRET_POLICY_DEADLINE=#{deadline};LEGACY_SECRET_HASH_ROTATED=#{if before.client_secret_hash != promoted.client_secret_hash, do: 1, else: 0};LEGACY_SECRET_RAT_PRESERVED=#{if rat_preserved, do: 1, else: 0};LEGACY_SECRET_IDENTITY_PRESERVED=#{if identity_preserved, do: 1, else: 0};LEGACY_SECRET_AUTH_PRESERVED=#{if auth_preserved, do: 1, else: 0};LEGACY_SECRET_AUTHORITY_PRESERVED=#{if preserved, do: 1, else: 0}\")"
    )
    secret_result = _run_host_control(child, environment, secret_expr)
    secret_match = re.search(
        r"LEGACY_SECRET_POLICY_DEADLINE=(\d+);LEGACY_SECRET_HASH_ROTATED=1;LEGACY_SECRET_RAT_PRESERVED=1;LEGACY_SECRET_IDENTITY_PRESERVED=1;LEGACY_SECRET_AUTH_PRESERVED=1;LEGACY_SECRET_AUTHORITY_PRESERVED=1",
        secret_result,
    )
    if not secret_match or not secret_path.is_file():
        raise PackageInputError("current-policy secret replacement did not preserve promoted management authority")
    if int(secret_match.group(1)) <= int(time.time()):
        raise PackageInputError("current-policy secret replacement did not issue a future deadline")
    replacement_secret = secret_path.read_text(encoding="utf-8").strip()
    redactor.register_material(replacement_secret)
    old_auth = provider.request("POST", introspection_path, {"token": "clean-room-unowned-token"}, {
        "authorization": basic(client_id, old_secret),
    })
    new_auth = provider.request("POST", introspection_path, {"token": "clean-room-unowned-token"}, {
        "authorization": basic(client_id, replacement_secret),
    })
    if old_auth["status"] != 401 or new_auth["status"] != 200:
        raise PackageInputError("legacy secret replacement did not invalidate only the previous credential")
    observation = {
        "old_secret_http_status": old_auth["status"], "replacement_secret_http_status": new_auth["status"],
        "management_put_http_status": put["status"], "old_management_http_status": old_management["status"],
        "replacement_management_http_status": new_management["status"], "lifetime_version": 1,
        "app_unlimited": True, "secret_current_policy_deadline": True,
        "management_current_policy_deadline": True, "whole_row_promoted": True,
        "unrelated_authority_preserved": True, "audit_persisted": True,
        "wire_client_expires_at": app_wire,
        "wire_registration_access_token_expires_at": management_wire,
    }
    marker_output = "LEGACY_WHOLE_ROW_PROMOTED=1;LEGACY_MANAGEMENT_AUTHORITY_PRESERVED=1;LEGACY_MANAGEMENT_POLICY_DEADLINE=1;LEGACY_MANAGEMENT_AUDIT=1"
    return observation, marker_output


def run_scenario(
    run_root: Path, prefix: str, candidate_package: Path, candidate_archive: Path,
    candidate_identity: PackageIdentity, redactor: Redactor,
) -> dict[str, object]:
    def run_child(host: Path, environment: dict[str, str], command: tuple[str, ...]) -> dict[str, object]:
        return run_process(
            host, environment, command, redactor, stage="legacy_upgrade", scenario=prefix
        )

    old_root = run_root / f"old-{prefix}"
    candidate_root = run_root / f"candidate-{prefix}"
    database_url = clean_room_database_url(f"life_{prefix}")
    downloads = old_root / "package" / "downloads"
    downloads.mkdir(mode=0o700, parents=True, exist_ok=True)
    old_tar = downloads / f"lockspire-{OLD_VERSION}.tar"
    if not old_tar.is_file():
        with urlopen(f"https://repo.hex.pm/tarballs/lockspire-{OLD_VERSION}.tar", timeout=30) as response:
            old_tar.write_bytes(response.read())
    digest = hashlib.sha256(old_tar.read_bytes()).hexdigest()
    if digest != OLD_SHA256:
        raise PackageInputError("public old package checksum did not match the pinned release")
    previous_root = os.environ.get("LOCKSPIRE_PACKAGE_ROOT")
    os.environ["LOCKSPIRE_PACKAGE_ROOT"] = str(downloads)
    try:
        old_package = old_root / "package" / "lockspire"
        old_package, old_entries, old_identity = prepare_package(
            old_root, PackageSource("tar", str(old_tar), OLD_SHA256)
        )
        verify_candidate_input(old_tar, old_package, old_identity)
    finally:
        if previous_root is None:
            os.environ.pop("LOCKSPIRE_PACKAGE_ROOT", None)
        else:
            os.environ["LOCKSPIRE_PACKAGE_ROOT"] = previous_root
    verify_candidate_input(candidate_archive, candidate_package, candidate_identity)
    if not (candidate_package / "priv/repo/migrations/20261021000000_add_client_lifetime_contract.exs").is_file():
        raise PackageInputError("candidate package lacks the lifetime expansion migration")
    if "priv/repo/migrations/20261021000000_add_client_lifetime_contract.exs" in old_entries:
        raise PackageInputError("pinned old package unexpectedly contains the lifetime expansion migration")
    old_checksums = migration_checksums(old_package)
    candidate_checksums = migration_checksums(candidate_package)
    if not old_checksums or any(candidate_checksums.get(name) != checksum for name, checksum in old_checksums.items()):
        raise PackageInputError("candidate package changed a shipped migration checksum")

    old_host = prepare_provider(old_root, database_url, package_root=old_package, storage_prefix=prefix, candidate_identity=old_identity)
    old_env = mix_env(old_host, old_root, database_url, prefix)
    old_processes = [
        run_child(old_host, old_env, ("ecto.create",)),
        run_child(old_host, old_env, ("ecto.migrate",)),
    ]

    # The old package still reads and writes every row after expansion: its schema ignores
    # the additive columns and PostgreSQL supplies the constant v0 default.
    candidate_host = prepare_provider(
        candidate_root, database_url, package_root=candidate_package, storage_prefix=prefix,
        candidate_identity=candidate_identity,
    )
    candidate_env = mix_env(candidate_host, candidate_root, database_url, prefix)
    host_provenance = candidate_host_provenance(candidate_host)
    expansion = run_child(candidate_host, candidate_env, ("ecto.migrate",))

    client_ids = [f"lifetime-{prefix}-{label}" for label in DATES]
    for client_id in client_ids:
        kind = "confidential" if client_id.endswith("stale_after_rotation") else "public"
        create_args = (
            "lockspire.client.create", "--client-type", kind, "--client-id", client_id,
            "--redirect-uri", "https://client.example/callback", "--scope", "openid",
            "--grant-type", "authorization_code", "--name", "Upgrade proof",
        )
        old_processes.append(run_child(old_host, old_env, (
            *create_args,
        )))

    qualified = f"{prefix}.lockspire_clients"
    date_updates = [
        f'Ecto.Adapters.SQL.query!(repo, "UPDATE {qualified} SET client_secret_expires_at = NULL WHERE client_id = $1", ["{client_ids[0]}"])',
        f'Ecto.Adapters.SQL.query!(repo, "UPDATE {qualified} SET client_secret_expires_at = created_at WHERE client_id = $1", ["{client_ids[1]}"])',
        f'Ecto.Adapters.SQL.query!(repo, "UPDATE {qualified} SET client_secret_expires_at = TIMESTAMPTZ \'2000-01-01 00:00:00+00\' WHERE client_id = $1", ["{client_ids[2]}"])',
        f'Ecto.Adapters.SQL.query!(repo, "UPDATE {qualified} SET client_secret_expires_at = TIMESTAMPTZ \'2099-01-01 00:00:00+00\' WHERE client_id = $1", ["{client_ids[3]}"])',
        f'Ecto.Adapters.SQL.query!(repo, "UPDATE {qualified} SET client_secret_expires_at = TIMESTAMPTZ \'2000-01-02 00:00:00+00\' WHERE client_id = $1", ["{client_ids[4]}"])',
    ]
    seed_dates = (
        'repo = Lockspire.Config.repo!(); ' + "; ".join(date_updates) + "; "
        f'{{:ok, _rotated}} = Lockspire.Admin.Clients.rotate_client_secret("{client_ids[4]}", %{{rotated_at: DateTime.utc_now(), actor: %{{type: :operator, id: "upgrade-proof"}}}}); '
        'IO.puts("LEGACY_SECRET_DATES_SEEDED=5;STALE_DATE_SURVIVED_ROTATION=1")'
    )
    old_rotation = run_child(old_host, old_env, ("run", "-e", seed_dates))
    old_processes.append(old_rotation)
    legacy_material = {
        "id": run_root / f"legacy-dcr-id-{prefix}",
        "secret": run_root / f"legacy-dcr-secret-{prefix}",
        "rat": run_root / f"legacy-dcr-rat-{prefix}",
    }
    legacy_dcr_setup = (
        '{:ok, policy} = Lockspire.Admin.ServerPolicy.put_dcr_policy(%{'
        'registration_policy: :open, dcr_allowed_scopes: ["openid"], '
        'dcr_allowed_grant_types: ["authorization_code"], dcr_allowed_response_types: ["code"], '
        'dcr_allowed_redirect_uri_schemes: ["https"], dcr_allowed_redirect_uri_hosts: ["client.example"], '
        'dcr_allowed_token_endpoint_auth_methods: ["client_secret_basic"], '
        'dcr_default_client_lifetime_seconds: 3600, dcr_default_client_secret_lifetime_seconds: 3600, '
        'dcr_default_registration_access_token_lifetime_seconds: 3600}); '
        'metadata = %{"client_name" => "Pinned legacy DCR client", '
        '"redirect_uris" => ["https://client.example/callback"], "grant_types" => ["authorization_code"], '
        '"response_types" => ["code"], "token_endpoint_auth_method" => "client_secret_basic", "scope" => "openid"}; '
        '{:ok, registered} = Lockspire.Protocol.Registration.register(%{metadata: metadata, server_policy: policy, source: %{ip: "127.0.0.1", user_agent: "legacy-cutover-proof"}}); '
        'client = registered.client; repo = Lockspire.Config.repo!(); '
        f'Ecto.Adapters.SQL.query!(repo, "UPDATE {prefix}.lockspire_clients SET client_secret_expires_at = TIMESTAMPTZ \'2000-01-02 00:00:00+00\' WHERE client_id = $1", [client.client_id]); '
        f'File.write!({json.dumps(str(legacy_material["id"]))}, client.client_id); File.chmod!({json.dumps(str(legacy_material["id"]))}, 0o600); '
        f'File.write!({json.dumps(str(legacy_material["secret"]))}, registered.client_secret_plaintext); File.chmod!({json.dumps(str(legacy_material["secret"]))}, 0o600); '
        f'File.write!({json.dumps(str(legacy_material["rat"]))}, registered.registration_access_token_plaintext); File.chmod!({json.dumps(str(legacy_material["rat"]))}, 0o600); '
        'IO.puts("LEGACY_DCR_CREDENTIALS_CREATED=1")'
    )
    legacy_dcr = run_child(old_host, old_env, ("run", "-e", legacy_dcr_setup))
    old_processes.append(legacy_dcr)
    if "LEGACY_DCR_CREDENTIALS_CREATED=1" not in str(legacy_dcr["output"]):
        raise PackageInputError("pinned old package did not create a DCR legacy credential")
    id_sql = ",".join("'" + value.replace("'", "''") + "'" for value in client_ids)
    old_read = run_child(old_host, old_env, (
        "run", "-e",
        'repo = Lockspire.Config.repo!(); '
        f'result = Ecto.Adapters.SQL.query!(repo, "SELECT count(*) FROM {qualified} WHERE client_id IN ({id_sql})", []); '
        'unless result.rows == [[5]], do: raise("old package could not read expanded rows"); IO.puts("OLD_EXPANDED_ROWS_READ=5")',
    ))
    old_processes.append(old_read)

    # All old child Mix processes have exited before the candidate's first v1 registration.
    old_stopped = all(item["exit_code"] == 0 for item in old_processes)
    if not old_stopped:
        raise PackageInputError("old writer process did not stop before cutover")
    policy = run_child(candidate_host, candidate_env, (
        "run", "-e",
        '{:ok, _} = Lockspire.Admin.ServerPolicy.put_dcr_policy(%{'
        'registration_policy: :open, dcr_allowed_scopes: ["openid"], '
        'dcr_allowed_grant_types: ["authorization_code"], dcr_allowed_response_types: ["code"], '
        'dcr_allowed_redirect_uri_schemes: ["https"], dcr_allowed_redirect_uri_hosts: ["client.example"], '
        'dcr_allowed_token_endpoint_auth_methods: ["client_secret_basic"], '
        'dcr_default_client_lifetime_seconds: 3600, dcr_default_client_secret_lifetime_seconds: 90, '
        'dcr_default_registration_access_token_lifetime_seconds: 3600}); IO.puts("LEGACY_CURRENT_POLICY_READY=1")',
    ))
    if "LEGACY_CURRENT_POLICY_READY=1" not in str(policy["output"]):
        raise PackageInputError("candidate current lifetime policy setup did not complete")

    v0_probe = (
        'repo = Lockspire.Config.repo!(); '
        f'result = Ecto.Adapters.SQL.query!(repo, "SELECT client_id, lifetime_version, client_expires_at, CASE WHEN client_secret_expires_at IS NULL THEN \'nil\' WHEN client_secret_expires_at::date = created_at::date THEN \'creation\' WHEN client_secret_expires_at < NOW() THEN \'past\' WHEN client_secret_expires_at > NOW() THEN \'future\' ELSE \'other\' END FROM {qualified} WHERE client_id IN ({id_sql})", []); '
        'now = DateTime.utc_now() |> DateTime.truncate(:second); '
        'valid = length(result.rows) == 5 and Enum.all?(result.rows, fn [_id, version, deadline, _date_kind] -> '
        'version == 0 and Lockspire.Domain.Client.app_eligibility(%Lockspire.Domain.Client{active: true, lifetime_version: version, client_expires_at: deadline}, now, :upgrade_proof) == :ok end); '
        'date_kinds = result.rows |> Enum.map(&Enum.at(&1, 3)) |> MapSet.new(); '
        'expected = MapSet.new(["nil", "creation", "past", "future"]); '
        f'stale = Enum.any?(result.rows, fn [id, _version, _deadline, kind] -> id == "{client_ids[4]}" and kind == "past" end); '
        'unless valid and MapSet.subset?(expected, date_kinds) and stale, do: raise("v0 legacy rows or historical dates failed observation"); '
        'IO.puts("V0_LEGACY_ROWS_VERIFIED=#{length(result.rows)};LEGACY_DATE_KINDS=#{MapSet.size(date_kinds)};STALE_AFTER_ROTATION_OBSERVED=1;LEGACY_V0_UNLIMITED=1;LEGACY_SECRET_PAST=1")'
    )
    legacy_observation = run_child(candidate_host, candidate_env, ("run", "-e", v0_probe))
    if "V0_LEGACY_ROWS_VERIFIED=5;LEGACY_DATE_KINDS=4;STALE_AFTER_ROTATION_OBSERVED=1;LEGACY_V0_UNLIMITED=1;LEGACY_SECRET_PAST=1" not in str(legacy_observation["output"]):
        raise PackageInputError("candidate did not observe five unlimited v0 rows and four historical date shapes")
    legacy_dcr_id = legacy_material["id"].read_text(encoding="utf-8").strip()
    legacy_secret = legacy_material["secret"].read_text(encoding="utf-8").strip()
    legacy_rat = legacy_material["rat"].read_text(encoding="utf-8").strip()
    redactor.register_material(legacy_secret)
    redactor.register_material(legacy_rat)
    legacy_probe_expr = (
        f'{{:ok, client}} = Lockspire.Admin.Clients.get_client({json.dumps(legacy_dcr_id)}); '
        'now = DateTime.utc_now(); '
        'valid = client.lifetime_version == 0 and client.client_secret_expires_at < now and '
        'client.registration_access_token_expires_at < now and is_nil(client.client_expires_at) and '
        'Lockspire.Domain.Client.app_eligibility(client, now, :upgrade_proof) == :ok and '
        'Lockspire.Domain.Client.secret_eligibility(client, now, :upgrade_proof) == :ok and '
        'Lockspire.Domain.Client.management_eligibility(client, now, :upgrade_proof) == :ok; '
        'IO.puts("LEGACY_DCR_V0_ADVISORY_DATES=#{if valid, do: 1, else: 0}")'
    )
    legacy_probe = run_child(candidate_host, candidate_env, ("run", "-e", legacy_probe_expr))
    if "LEGACY_DCR_V0_ADVISORY_DATES=1" not in str(legacy_probe["output"]):
        raise PackageInputError("candidate did not observe expired DCR advisory dates as unlimited v0 authority")

    v1_id = f"lifetime-{prefix}-candidate-v1"
    v1_write = run_child(candidate_host, candidate_env, (
        "lockspire.client.create", "--client-type", "public", "--client-id", v1_id,
        "--redirect-uri", "https://client.example/callback", "--scope", "openid",
        "--grant-type", "authorization_code", "--name", "Candidate v1 proof",
    ))
    retained_probe = (
        'repo = Lockspire.Config.repo!(); '
        f'result = Ecto.Adapters.SQL.query!(repo, "SELECT lifetime_version FROM {qualified} WHERE client_id = $1", ["{v1_id}"]); '
        'unless result.rows == [[1]], do: raise("candidate v1 state was not retained"); IO.puts("V1_STATE_RETAINED=1")'
    )
    retained_observation = run_child(candidate_host, candidate_env, ("run", "-e", retained_probe))
    if "V1_STATE_RETAINED=1" not in str(retained_observation["output"]):
        raise PackageInputError("candidate did not observe retained authoritative v1 state")
    signing_key = run_child(candidate_host, candidate_env, (
        "run", "-e",
        '{:ok, %{key: key}} = Lockspire.Admin.generate_key(:sig); '
        '{:ok, _} = Lockspire.Admin.publish_key(key.id); '
        '{:ok, _} = Lockspire.Admin.activate_key(key.id); '
        'IO.puts("LEGACY_HTTP_SIGNING_KEY_READY=1")',
    ))
    if "LEGACY_HTTP_SIGNING_KEY_READY=1" not in str(signing_key["output"]):
        raise PackageInputError("candidate signing key setup did not complete before the HTTP token flow")
    http_port = allocate_loopback_port(set())
    candidate_env.update({"PORT": str(http_port), "LOCKSPIRE_ISSUER": f"http://127.0.0.1:{http_port}/lockspire"})
    http_process = start_process(candidate_host, candidate_env, run_root / f"candidate-http-{prefix}.log")
    try:
        origin = f"http://127.0.0.1:{http_port}"
        wait_ready(origin)
        http_observation = exercise_legacy_http_use(origin, legacy_dcr_id, legacy_secret, redactor)
        promotion_observation, promotion_marker = replace_legacy_authorities(
            origin, candidate_host, candidate_env, legacy_dcr_id, legacy_secret, legacy_rat, run_root, redactor
        )
    finally:
        stop_process(http_process)
    if http_process.poll() is None:
        raise PackageInputError("candidate HTTP process remained alive after legacy upgrade observation")
    if http_observation != {
        "par_http_status": 201, "authorize_http_status": 302, "login_http_status": 200, "token_http_status": 200,
        "lifetime_version": 0, "client_secret_date_kind": "past", "access_token_issued": True,
    }:
        raise PackageInputError("candidate HTTP flow did not use the past-dated unlimited v0 legacy credential")
    legacy_http_process = {
        "pid": http_process.pid, "command": "run", "exit_code": int(http_process.returncode),
        "output": "LEGACY_HTTP_AUTH=1;LEGACY_V0_UNLIMITED=1;LEGACY_SECRET_PAST=1",
    }
    legacy_promotion_process = {
        "pid": http_process.pid, "command": "run", "exit_code": int(http_process.returncode),
        "output": promotion_marker,
    }
    database_cleanup = run_child(candidate_host, candidate_env, ("ecto.drop",))

    receipt = {
        "prefix": prefix,
        "old_package": old_identity.safe_receipt(),
        "candidate_package": {
            "kind": candidate_identity.kind,
            "version": candidate_identity.version,
            "archive_sha256": candidate_identity.archive_sha256,
            "tree_sha256": candidate_identity.tree_sha256,
            "source_revision": candidate_identity.source_revision,
            **host_provenance,
        },
        "historical_migration_checksums_preserved": True,
        "historical_migration_checksum_count": len(old_checksums),
        "historical_migration_checksums_sha256": hashlib.sha256(json.dumps(old_checksums, sort_keys=True).encode()).hexdigest(),
        "old_processes": old_processes,
        "expansion_process": expansion,
        "old_writer_processes_stopped_before_v1": old_stopped,
        "old_read_write_count": len(client_ids),
        "old_read_observation": old_read,
        "v0_legacy_rows_observation": legacy_observation,
        "old_rotation_observation": old_rotation,
        "candidate_v1_write_process": v1_write,
        "legacy_http_use_observation": http_observation,
        "legacy_http_use_process": legacy_http_process,
        "legacy_promotion_observation": promotion_observation,
        "legacy_promotion_process": legacy_promotion_process,
        "v1_state_retained_observation": retained_observation,
        "v1_state_retained": "V1_STATE_RETAINED=1" in str(retained_observation["output"]),
        "database_cleanup_process": database_cleanup,
        "old_binary_after_v1_traffic": False,
        "rollback_boundary": "retain schema and v1 state; fix forward or use lifetime-aware rollback",
    }
    return receipt


def validate_receipt(receipt: dict[str, object], expected_prefixes: set[str] | None = None) -> None:
    if not isinstance(receipt, dict) or set(receipt) != UPGRADE_RECEIPT_FIELDS or receipt.get("schema_version") != 1:
        raise PackageInputError("receipt fields are invalid")
    expected_prefixes = set(SCENARIOS.values()) if expected_prefixes is None else expected_prefixes
    rows = receipt.get("scenarios")
    if not isinstance(rows, list) or {row.get("prefix") for row in rows if isinstance(row, dict)} != expected_prefixes:
        raise PackageInputError("receipt is missing a requested prefix scenario")
    candidate_identities: set[tuple[object, ...]] = set()
    for row in rows:
        if not isinstance(row, dict) or set(row) != UPGRADE_SCENARIO_FIELDS:
            raise PackageInputError("receipt scenario fields are invalid")
        for name in ("old_processes",):
            processes = row.get(name)
            if not isinstance(processes, list) or any(not isinstance(item, dict) or set(item) != PROCESS_FIELDS for item in processes):
                raise PackageInputError("receipt process fields are invalid")
            if any(
                type(item.get("pid")) is not int
                or item.get("command") not in SAFE_COMMANDS
                or type(item.get("exit_code")) is not int
                for item in processes
            ):
                raise PackageInputError("receipt process identity is invalid")
        for name in (
            "expansion_process", "old_read_observation", "v0_legacy_rows_observation",
            "old_rotation_observation", "candidate_v1_write_process", "v1_state_retained_observation",
            "legacy_http_use_process", "legacy_promotion_process", "database_cleanup_process",
        ):
            process = row.get(name)
            if not isinstance(process, dict) or set(process) != PROCESS_FIELDS:
                raise PackageInputError("receipt process fields are invalid")
            if (
                type(process.get("pid")) is not int
                or process.get("command") not in SAFE_COMMANDS
                or type(process.get("exit_code")) is not int
            ):
                raise PackageInputError("receipt process identity is invalid")
            output = process.get("output")
            if not isinstance(output, str) or len(output) > 3000 or any(
                line and not SAFE_MARKER.fullmatch(line) for line in output.splitlines()
            ):
                raise PackageInputError("receipt process output is not an allowlisted observation")
        if not isinstance(row, dict) or row.get("old_read_write_count", 0) < len(DATES):
            raise PackageInputError("receipt has no observed old package writes")
        if "OLD_EXPANDED_ROWS_READ=5" not in str(row.get("old_read_observation", {}).get("output", "")):
            raise PackageInputError("receipt is missing the old package's post-expansion read")
        if "V0_LEGACY_ROWS_VERIFIED=5;LEGACY_DATE_KINDS=4;STALE_AFTER_ROTATION_OBSERVED=1;LEGACY_V0_UNLIMITED=1;LEGACY_SECRET_PAST=1" not in str(row.get("v0_legacy_rows_observation", {}).get("output", "")):
            raise PackageInputError("receipt is missing the candidate's observed v0-unlimited and historical-date results")
        if "STALE_DATE_SURVIVED_ROTATION=1" not in str(row.get("old_rotation_observation", {}).get("output", "")):
            raise PackageInputError("receipt is missing the old package secret-rotation observation")
        legacy_http = row.get("legacy_http_use_observation")
        if legacy_http != {
            "par_http_status": 201, "authorize_http_status": 302, "login_http_status": 200, "token_http_status": 200,
            "lifetime_version": 0, "client_secret_date_kind": "past", "access_token_issued": True,
        }:
            raise PackageInputError("receipt is missing successful candidate HTTP use of a past-dated unlimited v0 credential")
        if "LEGACY_HTTP_AUTH=1;LEGACY_V0_UNLIMITED=1;LEGACY_SECRET_PAST=1" not in str(row.get("legacy_http_use_process", {}).get("output", "")):
            raise PackageInputError("receipt is missing the candidate legacy HTTP flow process observation")
        promotion = row.get("legacy_promotion_observation")
        if not isinstance(promotion, dict) or set(promotion) != LEGACY_PROMOTION_FIELDS:
            raise PackageInputError("receipt is missing complete canonical legacy promotion observations")
        if (
            promotion.get("old_secret_http_status") != 401
            or promotion.get("replacement_secret_http_status") != 200
            or promotion.get("management_put_http_status") != 200
            or promotion.get("old_management_http_status") != 401
            or promotion.get("replacement_management_http_status") != 200
            or promotion.get("lifetime_version") != 1
            or any(promotion.get(key) is not True for key in (
                "app_unlimited", "secret_current_policy_deadline", "management_current_policy_deadline",
                "whole_row_promoted", "unrelated_authority_preserved", "audit_persisted",
            ))
            or promotion.get("wire_client_expires_at") != 0
            or type(promotion.get("wire_registration_access_token_expires_at")) is not int
            or promotion["wire_registration_access_token_expires_at"] <= 0
        ):
            raise PackageInputError("receipt does not prove successful current-policy legacy row promotion")
        if str(row.get("legacy_promotion_process", {}).get("output", "")) != (
            "LEGACY_WHOLE_ROW_PROMOTED=1;LEGACY_MANAGEMENT_AUTHORITY_PRESERVED=1;"
            "LEGACY_MANAGEMENT_POLICY_DEADLINE=1;LEGACY_MANAGEMENT_AUDIT=1"
        ):
            raise PackageInputError("receipt is missing the persisted legacy promotion process observation")
        if not row.get("old_writer_processes_stopped_before_v1") or not row.get("v1_state_retained"):
            raise PackageInputError("receipt is missing the writer drain or retained-v1-state boundary")
        if row.get("database_cleanup_process", {}).get("exit_code") != 0:
            raise PackageInputError("receipt is missing isolated database cleanup")
        if not row.get("historical_migration_checksums_preserved") or row.get("historical_migration_checksum_count", 0) == 0:
            raise PackageInputError("receipt is missing byte-preserved historical migration checksums")
        if row.get("old_binary_after_v1_traffic") is not False:
            raise PackageInputError("receipt claims unsafe old-binary protocol rollback")
        if not isinstance(row.get("old_package"), dict) or set(row["old_package"]) != OLD_PACKAGE_FIELDS:
            raise PackageInputError("receipt old package identity fields are invalid")
        candidate = row.get("candidate_package")
        candidate_fields = frozenset({"kind", "version", "archive_sha256", "tree_sha256", "source_revision", "vendor_tree_sha256", "compiled_candidate_sha256", "resolved_dependency_verified"})
        if not isinstance(candidate, dict) or set(candidate) != candidate_fields:
            raise PackageInputError("receipt is missing candidate package identity")
        if not all(isinstance(candidate.get(key), str) for key in ("kind", "version", "archive_sha256", "tree_sha256", "source_revision", "vendor_tree_sha256", "compiled_candidate_sha256")):
            raise PackageInputError("receipt candidate package identity is incomplete")
        if any(not re.fullmatch(r"[0-9a-f]{64}", str(candidate[key])) for key in ("archive_sha256", "tree_sha256", "vendor_tree_sha256", "compiled_candidate_sha256")):
            raise PackageInputError("receipt candidate package digest is invalid")
        if not re.fullmatch(r"[0-9a-f]{40,64}", str(candidate["source_revision"])):
            raise PackageInputError("receipt candidate source revision is invalid")
        if candidate.get("resolved_dependency_verified") is not True or candidate["vendor_tree_sha256"] != candidate["tree_sha256"]:
            raise PackageInputError("receipt candidate host provenance is incomplete")
        candidate_identities.add(tuple(candidate[key] for key in ("kind", "version", "archive_sha256", "tree_sha256", "source_revision")))
    if len(candidate_identities) != 1:
        raise PackageInputError("prefix scenarios do not share one candidate identity")
    try:
        validate_candidate_identity_agreement(
            [{key: row["candidate_package"][key] for key in ("kind", "version", "archive_sha256", "tree_sha256", "source_revision")} for row in rows]
        )
    except (AssertionError, KeyError, TypeError):
        raise PackageInputError("prefix scenarios do not share one candidate identity") from None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scenario", choices=("all", *SCENARIOS), default="all")
    parser.add_argument("--receipt", type=Path)
    parser.add_argument("--check-receipt", type=Path)
    parser.add_argument("--work-root", type=Path, help="reuse isolated package and provider trees under this task-local directory")
    parser.add_argument("--package-tar", type=Path)
    parser.add_argument("--package-sha256")
    parser.add_argument("--source-revision")
    args = parser.parse_args()
    redactor = Redactor(SentinelSet.for_run())
    try:
        if args.check_receipt:
            validate_receipt(json.loads(args.check_receipt.read_text()))
            print("lifetime upgrade receipt verified")
            return 0
        selected = list(SCENARIOS) if args.scenario == "all" else [args.scenario]
        debug_root = str(args.work_root) if args.work_root else os.environ.get("LOCKSPIRE_UPGRADE_DEBUG_ROOT")
        if debug_root:
            run_root = Path(debug_root).resolve()
            run_root.mkdir(mode=0o700, parents=True, exist_ok=True)
            candidate_package, _entries, candidate_identity = prepare_package(
                run_root, PackageSource("tar", str(args.package_tar), args.package_sha256)
                if args.package_tar else None
            )
            candidate_archive = args.package_tar.resolve() if args.package_tar else run_root / "package" / f"lockspire-{candidate_identity.version}.tar"
            if args.source_revision:
                if not re.fullmatch(r"[0-9a-f]{40,64}", args.source_revision):
                    raise PackageInputError("candidate source revision is invalid")
                candidate_identity = PackageIdentity(
                    candidate_identity.kind, candidate_identity.version, candidate_identity.sha256,
                    candidate_identity.archive_sha256, candidate_identity.tree_sha256, args.source_revision,
                )
            scenarios = [run_scenario(run_root, SCENARIOS[name], candidate_package, candidate_archive, candidate_identity, redactor) for name in selected]
            receipt = {"schema_version": 1, "scenarios": scenarios}
            validate_receipt(receipt, {SCENARIOS[name] for name in selected})
            rendered = json.dumps(receipt, sort_keys=True, indent=2)
            if args.receipt:
                args.receipt.parent.mkdir(parents=True, exist_ok=True)
                args.receipt.write_text(rendered + "\n")
            print(rendered)
        else:
            with tempfile.TemporaryDirectory(prefix="lockspire-lifetime-upgrade-") as temporary:
                run_root = Path(temporary)
                candidate_package, _entries, candidate_identity = prepare_package(
                    run_root, PackageSource("tar", str(args.package_tar), args.package_sha256)
                    if args.package_tar else None
                )
                candidate_archive = args.package_tar.resolve() if args.package_tar else run_root / "package" / f"lockspire-{candidate_identity.version}.tar"
                if args.source_revision:
                    if not re.fullmatch(r"[0-9a-f]{40,64}", args.source_revision):
                        raise PackageInputError("candidate source revision is invalid")
                    candidate_identity = PackageIdentity(
                        candidate_identity.kind, candidate_identity.version, candidate_identity.sha256,
                        candidate_identity.archive_sha256, candidate_identity.tree_sha256, args.source_revision,
                    )
                scenarios = [run_scenario(run_root, SCENARIOS[name], candidate_package, candidate_archive, candidate_identity, redactor) for name in selected]
                receipt = {"schema_version": 1, "scenarios": scenarios}
                validate_receipt(receipt, {SCENARIOS[name] for name in selected})
                rendered = json.dumps(receipt, sort_keys=True, indent=2)
                if args.receipt:
                    args.receipt.parent.mkdir(parents=True, exist_ok=True)
                    args.receipt.write_text(rendered + "\n")
                print(rendered)
        return 0
    except (PackageInputError, OSError, ValueError) as error:
        summary = safe_failure_summary(
            stage="legacy_upgrade", scenario="selected", event="runner_failure",
            field=type(error).__name__, count=1,
        )
        print(str(summary), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
