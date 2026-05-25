# Phase 91: `jwks_uri` Rotation Diagnostics And Remediation Truth - Research

**Researched:** 2026-05-25
**Domain:** remote `jwks_uri` rotation diagnostics and remediation truth
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| JWKS-01 | A host team using remote `jwks_uri` key material can tell when Lockspire considers the configuration supported, stale, or broken, with concrete remediation guidance. | Supported by shared fetcher/runtime audit plus operator-facing diagnosis surface and docs contract updates. |
| JWKS-02 | An operator can distinguish key-rotation failures caused by issuer metadata, JWKS content, cache freshness, or unsupported rollover posture without reading source code. | Supported by a shared diagnostic taxonomy that preserves detailed causes internally while keeping OAuth wire errors generic. |

</phase_requirements>

## Summary

Lockspire already ships a narrow remote-`jwks_uri` slice with real rotation recovery behavior, but that truth is currently spread across `Lockspire.JwksFetcher`, `PrivateKeyJwt`, `ClientKeyResolver`, a host guide, and milestone-era tests rather than one first-class diagnostic contract. The runtime today supports `https`-only guarded fetches, bounded caching, and one forced refresh path when the cached JWKS is clearly stale. At the wire boundary, however, many distinct failures are flattened to generic auth errors such as `invalid_client` or `:client_jwks_fetch_failed`, which means adopters cannot tell whether they hit transport trouble, malformed remote content, stale cache, or an unsupported rollover shape without reading code or tests.

The most important current implementation truth is the exact rotation posture:

1. successful cached JWKS entries are reused until TTL expiry or a verification miss forces one refresh;
2. one refresh is attempted on `:no_matching_key` and on `:invalid_signature` only when the JWT `kid` is absent from the cached JWKS;
3. the last known good cache entry is preserved when refresh fails;
4. some rollover shapes remain effectively unsupported or at least undiscoverable today, especially same-`kid` key replacement or ambiguous assertions that do not provide enough signal to prove the cache is stale.

That means Phase 91 should not invent a broader remote-key management system. It should make the existing bounded support story explicit, classify the current failure and rollover states, surface that classification where operators work, and pin the resulting truth with repo-native tests and docs-contract checks.

## Current Shipped Truth

### Shared fetcher boundary

- `Lockspire.JwksFetcher` already enforces `https` only, blocks redirects, disables retries, caps response size, applies strict timeouts, rejects unsafe targets before dispatch, and caches successful responses with an explicit TTL.
- `refresh_keys/2` already preserves the last-known-good cached entry if a forced refresh fails.
- Fetcher tests already prove the main low-level failure reasons: `:https_required`, `:timeout`, `:redirect_disallowed`, `{:unsafe_target, reason}`, `{:http_status, status}`, `:invalid_format`, `:payload_too_large`, and cached-entry preservation after refresh failure.

### Runtime consumers

- `Lockspire.Protocol.ClientAuth.PrivateKeyJwt` resolves remote JWKS through the shared fetcher, retries once on `:no_matching_key`, and retries once on `:invalid_signature` only when the JWT `kid` is not present in the cached JWKS.
- `Lockspire.Protocol.Jarm.ClientKeyResolver` uses the same fetcher and similarly refreshes remote JWKS once when an encryption key is unavailable from the cached set.
- `Lockspire.Protocol.ClientAuth.MTLS` also allows self-signed mTLS clients to resolve a `jwks_uri` on demand, but Phase 91's immediate support burden is still the shared remote-JWKS rotation story rather than certificate extraction guidance.

### Existing support wording

- `docs/private-key-jwt-host-guide.md` already says remote `jwks_uri` uses guarded fetches, bounded caching, and one bounded forced-refresh path.
- `docs/supported-surface.md` already points readers to that guide as the canonical narrow host explanation for the `jwks_uri` + `private_key_jwt` slice.
- `docs/operator-admin.md` does not yet give operators any concrete remote-JWKS diagnosis or remediation story.
- `mix lockspire.verify` currently covers install wiring only; it does not inspect any configured client's remote-JWKS posture.

## Exact Gap

### Distinct runtime causes are flattened too early

The fetcher returns granular reasons, but `PrivateKeyJwt` collapses any fetch or refresh failure into `:client_jwks_fetch_failed`, and the OAuth boundary then collapses that further into a generic `invalid_client`. That generic wire posture is correct, but Lockspire lacks a first-class internal/operator-facing translation layer that answers:

- was the URI itself unsafe or malformed?
- did the remote server time out or return a bad HTTP status?
- did the JWKS payload parse incorrectly?
- did a refresh attempt happen?
- was the cached set preserved?
- did the presented assertion look like a stale-cache rotation case or an unsupported rollover posture?

### Supported versus unsupported rollover is implicit

