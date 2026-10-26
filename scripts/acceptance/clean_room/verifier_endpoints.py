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
                ENDPOINT_CASES[0]: _positive(token["status"] == 200 and token["token_issued"], token["status"]),
                ENDPOINT_CASES[1]: _positive(introspection["status"] == 200 and introspection["active"] is True, introspection["status"]),
                ENDPOINT_CASES[2]: _positive(revocation["status"] == 200, revocation["status"]),
                ENDPOINT_CASES[3]: _positive(device["status"] == 200 and device["result"], device["status"], device.get("safe_error"), device.get("safe_description")),
                ENDPOINT_CASES[4]: _positive(ciba["status"] == 200 and ciba["result"], ciba["status"], ciba.get("safe_error"), ciba.get("safe_description")),
                ENDPOINT_CASES[5]: _positive(par["status"] in (400, 401) and not par["success"], par["status"], par.get("safe_error"), par.get("safe_description")),
                ENDPOINT_CASES[6]: _positive(all(negatives.values()), 400 if all(negatives.values()) else 200),
                ENDPOINT_CASES[7]: _positive(basic["status"] == 200 and basic["token_issued"], basic["status"]),
                ENDPOINT_CASES[8]: _positive(post["status"] == 200 and post["token_issued"], post["status"]),
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
              safe_description: str | None = None) -> dict[str, object]:
    return {"outcome": "pass" if passed else "fail", "executed": True,
            "assertion_passed": bool(passed), "fresh_jti": True, "http_status": status,
            "safe_error": safe_error, "safe_description": safe_description}


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
