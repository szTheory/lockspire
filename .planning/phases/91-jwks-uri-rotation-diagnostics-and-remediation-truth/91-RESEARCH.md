# Phase 91: `jwks_uri` Rotation Diagnostics And Remediation Truth - Research

**Researched:** 2026-05-25
**Domain:** remote JWKS rollover diagnostics, support truth, and remediation guidance
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Support contract and product boundary
- **D-01:** Describe the shipped `jwks_uri` behavior as bounded reactive rollover support, not as generic or proactive rotation support.
- **D-02:** Preserve the exact runtime truth: cached remote JWKS, one bounded forced refresh on stale or unknown-key verification mismatch, last-known-good cache preserved on refresh failure, current authentication attempt still fails closed.
- **D-03:** Do not add or imply background polling, prefetch, grace-window orchestration, hosted key management, or a broader federation/metadata subsystem.

### Diagnostics surface
- **D-04:** The primary operational truth must live in a shared runtime diagnostics subsystem, not only in docs and not only in admin UI.
- **D-05:** `mix lockspire.verify` remains the install-wiring diagnostic and must not be overloaded with runtime remote-JWKS incident handling.
- **D-06:** A doctor-style support entrypoint is preferred, with admin/operator surfaces consuming the same shared model rather than inventing a second truth source.

### Failure taxonomy and ownership
- **D-07:** OAuth wire behavior stays generic as `invalid_client`; do not create a more revealing protocol error contract.
- **D-08:** Operator-facing diagnostics should normalize to four stable classes: `remote_jwks_fetch_failed`, `remote_jwks_invalid`, `remote_jwks_key_unavailable`, and `remote_jwks_signature_invalid`.
- **D-09:** Preserve richer safe metadata underneath the stable class, including stage/subreason, source, cache presence, refresh attempt, requested `kid` presence, and safe fetch details.
- **D-10:** Keep ownership split explicit: Lockspire owns guarded fetch/cache/refresh/verify plus truthful diagnostics; host/operator owns incident handling on the Lockspire side; client integrator owns remote JWKS publication and overlap-based rollover choreography.

### Planning and escalation posture
- **D-11:** Resolve medium-impact implementation choices without re-asking the user when they do not widen public API, security posture, or support claims.
- **D-12:** Escalate only if the implementation would widen Lockspire into proactive remote-key management, change the wire contract, or materially strengthen the public support claim beyond what the runtime can prove.

### the agent's Discretion
- Exact module and function names for the shared diagnostics API
- Whether the support wrapper lands as a new mix task family or a single dedicated task, provided install verification remains separate
- Exact operator/admin copy and the balance between telemetry-first versus durable status, provided transient failures do not become noisy durable audit spam

### Deferred Ideas (OUT OF SCOPE)
- Background polling or periodic remote-key readiness checks
- A general remote metadata ingestion subsystem
- Dashboard-heavy operator UX that assumes every host mounts the admin plane
- Durable audit logging for every transient fetch failure
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| JWKS-01 | A host team using remote `jwks_uri` key material can tell when Lockspire considers the configuration supported, stale, or broken, with concrete remediation guidance. | Shared diagnostic state model, doctor/admin consumers, and doc truth anchored to the actual bounded-refresh runtime. |
| JWKS-02 | An operator can distinguish key-rotation failures caused by issuer metadata, JWKS content, cache freshness, or unsupported rollover posture without reading source code. | Stable four-class taxonomy with stage/subreason metadata and repo-native proof across fetcher, verifier, and JARM paths. |
</phase_requirements>

## Summary

Phase 91 does not need new protocol breadth. The current runtime already has the essential bounded-reactive rollover behavior: guarded HTTPS-only fetches, cache-backed reads, one forced refresh path, last-known-good preservation on refresh failure, generic OAuth wire errors, and existing targeted proof for `private_key_jwt` plus JARM remote-key recovery. What is missing is a first-class support truth surface that normalizes those internals into calm operator diagnostics and one canonical remediation story. [VERIFIED: `lib/lockspire/jwks_fetcher.ex`] [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`] [VERIFIED: `lib/lockspire/protocol/jarm/client_key_resolver.ex`] [VERIFIED: `test/lockspire/jwks_fetcher_test.exs`] [VERIFIED: `test/lockspire/protocol/client_auth_test.exs`] [VERIFIED: `test/lockspire/protocol/jarm_test.exs`] [VERIFIED: `test/integration/phase62_private_key_jwt_e2e_test.exs`]

Today the operator truth is fragmented. `docs/private-key-jwt-host-guide.md` describes cache and single-refresh behavior for the `private_key_jwt` slice, but there is no shared diagnostic API, no doctor-style runtime support entrypoint, no admin summary for remote-key incidents, and no canonical support-contract wording that names the bounded-reactive rollover posture directly. Existing telemetry and audit events still expose low-level reason codes rather than the explicit support taxonomy the phase context requires. [VERIFIED: `docs/private-key-jwt-host-guide.md`] [VERIFIED: `docs/supported-surface.md`] [VERIFIED: `lib/lockspire/observability.ex`] [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`]

