#!/usr/bin/env python3
"""Redact clean-room acceptance evidence before it reaches output or disk."""

from __future__ import annotations

import argparse
import base64
from dataclasses import dataclass
import hashlib
import re
import secrets
import sys
from typing import Any, Mapping, Sequence
from urllib.parse import quote, quote_plus


SECRET_HEADER_NAMES = frozenset({"authorization", "cookie", "set-cookie"})
FREE_TEXT_HEADERS = re.compile(r"(?i)(authorization|cookie|set-cookie)\s*[:=]\s*[^\r\n]+")
SAFE_IDENTIFIER = re.compile(r"[A-Za-z0-9_.-]{1,80}\Z")
SAFE_FAILURE_FIELDS = frozenset({"stage", "scenario", "event", "field", "count"})
SAFE_IDENTIFIERS = frozenset({
    "legacy_upgrade", "saas_journey", "public", "tenant_auth", "selected", "cleanup",
    "all", "happy_path", "boundary", "lifecycle", "negative", "dpop", "dcr_lifetime",
    "child_start", "child_timeout", "child_exit", "runner_failure", "assertion_failure",
    "stdout_stderr", "argv", "process", "exception", "PackageInputError", "AssertionError",
    "OSError", "SubprocessError", "JSONDecodeError", "TimeoutExpired", "RuntimeError",
})


@dataclass(frozen=True)
class SentinelSet:
    authorization_code: str
    access_token: str
    refresh_token: str
    bearer_client_secret: str
    dpop_client_secret: str
    session_encryption_key: str
    pkce_verifier: str
    dpop_private_key: str
    dpop_proof: str
    cookie: str

    @classmethod
    def for_run(cls) -> "SentinelSet":
        def value(label: str) -> str:
            return f"phase133-{label}-sentinel-{secrets.token_urlsafe(18)}"

        return cls(
            authorization_code=value("authorization-code"),
            access_token=value("access-token"),
            refresh_token=value("refresh-token"),
            bearer_client_secret=value("bearer-client-secret"),
            dpop_client_secret=value("dpop-client-secret"),
            session_encryption_key=value("session-key"),
            pkce_verifier=value("pkce-verifier"),
            dpop_private_key=value("dpop-private-key"),
            dpop_proof=value("dpop-proof"),
            cookie=value("cookie"),
        )

    def values(self) -> tuple[str, ...]:
        return tuple(value for value in self.__dict__.values())


class Redactor:
    """The only formatting boundary for process, HTTP, exception, and artifact evidence."""

    def __init__(self, sentinels: SentinelSet):
        self.sentinels = sentinels
        self._values = tuple(sorted(sentinels.values(), key=len, reverse=True))

    def register(self, value: object) -> None:
        """Register a real per-run credential before it can enter retained evidence."""
        if not isinstance(value, str) or not value:
            return
        self._values = tuple(sorted(set((*self._values, value)), key=len, reverse=True))

    def register_material(self, value: object) -> None:
        """Register a returned value and common retained encodings before rendering."""
        if not isinstance(value, str) or not value:
            return
        raw = value.encode("utf-8")
        digest = hashlib.sha256(raw).hexdigest()
        representations = {
            value,
            base64.b64encode(raw).decode("ascii"),
            base64.urlsafe_b64encode(raw).decode("ascii"),
            quote(value, safe=""),
            quote_plus(value, safe=""),
            digest,
        }
        for representation in representations:
            self.register(representation)

    def text(self, value: object) -> str:
        scrubbed = str(value)

        for secret in self._values:
            scrubbed = scrubbed.replace(secret, "[REDACTED]")

        return FREE_TEXT_HEADERS.sub(lambda match: f"{match.group(1)}: [REDACTED]", scrubbed)

    def structured(self, value: Any) -> Any:
        if isinstance(value, Mapping):
            return {
                str(key): "[REDACTED]"
                if str(key).lower() in SECRET_HEADER_NAMES
                else self.structured(item)
                for key, item in value.items()
            }

        if isinstance(value, list):
            return [self.structured(item) for item in value]

        if isinstance(value, tuple):
            return tuple(self.structured(item) for item in value)

        return self.text(value)

    def assert_safe(self, evidence: str) -> None:
        leaked = [secret for secret in self._values if secret in evidence]
        if leaked:
            raise RuntimeError(f"redaction sentinel scan failed for {len(leaked)} secret class(es)")


def safe_http_summary(redactor: Redactor, status: int, headers: Mapping[str, str], body: object) -> dict[str, Any]:
    return {
        "status": status,
        "headers": redactor.structured(headers),
        "body_excerpt": redactor.text(body)[:600],
    }


def safe_failure_summary(
    *, stage: object, scenario: object, event: object, field: object, count: object
) -> dict[str, str | int]:
    """Build diagnostics from a fixed identifier/count allowlist only."""
    def identifier(value: object) -> str:
        return value if isinstance(value, str) and SAFE_IDENTIFIER.fullmatch(value) and value in SAFE_IDENTIFIERS else "unknown"

    safe_count = count if type(count) is int and count >= 0 else 0
    summary: dict[str, str | int] = {
        "stage": identifier(stage),
        "scenario": identifier(scenario),
        "event": identifier(event),
        "field": identifier(field),
        "count": safe_count,
    }
    if set(summary) != SAFE_FAILURE_FIELDS:
        raise RuntimeError("safe failure summary fields drifted")
    return summary


def self_test() -> None:
    sentinels = SentinelSet.for_run()
    redactor = Redactor(sentinels)
    raw_free_text = "\n".join(sentinels.values()) + f"\nAuthorization: Bearer {sentinels.access_token}"
    raw_structured = {
        "authorization": f"Bearer {sentinels.access_token}",
        "cookie": f"session={sentinels.cookie}",
        "detail": raw_free_text,
    }
    rendered = f"{redactor.text(raw_free_text)}\n{redactor.structured(raw_structured)}"
    redactor.assert_safe(rendered)

    generated_secret = secrets.token_urlsafe(32)
    redactor.register(generated_secret)
    rendered_generated = redactor.text(f"Authorization: Bearer {generated_secret}")
    redactor.assert_safe(rendered_generated)
    if generated_secret in rendered_generated:
        raise RuntimeError("registered generated credential remained in evidence")


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    return parser.parse_args(argv)


def main(argv: Sequence[str]) -> int:
    args = parse_args(argv)
    if not args.self_test:
        print("choose --self-test", file=sys.stderr)
        return 2

    self_test()
    print("redaction verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
