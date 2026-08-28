#!/usr/bin/env python3
"""Run the Phase 133 bearer SaaS journey over two independently booted origins.

The runner is deliberately a browser-like transport driver.  Confidential client
authentication, token handling, discovery/JWKS validation, and resource access
remain inside the clean-room client process; this script only observes safe HTTP
receipts and redirects.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import http.client
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import time
from http.cookies import SimpleCookie
from urllib.parse import parse_qs, urlencode, urljoin, urlparse
import uuid

CLEAN_ROOM_DIR = Path(__file__).resolve().parent / "clean_room"
sys.path.insert(0, str(CLEAN_ROOM_DIR))

from build_client import patch_jose_record_extractors
from build_provider import prepare_provider, run_child_command
from package_input import (
    PackageInputError,
    clean_room_database_url,
    copy_child_template,
    locked_environment,
    package_source,
    prepare_package,
    probe_environment,
    verify_child,
)
from redaction import Redactor, SentinelSet
from processes import allocate_loopback_port


PROVIDER_ORIGIN = "http://127.0.0.1:4100"
CLIENT_ORIGIN = "http://127.0.0.1:4101"
MAX_REDIRECTS = 8
ACTIVE_REDACTOR: Redactor | None = None
RUN_ROOT_MARKER = ".lockspire-clean-room-owner"


class JourneyInterrupted(Exception):
    """Raised from SIGINT/SIGTERM so the runner reaches its teardown path."""


def interruption_handler(signum: int, _frame: object) -> None:
    raise JourneyInterrupted(f"clean-room journey interrupted by signal {signum}")


def register_secret(value: object) -> None:
    if ACTIVE_REDACTOR is not None:
        ACTIVE_REDACTOR.register(value)


class Browser:
    """A bounded origin-aware cookie jar for the browser side of the journey."""

    def __init__(self, origin: str):
        self.origin = origin.rstrip("/")
        self.cookies: dict[str, str] = {}

    def request(self, method: str, target: str, data: dict[str, str] | None = None, extra_headers: dict[str, str] | None = None) -> dict[str, object]:
        url = urljoin(self.origin + "/", target)
        parsed = urlparse(url)
        if f"{parsed.scheme}://{parsed.netloc}" != self.origin:
            raise AssertionError(f"cross-origin request expected {self.origin}, got {parsed.scheme}://{parsed.netloc}")

        headers: dict[str, str] = dict(extra_headers or {})
        body = None
        if data is not None:
            body = urlencode(data).encode()
            headers["content-type"] = "application/x-www-form-urlencoded"
        if self.cookies:
            headers["cookie"] = "; ".join(f"{name}={value}" for name, value in self.cookies.items())

        connection = http.client.HTTPConnection(parsed.hostname, parsed.port, timeout=10)
        path = parsed.path or "/"
        if parsed.query:
            path += "?" + parsed.query
        connection.request(method, path, body=body, headers=headers)
        response = connection.getresponse()
        raw = response.read()
        pairs = response.getheaders()
        connection.close()

        for name, value in pairs:
            if name.lower() == "set-cookie":
                parsed_cookie = SimpleCookie()
                parsed_cookie.load(value)
                self.cookies.update({key: morsel.value for key, morsel in parsed_cookie.items()})
                for morsel in parsed_cookie.values():
                    register_secret(morsel.value)

        return {"status": response.status, "headers": {key.lower(): value for key, value in pairs}, "body": raw.decode("utf-8", "replace")}


def claim_run_root(run_root: Path) -> str:
    """Bind cleanup and subprocess state to this exact, freshly-created root."""

    resolved = run_root.resolve(strict=True)
    owner = uuid.uuid4().hex
    marker = resolved / RUN_ROOT_MARKER
    marker.write_text(owner, encoding="ascii")
    return owner


def assert_owned_run_root(run_root: Path, owner: str) -> None:
    """Fail closed if this process no longer owns its unique temporary root."""

    try:
        marker = run_root.resolve(strict=True) / RUN_ROOT_MARKER
        if marker.read_text(encoding="ascii") != owner:
            raise AssertionError("clean-room run root ownership changed")
    except FileNotFoundError as error:
        raise AssertionError("clean-room run root disappeared before cleanup") from error


def require_status(response: dict[str, object], status: int, label: str) -> None:
    if response["status"] != status:
        if label == "client callback":
            time.sleep(10)
        raise AssertionError(
            f"{label}: expected HTTP {status}, got {response['status']}"
            f"{safe_oauth_error_code(response)}"
        )


def safe_oauth_error_code(response: dict[str, object]) -> str:
    """Return only the standardized OAuth error code for failed wire diagnostics.

    The runner must never retain or render a raw response body: token endpoint
    errors can be produced adjacent to credentials and other confidential
    material.  OAuth error identifiers are a bounded protocol vocabulary, so
    they are sufficient to locate a failed validation seam without widening the
    evidence surface.
    """

    try:
        error = json.loads(str(response["body"])).get("error")
    except (AttributeError, TypeError, json.JSONDecodeError):
        return ""

    if isinstance(error, str) and re.fullmatch(r"[a-z_]{1,64}", error):
        return f" ({error})"

    return ""


def redirect(response: dict[str, object], label: str) -> str:
    value = response["headers"].get("location")  # type: ignore[union-attr]
    if not isinstance(value, str):
        raise AssertionError(f"{label}: missing redirect location")
    for key, values in parse_qs(urlparse(value).query).items():
        if key in {"code", "id_token", "access_token", "refresh_token"}:
            for item in values:
                register_secret(item)
    return value


def csrf(body: object) -> str:
    rendered = str(body)
    match = re.search(r'<input[^>]+name="_csrf_token"[^>]+value="([^"]+)"', rendered)
    match = match or re.search(r'<input[^>]+value="([^"]+)"[^>]+name="_csrf_token"', rendered)
    match = match or re.search(r'<meta name="csrf-token" content="([^"]+)"', rendered)
    if not match:
        names = re.findall(r'<(?:input|meta)[^>]+(?:name|property)="([^"]+)"', rendered)
        raise AssertionError(f"form is missing CSRF token (fields: {','.join(names[:12])})")
    return match.group(1)


def wait_ready(origin: str) -> None:
    browser = Browser(origin)
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        try:
            if browser.request("GET", "/health" if origin == CLIENT_ORIGIN else "/lockspire/.well-known/openid-configuration")["status"] == 200:
                return
        except OSError:
            pass
        time.sleep(0.1)
    raise AssertionError("listener readiness timed out")


def start_process(child: Path, environment: dict[str, str], log_path: Path) -> subprocess.Popen[bytes]:
    handle = log_path.open("wb")
    process = subprocess.Popen(
        ("mix", "run", "--no-halt"), cwd=child, env=environment, stdin=subprocess.DEVNULL,
        stdout=handle, stderr=subprocess.STDOUT, close_fds=True, start_new_session=True,
    )
    process._clean_room_log_handle = handle  # type: ignore[attr-defined]
    return process


def stop_process(process: subprocess.Popen[bytes] | None) -> None:
    if process is None:
        return
    if process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)
    process._clean_room_log_handle.close()  # type: ignore[attr-defined]


def drop_child_database(child: Path, environment: dict[str, str], label: str) -> None:
    completed = subprocess.run(
        ("mix", "ecto.drop"),
        cwd=child,
        env=environment,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if completed.returncode != 0:
        raise AssertionError(f"{label} database teardown failed")


def prepare_client(
    run_root: Path,
    database_url: str,
    handoff: Path,
    client_port: int,
    package_root: Path,
) -> tuple[Path, dict[str, str]]:
    child = copy_child_template("confidential_client", run_root, package_root)
    environment = locked_environment(child, "confidential_client", dependency_cache_root(run_root))
    environment.update({
        "DATABASE_URL": database_url,
        "PORT": str(client_port),
        "CLEAN_ROOM_PROVIDER_ISSUER": PROVIDER_ORIGIN + "/lockspire",
        "CLEAN_ROOM_CLIENT_ORIGIN": CLIENT_ORIGIN,
        "CLEAN_ROOM_BEARER_SECRET_PATH": str(handoff / "bearer-client.secret"),
        "CLEAN_ROOM_DPOP_SECRET_PATH": str(handoff / "dpop-client.secret"),
        "CLEAN_ROOM_CLIENT_CIPHER_SECRET": "clean-room-client-ephemeral-secret-0123456789",
        "SECRET_KEY_BASE": "clean-room-client-secret-key-base-0123456789-abcdefghijklmnopqrstuvwxyz-0123456789",
    })
    verify_child("confidential_client", child, dependency_cache_root(run_root), {"DATABASE_URL": database_url})
    patch_jose_record_extractors(child, environment)
    run_child_command(child, environment, "ecto.create")
    run_child_command(child, environment, "ecto.migrate", "--migrations-path", "priv/repo/migrations")
    run_child_command(child, environment, "compile", "--warnings-as-errors")
    return child, environment


def dependency_cache_root(run_root: Path) -> Path:
    configured = Path(os.environ["CLEAN_ROOM_CACHE_ROOT"]).resolve() if "CLEAN_ROOM_CACHE_ROOT" in os.environ else run_root / "deps-cache"
    configured.mkdir(mode=0o700, parents=True, exist_ok=True)
    return configured


def configure_origins() -> tuple[int, int]:
    """Allocate one distinct loopback origin pair for this real journey."""
    global PROVIDER_ORIGIN, CLIENT_ORIGIN

    provider_port = allocate_loopback_port(set())
    client_port = allocate_loopback_port({provider_port})
    PROVIDER_ORIGIN = f"http://127.0.0.1:{provider_port}"
    CLIENT_ORIGIN = f"http://127.0.0.1:{client_port}"
    return provider_port, client_port


def verify_concurrent_real_journeys() -> int:
    commands = [[sys.executable, "-u", str(Path(__file__).resolve()), "--only", "happy_path"] for _ in range(2)]
    processes = [subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True) for command in commands]

    for process in processes:
        output, _ = process.communicate(timeout=300)
        if process.returncode != 0 or "cleanup complete" not in output:
            raise AssertionError("concurrent clean-room journey did not complete its isolated teardown")

    print("concurrent real journeys complete")
    return 0


def verify_signal_cleanup() -> int:
    command = [sys.executable, "-u", str(Path(__file__).resolve()), "--only", "happy_path", "--hold-after-ready", "60"]
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    deadline = time.monotonic() + 300
    output = ""

    while time.monotonic() < deadline:
        line = process.stdout.readline() if process.stdout is not None else ""
        output += line
        if "readiness complete" in line:
            process.terminate()
            remaining, _ = process.communicate(timeout=30)
            output += remaining
            if process.returncode != 130 or "cleanup complete" not in output:
                raise AssertionError("signal interruption did not complete clean-room teardown")
            print("signal cleanup complete")
            return 0
        if process.poll() is not None:
            break

    process.kill()
    process.communicate()
    raise AssertionError("signal cleanup probe never reached readiness")


def verify_run_root_ownership() -> int:
    """Prove ownership markers cannot be used across independent run roots."""

    with tempfile.TemporaryDirectory(prefix="lockspire-clean-room-owner-") as first, tempfile.TemporaryDirectory(
        prefix="lockspire-clean-room-owner-"
    ) as second:
        first_root, second_root = Path(first), Path(second)
        first_owner, second_owner = claim_run_root(first_root), claim_run_root(second_root)
        assert_owned_run_root(first_root, first_owner)
        assert_owned_run_root(second_root, second_owner)

        try:
            assert_owned_run_root(first_root, second_owner)
        except AssertionError:
            print("run-root ownership isolation complete")
            return 0

    raise AssertionError("run-root ownership accepted another runner marker")


def assert_redaction_guard(redactor: Redactor, generated_secret: str | None = None) -> None:
    raw = f"Authorization: Bearer {generated_secret or redactor.sentinels.access_token}\nCookie: {redactor.sentinels.cookie}"

    try:
        redactor.assert_safe(raw)
    except RuntimeError:
        pass
    else:
        raise AssertionError("redaction sentinel failure was not detected")

    safe = redactor.text(raw)
    redactor.assert_safe(safe)
    if re.search(r"(?i)(authorization|cookie)\s*[:=]\s*(?!\[REDACTED\])\S", safe):
        raise AssertionError("redaction left a raw sensitive header value")
    print("redaction sentinel failure contained")


def register_handoff_secrets(handoff: Path) -> None:
    for filename in ("bearer-client.secret", "dpop-client.secret"):
        register_secret((handoff / filename).read_text().strip())


def decoded_secret_payload(body: object) -> dict[str, object]:
    payload = json.loads(str(body))
    if not isinstance(payload, dict):
        raise AssertionError("expected JSON object payload")
    for key in ("access_token", "refresh_token", "id_token", "token", "code"):
        register_secret(payload.get(key))
    return payload


def scan_evidence(run_root: Path, redactor: Redactor) -> None:
    for path in sorted(run_root.glob("*.log")):
        evidence = redactor.text(path.read_text(errors="replace"))
        path.write_text(evidence, encoding="utf-8")
        redactor.assert_safe(evidence)
        if re.search(r"(?i)(authorization|cookie|set-cookie)\s*[:=]\s*(?!\[REDACTED\])\S", evidence):
            raise AssertionError(f"unsafe raw header value in {path.name}")
    print("evidence scan complete")


def browser_authorize(client: Browser, provider: Browser, *, account_id: str = "clean-room-user", before_callback=None, callback_transform=None) -> tuple[dict[str, object], str]:
    start = client.request("GET", "/oauth/start")
    require_status(start, 302, "client start")
    authorization_location = redirect(start, "client start")
    if "client_id" not in parse_qs(urlparse(authorization_location).query):
        raise AssertionError("client authorization redirect omitted client_id")
    authorize = provider.request("GET", authorization_location)
    require_status(authorize, 302, "provider authorize")

    login_location = redirect(authorize, "provider authorize")
    if urlparse(login_location).netloc == urlparse(CLIENT_ORIGIN).netloc:
        if before_callback:
            before_callback(client)
        if callback_transform:
            login_location = callback_transform(login_location)
        return client.request("GET", login_location), login_location
    login = provider.request("GET", login_location)
    require_status(login, 200, "provider login")
    resumed = redirect(provider.request("POST", "/login", {
        "_csrf_token": csrf(login["body"]),
        "return_to": re.search(r'name="return_to" value="([^"]*)"', str(login["body"])).group(1),
        "interaction_id": re.search(r'name="interaction_id" value="([^"]*)"', str(login["body"])).group(1),
        "account_id": account_id,
    }), "provider login")
    interaction_id = urlparse(resumed).path.rsplit("/", 1)[-1]
    if not interaction_id:
        raise AssertionError("login did not retain interaction")
    interaction = provider.request("GET", resumed)
    require_status(interaction, 302, "provider interaction")
    consent_location = redirect(interaction, "provider interaction")
    if urlparse(consent_location).netloc == urlparse(CLIENT_ORIGIN).netloc:
        if before_callback:
            before_callback(client)
        if callback_transform:
            consent_location = callback_transform(consent_location)
        return client.request("GET", consent_location), consent_location
    consent = provider.request("GET", consent_location)
    require_status(consent, 200, "provider consent")
    approval = {"decision": "approve", "remember": "true"}
    try:
        approval["_csrf_token"] = csrf(consent["body"])
    except AssertionError:
        # The forwarded Lockspire completion endpoint is not in the host browser
        # pipeline. Its static LiveView shell intentionally has no HTML form token.
        pass
    approved = provider.request("POST", f"/lockspire/interactions/{interaction_id}/complete", approval)
    require_status(approved, 302, "provider consent approval")
    callback = redirect(approved, "provider consent approval")
    callback_error = parse_qs(urlparse(callback).query).get("error", [None])[0]
    if callback_error:
        raise AssertionError(f"provider consent completed with {callback_error}")
    if before_callback:
        before_callback(client)
    if callback_transform:
        callback = callback_transform(callback)
    callback_response = client.request("GET", callback)
    return callback_response, callback


def receipt(client: Browser) -> dict[str, object]:
    response = client.request("GET", "/journey")
    require_status(response, 200, "client journey receipt")
    parsed = json.loads(str(response["body"]))
    forbidden = {"access_token", "refresh_token", "id_token", "code", "nonce", "verifier", "secret", "cookie", "claims"}
    if forbidden & set(parsed):
        raise AssertionError("client receipt exposed confidential material")
    return parsed


def s256(value: str) -> str:
    return base64.urlsafe_b64encode(hashlib.sha256(value.encode()).digest()).decode().rstrip("=")


def basic(client_id: str, client_secret: str) -> str:
    return "Basic " + base64.b64encode(f"{client_id}:{client_secret}".encode()).decode()


def provider_path(endpoint: str) -> str:
    parsed = urlparse(endpoint)
    if f"{parsed.scheme}://{parsed.netloc}" != PROVIDER_ORIGIN:
        raise AssertionError("discovery endpoint left the provider origin")
    return parsed.path + (f"?{parsed.query}" if parsed.query else "")


def lifecycle_code(
    provider: Browser,
    *,
    scopes: str = "openid profile read:billing offline_access",
    resource: str | None = None,
) -> tuple[str, str]:
    # `configure_origins()` assigns a new loopback origin for every journey.
    # Resolve this at invocation time; Python default arguments are evaluated
    # once at module import and would bind an authorization code to the stale
    # fixed-port resource while the token request uses the fresh origin.
    resource = resource or PROVIDER_ORIGIN + "/api/billing"
    state, nonce = uuid.uuid4().hex, uuid.uuid4().hex
    verifier = uuid.uuid4().hex + uuid.uuid4().hex
    register_secret(verifier)
    redirect_uri = CLIENT_ORIGIN + "/oauth/callback"
    authorize = provider.request("GET", "/lockspire/authorize?" + urlencode({
        "response_type": "code", "client_id": "clean-room-bearer", "redirect_uri": redirect_uri,
        "scope": scopes, "state": state, "nonce": nonce,
        "code_challenge": s256(verifier), "code_challenge_method": "S256", "resource": resource,
    }))
    require_status(authorize, 302, "lifecycle authorize")
    login = provider.request("GET", redirect(authorize, "lifecycle authorize"))
    require_status(login, 200, "lifecycle login")
    resumed = redirect(provider.request("POST", "/login", {
        "_csrf_token": csrf(login["body"]),
        "return_to": re.search(r'name="return_to" value="([^"]*)"', str(login["body"])).group(1),
        "interaction_id": re.search(r'name="interaction_id" value="([^"]*)"', str(login["body"])).group(1),
        "account_id": "clean-room-user",
    }), "lifecycle login")
    interaction_id = urlparse(resumed).path.rsplit("/", 1)[-1]
    interaction = provider.request("GET", resumed)
    require_status(interaction, 302, "lifecycle interaction")
    consent_location = redirect(interaction, "lifecycle interaction")
    if urlparse(consent_location).netloc == urlparse(CLIENT_ORIGIN).netloc:
        callback = urlparse(consent_location)
        values = parse_qs(callback.query)
        if values.get("state") != [state]:
            raise AssertionError("lifecycle authorization response violated the callback contract")
        code = values.get("code", [None])[0]
        if not isinstance(code, str):
            raise AssertionError("lifecycle authorization response omitted code")
        return code, verifier
    consent = provider.request("GET", consent_location)
    require_status(consent, 200, "lifecycle consent")
    approved = provider.request("POST", f"/lockspire/interactions/{interaction_id}/complete", {"decision": "approve", "remember": "false"})
    require_status(approved, 302, "lifecycle consent approval")
    callback = urlparse(redirect(approved, "lifecycle consent approval"))
    values = parse_qs(callback.query)
    if callback.scheme + "://" + callback.netloc != CLIENT_ORIGIN or values.get("state") != [state]:
        raise AssertionError("lifecycle authorization response violated the callback contract")
    code = values.get("code", [None])[0]
    if not isinstance(code, str):
        raise AssertionError("lifecycle authorization response omitted code")
    return code, verifier


def run_lifecycle(handoff: Path) -> None:
    provider = Browser(PROVIDER_ORIGIN)
    response = provider.request("GET", "/lockspire/.well-known/openid-configuration")
    require_status(response, 200, "lifecycle discovery")
    discovery = json.loads(str(response["body"]))
    authorization = {"authorization": basic("clean-room-bearer", (handoff / "bearer-client.secret").read_text().strip())}
    code, verifier = lifecycle_code(provider)
    issued = provider.request("POST", provider_path(discovery["token_endpoint"]), {
        "grant_type": "authorization_code", "code": code, "redirect_uri": CLIENT_ORIGIN + "/oauth/callback",
        "code_verifier": verifier, "resource": PROVIDER_ORIGIN + "/api/billing",
    }, authorization)
    require_status(issued, 200, "lifecycle authorization code exchange")
    original_refresh = decoded_secret_payload(issued["body"]).get("refresh_token")
    if not isinstance(original_refresh, str):
        raise AssertionError("lifecycle authorization code exchange omitted refresh token")
    rotated = provider.request("POST", provider_path(discovery["token_endpoint"]), {"grant_type": "refresh_token", "refresh_token": original_refresh}, authorization)
    require_status(rotated, 200, "lifecycle refresh rotation")
    rotated_refresh = decoded_secret_payload(rotated["body"]).get("refresh_token")
    if not isinstance(rotated_refresh, str) or rotated_refresh == original_refresh:
        raise AssertionError("lifecycle refresh rotation did not return a distinct refresh token")
    print("refresh rotation complete")
    replay = provider.request("POST", provider_path(discovery["token_endpoint"]), {"grant_type": "refresh_token", "refresh_token": original_refresh}, authorization)
    require_status(replay, 400, "lifecycle refresh reuse")
    if json.loads(str(replay["body"])).get("error") != "invalid_grant":
        raise AssertionError("lifecycle refresh reuse did not return invalid_grant")
    print("refresh reuse contained")
    introspection = provider.request("POST", provider_path(discovery["introspection_endpoint"]), {"token": rotated_refresh}, authorization)
    require_status(introspection, 200, "lifecycle family introspection")
    if json.loads(str(introspection["body"])) != {"active": False}:
        raise AssertionError("lifecycle family introspection was not inactive")
    print("family introspection inactive")
    for attempt in range(2):
        revocation = provider.request("POST", provider_path(discovery["revocation_endpoint"]), {"token": rotated_refresh}, authorization)
        require_status(revocation, 200, f"lifecycle revocation {attempt + 1}")
        if json.loads(str(revocation["body"])) != {}:
            raise AssertionError("lifecycle revocation did not return its empty success response")
    print("idempotent revocation complete")


def token_exchange(provider: Browser, discovery: dict[str, object], authorization: dict[str, str], code: str, verifier: str, resource: str) -> dict[str, object]:
    response = provider.request("POST", provider_path(str(discovery["token_endpoint"])), {
        "grant_type": "authorization_code", "code": code, "redirect_uri": CLIENT_ORIGIN + "/oauth/callback",
        "code_verifier": verifier, "resource": resource,
    }, authorization)
    require_status(response, 200, "negative authorization code exchange")
    return decoded_secret_payload(response["body"])


def assert_challenge(response: dict[str, object], status: int, error: str, label: str) -> None:
    require_status(response, status, label)
    challenge = response["headers"].get("www-authenticate", "")  # type: ignore[union-attr]
    if not challenge.startswith("Bearer realm=\"Lockspire\""):
        raise AssertionError(f"{label}: missing Bearer challenge")
    if error and f'error="{error}"' not in challenge:
        raise AssertionError(f"{label}: missing {error} challenge")


def run_negative(handoff: Path) -> None:
    provider, client = Browser(PROVIDER_ORIGIN), Browser(CLIENT_ORIGIN)
    discovery_response = provider.request("GET", "/lockspire/.well-known/openid-configuration")
    require_status(discovery_response, 200, "negative discovery")
    discovery = json.loads(str(discovery_response["body"]))
    authorization = {"authorization": basic("clean-room-bearer", (handoff / "bearer-client.secret").read_text().strip())}
    billing = PROVIDER_ORIGIN + "/api/billing"

    drift = provider.request("GET", "/lockspire/authorize?" + urlencode({
        "response_type": "code", "client_id": "clean-room-bearer", "redirect_uri": CLIENT_ORIGIN + "/unexpected",
        "scope": "openid", "state": uuid.uuid4().hex, "nonce": uuid.uuid4().hex,
        "code_challenge": s256(uuid.uuid4().hex + uuid.uuid4().hex), "code_challenge_method": "S256",
    }))
    require_status(drift, 400, "redirect drift")
    print("redirect drift rejected")

    code, verifier = lifecycle_code(provider)
    token_exchange(provider, discovery, authorization, code, verifier, billing)
    replay = provider.request("POST", provider_path(str(discovery["token_endpoint"])), {
        "grant_type": "authorization_code", "code": code, "redirect_uri": CLIENT_ORIGIN + "/oauth/callback",
        "code_verifier": verifier, "resource": billing,
    }, authorization)
    require_status(replay, 400, "authorization code reuse")
    if json.loads(str(replay["body"])).get("error") != "invalid_grant":
        raise AssertionError("authorization code reuse did not return invalid_grant")
    print("code reuse rejected")

    _, callback = browser_authorize(client, Browser(PROVIDER_ORIGIN), callback_transform=lambda value: value.replace("state=", "state=wrong-", 1))
    attempts = client.request("GET", "/acceptance/callback-attempts")
    require_status(attempts, 200, "callback attempt receipt")
    if json.loads(str(attempts["body"])).get("token_exchange_attempts") != 0:
        raise AssertionError("callback state mismatch reached token exchange")
    client.request("GET", callback)
    print("callback state rejected before exchange")

    nonce_client = Browser(CLIENT_ORIGIN)
    nonce_result, _ = browser_authorize(
        nonce_client,
        Browser(PROVIDER_ORIGIN),
        before_callback=lambda browser: browser.request(
            "POST", "/acceptance/replace-nonce", {"_csrf_token": client_csrf(browser)}
        ),
    )
    require_status(nonce_result, 400, "nonce mismatch callback")
    nonce_receipt = receipt(nonce_client)
    if not str(nonce_receipt.get("failed_stage", "")).startswith("oidc"):
        raise AssertionError("nonce mismatch did not fail in client OIDC validation")
    print("nonce mismatch rejected by client validation")

    assert_challenge(provider.request("GET", "/api/billing/summary"), 401, "", "missing token")
    print("missing token rejected")
    wrong_audience = token_exchange(provider, discovery, authorization, *lifecycle_code(Browser(PROVIDER_ORIGIN), resource=PROVIDER_ORIGIN + "/api/other"), PROVIDER_ORIGIN + "/api/other")
    assert_challenge(provider.request("GET", "/api/billing/summary", extra_headers={"authorization": "Bearer " + str(wrong_audience["access_token"])}), 401, "invalid_token", "wrong audience")
    print("wrong audience rejected")
    under_scoped = token_exchange(provider, discovery, authorization, *lifecycle_code(Browser(PROVIDER_ORIGIN), scopes="openid profile", resource=billing), billing)
    assert_challenge(provider.request("GET", "/api/billing/summary", extra_headers={"authorization": "Bearer " + str(under_scoped["access_token"])}), 403, "insufficient_scope", "insufficient scope")
    print("insufficient scope rejected")


def run_happy() -> None:
    client = Browser(CLIENT_ORIGIN)
    provider = Browser(PROVIDER_ORIGIN)
    result, callback = browser_authorize(client, provider)
    if result["status"] != 200:
        safe = receipt(client)
        stage = safe.get("failed_stage") or str(result["body"]).split(":")[-1].strip()
        raise AssertionError(f"client callback failed at {stage}")
    require_status(result, 200, "client callback")
    safe = receipt(client)
    if safe.get("stages") != ["discovery", "authorization", "callback", "oidc", "userinfo", "resource"]:
        raise AssertionError("safe receipt did not prove validation order")
    resource = safe.get("resource")
    expected = {"subject", "scopes", "audiences", "expires_at", "confirmation"}
    if not isinstance(resource, dict) or set(resource) != expected:
        raise AssertionError("resource response was not the documented semantic contract")
    print("discovery complete")
    print("authorization complete")
    print("callback complete")
    print("oidc complete")
    print("userinfo complete")
    print("resource complete")
    return callback


def run_boundary() -> None:
    client = Browser(CLIENT_ORIGIN)
    provider = Browser(PROVIDER_ORIGIN)
    result, callback = browser_authorize(client, provider, account_id="clean-room-denied-user")
    require_status(result, 400, "host policy denied callback")
    safe = receipt(client)
    if safe.get("host_policy") != "denied" or safe.get("stages", [])[-1:] != ["resource"]:
        raise AssertionError("host policy denial did not follow completed protocol validation")
    retry = client.request("GET", callback)
    require_status(retry, 400, "terminal callback reuse")
    print("callback reuse rejected")
    print("host policy boundary complete")


def safe_dpop_operation(client: Browser, path: str, label: str) -> dict[str, object]:
    response = client.request("POST", path, {"_csrf_token": client_csrf(client)})
    parsed = json.loads(str(response["body"]))
    if response["status"] != 200:
        raise AssertionError(
            f"{label}: expected HTTP 200, got {response['status']}"
            f"{safe_oauth_error_code(response)}"
            f" (stage: {safe_dpop_failure_stage(parsed)}, provider_status: {safe_dpop_provider_status(parsed)})"
        )
    forbidden = {"access_token", "nonce", "proof", "private_key", "secret", "cookie"}
    if forbidden & set(parsed):
        raise AssertionError(f"{label}: client receipt exposed confidential material")
    return parsed


def safe_dpop_failure_stage(receipt: dict[str, object]) -> str:
    """Return a fixed client-side stage label without rendering HTTP payloads."""

    stage = receipt.get("stage")
    if isinstance(stage, str) and re.fullmatch(r"[a-z_]{1,64}", stage):
        return stage
    return "unknown"


def safe_dpop_provider_status(receipt: dict[str, object]) -> str:
    """Render an HTTP status code only when a client operation rejects it."""

    status = receipt.get("provider_status")
    return str(status) if isinstance(status, int) and 100 <= status <= 599 else "unknown"


def client_csrf(client: Browser) -> str:
    response = client.request("GET", "/acceptance/csrf")
    require_status(response, 200, "client csrf")
    token = json.loads(str(response["body"])).get("csrf_token")
    if not isinstance(token, str) or not token:
        raise AssertionError("client csrf endpoint omitted token")
    return token


def assert_client_csrf_protection(client: Browser) -> None:
    rejected = client.request("POST", "/acceptance/dpop/resource/challenge")
    require_status(rejected, 403, "client CSRF rejection")
    print("client CSRF protection enforced")


def wait_dpop_resource_restart_ready(client: Browser) -> None:
    deadline = time.monotonic() + 10

    while time.monotonic() < deadline:
        response = client.request(
            "POST", "/acceptance/dpop/resource/restart-ready", {"_csrf_token": client_csrf(client)}
        )

        try:
            receipt = json.loads(str(response["body"]))
        except json.JSONDecodeError:
            receipt = {}

        if response["status"] == 200 and receipt == {"status": 200, "restart_ready": True}:
            print("dpop provider restart ready")
            return

        # A just-spawned provider can publish discovery before its protected
        # resource pipeline has accepted its first request. Retry only that
        # fixed, safe startup condition; all other contracts remain strict.
        if (
            response["status"] == 400
            and isinstance(receipt, dict)
            and safe_dpop_failure_stage(receipt) == "restart_ready"
        ):
            time.sleep(0.1)
            continue

        raise AssertionError(
            "dpop provider restart readiness failed"
            f" (stage: {safe_dpop_failure_stage(receipt if isinstance(receipt, dict) else {})},"
            f" provider_status: {safe_dpop_provider_status(receipt if isinstance(receipt, dict) else {})})"
        )

    raise AssertionError("dpop provider restart readiness timed out")


def run_dpop(
    provider_child: Path,
    provider_environment: dict[str, str],
    provider_process: subprocess.Popen[bytes] | None,
    run_root: Path,
    track_provider_process,
) -> subprocess.Popen[bytes]:
    client = Browser(CLIENT_ORIGIN)
    provider = Browser(PROVIDER_ORIGIN)
    assert_client_csrf_protection(client)
    start = client.request("GET", "/oauth/dpop/start")
    require_status(start, 302, "dpop client start")
    authorization_location = redirect(start, "dpop client start")
    if parse_qs(urlparse(authorization_location).query).get("client_id") != ["clean-room-dpop"]:
        raise AssertionError("dpop start did not select the fixed DPoP client")

    callback_result, _callback = browser_authorize_dpop(client, provider, authorization_location)
    safe = receipt(client)
    if callback_result["status"] != 200:
        stage = safe.get("failed_stage") or str(callback_result["body"]).split(":")[-1].strip()
        raise AssertionError(f"dpop client callback failed at {stage}")
    if not (
        safe.get("profile") == "dpop"
        and safe.get("complete") is True
        and safe.get("token_nonce_retry") is True
        and safe.get("userinfo_nonce_retry") is True
        and isinstance(safe.get("dpop_session"), str)
        and isinstance(safe.get("dpop_jkt"), str)
    ):
        raise AssertionError("dpop callback did not produce the expected safe session receipt")
    print("dpop token nonce retry complete")
    print("dpop userinfo nonce retry complete")

    challenge = safe_dpop_operation(client, "/acceptance/dpop/resource/challenge", "dpop resource challenge")
    if challenge != {"status": 401, "challenge": "use_dpop_nonce", "dpop_nonce_present": True}:
        raise AssertionError("dpop resource challenge did not expose the documented safe receipt")
    print("dpop resource nonce challenge received")

    retry = safe_dpop_operation(client, "/acceptance/dpop/resource/retry", "dpop resource retry")
    if retry != {"status": 200, "confirmation_jkt_matches": True}:
        raise AssertionError("dpop resource retry did not prove semantic confirmation binding")
    print("dpop resource nonce retry complete")

    replay = safe_dpop_operation(client, "/acceptance/dpop/resource/replay", "dpop resource replay")
    if replay.get("challenge") != "invalid_token" or replay.get("status") not in (400, 401):
        raise AssertionError("dpop exact proof replay was not rejected")
    print("dpop exact proof replay rejected")

    stop_process(provider_process)
    provider_process = start_process(provider_child, provider_environment, run_root / "provider-restart.log")
    # Publish the replacement before readiness or replay assertions.  If either
    # fails, the outer teardown still owns this live process and can release the
    # database deterministically.
    track_provider_process(provider_process)
    wait_ready(PROVIDER_ORIGIN)
    wait_dpop_resource_restart_ready(client)

    durable_replay = safe_dpop_operation(client, "/acceptance/dpop/resource/replay", "durable dpop resource replay")
    if durable_replay.get("challenge") != "invalid_token" or durable_replay.get("status") not in (400, 401):
        raise AssertionError(
            "dpop replay was accepted after provider restart "
            f"(stage: {safe_dpop_failure_stage(durable_replay)})"
        )
    print("dpop replay rejected after provider restart")
    return provider_process


def browser_authorize_dpop(client: Browser, provider: Browser, authorization_location: str) -> tuple[dict[str, object], str]:
    authorize = provider.request("GET", authorization_location)
    require_status(authorize, 302, "dpop provider authorize")
    login = provider.request("GET", redirect(authorize, "dpop provider authorize"))
    require_status(login, 200, "dpop provider login")
    resumed = redirect(provider.request("POST", "/login", {
        "_csrf_token": csrf(login["body"]),
        "return_to": re.search(r'name="return_to" value="([^"]*)"', str(login["body"])).group(1),
        "interaction_id": re.search(r'name="interaction_id" value="([^"]*)"', str(login["body"])).group(1),
        "account_id": "clean-room-user",
    }), "dpop provider login")
    interaction_id = urlparse(resumed).path.rsplit("/", 1)[-1]
    consent = provider.request("GET", redirect(provider.request("GET", resumed), "dpop provider interaction"))
    require_status(consent, 200, "dpop provider consent")
    approved = provider.request("POST", f"/lockspire/interactions/{interaction_id}/complete", {"decision": "approve", "remember": "true"})
    require_status(approved, 302, "dpop provider consent approval")
    callback = redirect(approved, "dpop provider consent approval")
    return client.request("GET", callback), callback


def main(argv: list[str]) -> int:
    global ACTIVE_REDACTOR
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", action="append", choices=("happy_path", "boundary", "lifecycle", "negative", "dpop"))
    parser.add_argument("--hold-after-ready", type=float, default=0.0, help=argparse.SUPPRESS)
    parser.add_argument("--verify-concurrent-origins", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--verify-signal-cleanup", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--verify-run-root-ownership", action="store_true", help=argparse.SUPPRESS)
    sources = parser.add_mutually_exclusive_group()
    sources.add_argument("--package-tar", type=Path)
    sources.add_argument("--hex-version")
    parser.add_argument("--package-sha256")
    args = parser.parse_args(argv)
    if args.verify_concurrent_origins:
        return verify_concurrent_real_journeys()
    if args.verify_signal_cleanup:
        return verify_signal_cleanup()
    if args.verify_run_root_ownership:
        return verify_run_root_ownership()
    if not args.only:
        parser.error("at least one --only journey group is required")
    signal.signal(signal.SIGINT, interruption_handler)
    signal.signal(signal.SIGTERM, interruption_handler)
    redactor = Redactor(SentinelSet.for_run())
    ACTIVE_REDACTOR = redactor
    provider_process = client_process = None
    provider_child = client_child = None
    provider_environment = client_environment = None
    with tempfile.TemporaryDirectory(prefix="lockspire-clean-room-journey-") as temporary:
        run_root = Path(temporary)
        run_root_owner = claim_run_root(run_root)
        runner_tmpdir = run_root / "mix-tmp"
        runner_tmpdir.mkdir(mode=0o700)
        previous_tmpdir = os.environ.get("TMPDIR")
        # Mix Sync lock files live below TMPDIR.  Every acceptance run gets an
        # owned directory so a concurrent Mix process cannot race its lock-file
        # replacement or cleanup against this run.
        os.environ["TMPDIR"] = str(runner_tmpdir)
        provider_port, client_port = configure_origins()
        provider_database = clean_room_database_url("provider")
        client_database = clean_room_database_url("client")

        def track_provider_process(process: subprocess.Popen[bytes]) -> None:
            nonlocal provider_process
            provider_process = process

        try:
            assert_owned_run_root(run_root, run_root_owner)
            probe_environment()
            assert_redaction_guard(redactor)
            selected_source = package_source(args.package_tar, args.hex_version, args.package_sha256)
            package_root, _package_inventory, package_identity = prepare_package(run_root, selected_source)
            print(
                "package provenance verified "
                f"({package_identity.kind} lockspire-{package_identity.version} sha256:{package_identity.sha256})"
            )
            handoff = run_root / "handoff"
            provider_child = prepare_provider(
                run_root,
                provider_database,
                package_root=package_root,
                port=provider_port,
                cache_root=dependency_cache_root(run_root),
            )
            provider_environment = locked_environment(provider_child, "provider_host", dependency_cache_root(run_root))
            provider_environment.update({"DATABASE_URL": provider_database, "PORT": str(provider_port), "LOCKSPIRE_ISSUER": PROVIDER_ORIGIN + "/lockspire", "CLEAN_ROOM_PROVIDER_ORIGIN": PROVIDER_ORIGIN, "CLEAN_ROOM_CLIENT_ORIGIN": CLIENT_ORIGIN, "SECRET_KEY_BASE": "clean-room-provider-secret-key-base-0123456789-abcdefghijklmnopqrstuvwxyz-0123456789"})
            run_child_command(provider_child, provider_environment, "ecto.create")
            run_child_command(
                provider_child,
                provider_environment,
                "ecto.migrate",
                "--migrations-path",
                "priv/repo/migrations",
            )
            run_child_command(provider_child, provider_environment, "compile", "--warnings-as-errors")
            run_child_command(provider_child, provider_environment, "lockspire.verify")
            run_child_command(provider_child, provider_environment, "run", "-e", f'CleanRoomProvider.Bootstrap.provision!("{handoff}")')
            register_handoff_secrets(handoff)
            assert_redaction_guard(redactor, (handoff / "bearer-client.secret").read_text().strip())
            client_child, client_environment = prepare_client(
                run_root, client_database, handoff, client_port, package_root
            )
            provider_process = start_process(provider_child, provider_environment, run_root / "provider.log")
            client_process = start_process(client_child, client_environment, run_root / "client.log")
            wait_ready(PROVIDER_ORIGIN)
            wait_ready(CLIENT_ORIGIN)
            print("readiness complete")
            if args.hold_after_ready:
                time.sleep(args.hold_after_ready)
            if "happy_path" in args.only:
                run_happy()
            if "boundary" in args.only:
                run_boundary()
            if "lifecycle" in args.only:
                run_lifecycle(handoff)
            if "negative" in args.only:
                run_negative(handoff)
            if "dpop" in args.only:
                assert_owned_run_root(run_root, run_root_owner)
                provider_process = run_dpop(
                    provider_child,
                    provider_environment,
                    provider_process,
                    run_root,
                    track_provider_process,
                )
            scan_evidence(run_root, redactor)
            return 0
        except JourneyInterrupted:
            print("clean-room journey interrupted", file=sys.stderr)
            return 130
        except (AssertionError, PackageInputError, OSError, subprocess.SubprocessError, json.JSONDecodeError) as error:
            print(redactor.text(error), file=sys.stderr)
            return 1
        finally:
            stop_process(client_process)
            stop_process(provider_process)
            try:
                assert_owned_run_root(run_root, run_root_owner)
            except AssertionError as error:
                print(redactor.text(error), file=sys.stderr)
            else:
                if client_child is not None and client_environment is not None:
                    drop_child_database(client_child, client_environment, "client")
                if provider_child is not None and provider_environment is not None:
                    drop_child_database(provider_child, provider_environment, "provider")
            if previous_tmpdir is None:
                os.environ.pop("TMPDIR", None)
            else:
                os.environ["TMPDIR"] = previous_tmpdir
            print("cleanup complete")


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
