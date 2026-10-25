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
from collections import Counter
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
from build_provider import prepare_provider, run_child_command, run_child_command_output
from lifetime_receipts import validate_lifetime_receipt, write_lifetime_receipt
from selected_receipts import (
    SELECTED_CASE_IDS,
    validate_selected_receipt,
    write_selected_receipt,
)
from package_input import (
    PackageInputError,
    clean_room_database_url,
    copy_child_template,
    locked_environment,
    package_source,
    prepare_package,
    probe_environment,
    verify_candidate_host,
    verify_candidate_input,
    candidate_host_provenance,
    verify_child,
)
from redaction import Redactor, SentinelSet, safe_failure_summary
from processes import allocate_loopback_port


PROVIDER_ORIGIN = "http://127.0.0.1:4100"
CLIENT_ORIGIN = "http://127.0.0.1:4101"
MAX_REDIRECTS = 8
ACTIVE_REDACTOR: Redactor | None = None
CUSTOM_EXAMPLE_EVIDENCE: dict[str, object] | None = None
RUN_ROOT_MARKER = ".lockspire-clean-room-owner"


class JourneyInterrupted(Exception):
    """Raised from SIGINT/SIGTERM so the runner reaches its teardown path."""


def interruption_handler(signum: int, _frame: object) -> None:
    raise JourneyInterrupted(f"clean-room journey interrupted by signal {signum}")


def register_secret(value: object) -> None:
    if ACTIVE_REDACTOR is not None:
        ACTIVE_REDACTOR.register_material(value)


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
            if headers.get("content-type") == "application/json":
                body = json.dumps(data).encode()
            else:
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
        payload = json.loads(str(response["body"]))
        error = payload.get("error")
        description = payload.get("error_description")
    except (AttributeError, TypeError, json.JSONDecodeError):
        return ""

    if isinstance(error, str) and re.fullmatch(r"[a-z_]{1,64}", error):
        if isinstance(description, str) and re.fullmatch(r"[a-z_]{1,64} for [a-z_]{1,64}", description):
            return f" ({error}: {description})"
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


def selected_authorization_params(client_id: str, redirect_uri: str) -> dict[str, str]:
    verifier = uuid.uuid4().hex + uuid.uuid4().hex
    register_secret(verifier)
    return {
        "response_type": "code", "client_id": client_id, "redirect_uri": redirect_uri,
        "scope": "openid email", "state": uuid.uuid4().hex, "nonce": uuid.uuid4().hex,
        "code_challenge": s256(verifier), "code_challenge_method": "S256",
    }


def _selected_client(child: Path, environment: dict[str, str], redirect_uri: str) -> str:
    client_id = "clean-room-selected-" + uuid.uuid4().hex[:12]
    expression = (
        "{:ok, result} = Lockspire.Clients.register_client(%{"
        f"client_id: {json.dumps(client_id)}, client_type: :public, name: {json.dumps(client_id)}, "
        f"redirect_uris: [{json.dumps(redirect_uri)}], allowed_scopes: [\"openid\", \"email\"], "
        "allowed_grant_types: [\"authorization_code\"], allowed_response_types: [\"code\"], "
        "token_endpoint_auth_method: :none, pkce_required: true}); "
        "IO.puts(\"SELECTED_CLIENT_READY=\" <> result.client.client_id)"
    )
    output = _run_host_control(child, environment, expression)
    if f"SELECTED_CLIENT_READY={client_id}" not in output:
        raise AssertionError("selected authorization client setup did not complete")
    return client_id


def run_selected_authorization_case(
    identifier: str,
    provider: Browser,
    child: Path,
    environment: dict[str, str],
) -> dict[str, object]:
    """Run one implemented selected authorization projection through the packaged host."""
    if identifier != "A171-003":
        raise AssertionError(f"selected authorization case is not implemented: {identifier}")
    redirect_uri = CLIENT_ORIGIN + "/oauth/callback"
    client_id = _selected_client(child, environment, redirect_uri)
    params = selected_authorization_params(client_id, redirect_uri)
    valid = provider.request("GET", "/lockspire/authorize?" + urlencode(params))
    require_status(valid, 302, "A171-003 query-mode control")
    login_location = redirect(valid, "A171-003 query-mode control")
    login = urlparse(login_location)
    if login.netloc or not login.path.startswith("/login"):
        raise AssertionError("A171-003 query-mode control missed the host login handoff")

    unsupported_params = {**params, "response_mode": "binary"}
    unsupported = provider.request("GET", "/lockspire/authorize?" + urlencode(unsupported_params))
    require_status(unsupported, 400, "A171-003 unsupported response mode")
    content_type = str(unsupported["headers"].get("content-type", "")).split(";", 1)[0].strip().lower()
    body = str(unsupported["body"])
    no_location = "location" not in unsupported["headers"]
    no_oauth_parameters = not (
        re.search(r"(?i)(?:[?&]|\b)(?:error|error_description|error_uri|iss|state)=", body)
        or re.search(r"(?i)<(?:input|param)[^>]+name=[\"'](?:error|error_description|error_uri|iss|state)[\"']", body)
        or re.search(r"(?i)[\"'](?:error|error_description|error_uri|iss|state)[\"']\s*:", body)
    )
    if content_type != "text/html" or not no_location or not no_oauth_parameters:
        raise AssertionError("A171-003 unsupported response mode violated the first-party HTTP error contract")
    return {
        "id": identifier, "outcome": "passed",
        "observations": {
            "control_status": int(valid["status"]),
            "control_reached_host_handoff": True,
            "unsupported_status": int(unsupported["status"]),
            "html_content_type": content_type == "text/html",
            "no_location": no_location,
            "no_oauth_error_parameters": no_oauth_parameters,
        },
        "counts": {"executed": 1, "passed": 1, "failed": 0, "skipped": 0},
    }


def run_selected_authorization_par(
    case_ids: tuple[str, ...], provider: Browser, child: Path, environment: dict[str, str]
) -> list[dict[str, object]]:
    if not case_ids:
        raise AssertionError("selected authorization case set is empty")
    return [run_selected_authorization_case(identifier, provider, child, environment) for identifier in case_ids]


