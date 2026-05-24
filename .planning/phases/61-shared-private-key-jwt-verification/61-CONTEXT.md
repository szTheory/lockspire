# Phase 61: Shared Private Key JWT Verification - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 61 turns `private_key_jwt` from payload-shape validation into real shared client authentication across Lockspire-owned direct-client surfaces. The phase covers key resolution, signature verification, claim validation, replay ordering, failure observability, and consistent endpoint behavior through the shared `ClientAuth` seam.

This phase does **not** broaden into new client-auth methods, multi-issuer compatibility knobs, background JWKS jobs, endpoint-specific auth policy planes, or milestone-close docs/end-to-end closure work from Phase 62.

</domain>

<decisions>
## Implementation Decisions

### Decisioning posture

- **D-01:** Downstream Phase 61 work should default to **research-first, recommendation-heavy decisions** rather than branching into broad option menus. Escalate only for choices that materially change public API, security posture, or Lockspire’s embedded-library shape.
- **D-02:** For this phase, optimize for **least surprise and truthful shared behavior**. If Lockspire says `private_key_jwt` is supported on a direct-client surface, the same verification contract should apply everywhere that surface reuses `ClientAuth`.
- **D-03:** This phase should favor one coherent architecture over per-endpoint accommodation. The repo should pay a little implementation cleanup cost now to avoid long-term policy drift and support confusion.

### Verification pipeline shape

- **D-04:** `ClientAuth` should be decomposed into explicit stages: request-shape parsing, tentative client lookup, key resolution, signature verification, verified-claim validation, and replay recording.
- **D-05:** Untrusted JWT payload material may be used only to **tentatively locate a candidate client**. No TTL, audience, or replay decision may be made from an unverified payload.
- **D-06:** Signature verification must happen before any acceptance decision or replay-store write. Invalid or attacker-signed assertions must never poison durable replay state.
- **D-07:** `private_key_jwt` verification should reuse the narrow Phase 60 fetch boundary for remote keys and the repo’s existing JOSE-based verification patterns rather than inventing a second JWT verifier.
- **D-08:** Two-phase replay reservation or speculative durable `jti` reservation is out of scope for Phase 61. It adds complexity and fresh poisoning/race footguns without matching this milestone’s needs.

### Algorithm and claim validation

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

### Replay contract

- **D-14:** Replay ordering for `private_key_jwt` is: parse enough to identify, fetch client, resolve keys, verify signature, validate trusted claims, then build and persist replay state.
- **D-15:** Replay uniqueness for Phase 61 should be keyed by `{client_id, jti}` and shared across direct-client surfaces. The same assertion must not be reusable across token, PAR, device authorization, token exchange, revocation, introspection, or CIBA backchannel flows.
- **D-16:** Replay-store failures should be **fail-closed**. If durable replay enforcement cannot be trusted, the auth attempt should fail rather than silently degrading into a weaker security mode.
- **D-17:** Phase 61 should preserve durable replay as a Lockspire-owned security guarantee. Do not fall back to in-memory or best-effort replay handling on store failures.

### Failure visibility and observability

- **D-18:** Public HTTP-facing auth failures for `private_key_jwt` should stay generic: `401 invalid_client` with a generic description such as `Client authentication failed`.
- **D-19:** Detailed failure reasons belong to internal protocol result codes, telemetry, and audit surfaces, not public JSON bodies. Do not expose verifier internals, JWKS transport details, or internal `reason_code` values to external callers.
- **D-20:** Internal `reason_code` values for this slice should be **detailed, stable, and shared** across endpoints so operators and maintainers can reason about failures once instead of per surface.
- **D-21:** Telemetry should capture every failure with redaction-safe metadata. Durable audit should focus on security-significant and client-attributable events, especially replay detection and resolved-client verification failures, to avoid turning hostile traffic into noisy permanent audit spam.
- **D-22:** Keep strong redaction intact: no raw `client_assertion`, parsed payloads, headers, or remote JWKS body material may leak into telemetry, audit metadata, logs, or operator surfaces.

### Shared endpoint rollout

