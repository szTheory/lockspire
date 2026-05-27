# v1.27 Architecture Research — Phoenix Resource Server Token Acceptance

**Domain:** Embedded OAuth/OIDC authorization-server library for Phoenix/Elixir — Resource Server token acceptance integration.
**Researched:** 2026-05-27
**Confidence:** HIGH (read directly from shipped source in `lib/lockspire/plug/`, `lib/lockspire/protocol/`, `examples/adoption_demo/`, and `priv/templates/lockspire.install/`).

## Scope of This Document

This is **not** a greenfield architecture exercise. The existing Lockspire architecture is described in `.planning/research/archive/pre-v1.27/ARCHITECTURE.md` and is not re-derived here. This document answers exactly the six v1.27 integration questions:

1. Where does "RS token acceptance" live in the codebase?
2. How are JWT-bearer and introspection-backed opaque acceptance exposed (one plug, two plugs, host-seam)?
3. Where does audience/resource-indicator binding live?
4. How is the adoption demo re-wired so it stops conflating stored tokens with JWT bearer protection?
5. What changes vs what stays stable?
6. What is the suggested phase build order?

## The Tension in Two Sentences

`Lockspire.Plug.VerifyToken` (shipped v1.21) calls `JOSE.JWT.verify_strict/3` directly on the raw bearer; it only accepts a JWT-shaped token signed by a key in `Lockspire.KeyCache`. But the shipped `/token` endpoint emits an **opaque** `TokenFormatter.format_access_token/1` token for `authorization_code`, `refresh_token`, `device_code`, and CIBA grants — only `RFC 8693 Token Exchange` with a host-provided custom-claims validator produces a JWT (`typ: at+jwt`). The adoption demo papers over this gap by pointing its `/userinfo` call at Lockspire's own resource endpoint (which speaks to the durable token store), not at the host's `Lockspire.Plug.VerifyToken`-protected `/api/billing/summary` route.

## Existing Architecture — Stable Surfaces (Do Not Touch)

Verified by direct read of source on `main`:

| Module | File | Role | v1.27 Status |
|--------|------|------|--------------|
| `Lockspire.Plug.VerifyToken` | `lib/lockspire/plug/verify_token.ex` | Soft-validation plug — extracts Bearer/DPoP, JOSE-verifies, assigns `%Lockspire.AccessToken{}` | **Modified** (verifier internals) |
| `Lockspire.Plug.EnforceSenderConstraints` | `lib/lockspire/plug/enforce_sender_constraints.ex` | DPoP + mTLS binding enforcement using `binding_requirements` on `%AccessToken{}` | **Unchanged** |
| `Lockspire.Plug.RequireToken` | `lib/lockspire/plug/require_token.ex` | Strict halting + RFC 6750 challenge response | **Unchanged** |
| `Lockspire.AccessToken` | `lib/lockspire/access_token.ex` | In-pipeline struct: `token`, `claims`, `client_id`, `authorization_scheme`, `binding_type`, `binding_requirements`, `error` | **Unchanged shape** (semantics broadened) |
| `Lockspire.Protocol.Introspection` | `lib/lockspire/protocol/introspection.ex` | `POST /introspect` — confidential-client-authenticated lookup by hashed token; emits RFC 7662 payload | **Unchanged** (consumed in-process) |
| `Lockspire.Protocol.Userinfo` | `lib/lockspire/protocol/userinfo.ex` | OIDC `/userinfo` — already speaks opaque-token-via-`fetch_active_access_token` | **Unchanged** |
| `Lockspire.Storage.TokenStore.fetch_active_access_token/1` | `lib/lockspire/storage/token_store.ex` | Behaviour for opaque-token resolution via hashed lookup | **Unchanged** (reused) |
| `Lockspire.Protocol.TokenFormatter.hash_token/1` | `lib/lockspire/protocol/token_formatter.ex` | Canonical SHA-256 hex lower hash used by `/userinfo`, `/introspect`, and the token store | **Unchanged** (reused) |
| `Lockspire.Web.ProtectedResourceChallenge` | `lib/lockspire/web/protected_resource_challenge.ex` | DPoP-nonce challenge builder | **Unchanged** |