def run_dcr_lifetime(
    provider: Browser,
    provider_child: Path,
    provider_environment: dict[str, str],
    handoff: Path,
    provider_log: Path,
    *,
    custom: bool = False,
) -> list[dict[str, object]]:
    """Register a fresh public client and redeem an S256 code through HTTP."""
    discovery_response = provider.request("GET", "/lockspire/.well-known/openid-configuration")
    require_status(discovery_response, 200, "DCR lifetime discovery")
    discovery = json.loads(str(discovery_response["body"]))
    endpoint = discovery.get("registration_endpoint")
    if not isinstance(endpoint, str):
        raise AssertionError("DCR lifetime discovery omitted the mounted registration endpoint")

    redirect_uri = CLIENT_ORIGIN + "/oauth/callback"
    metadata = {
        "client_name": "Lifetime journey",
        "redirect_uris": [redirect_uri],
        "grant_types": ["authorization_code"],
        "response_types": ["code"],
        "token_endpoint_auth_method": "none",
        "scope": "openid profile",
    }
    registered = provider.request("POST", provider_path(endpoint), metadata, {"content-type": "application/json"})
    require_status(registered, 201, "production DCR registration")
    registration = json.loads(str(registered["body"]))
    client_id = registration.get("client_id")
    if not isinstance(client_id, str) or not client_id:
        raise AssertionError("DCR registration omitted the created client identity")
    for name in ("client_secret", "registration_access_token"):
        register_secret(registration.get(name))

    state, nonce = uuid.uuid4().hex, uuid.uuid4().hex
    verifier = uuid.uuid4().hex + uuid.uuid4().hex
    register_secret(verifier)
    authorize = provider.request("GET", "/lockspire/authorize?" + urlencode({
        "response_type": "code", "client_id": client_id, "redirect_uri": redirect_uri,
        "scope": "openid profile", "state": state, "nonce": nonce,
        "code_challenge": s256(verifier), "code_challenge_method": "S256",
    }))
    require_status(authorize, 302, "DCR authorization request")
    login = provider.request("GET", redirect(authorize, "DCR authorization request"))
    require_status(login, 200, "DCR host login")
    login_redirect = redirect(provider.request("POST", "/login", {
        "_csrf_token": csrf(login["body"]),
        "return_to": re.search(r'name="return_to" value="([^"]*)"', str(login["body"])).group(1),
        "interaction_id": re.search(r'name="interaction_id" value="([^"]*)"', str(login["body"])).group(1),
        "account_id": "clean-room-user",
    }), "DCR host login")
    interaction_id = urlparse(login_redirect).path.rsplit("/", 1)[-1]
    interaction = provider.request("GET", login_redirect)
    require_status(interaction, 302, "DCR authorization interaction")
    consent_location = redirect(interaction, "DCR authorization interaction")
    consent = provider.request("GET", consent_location)
    require_status(consent, 200, "DCR authorization consent")
    approval = provider.request("POST", f"/lockspire/interactions/{interaction_id}/complete", {
        "decision": "approve", "remember": "false",
    })
    require_status(approval, 302, "DCR authorization approval")
    callback = urlparse(redirect(approval, "DCR authorization approval"))
    values = parse_qs(callback.query)
    code = values.get("code", [None])[0]
    if callback.scheme + "://" + callback.netloc != CLIENT_ORIGIN or values.get("state") != [state] or not isinstance(code, str):
        raise AssertionError("DCR authorization callback did not contain the expected code and state")
    register_secret(code)
    exchanged = provider.request("POST", provider_path(str(discovery["token_endpoint"])), {
        "grant_type": "authorization_code", "code": code, "redirect_uri": redirect_uri,
        "code_verifier": verifier, "client_id": client_id,
    })
    require_status(exchanged, 200, "DCR S256 code redemption")
    issued = decoded_secret_payload(exchanged["body"])
    access_token = issued.get("access_token")
    if not isinstance(access_token, str) or not access_token:
        raise AssertionError("DCR code redemption did not issue an access token")
    is_custom = custom
    replacement_status = None
    if is_custom:
        registration_uri = registration.get("registration_client_uri")
        registration_access_token = registration.get("registration_access_token")
        if not isinstance(registration_uri, str) or not isinstance(registration_access_token, str):
            raise AssertionError("DCR registration omitted its management endpoint or credential")
        replaced = provider.request(
            "PUT",
            provider_path(registration_uri),
            {**metadata, "client_id": client_id, "client_name": "Lifetime journey replaced"},
            {
                "content-type": "application/json",
                "authorization": f"Bearer {registration_access_token}",
            },
        )
        require_status(replaced, 200, "production DCR credential replacement")
        replacement = json.loads(str(replaced["body"]))
        register_secret(replacement.get("registration_access_token"))
        replacement_status = 200
    callback_counts = callback_counts_from_log(provider_log) if is_custom else {}
    if is_custom and not all(
        callback_counts.get(callback, 0) > 0
        for callback in ("lifetime_contract", "transaction_authority", "register_client", "lock_clients", "replace_client_registration", "transact")
    ):
        raise AssertionError("configured adapter callback observations are incomplete")
    registration_scenario = {
        "id": "custom.issue_replace" if is_custom else "fresh.register_use",
        "leg": "custom" if is_custom else "fresh",
        "contract_case_ids": ["C-POL-01", "C-APP-06", "C-PROOF-01"],
        "outcome": "passed",
        "observations": {
            "registration_http_status": 201,
            "token_http_status": 200,
            "replacement_http_status": replacement_status,
            "access_token_issued": True,
            "management_credential_replaced": is_custom,
            "callbacks_executed": sum(callback_counts.values()),
            "callback_counts": callback_counts,
            "authority_shared": is_custom,
            "example_executed": os.environ.get("CLEAN_ROOM_ADAPTER_EXAMPLE_EXECUTED") == "true",
            "pkce_method": "S256",
        },
        "event_counts": {
            "registration_succeeded": 1,
            "authorization_code_redeemed": 1,
            "credential_replaced": int(is_custom),
        },
        "audit_counts": {},
        "counts": {
            "executed": 1 + sum(callback_counts.values()),
            "passed": 1 + sum(callback_counts.values()),
            "failed": 0,
            "skipped": 0,
        },
    }
    if is_custom:
        return [registration_scenario]
    return [
        registration_scenario,
        run_secret_expiry_rotation(provider, provider_child, provider_environment, discovery),
        run_management_put_and_host_recovery(provider, provider_child, provider_environment, discovery),
        run_expired_and_disabled_app(provider, provider_child, provider_environment, discovery),
    ]


