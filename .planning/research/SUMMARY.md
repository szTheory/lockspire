# Research Summary: Lockspire (RFC 8628 - Device Flow)

**Domain:** OAuth 2.0 Device Authorization Grant (Embedded Elixir Provider)
**Researched:** 2026-04-27
**Overall confidence:** HIGH

## Executive Summary

RFC 8628 (OAuth 2.0 Device Authorization Grant) is designed for input-constrained devices (CLI tools, Smart TVs) that lack a suitable browser for standard OAuth flows. Instead of a redirect, the device receives a high-entropy `device_code` (for polling) and a low-entropy `user_code` (for the user to type into a secondary device like a smartphone). 

For Lockspire, this milestone represents a strategic expansion to support CLI and partner integrations. The primary challenges in implementing this in Elixir revolve around managing high-frequency polling on the `/token` endpoint without crushing the database, and securing the low-entropy `user_code` against brute-force and remote phishing attacks. Since Lockspire avoids requiring external infrastructure like Redis, the polling and state management must be handled efficiently via Ecto/Postgres with proper indexing and backpressure mechanisms.

## Key Findings

**Stack:** Phoenix for endpoints, Ecto/Postgres for state, and strict rate-limiting for brute-force prevention.
**Architecture:** A polling-based token issuance model heavily reliant on efficient database reads and the `slow_down` backpressure signal.
**Critical pitfall:** Remote phishing attacks and brute-forcing of the low-entropy `user_code`.

## Implications for Roadmap

Based on research, suggested phase structure for the v1.6 milestone:

1. **Phase A: Core Device Authorization Endpoint & Storage** - Establishes the foundation.
   - Addresses: `POST /device/code` endpoint, generating Base20 user codes, Ecto schema for tracking pending device codes.
   - Avoids: DB bloat by implementing strict TTLs/expiration (5-10 minutes) for device codes.

2. **Phase B: Host-Owned Verification UI Seam** - The user-facing component.
   - Addresses: `GET /verify` and `POST /verify` integration, passing device context to the consent screen.
   - Avoids: Remote phishing by requiring explicit user interaction (no auto-submit on `verification_uri_complete`).

3. **Phase C: Polling & Token Issuance** - Closing the loop.
   - Addresses: `POST /token` support for `grant_type=urn:ietf:params:oauth:grant-type:device_code`, handling `authorization_pending`, `slow_down`, and token issuance upon authorization.
   - Avoids: The "Polling Storm" by strictly enforcing polling intervals and using efficient Ecto indexes.

**Phase ordering rationale:**
- Storage and generation must exist before users can verify codes. Verification must exist before the device can successfully poll for a token.

**Research flags for phases:**
- Phase B: Needs careful documentation on how host apps should implement rate-limiting on their verification screens, as this falls into the host's domain but is critical for protocol security.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Ecto/Postgres is already the standard for Lockspire; no external dependencies needed. |
| Features | HIGH | RFC 8628 is a stable standard with clear requirements. |
| Architecture | HIGH | Polling patterns in Elixir are well-understood. |
| Pitfalls | HIGH | Recent security analyses heavily document Device Code phishing (e.g., Storm-2372). |

## Gaps to Address

- **Rate Limiting Mechanism:** Lockspire relies on the host app for UI. We need to define if Lockspire should provide a built-in rate limiter (e.g., using `Registry` or ETS) or if it relies entirely on the host's existing rate-limiting solution (like `Hammer` or `Rack::Attack` equivalent) to protect the `/verify` endpoint.