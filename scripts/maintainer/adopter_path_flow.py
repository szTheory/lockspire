#!/usr/bin/env python3
"""Adopter path flow driver.

Drives the documented authorization-code + PKCE sequence against a booted
adopter-path host over plain HTTP (no browser, no mailbox), then proves the
issued access token is *usable* at two independent layers: Lockspire's own
`<mount>/userinfo` and a host-owned protected API route (ADOPT-04).

This module is adapted from `scripts/demo/adoption_smoke.py:221-320`, which
already drives the same sequence. That file is never edited in place --
`scripts/maintainer/repo_hygiene_check.sh` holds a BLOCK-level contract over
its contents. Demo-specific hardcodes (client id, seeded account, resource
indicator, admin-shell CSS assertions) are left behind here in favor of
`argparse` flags.

The driver never prints the access token, ID token, authorization code,
session cookie, or the seeded password -- only the assertion label and HTTP
status appear in result lines and error details.
"""
import argparse
import base64
import hashlib
import http.client
import json
import os
import re
import sys
import time
from http.cookies import SimpleCookie
from urllib.parse import parse_qs, urlencode, urljoin, urlparse


DEFAULT_BASE_URL = "http://127.0.0.1:4200"
DEFAULT_MOUNT = "/lockspire"
DEFAULT_CLIENT_ID = "adopter-walk-public"
DEFAULT_PROTECTED_PATH = "/api/walk/summary"
DEFAULT_SCOPE = "openid email profile read:walk"

_FORM_TOKEN = re.compile(r'name="_csrf_token"[^>]*\bvalue="([^"]+)"')
_META_TOKEN = re.compile(r'<meta[^>]*name="csrf-token"[^>]*content="([^"]+)"')


class Browser:
    def __init__(self, base_url):
        self.base = base_url.rstrip("/")
        self.origin = urlparse(self.base)
        self.cookies = {}

    def request(self, method, target, data=None, headers=None, follow=False):
        url = urljoin(self.base + "/", target)
        for _ in range(8):
            response = self._single_request(method, url, data, headers)
            if not follow or response["status"] not in (301, 302, 303, 307, 308):
                return response

            location_header = response["headers"].get("location")
            if not location_header:
                return response

            url = urljoin(url, location_header)
            if response["status"] == 303 or method.upper() != "GET":
                method, data = "GET", None

        raise AssertionError("too many redirects")

    def _single_request(self, method, url, data, headers):
        parsed = urlparse(url)
        body = None
        request_headers = dict(headers or {})

        if isinstance(data, dict):
            body = urlencode(data).encode()
            request_headers.setdefault("content-type", "application/x-www-form-urlencoded")
        elif isinstance(data, bytes):
            body = data

        if self.cookies:
            request_headers["cookie"] = "; ".join(
                f"{key}={value}" for key, value in self.cookies.items()
            )

        conn = http.client.HTTPConnection(parsed.hostname, parsed.port or 80, timeout=10)
        path = parsed.path or "/"
        if parsed.query:
            path += "?" + parsed.query

        conn.request(method.upper(), path, body=body, headers=request_headers)
        resp = conn.getresponse()
        raw_body = resp.read()
        header_pairs = resp.getheaders()
        conn.close()

        for name, value in header_pairs:
            if name.lower() == "set-cookie":
                cookie = SimpleCookie()
                cookie.load(value)
                for key, morsel in cookie.items():
                    self.cookies[key] = morsel.value

        return {
            "status": resp.status,
            "headers": {name.lower(): value for name, value in header_pairs},
            "body": raw_body.decode("utf-8", "replace"),
            "url": url,
        }


def assert_status(response, expected, label):
    if response["status"] != expected:
        raise AssertionError(
            f"{label}: expected HTTP {expected}, got {response['status']}\n{response['body'][:600]}"
        )


def assert_contains(response, needle, label):
    if needle not in response["body"]:
        raise AssertionError(f"{label}: missing {needle!r}\n{response['body'][:600]}")


def assert_equal(actual, expected, label):
    if actual != expected:
        raise AssertionError(f"{label}: expected {expected!r}, got {actual!r}")


def location(response):
    value = response["headers"].get("location")
    if not value:
        raise AssertionError(f"missing location header on HTTP {response['status']}")
    return value


def code_challenge(verifier):
    digest = hashlib.sha256(verifier.encode()).digest()
    return base64.urlsafe_b64encode(digest).rstrip(b"=").decode()


def json_body(response, label):
    try:
        return json.loads(response["body"])
    except json.JSONDecodeError as exc:
        raise AssertionError(f"{label}: invalid JSON: {exc}\n{response['body'][:600]}")


