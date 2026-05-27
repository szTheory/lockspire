# Technology Stack — v1.27 Phoenix Resource Server Token Acceptance

**Project:** Lockspire v1.27 — Phoenix Resource Server Token Acceptance
**Researched:** 2026-05-27
**Mode:** Ecosystem (scoped to one design decision)
**Overall confidence:** HIGH

## Headline Recommendation

**No new runtime dependencies are required for v1.27.** The shipped stack — JOSE, Plug, NimbleOptions, Ecto/Postgres, Phoenix — already covers every code path the milestone needs. The work is a **contract redesign on top of existing libraries**, not a library hunt.

What v1.27 actually needs is:

1. A documented, opinionated **shape contract** for `Lockspire.Plug.VerifyToken` that names "JWT bearer access token (RFC 9068 `typ: at+jwt`)" as the route-protection input, and explicitly rejects opaque stored tokens at the verifier seam.
2. A **second, narrowly-named verification path** for the small set of Lockspire-owned resource surfaces that legitimately consume opaque stored access tokens (today: `/userinfo`). This already exists as `Lockspire.Protocol.Userinfo` + `Storage.TokenStore.fetch_active_access_token/1`. It should NOT be promoted to a general host-app plug.
3. A blessed **issuance path** that mints `typ: at+jwt` access tokens for clients that intend to call host-app Phoenix APIs. Today only `Protocol.RFC8693Exchange` does this; v1.27 must extend the authorization-code / refresh / device / CIBA paths to optionally produce `at+jwt` access tokens — gated by a per-client or per-resource configuration that already has a natural home in `Storage.KeyStore` + `Domain.Client`.

Every one of those changes is a refactor and a contract write-down. No new Hex package is justified.

## Recommended Stack (Unchanged)

### Core (no version bumps required by this milestone)

| Technology | Current Version | Purpose in v1.27 | Why Unchanged |
|------------|-----------------|------------------|---------------|
| `:jose` | `~> 1.11` | Sign and verify `at+jwt` access tokens, validate `typ` header, pin allow-listed algs (`PS256`, `ES256`, `RS256`). Already used identically by `Lockspire.Plug.VerifyToken`, `Protocol.RFC8693Exchange`, `Protocol.IntrospectionJwt`, and `Protocol.Jar`. | JOSE is the canonical Erlang/Elixir JWT library; it already handles JWS, JWE, JWK, JWT, strict alg pinning (`JOSE.JWT.verify_strict/3`), and header peeking (`JOSE.JWT.peek_protected/1`). Nothing in the new contract requires functionality JOSE does not already expose. (HIGH — sourced from `lib/lockspire/plug/verify_token.ex:345-358` and `lib/lockspire/protocol/rfc8693_exchange.ex:340-348`.) |
| `:plug` (via Phoenix `~> 1.8.5`) | transitively current | Hosts `Lockspire.Plug.VerifyToken`, `Lockspire.Plug.EnforceSenderConstraints`, `Lockspire.Plug.RequireToken`. The v1.27 contract change is in plug behavior, not the plug API. | Plug's `init/1` + `call/2` model already lets the verifier reject non-JWT bearers cleanly without further infrastructure. |
| `:nimble_options` | `~> 1.1` | Already enforces `scopes:`, `audience:`, `audiences:` option validation on `Lockspire.Plug.VerifyToken.init/1`. v1.27 can add new options (e.g., a per-route `resource:` indicator, or a `:verifier` mode hint) through the existing schema. | `NimbleOptions` is the project's idiomatic plug-option validator; no replacement is justified. |
| `:ecto_sql` + `:postgrex` | `~> 3.13.5` / `>= 0.0.0` | `Storage.TokenStore` already persists opaque access tokens and looks them up by hash. The opaque-token path uses this; it is the substrate for any "stored token introspection" code path Lockspire-owned resources continue to rely on. | The opaque side of the world doesn't grow — it stays exactly where it is and is **explicitly fenced off** from `Lockspire.Plug.VerifyToken`. |
| `Lockspire.KeyCache` (in-tree) | n/a | Already serves verifier JWKs to `Lockspire.Plug.VerifyToken`. v1.27 must guarantee that the keys minted for the `at+jwt` signing path appear in this cache. | The cache already exists; v1.27 must enforce one rule (signer kid present in `KeyCache`), not introduce caching infrastructure. |

