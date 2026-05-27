# Feature Landscape: v1.27 Phoenix Resource Server Token Acceptance

**Domain:** Embedded OAuth/OIDC authorization-server library — Resource Server token acceptance for host Phoenix APIs.
**Researched:** 2026-05-27
**Confidence:** HIGH (grounded in shipped Lockspire surface inspection + RFC anchors).

## Framing

The milestone resolves one concrete contradiction inside the shipped library, not a greenfield design space:

- `Lockspire.Protocol.TokenFormatter` issues **opaque** access tokens (32 random bytes, URL-safe base64) at the token endpoint. The token-endpoint shape is **opaque-by-default** and verified server-side via `fetch_active_access_token(token_hash)` in `Lockspire.Protocol.Userinfo`.
- `Lockspire.Plug.VerifyToken` is **JWT-only**: it calls `JOSE.JWT.peek_protected(token)` to extract `kid`, fetches the key from `Lockspire.KeyCache`, and runs `JOSE.JWT.verify_strict/3` over `["RS256","ES256","PS256"]`. It cannot accept the opaque tokens Lockspire issues today.
- The adoption demo (`examples/adoption_demo`) calls `/lockspire/userinfo` with a Bearer header (AS-owned protected resource accepting the stored opaque token) and only proves the host `/api/billing/summary` returns `401` to anonymous requests. **It never proves a Lockspire-issued token actually reaches the host API plug.**

So this is not a "what RS features should we build?" exercise in the abstract. It is: pick the truthful host-API protection shape, make Lockspire's issued token actually verifiable through `Lockspire.Plug.VerifyToken`, and align demo + docs + CI on that one shape — without re-implementing what the introspection endpoint, `/userinfo` resolver, or the existing plug pipeline already provide.

## Table Stakes (must ship in v1.27 with docs + demo + CI)

These are the features required to remove first-adopter ambiguity at the RS token seam. Each is single-milestone-sized and directly traceable to a shipped surface.

| # | Feature | RFC Anchor | Complexity | Why It Is Table Stakes |
|---|---------|------------|------------|------------------------|
| TS-1 | Lockspire-issued **JWT access tokens (`typ: at+jwt`)** as the wire format consumed by `Lockspire.Plug.VerifyToken` | RFC 9068 | Medium | The plug already does JWT verify_strict; Lockspire already has a JWKS, key rotation, and `RS256/ES256/PS256` discipline. Closing this gap makes the existing plug do what its docstring already implies. |
| TS-2 | **Operator-selectable access-token format** per server policy (or per client): `opaque` (current default) vs `jwt` (RFC 9068) | RFC 9068 + RFC 7662 framing | Small–Medium | Without an explicit selector, opaque is the silent default and adopters keep tripping the plug. Operator truth must be loud. |
| TS-3 | **`Lockspire.Plug.VerifyToken` acceptance proof for Lockspire-issued JWT access tokens** under the new format — including `iss`, `aud`, `exp`, `nbf`, `iat`, `scope`, `client_id`, `jti` | RFC 9068 §2.2 | Small | Today's plug tests cover synthetic JWTs minted in-test. The blessed adoption story needs proof that `/lockspire/token` → plug works without test-only fixtures. |
| TS-4 | **Route-level audience (`aud`) and scope enforcement** preserved end-to-end across issuance and verification, including `scope` as space-delimited string | RFC 9068 §2.2.3, RFC 8707, RFC 6749 §3.3 | Small | Already exists in `VerifyToken.validate_audience/validate_scopes`. Table stakes is making issuance produce `aud`/`scope` claims that round-trip — the plug code path is already shipped. |
| TS-5 | **DPoP-bound RS validation on host routes** (already shipped via `EnforceSenderConstraints` + `ProtectedResourceDPoP`) explicitly retained and proven against a Lockspire-issued JWT access token with `cnf.jkt` | RFC 9449 §7 | Small (no new code; proof + docs) | The plug already reads `cnf.jkt`; the constraint enforcer is already shipped with nonce challenge/retry. The gap is that no end-to-end fixture proves Lockspire-issued JWT + DPoP proof + host plug today. |
| TS-6 | **mTLS-bound RS validation on host routes** (already shipped via `EnforceSenderConstraints` + `MTLSTokenBinding`) explicitly retained and proven against a Lockspire-issued JWT access token with `cnf["x5t#S256"]` | RFC 8705 §3 | Small (no new code; proof + docs) | Same shape as TS-5: `binding_requirements` parsing and `MTLSTokenBinding.confirmation_matches?/2` are shipped; what's missing is the issuance → plug round-trip evidence. |
| TS-7 | **One authoritative adopter-facing answer**: "for a host Phoenix API, use `Lockspire.Plug.VerifyToken` with JWT access tokens; for talking to Lockspire's own `/userinfo` or `/introspect`, use the stored opaque token Lockspire issues." | n/a (docs) | Small | The current ambiguity is itself the milestone goal per `STATE.md`. Without this explicit split, the rest is technically correct and operationally confusing. |
| TS-8 | **Blessed adoption-demo path** that drives a Lockspire-issued JWT access token through `/api/billing/summary` end-to-end (replacing the current "anonymous returns 401" half-proof) | n/a (CI) | Small | The demo is already wired with `Lockspire.Plug.VerifyToken` in the protected pipeline; it just never gets a real token to it. |
| TS-9 | **CI smoke fence** that fails loudly if `Lockspire.Plug.VerifyToken` cannot verify a freshly-issued token from the same Lockspire instance | n/a (CI) | Small | This is the durable drift guard that makes table stakes stay table stakes. |
| TS-10 | **Discovery metadata truth** for the chosen format (e.g., `access_token_signing_alg_values_supported`, JWT-format advertisement) and unchanged `introspection_endpoint` semantics | OIDC Discovery 1.0, RFC 7662 | Small | Keeps the supported-surface contract honest with the runtime; Lockspire already publishes discovery and JWKS. |