- **D-23:** `ClientAuth` is the single capability source for direct-client authentication across token, PAR, device authorization, token exchange, revocation, introspection, and CIBA backchannel authentication.
- **D-24:** Once real `private_key_jwt` verification ships in `ClientAuth`, every endpoint that already depends on it should accept and enforce that behavior consistently unless there is a documented, protocol-grounded exception.
- **D-25:** Endpoint modules may add checks only for true post-auth semantic differences. They may not duplicate or narrow `private_key_jwt` acceptance with endpoint-local allowlists or parallel auth-method policy.
- **D-26:** Metadata and admin truth must follow effective runtime capability. Do not keep endpoint-specific metadata suppression or extra knobs once runtime support is actually shared.
- **D-27:** Current endpoint-specific drift points should be treated as cleanup targets for this phase, not as design precedent:
  - discovery currently omits `private_key_jwt` from published direct-client auth methods
  - introspection currently narrows successful callers to secret-based confidential clients only
  - CIBA error JSON currently exposes `reason_code`

### the agent's Discretion

- Exact helper/module names for verification stages and failure-mapping helpers.
- Exact internal `reason_code` taxonomy names, provided they remain stable, specific, and shared.
- Exact skew value and whether it is hard-coded or config-backed, as long as it stays intentionally small and consistent with existing repo posture.
- Whether replay-expiry pruning is handled inside the replay-store write path or by an adjacent helper, provided correctness does not depend on background cleanup timing.

</decisions>

<specifics>
## Specific Ideas

- The coherent recommendation bundle for Phase 61 is:
  - generic external `invalid_client` responses,
  - detailed internal observability and audit reasons,
  - post-verification replay recording only,
  - issuer-bound audience only,
  - strict shared rollout across all direct-client surfaces using `ClientAuth`.
- This aligns with the strongest ecosystem lessons:
  - mature servers keep client-auth HTTP failures externally stable while evolving internal verifier policy,
  - successful auth systems centralize advanced auth in one verifier seam instead of per-endpoint logic,
  - the recurring footguns are endpoint-based audience acceptance, pre-verification replay writes, metadata/runtime drift, and operator-visible error overexposure.
- The repo already has nearby patterns worth reusing:
  - `Lockspire.Protocol.Jar` provides a signature-then-claims structure worth echoing,
  - DPoP replay handling already models “verify first, record replay second,”
  - `Observability`, `Redaction`, and `Audit.Event` already provide the right internal visibility seams.
- Shift-left preference for GSD downstream work:
  - researchers and planners should treat the recommendation bundle above as the default path,
  - do not reopen medium-value branches during planning,
  - escalate only if implementation would otherwise alter public error contracts, security guarantees, or embedded-library boundaries.
- Great DX for this phase means:
  - one verifier contract across endpoints,
  - one clear failure story for integrators,
  - one stable reason taxonomy for operators,
  - one predictable policy source for algorithms and audience rules.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Lockspire planning artifacts
- `.planning/PROJECT.md` — v1.15 goal, embedded-library boundary, and current milestone posture
- `.planning/REQUIREMENTS.md` — `PKJWT-01` through `PKJWT-06`, `OBS-01`
- `.planning/ROADMAP.md` — Phase 61 goal, plans, and success criteria
- `.planning/STATE.md` — current milestone position and next action
- `.planning/research/SUMMARY.md` — milestone-wide recommendation to keep `jwks_uri` + `private_key_jwt` narrow and issuer-audience-bound
- `.planning/phases/59-registration-policy-metadata-truth/59-CONTEXT.md` — registration, metadata truth, algorithm-policy, and issuer-audience carry-forward rules
- `.planning/phases/60-guarded-remote-jwks-resolution/60-CONTEXT.md` — remote-JWKS fetch, cache, and refresh contract Phase 61 must consume
- `.planning/METHODOLOGY.md` — recommendation-first workflow preference and least-surprise host seam lens