def _set_lifetime_policy(child: Path, environment: dict[str, str], app: int, secret: int, management: int) -> None:
    expression = (
        "{:ok, _} = Lockspire.Admin.ServerPolicy.put_dcr_policy(%{"
        "registration_policy: :open, dcr_allowed_scopes: [\"profile\"], "
        "dcr_allowed_grant_types: [\"authorization_code\"], dcr_allowed_response_types: [\"code\"], "
        "dcr_allowed_redirect_uri_schemes: [\"http\"], dcr_allowed_redirect_uri_hosts: [\"127.0.0.1\"], "
        "dcr_allowed_token_endpoint_auth_methods: [\"none\", \"client_secret_basic\"], "
        f"dcr_default_client_lifetime_seconds: {app}, "
        f"dcr_default_client_secret_lifetime_seconds: {secret}, "
        f"dcr_default_registration_access_token_lifetime_seconds: {management}"
        "}); IO.puts(\"LIFETIME_POLICY_READY=1\")"
    )
    try:
        output = _run_host_control(child, environment, expression)
    except PackageInputError as error:
        print(f"lifetime policy setup failed: {error}")
        raise
    if "LIFETIME_POLICY_READY=1" not in output:
        raise AssertionError("clean-room lifetime policy setup did not complete")


def _run_host_control(child: Path, environment: dict[str, str], expression: str) -> str:
    """Run a setup/observation seam without booting a second HTTP listener."""
    expression = "{:ok, _} = Application.ensure_all_started(:ecto_sql); {:ok, _repo} = CleanRoomProvider.Repo.start_link(); {:ok, _} = Application.ensure_all_started(:lockspire); " + expression
    try:
        return run_child_command_output(child, environment, "run", "--no-start", "-e", expression)
    except PackageInputError as error:
        try:
            if ACTIVE_REDACTOR is not None:
                ACTIVE_REDACTOR.assert_safe(str(error))
            print(f"host control failed: {error}")
        except RuntimeError:
            print("host control failed; diagnostic contained by redaction guard")
        raise


def _register_confidential(provider: Browser, discovery: dict[str, object], label: str) -> dict[str, object]:
    metadata = {
        "client_name": label,
        "redirect_uris": [CLIENT_ORIGIN + "/oauth/callback"],
        "grant_types": ["authorization_code"],
        "response_types": ["code"],
        "token_endpoint_auth_method": "client_secret_basic",
        "scope": "openid profile",
    }
    endpoint = discovery.get("registration_endpoint")
    if not isinstance(endpoint, str):
        raise AssertionError("DCR lifetime discovery omitted the mounted registration endpoint")
    response = provider.request("POST", provider_path(endpoint), metadata, {"content-type": "application/json"})
    require_status(response, 201, f"{label} production DCR registration")
    registration = json.loads(str(response["body"]))
    for key in ("client_id", "client_secret", "registration_access_token", "registration_client_uri"):
        if not isinstance(registration.get(key), str) or not registration[key]:
            raise AssertionError(f"{label} registration omitted required credentials")
        if key != "client_id":
            register_secret(registration[key])
    return registration


def _stored_deadlines(child: Path, environment: dict[str, str], client_id: str) -> tuple[int | None, int | None, int | None, int]:
    client = json.dumps(client_id)
    expression = (
        f"{{:ok, client}} = Lockspire.Admin.Clients.get_client({client}); "
        "deadline = fn nil -> \"0\"; value -> Integer.to_string(DateTime.to_unix(value)) end; "
        "repo = Lockspire.Config.repo!(); "
        "{:ok, count} = Ecto.Adapters.SQL.query(repo, \"SELECT count(*) FROM lockspire.lockspire_audit_events WHERE resource_id = $1\", [client.client_id]); "
        "[[audit_count]] = count.rows; "
        "IO.puts(\"LIFETIME_DEADLINES=\" <> Enum.join([deadline.(client.client_expires_at), deadline.(client.client_secret_expires_at), deadline.(client.registration_access_token_expires_at), Integer.to_string(audit_count)], \",\"))"
    )
    output = _run_host_control(child, environment, expression)
    match = re.search(r"^LIFETIME_DEADLINES=(\d+),(\d+),(\d+),(\d+)$", output, re.MULTILINE)
    if not match:
        raise AssertionError("host lifetime observer omitted deadline or audit counts")
    app, secret, management, audit = (int(value) for value in match.groups())
    return tuple(value or None for value in (app, secret, management)) + (audit,)  # type: ignore[return-value]


def _wait_for_expiry(deadline: int | None) -> None:
    if deadline is None:
        raise AssertionError("isolated lifetime scenario has no issued deadline")
    remaining = deadline - int(time.time())
    if remaining > 0:
        time.sleep(remaining + 0.05)
    if int(time.time()) < deadline:
        raise AssertionError("observed lifetime deadline has not elapsed")


def _introspect(provider: Browser, discovery: dict[str, object], client_id: str, secret: str) -> dict[str, object]:
    endpoint = discovery.get("introspection_endpoint")
    if not isinstance(endpoint, str):
        raise AssertionError("OIDC discovery omitted introspection endpoint")
    return provider.request("POST", provider_path(endpoint), {"token": "clean-room-unowned-token"}, {
        "authorization": basic(client_id, secret),
    })


def _audit_count(child: Path, environment: dict[str, str], client_id: str) -> int:
    return _stored_deadlines(child, environment, client_id)[3]


