# v1.27 Phoenix Resource Server Token Acceptance — Research Summary

**Project:** Lockspire — embedded OAuth/OIDC authorization-server library for Phoenix/Elixir
**Domain:** RS-side token-acceptance contract on an already-shipped embedded provider
**Researched:** 2026-05-27
**Confidence:** HIGH on diagnosis and stack; **OPEN** on plug-shape design (see Open Design Decision)

## Executive Summary

v1.27 exists to resolve one concrete, code-grounded contradiction inside an otherwise-shipped library: `Lockspire.Plug.VerifyToken` is JOSE-strict, JWT-only (verifies `RS256/ES256/PS256` via `JOSE.JWT.verify_strict/3`); `Lockspire.Protocol.TokenFormatter` emits 32-byte opaque random tokens for the authorization-code, refresh, device, and CIBA paths; only the RFC 8693 token-exchange path emits `at+jwt`. The `examples/adoption_demo` smoke (`scripts/demo/adoption_smoke.py`) papers over the gap by only asserting `401` on anonymous requests to `:lockspire_protected_api` and by sending the issued opaque token to Lockspire-owned `/userinfo` (which looks up by hash) — it never threads a Lockspire-issued token through `Lockspire.Plug.VerifyToken`. The "blessed adoption path" is non-blessed by accident today, and any first adopter who copies the demo will hit `{:error, :malformed}` the moment they try to protect their own Phoenix API.

The milestone needs **no new runtime dependency**. JOSE, Plug, NimbleOptions, Ecto/Postgres, and the existing `at+jwt` signing block in `lib/lockspire/protocol/rfc8693_exchange.ex` cover every code path required. The work is a **contract decision plus a CI-provable round-trip**, not a library hunt. Equally important, RFC 7662 introspection-at-the-RS-plug is the wrong primitive for the host-API seam — it recreates the gateway/CIAM productization PROJECT.md explicitly forbids and forces a synchronous network/IPC hop for state the same BEAM already holds. Introspection stays a Lockspire-owned operator/tooling primitive.

The four researchers converged on diagnosis but **split on the plug shape** that resolves it. STACK and FEATURES recommend tightening `Lockspire.Plug.VerifyToken` to JWT-only and routing AC/refresh/device/CIBA through a new shared `Protocol.AccessTokenSigner` to mint `at+jwt`. ARCHITECTURE recommends keeping one plug with two internal verifiers (`JwtVerifier` + a new `OpaqueVerifier` that calls the in-process `Storage.TokenStore.fetch_active_access_token/1` — the same path `Protocol.Userinfo` already uses). Both branches close the demo gap; both ship without new dependencies; both leave DPoP/mTLS sender-constraint enforcement and RFC 8707 resource-indicator audience binding untouched. They differ on what the plug accepts and what adopters opt into. **This is the milestone's load-bearing design decision and must be resolved with the user during requirements definition — the synthesizer is not picking a winner.**

## Key Findings

### Diagnosis (Convergence) — All Four Researchers Agree

The structural mismatch is real, narrow, and code-grounded:

- `lib/lockspire/plug/verify_token.ex:345-358` — uses `JOSE.JWT.verify_strict/3` over `["RS256","ES256","PS256"]` and `JOSE.JWT.peek_protected/1` for `kid`. Physically cannot accept opaque tokens.
- `lib/lockspire/protocol/token_formatter.ex:29-34` — `format_access_token/1` emits 32-byte url-safe base64 opaque strings.
- `lib/lockspire/protocol/rfc8693_exchange.ex:340-348` — the **only** path today that emits `typ: at+jwt` with the seven RFC 9068 mandatory claims (`iss`, `exp`, `aud`, `sub`, `client_id`, `iat`, `jti` + `scope`).
- `lib/lockspire/protocol/userinfo.ex:122-136` — accepts the stored opaque token via SHA-256 hash + `Storage.TokenStore.fetch_active_access_token/1`. **This is correct** for a Lockspire-owned resource and is not the bug.
- `examples/adoption_demo/lib/adoption_demo_web/router.ex:23-27` — pipeline mounts `VerifyToken → EnforceSenderConstraints → RequireToken` correctly, but `scripts/demo/adoption_smoke.py:235-244` only asserts `401` on anonymous and uses the stored token against `/userinfo`. **No issued Lockspire token is ever proven to flow through `Lockspire.Plug.VerifyToken`.**

Additionally, the plug carries real RFC 9068 / RFC 8725 compliance gaps that v1.27 must close **regardless of which design branch wins**:

- Missing `iss` claim enforcement (RFC 9068 §4 step 4, RFC 9700 mix-up class).
- Missing `typ: at+jwt` header enforcement (RFC 9068 §2.1, RFC 8725 §3.11) — enables silent cross-JWT confusion (ID token accepted as access token).
- Silent acceptance of JWTs without `exp` (RFC 9068 §2.2 makes `exp` REQUIRED).
- `WWW-Authenticate` challenge derived from the failure category instead of the token's binding shape — DPoP-bound failures returning a `Bearer` challenge loop the client (RFC 9449 §7.1).

DPoP-bound (RFC 9449) and mTLS-bound (RFC 8705) access tokens are already shipped end-to-end via `Lockspire.Plug.EnforceSenderConstraints` (consuming `binding_requirements` from `cnf.jkt` / `cnf["x5t#S256"]`). RFC 8707 Resource Indicators is already validated (v1.14). **v1.27 must not re-implement any of those — it must prove them against a Lockspire-issued access token that actually reaches the host-API plug.**

See: `.planning/research/STACK.md` Findings 1-8; `.planning/research/ARCHITECTURE.md` "The Tension in Two Sentences"; `.planning/research/FEATURES.md` "Framing"; `.planning/research/PITFALLS.md` Pitfall 1.

### Stack — No New Dependencies

**Headline:** No new Hex package is justified. v1.27 is a contract refactor on top of `:jose`, `:plug`, `:nimble_options`, `:ecto_sql`, `:postgrex`, and the existing in-tree `Lockspire.KeyCache` / `Storage.KeyStore`.

**Explicitly rejected additions:**

| Tempting addition | Why rejected |
|---|---|
| `:joken` or `:guardian` | Duplicates the shipped JOSE-direct verifier; broadens dependency surface for no gain. |
| External JWKS HTTP fetcher | Lockspire is the issuer; verifier reads in-process `KeyCache`. The existing `lib/lockspire/jwks_fetcher/` is for **client assertion** verification, a different code path. |
| RFC 7662 introspection client as the host-API verifier seam | Anti-feature trap — recreates gateway/CIAM productization PROJECT.md forbids; forces synchronous round-trip; defeats the embedded-library value proposition. |
| A generic "stored token verify" plug exported to host apps | Either couples host Repo to Lockspire's Repo or forces network introspection. Both violate the embedded-library boundary. |

**The one new verifier rule both design branches require:** explicit `typ: at+jwt` enforcement on the JWT path (one-line guard; RFC 8725 §3.11 motivation).

### Feature Categories

**Table stakes (must ship in v1.27 with docs + demo + CI):**

- **TS-1 / TS-3** — A Lockspire-issued access token actually flowing through `Lockspire.Plug.VerifyToken` end-to-end (the issuance shape depends on the Open Design Decision).
- **TS-4** — Route-level `aud` and `scope` enforcement preserved end-to-end (already shipped in the plug; needs round-trip proof against issued tokens).
- **TS-5 / TS-6** — DPoP-bound and mTLS-bound proof against issued access tokens (no new code; the enforcer is already shipped correctly through v1.22).
- **TS-7** — One authoritative adopter-facing answer: "this token shape protects host Phoenix APIs; this other shape is for Lockspire-owned resources." No more four-source-of-truth drift between demo, docs, plug docstring, and CI fixture.
- **TS-8 / TS-9** — Blessed adoption-demo path that drives an issued token through `/api/billing/summary` end-to-end, plus a CI smoke fence that fails loudly if drift returns.
- **Plug hardening pass** — `iss` enforcement, `typ: at+jwt` enforcement, mandatory `exp`/`iat`/`sub`, `WWW-Authenticate` scheme derived from binding shape (closes Pitfalls 3, 4, 6, 11, 12).
- **Audience mandatory in the blessed pipeline** — make `audience:` / `audiences:` effectively required (or document + assert via `release_readiness_contract_test`) so the demo's current "no audience" router stops being the bug-pattern (closes Pitfall 2).
- **Discovery metadata truth** for whatever issuance shape is chosen.

**Differentiators (flag for the roadmapper; not required to close v1.27):**

- **DIFF-2** — RFC 8707 resource indicators honored in JWT `aud` is essentially free since the runtime already lands in v1.14; strong candidate to fold into table stakes if implementation cost is trivial.
- **DIFF-1 / DIFF-4** — A second introspection-backed plug or a `mode:` knob — explicitly defer (recreates the ambiguity the milestone exists to delete).
- **DIFF-5** — Per-client format pinning — defer.
- **DIFF-6** — JWT acceptance at `/userinfo` for one-token-fits-everywhere — defer.