### Code and tests
- `lib/lockspire/protocol/client_auth.ex` — current shared seam that still trusts payload shape before signature truth
- `test/lockspire/protocol/client_auth_test.exs` — current proof shape to replace with cryptographic and ordering-aware tests
- `lib/lockspire/jwks_fetcher.ex` — hardened Phase 60 remote-key boundary
- `lib/lockspire/protocol/jar.ex` — existing JOSE verification and claim-validation patterns worth reusing
- `lib/lockspire/protocol/security_profile.ex` — effective signing-algorithm posture source
- `lib/lockspire/protocol/pushed_authorization_request.ex` — PAR surface using `ClientAuth`
- `lib/lockspire/protocol/device_authorization.ex` — device authorization surface using `ClientAuth`
- `lib/lockspire/protocol/token_exchange.ex` — token and token-exchange surfaces using `ClientAuth`
- `lib/lockspire/protocol/revocation.ex` — revocation surface using `ClientAuth`
- `lib/lockspire/protocol/introspection.ex` — introspection surface with current secret-only post-auth narrowing
- `lib/lockspire/protocol/backchannel_authentication.ex` — CIBA backchannel auth surface using `ClientAuth`
- `lib/lockspire/protocol/discovery.ex` — current metadata truth path that still suppresses `private_key_jwt`
- `lib/lockspire/web/ciba_authorization_json.ex` — current CIBA JSON surface exposing `reason_code`
- `lib/lockspire/observability.ex` — telemetry emission seam
- `lib/lockspire/redaction.ex` — redaction contract for telemetry/audit
- `lib/lockspire/audit/event.ex` — durable audit normalization seam
- `lib/lockspire/protocol/token_endpoint_dpop.ex` — replay-ordering precedent
- `test/lockspire/storage/ecto/repository_used_jti_test.exs` — current durable JTI storage proof

### Ecosystem references that shaped these decisions
- `RFC 7523` — JWT bearer client assertions and error semantics
- `OpenID Foundation January 2025 private_key_jwt disclosure notice` — audience-hardening lesson
- `Spring Authorization Server` docs — shared decoder/validator architecture for client assertions
- `OpenIddict` assertion-auth and 7.0 migration docs — server-wide capability posture and issuer-audience migration
- `node-oidc-provider` changelog — removal of endpoint-specific auth-method metadata drift

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Protocol.ClientAuth` is already the one place where direct-client auth converges; Phase 61 should strengthen that seam rather than distributing verification into endpoints.
- `Lockspire.JwksFetcher` already provides a guarded remote-key path and bounded refresh contract suitable for `jwks_uri` verification.
- `Lockspire.Protocol.Jar` already demonstrates JOSE-based verification plus explicit claim checks, including audience and issuer validation.
- `Lockspire.Protocol.SecurityProfile` already centralizes effective algorithm posture and should remain the source of allowed client-assertion algorithms.
- `Observability`, `Redaction`, and `Audit.Event` already provide the right internal visibility seams for stable failure reasoning without public leakage.

### Established Patterns

- Controllers and endpoint modules are thin delivery adapters; protocol modules own security behavior.
- Lockspire prefers derived runtime truth over configurable parallel policy planes.
- Security-sensitive host seams stay narrow and explicit; dangerous protocol behavior stays Lockspire-owned.
- The repo increasingly favors one shared capability source per concern and treats metadata/runtime drift as a bug, not as tolerated flexibility.

### Integration Points

- `ClientAuth` should become the place where `private_key_jwt` key resolution, signature trust, claim validation, replay ordering, and failure taxonomy come together.
- Direct-client endpoints should mostly inherit the new behavior automatically once `ClientAuth` is corrected, with only endpoint-local error remapping and semantic post-auth work remaining.
- Discovery/admin truth updates in this phase should follow the runtime capability exposed by `ClientAuth` and `SecurityProfile`, not preserved historical suppression.
- Observability and audit changes should be wired close to the shared auth seam so all direct-client surfaces benefit uniformly.

</code_context>

<deferred>
## Deferred Ideas

- `client_secret_jwt`, mTLS, or other auth-method expansion
- Endpoint-URL audience compatibility knobs or multi-issuer audience variants
- Two-phase replay reservation or distributed replay-coordination refinements beyond the current durable store
- Background JWKS refresh/prefetch scheduling
- New endpoint-specific auth metadata knobs or operator-configurable verifier divergence
- Broader docs and end-to-end closure work reserved for Phase 62

</deferred>

---

*Phase: 61-shared-private-key-jwt-verification*
*Context gathered: 2026-05-06*