def csrf(body, label="page"):
    match = _FORM_TOKEN.search(body)
    if match:
        return match.group(1)

    # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D10
    # Lockspire's shipped Lockspire.Web.ConsentLive renders raw <form method="post">
    # decision forms with no _csrf_token input at all -- there is nothing for the
    # form-input pattern above to find. Fall back to the <meta name="csrf-token">
    # tag the generated root layout renders, which protect_from_forgery accepts.
    # This absence is a real defect the ledger records; the fallback is a marked
    # workaround, not a fix.
    match = _META_TOKEN.search(body)
    if match:
        return match.group(1)

    raise AssertionError(f"{label}: missing CSRF token")


def wait_until_ready(base_url, mount):
    deadline = time.time() + 45
    browser = Browser(base_url)

    discovery_ready = False
    last_error = None

    while time.time() < deadline:
        try:
            response = browser.request("GET", f"{mount}/.well-known/openid-configuration")
            if response["status"] == 200:
                discovery_ready = True
                break
        except OSError as exc:
            last_error = exc

        time.sleep(1)

    if not discovery_ready:
        raise AssertionError(
            f"readiness: {mount}/.well-known/openid-configuration did not return 200 at "
            f"{base_url} within 45s (last connection error: {last_error})"
        )

    jwks = browser.request("GET", f"{mount}/jwks")
    assert_status(jwks, 200, "readiness: jwks")
    jwks_json = json_body(jwks, "readiness: jwks")

    if not jwks_json.get("keys"):
        raise AssertionError(
            "readiness: jwks published zero signing keys -- Lockspire.Admin.generate_key/1 may "
            "not yield a published, active key without a separate publish step"
        )


def login(browser, email, password):
    page = browser.request("GET", "/users/log-in")
    assert_status(page, 200, "login page")

    return browser.request(
        "POST",
        "/users/log-in",
        {
            "_csrf_token": csrf(page["body"], "login page"),
            "user[email]": email,
            "user[password]": password,
        },
    )


def exercise_authorization_code(base_url, mount, client_id, email, password, scope):
    browser = Browser(base_url)
    verifier = base64.urlsafe_b64encode(os.urandom(32)).rstrip(b"=").decode()
    state = base64.urlsafe_b64encode(os.urandom(16)).rstrip(b"=").decode()
    nonce = base64.urlsafe_b64encode(os.urandom(16)).rstrip(b"=").decode()
    redirect_uri = base_url + "/oauth/callback"

    authorize_params = {
        "response_type": "code",
        "client_id": client_id,
        "redirect_uri": redirect_uri,
        "scope": scope,
        "state": state,
        "nonce": nonce,
        "prompt": "consent",
        "code_challenge": code_challenge(verifier),
        "code_challenge_method": "S256",
    }

    start = browser.request("GET", f"{mount}/authorize?" + urlencode(authorize_params))
    assert_status(start, 302, "authorize starts login handoff")

    handoff = urlparse(location(start))
    handoff_params = parse_qs(handoff.query)
    if "interaction_id" not in handoff_params or "return_to" not in handoff_params:
        raise AssertionError("authorize handoff: missing interaction_id or return_to")

    interaction_id = handoff_params["interaction_id"][0]
    return_to = handoff_params["return_to"][0]

    logged_in = login(browser, email, password)
    assert_status(logged_in, 302, "account login")

    # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D14
    # The generated phx.gen.auth log_in_user/3 redirects to a session key
    # (:user_return_to) that only a GET through require_authenticated_user ever
    # writes, so a return_to query parameter POSTed to /users/log-in is inert.
    # The driver navigates to return_to itself rather than trusting the login
    # POST's own redirect target.
    #
    # return_to is the consent page itself (AuthorizeController wires it to
    # consent_path/1, not an intermediate resume redirect), and ConsentLive's own
    # ensure_ready_for_consent/2 transitions a :pending_login interaction to
    # :pending_consent inline on this same request -- confirmed against a real
    # generated host: this GET returns 200 with the consent page body directly,
    # never a 302 to a separate resume hop.
    consent = browser.request("GET", return_to)
    assert_status(consent, 200, "consent page (via return_to)")
    assert_contains(consent, "Approve access", "consent page")

    completed = browser.request(
        "POST",
        f"{mount}/interactions/{interaction_id}/complete",
        {
            "_csrf_token": csrf(consent["body"], "consent page"),
            "decision": "approve",
            "remember": "true",
        },
    )
    assert_status(completed, 302, "consent approval")

    callback_url = urljoin(base_url + "/", location(completed))
    callback = urlparse(callback_url)
    callback_without_query = callback._replace(query="", fragment="").geturl()
    assert_equal(callback_without_query, redirect_uri, "authorization callback redirect_uri")

    callback_params = parse_qs(callback.query)
    if "state" not in callback_params:
        raise AssertionError("authorization callback: missing state")
    assert_equal(callback_params["state"][0], state, "authorization callback state")

    if "code" not in callback_params:
        raise AssertionError("authorization callback: missing code")
    code = callback_params["code"][0]

    token = browser.request(
        "POST",
        f"{mount}/token",
        {
            "grant_type": "authorization_code",
            "client_id": client_id,
            "redirect_uri": redirect_uri,
            "code": code,
            "code_verifier": verifier,
        },
    )
    assert_status(token, 200, "token exchange")
    token_json = json_body(token, "token exchange")

    if not token_json.get("access_token"):
        raise AssertionError("token exchange: response carries no access_token")
    if not token_json.get("id_token"):
        raise AssertionError("token exchange: response carries no id_token")

    return token_json["access_token"], token_json["id_token"]