## Differentiators (worth flagging for the Roadmapper; NOT required to close v1.27)

These would distinguish Lockspire from "generic Phoenix bearer-plug" libraries and from token-only auth-server libraries, but each carries cost/benefit the Roadmapper should weigh against the sustainment default.

| # | Feature | RFC Anchor | Complexity | Cost / Benefit |
|---|---------|------------|------------|----------------|
| DIFF-1 | **Introspection-backed `Lockspire.Plug.VerifyToken` mode** for hosts who deliberately want opaque tokens at the host API (e.g., immediate revocation, no key distribution to RS) — selectable per pipeline | RFC 7662 | Medium–Large | Benefit: real choice for "I want a kill-switch on every API call." Cost: caching policy, replay vs revocation tradeoff, new failure modes, doubles the public plug surface to maintain. Recommend deferring to a later milestone unless adopter evidence demands it; v1.27 should state explicitly that this is _not_ the blessed path. |
| DIFF-2 | **Resource Indicators (RFC 8707) honored in issued JWT `aud`** so per-resource audience targeting on the host plug becomes a one-flag adopter story | RFC 8707 | Small | Benefit: meaningful; the indicator runtime is already shipped (validated in v1.14). Cost: small docs + one issuance touch-up. Strong candidate to fold into table stakes if the implementation cost is genuinely trivial; otherwise differentiator. |
| DIFF-3 | **JWT introspection responses (RFC 7662 + RFC 9701)** already shipped (v1.19) — explicitly position as the "AS-side equivalent" for hosts that pass introspection responses across trust boundaries | RFC 7662, RFC 9701 | Small (doc only) | Already shipped. Differentiator only in the sense that documenting it inside the RS story is differentiating; no new build. |
| DIFF-4 | **`Lockspire.Plug.IntrospectToken`** — a separate plug for the opaque-token-at-RS path, distinct from `VerifyToken`, to keep the JWT vs introspection shapes from leaking into one option-bag | RFC 7662 | Medium | Benefit: keeps each plug's contract honest. Cost: only valuable if DIFF-1 is opened. Bundle with DIFF-1 or skip. |
| DIFF-5 | **Per-client format pinning** (some clients always get JWT, others get opaque) | n/a | Medium | Benefit: nice for mixed partner-vs-internal client populations. Cost: another policy surface adopters must understand. Recommend deferring. |
| DIFF-6 | **`/userinfo` JWT access-token acceptance** so a single Lockspire-issued JWT can hit both the host API _and_ Lockspire's own `/userinfo` | RFC 9068 §4 | Medium | Today `/userinfo` only accepts the stored opaque token (`fetch_active_access_token(token_hash)`). Making it also accept JWT-format access tokens removes adopter confusion when both paths are exercised with the same token. Strong candidate but explicitly out of scope of the "host API protection" wedge unless we want one token to work everywhere. |