**Primary recommendation:** split Phase 91 into three slices:
1. codify the shared remote-JWKS diagnostic model from the existing runtime behavior;
2. expose that model through a doctor-style support entrypoint plus admin/operator consumers;
3. lock the public truth and proof around the bounded-reactive rollover contract.

## Current Shipped Truth And Exact Gap

### Runtime truth already present

- `Lockspire.JwksFetcher` already enforces HTTPS-only, no redirects, target-safety validation, body caps, strict timeouts, explicit TTL caching, and refresh-on-demand that preserves the last known good cache entry when refresh fails. [VERIFIED: `lib/lockspire/jwks_fetcher.ex`]
- `Lockspire.Protocol.ClientAuth.PrivateKeyJwt` already retries remote verification once on key mismatch or stale `kid` detection and still returns generic `invalid_client` behavior through the outer client-auth boundary. [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`] [VERIFIED: `lib/lockspire/protocol/client_auth.ex`]
- `Lockspire.Protocol.Jarm.ClientKeyResolver` already shares the same guarded fetch plus one-refresh posture for JARM client-key lookup. [VERIFIED: `lib/lockspire/protocol/jarm/client_key_resolver.ex`]
- Existing tests already prove fetch failures, invalid content, refresh-once behavior, and end-to-end rollover recovery. [VERIFIED: `test/lockspire/jwks_fetcher_test.exs`] [VERIFIED: `test/lockspire/protocol/client_auth_test.exs`] [VERIFIED: `test/lockspire/protocol/jarm_test.exs`] [VERIFIED: `test/integration/phase62_private_key_jwt_e2e_test.exs`]

### Exact gap Phase 91 must close

- There is no shared `Lockspire.Diagnostics.RemoteJwks`-style module that converts low-level fetcher and verifier reasons into the stable four-class support taxonomy from the phase context. [VERIFIED: repo grep]
- There is no runtime support entrypoint analogous to a doctor command for remote JWKS incidents; the only shipped diagnostic command family is install-time `mix lockspire.verify`, which is intentionally scoped to host wiring. [VERIFIED: `lib/mix/tasks/lockspire.verify.ex`] [VERIFIED: `lib/lockspire/install/verify.ex`]
- The canonical public support contract does not yet state the bounded-reactive rollover claim directly or explain what Lockspire owns versus what the operator and client integrator own in a remote-key incident. [VERIFIED: `docs/supported-surface.md`]
- Existing telemetry metadata on client-auth failures exposes raw reason codes but not the phase-local stable support categories or the richer safe subreason metadata operators need for diagnosis. [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`] [VERIFIED: `lib/lockspire/observability.ex`]

## Recommended Diagnostic Model

### Stable external classes

- `remote_jwks_fetch_failed`
- `remote_jwks_invalid`
- `remote_jwks_key_unavailable`
- `remote_jwks_signature_invalid`

These should be the only stable operator-facing classes in docs, doctor output, admin summaries, and any future support-truth assertions. The runtime can continue to carry lower-level details beneath them. This satisfies the need for calm, legible support truth without speculating about upstream intent. [VERIFIED: `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-CONTEXT.md`]

### Safe detail that should ride with the class

- consumer surface: `:private_key_jwt` or `:jarm`
- stage: fetch, parse, cache, select-key, verify-signature
- subreason: timeout, redirect_disallowed, invalid_format, http_status, requested_kid_missing, post_refresh_key_still_missing, post_refresh_signature_invalid, etc.
- `jwks_source`
- `cached_entry_present?`
- `forced_refresh_attempted?`
- `requested_kid_present_in_cached_set?`
- safe fetch metadata such as HTTP status or target-safety reason

This lets the public support contract stay small while the doctor/admin surfaces answer the operator’s actual question: what happened, why, and what next. [VERIFIED: `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-CONTEXT.md`] [VERIFIED: `prompts/lockspire-telemetry-audit-and-introspection.md`]

## Recommended Implementation Shape

### Shared library-first diagnostics API