def exercise_token_proof(base_url, mount, protected_path, access_token):
    browser = Browser(base_url)

    userinfo = browser.request(
        "GET",
        f"{mount}/userinfo",
        headers={"authorization": "Bearer " + access_token},
    )
    assert_status(userinfo, 200, "userinfo accepts issued access token")
    userinfo_json = json_body(userinfo, "userinfo")

    if not userinfo_json.get("sub"):
        raise AssertionError("userinfo: response carries no sub claim")
    if not userinfo_json.get("email"):
        raise AssertionError("userinfo: response carries no email claim")

    anonymous_api = Browser(base_url).request("GET", protected_path)
    assert_status(anonymous_api, 401, "protected host route rejects anonymous request")

    authed_api = Browser(base_url).request(
        "GET",
        protected_path,
        headers={"authorization": "Bearer " + access_token},
    )
    assert_status(authed_api, 200, "protected host route accepts issued access token")
    authed_api_json = json_body(authed_api, "protected host route")

    access_token_claims = authed_api_json.get("access_token") or {}
    if not access_token_claims.get("subject"):
        raise AssertionError("protected host route: response carries no access_token.subject")
    if not access_token_claims.get("scope"):
        raise AssertionError("protected host route: response carries no access_token.scope")


def record(line):
    print(line)


def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description=(
            "Drive the authorization-code + PKCE flow against a booted adopter-path host and "
            "prove the issued access token is usable at two independent layers (ADOPT-04)."
        )
    )
    parser.add_argument(
        "--base-url",
        default=os.environ.get("LOCKSPIRE_WALK_BASE_URL", DEFAULT_BASE_URL),
        help="Base URL of the booted host app (default: %(default)s, env LOCKSPIRE_WALK_BASE_URL)",
    )
    parser.add_argument(
        "--mount",
        default=DEFAULT_MOUNT,
        help="Lockspire mount path (default: %(default)s)",
    )
    parser.add_argument(
        "--client-id",
        default=DEFAULT_CLIENT_ID,
        help="Registered public client id (default: %(default)s)",
    )
    parser.add_argument(
        "--email",
        default=os.environ.get("LOCKSPIRE_WALK_EMAIL"),
        help="Seeded user email (default: env LOCKSPIRE_WALK_EMAIL)",
    )
    parser.add_argument(
        "--password",
        default=os.environ.get("LOCKSPIRE_WALK_PASSWORD"),
        help="Seeded user password (default: env LOCKSPIRE_WALK_PASSWORD)",
    )
    parser.add_argument(
        "--protected-path",
        default=DEFAULT_PROTECTED_PATH,
        help="Host-owned protected API route path (default: %(default)s)",
    )
    parser.add_argument(
        "--scope",
        default=DEFAULT_SCOPE,
        help="Requested scope string (default: %(default)s)",
    )
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    base_url = args.base_url.rstrip("/")

    try:
        wait_until_ready(base_url, args.mount)
    except AssertionError as exc:
        record(f"[FAIL] step-06b-flow: §6 prove the flow: {exc}")
        record(
            "[FAIL] step-06c-token-proof: §6 prove the flow: precondition step-06b-flow did "
            f"not run ({exc})"
        )
        return 1

    exit_code = 0
    access_token = None

    try:
        access_token, _id_token = exercise_authorization_code(
            base_url, args.mount, args.client_id, args.email, args.password, args.scope
        )
        record(
            "[PASS] step-06b-flow: §6 prove the flow: authorization-code + PKCE sequence "
            "completed, access_token and id_token issued"
        )
    except AssertionError as exc:
        record(f"[FAIL] step-06b-flow: §6 prove the flow: {exc}")
        exit_code = 1

    try:
        if access_token is None:
            raise AssertionError("step-06b-flow did not yield an access token")

        exercise_token_proof(base_url, args.mount, args.protected_path, access_token)
        record(
            "[PASS] step-06c-token-proof: §6 prove the flow: userinfo and the protected host "
            "route both accepted the issued access token; the anonymous request was rejected"
        )
    except AssertionError as exc:
        record(f"[FAIL] step-06c-token-proof: §6 prove the flow: {exc}")
        exit_code = 1

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