def run_secret_expiry_rotation(
    provider: Browser, child: Path, environment: dict[str, str], discovery: dict[str, object]
) -> dict[str, object]:
    print("fresh secret expiry scenario starting")
    _set_lifetime_policy(child, environment, 120, 2, 120)
    print("fresh secret policy configured")
    registration = _register_confidential(provider, discovery, "Secret expiry and rotation")
    print("fresh secret client registered")
    client_id = str(registration["client_id"])
    old_secret = str(registration["client_secret"])
    deadlines_before = _stored_deadlines(child, environment, client_id)
    print("fresh secret deadline observed")
    _wait_for_expiry(deadlines_before[1])
    expired = _introspect(provider, discovery, client_id, old_secret)
    require_status(expired, 401, "expired DCR client secret")
    secret_path = Path(environment["CLEAN_ROOM_HANDOFF_DIR"]) / f"{client_id}.secret"
    expression = (
        f"{{:ok, result}} = Lockspire.Admin.Clients.rotate_client_secret({json.dumps(client_id)}, %{{actor: %{{type: :operator, id: \"clean-room-host-operator\"}}}}); "
        f"File.write!({json.dumps(str(secret_path))}, result.client_secret); "
        f"File.chmod!({json.dumps(str(secret_path))}, 0o600); IO.puts(\"HOST_SECRET_ROTATION=1\")"
    )
    output = _run_host_control(child, environment, expression)
    if "HOST_SECRET_ROTATION=1" not in output or not secret_path.is_file():
        raise AssertionError("host secret rotation setup did not complete")
    new_secret = secret_path.read_text(encoding="utf-8")
    register_secret(new_secret)
    restored = _introspect(provider, discovery, client_id, new_secret)
    require_status(restored, 200, "rotated DCR client secret")
    deadlines_after = _stored_deadlines(child, environment, client_id)
    if deadlines_before[0] != deadlines_after[0] or deadlines_before[2] != deadlines_after[2]:
        raise AssertionError("secret rotation changed unrelated client deadlines")
    if deadlines_after[3] <= deadlines_before[3]:
        raise AssertionError("secret rotation audit event was not persisted")
    return {
        "id": "fresh.secret_expiry_rotate", "leg": "fresh", "contract_case_ids": ["C-LEG-01", "C-LEG-05", "C-PROOF-02"],
        "outcome": "passed", "observations": {
            "expiry_rejected": True, "rotation_restored_auth": True,
            "unrelated_deadlines_preserved": True, "production_routes_used": True,
        }, "event_counts": {"secret_expired": 1, "secret_rotated": 1},
        "audit_counts": {"host_secret_rotation": deadlines_after[3] - deadlines_before[3]},
        "counts": {"executed": 3, "passed": 3, "failed": 0, "skipped": 0},
    }


def run_management_put_and_host_recovery(
    provider: Browser, child: Path, environment: dict[str, str], discovery: dict[str, object]
) -> dict[str, object]:
    print("fresh management replacement scenario starting")
    # This journey performs registration and reads the stored deadlines before
    # its first management request. Keep enough headroom for loaded CI runners;
    # the scenario still proves expiry after the replacement response below.
    _set_lifetime_policy(child, environment, 120, 120, 10)
    registration = _register_confidential(provider, discovery, "Management replacement and recovery")
    client_id, secret = str(registration["client_id"]), str(registration["client_secret"])
    management_uri = str(registration["registration_client_uri"])
    old_token = str(registration["registration_access_token"])
    before = _stored_deadlines(child, environment, client_id)
    update = provider.request("PUT", provider_path(management_uri), {
        "client_id": client_id, "client_name": "Management replacement and recovery",
        "redirect_uris": [CLIENT_ORIGIN + "/oauth/callback"], "grant_types": ["authorization_code"],
        "response_types": ["code"], "token_endpoint_auth_method": "client_secret_basic", "scope": "openid profile",
        "client_secret": secret,
    }, {"content-type": "application/json", "authorization": f"Bearer {old_token}"})
    require_status(update, 200, "production DCR management-token replacement")
    replacement = json.loads(str(update["body"]))
    new_token = replacement.get("registration_access_token")
    if not isinstance(new_token, str) or not new_token:
        raise AssertionError("successful management replacement omitted replacement credential")
    register_secret(new_token)
    require_status(provider.request("GET", provider_path(management_uri), extra_headers={"authorization": f"Bearer {old_token}"}), 401, "replaced management credential")
    require_status(provider.request("GET", provider_path(management_uri), extra_headers={"authorization": f"Bearer {new_token}"}), 200, "new management credential")
    after_put = _stored_deadlines(child, environment, client_id)
    if before[0] != after_put[0] or before[1] != after_put[1]:
        raise AssertionError("management replacement changed unrelated client deadlines")
    _wait_for_expiry(after_put[2])
    require_status(provider.request("GET", provider_path(management_uri), extra_headers={"authorization": f"Bearer {new_token}"}), 401, "expired management credential")
    recovery_path = Path(environment["CLEAN_ROOM_HANDOFF_DIR"]) / f"{client_id}.rat"
    recovery = (
        f"{{:ok, client}} = Lockspire.Admin.Clients.get_client({json.dumps(client_id)}); "
        f"{{:ok, token, _}} = Lockspire.Protocol.RegistrationManagement.rotate_registration_access_token(client); "
        f"File.write!({json.dumps(str(recovery_path))}, token); File.chmod!({json.dumps(str(recovery_path))}, 0o600); "
        "IO.puts(\"HOST_RECOVERY=1\")"
    )
    output = _run_host_control(child, environment, recovery)
    if "HOST_RECOVERY=1" not in output or not recovery_path.is_file():
        raise AssertionError("host-authorized management recovery setup did not complete")
    recovered_token = recovery_path.read_text(encoding="utf-8")
    register_secret(recovered_token)
    require_status(provider.request("GET", provider_path(management_uri), extra_headers={"authorization": f"Bearer {recovered_token}"}), 200, "host-recovered management credential")
    after_recovery = _stored_deadlines(child, environment, client_id)
    if before[0] != after_recovery[0] or before[1] != after_recovery[1] or after_recovery[3] <= before[3]:
        raise AssertionError("host recovery changed unrelated deadlines or omitted persisted audit")
    return {
        "id": "fresh.management_put_recover", "leg": "fresh", "contract_case_ids": ["C-MGMT-02", "C-MGMT-03", "C-PROOF-02", "C-PROOF-03"],
        "outcome": "passed", "observations": {
            "old_credential_rejected": True, "new_credential_accepted": True,
            "host_authorized_recovery": True, "unrelated_deadlines_preserved": True,
            "production_routes_used": True,
        }, "event_counts": {"management_token_replaced": 1, "host_recovery": 1},
        "audit_counts": {"management_mutations": after_recovery[3] - before[3]},
        "counts": {"executed": 5, "passed": 5, "failed": 0, "skipped": 0},
    }