### What Is NOT Being Added

| Tempting Addition | Why Not |
|-------------------|---------|
| A "generic OAuth resource-server" Hex package (e.g., `:joken`, `:guardian`) | Lockspire already implements the strict verifier in `Lockspire.Plug.VerifyToken` using JOSE directly. Importing `:joken` or `:guardian` would duplicate behavior, broaden the dependency surface, and dilute the "Lockspire is the authority for Lockspire-issued tokens" story. (HIGH — verified against `lib/lockspire/plug/verify_token.ex`.) |
| An external JWKS HTTP fetcher dependency | Lockspire is the issuer. `KeyCache` reads `Storage.KeyStore` in-process. There is no remote JWKS fetch in the verifier path. The existing remote `jwks_uri` resolver (`lib/lockspire/jwks_fetcher/`) is for **client** assertion verification, not for verifying Lockspire-issued access tokens. Do not conflate. |
| A separate "introspection client" library that hosts can call to validate opaque tokens | This is the anti-feature trap. Promoting RFC 7662 introspection as the host-app route-protection story would (a) make every protected request a synchronous round-trip to Lockspire's introspection endpoint, (b) re-create the gateway/CIAM productization that PROJECT.md explicitly forbids, and (c) defeat the embedded-library value proposition. The shipped story stays: **JWT for host APIs, opaque only for Lockspire-owned resources.** |
| A new OWASP-named library | OWASP guidance (ASVS 4.0, OAuth/OIDC cheat sheets) maps to **practices** the existing verifier already enforces: strict alg allow-list, audience required, expiration check, `typ` header explicit typing. No library is named; the work is contract documentation. |

## Why No Library, In Detail

### Finding 1 — `Lockspire.Plug.VerifyToken` is already a JWT verifier; it has never been opaque-token aware

`lib/lockspire/plug/verify_token.ex` (read in this research):

- `extract_kid/1` calls `JOSE.JWT.peek_protected/1` — by definition the input must be a JWS compact serialization. Opaque random tokens crash that path and fall to `{:error, :malformed}`.
- `verify_signature_and_claims/2` uses `JOSE.JWT.verify_strict(jwk, ["RS256", "ES256", "PS256"], token)`.
- `fetch_key/1` resolves a `kid` against the in-process `KeyCache`.

This module physically cannot validate the 32-byte base64url opaque token that `TokenFormatter.format_access_token/1` produces (see `lib/lockspire/protocol/token_formatter.ex:29-34`). The ambiguity is purely at the **documentation and adoption-recipe layer**, not in the runtime contract.

(HIGH — direct code read.)

### Finding 2 — Lockspire already mints `at+jwt` access tokens, but only via RFC 8693 Token Exchange

`lib/lockspire/protocol/rfc8693_exchange.ex:340-348` already does:

```elixir
JOSE.JWT.sign(
  JOSE.JWK.from_map(jwk_map),
  %{"alg" => alg, "kid" => kid, "typ" => "at+jwt"},
  claims
)
```

with the seven RFC 9068 mandatory claims (`iss`, `exp`, `aud`, `sub`, `client_id`, `iat`, `jti`, plus `scope`). This is the exact shape `Lockspire.Plug.VerifyToken` was built to consume. The path exists; it is simply not the default for authorization-code / refresh / device / CIBA issuance today. v1.27's signing work is **lifting this same code shape into a shared issuer**, not bringing in a new JWT library.

(HIGH — direct code read of `rfc8693_exchange.ex:317-361`.)