The internal boundaries (`Protocol` core vs `Storage` vs `Plug` vs `Host`) stay intact. The fix is to land RS-token acceptance **inside the existing plug pipeline**, not as a new product surface.

## v1.27 Integration Decision

### 1. Where does RS token acceptance live?

**Inside `Lockspire.Plug.VerifyToken` as a new internal `Verifier` module dispatch — not a parallel plug, not a new protocol module, not a host seam.**

Rationale, ordered by weight:

- The shipped public contract is "put `VerifyToken → EnforceSenderConstraints → RequireToken` in your `:lockspire_protected_api` pipeline." That public contract must keep working. Forking it into two plugs creates the exact "which one do I pick?" ambiguity the milestone is supposed to delete.
- The pipeline state contract — `conn.assigns[:access_token] :: %Lockspire.AccessToken{}` — is already designed around a uniform post-verification struct, with `:claims` as a generic map. Opaque-token verification produces an equivalent claims map (issuer, sub, client_id, scope, aud, exp, iat, cnf) from the stored `%Lockspire.Domain.Token{}` plus client/server context. The downstream plugs (`EnforceSenderConstraints` consumes `binding_requirements`; `RequireToken` consumes `error`) work without modification.
- The duplication cost of "two plugs that mostly agree" is much higher than the dispatch cost inside one plug. The branch is one explicit step in `verify_token/3`.
- It encodes the honest split in the **code**, not in the docs: there is one Lockspire plug, with one `%AccessToken{}` shape, and the verifier knows how to honor either of two token shapes Lockspire actually issues.

**Concrete shape:**

```
lib/lockspire/plug/verify_token.ex                 (existing — orchestrator)
lib/lockspire/plug/verify_token/verifier.ex        (new — token-shape dispatch)
lib/lockspire/plug/verify_token/jwt_verifier.ex    (new — current JOSE flow, extracted)
lib/lockspire/plug/verify_token/opaque_verifier.ex (new — stored-token flow)
```

`Verifier.verify/3` decides JWT vs opaque from the token shape (detect a JWS three-segment compact form vs an opaque url-safe random string emitted by `TokenFormatter`). It is **not** a configuration knob the adopter sets per route. Lockspire knows which token shape it issued; the verifier honors what arrives.

### 2. How are JWT-bearer and introspection-backed opaque acceptance exposed?

**One plug. Two internal verifiers. No new plug surface. No host seam.**

Considered alternatives and why each is rejected:

| Option | Why rejected |
|--------|--------------|
| Two plugs (`VerifyJwtToken`, `VerifyIntrospectedToken`) | Forces adopters to pick — recreates the v1.27 ambiguity. Doubles the documentation surface. Splinters DPoP/mTLS enforcement composition. |
| One plug with a `mode: :jwt \| :introspect` option | A configuration knob is the same ambiguity with a slightly nicer name. Adopters with mixed-grant-type clients would be forced into per-route conditional logic. |
| Delegate to a host behaviour (`Lockspire.Host.TokenVerifier`) | Lockspire owns "is this Lockspire-issued token currently active and bound correctly?" That is protocol truth, not host policy. Host seams in `lib/lockspire/host/` cover account, claims, CIBA notification, token-exchange validation — places where host policy is genuinely the owner. Token shape acceptance is not such a place. |
| External `Lockspire.Client` library or remote `/introspect` round-trip | The plug already runs **in-process** alongside the same token store and same key cache that issued the token. Forcing an HTTP call to its own introspection endpoint to validate a stored token is a category error. The introspection endpoint stays available for genuine remote consumers (other services), but the in-process plug calls `Storage.TokenStore.fetch_active_access_token/1` directly. This is the same path `Lockspire.Protocol.Userinfo` already uses. |

