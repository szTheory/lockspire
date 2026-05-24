# Phase 61: Shared Private Key JWT Verification - Research

**Researched:** 2026-05-06 [VERIFIED: repo clock]
**Domain:** Shared `private_key_jwt` verification for Lockspire-owned direct-client authentication surfaces [VERIFIED: .planning/ROADMAP.md]
**Confidence:** HIGH [VERIFIED: repo analysis + official specifications]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Source: `.planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md` [VERIFIED: repo file]

- **D-01:** Downstream Phase 61 work should default to **research-first, recommendation-heavy decisions** rather than branching into broad option menus. Escalate only for choices that materially change public API, security posture, or Lockspire’s embedded-library shape.
- **D-02:** For this phase, optimize for **least surprise and truthful shared behavior**. If Lockspire says `private_key_jwt` is supported on a direct-client surface, the same verification contract should apply everywhere that surface reuses `ClientAuth`.
- **D-03:** This phase should favor one coherent architecture over per-endpoint accommodation. The repo should pay a little implementation cleanup cost now to avoid long-term policy drift and support confusion.
- **D-04:** `ClientAuth` should be decomposed into explicit stages: request-shape parsing, tentative client lookup, key resolution, signature verification, verified-claim validation, and replay recording.
- **D-05:** Untrusted JWT payload material may be used only to **tentatively locate a candidate client**. No TTL, audience, or replay decision may be made from an unverified payload.
- **D-06:** Signature verification must happen before any acceptance decision or replay-store write. Invalid or attacker-signed assertions must never poison durable replay state.
- **D-07:** `private_key_jwt` verification should reuse the narrow Phase 60 fetch boundary for remote keys and the repo’s existing JOSE-based verification patterns rather than inventing a second JWT verifier.
- **D-08:** Two-phase replay reservation or speculative durable `jti` reservation is out of scope for Phase 61. It adds complexity and fresh poisoning/race footguns without matching this milestone’s needs.
- **D-09:** Accepted algorithms are derived from Lockspire’s effective security posture through `Lockspire.Protocol.SecurityProfile`; do not add a second algorithm policy plane for client assertions.
- **D-10:** `private_key_jwt` must reject `alg=none`, symmetric algorithms, and any signing algorithms outside the effective allowlist.
- **D-11:** Verified claims must require:
  - `iss` present and equal to `client_id`
  - `sub` present and equal to `client_id`
  - `aud` present and bound to the issuer identifier string
  - `exp` present and valid
  - `iat` or `nbf` present
  - bounded lifetime with a small explicit skew allowance
- **D-12:** Keep the issuer-bound audience rule locked. Do **not** introduce endpoint-URL audience compatibility in Phase 61.
- **D-13:** Replay expiry should follow the **effective acceptance window**, not raw `exp` alone. Store replay entries until verified `exp + skew` so accepted assertions cannot be replayed at the edge of the time window.
- **D-14:** Replay ordering for `private_key_jwt` is: parse enough to identify, fetch client, resolve keys, verify signature, validate trusted claims, then build and persist replay state.
- **D-15:** Replay uniqueness for Phase 61 should be keyed by `{client_id, jti}` and shared across direct-client surfaces. The same assertion must not be reusable across token, PAR, device authorization, token exchange, revocation, introspection, or CIBA backchannel flows.
- **D-16:** Replay-store failures should be **fail-closed**. If durable replay enforcement cannot be trusted, the auth attempt should fail rather than silently degrading into a weaker security mode.
- **D-17:** Phase 61 should preserve durable replay as a Lockspire-owned security guarantee. Do not fall back to in-memory or best-effort replay handling on store failures.
- **D-18:** Public HTTP-facing auth failures for `private_key_jwt` should stay generic: `401 invalid_client` with a generic description such as `Client authentication failed`.
- **D-19:** Detailed failure reasons belong to internal protocol result codes, telemetry, and audit surfaces, not public JSON bodies. Do not expose verifier internals, JWKS transport details, or internal `reason_code` values to external callers.
- **D-20:** Internal `reason_code` values for this slice should be **detailed, stable, and shared** across endpoints so operators and maintainers can reason about failures once instead of per surface.
- **D-21:** Telemetry should capture every failure with redaction-safe metadata. Durable audit should focus on security-significant and client-attributable events, especially replay detection and resolved-client verification failures, to avoid turning hostile traffic into noisy permanent audit spam.
- **D-22:** Keep strong redaction intact: no raw `client_assertion`, parsed payloads, headers, or remote JWKS body material may leak into telemetry, audit metadata, logs, or operator surfaces.
- **D-23:** `ClientAuth` is the single capability source for direct-client authentication across token, PAR, device authorization, token exchange, revocation, introspection, and CIBA backchannel authentication.
- **D-24:** Once real `private_key_jwt` verification ships in `ClientAuth`, every endpoint that already depends on it should accept and enforce that behavior consistently unless there is a documented, protocol-grounded exception.
- **D-25:** Endpoint modules may add checks only for true post-auth semantic differences. They may not duplicate or narrow `private_key_jwt` acceptance with endpoint-local allowlists or parallel auth-method policy.
- **D-26:** Metadata and admin truth must follow effective runtime capability. Do not keep endpoint-specific metadata suppression or extra knobs once runtime support is actually shared.
- **D-27:** Current endpoint-specific drift points should be treated as cleanup targets for this phase, not as design precedent:
  - discovery currently omits `private_key_jwt` from published direct-client auth methods
  - introspection currently narrows successful callers to secret-based confidential clients only
  - CIBA error JSON currently exposes `reason_code`

### Claude's Discretion
Source: `.planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md` [VERIFIED: repo file]

- Exact helper/module names for verification stages and failure-mapping helpers.
- Exact internal `reason_code` taxonomy names, provided they remain stable, specific, and shared.
- Exact skew value and whether it is hard-coded or config-backed, as long as it stays intentionally small and consistent with existing repo posture.
- Whether replay-expiry pruning is handled inside the replay-store write path or by an adjacent helper, provided correctness does not depend on background cleanup timing.

### Deferred Ideas (OUT OF SCOPE)
Source: `.planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md` [VERIFIED: repo file]