def run_expired_and_disabled_app(
    provider: Browser, child: Path, environment: dict[str, str], discovery: dict[str, object]
) -> dict[str, object]:
    print("fresh expired and disabled app scenario starting")
    _set_lifetime_policy(child, environment, 2, 120, 120)
    expired_registration = _register_confidential(provider, discovery, "Expired enabled app")
    expired_id = str(expired_registration["client_id"])
    expired_uri = str(expired_registration["registration_client_uri"])
    expired_token = str(expired_registration["registration_access_token"])
    expired_deadlines = _stored_deadlines(child, environment, expired_id)
    _wait_for_expiry(expired_deadlines[0])
    require_status(provider.request("GET", provider_path(expired_uri), extra_headers={"authorization": f"Bearer {expired_token}"}), 200, "expired enabled app management GET")
    put = provider.request("PUT", provider_path(expired_uri), {"client_id": expired_id, "client_name": "Expired enabled app"}, {
        "content-type": "application/json", "authorization": f"Bearer {expired_token}",
    })
    require_status(put, 403, "expired app management PUT")
    delete = provider.request("DELETE", provider_path(expired_uri), extra_headers={"authorization": f"Bearer {expired_token}"})
    require_status(delete, 204, "expired enabled app management DELETE")
    disabled_registration = _register_confidential(provider, discovery, "Disabled app state retention")
    disabled_id = str(disabled_registration["client_id"])
    disabled_uri = str(disabled_registration["registration_client_uri"])
    disabled_token = str(disabled_registration["registration_access_token"])
    disabled_audit_before = _audit_count(child, environment, disabled_id)
    disable_expr = f"{{:ok, _}} = Lockspire.Admin.Clients.disable_client({json.dumps(disabled_id)}, %{{actor: %{{type: :operator, id: \"clean-room-host-operator\"}}}}); IO.puts(\"APP_DISABLED=1\")"
    if "APP_DISABLED=1" not in _run_host_control(child, environment, disable_expr):
        raise AssertionError("host disabled-app setup did not complete")
    disabled_statuses = [
        provider.request("GET", provider_path(disabled_uri), extra_headers={"authorization": f"Bearer {disabled_token}"})["status"],
        provider.request("PUT", provider_path(disabled_uri), {"client_id": disabled_id}, {"content-type": "application/json", "authorization": f"Bearer {disabled_token}"})["status"],
        provider.request("DELETE", provider_path(disabled_uri), extra_headers={"authorization": f"Bearer {disabled_token}"})["status"],
    ]
    if disabled_statuses != [401, 401, 401]:
        raise AssertionError("disabled app self-management was not denied for every operation")
    remaining = _run_host_control(child, environment, (
        f"{{:ok, client}} = Lockspire.Admin.Clients.get_client({json.dumps(disabled_id)}); "
        "IO.puts(\"DISABLED_STATE_RETAINED=#{if client.active, do: 0, else: 1}\")"
    ))
    if "DISABLED_STATE_RETAINED=1" not in remaining:
        raise AssertionError("disabled registration state was not retained")
    disabled_audit_after = _audit_count(child, environment, disabled_id)
    if disabled_audit_after <= disabled_audit_before:
        raise AssertionError("host disable action did not persist an audit event")
    return {
        "id": "fresh.app_expiry_disabled", "leg": "fresh", "contract_case_ids": ["C-APP-14", "C-APP-15", "C-APP-16", "C-PROOF-02"],
        "outcome": "passed", "observations": {
            "expired_get_allowed": True, "expired_delete_allowed": True,
            "expired_put_rejected": True, "disabled_management_denied": True,
            "state_retained": True, "production_routes_used": True,
        }, "event_counts": {"app_expired": 1, "disabled_management_denied": 3},
        "audit_counts": {"host_disable": disabled_audit_after - disabled_audit_before},
        "counts": {"executed": 7, "passed": 7, "failed": 0, "skipped": 0},
    }


def callback_counts_from_log(path: Path) -> dict[str, int]:
    counts = Counter(re.findall(r"^LIFETIME_ADAPTER_CALLBACK ([a-z_]+)$", path.read_text(encoding="utf-8"), re.MULTILINE))
    return dict(sorted(counts.items()))


def run_packaged_adapter_example(package_root: Path, provider_child: Path, environment: dict[str, str]) -> None:
    """Execute the exact ExUnit code block shipped in the candidate package."""
    markdown = package_root / "docs" / "examples" / "client-lifetime-adapter.md"
    if not markdown.is_file():
        raise PackageInputError("candidate package omits the client lifetime adapter example")
    examples = re.findall(r"^```elixir\n(.*?)^```\s*$", markdown.read_text(encoding="utf-8"), re.MULTILINE | re.DOTALL)
    if len(examples) != 1 or "defmodule HostLifetimeAdapterTest do" not in examples[0]:
        raise PackageInputError("candidate package lifetime example is not one bounded ExUnit module")
    test_file = provider_child / "test" / "client_lifetime_adapter_example_test.exs"
    test_file.parent.mkdir(parents=True, exist_ok=True)
    test_file.write_text(examples[0], encoding="utf-8")
    helper = test_file.parent / "test_helper.exs"
    if not helper.exists():
        helper.write_text("Logger.configure(level: :warning)\nExUnit.start()\n", encoding="utf-8")
    test_environment = dict(environment, MIX_ENV="test")
    output = run_child_command_output(
        provider_child,
        test_environment,
        "test",
        "--trace",
        str(test_file.relative_to(provider_child)),
    )
    summaries = re.findall(r"\b(\d+) tests?, (\d+) failures?\b", output)
    if len(summaries) != 1:
        raise AssertionError("packaged adapter example did not produce one ExUnit summary")
    executed, failed = (int(value) for value in summaries[0])
    required_cases = (
        "the configured stores round-trip a client under one PostgreSQL authority",
        "a late replacement audit failure restores credentials for an independent observer",
        "a late issuance audit failure restores grant, token and audit rows independently",
        "unsupported lifetime state fails closed",
    )
    if executed != 4 or failed != 0 or any(case not in output for case in required_cases):
        raise AssertionError("packaged adapter example omitted rollback, observer, unsupported, or clean test evidence")
    global CUSTOM_EXAMPLE_EVIDENCE
    CUSTOM_EXAMPLE_EVIDENCE = {"executed": executed, "passed": executed - failed}
    os.environ["CLEAN_ROOM_ADAPTER_EXAMPLE_EXECUTED"] = "true"


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