**The opaque verifier is structurally a thin local-introspection helper**, not a remote introspection client. It reuses `TokenFormatter.hash_token/1` and `fetch_active_access_token/1` and projects the resulting `%Domain.Token{}` into a synthetic claims map shaped like the existing JWT claims map. This is the single most important architectural simplification in the milestone: **the plug does not need a remote `/introspect` HTTP client at all** for adopters who mount Lockspire in the same BEAM. A separate `Lockspire.IntrospectionClient` could be a follow-on for adopters who deploy Lockspire as a separate node, but is explicitly **out of scope for v1.27** under the "no service mesh / hosted auth" non-goals.

### 3. Where does audience / resource-indicator binding live?

**Already in the verifier — in `Lockspire.Plug.VerifyToken.validate_audience/2`. It moves earlier in the call graph but does not change shape.**

The existing `apply_restrictions/2` already handles `:audience` / `:audiences` against a JWT `aud` claim. For opaque tokens, the stored `%Domain.Token{}` carries `audience` (populated from `interaction.resources_requested`, set during `authorization_flow.ex:308`). The opaque verifier projects `token.audience` into the synthetic claims map under `"aud"` exactly as the JWT verifier already does. **No new audience-binding module is needed.**

Resource Indicators (RFC 8707) intake on the `/token` endpoint and on PAR/authorization already runs; v1.14 validated `Resource Indicators for targeted audience claims`. The stored token already records the requested resources. The v1.27 verifier needs to surface them, not re-derive them.

**Single rule for v1.27:** `validate_audience/2` runs unchanged after the verifier branch; it consumes `%AccessToken{}.claims["aud"]` regardless of source. Configuration on the plug (`:audience` / `:audiences`) is the canonical and only place a route declares which resource indicator it accepts.

### 4. Adoption demo re-wire

The current demo (`examples/adoption_demo/`) has two seams that conflate the two acceptance stories:

| Seam | Current behavior | After v1.27 |
|------|------------------|-------------|
| `scripts/demo/adoption_smoke.py` lines 235-242 | Hits `GET /lockspire/userinfo` with the stored access token to prove acceptance. This is `Protocol.Userinfo` doing its own thing — it never exercises `Lockspire.Plug.VerifyToken`. | Keep this assertion as proof that **Lockspire-owned** RS endpoints accept the stored token. Add a **second** assertion that hits `GET /api/billing/summary` with the same stored token and gets a `200`, proving **host-owned** RS protection accepts it too. |
| `examples/adoption_demo/lib/adoption_demo_web/router.ex:23-27` `:lockspire_protected_api` | Pipeline is correctly wired (`VerifyToken → EnforceSenderConstraints → RequireToken`) but **the smoke test never exercises it with an issued token** — it only confirms `401` on anonymous request (line 244). | Pipeline unchanged in shape. The smoke test now actually drives it with a real `authorization_code`-issued bearer. |
| `examples/adoption_demo/lib/adoption_demo_web/controllers/api_controller.ex` | Reads `token.claims["sub"]`, `["scope"]`, `["aud"]`. Today this only succeeds if the token is JWT — and the demo never reaches this branch because no JWT is ever issued by `authorization_code`. | After v1.27, the controller reads the same fields off the synthetic claims map projected by the opaque verifier. No controller change. |

The re-wire is **subtractive**: nothing in the demo learns about a new concept. One additional smoke-test HTTP call proves the round-trip end-to-end, and the existing comment/docs are updated to say "the same stored bearer Lockspire issued works through `Lockspire.Plug.VerifyToken` against your host API."

### 5. What changes vs what stays stable

#### New files

