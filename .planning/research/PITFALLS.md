# v1.27 Research: Pitfalls — Phoenix Resource Server Token Acceptance

**Scope.** Pitfalls that arise specifically when adding "Resource Server token acceptance" to a system (Lockspire) that already issues both stored opaque access tokens (auth-code, refresh, device, CIBA) and JWT-shaped access tokens (RFC 8693 token exchange with host-provided custom claims). The pre-v1.27 archived PITFALLS.md is the `client_secret_jwt` baseline; do not duplicate it.

**How to read this.** Each pitfall has:
- **Warning sign** — how it shows up in code, docs, or runtime.
- **Prevention** — concrete countermeasure in this codebase.
- **Coverage owner** — which phase or test should address it so the roadmap can map pitfalls to coverage.

Severity legend: **Critical** = security or correctness break that can wreck adopter trust; **Moderate** = drift that costs support time and erodes the GA support contract; **Minor** = ergonomic / cleanup.

---

## Critical Pitfalls

### Pitfall 1: Token-type confusion — stuffing a stored opaque token into the JWT verifier path (Critical)

The library issues 32-byte opaque random strings at `/token` (see `lib/lockspire/protocol/token_formatter.ex`) for every grant except RFC 8693 with host custom claims. `Lockspire.Plug.VerifyToken` runs `JOSE.JWT.peek_protected/1` and `JOSE.JWT.verify_strict/3` on whatever it gets, so a perfectly valid opaque access token hits `extract_kid/1`, raises inside `JOSE.JWS.to_map/1`, and falls through to `{:error, :malformed}` → generic `invalid_token`. The adoption demo masks this: it uses the issued opaque token against Lockspire `/userinfo`, not against the host's `Lockspire.Plug.VerifyToken`-protected `/api/billing/summary` route. Adopters following the demo will copy the token-acquisition pattern, then be confused when the same token is rejected as `invalid_token` by their host API. This is the central v1.27 tension.

**Warning sign:** `extract_kid/1` returning `{:error, :malformed}` or `{:error, :no_kid}` whenever the demo's `access_token` is sent at the protected route. The same token works at `/lockspire/userinfo` (which looks up by hash) but fails at any `VerifyToken`-guarded route. Logs show `event: :lockspire_verify_token_failed, reason_code: :malformed` for tokens that are otherwise active per `/introspect`.

**Prevention:**
- Pick the blessed RS token shape once and document it: either (a) JWT bearer (RFC 9068 `typ: at+jwt`) for `VerifyToken` routes with opaque tokens only at Lockspire-owned endpoints, or (b) make `VerifyToken` dispatch on token shape (JWT vs opaque-via-introspection) with the same `%Lockspire.AccessToken{}` contract.
- If (a): rename/scope the plug to make the JWT-only contract obvious (e.g. require an explicit `verifier: :jwt` option) and emit a *distinct* `reason_code: :wrong_token_shape` (not `:malformed`) when a non-JWT bearer hits the JWT verifier — adopter diagnostics should not require knowing the difference between JOSE compact serialization and 32-byte base64url.
- If (b): keep one `AccessToken` struct contract; the introspection branch fills `claims` with the same atom-keyed shape (`"client_id"`, `"scope"`, `"aud"`, `"exp"`, `"cnf"`).
- Add a CI assertion that an end-to-end auth-code grant against the demo issuer produces a token the canonical pipeline accepts. This single test (auth-code → `/api/billing/summary`) is the milestone-close audit criterion.

**Coverage owner:** Plug-shape decision phase + a new `integration/v1_27_blessed_rs_acceptance_e2e_test.exs` that runs auth-code → bearer → 200 from `/api/billing/summary` against the demo router.