## Dependencies on Already-Shipped Lockspire Surfaces (the Roadmapper must NOT re-implement these)

The point of this section is to make sure phases don't try to rebuild what is already in the library.

| Capability | Where It Lives | What v1.27 Relies On / Must Not Touch |
|------------|----------------|---------------------------------------|
| Bearer / DPoP header extraction | `Lockspire.Plug.VerifyToken.extract_token/1` | Keep as-is. Both `Bearer` and `DPoP` schemes are already extracted. |
| JWT signature + standard-claims verification | `Lockspire.Plug.VerifyToken.verify_signature_and_claims/2`, `JOSE.JWT.verify_strict` with `["RS256","ES256","PS256"]` | Keep as-is. RFC 9068 only restricts algs further; never broaden. |
| JWKS / `kid` resolution | `Lockspire.KeyCache.get_key/1` | Keep as-is. Issued JWT access tokens use the same signing keys already published via discovery + JWKS. |
| Route-level scope + audience enforcement | `Lockspire.Plug.VerifyToken.validate_audience/validate_scopes` | Keep as-is. Already handles `aud` string-or-list and space-delimited `scope`. |
| `cnf.jkt` and `cnf["x5t#S256"]` parsing into `binding_requirements` | `Lockspire.Plug.VerifyToken.binding_type/binding_requirements` | Keep as-is. The plug already recognizes both bindings. |
| DPoP RS proof validation (incl. nonce challenge/retry, replay store) | `Lockspire.Plug.EnforceSenderConstraints`, `Lockspire.Protocol.ProtectedResourceDPoP` | Keep as-is. Already nonce-aware and shipped through v1.22. |
| mTLS RS thumbprint comparison | `Lockspire.Plug.EnforceSenderConstraints.maybe_validate_mtls`, `Lockspire.Protocol.MTLSTokenBinding.confirmation_matches?/2` | Keep as-is. |
| OAuth-shaped failure responses (`401 invalid_token`, `403 insufficient_scope`, `DPoP-Nonce` retry) | `Lockspire.Plug.RequireToken`, `Lockspire.Web.ProtectedResourceChallenge` | Keep as-is. RFC 6750 + RFC 9449 challenge shaping is already correct. |
| Opaque access-token storage and active-state lookup | `Lockspire.Protocol.TokenFormatter`, `Lockspire.Storage.Ecto.Repository.fetch_active_access_token/1` | Keep as-is. Whatever issuance does for JWT access tokens must still produce a stored token row for revocation + introspection truth. |
| Introspection endpoint (incl. JWT introspection responses) | `Lockspire.Protocol.Introspection`, `Lockspire.Protocol.IntrospectionJwt`, `Lockspire.Web.IntrospectionController` | Keep as-is. v1.27 changes _what's introspected_, not _how_. |
| `/userinfo` opaque-token resolution (incl. DPoP + mTLS binding) | `Lockspire.Protocol.Userinfo.fetch_claims/1` | Keep as-is. The demo's `/userinfo` Bearer call continues to work against the stored-opaque-token model; that path is correct, not the bug. |
| Discovery + JWKS publication | `Lockspire.Protocol.Discovery` | Extend metadata only; never re-implement. |
| FAPI 2.0 strict-mode enforcement | `Lockspire.Protocol.SecurityProfile`, `Lockspire.Protocol.Fapi20EnforcerPlug` | Keep as-is. Alg restrictions under the profile already match RFC 9068's allowed algs. |
| Resource Indicators audience targeting | `Lockspire.Protocol.ResourceIndicators` (v1.14) | Reuse for DIFF-2; do not re-derive. |

## Anti-Features (explicit non-goals — do NOT phase these in)