| Path | Purpose |
|------|---------|
| `lib/lockspire/plug/verify_token/verifier.ex` | Internal dispatch: detect JWT vs opaque shape; route to the right verifier. |
| `lib/lockspire/plug/verify_token/jwt_verifier.ex` | Extracted JOSE / `KeyCache` path (the current `extract_kid/1` → `fetch_key/1` → `verify_signature_and_claims/2` flow). |
| `lib/lockspire/plug/verify_token/opaque_verifier.ex` | Stored-token path: hash via `TokenFormatter`, fetch via `Storage.TokenStore`, project into synthetic claims map, attach `binding_requirements` from `token.cnf`. |
| `test/lockspire/plug/verify_token_test.exs` (extended) | Negative + positive paths for both verifier branches plus the dispatch boundary. |
| `test/integration/v1_27_rs_token_acceptance_e2e_test.exs` | End-to-end: `authorization_code` → opaque bearer → `Lockspire.Plug.VerifyToken` accepts on host route. |
| Adoption demo: extra assertion in `scripts/demo/adoption_smoke.py` | One additional request through `/api/billing/summary` with the stored bearer; assert `200`. |
| `priv/templates/lockspire.install/router.ex` (extended) | Add the optional `:lockspire_protected_api` pipeline block as a commented-out scaffold mirroring the demo. |

#### Modified files

| Path | Change |
|------|--------|
| `lib/lockspire/plug/verify_token.ex` | `verify_token/3` becomes a thin shell that calls `Verifier.verify/3`. `apply_restrictions/2`, `validate_audience/2`, `validate_scopes/2`, and the `%AccessToken{}` projection stay where they are. |
| `lib/lockspire/access_token.ex` | Docstring widened to state that `:claims` may originate from a JWS or from a projected stored-token. No struct field change. |
| `docs/protected-route-host-guide.md` (or equivalent shipped doc) | Single authoritative "which token shape protects a host Phoenix API route?" answer. Names the two issued shapes Lockspire produces. States that one plug accepts both. |

#### Stable — explicitly do not touch

- `Lockspire.Plug.EnforceSenderConstraints` (already consumes `binding_requirements` generically)
- `Lockspire.Plug.RequireToken` (already consumes `error` and challenge metadata generically)
- `Lockspire.Protocol.Introspection` (its `POST /introspect` HTTP surface is for remote callers, not for the in-process plug — the plug does **not** call it)
- `Lockspire.Protocol.Userinfo`
- `Lockspire.Storage.TokenStore` behaviour (callbacks already cover what v1.27 needs)
- `Lockspire.KeyCache`
- Any host seam in `lib/lockspire/host/` — none of these grow a new callback. RS token acceptance is not host policy.
- `Lockspire.Web.AdminRouter` and all admin LiveViews
- All discovery metadata under `lib/lockspire/protocol/discovery/` — `introspection_endpoint` already advertises correctly; no new discovery key emerges from v1.27.

### 6. Suggested phase build order

The build order respects three hard dependencies: a contract must exist before plug code can be written against it; the plug surface must exist before integration tests can drive it; the demo cannot be re-wired before the runtime accepts both token shapes; the generated host scaffold must reflect the demo, not lead it.

| # | Phase | Outcome | Depends on |
|---|-------|---------|------------|
| 1 | **Contract + docs first** | A single authoritative protected-route doc page lands stating: "Lockspire issues two access-token shapes — opaque (default) and JWT (`at+jwt`, only from RFC 8693 Token Exchange with host claims). `Lockspire.Plug.VerifyToken` accepts both." Plus release-readiness assertions pinning the contract. | — |
| 2 | **Plug surface refactor (no behavior change yet)** | `Lockspire.Plug.VerifyToken` extracts its current JOSE path into `JwtVerifier`. The orchestrator delegates through a stub `Verifier` that still only knows the JWT path. All existing tests pass green. | Phase 1 (contract names the verifiers) |
| 3 | **Opaque verifier internals** | `OpaqueVerifier` lands: detects an opaque shape, hashes via `TokenFormatter`, fetches via `Storage.TokenStore`, projects synthetic claims, attaches `binding_requirements` from `token.cnf`. Unit tests cover positive, expired, revoked, reuse-detected, audience-mismatch, and scope-mismatch. | Phase 2 (the verifier indirection exists) |
| 4 | **Dispatch + composition with DPoP/mTLS** | `Verifier.verify/3` now selects JWT or opaque based on shape detection. Cross-plug tests prove that DPoP-bound and mTLS-bound stored access tokens still flow correctly through `EnforceSenderConstraints` and `RequireToken`. | Phase 3 |
| 5 | **Adoption-demo re-wire (executable proof)** | `scripts/demo/adoption_smoke.py` adds a host-RS assertion against `/api/billing/summary` using the stored bearer from the authorization-code flow. The existing `/userinfo` assertion stays. | Phase 4 (runtime accepts the stored bearer through the plug) |
| 6 | **CI proof — repo-native** | The adoption-demo smoke runs in CI on the `:lockspire_protected_api` host pipeline; a `release_readiness_contract_test.exs` clause asserts both verifier branches are exercised. | Phase 5 |
| 7 | **Generated-host scaffolding update** | `priv/templates/lockspire.install/router.ex` gains a commented `:lockspire_protected_api` pipeline block mirroring the demo wiring, with a short companion section in the install docs pointing at the doc page from Phase 1. | Phase 5 (demo is the source of truth the scaffold mirrors) |