**Dependent on shipped surface (must NOT be re-implemented):**

`Lockspire.Plug.EnforceSenderConstraints`, `Lockspire.Plug.RequireToken`, `Lockspire.AccessToken`, `Lockspire.KeyCache`, `Lockspire.Storage.TokenStore`, `Lockspire.Protocol.TokenFormatter.hash_token/1`, `Lockspire.Protocol.Userinfo`, `Lockspire.Protocol.Introspection`, all FAPI 2.0 / DPoP / mTLS / Resource Indicators runtime, all discovery + JWKS publication.

### Architecture Integration — Where New Code Lands

**Stable surfaces — do not touch:** `EnforceSenderConstraints`, `RequireToken`, `AccessToken` struct shape, `Protocol.Introspection`'s HTTP `/introspect` (stays for remote callers + operator tooling), `Protocol.Userinfo`, `Storage.TokenStore` behaviour callbacks, `KeyCache`, every host seam in `lib/lockspire/host/`, every discovery key, the admin router.

**New code (shape depends on which design branch wins):**

- **Both branches need:** A shared signer module if `at+jwt` issuance is extended beyond RFC 8693 (`Protocol.AccessTokenSigner`, extracted from `rfc8693_exchange.ex:317-361`).
- **Both branches need:** Plug-hardening changes to `verify_token.ex` for `iss`, `typ: at+jwt`, mandatory `exp`/`iat`/`sub`, scheme-aware `WWW-Authenticate`.
- **JWT-only branch needs:** An issuance opt-in (per-client / per-server policy) so AC/refresh/device/CIBA paths can emit `at+jwt` when a client is configured for it; demo router gains a host-owned `/api/demo/me` route protected by `VerifyToken` with `audience:` and `resource=...` wired through.
- **Dual-verifier branch needs:** New internal modules under `lib/lockspire/plug/verify_token/` (`verifier.ex` dispatcher, `jwt_verifier.ex` extracted from the current path, `opaque_verifier.ex` calling `Storage.TokenStore.fetch_active_access_token/1` and projecting `%Domain.Token{}` into a synthetic claims map with `binding_requirements`).

**Generated-host scaffolding (both branches):** `priv/templates/lockspire.install/router.ex` gains a commented `:lockspire_protected_api` pipeline block mirroring whichever shape the demo proves.

### Watch Out For — Highest-Leverage Pitfalls

1. **Token-type confusion (Pitfall 1, Critical).** The reason this milestone exists. Any first adopter who copies the demo today gets `{:error, :malformed}` from `Lockspire.Plug.VerifyToken` on a valid Lockspire-issued opaque token. The fix is whichever design branch wins, *plus* a distinct `reason_code: :wrong_token_shape` so diagnostics are honest. Guard: end-to-end auth-code → `/api/billing/summary` → 200 in CI. **The smoke proving 401 on anonymous proves nothing.**
2. **Audience-substitution / cross-API token reuse (Pitfall 2, Critical).** `audience:` is currently optional on the plug, and the demo router uses no audience. Make audience effectively mandatory in the blessed pipeline (raise from `init/1` or assert via `release_readiness_contract_test` content scan).
3. **Issuer pinning gap (Pitfall 3, Critical).** `verify_signature_and_claims/2` does not validate `iss` against `Config.issuer!()`. RFC 9068 §4 step 4 mandates it; RFC 9700 names the mix-up class. Add the check + three negative test cases (missing/wrong/matching `iss`).
4. **JWT alg-confusion / signature-stripping regression (Pitfall 4, Critical).** The current `@allowed_algs ["RS256","ES256","PS256"]` + `JOSE.JWT.verify_strict/3` posture is correct. Freeze it via a `release_readiness_contract_test` literal-value assertion and add an explicit HS256-with-public-key-as-HMAC-secret rejection test. Symmetric verification on the RS side is **never** the right answer.
5. **DPoP / mTLS binding bypass when constraint enforcement is missing or out-of-order (Pitfall 5, Critical).** The three-plug split is correct internally but a known adopter footgun. Either ship a single composite `Lockspire.Plug.LockspireProtectedResource` for the blessed path, or have `RequireToken` fail closed when `binding_requirements` is non-nil but no `conn.private[:lockspire_sender_constraint_checked]` flag is set.
6. **WWW-Authenticate scheme mismatch on DPoP-bound failures (Pitfall 6, Critical→Moderate).** Today the challenge is derived from the failure category, not the token's binding shape. DPoP-bound audience/scope failures emit `Bearer` and clients loop. Drive challenge selection from `access_token.binding_type` and `access_token.authorization_scheme`.
7. **Missing `typ: at+jwt` enforcement (Pitfall 11, Moderate).** Without it, an ID token whose `aud` happens to line up gets accepted as an access token. Cross-JWT confusion is the named attack class; RFC 9068 §2.1 is explicit.
8. **Demo / docs / plug / CI four-source-of-truth drift (Pitfall 10, Moderate).** The named v1.27 problem. One canonical snippet, content-hashed across the four files, with the smoke proving `200 with issued token`, not just `401 anonymous`.