**References:** [RFC 9068 §4 — Validating JWT Access Tokens](https://datatracker.ietf.org/doc/html/rfc9068#section-4); current `verify_token.ex` lines 326-358; `token_formatter.ex` (opaque-only output).

---

### Pitfall 2: Audience-substitution / cross-API token reuse (Critical)

`VerifyToken` already supports route-level `audience:` / `audiences:` checks, but the `audience` route option is **optional** (`required: false`). A pipeline that omits it — including the `:lockspire_protected_api` pipeline shown in `docs/protect-phoenix-api-routes.md` when used without an `audience:` option — accepts any valid Lockspire-issued JWT regardless of the `aud` claim. In a host running multiple Phoenix APIs (`billing-api`, `ledger-api`, `admin-internal`), a token minted for `billing-api` will pass the verifier on the `ledger-api` route. This is the classic JWT audience-substitution attack ([WorkOS — How to validate aud](https://workos.com/blog/how-to-validate-the-jwt-aud-claim-and-why-it-matters), [VulnAPI — JWT cross-service relay](https://vulnapi.cerberauth.com/docs/vulnerabilities/broken-authentication/jwt-cross-service-relay-attack)), and RFC 9068 §4 mandates rejection when `aud` does not contain the resource indicator.

**Warning sign:** A pipeline using `Lockspire.Plug.VerifyToken` without an `audience:` or `audiences:` option, especially in code that documents itself as protecting "the API" rather than one specific resource. Audit `examples/adoption_demo/lib/adoption_demo_web/router.ex` — line 24 currently sets `scopes: ["read:billing"]` but has **no audience**. That is the bug-pattern the milestone must not bless.

**Prevention:**
- Make `audience:` (or `audiences:`) effectively mandatory in the blessed pipeline. Either raise from `init/1` when neither is set (loudest), or have the *generated* host pipeline always pass one and have docs/demos never show an example without one.
- The demo router must be updated to set `audience:` to a stable demo identifier, and the issuance side must mint with `resource=` (RFC 8707) so the JWT actually carries that `aud`.
- Add an in-repo `release_readiness_contract_test` assertion that scans `docs/protect-phoenix-api-routes.md` and `examples/adoption_demo/lib/**/*.ex` for any `Lockspire.Plug.VerifyToken` usage missing an audience — pin via a regex or AST scan so future drift is loud.

**Coverage owner:** Blessed adoption recipe phase + docs/demo synchronization phase. Guard test: `release_readiness_contract_test` AST scan and a `VerifyToken.init/1` change.

**References:** [RFC 9068 §4](https://datatracker.ietf.org/doc/html/rfc9068#section-4), [RFC 8707 §2.2](https://www.rfc-editor.org/rfc/rfc8707.html#section-2.2), [Ping Identity — Multi-resource access token strategies](https://www.pingidentity.com/en/resources/blog/post/oauth-2-access-token-usage-strategies-multiple-resources-apis-pt-3.html).

---

### Pitfall 3: Issuer pinning gap when Lockspire is embedded (Critical)

`VerifyToken.verify_signature_and_claims/2` validates `exp` and `nbf` but **does not validate `iss`**. In an embedded deployment the host's Lockspire issuer is `Config.issuer!()`, but the JOSE verifier only proves "signed by a key in our `KeyCache`" — and `KeyCache` is the host's own JWKS. That is *almost* good enough, but RFC 9068 §4 step 4 mandates `iss` validation, and once a generated host runs multiple environments (staging issuer, production issuer) or proxies to a sibling Lockspire instance, the absence of `iss` pinning becomes an issuer-confusion vector. The mix-up class is well-documented ([RFC 9700 BCP — Mix-up](https://datatracker.ietf.org/doc/rfc9700/), [RFC 9207](https://datatracker.ietf.org/doc/html/rfc9207)).

**Warning sign:** `verify_signature_and_claims/2` only checks `exp`/`nbf`. There is no test in `verify_token_test.exs` that exercises a JWT signed by the right key but bearing the wrong `iss`. The RFC 8693 emitter at `rfc8693_exchange.ex:325` correctly stamps `iss => Config.issuer!()`, but nothing on the RS side enforces a match.

**Prevention:**
- Add a mandatory `iss` claim check in `verify_signature_and_claims/2` against `Config.issuer!()` (or an explicitly-configured `expected_issuer:` plug option for hosts that run Lockspire on a sub-issuer).
- Add `verify_token_test.exs` cases: (a) missing `iss` → reject, (b) wrong `iss` → reject, (c) matching `iss` → accept.
- Document in `docs/protect-phoenix-api-routes.md` that issuer pinning is automatic and host-owned changes to `Config.issuer!()` require token revocation discipline.

**Coverage owner:** Plug hardening phase. Guard test: extend `verify_token_test.exs` with the three issuer cases above.

**References:** [RFC 9068 §4 step 4](https://datatracker.ietf.org/doc/html/rfc9068#section-4), [RFC 9700 — Mix-up](https://datatracker.ietf.org/doc/rfc9700/), [RFC 9207](https://datatracker.ietf.org/doc/html/rfc9207).

---

### Pitfall 4: JWT alg-confusion and signature-stripping regression (Critical)

`VerifyToken.@allowed_algs` is `["RS256", "ES256", "PS256"]` and it uses `JOSE.JWT.verify_strict/3`, which is the correct primitive — it pins the accepted alg list against the *server side*, not the token header. That posture is sound today. The pitfall is *regression*: a well-meaning future change that (a) widens `@allowed_algs` to include `HS256` to "match `client_secret_jwt`", (b) replaces `verify_strict/3` with `verify/2` to "support multiple keys", or (c) accepts `none` for development. Each of those is a known exploit class ([WorkOS — JWT alg confusion](https://workos.com/blog/jwt-algorithm-confusion-attacks), [PortSwigger Academy](https://portswigger.net/web-security/jwt/algorithm-confusion)). RFC 8725 §3.1 mandates an explicit alg allowlist; widening the RS-side allowlist to symmetric algorithms turns the published JWKS public key into a forge-the-token primitive.

**Warning sign:** any diff that touches `@allowed_algs`, swaps `verify_strict/3` for `verify/2`, or imports HS-family algs into the protected-resource path. Symmetric verification on the RS side is **never** the right answer — `client_secret_jwt` (HS256) is for *authorization-server-side client auth*, not for access-token verification at the RS.

**Prevention:**
- Add a `release_readiness_contract_test` that asserts the literal value of `@allowed_algs` and that `JOSE.JWT.verify_strict/3` is the call used in `verify_token.ex`. This is a "freeze this line" assertion, intentionally annoying to change.
- Document in `docs/protect-phoenix-api-routes.md` and the verify-token moduledoc: "RS-side verifier is asymmetric-only by construction. HS-family algorithms are reserved for client authentication."
- Add an explicit negative test: HS256-signed token (signed with the published JWKS public key bytes as the HMAC secret) must be rejected. This is the literal alg-confusion exploit reproduced.

**Coverage owner:** Plug hardening phase. Guard test: literal contract pin + negative HS256 test in `verify_token_test.exs`.

**References:** [RFC 8725 §3.1](https://datatracker.ietf.org/doc/html/rfc8725#section-3.1), [PortSwigger — Algorithm confusion](https://portswigger.net/web-security/jwt/algorithm-confusion).

---

### Pitfall 5: DPoP / mTLS binding bypass when the token is JWT but the proof is missing (Critical)

`VerifyToken.binding_type/1` reads `cnf.jkt` / `cnf.x5t#S256` and *records* the binding, but it does not enforce it — enforcement is the job of `Lockspire.Plug.EnforceSenderConstraints`. If a host pipeline mounts `VerifyToken` and `RequireToken` but forgets `EnforceSenderConstraints` (or mounts it after `RequireToken`), a DPoP-bound JWT will pass the verifier as a plain bearer because `RequireToken` only checks `error: nil` and `claims != nil`. The token's `cnf.jkt` is recorded in the assigns but never compared against an actual `DPoP:` header. That is a sender-constraint bypass.

**Warning sign:** A `:lockspire_protected_api` pipeline that mounts only `VerifyToken` + `RequireToken` and skips `EnforceSenderConstraints`. Or any pipeline that mounts the three plugs out of order (e.g. `EnforceSenderConstraints` before `VerifyToken`, which makes the constraint a no-op because `conn.assigns[:access_token]` is not yet populated). Adopters who copy the "Scope-restricted route example" or "Audience-restricted route example" in `docs/protect-phoenix-api-routes.md` without also copying `EnforceSenderConstraints` will silently downgrade DPoP-bound tokens to bearer.

**Prevention:**
- Make the three plugs a single, opinionated composite plug for the blessed path (e.g. `Lockspire.Plug.LockspireProtectedResource`) that mounts the canonical order internally and exposes one option surface. The current three-plug split is correct internally but is a known footgun for adopters.
- If keeping three plugs: have `RequireToken` *refuse to halt-accept* when `binding_requirements` is non-nil but no constraint enforcement has run. Track an internal `conn.private[:lockspire_sender_constraint_checked]` flag from `EnforceSenderConstraints`. If `RequireToken` sees `binding_requirements: %{...}` and that flag is absent, fail closed with a maintainer-grade log.
- Add `verify_token_test.exs` (or pipeline-level) cases for: (a) DPoP-bound JWT + no `DPoP:` header + missing `EnforceSenderConstraints` → must fail closed, (b) mTLS-bound JWT + no cert + missing extractor → must fail closed.

**Coverage owner:** Pipeline-shape phase (decide composite plug vs assertion in `RequireToken`). Guard test: dedicated pipeline-composition test that fails closed when constraints are absent.

**References:** [RFC 9449 §7](https://datatracker.ietf.org/doc/html/rfc9449#section-7), [draft-ietf-oauth-dpop mailing list — multi-scheme protected resources](https://mailarchive.ietf.org/arch/msg/oauth/9urd8n9wbArhSQisTc6KOsUhuuI/), current `enforce_sender_constraints.ex` lines 56-78.

---

### Pitfall 6: WWW-Authenticate scheme mismatch — Bearer challenge for a DPoP-bound failure (Critical→Moderate)

`RequireToken.handle_invalid_token/2` defaults the challenge to `Bearer` unless the error has `category: :sender_constraint` with `challenge: :dpop`. But the upstream `VerifyToken` failure paths set `challenge: :bearer` for audience/scope failures, even when the route is DPoP-only and the token was DPoP-bound. The client will see a `Bearer` challenge, retry without a `DPoP:` proof, and loop. RFC 9449 §7.1 and the mailing list thread above explicitly call this out: "the scheme is needed for the protected resource to form the correct WWW-Authenticate challenge."

**Warning sign:** Negative-path response on a DPoP-bound JWT route returning `WWW-Authenticate: Bearer realm="Lockspire", error="insufficient_scope"` instead of `WWW-Authenticate: DPoP realm="Lockspire", error="insufficient_scope"`. Audit `require_token.ex` lines 121-132 (`www_authenticate/1`) — the challenge is determined by the *error* not by the *token's binding type*.

**Prevention:**
- When `access_token.binding_type` is `"dpop"` or `"dpop+mtls"`, `RequireToken` should construct the DPoP challenge for *all* failure categories, not just `:sender_constraint`. Audience and scope failures on DPoP-bound tokens should challenge `DPoP`.
- When the request used `Authorization: DPoP ...`, the challenge must be `DPoP` regardless of `binding_type` (the client signaled DPoP intent). `access_token.authorization_scheme` is already captured (`"DPoP"` vs `"Bearer"`) — use it to drive challenge selection.
- Add `require_token_test.exs` cases: (a) DPoP-bound JWT + audience mismatch → `WWW-Authenticate: DPoP ... error="invalid_token"`, (b) DPoP request scheme + scope mismatch → `WWW-Authenticate: DPoP ... error="insufficient_scope"`.

**Coverage owner:** Plug hardening phase. Guard test: extend `require_token_test.exs`.

**References:** [RFC 9449 §7](https://datatracker.ietf.org/doc/html/rfc9449#section-7), [OAuth WG mailing list — multi-scheme](https://mailarchive.ietf.org/arch/msg/oauth/9urd8n9wbArhSQisTc6KOsUhuuI/).

---

### Pitfall 7: RFC 8707 `resource` → `aud` binding drift (Critical)

Lockspire claims `resource_indicators_supported` in discovery, and the authorization/token endpoints accept `resource=` per RFC 8707. The pitfall is the half-binding: the AS accepts the parameter (so discovery is truthful) but the *opaque* access tokens stored in the DB carry only the audience list inside `Token.audience`, not inside a JWT `aud` claim — and `VerifyToken` reads `claims["aud"]`. For opaque tokens accepted via introspection (if v1.27 adds that path), the introspection response *does* surface `aud` (see `introspection.ex:146`), and that must map to the same audience-check semantics as a JWT `aud`. If it does not, RFC 8707's whole purpose — preventing cross-API token reuse — silently fails for the opaque side. Multi-tenant hosts are the worst affected ([RFC 8707 §2.2](https://www.rfc-editor.org/rfc/rfc8707.html#section-2.2): "use a specific resource URI including any portion of the URI that identifies the tenant").

**Warning sign:** A `resource=https://billing.example.com` parameter on a token request that produces a token accepted by `https://ledger.example.com`'s `VerifyToken` because the audience-check was skipped (no `audience:` set) or because the introspection-fed `AccessToken.claims["aud"]` shape differs from the JWT shape.

**Prevention:**
- One shared `AccessToken.claims` shape: whether populated from JWT decode or from introspection response, `aud` must be either a non-empty string or non-empty list of strings, never absent for the canonical RS pipeline.
- Add a guard test that issues an opaque token with `resource=billing-api` and proves the same token is rejected by a route bound to `audience: "ledger-api"`, both via the JWT-bearer path and via the introspection path (if introspection-based RS validation ships in v1.27).
- Discovery `resource_indicators_supported: true` must imply the AS *binds* the resource to the audience — add a release-readiness assertion that fails if the discovery key is true but no end-to-end test proves the binding.

**Coverage owner:** Audience-binding phase. Guard test: cross-resource rejection e2e, both shapes.

**References:** [RFC 8707 §2.2](https://www.rfc-editor.org/rfc/rfc8707.html#section-2.2), [Ping Identity multi-resource strategies](https://www.pingidentity.com/en/resources/blog/post/oauth-2-access-token-usage-strategies-multiple-resources-apis-pt-3.html).

---

## Moderate Pitfalls

### Pitfall 8: Introspection caching → stale revocation visibility (Moderate)

If v1.27 introduces an introspection-based RS path for opaque tokens, the natural performance reflex is to cache introspection responses. Industry guidance is "cache briefly, evict on revoke" ([Scalekit — RFC 7662 caching](https://www.scalekit.com/blog/oauth-2-0-token-introspection-rfc-7662)), but in an embedded library where the AS and RS are *in the same BEAM*, the cache layer is doubly tempting — and a stale cache after `/revoke` is a known broken-by-default pattern. Worse: an embedded library that ships a cache module that adopters then use across *separate* BEAM nodes will get the stale-after-revoke surface without any of the same-BEAM optimisations.

**Warning sign:** An in-library introspection cache with a TTL longer than the access-token lifetime tolerance, or an adopter-visible cache API that does not invalidate on `revoke_at` change. Any cache that does not key on the token hash and the `revoked_at` timestamp.

**Prevention:**
- If v1.27 ships introspection-based RS validation, **do not** ship a cache layer at the same time. Make the first slice cache-free and document the latency posture explicitly.
- If a cache is unavoidable, key on `(token_hash, observed_revoked_at)` and force a re-introspect when any `Lockspire.Domain.Token` revocation fires (revocation already runs in the same BEAM — emit a `Phoenix.PubSub` or telemetry event the cache can subscribe to).
- Add a guard test: revoke a token, then prove the next protected-route request returns 401 within the introspection cycle, with TTL set to a representative production value.

**Coverage owner:** Introspection-RS phase (only if that path is in scope for v1.27). Guard test: revoke-then-call within TTL.

**References:** [RFC 7662](https://datatracker.ietf.org/doc/html/rfc7662), [Scalekit — Introspection caching](https://www.scalekit.com/blog/oauth-2-0-token-introspection-rfc-7662), [Spring Security — Opaque token](https://docs.spring.io/spring-security/reference/reactive/oauth2/resource-server/opaque-token.html).

---

### Pitfall 9: Scope-vs-RAR-vs-resource-indicator semantic confusion at the RS (Moderate)

The current `VerifyToken` enforces `scopes:` (route-level required scopes) as an `Enum.all?` over the token's space-delimited `scope` claim. It does **not** consider `authorization_details` (RAR). Lockspire already supports RAR intake at the AS and exposes `authorization_details` in the introspection response. An adopter doing fine-grained PSD2-style consent ([authlete on RAR](https://www.authlete.com/kb/oauth-and-openid-connect/authorization-requests/rich-authorization-requests/)) will be tempted to also enforce RAR at the route — and discover that the plug ignores it. Worse, an adopter may *replace* `scope` with RAR ([RFC 9396 §11](https://datatracker.ietf.org/doc/html/rfc9396#section-11) explicitly allows coexistence) and then have routes that protect with `scopes:` but the token has none — false-negatives, locked-out clients.

**Warning sign:** Discovery advertises `authorization_details_types_supported`, but the RS plug has no `authorization_details:` option. Adopters writing custom `plug :enforce_rar` handlers downstream of `VerifyToken` because the canonical plug does not address it.

**Prevention:**
- For v1.27: explicitly scope-down the RS contract to *scope-based authorization only*. The plug enforces `scopes:` and `audience:`; RAR enforcement at the RS is *not* in the v1.27 blessed contract. Document this in `docs/protect-phoenix-api-routes.md` and `docs/supported-surface.md`.
- Surface `access_token.claims["authorization_details"]` (or via introspection) to the host so adopters can write their own enforcement inside the controller. This keeps RAR semantics explicitly host-owned, consistent with the host-seam philosophy.
- Add a release-readiness assertion that the supported-surface page does **not** claim RS-side RAR enforcement.

**Coverage owner:** Docs/contract phase. Guard test: supported-surface assertion.

**References:** [RFC 9396 §11](https://datatracker.ietf.org/doc/html/rfc9396#section-11), [oauthstuff/draft-oauth-rar issue 40 — RAR + resources](https://github.com/oauthstuff/draft-oauth-rar/issues/40).

---

### Pitfall 10: Demo/docs/plug/CI drift — the four-source-of-truth problem (Moderate)

This is the named v1.27 problem. Today:
- **Demo** (`examples/adoption_demo/lib/adoption_demo_web/router.ex:24`) mounts `Lockspire.Plug.VerifyToken, scopes: ["read:billing"]` with **no audience**, **no `EnforceSenderConstraints`**, **no `RequireToken`**. Then the smoke (`scripts/demo/adoption_smoke.py:244`) only proves an anonymous request returns 401 — it never proves a *valid* issued token reaches 200.
- **Docs** (`docs/protect-phoenix-api-routes.md`) shows the three-plug pipeline with `audience:` and `EnforceSenderConstraints` — but those three plugs are scattered across three examples, none of which the demo or generated host uses verbatim.
- **Plug** (`lib/lockspire/plug/verify_token.ex`) is JWT-only by virtue of using `verify_strict/3`, but its docstring says "extracts and verifies a Bearer token from the Authorization header" — opaque tokens are bearer tokens too, and the docstring does not say "JWT bearer."
- **CI** (`test/integration/phase81_generated_host_route_protection_e2e_test.exs`) tests the three-plug pipeline against synthetic JWTs, not against tokens that an end-to-end auth-code flow against this same Lockspire would actually produce.

Each layer is internally consistent. Across layers, they describe *four slightly different products*. That is the "blessed-path-by-accident" surface: whichever layer an adopter copies first becomes their truth.

**Warning sign:** Any time a milestone-close audit can answer "what protects a host Phoenix API?" with four different concrete code snippets, drawn from these four sources.

**Prevention:**
- Pick **one** blessed snippet. Put it in `docs/protect-phoenix-api-routes.md` *and* `docs/saas-adoption-recipe.md` *and* the adoption demo router *and* the generated host scaffolding. Use a literal-copy assertion in `release_readiness_contract_test` that hashes the canonical block and fails if any of those four files drifts.
- Extend `phase81_generated_host_route_protection_e2e_test.exs` (or add a sibling test) to use the *demo's* issued access token against the *demo's* protected route — not synthetic JWTs. If the demo can't drive the canonical pipeline to a 200, the milestone is not done.
- The smoke must do `auth-code → access_token → GET /api/billing/summary → 200`, not just `anonymous → 401`. The 401 line proves nothing.

**Coverage owner:** Cross-cut alignment phase (this is the spine of the milestone). Guard test: canonical-snippet content hash + e2e proof in the smoke.

---

### Pitfall 11: `at+jwt` typ header — accept it, require it, or ignore it (Moderate)

RFC 9068 §2.1 mandates `typ: at+jwt` (or media-type `application/at+jwt`) in the JWT header for JWT access tokens, specifically to defeat cross-JWT confusion attacks (an ID token getting accepted as an access token, or vice versa). Lockspire's RFC 8693 emitter already stamps `typ: at+jwt` (`rfc8693_exchange.ex:342`), but `VerifyToken.verify_signature_and_claims/2` does **not** check it. So today, a Lockspire-issued ID token whose `aud` happens to equal a configured route audience would be accepted by `VerifyToken` as an access token.

**Warning sign:** `verify_token_test.exs` has no case for "JWT with `typ: JWT` (or absent typ) → reject" or "JWT with `typ: id-token+jwt` → reject." The verifier accepts any RS256/ES256/PS256-signed JWT whose `aud` and `exp` line up.

**Prevention:**
- Enforce `typ` either at `at+jwt` (strict) or at "any non-ID-Token typ" (permissive). RFC 9068 is clear that `at+jwt` is the answer; pick it.
- Add `verify_token_test.exs` cases: (a) `typ: at+jwt` → accept, (b) `typ: JWT` → reject with `:wrong_typ`, (c) `typ` absent → reject, (d) an actual `Lockspire.Protocol.IdToken` minted by the same key set → reject.

**Coverage owner:** Plug hardening phase. Guard test: extend `verify_token_test.exs` with cross-JWT confusion cases.

**References:** [RFC 9068 §2.1 — Header](https://datatracker.ietf.org/doc/html/rfc9068#section-2.1).

---

### Pitfall 12: Missing `exp` silently accepted (Moderate)

`verify_token.ex` line 365: `_ -> true` — a JWT with no `exp` claim is treated as valid. RFC 7519 §4.1.4 and RFC 9068 §2.2 both require `exp`. The current "missing exp ≈ valid" comment notes that stricter policy may demand it; v1.27 should make that policy decision.

**Warning sign:** A test that signs a JWT without `exp` and gets a 200 from a `RequireToken` route.

**Prevention:**
- Make missing `exp` a rejection. RFC 9068 makes `exp` REQUIRED.
- Add a `verify_token_test.exs` case proving rejection.
- Same for missing `iat` (RFC 9068 §2.2 REQUIRED) and missing `sub` (REQUIRED) — be explicit.

**Coverage owner:** Plug hardening phase. Guard test: extend `verify_token_test.exs`.

**References:** [RFC 9068 §2.2](https://datatracker.ietf.org/doc/html/rfc9068#section-2.2).

---

### Pitfall 13: DPoP `iat`/`jti` replay store reset across BEAM restarts (Moderate)

`EnforceSenderConstraints` accepts an `dpop_replay_store:` option for the protected-resource path. If the host wires a process-local ETS table (common copy-paste pattern), DPoP `jti` replay protection silently resets on every BEAM restart. RFC 9449 §11.1 calls out replay-window enforcement explicitly; the failure mode is silent because nothing in the runtime warns when the store is volatile.

**Warning sign:** `dpop_replay_store: MyAppWeb.ProtectedApiReplayStore` documented but never required to implement a `persistent?/0` callback, or no warning when the configured store is process-local.

**Prevention:**
- Add an explicit replay-store interface (behaviour) that documents the durability requirement. The interface can have an explicit `persistent?/0` callback; if false, log a `Logger.warning` at boot.
- Document the production expectation in `docs/protect-phoenix-api-routes.md`: persistent replay store, not process state, not application env.

**Coverage owner:** DPoP-RS hardening phase (or defer to a follow-up patch if v1.27 only addresses JWT/opaque shape). Guard test: behaviour-conformance test.

**References:** [RFC 9449 §11.1](https://datatracker.ietf.org/doc/html/rfc9449#section-11.1).

---

## Minor Pitfalls

### Pitfall 14: `apply_restrictions/2` early-returns on first failure — audience checked before scope (Minor)

`verify_token.ex:99-108` uses `with` — audience is checked first, then scope. A token failing both audience and scope only reports the audience error. That is fine for security but produces support-burden when an adopter is debugging the wrong dimension. Not a security issue; flag for log richness.

**Warning sign:** "Why does the error not mention scope when both are wrong?"

**Prevention:** Either accept this as documented ordering, or have the log line include both check outcomes even though the response surfaces only the first. The current `log_restriction_failure/2` already includes `category` and `reason_code`; consider adding both.

**Coverage owner:** Diagnostics polish phase (low priority).

---

### Pitfall 15: `Lockspire.Plug.VerifyToken` moduledoc undersells the JWT-only shape (Minor)

The docstring says "extracts and verifies a Bearer token from the Authorization header." Opaque tokens are also Bearer tokens. The docstring must say "extracts and verifies a JWT bearer (or DPoP-bound) access token from the Authorization header" and link to the RS contract in `docs/protect-phoenix-api-routes.md`.

**Warning sign:** Adopter confusion at the function level.

**Prevention:** Update the moduledoc. Add a `release_readiness_contract_test` assertion that the moduledoc contains "JWT" — small, blunt, effective.

**Coverage owner:** Docs/contract phase. Guard test: docstring content assertion.

---

### Pitfall 16: `audiences:` plug option `Enum.any?` is correct, but undocumented (Minor)

`validate_audience/2` accepts a route token if *any* of the route's `audiences:` matches *any* of the token's `aud` values. That is the correct interpretation of "any-of" but is not documented as such. Adopters bringing OIDC `aud` array intuition may expect *all-of* semantics.

**Warning sign:** Adopter asks: "do I need every audience in my `audiences:` list to be in the token?"

**Prevention:** Make the semantics explicit in `protect-phoenix-api-routes.md` and in the plug's option doc string.

**Coverage owner:** Docs phase.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|---|---|---|
| Token-shape decision (JWT vs introspection vs both) | Pitfall 1 (token-type confusion) | Pick one. If both: one unified `AccessToken.claims` shape. |
| Plug-shape decision (composite vs three-plug) | Pitfall 5 (binding bypass), Pitfall 6 (challenge mismatch) | Composite plug or fail-closed assertion in `RequireToken`. |
| Audience binding (RFC 8707 → `aud`) | Pitfalls 2, 7 | Make `audience:` effectively mandatory; same shape opaque vs JWT. |
| Plug hardening (`iss`, `typ`, `exp`, alg, HS256-confusion) | Pitfalls 3, 4, 11, 12 | RFC 9068 + RFC 8725 compliance pass. |
| Demo/docs/CI alignment | Pitfall 10 | One canonical block, content-hashed across four files. |
| Smoke evolution | Pitfall 10 (smoke proves 401 only) | Smoke must prove `200 with issued token` against the canonical route. |
| Introspection-based RS (if in scope) | Pitfalls 7, 8 | No cache in first slice. |
| DPoP-RS polish (if in scope) | Pitfalls 5, 6, 13 | Replay-store behaviour, challenge-scheme derivation. |
| Support-surface truth | Pitfall 9 (RAR), Pitfall 15 (moduledoc) | Explicit "scope-based RS only" wording. |

---

## CVE / RFC References Cited

- **RFC 9068** — JWT Profile for OAuth 2.0 Access Tokens (audience, issuer, typ, alg rules).
- **RFC 8725** — JWT Best Current Practices (alg allowlist, no `none`, no HS-vs-RS confusion).
- **RFC 8707** — Resource Indicators (audience binding).
- **RFC 9449** — DPoP (htm/htu/jti/nonce, RS-side validation).
- **RFC 9396** — Rich Authorization Requests (RAR vs scope, coexistence).
- **RFC 9700** — Security BCP (mix-up, audience).
- **RFC 9207** — Issuer Identification.
- **RFC 7662** — Token Introspection (caching, revocation).
- **RFC 7519 §4.1.4** — `exp` claim semantics.

**Attack classes referenced:**
- JWT alg-confusion (RS256 → HS256 with published JWKS public key as HMAC secret).
- JWT signature-stripping (`alg: none`).
- JWT cross-JWT confusion (ID token accepted as access token via missing `typ`).
- JWT audience substitution / cross-API relay.
- OAuth mix-up (cross-issuer token routing).
- DPoP replay (volatile `jti` store, missing nonce).

---

## Confidence

**HIGH** on the codebase-grounded pitfalls (1, 2, 3, 5, 6, 7, 10, 11, 12, 15, 16) — these are direct reads of `verify_token.ex`, `enforce_sender_constraints.ex`, `require_token.ex`, `token_formatter.ex`, `rfc8693_exchange.ex`, the demo router, the smoke script, and the supported-surface page.

**HIGH** on the RFC-mandated pitfalls (4, 11, 12, 13) — RFCs 9068, 8725, 9449 are explicit.

**MEDIUM** on Pitfalls 8 and 9 — these depend on whether v1.27 actually opens an introspection-RS path or stays JWT-only. The pitfall is real either way, but the phase-coverage mapping is conditional on scope.