**Phase 1 is non-negotiably first** because the milestone goal explicitly says "make it obvious which Lockspire-issued token shape protects a host Phoenix API." If the doc is written after the code, the doc becomes a description of an implementation accident instead of a contract the implementation honors.

**Phase 6 must precede Phase 7** because the generated host should advertise only what CI continuously proves.

## Component Responsibilities (v1.27 view of the verify pipeline)

| Component | Owns | Does not own |
|-----------|------|--------------|
| `Lockspire.Plug.VerifyToken` | Orchestration: extract Authorization header, delegate to `Verifier`, apply audience/scope restrictions, produce `%AccessToken{}` for downstream plugs. | Sender-constraint enforcement; halting; HTTP responses. |
| `Verifier` | Token-shape detection. | Hashing, fetching, JOSE verification — delegates to the two sub-verifiers. |
| `JwtVerifier` | JOSE strict verify, `kid` lookup via `KeyCache`, `exp`/`nbf` time check, building synthetic claims and `binding_requirements` from `cnf`. | Audience / scope restrictions (those live one layer up so both verifiers share them). |
| `OpaqueVerifier` | Hash via `TokenFormatter`, fetch via `Storage.TokenStore.fetch_active_access_token/1`, projection from `%Domain.Token{}` into claims map, build `binding_requirements` from `token.cnf`. | Audience / scope restrictions. Confidential-caller authentication (that lives in `Protocol.Introspection` for the HTTP `/introspect` use case; the in-process verifier already trusts the store). |
| `Lockspire.Plug.EnforceSenderConstraints` | DPoP proof validation + mTLS thumbprint matching from `binding_requirements`. | Shape detection or token resolution. |
| `Lockspire.Plug.RequireToken` | Halting + RFC 6750 / DPoP challenge response. | Anything about token shape. |

## Data Flow — host Phoenix API protected route, v1.27

```
client request
  Authorization: Bearer <token>            (opaque OR JWT — Lockspire issued either way)
       ↓
:lockspire_protected_api pipeline
       ↓
Lockspire.Plug.VerifyToken
  ├─ extract Bearer/DPoP token from header
  ├─ Verifier.verify/3
  │    ├─ JwtVerifier   (if compact JWS detected)
  │    │   → KeyCache → JOSE.JWT.verify_strict
  │    └─ OpaqueVerifier (otherwise)
  │        → TokenFormatter.hash_token
  │        → Storage.TokenStore.fetch_active_access_token
  │        → project %Domain.Token{} into synthetic claims + binding_requirements
  ├─ validate_audience/2   (same code for both branches)
  ├─ validate_scopes/2     (same code for both branches)
  └─ conn.assigns[:access_token] = %Lockspire.AccessToken{...}
       ↓
Lockspire.Plug.EnforceSenderConstraints
       ↓ (DPoP / mTLS from binding_requirements — unchanged)
       ↓
Lockspire.Plug.RequireToken
       ↓ (halt with RFC 6750 challenge on error — unchanged)
       ↓
host controller reads conn.assigns.access_token uniformly
```

The host controller cannot tell from `%AccessToken{}` whether the token was opaque or JWT, and it should not be able to. That is the architectural payoff.