The current code supports rotation when the new key is detectable through a key miss or a stale `kid`. It does not state an explicit product truth for cases like:

- same-`kid` key replacement with changed key material;
- assertions that omit `kid` while the cached set still contains plausible keys but verification fails;
- refresh failures during an otherwise supported rollover event.

Those conditions are critical because they create support incidents that look identical at the wire boundary.

### Operator and doctor surfaces are missing

There is no admin, doctor, or install-time diagnostic output that explains a client's current remote-JWKS posture in Lockspire's own language. The client detail view shows the configured `jwks_uri`, but not whether Lockspire considers the posture healthy, stale, blocked, or unsupported.

## Recommended Product Truth

Phase 91 should lock in one narrow truth contract:

- Supported:
  - remote `jwks_uri` for the shipped direct-client and JARM client-key paths;
  - guarded `https` fetches through the shared fetcher;
  - cached successful responses with bounded TTL;
  - one forced refresh on key miss or clearly stale `kid` mismatch;
  - preservation of last-known-good cache on refresh failure.
- Not promised:
  - indefinite background sync or proactive polling;
  - unlimited refresh attempts;
  - federation-style metadata trust;
  - silent recovery from same-`kid` key replacement or other rollover shapes the runtime cannot distinguish from a bad signature.
- Required diagnostics:
  - classify transport, target-safety, HTTP, payload, freshness, and unsupported-rollover states separately;
  - surface remediation guidance that tells the operator whether to fix the URI, fix the remote payload, restore key overlap, wait for transient availability, or re-register with inline `jwks`.

## Recommended Plan Split

### 91-01: Codify the shared remote-JWKS diagnosis model

Create one shared remote-JWKS diagnostic classifier rather than leaving each caller to flatten reasons independently. Feed it from `JwksFetcher`, `PrivateKeyJwt`, and `ClientKeyResolver`, and make the rotation-support boundary explicit in code and tests.

### 91-02: Surface the diagnosis where operators and hosts work

Expose the shared diagnosis through Lockspire-owned support surfaces:

- admin client detail for read-only remote-JWKS posture and remediation;
- an optional doctor/install diagnostic path instead of source-diving;
- host/operator docs that describe supported rotation posture and explicit non-goals.

### 91-03: Prove the contract end to end

Add repo-native proof for:

- refreshable rotation success;
- failed refresh with preserved cache;
- unsupported rollover posture classification;
- doc/support-truth drift fences so the published remediation story stays aligned with runtime behavior.

## Validation Architecture

The phase is fully automatable with existing ExUnit, Phoenix LiveView, and docs-verification infrastructure.

- Quick path:
  - `mix test test/lockspire/jwks_fetcher_test.exs test/lockspire/protocol/client_auth_test.exs test/lockspire/protocol/jarm_test.exs test/lockspire/admin/clients_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/release_readiness_contract_test.exs`
- Full path:
  - `mix test`
  - `mix docs.verify`

No new harness is required. The main validation risk is keeping docs and operator copy aligned with the new runtime diagnosis taxonomy.

## Key Files For Planning

- `lib/lockspire/jwks_fetcher.ex`
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex`
- `lib/lockspire/protocol/jarm/client_key_resolver.ex`
- `lib/lockspire/protocol/client_auth/mtls.ex`
- `lib/lockspire/install/verify.ex`
- `lib/mix/tasks/lockspire.verify.ex`
- `lib/lockspire/admin/clients.ex`
- `lib/lockspire/web/live/admin/clients_live/show.ex`
- `docs/private-key-jwt-host-guide.md`
- `docs/supported-surface.md`
- `docs/operator-admin.md`
- `test/lockspire/jwks_fetcher_test.exs`
- `test/lockspire/protocol/client_auth_test.exs`
- `test/lockspire/protocol/jarm_test.exs`
- `test/integration/phase62_private_key_jwt_e2e_test.exs`
- `test/lockspire/web/live/admin/clients_live/show_test.exs`
- `test/lockspire/release_readiness_contract_test.exs`

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/milestones/v1.15-ROADMAP.md`
- `.planning/milestones/v1.15-MILESTONE-AUDIT.md`
- `lib/lockspire/jwks_fetcher.ex`
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex`
- `lib/lockspire/protocol/jarm/client_key_resolver.ex`
- `lib/lockspire/install/verify.ex`
- `lib/mix/tasks/lockspire.verify.ex`
- `lib/lockspire/web/live/admin/clients_live/show.ex`
- `docs/private-key-jwt-host-guide.md`
- `docs/supported-surface.md`
- `docs/operator-admin.md`
- `test/lockspire/jwks_fetcher_test.exs`
- `test/lockspire/protocol/client_auth_test.exs`
- `test/lockspire/protocol/jarm_test.exs`
- `test/integration/phase62_private_key_jwt_e2e_test.exs`

## RESEARCH COMPLETE
