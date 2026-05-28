#!/usr/bin/env python3
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


BASE_URL = os.environ.get("LOCKSPIRE_DEMO_BASE_URL", "http://127.0.0.1:4100")


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

            location = response["headers"].get("location")
            if not location:
                return response

            url = urljoin(url, location)
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
            request_headers["cookie"] = "; ".join(f"{key}={value}" for key, value in self.cookies.items())

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
        raise AssertionError(f"{label}: expected HTTP {expected}, got {response['status']}\n{response['body'][:600]}")


def assert_contains(response, needle, label):
    if needle not in response["body"]:
        raise AssertionError(f"{label}: missing {needle!r}\n{response['body'][:600]}")


def csrf(body):
    match = re.search(r'name="_csrf_token"\s+value="([^"]+)"', body)
    if not match:
        raise AssertionError("missing CSRF token")
    return match.group(1)


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


def wait_until_ready():
    deadline = time.time() + 45
    browser = Browser(BASE_URL)

    while time.time() < deadline:
        try:
            response = browser.request("GET", "/")
            if response["status"] == 200:
                return
        except OSError:
            pass

        time.sleep(1)

    raise AssertionError(f"demo app did not become ready at {BASE_URL}")


def login(browser, account, return_to="/", interaction_id=None):
    page = browser.request("GET", "/login")
    assert_status(page, 200, "login page")

    params = {
        "_csrf_token": csrf(page["body"]),
        "login": account,
        "return_to": return_to,
    }
    if interaction_id:
        params["interaction_id"] = interaction_id

    return browser.request("POST", "/login", params)


def exercise_discovery_and_admin():
    browser = Browser(BASE_URL)

    discovery = browser.request("GET", "/lockspire/.well-known/openid-configuration")
    assert_status(discovery, 200, "discovery")
    discovery_json = json_body(discovery, "discovery")
    assert discovery_json["issuer"] == BASE_URL + "/lockspire"
    assert discovery_json["authorization_endpoint"] == BASE_URL + "/lockspire/authorize"
    assert discovery_json["device_authorization_endpoint"] == BASE_URL + "/lockspire/device/code"

    jwks = browser.request("GET", "/lockspire/jwks")
    assert_status(jwks, 200, "jwks")
    assert json_body(jwks, "jwks")["keys"], "jwks must publish at least one signing key"

    denied = browser.request("GET", "/lockspire/admin")
    assert_status(denied, 403, "anonymous admin access")

    logged_in = login(browser, "ops", "/lockspire/admin")
    assert_status(logged_in, 302, "operator login")
    assert location(logged_in).startswith("/lockspire/admin")

    admin = browser.request("GET", "/lockspire/admin")
    assert_status(admin, 200, "operator admin access")


def exercise_authorization_code():
    browser = Browser(BASE_URL)
    verifier = "demo-pkce-verifier"
    state = "smoke-state"
    authorize_params = {
        "response_type": "code",
        "client_id": "acme-ledger-public",
        "redirect_uri": BASE_URL + "/oauth/callback",
        "scope": "openid email profile read:billing",
        "state": state,
        "nonce": "smoke-nonce",
        "prompt": "consent",
        "code_challenge": code_challenge(verifier),
        "code_challenge_method": "S256",
    }

    start = browser.request("GET", "/lockspire/authorize?" + urlencode(authorize_params))
    assert_status(start, 302, "authorize starts login handoff")

    handoff = urlparse(location(start))
    handoff_params = parse_qs(handoff.query)
    interaction_id = handoff_params["interaction_id"][0]
    return_to = handoff_params["return_to"][0]

    logged_in = login(browser, "alice", return_to, interaction_id)
    assert_status(logged_in, 302, "account login")

    resumed = browser.request("GET", location(logged_in))
    assert_status(resumed, 302, "interaction resume")

    consent = browser.request("GET", location(resumed))
    assert_status(consent, 200, "consent page")
    assert_contains(consent, "Approve access", "consent page")

    completed = browser.request(
        "POST",
        f"/lockspire/interactions/{interaction_id}/complete",
        {"_csrf_token": csrf(consent["body"]), "decision": "approve", "remember": "true"},
    )
    assert_status(completed, 302, "consent approval")

    callback = urlparse(location(completed))
    callback_params = parse_qs(callback.query)
    assert callback_params["state"][0] == state
    code = callback_params["code"][0]

    token = browser.request(
        "POST",
        "/lockspire/token",
        {
            "grant_type": "authorization_code",
            "client_id": "acme-ledger-public",
            "redirect_uri": BASE_URL + "/oauth/callback",
            "code": code,
            "code_verifier": verifier,
        },
    )
    assert_status(token, 200, "token exchange")
    token_json = json_body(token, "token exchange")
    assert token_json["access_token"]
    assert token_json["id_token"]

    userinfo = browser.request(
        "GET",
        "/lockspire/userinfo",
        headers={"authorization": "Bearer " + token_json["access_token"]},
    )
    assert_status(userinfo, 200, "userinfo accepts issued access token")
    userinfo_json = json_body(userinfo, "userinfo")
    assert userinfo_json["email"] == "alice@acme.test"

    # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
    # pipeline :lockspire_protected_api do
    #   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "billing-api", enforce_audience: true
    #   plug Lockspire.Plug.EnforceSenderConstraints,
    #     dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
    #   plug Lockspire.Plug.RequireToken
    # end
    # END LOCKSPIRE_PROTECTED_PIPELINE

    anonymous_api = Browser(BASE_URL).request("GET", "/api/billing/summary")
    assert_status(anonymous_api, 401, "protected API rejects anonymous request")


def exercise_device_flow():
    browser = Browser(BASE_URL)

    issued = browser.request(
        "POST",
        "/lockspire/device/code",
        {"client_id": "acme-tv-device", "scope": "openid profile read:billing"},
    )
    assert_status(issued, 200, "device authorization")
    issued_json = json_body(issued, "device authorization")
    assert issued_json["device_code"]
    assert issued_json["user_code"]
    assert issued_json["verification_uri"] == BASE_URL + "/verify"

    login(browser, "alice", "/verify")

    # WR-05: fetch the verify page in its own statement so the GET is visible
    # and its failure surfaces directly (rather than being masked by csrf()
    # raising on an empty body when the GET itself fails).
    verify_page = browser.request("GET", "/verify")
    assert_status(verify_page, 200, "verify page")

    lookup = browser.request(
        "POST",
        "/verify",
        {
            "_csrf_token": csrf(verify_page["body"]),
            "user_code": issued_json["user_code"],
        },
    )
    assert_status(lookup, 200, "device code lookup")
    assert_contains(lookup, "Approve device", "device review")

    match = re.search(r'action="/verify/([^"]+)/approve"', lookup["body"])
    if not match:
        raise AssertionError("missing device approval form")

    approved = browser.request(
        "POST",
        f"/verify/{match.group(1)}/approve",
        {"_csrf_token": csrf(lookup["body"])},
    )
    assert_status(approved, 302, "device approval")

    token = browser.request(
        "POST",
        "/lockspire/token",
        {
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
            "device_code": issued_json["device_code"],
            "client_id": "acme-tv-device",
        },
    )
    assert_status(token, 200, "device token exchange")
    assert json_body(token, "device token exchange")["access_token"]


def main():
    wait_until_ready()
    exercise_discovery_and_admin()
    exercise_authorization_code()
    exercise_device_flow()
    print("adoption demo smoke passed")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"adoption demo smoke failed: {exc}", file=sys.stderr)
        sys.exit(1)