## Integration Points

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `Plug.VerifyToken` ↔ `Storage.TokenStore` | Direct in-process call to `fetch_active_access_token/1` | Already a `@callback` behaviour; no new behaviour needed. |
| `Plug.VerifyToken` ↔ `Protocol.TokenFormatter` | Direct call to `hash_token/1` | Already pure; safe to call from a plug. |
| `Plug.VerifyToken` ↔ `KeyCache` | Direct ETS read via `get_key/1` | Existing pattern. |
| `Plug.VerifyToken` ↔ `Protocol.Introspection` | **None.** The HTTP introspection endpoint exists for **remote** consumers. The in-process plug does not round-trip through HTTP to itself. | This is the central non-decision: do not build a self-introspection HTTP client. |
| Plug pipeline ↔ host Phoenix router | `pipe_through [:lockspire_protected_api]` | Already shipped public contract; v1.27 does not change this. |

### External Services

None. v1.27 deliberately avoids introducing a remote `Lockspire.IntrospectionClient`. Adopters who run Lockspire as a separate node are an explicit non-goal under the v1.27 "no service mesh / hosted auth" boundary.

## Anti-Patterns to Avoid

### Anti-Pattern 1: A second plug for opaque tokens

**What people do:** Ship `Lockspire.Plug.VerifyOpaqueToken` alongside `Lockspire.Plug.VerifyToken`.
**Why it's wrong:** Forces adopters to choose, recreating the exact ambiguity v1.27 is meant to delete. Splinters the DPoP/mTLS composition that already works through `binding_requirements`. Doubles the support and CI surface forever.
**Do this instead:** One plug, internal dispatch on token shape.

### Anti-Pattern 2: A `mode:` keyword on the plug

**What people do:** `plug Lockspire.Plug.VerifyToken, mode: :introspect`.
**Why it's wrong:** It is the same fork as two plugs, with a slightly friendlier name. Adopters serving both JWT-issued (token exchange) and opaque-issued (authorization code) clients on the same route would have no usable option.
**Do this instead:** Detect token shape from the token itself. Lockspire knows what it issued.

### Anti-Pattern 3: Remote `/introspect` HTTP self-call from the plug

**What people do:** Have `VerifyToken` POST to its own `/introspect` endpoint to validate the bearer.
**Why it's wrong:** Adds an HTTP round-trip, a `client_secret`/`private_key_jwt` self-credential, latency, and a failure mode for a piece of state the same BEAM already holds. The introspection endpoint is for **remote** callers; this is an embedded library.
**Do this instead:** Direct in-process call through `Storage.TokenStore.fetch_active_access_token/1`. Same path `Protocol.Userinfo` already uses.

### Anti-Pattern 4: New host seam behaviour for token verification

**What people do:** Add `Lockspire.Host.TokenVerifier` so the host "decides" how to verify.
**Why it's wrong:** Token shape acceptance is protocol truth (which token did Lockspire issue?), not host policy (who is the user? what claims do they get?). Host seams in `lib/lockspire/host/` exist for genuine host policy questions. Putting verification there hands a security-critical responsibility to adopters who do not want it.
**Do this instead:** Verification stays in Lockspire. The host configures audience and scope per route; the host does not implement verification.

### Anti-Pattern 5: Synthesizing a JWT from the stored token "for symmetry"

**What people do:** Have `OpaqueVerifier` re-sign a JWT from the stored `%Domain.Token{}` so downstream code "always sees a JWT."
**Why it's wrong:** Performs cryptographic work for no callers. Re-introduces signing-key dependence on a path that does not need it. Confuses operators reading audit trails about which JWTs were actually issued vs synthesized.
**Do this instead:** Project the stored token into a plain Elixir map shaped like the JWT claims. The `%AccessToken{}` struct already accepts a generic claims map.

## Scaling Considerations

v1.27 does not change scaling characteristics:

- **JWT path:** unchanged — ETS-cached JWK lookup + in-memory JOSE verify. O(1) per request.
- **Opaque path:** one `Storage.TokenStore.fetch_active_access_token/1` per protected request. Indexed lookup on `token_hash`. Identical cost to the existing `/userinfo` and `/introspect` endpoints, both already shipped at the same volume of host-app expectation.
- **DPoP/mTLS binding enforcement:** unchanged; consumes `binding_requirements`.

The only new operational story is that protected-route traffic now touches the `tokens` table on every request for opaque-token routes. This is identical to how `/userinfo` already behaves and is operationally well-understood by adopters today. No new caching layer is introduced in v1.27 — that would be a follow-on if and only if adopter evidence requires it.

## Boundary Decisions (carrying the archived v1.24 format forward)

- **core:** verifier dispatch, opaque verifier, JWT verifier extraction, integration tests, release-readiness contract assertions.
- **core:** the single protected-route doc page; release-readiness assertions fail loudly if the doc drifts from the shipped behavior.
- **adoption-demo:** one additional smoke-test assertion plus comment cleanup.
- **scaffolding:** one commented-out pipeline block in the install router template.
- **defer:** any standalone `Lockspire.IntrospectionClient` for cross-node deployments; any token-shape preference at the issuance side (Lockspire continues to issue what it already issues per grant type).
- **defer:** new host seam for token verification — explicit non-decision.

## Proof Posture

- **Merge-blocking proof:** ExUnit coverage for both verifier branches in `test/lockspire/plug/verify_token_test.exs`; an end-to-end integration test in `test/integration/v1_27_rs_token_acceptance_e2e_test.exs` that drives `authorization_code` → opaque bearer → `Lockspire.Plug.VerifyToken`-protected host route; the adoption-demo smoke asserting `200` on `/api/billing/summary` with the stored bearer.
- **Merge-blocking proof:** A `release_readiness_contract_test.exs` clause that asserts the protected-route doc names both issued token shapes and points at one plug, not two.
- **Advisory proof:** stays repo-local; no certification suite required for this milestone (the certification posture stays exactly where v1.20/v1.22 left it).

## Sources

- `lib/lockspire/plug/verify_token.ex` (read in full, 2026-05-27)
- `lib/lockspire/plug/enforce_sender_constraints.ex` (read in full, 2026-05-27)
- `lib/lockspire/plug/require_token.ex` (read in full, 2026-05-27)
- `lib/lockspire/access_token.ex` (read in full, 2026-05-27)
- `lib/lockspire/protocol/introspection.ex` (read in full, 2026-05-27)
- `lib/lockspire/protocol/userinfo.ex` (read in full, 2026-05-27)
- `lib/lockspire/protocol/token_formatter.ex` (read in full, 2026-05-27)
- `lib/lockspire/protocol/rfc8693_exchange.ex` (verified `at+jwt` is the only JWT-emitting grant path, line 343)
- `lib/lockspire/protocol/authorization_flow.ex` (verified opaque token issuance, line 308)
- `lib/lockspire/protocol/refresh_exchange.ex` (verified opaque rotation, line 286)
- `lib/lockspire/key_cache.ex` (verified ETS-backed key lookup)
- `lib/lockspire/storage/token_store.ex` (`@callback fetch_active_access_token/1`)
- `examples/adoption_demo/lib/adoption_demo_web/router.ex` (verified `:lockspire_protected_api` is wired but not exercised with an issued token)
- `examples/adoption_demo/lib/adoption_demo_web/controllers/api_controller.ex` (verified controller reads `token.claims["sub"]`, etc.)
- `scripts/demo/adoption_smoke.py` (verified `/userinfo` is the only RS assertion using the stored bearer)
- `priv/templates/lockspire.install/router.ex` (verified no `:lockspire_protected_api` scaffold exists yet in the generated host)
- `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/ROADMAP.md` (milestone scope and non-goals)
- `.planning/research/archive/pre-v1.27/ARCHITECTURE.md` (prior architecture snapshot, intentionally not re-derived)

---
*Architecture integration research for: v1.27 Phoenix Resource Server Token Acceptance*
*Researched: 2026-05-27*