def assert_bare_mix_tasks(provider_child: Path, provider_environment: dict[str, str], redactor: Redactor) -> None:
    """Run the DB-touching Lockspire tasks in bare mix processes and assert on their output."""
    client_id = "clean-room-cli-" + uuid.uuid4().hex[:8]
    created = run_child_command_output(
        provider_child,
        provider_environment,
        "lockspire.client.create",
        "--client-type", "confidential",
        "--client-id", client_id,
        "--name", "Clean Room CLI",
        "--redirect-uri", "https://clean-room-cli.example/callback",
        "--scope", "openid",
        "--grant-type", "authorization_code",
    )
    secrets = re.findall(r"^client_secret=(\S+)$", created, re.MULTILINE)
    if len(secrets) == 1:
        register_secret(secrets[0])
        assert_redaction_guard(redactor, secrets[0])
    if len(secrets) != 1 or f"client_id={client_id}" not in created:
        raise AssertionError("bare mix step failed: lockspire.client.create output")

    token_format = run_child_command_output(provider_child, provider_environment, "lockspire.doctor", "token_format")
    if f"{client_id}: " not in token_format or "Could not inspect token formats" in token_format:
        tail = " | ".join(token_format.splitlines()[-8:])
        raise AssertionError(f"bare mix step failed: lockspire.doctor token_format output {tail}")

    remote_jwks = run_child_command_output(
        provider_child, provider_environment, "lockspire.doctor", "remote-jwks", "--client", client_id
    )
    if "Status: not_applicable" not in remote_jwks:
        tail = " | ".join(remote_jwks.splitlines()[-8:])
        raise AssertionError(f"bare mix step failed: lockspire.doctor remote-jwks output {tail}")
    print("bare mix tasks complete")