## Open Design Decision (REQUIRED — Must Resolve With User in Requirements)

**The four researchers converged on the diagnosis but split on the plug shape that resolves it. This decision drives every downstream phase. The synthesizer is explicitly not choosing.**

### Branch A — JWT-only plug (STACK + FEATURES position)

**One plug. JWT-only contract. Opaque tokens out of scope at the host-API seam.**

- `Lockspire.Plug.VerifyToken` is narrowed to RFC 9068 `typ: at+jwt` only.
- The `at+jwt` signing block in `rfc8693_exchange.ex:317-361` is extracted into a shared `Protocol.AccessTokenSigner`.
- AC / refresh / device / CIBA paths opt into `at+jwt` issuance via a per-client (or per-server) policy switch.
- Opaque tokens remain confined to Lockspire-owned resources (`/userinfo`, `/introspect`) where they already are.
- Adoption demo rewires to obtain an `at+jwt` access token (via the new opt-in) and proves it against a host-owned RS endpoint.
- Adopters who **do not** opt into `at+jwt` issuance get **no** host-API protection from `VerifyToken` — that fact is explicit, named, and documented in `docs/protect-phoenix-api-routes.md`.

**Argument:** Smaller plug surface. No in-process DB coupling promoted at the plug seam. The simplest possible RFC 9068 contract. The plug's docstring becomes literally true. The introspection-as-RS-seam temptation is structurally foreclosed.

**Conditional pitfalls this branch carries:**

- Adopters who never opt into `at+jwt` issuance silently get no protection from `VerifyToken`. Mitigation: loud docs + diagnostic emission + an opt-in default for the generated host scaffold.
- Demo migration cost: issuance opt-in must land before the demo can prove end-to-end through the plug.
- Per-client/per-server format policy is a new operator surface adopters must learn.

### Branch B — Dual-verifier plug (ARCHITECTURE position)

**One plug. Two internal verifiers. Lockspire knows what it issued; the verifier honors either shape.**

- `Lockspire.Plug.VerifyToken` keeps its public contract; internally splits into `Verifier` (dispatch on token shape — JWS three-segment vs opaque url-safe random) → `JwtVerifier` (current JOSE path) + new `OpaqueVerifier` (in-process `Storage.TokenStore.fetch_active_access_token/1`, same path `Protocol.Userinfo` already uses).
- The opaque verifier projects `%Domain.Token{}` into a synthetic claims map identical in shape to the JWT claims map (`iss`, `sub`, `client_id`, `scope`, `aud`, `exp`, `iat`, `cnf`).
- `EnforceSenderConstraints` and `RequireToken` consume `%AccessToken{}` unchanged.
- No new HTTP introspection client. No remote round-trip. The plug runs in the same BEAM that issued the token.
- Adoption demo rewires by adding **one** assertion: the same stored bearer it already obtains now also hits `/api/billing/summary` and gets 200 — no issuance change required.

**Argument:** Lockspire is embedded — host and Lockspire already share the BEAM and the DB. Refusing to look up tokens via the existing in-process path is artificially restrictive. The host controller cannot tell from `%AccessToken{}` whether the source was opaque or JWT, and it should not be able to — that is the architectural payoff. Adopters get protection on day one without an issuance opt-in.

**Conditional pitfalls this branch carries:**

- Doubled plug-internal surface (two verifier modules + dispatcher).
- In-process DB coupling becomes implicit at the route-protection seam. The `Storage.TokenStore` behaviour is already public, but its semantics shift from "AS-owned resolver" to "RS-owned resolver, in process."
- Cross-shape audience semantics differ subtly: JWT `aud` is a claim on the token; opaque `aud` is projected from `token.audience` populated at issuance from `interaction.resources_requested`. The projection must be byte-for-byte consistent with how `validate_audience/2` reads JWT `aud` (Pitfall 7).
- Token-shape detection (JWS three-segment vs base64url 32 bytes) needs to be unambiguous and CI-tested — a future change to `TokenFormatter` could collide with JWS shape.