| Anti-Feature | Why Reject | What To Do Instead |
|--------------|-----------|--------------------|
| Hosted introspection cache or RS proxy service | Lockspire is an embedded library, not a gateway | If a host wants caching, document Plug-level memoization as a host-owned concern. |
| Generic JWT plug that accepts any issuer | Lockspire is _the_ issuer for Lockspire-issued tokens; the plug pins to `iss` from Lockspire config | State explicit single-issuer scope in docs. |
| Asymmetric vs symmetric algorithm parity for access-token signing (HS256, etc.) | Adds attack surface; RFC 9068 §4 prohibits `alg=none` and best practice is asymmetric only | Keep `["RS256","ES256","PS256"]` exactly. |
| Per-route introspection-vs-JWT auto-detection | Magic auto-detection is exactly the ambiguity the milestone exists to remove | Operator picks the format at the issuance seam; the plug expects exactly one shape per pipeline. |
| Custom claim extension framework for access tokens | Out of scope; current `claims` map is host-readable from `conn.assigns.access_token` already | Document the existing assigns contract. |
| Replacing the existing protected-resource pipeline | This is a clarification milestone, not a rewrite (per `<milestone_context>`) | Additive only: new format, same plug contract. |
| SAML / LDAP / auth-method parity work | Already in `PROJECT.md` Out of Scope | Reject at planning. |
| Hosted CIAM, service mesh, gateway productization | Already in `PROJECT.md` Out of Scope | Reject at planning. |
| Certification-breadth chasing beyond shipped claims | Already in `PROJECT.md` Out of Scope | Reject at planning. |

## Blessed Adoption Path Recommendation

**Single recommendation (per advisor mode default):** Ship **JWT bearer (RFC 9068) as the blessed host-API protection format**, with an explicit operator-selectable format selector for the token endpoint, and a loud doc split between "host API protection" (JWT, via the plug) and "talking to Lockspire's own `/userinfo` and `/introspect`" (stored opaque, via Lockspire endpoints).

**Why this and not "both with shape selector at the plug":**

1. The plug is already JWT-only in code. Making it accept JWT-formatted Lockspire-issued tokens is the smallest truthful delta — it makes the docstring become true, not the other way around.
2. JWT at the host API means no per-request network call from the host to Lockspire — which is the whole point of an _embedded_ provider sitting next to a Phoenix API.
3. The introspection-at-RS path (DIFF-1) doubles the public plug surface for a use case the demo does not exercise and no adopter has yet asked for. Per `STATE.md`, the sustaining default opposes adding plug-surface area without adopter evidence.
4. Hosts who want a kill-switch retain it through revocation: revocation already invalidates the token; JWT `exp` should stay short (minutes), and refresh rotation already handles the rest. The "but I want instant revocation" pressure point is real but rare, and the right answer for v1.27 is documentation, not a second plug.
5. The opaque-token path remains correct and shipped for AS-owned protected resources (`/userinfo`, `/introspect`). v1.27 does not delete it; it just stops conflating it with host-API protection.

**The operator selector should live at issuance, not at verification.** One plug shape, one issuance shape selectable per server policy (and/or per client). That keeps the host-side pipeline a single boring fact.

## Feature Dependencies

```
TS-1 (issue JWT access tokens RFC 9068)
  ├─ depends on: shipped TokenFormatter for opaque path
  ├─ depends on: shipped JWKS + key rotation
  └─ enables: TS-3 (issuance→plug end-to-end proof)

TS-2 (operator format selector)
  ├─ depends on: TS-1
  └─ enables: TS-7 (authoritative answer in docs)

TS-3 (end-to-end proof)
  ├─ depends on: TS-1, TS-2
  └─ enables: TS-8 (demo), TS-9 (CI fence)

TS-5 (DPoP-bound proof) and TS-6 (mTLS-bound proof)
  └─ both depend on: TS-1 (so the JWT carries cnf correctly), shipped EnforceSenderConstraints

TS-7 (docs split) and TS-10 (discovery metadata)
  └─ depend on: TS-1, TS-2 having landed first

TS-8 (demo) and TS-9 (CI) close the loop and must be the last gate.
```

## MVP Recommendation for the Roadmapper

Closing v1.27 with adopter-honest evidence requires, in order:

1. **TS-1** — Lockspire issues `at+jwt` access tokens (with `iss`, `aud`, `exp`, `iat`, `nbf`, `jti`, `client_id`, `scope`, plus existing `cnf` when sender-constrained).
2. **TS-2** — Operator can select `:opaque` (current default) vs `:jwt` at the server policy / client level, with truthful discovery + admin surfaces.
3. **TS-3 + TS-4** — End-to-end issuance → `Lockspire.Plug.VerifyToken` proof for `aud` and `scope` semantics.
4. **TS-5 + TS-6** — Same end-to-end proof with DPoP and mTLS sender-constrained variants (reusing the shipped `EnforceSenderConstraints` pipeline; no new code expected).
5. **TS-7** — Authoritative docs split (`docs/protect-phoenix-api-routes.md` updated to state JWT format expectation; `docs/adoption-demo.md` updated to call out the operator selector).
6. **TS-10** — Discovery metadata reflects the chosen format truthfully.
7. **TS-8 + TS-9** — Adoption demo drives a Lockspire-issued JWT token through `/api/billing/summary` and CI fails loudly if it ever stops working.