- Add a new diagnostics module that accepts the existing fetcher/verifier/JARM results and returns a normalized incident struct or map.
- Keep the source data close to the runtime: it should be produced where the fetch, refresh, and key-selection decisions already happen, not reconstructed later from logs.
- Reuse the same normalization path for both `private_key_jwt` and JARM so the support story stays unified.

### Support wrapper

- Introduce a doctor-style mix task separate from `mix lockspire.verify`.
- The wrapper should focus on one client at a time and return short, operator-readable classification plus recommended next step.
- It should not become a generic remote metadata browser or an install-time host verification replacement.

### Admin/operator consumption

- Admin client detail can consume the same diagnostics state and show a small remote-JWKS status summary plus next-step hint.
- The admin UI should remain a consumer, not the authority; the runtime diagnostics API and canonical docs stay authoritative.

## Risks And Design Traps

### Overclaiming rotation support

- The biggest support risk is saying “supports key rotation” without naming the bounded cache plus one-refresh semantics and the lack of proactive readiness. That would create false operator expectations. [VERIFIED: `docs/private-key-jwt-host-guide.md`] [VERIFIED: `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-CONTEXT.md`]

### Splitting the truth between surfaces

- If docs, doctor output, telemetry, and admin UI each invent their own remote-key terms, Phase 91 will increase rather than reduce support burden. The shared diagnostics module must define the truth vocabulary once. [VERIFIED: repo grep]

### Accidentally widening the product boundary

- A doctor command that starts doing background polling, endpoint history, or host-wide remote metadata inventory would quietly widen Lockspire beyond the embedded-library posture this phase is supposed to preserve. [VERIFIED: `.planning/PROJECT.md`] [VERIFIED: `.planning/REQUIREMENTS.md`]

### Diverging `private_key_jwt` and JARM posture

- The same guarded remote-key truth underlies both consumers today. Shipping diagnostics only for `private_key_jwt` would leave JARM as a second-class support surface and reintroduce tribal knowledge. [VERIFIED: `lib/lockspire/protocol/client_auth/private_key_jwt.ex`] [VERIFIED: `lib/lockspire/protocol/jarm/client_key_resolver.ex`]

## Recommended Plan Split

1. **91-01:** Build the shared remote-JWKS diagnostics taxonomy and normalization layer directly on top of the existing fetcher, verifier, and JARM runtime states.
2. **91-02:** Expose the normalized truth through a doctor-style support command and admin/operator consumers without overloading install verification.
3. **91-03:** Tighten docs and automated proof so the bounded-reactive rollover contract, remediation guidance, and failure-path truth cannot drift.

## Key Files For Planning

- `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-CONTEXT.md`
- `lib/lockspire/jwks_fetcher.ex`
- `lib/lockspire/protocol/client_auth.ex`
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex`
- `lib/lockspire/protocol/jarm/client_key_resolver.ex`
- `lib/lockspire/observability.ex`
- `lib/mix/tasks/lockspire.verify.ex`
- `lib/lockspire/install/verify.ex`
- `lib/lockspire/web/live/admin/clients_live/show.ex`
- `lib/lockspire/admin/clients.ex`
- `docs/supported-surface.md`
- `docs/private-key-jwt-host-guide.md`
- `test/lockspire/jwks_fetcher_test.exs`
- `test/lockspire/protocol/client_auth_test.exs`
- `test/lockspire/protocol/jarm_test.exs`
- `test/integration/phase62_private_key_jwt_e2e_test.exs`
- `test/lockspire/release_readiness_contract_test.exs`

## Sources

### Primary

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-CONTEXT.md`
- `lib/lockspire/jwks_fetcher.ex`
- `lib/lockspire/protocol/client_auth.ex`
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex`
- `lib/lockspire/protocol/jarm/client_key_resolver.ex`
- `lib/lockspire/install/verify.ex`
- `lib/mix/tasks/lockspire.verify.ex`
- `lib/lockspire/observability.ex`
- `docs/supported-surface.md`
- `docs/private-key-jwt-host-guide.md`
- `test/lockspire/jwks_fetcher_test.exs`
- `test/lockspire/protocol/client_auth_test.exs`
- `test/lockspire/protocol/jarm_test.exs`
- `test/integration/phase62_private_key_jwt_e2e_test.exs`
- `test/lockspire/release_readiness_contract_test.exs`

## Metadata

**Confidence breakdown:**
- Runtime evidence: HIGH - the shipped bounded-refresh behavior and failure mapping are directly visible in code and tests.
- Architecture: HIGH - the phase boundary and diagnostics split are explicitly constrained by the context and methodology.
- Pitfalls: HIGH - the main failure modes are concrete and already represented by current fetcher/verifier behavior, just not normalized into a support surface yet.

## RESEARCH COMPLETE