### What the Two Branches Have in Common (Both Must Ship)

Both branches must close the same RFC 9068 / RFC 8725 / RFC 9449 gaps: `iss` enforcement, `typ: at+jwt` enforcement on the JWT path, mandatory `exp`/`iat`/`sub`, scheme-aware `WWW-Authenticate`, audience effectively mandatory in the blessed pipeline, the demo smoke proving `200 with issued token` instead of `401 anonymous`, one canonical snippet content-hashed across demo + docs + scaffolding + CI.

Both branches keep `Protocol.Introspection` exactly as it is and keep it out of the host-API route-protection seam.

### Recommended Resolution Path

The requirements step should choose Branch A or Branch B with the user explicitly, and the chosen branch should be recorded as a Key Decision in PROJECT.md before any phase planning. Picking one removes ambiguity that no later phase can recover from.

## Suggested Phase Shape (Advisory — Roadmapper Will Refine)

**Both branches share a phase backbone**; only Phase 3 differs by branch.

1. **Phase 1: Contract + docs first.** Single authoritative protected-route doc page lands stating (depending on resolution) either "JWT for host APIs, opaque only for Lockspire-owned resources" or "one plug, two shapes, Lockspire knows what it issued." Release-readiness assertions pin the contract.

2. **Phase 2: Plug hardening — RFC 9068 / RFC 8725 / RFC 9449 compliance pass.** `iss` enforcement, `typ: at+jwt` enforcement, mandatory `exp`/`iat`/`sub`, scheme-aware `WWW-Authenticate`, audience effectively mandatory. Negative tests for HS256-confusion, missing-typ ID-token-confusion, missing-iss. **Branch-independent.**

3. **Phase 3: Verifier delta (branch-specific).**
   - *Branch A:* extract `Protocol.AccessTokenSigner`; wire the per-client/per-server issuance opt-in for AC/refresh/device/CIBA; narrow `VerifyToken` to JWT-only.
   - *Branch B:* extract `JwtVerifier`; land `OpaqueVerifier` with synthetic-claims projection from `%Domain.Token{}`; land `Verifier` dispatcher with unambiguous shape detection.

4. **Phase 4: DPoP/mTLS composition proof.** Prove the chosen shape carries `cnf.jkt` / `cnf["x5t#S256"]` correctly through `EnforceSenderConstraints` and `RequireToken`. No new enforcer code — proof only.

5. **Phase 5: Adoption-demo re-wire (executable proof).** Smoke adds the canonical `auth-code → bearer → GET /api/billing/summary → 200` assertion. Audience set in the demo router. The existing `/userinfo` assertion stays.

6. **Phase 6: CI proof — repo-native.** End-to-end integration test driving the canonical pipeline against the demo's own issued token (not synthetic fixtures). `release_readiness_contract_test` clause asserting the one canonical snippet is content-hashed across docs/demo/scaffold/CI.

7. **Phase 7: Generated-host scaffolding update.** `priv/templates/lockspire.install/router.ex` gains the commented `:lockspire_protected_api` pipeline block mirroring whatever the demo proves. Install docs point at the Phase 1 doc page.

**Ordering rationale:** Contract first so docs are a contract the implementation honors, not a description of an accident (Phase 1 is non-negotiably first). Plug hardening is branch-independent and unblocks both branches (Phase 2 can run in parallel with Phase 1). The verifier delta (Phase 3) cannot land before the contract is named. Demo cannot prove end-to-end until the runtime accepts the chosen shape through the plug. Generated-host scaffolding must follow the demo (the scaffold mirrors what CI continuously proves).

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Branch A):** if chosen, the per-client/per-server format-policy surface and discovery metadata need a small targeted research pass (operator UX + `Storage.KeyStore` / `Domain.Client` schema implications).
- **Phase 3 (Branch B):** if chosen, the token-shape detection heuristic needs validation against `Protocol.TokenFormatter`'s output space — confirm no current or near-future opaque token can be mistaken for a JWS compact serialization.