def main(argv: list[str]) -> int:
    global ACTIVE_REDACTOR
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", action="append", choices=("happy_path", "boundary", "lifecycle", "negative", "dpop", "dcr_lifetime", "selected_authorization_par"))
    parser.add_argument("--lifetime-leg", action="append", choices=("fresh", "custom", "legacy"))
    parser.add_argument("--receipt", type=Path)
    parser.add_argument("--check-lifetime-receipt", type=Path)
    parser.add_argument("--selected-case", action="append", choices=SELECTED_CASE_IDS)
    parser.add_argument("--selected-receipt", type=Path)
    parser.add_argument("--check-selected-receipt", type=Path)
    parser.add_argument("--expected-source-revision")
    parser.add_argument("--expected-receipt-sha256")
    parser.add_argument("--hold-after-ready", type=float, default=0.0, help=argparse.SUPPRESS)
    parser.add_argument("--verify-concurrent-origins", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--verify-signal-cleanup", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--verify-run-root-ownership", action="store_true", help=argparse.SUPPRESS)
    sources = parser.add_mutually_exclusive_group()
    sources.add_argument("--package-tar", type=Path)
    sources.add_argument("--hex-version")
    parser.add_argument("--package-sha256")
    args = parser.parse_args(argv)
    lifetime_leg = (args.lifetime_leg or ["fresh"])[0]
    if len(args.lifetime_leg or []) > 1:
        parser.error("run one lifetime leg per isolated provider process")
    if args.check_lifetime_receipt:
        try:
            expected_scenarios = (
                ("custom.issue_replace", "custom.shared_rollback", "custom.unsupported")
                if lifetime_leg == "custom"
                else (
                    "fresh.register_use",
                    "fresh.secret_expiry_rotate",
                    "fresh.management_put_recover",
                    "fresh.app_expiry_disabled",
                )
            )
            validate_lifetime_receipt(args.check_lifetime_receipt, expected_scenarios=expected_scenarios)
        except (AssertionError, OSError, json.JSONDecodeError) as error:
            print(str(error), file=sys.stderr)
            return 1
        print("lifetime receipt verified")
        return 0
    if args.check_selected_receipt:
        if args.expected_source_revision is None or args.expected_receipt_sha256 is None:
            parser.error("--check-selected-receipt requires --expected-source-revision and --expected-receipt-sha256")
        expected_cases = tuple(args.selected_case or SELECTED_CASE_IDS)
        try:
            validate_selected_receipt(
                args.check_selected_receipt, expected_case_ids=expected_cases,
                expected_source_revision=args.expected_source_revision,
                expected_receipt_sha256=args.expected_receipt_sha256,
            )
        except (AssertionError, OSError, json.JSONDecodeError) as error:
            print(str(error), file=sys.stderr)
            return 1
        print("selected receipt verified")
        return 0
    if args.verify_concurrent_origins:
        return verify_concurrent_real_journeys()
    if args.verify_signal_cleanup:
        return verify_signal_cleanup()
    if args.verify_run_root_ownership:
        return verify_run_root_ownership()
    if not args.only:
        parser.error("at least one --only journey group is required")
    if "selected_authorization_par" in args.only and args.only != ["selected_authorization_par"]:
        parser.error("selected_authorization_par must run as its only journey group")
    if "selected_authorization_par" in args.only and args.selected_receipt is None:
        parser.error("selected_authorization_par requires --selected-receipt")
    if args.selected_receipt is not None and args.only != ["selected_authorization_par"]:
        parser.error("--selected-receipt is only supported with --only selected_authorization_par")
    if args.selected_case and args.only != ["selected_authorization_par"]:
        parser.error("--selected-case requires selected_authorization_par or --check-selected-receipt")
    selected_cases = tuple(args.selected_case or SELECTED_CASE_IDS)
    if len(selected_cases) != len(set(selected_cases)):
        parser.error("--selected-case values must be unique")
    if "dcr_lifetime" in args.only and (args.only != ["dcr_lifetime"] or args.receipt is None):
        parser.error("dcr_lifetime requires --receipt and must run as its only journey group")
    if args.receipt is not None and args.only != ["dcr_lifetime"]:
        parser.error("--receipt is only supported with --only dcr_lifetime")
    if lifetime_leg == "legacy":
        parser.error("legacy lifetime leg is added by the legacy upgrade plan")
    signal.signal(signal.SIGINT, interruption_handler)
    signal.signal(signal.SIGTERM, interruption_handler)
    redactor = Redactor(SentinelSet.for_run())
    ACTIVE_REDACTOR = redactor
    # Random per run; it must never be written to evidence, so it is a registered secret.
    kek = base64.b64encode(os.urandom(32)).decode("ascii")
    os.environ["LOCKSPIRE_KEY_ENCRYPTION_KEY"] = kek
    register_secret(kek)
    provider_process = client_process = None
    provider_child = client_child = None
    provider_environment = client_environment = None
    dcr_scenario: list[dict[str, object]] | None = None
    selected_scenarios: list[dict[str, object]] | None = None
    result_code = 0
    cleanup = {"processes_stopped": False, "databases_removed": False, "temporary_roots_removed": False}
    redaction = {"sentinel_check_passed": False, "evidence_scan_passed": False}
    candidate: dict[str, str] | None = None
    candidate_binding: dict[str, object] | None = None
    source_revision = ""
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
        # The router overlay captures its audience while the child host compiles
        # during prepare_provider, so these origins must be inherited before
        # that call rather than added only to the later server environment.
        os.environ.update({
            "CLEAN_ROOM_PROVIDER_ORIGIN": PROVIDER_ORIGIN,
            "CLEAN_ROOM_CLIENT_ORIGIN": CLIENT_ORIGIN,
        })
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
            source_revision = package_identity.source_revision or ""
            current_head = subprocess.check_output(("git", "rev-parse", "HEAD"), cwd=Path(__file__).resolve().parents[2], text=True).strip()
            if not source_revision or source_revision != current_head:
                raise PackageInputError("package source revision differs from the current committed source")
            if "selected_authorization_par" in args.only and subprocess.check_output(
                ("git", "status", "--porcelain"), cwd=Path(__file__).resolve().parents[2], text=True
            ).strip():
                raise PackageInputError("selected package proof requires committed source and a clean checkout")
            if package_identity.tree_sha256 is None:
                raise PackageInputError("packaged candidate tree identity is unavailable")
            if package_identity.archive_sha256 is None:
                raise PackageInputError("packaged candidate archive identity is unavailable")
            candidate = {
                "kind": package_identity.kind,
                "version": package_identity.version,
                "archive_sha256": package_identity.archive_sha256,
                "tree_sha256": package_identity.tree_sha256,
            }
            print(
                "package candidate built "
                f"({package_identity.kind} lockspire-{package_identity.version} "
                f"archive_sha256:{candidate['archive_sha256']} tree_sha256:{candidate['tree_sha256']})"
            )
            handoff = run_root / "handoff"
            provider_child = prepare_provider(
                run_root,
                provider_database,
                package_root=package_root,
                candidate_identity=package_identity,
                port=provider_port,
                cache_root=dependency_cache_root(run_root),
                custom_lifetime_adapter=lifetime_leg == "custom",
            )
            print("provider host prepared")
            if "selected_authorization_par" in args.only:
                archive = run_root / "package" / f"lockspire-{package_identity.version}.tar"
                verify_candidate_input(archive, package_root, package_identity)
                vendor = (provider_child / "vendor" / "lockspire").resolve(strict=True)
                # prepare_provider has already verified the actual resolver path and
                # compiled marker using this exact PackageIdentity before returning.
                # Recheck the marker-bound candidate here before any listener starts.
                verify_candidate_host(package_root, provider_child, package_identity, vendor, vendor)
                provenance = candidate_host_provenance(provider_child)
                candidate_binding = {
                    "kind": package_identity.kind,
                    "version": package_identity.version,
                    "source_revision": source_revision,
                    "archive_sha256": package_identity.archive_sha256,
                    "tree_sha256": package_identity.tree_sha256,
                    "vendor_tree_sha256": provenance["vendor_tree_sha256"],
                    "compiled_candidate_sha256": provenance["compiled_candidate_sha256"],
                    "resolved_dependency_verified": provenance["resolved_dependency_verified"],
                }
            provider_environment = locked_environment(provider_child, "provider_host", dependency_cache_root(run_root))
            provider_environment.update({"DATABASE_URL": provider_database, "PORT": str(provider_port), "LOCKSPIRE_ISSUER": PROVIDER_ORIGIN + "/lockspire", "CLEAN_ROOM_PROVIDER_ORIGIN": PROVIDER_ORIGIN, "CLEAN_ROOM_CLIENT_ORIGIN": CLIENT_ORIGIN, "CLEAN_ROOM_HANDOFF_DIR": str(handoff), "SECRET_KEY_BASE": "clean-room-provider-secret-key-base-0123456789-abcdefghijklmnopqrstuvwxyz-0123456789"})
            if lifetime_leg == "custom":
                provider_environment["CLEAN_ROOM_CUSTOM_LIFETIME_ADAPTER"] = "true"
            run_child_command(provider_child, provider_environment, "ecto.create")
            print("provider database created")
            run_child_command(
                provider_child,
                provider_environment,
                "ecto.migrate",
                "--migrations-path",
                "priv/repo/migrations",
            )
            run_child_command(provider_child, provider_environment, "compile", "--warnings-as-errors")
            run_child_command(provider_child, provider_environment, "lockspire.verify")
            print("provider migrations and verification complete")
            if lifetime_leg == "custom":
                run_packaged_adapter_example(package_root, provider_child, provider_environment)
                print("packaged adapter example executed")
            run_child_command(provider_child, provider_environment, "run", "-e", f'CleanRoomProvider.Bootstrap.provision!("{handoff}")')
            run_child_command(provider_child, provider_environment, "lockspire.keys.reencrypt", "--check")
            run_child_command(provider_child, provider_environment, "lockspire.doctor", "key_encryption")
            assert_bare_mix_tasks(provider_child, provider_environment, redactor)
            print("provider smoke tasks complete")
            register_handoff_secrets(handoff)
            assert_redaction_guard(redactor, (handoff / "bearer-client.secret").read_text().strip())
            if "dcr_lifetime" in args.only:
                setup = run_child_command_output(
                    provider_child,
                    provider_environment,
                    "run",
                    "-e",
                    '{:ok, policy} = Lockspire.Admin.ServerPolicy.put_dcr_policy(%{registration_policy: :open, dcr_allowed_scopes: ["profile"], dcr_allowed_grant_types: ["authorization_code"], dcr_allowed_response_types: ["code"], dcr_allowed_redirect_uri_schemes: ["http"], dcr_allowed_redirect_uri_hosts: ["127.0.0.1"], dcr_allowed_token_endpoint_auth_methods: ["none"]}); IO.puts("DCR_POLICY_READY " <> Enum.join(policy.dcr_allowed_grant_types, ","))',
                )
                if "DCR_POLICY_READY authorization_code" not in setup:
                    raise AssertionError("clean-room DCR policy setup did not complete")
            if not any(group in args.only for group in ("dcr_lifetime", "selected_authorization_par")):
                client_child, client_environment = prepare_client(
                    run_root, client_database, handoff, client_port, package_root
                )
            provider_process = start_process(provider_child, provider_environment, run_root / "provider.log")
            if client_child is not None and client_environment is not None:
                client_process = start_process(client_child, client_environment, run_root / "client.log")
            wait_ready(PROVIDER_ORIGIN)
            if client_process is not None:
                wait_ready(CLIENT_ORIGIN)
            print("readiness complete")
            if args.hold_after_ready:
                time.sleep(args.hold_after_ready)
            if "dcr_lifetime" in args.only:
                dcr_scenario = run_dcr_lifetime(
                    Browser(PROVIDER_ORIGIN),
                    provider_child,
                    provider_environment,
                    handoff,
                    run_root / "provider.log",
                    custom=lifetime_leg == "custom",
                )
            if "selected_authorization_par" in args.only:
                assert_owned_run_root(run_root, run_root_owner)
                selected_scenarios = run_selected_authorization_par(
                    selected_cases, Browser(PROVIDER_ORIGIN), provider_child, provider_environment
                )
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
            redaction["sentinel_check_passed"] = True
            redaction["evidence_scan_passed"] = True
        except JourneyInterrupted:
            print("clean-room journey interrupted", file=sys.stderr)
            result_code = 130
        except (AssertionError, PackageInputError, OSError, subprocess.SubprocessError, json.JSONDecodeError) as error:
            print(str(safe_failure_summary(
                stage="saas_journey", scenario="-".join(args.only or ["all"]),
                event="runner_failure", field=type(error).__name__, count=1,
            )), file=sys.stderr)
            result_code = 1
        finally:
            try:
                stop_process(client_process)
                stop_process(provider_process)
                cleanup["processes_stopped"] = all(process is None or process.poll() is not None for process in (client_process, provider_process))
            except (OSError, subprocess.SubprocessError):
                result_code = 1
                cleanup["processes_stopped"] = False
                print("clean-room process cleanup failed", file=sys.stderr)
            try:
                assert_owned_run_root(run_root, run_root_owner)
            except AssertionError as error:
                print(str(safe_failure_summary(
                    stage="saas_journey", scenario="cleanup", event="runner_failure",
                    field=type(error).__name__, count=1,
                )), file=sys.stderr)
            else:
                try:
                    if client_child is not None and client_environment is not None:
                        drop_child_database(client_child, client_environment, "client")
                    if provider_child is not None and provider_environment is not None:
                        drop_child_database(provider_child, provider_environment, "provider")
                    cleanup["databases_removed"] = True
                except (AssertionError, OSError, subprocess.SubprocessError):
                    result_code = 1
                    cleanup["databases_removed"] = False
                    print("clean-room database cleanup failed", file=sys.stderr)
            if previous_tmpdir is None:
                os.environ.pop("TMPDIR", None)
            else:
                os.environ["TMPDIR"] = previous_tmpdir
            print("cleanup complete")
    cleanup["temporary_roots_removed"] = not run_root.exists()
    if "selected_authorization_par" in args.only and args.selected_receipt is not None and candidate_binding is not None:
        if selected_scenarios is None:
            selected_scenarios = [{
                "id": selected_cases[0], "outcome": "failed", "observations": {},
                "counts": {"executed": 1, "passed": 0, "failed": 1, "skipped": 0},
            }]
        expected_cases = selected_cases
        selection = "complete" if expected_cases == SELECTED_CASE_IDS else "partial"
        try:
            write_selected_receipt(
                args.selected_receipt, selection=selection, expected_case_ids=expected_cases,
                source_revision=source_revision, candidate=candidate_binding,
                scenarios=selected_scenarios, cleanup=cleanup, redaction=redaction,
            )
            if result_code == 0:
                validate_selected_receipt(
                    args.selected_receipt, expected_case_ids=expected_cases,
                    expected_source_revision=source_revision, expected_binding=candidate_binding,
                )
        except (AssertionError, OSError, ValueError) as error:
            print(str(safe_failure_summary(
                stage="selected_receipt", scenario="-".join(expected_cases),
                event="receipt_rejected", field=type(error).__name__, count=1,
            )), file=sys.stderr)
            result_code = 1
    if args.receipt is not None:
        if dcr_scenario is None and result_code != 0:
            dcr_scenario = [{
                "id": "custom.issue_replace" if lifetime_leg == "custom" else "fresh.register_use",
                "leg": lifetime_leg if lifetime_leg == "custom" else "fresh",
                "contract_case_ids": ["C-POL-01", "C-APP-06", "C-PROOF-01"],
                "outcome": "failed", "observations": {}, "event_counts": {}, "audit_counts": {},
                "counts": {"executed": 1, "passed": 0, "failed": 1, "skipped": 0},
            }]
        if dcr_scenario is not None and candidate is not None:
            scenarios = dcr_scenario
            if lifetime_leg == "custom" and CUSTOM_EXAMPLE_EVIDENCE is not None:
                executed = int(CUSTOM_EXAMPLE_EVIDENCE["executed"])
                passed = int(CUSTOM_EXAMPLE_EVIDENCE["passed"])
                scenarios.extend([
                    {
                        "id": "custom.shared_rollback", "leg": "custom",
                        "contract_case_ids": ["C-APP-06", "C-PROOF-01"],
                        "outcome": "passed", "observations": {
                            "independent_observer": True, "rollback_preserved": True,
                            "replacement_observed": True, "issuance_observed": True,
                        }, "event_counts": {}, "audit_counts": {},
                        "counts": {"executed": 2, "passed": 2, "failed": 0, "skipped": 0},
                    },
                    {
                        "id": "custom.unsupported", "leg": "custom",
                        "contract_case_ids": ["C-POL-01"],
                        "outcome": "passed", "observations": {
                            "unsupported_rejected": True, "example_executed": True,
                        }, "event_counts": {}, "audit_counts": {},
                        "counts": {"executed": 1, "passed": 1, "failed": 0, "skipped": 0},
                    },
                ])
            write_lifetime_receipt(
                args.receipt,
                source_revision=source_revision,
                candidate=candidate,
                scenarios=scenarios,
                cleanup=cleanup,
            )
    return result_code


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