### Finding 3 — The opaque-token resource path is Lockspire-internal and stays that way

`lib/lockspire/protocol/userinfo.ex:122-136` looks the access token up by SHA-256 hash via `Storage.TokenStore.fetch_active_access_token/1`. This is the **correct** path for `/userinfo` because `/userinfo` is owned by Lockspire and lives in the same BEAM node as the token store — no network round-trip, no extra contract, no need to expose this to host apps.

The trap to avoid: do not generalize this lookup into a "stored-token verify" plug for host-app Phoenix APIs. That would either (a) tightly couple host apps to Lockspire's Repo, or (b) force a network introspection hop, which is anti-thesis. (HIGH — direct code read.)

### Finding 4 — RFC 9068 is the right constraint document for the verifier contract

RFC 9068 (JWT Profile for OAuth 2.0 Access Tokens, October 2021, IETF Standards Track) defines the exact shape Lockspire-issued JWT access tokens should take and the exact shape `Lockspire.Plug.VerifyToken` should require. Verified against the spec:

- Mandatory claims: `iss`, `exp`, `aud`, `sub`, `client_id`, `iat`, `jti`. (HIGH — RFC 9068 §2.2, fetched directly.)
- `typ` header SHOULD be `at+jwt`. (HIGH — RFC 9068 §2.1.)
- `aud` MUST match the resource indicator from RFC 8707 when one was used at issuance. (HIGH — RFC 9068 §3.)
- RFC 9068 does NOT contemplate introspection as a substitute for JWT verification — it specifically enables direct stateless verification. That is the philosophical match for `Lockspire.Plug.VerifyToken`. (HIGH.)

### Finding 5 — RFC 8725 (JWT BCP) names the rules the existing verifier already enforces

`Lockspire.Plug.VerifyToken` already implements RFC 8725's required practices:

- §3.1 / §3.2 algorithm pinning: enforced via `@allowed_algs ["RS256", "ES256", "PS256"]` and `JOSE.JWT.verify_strict/3`. (HIGH — code read + spec read.)
- §3.8 issuer/key binding: enforced via `kid` → `KeyCache` lookup against Lockspire's own JWKS. (HIGH.)
- §3.9 audience validation: enforced via `validate_audience/2`. (HIGH.)
- §3.11 explicit typing: the existing verifier does **not** check `typ: at+jwt` today. v1.27 should add this check as the explicit boundary marker between "this is a Lockspire JWT access token" and "this is something else (and therefore not for this plug)." (HIGH — code read; this is the one verifier gap the milestone must close.)

The one new verifier rule that RFC 9068 + RFC 8725 jointly require — and that the shipped plug does not yet enforce — is `typ: at+jwt`. That is a one-line change inside `extract_kid/1` (or a sibling header check), not a dependency change.

### Finding 6 — RFC 7662 introspection is the WRONG primitive for the host-app route-protection seam

RFC 7662 (OAuth 2.0 Token Introspection) is designed for an authorization server to publish state about opaque tokens to a trusted resource server. Lockspire already implements `POST /introspect` (`lib/lockspire/protocol/introspection.ex`) and uses it for client tooling. The roadmap-relevant point is:

- Introspection is appropriate for **Lockspire-owned tooling and operator surfaces** (e.g., admin UI showing token state).
- Introspection is **inappropriate as the host-app route-protection contract** because it forces every protected API call into a synchronous network/IPC round-trip against Lockspire, and it re-introduces the "Lockspire as gateway" anti-feature.
- The RFC 9068 alternative — stateless JWT verification — is faster, scales horizontally, and matches the embedded-library shape.

The blessed contract should therefore be: **JWT for host APIs (stateless, `Lockspire.Plug.VerifyToken`); introspection for Lockspire-owned tooling only.** (HIGH — RFC 7662 plus design fit.)

### Finding 7 — RFC 8707 Resource Indicators already in the codebase; v1.27 leans on it, doesn't extend it