Phases with standard patterns (skip research-phase):
- **Phases 1, 2, 4, 5, 6, 7** — RFC 9068 / RFC 8725 / RFC 9449 are explicit; the demo and scaffolding patterns are well-established in this codebase (v1.21, v1.22, v1.26 all set precedent).

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Stack | HIGH | Every relevant module read directly; RFC 9068 / 8725 / 7662 / 8693 / 8707 verified. No new dependency. |
| Features (table stakes) | HIGH | Grounded in direct code reads; gap is named in STATE.md and matches what the smoke fails to prove. |
| Architecture (mechanics) | HIGH | Both candidate shapes are mechanically sound; module boundaries verified. |
| Architecture (plug shape) | **OPEN** | Two coherent designs, both valid, with different operator/adopter consequences. Requires user resolution. |
| Pitfalls (codebase-grounded) | HIGH | Pitfalls 1, 2, 3, 5, 6, 7, 10, 11, 12, 15, 16 are direct reads of current code. |
| Pitfalls (RFC-mandated) | HIGH | Pitfalls 4, 11, 12, 13 grounded in explicit RFC text. |
| Pitfalls (conditional on Branch B) | MEDIUM | Pitfalls 7, 8 escalate if introspection-shaped resolution is chosen; mitigations identified. |

**Overall:** HIGH confidence on what must ship; **OPEN** on plug shape (single load-bearing decision for requirements to resolve).

### Gaps to Address

1. **Plug shape resolution.** The Open Design Decision above. Cannot be deferred past requirements.
2. **`aud` semantics for `at+jwt` minted with `resource=`** (whichever branch ships `at+jwt` issuance for AC/refresh/device/CIBA). RFC 9068 §3 expects the resource indicator as `aud`; the existing RFC 8693 path uses `client_id` for delegation. Recommendation: when `resource` is present, `aud = resource`; when absent on a delegation path, retain `aud = client_id` for backward compatibility. Confirm in requirements.
3. **Discovery metadata posture.** `access_token_signing_alg_values_supported` and any new format-advertisement key should be truthful, but the exact keys depend on Branch A vs Branch B. Low priority; flag for requirements.
4. **Replay-store durability story for DPoP at the RS** (Pitfall 13). Out-of-scope-for-v1.27 unless the user opts in — the gap exists today on the host-side `dpop_replay_store:` option. Flag.
5. **RAR-at-the-RS scope clarification** (Pitfall 9). Recommendation: `docs/supported-surface.md` explicitly says v1.27 RS contract is scope-based only; RAR enforcement stays host-owned via `conn.assigns.access_token`. Confirm in requirements.

## Sources

### Primary (HIGH confidence — direct in-tree reads, 2026-05-27)

- `lib/lockspire/plug/verify_token.ex`
- `lib/lockspire/plug/enforce_sender_constraints.ex`
- `lib/lockspire/plug/require_token.ex`
- `lib/lockspire/access_token.ex`
- `lib/lockspire/protocol/introspection.ex`
- `lib/lockspire/protocol/userinfo.ex`
- `lib/lockspire/protocol/token_formatter.ex`
- `lib/lockspire/protocol/rfc8693_exchange.ex`
- `lib/lockspire/protocol/authorization_flow.ex`
- `lib/lockspire/protocol/refresh_exchange.ex`
- `lib/lockspire/storage/token_store.ex`
- `lib/lockspire/key_cache.ex`
- `examples/adoption_demo/lib/adoption_demo_web/router.ex`
- `examples/adoption_demo/lib/adoption_demo_web/controllers/api_controller.ex`
- `scripts/demo/adoption_smoke.py`
- `priv/templates/lockspire.install/router.ex`
- `docs/protect-phoenix-api-routes.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- `mix.exs`

### Primary (HIGH confidence — IETF / OWASP)

- RFC 9068 — JWT Profile for OAuth 2.0 Access Tokens
- RFC 8725 — JWT Best Current Practices
- RFC 7662 — OAuth 2.0 Token Introspection
- RFC 8693 — OAuth 2.0 Token Exchange
- RFC 8707 — Resource Indicators for OAuth 2.0
- RFC 9449 — OAuth 2.0 DPoP
- RFC 8705 — OAuth 2.0 Mutual TLS
- RFC 9700 — OAuth 2.0 Security Best Current Practice
- RFC 9207 — OAuth 2.0 Authorization Server Issuer Identification
- RFC 6750 — Bearer Token Usage
- RFC 9396 — Rich Authorization Requests
- RFC 9701 — JWT Response for OAuth Token Introspection
- RFC 7519 — JSON Web Token

### Detailed research files

- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`

---
*Research synthesis: 2026-05-27. Ready for requirements pending resolution of the Open Design Decision (Branch A JWT-only vs Branch B dual-verifier plug shape).*