- `client_secret_jwt`, mTLS, or other auth-method expansion
- Endpoint-URL audience compatibility knobs or multi-issuer audience variants
- Two-phase replay reservation or distributed replay-coordination refinements beyond the current durable store
- Background JWKS refresh/prefetch scheduling
- New endpoint-specific auth metadata knobs or operator-configurable verifier divergence
- Broader docs and end-to-end closure work reserved for Phase 62
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PKJWT-01 | `Lockspire.Protocol.ClientAuth` performs full cryptographic verification of `client_assertion` signatures using the registered client key material from inline `jwks` or resolved `jwks_uri`. | Shared staged verifier in `ClientAuth`; JOSE multi-key verification; inline/remote key resolution contract [VERIFIED: .planning/REQUIREMENTS.md, lib/lockspire/protocol/client_auth.ex, lib/lockspire/jwks_fetcher.ex, lib/lockspire/protocol/jar.ex] |
| PKJWT-02 | Reject `alg=none`, symmetric algorithms, and unsupported signing algorithms. | Use `SecurityProfile.allowed_signing_algorithms/1` plus JOSE `verify_strict/3`; never add endpoint-local allowlists [VERIFIED: .planning/REQUIREMENTS.md, lib/lockspire/protocol/security_profile.ex, lib/lockspire/protocol/jar.ex][CITED: https://www.rfc-editor.org/rfc/rfc7523] |
| PKJWT-03 | Require `iss=sub=client_id`, valid `exp`, bounded lifetime, and `iat`/`nbf` skew handling. | Reuse JAR-style verified claim validators after signature verification; bind to issuer identifier for `aud` separately [VERIFIED: .planning/REQUIREMENTS.md, lib/lockspire/protocol/jar.ex][CITED: https://www.rfc-editor.org/rfc/rfc7523] |
| PKJWT-04 | Validate `aud` against issuer identifier string. | Use `Config.issuer!()` rather than endpoint URL audiences across all direct-client surfaces [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md][CITED: https://openid.net/wp-content/uploads/2025/01/OIDF-Responsible-Disclosure-Notice-on-Security-Vulnerability-for-private_key_jwt.pdf] |
| PKJWT-05 | Durable `jti` replay protection is recorded only after signature and claim validation succeed. | Mirror DPoP ordering and keep `Repository.record_used_jti/1` as the durable write boundary [VERIFIED: .planning/REQUIREMENTS.md, lib/lockspire/protocol/token_endpoint_dpop.ex, lib/lockspire/protocol/client_auth.ex, test/lockspire/storage/ecto/repository_used_jti_test.exs] |
| PKJWT-06 | Shared direct-client auth seam accepts registered `private_key_jwt` consistently across token, PAR, device authorization, token exchange, revocation, introspection, and CIBA backchannel flows. | Keep `ClientAuth.authenticate/3` as the only verifier; clean up endpoint drift in discovery, introspection, and CIBA JSON [VERIFIED: .planning/REQUIREMENTS.md, lib/lockspire/protocol/pushed_authorization_request.ex, lib/lockspire/protocol/device_authorization.ex, lib/lockspire/protocol/token_exchange.ex, lib/lockspire/protocol/revocation.ex, lib/lockspire/protocol/introspection.ex, lib/lockspire/protocol/backchannel_authentication.ex, lib/lockspire/protocol/discovery.ex, lib/lockspire/web/ciba_authorization_json.ex] |
| OBS-01 | Telemetry, audit, and logs capture failure reasons without leaking assertions or key material. | Emit shared redacted telemetry from `ClientAuth`; reserve durable audit for replay and verified-client security failures; extend redaction denylist for client assertion material [VERIFIED: .planning/REQUIREMENTS.md, lib/lockspire/observability.ex, lib/lockspire/redaction.ex, lib/lockspire/audit/event.ex] |
</phase_requirements>

## Summary

Phase 61 should harden the existing shared seam, not introduce a new auth subsystem. `ClientAuth.authenticate/3` already sits in front of token, PAR, device authorization, token exchange, revocation, introspection, and CIBA, but its current `private_key_jwt` branch only peeks at the JWT payload, checks TTL, and writes replay state before any cryptographic proof exists. That is the exact behavior this phase needs to replace. [VERIFIED: lib/lockspire/protocol/client_auth.ex, lib/lockspire/protocol/pushed_authorization_request.ex, lib/lockspire/protocol/device_authorization.ex, lib/lockspire/protocol/token_exchange.ex, lib/lockspire/protocol/revocation.ex, lib/lockspire/protocol/introspection.ex, lib/lockspire/protocol/backchannel_authentication.ex]

The repo already contains the patterns needed to fix it cleanly. `Lockspire.JwksFetcher` now provides a narrow cached `get_keys/2` plus bounded `refresh_keys/2` contract for `jwks_uri`, `Lockspire.Protocol.Jar` already shows how Lockspire uses `JOSE.JWT.verify_strict/3` and post-verification claim checks, and `Lockspire.Protocol.TokenEndpointDPoP` already demonstrates the correct security ordering of “verify first, record replay second.” Phase 61 should compose those existing seams into one staged verifier and then remove the remaining endpoint drift around discovery, introspection, and CIBA error exposure. [VERIFIED: lib/lockspire/jwks_fetcher.ex, lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/token_endpoint_dpop.ex, lib/lockspire/protocol/discovery.ex, lib/lockspire/protocol/introspection.ex, lib/lockspire/web/ciba_authorization_json.ex]

The main external security rule to preserve is issuer-bound audience validation. RFC 7523 allows the `aud` claim to identify the authorization server, and the OpenID Foundation’s January 2025 disclosure specifically warns against permissive endpoint-based audience matching for `private_key_jwt`; keeping `aud` bound to the issuer string across every `ClientAuth` consumer is the narrowest safe milestone choice. [CITED: https://www.rfc-editor.org/rfc/rfc7523][CITED: https://openid.net/wp-content/uploads/2025/01/OIDF-Responsible-Disclosure-Notice-on-Security-Vulnerability-for-private_key_jwt.pdf]

**Primary recommendation:** Implement one shared `ClientAuth.PrivateKeyJwt` pipeline that performs tentative lookup, inline/remote key resolution, JOSE signature verification, verified-claim validation, and post-verification durable replay recording, then make all current `ClientAuth` consumers inherit that behavior without endpoint-local exceptions. [VERIFIED: lib/lockspire/protocol/client_auth.ex, lib/lockspire/jwks_fetcher.ex, lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/token_endpoint_dpop.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Parse client auth shape and tentatively identify `client_id` | API / Backend | — | All current direct-client surfaces call `ClientAuth.authenticate/3`; request parsing is already backend-owned and should stay centralized there. [VERIFIED: lib/lockspire/protocol/client_auth.ex] |
| Resolve inline `jwks` or remote `jwks_uri` keys | API / Backend | CDN / Static | Remote key retrieval and cache policy are implemented in `Lockspire.JwksFetcher`; no browser or host-app tier owns this security boundary. [VERIFIED: lib/lockspire/jwks_fetcher.ex] |
| Verify JWS signature and algorithm allowlist | API / Backend | — | JOSE verification already happens in backend protocol modules such as `Jar` and DPoP, and the allowed algorithm set comes from server/client security posture. [VERIFIED: lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/dpop.ex, lib/lockspire/protocol/security_profile.ex] |
| Validate verified assertion claims (`iss`, `sub`, `aud`, `exp`, `iat`/`nbf`) | API / Backend | — | Claim validation requires issuer config and must happen only after cryptographic verification, which is backend-only work. [VERIFIED: lib/lockspire/protocol/jar.ex, lib/lockspire/config.ex][CITED: https://www.rfc-editor.org/rfc/rfc7523] |
| Record and enforce durable replay state | Database / Storage | API / Backend | Replay uniqueness already persists via `record_used_jti/1`; backend code decides when to write, storage guarantees cross-request uniqueness. [VERIFIED: lib/lockspire/protocol/client_auth.ex, test/lockspire/storage/ecto/repository_used_jti_test.exs] |
| Emit telemetry, audit, and redaction-safe failure metadata | API / Backend | Database / Storage | `Observability` emits telemetry immediately, while `Audit.Event` normalizes durable audit payloads; both depend on backend-owned reason codes. [VERIFIED: lib/lockspire/observability.ex, lib/lockspire/audit/event.ex, lib/lockspire/redaction.ex] |
| Publish truthful endpoint capability metadata | API / Backend | — | Discovery metadata is assembled centrally in `Lockspire.Protocol.Discovery`; it should follow runtime verifier capability, not endpoint-local toggles. [VERIFIED: lib/lockspire/protocol/discovery.ex] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `jose` | `1.11.12` | JWS/JWT/JWK parsing and strict signature verification | The repo already uses JOSE for JAR, DPoP, logout-token, and key management, so Phase 61 should reuse the same verified crypto primitive instead of introducing another JWT library. [VERIFIED: mix.lock, lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/dpop.ex] |
| `req` | `0.5.17` | Narrow remote JWKS retrieval behind Phase 60 guards | `JwksFetcher` already encapsulates the request policy, timeout budget, and forced refresh path needed for `jwks_uri` key resolution. [VERIFIED: mix.lock, lib/lockspire/jwks_fetcher.ex] |
| `cachex` | `4.1.1` | Cache successful remote JWKS fetches with TTL | The cache is already supervised and Phase 60 chose to harden it in place rather than redesign the substrate. [VERIFIED: mix.lock, lib/lockspire/application.ex, lib/lockspire/jwks_fetcher.ex, .planning/phases/60-guarded-remote-jwks-resolution/60-RESEARCH.md] |
| `Lockspire.Protocol.ClientAuth` | repo internal | Shared direct-client auth seam | Every direct-client surface already converges here, so this is the correct enforcement boundary for shared `private_key_jwt` behavior. [VERIFIED: lib/lockspire/protocol/client_auth.ex, lib/lockspire/protocol/pushed_authorization_request.ex, lib/lockspire/protocol/device_authorization.ex, lib/lockspire/protocol/token_exchange.ex, lib/lockspire/protocol/revocation.ex, lib/lockspire/protocol/introspection.ex, lib/lockspire/protocol/backchannel_authentication.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Lockspire.Protocol.Jar` | repo internal | Existing JOSE verification and verified-claim validation pattern | Reuse its structure and helper style when implementing signature-first client assertion verification, but do not call it directly because it carries JAR-specific `typ` rules and only understands inline `client.jwks`. [VERIFIED: lib/lockspire/protocol/jar.ex] |
| `Lockspire.Protocol.SecurityProfile` | repo internal | Resolve effective allowed signing algorithms | Use it to derive the assertion `alg` allowlist from issuer posture instead of adding a second policy plane. [VERIFIED: lib/lockspire/protocol/security_profile.ex] |
| `Lockspire.Protocol.TokenEndpointDPoP` | repo internal | Ordering precedent for verify-then-record replay | Mirror its ordering and fail-closed replay-store behavior for client assertions. [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex] |
| `Lockspire.Observability` + `Lockspire.Redaction` + `Lockspire.Audit.Event` | repo internal | Shared telemetry, redaction, and durable audit seams | Use these for stable failure taxonomy and redaction-safe metadata instead of endpoint-local logging. [VERIFIED: lib/lockspire/observability.ex, lib/lockspire/redaction.ex, lib/lockspire/audit/event.ex] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared `ClientAuth` verifier | Endpoint-local `private_key_jwt` logic in each protocol module | Rejected because it would recreate the exact drift Phase 61 is supposed to remove and would make metadata truth harder to keep aligned. [VERIFIED: lib/lockspire/protocol/client_auth.ex, .planning/ROADMAP.md] |
| Reusing JOSE patterns already in repo | Adding another JWT verification dependency | Rejected because the repo already standardizes on JOSE and the phase does not need new crypto surface area. [VERIFIED: mix.lock, lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/dpop.ex] |
| Phase 60 `JwksFetcher` contract | Ad hoc remote fetches from `ClientAuth` | Rejected because the fetch safety, cache TTL, and forced refresh semantics are already centralized there. [VERIFIED: lib/lockspire/jwks_fetcher.ex, .planning/phases/60-guarded-remote-jwks-resolution/60-CONTEXT.md] |

**Installation:** No new dependencies are required for Phase 61; use the repo’s pinned `jose`, `req`, and `cachex` versions already present in `mix.lock`. [VERIFIED: mix.lock]

**Version verification:** `mix.lock` currently pins `jose 1.11.12`, `req 0.5.17`, and `cachex 4.1.1`, which are the only external libraries this phase needs beyond the repo’s internal protocol modules. [VERIFIED: mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
HTTP request
  -> endpoint module (`/token`, `/par`, `/device/code`, `/revoke`, `/introspect`, `/bc-authorize`) [VERIFIED: repo routes + protocol modules]
  -> `ClientAuth.authenticate/3` [VERIFIED: protocol consumers]
      -> parse auth shape
      -> tentative client lookup from unverified payload only
      -> registered auth-method check
      -> key resolution
          -> inline `client.jwks`
          -> or `JwksFetcher.get_keys/2`
          -> optional one-time `refresh_keys/2` on key miss/signature mismatch
      -> JOSE signature verification with allowlisted algorithms
      -> verified-claim validation (`iss`, `sub`, `aud`, `exp`, `iat`/`nbf`, max lifetime)
      -> durable replay write `{client_id, jti}` only after verified acceptance
      -> return `%Client{}` or shared `ClientAuth.Error`
  -> endpoint-specific post-auth semantics only
      -> token issuance / PAR persistence / device auth persistence / token introspection / revocation / CIBA
  -> observability + optional audit emission using redacted metadata
```

This is the narrowest architecture that satisfies PKJWT-01..06 while preserving Phase 60’s fetch boundary and the repo’s existing “protocol module owns security behavior” pattern. [VERIFIED: lib/lockspire/protocol/client_auth.ex, lib/lockspire/jwks_fetcher.ex, lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/token_endpoint_dpop.ex]

### Recommended Project Structure

```text
lib/lockspire/protocol/
├── client_auth.ex                     # keep public shared seam here
├── client_auth/
│   ├── private_key_jwt.ex            # staged verifier orchestration
│   ├── private_key_jwt/keys.ex       # inline + remote JWKS normalization / refresh
│   └── private_key_jwt/claims.ex     # verified claim checks and replay payload build
└── discovery.ex                      # runtime metadata truth cleanup

test/lockspire/protocol/
├── client_auth_test.exs              # legacy/mixed auth + secret auth coverage
├── client_auth/private_key_jwt_test.exs
├── introspection_test.exs
├── revocation_test.exs
└── backchannel_authentication_test.exs
```

This split keeps the public seam stable while isolating the new verifier stages into testable helpers instead of growing `client_auth.ex` into one large branchy module. [VERIFIED: lib/lockspire/protocol/client_auth.ex][ASSUMED]

### Pattern 1: Staged Shared Verifier
**What:** Keep `ClientAuth.authenticate/3` as the public entrypoint, but delegate the `:private_key_jwt` branch into an explicit staged pipeline: parse, tentative lookup, key resolution, signature verification, verified claims, replay write. [VERIFIED: .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md, lib/lockspire/protocol/client_auth.ex]
**When to use:** For every direct-client endpoint that already calls `ClientAuth.authenticate/3`; do not fork endpoint-specific JWT verifier logic. [VERIFIED: lib/lockspire/protocol/pushed_authorization_request.ex, lib/lockspire/protocol/device_authorization.ex, lib/lockspire/protocol/token_exchange.ex, lib/lockspire/protocol/revocation.ex, lib/lockspire/protocol/introspection.ex, lib/lockspire/protocol/backchannel_authentication.ex]
**Example:**
```elixir
# Source: repo pattern synthesized from `client_auth.ex`, `jar.ex`, and `token_endpoint_dpop.ex`
with {:ok, parsed} <- PrivateKeyJwt.parse(assertion),
     {:ok, client_id} <- PrivateKeyJwt.peek_client_id(parsed),
     {:ok, client} <- fetch_client(client_id, opts),
     :ok <- validate_registered_auth_method(client, :private_key_jwt),
     {:ok, key_set, resolution} <- PrivateKeyJwt.resolve_keys(client, opts),
     {:ok, verified} <- PrivateKeyJwt.verify_signature(parsed.compact, key_set, client, opts),
     :ok <- PrivateKeyJwt.validate_claims(verified, client, opts),
     :ok <- PrivateKeyJwt.record_replay(verified, client, opts) do
  {:ok, client}
end
```

### Pattern 2: Rotation-Aware Remote Key Retry
**What:** Resolve keys from inline `jwks` first when present; otherwise call `JwksFetcher.get_keys/2`, and if no key matches or every candidate fails signature verification, perform exactly one `refresh_keys/2` retry before returning failure. [VERIFIED: lib/lockspire/jwks_fetcher.ex, .planning/phases/60-guarded-remote-jwks-resolution/60-CONTEXT.md]
**When to use:** Only for `client.jwks_uri` clients in the `private_key_jwt` path; do not call forced refresh on malformed JWTs, unsupported algorithms, or claim-validation failures because rotation cannot fix those. [VERIFIED: lib/lockspire/jwks_fetcher.ex][CITED: https://openid.net/wp-content/uploads/2025/01/OIDF-Responsible-Disclosure-Notice-on-Security-Vulnerability-for-private_key_jwt.pdf]
**Example:**
```elixir
# Source: Phase 60 fetcher contract + Phase 61 verifier recommendation
case JwksFetcher.get_keys(client.jwks_uri, fetcher_opts) do
  {:ok, key_set} ->
    case verify_against_key_set(jwt, key_set, allowed_algs) do
      {:ok, verified} -> {:ok, verified}
      {:error, :no_matching_key} -> retry_with_refresh(jwt, client, allowed_algs, fetcher_opts)
      {:error, :invalid_signature} -> retry_with_refresh(jwt, client, allowed_algs, fetcher_opts)
      other -> other
    end

  {:error, {:jwks_fetch_failed, reason}} ->
    {:error, {:client_assertion_jwks_fetch_failed, reason}}
end
```

### Pattern 3: Generic Public Failure, Detailed Internal Reason
**What:** Keep external OAuth responses at `401 invalid_client` with a generic `"Client authentication failed"` description, but carry a stable internal `reason_code` taxonomy through telemetry and selected audit paths. [VERIFIED: .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md, lib/lockspire/protocol/client_auth.ex]
**When to use:** For every `private_key_jwt` rejection after request-shape parsing, including signature failures, issuer-bound audience mismatches, JWKS refresh failures, and replay detection. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: repo error-struct pattern
%ClientAuth.Error{
  status: 401,
  error: "invalid_client",
  error_description: "Client authentication failed",
  reason_code: :client_assertion_aud_invalid
}
```

### Anti-Patterns to Avoid
- **Pre-verification replay writes:** The current `ClientAuth` branch records `jti` before any signature verification; keep that ordering nowhere in the new pipeline. [VERIFIED: lib/lockspire/protocol/client_auth.ex]
- **Endpoint-specific caller narrowing after shared auth:** `Introspection` currently accepts auth through `ClientAuth` and then discards non-secret confidential callers, which would silently suppress newly shared `private_key_jwt` support. [VERIFIED: lib/lockspire/protocol/introspection.ex]
- **Preserving metadata suppression after runtime support lands:** `Discovery` still removes `private_key_jwt` from published direct-client auth methods; that becomes incorrect once Phase 61 ships. [VERIFIED: lib/lockspire/protocol/discovery.ex]
- **Leaking internal verifier detail in public JSON:** `Lockspire.Web.CibaAuthorizationJSON` currently serializes `reason_code`; Phase 61 should stop extending that pattern to client-auth failures and should likely remove this exposure for CIBA auth errors as part of the shared cleanup. [VERIFIED: lib/lockspire/web/ciba_authorization_json.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JWS verification and algorithm enforcement | Manual JWT parsing plus ad hoc signature checks | `JOSE.JWT.verify_strict/3` with repo-style multi-key iteration | JOSE already backs JAR and DPoP verification in the repo and rejects algorithms outside the explicit allowlist. [VERIFIED: lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/dpop.ex] |
| Remote `jwks_uri` retrieval and refresh | New HTTP code in `ClientAuth` | `Lockspire.JwksFetcher.get_keys/2` and `refresh_keys/2` | Phase 60 already codified HTTPS-only fetch policy, target safety, payload cap, cache TTL, and bounded refresh semantics there. [VERIFIED: lib/lockspire/jwks_fetcher.ex, .planning/phases/60-guarded-remote-jwks-resolution/60-RESEARCH.md] |
| Verified claim validation | One-off per-endpoint checks | Shared `private_key_jwt` claim validator modeled after `Jar.validate_claims/2` | It keeps the same semantics everywhere and prevents endpoint-local drift on `aud`, `exp`, `iat`, or `nbf`. [VERIFIED: lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/client_auth.ex][CITED: https://www.rfc-editor.org/rfc/rfc7523] |
| Replay uniqueness | In-memory `MapSet` or endpoint-local cache | Existing durable `record_used_jti/1` store keyed by `{client_id, jti}` | The repo already tests durable replay behavior across repository calls and across clients. [VERIFIED: test/lockspire/storage/ecto/repository_used_jti_test.exs] |
| Telemetry/audit redaction | Endpoint-local logger redaction lists | `Observability`, `Redaction`, and `Audit.Event.normalize/1` | The repo already centralizes safe metadata handling there; extend the denylist for client assertion material once, not per endpoint. [VERIFIED: lib/lockspire/observability.ex, lib/lockspire/redaction.ex, lib/lockspire/audit/event.ex] |

**Key insight:** Phase 61 is mostly a composition task across existing Lockspire seams. The expensive mistake would be creating a second JWT verifier, a second fetch path, or endpoint-local auth behavior that the repo then has to keep in sync forever. [VERIFIED: repo analysis]

## Common Pitfalls

### Pitfall 1: Trusting unverified payload claims
**What goes wrong:** TTL, audience, or replay decisions get made from a payload that was only base64-decoded, not signature-verified. [VERIFIED: lib/lockspire/protocol/client_auth.ex]
**Why it happens:** The current implementation uses the unverified payload both to enforce TTL and to record replay state. [VERIFIED: lib/lockspire/protocol/client_auth.ex]
**How to avoid:** Allow unverified payload access only for tentative `client_id` lookup; every other security decision must happen on verified claims. [VERIFIED: .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md]
**Warning signs:** A helper named like `validate_jwt_ttl/1` or `validate_jwt_replay/3` still accepts a raw decoded payload map rather than a verified assertion struct. [VERIFIED: lib/lockspire/protocol/client_auth.ex]

### Pitfall 2: Refreshing remote JWKS too broadly
**What goes wrong:** Every malformed assertion or disallowed algorithm triggers an outbound refresh, amplifying hostile traffic into avoidable network work. [VERIFIED: Phase 60 fetch contract + verifier design reasoning]
**Why it happens:** “Refresh on any failure” is easier to implement than distinguishing key-rotation recoverable failures from structural failures. [ASSUMED]
**How to avoid:** Only call `refresh_keys/2` on key miss or signature mismatch after an otherwise well-formed JWT reaches the verification stage. [VERIFIED: lib/lockspire/jwks_fetcher.ex][ASSUMED]
**Warning signs:** Refresh is triggered from a generic `rescue` branch or from claim-validation failures like `aud` mismatch or expired token. [ASSUMED]

### Pitfall 3: Shared verifier ships, endpoint drift remains
**What goes wrong:** Token and PAR accept `private_key_jwt`, but discovery still suppresses it, introspection still rejects those callers, or CIBA still leaks internal reasons publicly. [VERIFIED: lib/lockspire/protocol/discovery.ex, lib/lockspire/protocol/introspection.ex, lib/lockspire/web/ciba_authorization_json.ex]
**Why it happens:** The endpoint modules already have small post-auth behavior branches that predate full shared verification. [VERIFIED: lib/lockspire/protocol/introspection.ex, lib/lockspire/protocol/discovery.ex]
**How to avoid:** Treat those modules as explicit cleanup targets in Phase 61 rather than assuming the shared `ClientAuth` refactor alone completes the phase. [VERIFIED: .planning/ROADMAP.md]
**Warning signs:** New tests pass in `ClientAuth`, but discovery, introspection, or CIBA controller tests still pin old behavior around method suppression or `reason_code` leakage. [VERIFIED: test/lockspire/web/discovery_controller_test.exs, lib/lockspire/web/ciba_authorization_json.ex]

### Pitfall 4: Public error contract exposes internal verifier taxonomy
**What goes wrong:** Operators get useful reason codes, but callers also learn which part of verification failed, creating support inconsistency and unnecessary attack feedback. [CITED: https://www.rfc-editor.org/rfc/rfc7523]
**Why it happens:** Error structs in the repo commonly carry `reason_code`, and one JSON serializer already emits it for CIBA. [VERIFIED: lib/lockspire/web/ciba_authorization_json.ex, lib/lockspire/protocol/client_auth.ex]
**How to avoid:** Keep `reason_code` internal to telemetry/audit and return generic `invalid_client` payloads from every HTTP-facing endpoint that reuses `ClientAuth`. [VERIFIED: .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md]
**Warning signs:** Controller JSON tests assert `reason_code` for client-auth failures or new serializers mirror `CibaAuthorizationJSON.error_response/1`. [VERIFIED: lib/lockspire/web/ciba_authorization_json.ex]

## Code Examples

Verified patterns from official sources and current repo structure:

### Multi-key JOSE signature verification
```elixir
# Source: https://hexdocs.pm/jose/JOSE.JWT.html + repo usage in `lib/lockspire/protocol/jar.ex`
case JOSE.JWT.verify_strict(public_jwk, allowed_algorithms, jwt) do
  {true, %JOSE.JWT{} = jwt_struct, %JOSE.JWS{} = jws_struct} ->
    {_modules, claims} = JOSE.JWT.to_map(jwt_struct)
    {_modules, header} = JOSE.JWS.to_map(jws_struct)
    {:ok, %{claims: claims, header: header}}

  {false, _jwt_struct, _jws_struct} ->
    {:error, :invalid_signature}
end
```

### Verified claim validation shape
```elixir
# Source: repo pattern in `lib/lockspire/protocol/jar.ex` + RFC 7523 claim rules
with :ok <- check_issuer(claims, client.client_id),
     :ok <- check_subject(claims, client.client_id),
     :ok <- check_audience(claims, issuer),
     :ok <- check_expiration(claims, now, leeway, max_age),
     :ok <- check_not_before(claims, now, leeway),
     :ok <- check_issued_at(claims, now, leeway),
     :ok <- check_jti(claims) do
  :ok
end
```

### Replay-after-verification ordering
```elixir
# Source: repo ordering precedent in `lib/lockspire/protocol/token_endpoint_dpop.ex`
with {:ok, verified} <- verify_signature(jwt, key_set, allowed_algorithms),
     :ok <- validate_claims(verified, client, opts),
     {:ok, used_jti} <- build_used_jti(verified, client, opts),
     {:ok, :accepted} <- store.record_used_jti(used_jti) do
  {:ok, client}
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Endpoint-specific or permissive audience matching for `private_key_jwt` | Issuer-bound audience validation across all direct-client surfaces | The OpenID Foundation published the January 2025 disclosure on multi-endpoint audience confusion for `private_key_jwt`. [CITED: https://openid.net/wp-content/uploads/2025/01/OIDF-Responsible-Disclosure-Notice-on-Security-Vulnerability-for-private_key_jwt.pdf] | It makes a single issuer audience string the safest Lockspire-wide rule and argues against endpoint-URL compatibility knobs in this milestone. [CITED: https://openid.net/wp-content/uploads/2025/01/OIDF-Responsible-Disclosure-Notice-on-Security-Vulnerability-for-private_key_jwt.pdf] |
| Payload-shape “validation” before cryptographic proof | Signature-first verification followed by verified-claim checks | This is already the pattern in Lockspire’s JAR and DPoP code paths. [VERIFIED: lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/dpop.ex] | Phase 61 should bring `ClientAuth` into alignment with the repo’s stronger existing security pattern. [VERIFIED: lib/lockspire/protocol/client_auth.ex, lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/dpop.ex] |
| Per-endpoint capability drift in metadata | Runtime-truth metadata backed by one shared verifier capability | Phase 59 already locked this direction for discovery/admin truth. [VERIFIED: .planning/phases/59-registration-policy-metadata-truth/59-CONTEXT.md] | Discovery, introspection, and CIBA should be cleaned up in the same phase that runtime support actually lands. [VERIFIED: lib/lockspire/protocol/discovery.ex, lib/lockspire/protocol/introspection.ex, lib/lockspire/web/ciba_authorization_json.ex] |

**Deprecated/outdated:**
- Decoding a `client_assertion` payload and treating its `exp`, `iat`/`nbf`, and `jti` as trustworthy before verifying the signature is the current repo behavior but it is no longer acceptable once `private_key_jwt` is advertised as supported. [VERIFIED: lib/lockspire/protocol/client_auth.ex]
- Publishing discovery metadata that suppresses `private_key_jwt` after runtime verification ships would be outdated Phase 59 transitional behavior, not the correct steady state for Phase 61. [VERIFIED: lib/lockspire/protocol/discovery.ex, .planning/phases/59-registration-policy-metadata-truth/59-CONTEXT.md]

## Plan-Shaping Recommendations

### 61-01: Split `ClientAuth` into lookup, key resolution, signature verification, and claims validation stages
- Keep `ClientAuth.authenticate/3` as the stable public seam and move only the `:private_key_jwt` branch into a dedicated staged helper. [VERIFIED: lib/lockspire/protocol/client_auth.ex]
- Introduce a small verified assertion struct carrying `claims`, `header`, `client_id`, `jti`, `expires_at`, and whether remote refresh was used; downstream stages should never pass raw payload maps around once verification succeeds. [ASSUMED]
- Reuse `Jar`’s JOSE verification loop style and `TokenEndpointDPoP`’s replay ordering rather than extracting a generic cross-protocol JWT framework in this phase. [VERIFIED: lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/token_endpoint_dpop.ex]
- Leave `client_secret_basic`, `client_secret_post`, and `none` paths behaviorally unchanged except for shared error-shape cleanup if the refactor naturally improves it. [VERIFIED: lib/lockspire/protocol/client_auth.ex]

### 61-02: Enforce issuer-bound audience, algorithm allowlists, TTL/skew, and replay ordering
- Use `SecurityProfile.allowed_signing_algorithms/1` as the only source of allowed assertion algorithms and reject any `alg` outside that set, including `none` and symmetric values. [VERIFIED: lib/lockspire/protocol/security_profile.ex][CITED: https://www.rfc-editor.org/rfc/rfc7523]
- Validate `iss == client_id`, `sub == client_id`, `aud` contains exactly the issuer string, `exp` is present and unexpired, one of `iat` or `nbf` is present, and `exp - (iat || nbf)` stays within the existing 10-minute ceiling already encoded in the current repo behavior, using a shared 30-second skew allowance aligned with DPoP’s current repo default. [VERIFIED: lib/lockspire/protocol/client_auth.ex, lib/lockspire/protocol/token_endpoint_dpop.ex][CITED: https://www.rfc-editor.org/rfc/rfc7523]
- Record `UsedJti` only after signature and claims succeed, and persist replay entries until the effective acceptance window closes rather than raw `exp` alone. [VERIFIED: lib/lockspire/protocol/client_auth.ex, test/lockspire/storage/ecto/repository_used_jti_test.exs, .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md]
- Treat replay-store failure as `invalid_client` internally keyed to a distinct stable reason code; do not degrade to best-effort replay handling. [VERIFIED: .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md]

### 61-03: Wire verified `private_key_jwt` behavior across token-adjacent direct-client endpoints
- Expect token, PAR, device authorization, token exchange, revocation, and backchannel authentication to inherit the new behavior automatically because they already call `ClientAuth.authenticate/3`. [VERIFIED: lib/lockspire/protocol/pushed_authorization_request.ex, lib/lockspire/protocol/device_authorization.ex, lib/lockspire/protocol/token_exchange.ex, lib/lockspire/protocol/revocation.ex, lib/lockspire/protocol/backchannel_authentication.ex]
- Update `Introspection.validate_confidential_caller/1` so confidential `private_key_jwt` clients are treated as valid successful callers rather than silently collapsed to `active: false`. [VERIFIED: lib/lockspire/protocol/introspection.ex]
- Update `Discovery.published_direct_client_auth_methods/0` and associated endpoint metadata logic so `private_key_jwt` is published once runtime support becomes real, including signing-alg metadata for token, revocation, and introspection when mounted. [VERIFIED: lib/lockspire/protocol/discovery.ex]
- Remove CIBA public `reason_code` exposure for shared client-auth failures so the endpoint does not remain the odd public-contract exception after Phase 61. [VERIFIED: lib/lockspire/web/ciba_authorization_json.ex]

### 61-04: Telemetry, audit, and redaction proof for auth failures and replay outcomes
- Emit shared `Observability.emit/4` failures from the `ClientAuth` seam with stable redacted metadata such as `client_id`, auth method, resolution source (`:jwks` vs `:jwks_uri`), refresh-used flag, and stable `reason_code`, but never raw assertion content. [VERIFIED: lib/lockspire/observability.ex, lib/lockspire/redaction.ex][ASSUMED]
- Extend `Redaction` drop lists to include `client_assertion`, `client_assertion_type`, JWT headers, and any remote JWKS material that might otherwise be logged or embedded in metadata. [VERIFIED: lib/lockspire/redaction.ex][ASSUMED]
- Persist durable audit only for security-significant events with an attributable client, especially replay detected, replay store failed, JWKS fetch failed after client resolution, and verified-client signature/claim failures that matter operationally. [VERIFIED: .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md][ASSUMED]
- Add explicit regression tests proving that HTTP JSON bodies stay generic while telemetry/audit receive the richer reason taxonomy. [VERIFIED: .planning/REQUIREMENTS.md, lib/lockspire/web/ciba_authorization_json.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Splitting the `private_key_jwt` path into `client_auth/private_key_jwt*.ex` helper modules is the cleanest file layout, while keeping `ClientAuth.authenticate/3` stable. | Architecture Patterns | Low; the planner can keep everything inside `client_auth.ex` if maintainers prefer fewer files. |
| A2 | A dedicated verified assertion struct carrying normalized replay data will make the staged pipeline clearer than passing raw maps. | Plan-Shaping Recommendations | Low; the implementation can use plain maps if testability stays strong. |
| A3 | Only key miss and signature mismatch should trigger `refresh_keys/2`; malformed JWTs and claim failures should not. | Common Pitfalls / Pattern 2 | Medium; if future rotation behavior shows another recoverable failure mode, the retry trigger list may need expansion. |
| A4 | Redaction should explicitly add `client_assertion`, `client_assertion_type`, and JWT header material to the denylist. | 61-04 | Low; the exact key names may differ, but the security requirement remains. |
| A5 | Durable audit should be selective rather than logging every malformed client assertion attempt. | 61-04 | Medium; if maintainers want a denser audit trail, the plan may need to widen audit coverage and storage expectations. |

## Open Questions (RESOLVED)

1. **Clock-skew allowance for `private_key_jwt`**
   - Resolution: Reuse DPoP’s current 30-second skew budget as the Phase 61 shared verifier default, implemented once inside the shared `ClientAuth` verifier path rather than as endpoint-local knobs. [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex, .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md]
   - Why this resolves the question: the repo already treats 30 seconds as a small, explicit skew allowance for proof-style JWT validation, and Phase 61 only needs one coherent verifier-wide default rather than a new configurable policy surface. [VERIFIED: lib/lockspire/protocol/token_endpoint_dpop.ex, .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md]
   - Planning impact: the verifier and replay-expiry logic should use the same 30-second skew when evaluating `exp`, `iat`/`nbf`, and `exp + skew` replay retention. [VERIFIED: .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Protocol implementation and ExUnit validation | ✓ | `1.19.5` | — [VERIFIED: local `elixir --version`] |
| Mix | Running targeted and full test commands | ✓ | `1.19.5` | — [VERIFIED: local `mix --version`] |
| ExUnit + Ecto sandbox test setup | Unit and integration proof | ✓ | repo-managed | — [VERIFIED: test/test_helper.exs, test suite layout, mix.exs] |

**Missing dependencies with no fallback:** None identified for planning Phase 61 implementation in this workspace. [VERIFIED: local environment audit]

**Missing dependencies with fallback:** None identified. [VERIFIED: local environment audit]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL sandbox-backed repo tests [VERIFIED: test/test_helper.exs, test suite patterns] |
| Config file | `test/test_helper.exs` [VERIFIED: repo file] |
| Quick run command | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/client_auth_test.exs test/lockspire/storage/ecto/repository_used_jti_test.exs` [VERIFIED: repo test layout] |
| Full suite command | `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs alias] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PKJWT-01 | Signature verification works for inline `jwks` and remote `jwks_uri` | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/client_auth/private_key_jwt_test.exs` | ❌ Wave 0 [VERIFIED: repo file absence] |
| PKJWT-02 | Disallowed algorithms, `alg=none`, and symmetric algs fail closed | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/client_auth/private_key_jwt_test.exs` | ❌ Wave 0 [VERIFIED: repo file absence][CITED: https://www.rfc-editor.org/rfc/rfc7523] |
| PKJWT-03 | `iss`, `sub`, `aud`, `exp`, `iat`/`nbf`, and max lifetime are enforced after verification | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/client_auth/private_key_jwt_test.exs` | ❌ Wave 0 [VERIFIED: repo file absence] |
| PKJWT-04 | Issuer-bound `aud` is enforced consistently | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/client_auth/private_key_jwt_test.exs test/lockspire/web/discovery_controller_test.exs` | ❌ / ✅ mixed [VERIFIED: repo files] |
| PKJWT-05 | Replay is recorded only after verified acceptance and durable duplicates are rejected | unit + integration | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/client_auth/private_key_jwt_test.exs test/lockspire/storage/ecto/repository_used_jti_test.exs` | ❌ / ✅ mixed [VERIFIED: repo files] |
| PKJWT-06 | All `ClientAuth` consumers accept the same `private_key_jwt` behavior | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/pushed_authorization_request_test.exs test/lockspire/protocol/device_authorization_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/protocol/backchannel_authentication_test.exs` | ✅ / ✅ / ✅ / ✅ / ✅ [VERIFIED: repo files] |
| OBS-01 | Public failures stay generic while telemetry/audit capture stable internal reasons with redaction | unit | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/client_auth/private_key_jwt_test.exs test/lockspire/redaction/redaction_test.exs test/lockspire/audit/audit_writer_test.exs` | ❌ / ✅ / ✅ mixed [VERIFIED: repo files] |

### Sampling Rate
- **Per task commit:** `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/client_auth/private_key_jwt_test.exs` once that file exists; until then use the existing `client_auth_test.exs` plus any touched endpoint tests. [VERIFIED: repo test layout][ASSUMED]
- **Per wave merge:** `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/client_auth_test.exs test/lockspire/storage/ecto/repository_used_jti_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/protocol/revocation_test.exs test/lockspire/protocol/backchannel_authentication_test.exs test/lockspire/web/discovery_controller_test.exs` [VERIFIED: repo files]
- **Phase gate:** `MIX_ENV=test mix test.fast` plus the new focused `private_key_jwt` verifier test file green before `/gsd-verify-work`. [VERIFIED: mix.exs alias][ASSUMED]

### Wave 0 Gaps
- [ ] `test/lockspire/protocol/client_auth/private_key_jwt_test.exs` — missing focused cryptographic verifier coverage for PKJWT-01..05. [VERIFIED: repo file absence]
- [ ] Extend `test/lockspire/protocol/introspection_test.exs` — add successful confidential `private_key_jwt` caller cases and negative-path consistency checks for PKJWT-06. [VERIFIED: repo test inventory]
- [ ] Extend `test/lockspire/protocol/discovery_test.exs` and `test/lockspire/web/discovery_controller_test.exs` — replace Phase 59 suppression assertions with runtime-truth assertions once shared support lands. [VERIFIED: test/lockspire/protocol/discovery_test.exs, test/lockspire/web/discovery_controller_test.exs]
- [ ] Extend `test/lockspire/protocol/backchannel_authentication_test.exs` and add `test/lockspire/web/ciba_authorization_json_test.exs` or equivalent — prove generic public error bodies with no `reason_code` leak for shared client-auth failures. [VERIFIED: test/lockspire/protocol/backchannel_authentication_test.exs, lib/lockspire/web/ciba_authorization_json.ex][ASSUMED]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Shared `ClientAuth` verifier with JOSE signature validation and confidential-client method enforcement. [VERIFIED: lib/lockspire/protocol/client_auth.ex, lib/lockspire/protocol/jar.ex] |
| V3 Session Management | no | Not a session-management phase; this work is direct client authentication, not end-user session state. [VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | yes | Introspection caller gating and endpoint capability truth depend on correct confidential client authentication. [VERIFIED: lib/lockspire/protocol/introspection.ex, lib/lockspire/protocol/discovery.ex] |
| V5 Input Validation | yes | JWT structure parsing, claim typing, `aud`/`iss`/`sub` checks, and bounded lifetime validation are all explicit input-validation work. [VERIFIED: lib/lockspire/protocol/client_auth.ex, lib/lockspire/protocol/jar.ex][CITED: https://www.rfc-editor.org/rfc/rfc7523] |
| V6 Cryptography | yes | `private_key_jwt` depends on asymmetric key resolution, allowed algorithm enforcement, and JOSE-based signature verification; no custom crypto should be added. [VERIFIED: lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/security_profile.ex] |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unsigned or attacker-signed assertion accepted as valid | Spoofing | `JOSE.JWT.verify_strict/3` with a posture-derived asymmetric allowlist and no `alg=none`. [VERIFIED: lib/lockspire/protocol/jar.ex, lib/lockspire/protocol/security_profile.ex][CITED: https://www.rfc-editor.org/rfc/rfc7523] |
| Audience confusion across token/PAR/revocation/introspection/CIBA | Spoofing | Validate `aud` against the issuer identifier string everywhere rather than endpoint URLs. [VERIFIED: .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md][CITED: https://openid.net/wp-content/uploads/2025/01/OIDF-Responsible-Disclosure-Notice-on-Security-Vulnerability-for-private_key_jwt.pdf] |
| Replay-store poisoning with invalid assertions | Tampering / DoS | Record `{client_id, jti}` only after signature and claim verification succeed; fail closed on store errors. [VERIFIED: lib/lockspire/protocol/client_auth.ex, .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md] |
| Remote key rotation causes false negatives | Denial of Service | Use Phase 60 `refresh_keys/2` exactly once on key miss or signature mismatch while preserving last-known-good cache state on refresh failure. [VERIFIED: lib/lockspire/jwks_fetcher.ex] |
| Internal verifier detail leaks to callers | Information Disclosure | Keep HTTP `invalid_client` responses generic and route detailed `reason_code` only to telemetry/audit. [VERIFIED: .planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md, lib/lockspire/web/ciba_authorization_json.ex] |

## Sources

### Primary (HIGH confidence)
- `.planning/REQUIREMENTS.md` - Phase 61 requirement definitions (`PKJWT-01`..`PKJWT-06`, `OBS-01`). [VERIFIED: repo file]
- `.planning/ROADMAP.md` - Phase goal, roadmap plans `61-01`..`61-04`, and success criteria. [VERIFIED: repo file]
- `.planning/phases/61-shared-private-key-jwt-verification/61-CONTEXT.md` - locked implementation decisions and out-of-scope boundaries. [VERIFIED: repo file]
- `lib/lockspire/protocol/client_auth.ex` - current incomplete `private_key_jwt` path and public error shape. [VERIFIED: repo file]
- `lib/lockspire/jwks_fetcher.ex` - Phase 60 fetch/refresh contract reused by Phase 61. [VERIFIED: repo file]
- `lib/lockspire/protocol/jar.ex` - existing JOSE verification and claim-validation pattern. [VERIFIED: repo file]
- `lib/lockspire/protocol/token_endpoint_dpop.ex` - replay-after-verification ordering precedent. [VERIFIED: repo file]
- `lib/lockspire/protocol/security_profile.ex` - effective signing algorithm allowlists. [VERIFIED: repo file]
- `lib/lockspire/protocol/discovery.ex` - current metadata suppression drift. [VERIFIED: repo file]
- `lib/lockspire/protocol/introspection.ex` - current secret-only post-auth narrowing drift. [VERIFIED: repo file]
- `lib/lockspire/web/ciba_authorization_json.ex` - current public `reason_code` leakage. [VERIFIED: repo file]
- `test/lockspire/protocol/client_auth_test.exs` - current replay/TTL-only proof shape. [VERIFIED: repo file]
- `test/lockspire/storage/ecto/repository_used_jti_test.exs` - durable replay uniqueness proof. [VERIFIED: repo file]
- RFC 7523 - JWT Bearer Token Profiles; client assertion claim semantics and invalid-client behavior. [CITED: https://www.rfc-editor.org/rfc/rfc7523]
- OpenID Foundation disclosure notice (January 2025) - issuer-bound audience hardening guidance for `private_key_jwt`. [CITED: https://openid.net/wp-content/uploads/2025/01/OIDF-Responsible-Disclosure-Notice-on-Security-Vulnerability-for-private_key_jwt.pdf]
- JOSE HexDocs - `JOSE.JWT.verify_strict/3` API behavior used by repo patterns. [CITED: https://hexdocs.pm/jose/JOSE.JWT.html]

### Secondary (MEDIUM confidence)
- `mix.lock` - pinned versions for `jose`, `req`, and `cachex`. [VERIFIED: repo file]
- Local environment audit (`elixir --version`, `mix --version`) - execution prerequisites available in workspace. [VERIFIED: local commands]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no new dependency choice is needed; the repo already standardizes on JOSE, Req, Cachex, and shared protocol modules. [VERIFIED: mix.lock, repo analysis]
- Architecture: HIGH - the direct-client endpoints already converge on `ClientAuth`, and the repo already contains matching JOSE and replay-ordering patterns to reuse. [VERIFIED: repo analysis]
- Pitfalls: HIGH - each listed pitfall is grounded in current repo code or locked Phase 61 decisions, not general ecosystem folklore. [VERIFIED: repo analysis]

**Research date:** 2026-05-06 [VERIFIED: repo clock]
**Valid until:** 2026-06-05 for repo-shape findings; recheck the external audience-hardening guidance if implementation starts after that date. [VERIFIED: repo analysis][CITED: https://openid.net/wp-content/uploads/2025/01/OIDF-Responsible-Disclosure-Notice-on-Security-Vulnerability-for-private_key_jwt.pdf]

## RESEARCH COMPLETE