Resource Indicators (already validated in `v1.14`) is the protocol seam by which a client says "mint this access token for this resource server." It is the mechanism that lets a JWT access token's `aud` claim match the host-app's expected audience, and is exactly what the existing `audience:` / `audiences:` plug options pivot against.

v1.27 does not need to add anything to RFC 8707; it just needs the documented recipe to wire `resource=<host API URL>` through PAR/authorization → `aud` in issued `at+jwt` → `audience:` option on the host's `Lockspire.Plug.VerifyToken`. This is a docs/recipe deliverable. (HIGH — Resource Indicators already validated in v1.14.)

### Finding 8 — RFC 8693 audience handling is already correct in the codebase

`rfc8693_exchange.ex:327` sets `"aud" => client.client_id` for the exchanged JWT today. v1.27 should review whether the canonical `aud` for a host-API-targeted `at+jwt` should be the **client_id** (current behavior, useful for client-to-client delegation) versus the **resource indicator URL** (RFC 9068 §3 expected default). This is a contract decision, not a library decision. Recommended resolution: when a `resource` parameter is present, mint `aud = resource`; when absent on a delegation path, retain `aud = client_id` for backward compatibility. (MEDIUM — recommendation derived from RFC 9068 §3 + 8707 §2; existing code asserts the former.)

## Specific Contract Changes The Roadmap Should Plan For

These are stack-shaped notes for the roadmapper, not phase plans:

1. **`Lockspire.Plug.VerifyToken` gains explicit `typ: at+jwt` enforcement.** One-line guard in `extract_kid/1` or a sibling header check. RFC 8725 §3.11 motivation; RFC 9068 §2.1 specification. This is the boundary marker that makes the plug self-documenting about what it accepts.
2. **`Lockspire.Plug.VerifyToken` documents (in `@moduledoc`) that it accepts ONLY Lockspire-issued JWT access tokens** (`at+jwt` typed, signed by `Storage.KeyStore`, verified via `KeyCache`). Opaque tokens are out of scope — they 401 with `invalid_token` and a clear reason code.
3. **A new `Lockspire.AccessTokenFormat` (or extension to `Storage.KeyStore`/`Domain.Client`) per-client switch** chooses between opaque and `at+jwt` access-token issuance for authorization-code / refresh / device / CIBA paths. The signing block already exists in `rfc8693_exchange.ex` and should be extracted into a shared `Lockspire.Protocol.AccessTokenSigner` (or similar). No new library; refactor only.
4. **`/userinfo` and operator/admin paths continue to use opaque stored access tokens** with the existing `Storage.TokenStore.fetch_active_access_token/1` path. That is the explicit anti-mixing rule. The adoption demo's current "stored access token → `/userinfo`" path stays valid because `/userinfo` is a Lockspire-owned resource.
5. **Adoption demo gains a second protected route** (e.g., `/api/demo/me` mounted by the host) that uses `Lockspire.Plug.VerifyToken`, fed by an `at+jwt` access token minted via authorization-code with `resource=...` from RFC 8707. This makes the contract executable, demonstrable, and CI-provable.
6. **Discovery metadata** (`Lockspire.Protocol.Discovery`) should advertise `access_token_signing_alg_values_supported` and a truthful note about the dual-format issuance. (LOW — to be decided in the roadmap; discovery doesn't strictly require this for RFC 9068 conformance, but adopters benefit from explicit truth.)

## Anti-Features (Explicit Non-Goals That Affect the Stack Decision)

| Anti-Feature | Why Avoid in v1.27 |
|--------------|--------------------|
| Promote RFC 7662 introspection as the host-app route-protection seam | Recreates gateway/CIAM productization; forces synchronous network hop; defeats embedded-library value. |
| Add `:joken`, `:guardian`, `:assent`, or any third-party OAuth client/server library | All redundant with shipped JOSE-based verifier; would dilute Lockspire's "we are the authority for Lockspire-issued tokens" story. |
| Add a "remote JWKS fetcher for the verifier" code path | Lockspire is the issuer; the verifier reads in-process `KeyCache`. Remote `jwks_uri` is a **client assertion** verifier feature, not an access-token verifier feature. |
| Add a SAML/LDAP/federation library | Out of scope by PROJECT.md. |
| Add `oauth2_metadata_updater`-style RFC 8414 client tooling | Out of scope; the host-app side of Lockspire is the issuer, not a client of someone else's AS. |
| Add a generic "stored token verify" plug for host apps | Couples host Repo to Lockspire's Repo OR forces network introspection. Both violate the embedded-library boundary. |

## Integration Points With Existing Code

| Existing Module | v1.27 Touchpoint | Nature of Change |
|-----------------|------------------|------------------|
| `lib/lockspire/plug/verify_token.ex` | `extract_kid/1` + new `typ` check; `@moduledoc` rewrite | Contract narrowing + docs |
| `lib/lockspire/protocol/rfc8693_exchange.ex` (signing block lines 317-361) | Extracted into shared `Protocol.AccessTokenSigner` | Pure refactor |
| `lib/lockspire/protocol/token_formatter.ex` | Possibly gains a `:format` keyword (`:opaque` vs `:at_jwt`) | Additive |
| `lib/lockspire/storage/key_store.ex` | Becomes the canonical signing-key source for `at+jwt` access tokens (already is for RFC 8693) | No interface change |
| `lib/lockspire/key_cache.ex` | Must serve the signer's kid to verifiers in-process | No interface change; assertion only |
| `lib/lockspire/protocol/userinfo.ex` | Documented as Lockspire-owned resource using opaque tokens — not a model for host apps | Docs only |
| `lib/lockspire/protocol/introspection.ex` | Documented as operator/tooling primitive, not a host-app verifier path | Docs only |
| `lib/lockspire/protocol/discovery.ex` | Optional: publish `access_token_signing_alg_values_supported` truthfully | Additive metadata |
| `examples/adoption_demo/` | New host-owned protected route demonstrating `at+jwt` verification | Additive demo path |
| `docs/protect-phoenix-api-routes.md` | Becomes authoritative recipe with `at+jwt` shape, `resource=` wiring, `audience:` plug option | Rewrite |
| `docs/adoption-demo.md` | Calls out the boundary: `/userinfo` uses opaque (Lockspire-owned); demo API uses `at+jwt` | Rewrite |
| `docs/supported-surface.md` | Public truth: "JWT bearer for host APIs; opaque only for Lockspire-owned resources" | Add subsection |

## RFC and Spec Anchors

| Spec | What It Constrains in v1.27 |
|------|------------------------------|
| **RFC 9068** — JWT Profile for OAuth 2.0 Access Tokens | The canonical shape Lockspire-issued JWT access tokens MUST take. Mandatory claims, `typ: at+jwt`, explicit `aud` handling. Lockspire already meets this in the RFC 8693 path; v1.27 lifts the same shape into authorization-code/refresh/device/CIBA. |
| **RFC 8725** — JSON Web Token Best Current Practices | The verifier rules `Lockspire.Plug.VerifyToken` MUST enforce: strict alg allow-list (§3.1), key/issuer binding (§3.8), audience required (§3.9), explicit typing (§3.11). Of these, only §3.11 (explicit `typ: at+jwt` check) is not yet enforced today. |
| **RFC 7662** — OAuth 2.0 Token Introspection | The shape of Lockspire's introspection endpoint. v1.27 must explicitly say: introspection is for operator/tooling/Lockspire-owned consumption, not for host-app route protection. |
| **RFC 8693** — OAuth 2.0 Token Exchange | The existing JWT-issuing path. v1.27 generalizes its signing block, not its semantics. |
| **RFC 8707** — Resource Indicators for OAuth 2.0 | The wire mechanism by which a client signals "this `at+jwt` is for resource server X." Drives the `aud` claim that `Lockspire.Plug.VerifyToken`'s `audience:` option checks. Already validated in v1.14. |
| **RFC 6750** — Bearer Token Usage | The transport layer (`Authorization: Bearer …`). Already handled in `Lockspire.Plug.VerifyToken.extract_token/1`. No change. |
| **OWASP ASVS 4.0** (and OAuth/OIDC cheat sheets) | Confirms the verifier rules above. Not a library; not a code change. (MEDIUM — referenced; not directly cited line-by-line in this research.) |

## Installation

```bash
# Nothing to install for v1.27. Verify the current deps remain healthy:
mix deps.get
mix deps.audit
```

(HIGH — there are no new packages.)

## Sources

- `lib/lockspire/plug/verify_token.ex` (in-tree; direct read, 2026-05-27) — confirms the verifier is JWT-only via JOSE.
- `lib/lockspire/protocol/rfc8693_exchange.ex` (in-tree; direct read, 2026-05-27) — confirms `at+jwt` issuance shape already exists in the codebase.
- `lib/lockspire/protocol/token_formatter.ex` (in-tree; direct read, 2026-05-27) — confirms the default access-token format is a 32-byte opaque random string.
- `lib/lockspire/protocol/userinfo.ex` (in-tree; direct read, 2026-05-27) — confirms `/userinfo` consumes opaque stored access tokens.
- `lib/lockspire/protocol/introspection.ex` (in-tree; direct read, 2026-05-27) — confirms RFC 7662 endpoint exists today.
- `lib/lockspire/storage/token_store.ex` (in-tree; direct read, 2026-05-27) — confirms the opaque-token persistence contract.
- `mix.exs` (in-tree; direct read, 2026-05-27) — confirms the current dependency set (`:jose`, `:plug`, `:nimble_options`, `:ecto_sql`, `:postgrex`, `:phoenix`).
- [RFC 9068 — JWT Profile for OAuth 2.0 Access Tokens](https://datatracker.ietf.org/doc/html/rfc9068) (IETF Standards Track, October 2021; verified directly).
- [RFC 8725 — JSON Web Token Best Current Practices](https://datatracker.ietf.org/doc/html/rfc8725) (IETF BCP, February 2020; verified directly).
- [RFC 7662 — OAuth 2.0 Token Introspection](https://datatracker.ietf.org/doc/html/rfc7662) (IETF Standards Track, October 2015; spec known and cross-referenced with codebase implementation).
- [RFC 8693 — OAuth 2.0 Token Exchange](https://datatracker.ietf.org/doc/html/rfc8693) (IETF Standards Track, January 2020; already validated in v1.12).
- [RFC 8707 — Resource Indicators for OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc8707) (IETF Standards Track, February 2020; already validated in v1.14).

## Confidence Summary

| Claim | Confidence |
|-------|------------|
| No new runtime dependency is required | HIGH (direct code reads of every relevant module + spec reads) |
| `Lockspire.Plug.VerifyToken` is JWT-only today | HIGH (direct code read) |
| RFC 9068 `at+jwt` is the right contract shape | HIGH (RFC verified) |
| The verifier needs an added `typ: at+jwt` check | HIGH (verifier code read confirms it does not check `typ` today; RFC 8725 §3.11 motivates the fix) |
| Introspection (RFC 7662) is the wrong primitive for host-app route protection | HIGH (architectural fit + PROJECT.md anti-features) |
| The signing block in `rfc8693_exchange.ex` should be extracted to a shared module | MEDIUM (recommendation; the roadmap may choose alternatives such as adding the signer block inline at each issuance path) |
| `aud` for a `resource=`-bearing `at+jwt` should be the resource indicator URL | MEDIUM (RFC 9068 §3 expected default; existing code uses `client_id` for the delegation path) |
| Discovery should publish `access_token_signing_alg_values_supported` | LOW (nice-to-have; not required for the verifier contract) |