**Defer to a later milestone (or never):**

- DIFF-1 introspection-backed plug mode — defer; reopen only on explicit adopter evidence.
- DIFF-4 separate `IntrospectToken` plug — bundled with DIFF-1; defer.
- DIFF-5 per-client format pinning beyond simple policy — defer.
- DIFF-6 JWT acceptance at `/userinfo` — defer; today's stored-opaque path remains correct.

**Strong-candidate flip to table stakes if cost is trivial:** DIFF-2 (Resource Indicators honored in JWT `aud`). The runtime is already shipped; the only question is whether the issuance touch-up fits inside the same phase as TS-1. Flag this for the Roadmapper to evaluate.

## RFC Anchors Cited

- **RFC 9068** — JWT Profile for OAuth 2.0 Access Tokens. `typ: at+jwt`, required claims (`iss`, `aud`, `exp`, `iat`, `client_id`, `jti`), `scope` as space-delimited string, asymmetric algorithms.
- **RFC 7662** — OAuth 2.0 Token Introspection. Opaque-token validation contract via AS network call; explicitly the model Lockspire already implements at `/lockspire/introspect`.
- **RFC 9449** — OAuth 2.0 DPoP. RS validation of `cnf.jkt`, `htm`, `htu`, `ath`, `nonce`. Lockspire's `EnforceSenderConstraints` + `ProtectedResourceDPoP` are already RFC 9449-aligned through v1.22.
- **RFC 8705** — OAuth 2.0 Mutual TLS. `cnf["x5t#S256"]` resource-server confirmation. Shipped through v1.20.
- **RFC 8707** — Resource Indicators. `resource=` parameter → targeted `aud`. Shipped through v1.14.
- **RFC 6750** — Bearer Token Usage. `WWW-Authenticate` header shape. Shipped through `Lockspire.Plug.RequireToken`.
- **RFC 9701** — JWT Response for OAuth Token Introspection. Shipped through v1.19.

## Sources

- [RFC 9068 — JWT Profile for OAuth 2.0 Access Tokens](https://datatracker.ietf.org/doc/html/rfc9068)
- [RFC 7662 — OAuth 2.0 Token Introspection](https://datatracker.ietf.org/doc/html/rfc7662)
- [RFC 9449 — OAuth 2.0 Demonstrating Proof of Possession (DPoP)](https://datatracker.ietf.org/doc/html/rfc9449)
- [oauth.net — JWT Access Tokens for OAuth 2.0](https://oauth.net/2/jwt-access-tokens/)
- [Choosing Between JWKS and Token Introspection for OAuth 2.0 Token Validation](https://dev.to/mechcloud_academy/choosing-between-jwks-and-token-introspection-for-oauth-20-token-validation-1h9d)
- Repo-internal authoritative inspection (HIGH confidence):
  - `lib/lockspire/plug/verify_token.ex` — JWT-only verification path
  - `lib/lockspire/plug/enforce_sender_constraints.ex` — shipped DPoP/mTLS RS enforcement
  - `lib/lockspire/plug/require_token.ex` — shipped OAuth challenge shaping
  - `lib/lockspire/protocol/token_formatter.ex` — opaque-by-default issuance
  - `lib/lockspire/protocol/userinfo.ex` — stored-opaque acceptance at `/userinfo`
  - `lib/lockspire/protocol/introspection.ex` — RFC 7662 implementation
  - `examples/adoption_demo/lib/adoption_demo_web/router.ex` — already mounts the protected pipeline
  - `examples/adoption_demo/lib/adoption_demo_web/controllers/api_controller.ex` — already reads `conn.assigns.access_token`
  - `scripts/demo/adoption_smoke.py` — currently calls `/lockspire/userinfo` and verifies `401` on `/api/billing/summary` only
  - `docs/protect-phoenix-api-routes.md` — current adopter-facing contract
