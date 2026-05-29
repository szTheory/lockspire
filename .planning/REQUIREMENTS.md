# v1.27 Requirements

**Milestone:** v1.27 Phoenix Resource Server Token Acceptance
**Defined:** 2026-05-27
**Core Value:** A Phoenix SaaS team can turn an existing app into a trustworthy OAuth/OIDC provider while keeping account, login, tenant policy, and operator authentication in the host app.

**Milestone Goal:** Make it obvious which Lockspire-issued token shape a host Phoenix API should accept, how that relates to `Lockspire.Plug.VerifyToken`, and what CI proof backs the blessed path — without conflating stored opaque access tokens with JWT bearer route-protection fixtures.

**Design Decision:** Branch A with JWT-default issuance. `Lockspire.Plug.VerifyToken` narrows to RFC 9068 `at+jwt` only. Default access-token issuance flips from opaque to `at+jwt` for the authorization-code, refresh, device, and CIBA paths. Opaque tokens remain available as an explicit per-client opt-in and continue to back the Lockspire-owned `/userinfo` and `/introspect` endpoints. Recorded as a Key Decision in PROJECT.md.

**Research basis:** `.planning/research/SUMMARY.md`, augmented by ecosystem + canon + migration-cost research (2026-05-27). Branch B (dual-verifier plug with shape-dispatch) explicitly rejected on canon-alignment, ecosystem-footgun (Ory oathkeeper #257 class), and security-posture grounds. Introspection-at-the-RS as the host-API seam also explicitly rejected.

## v1.27 Requirements

Each requirement maps to roadmap phases via the Traceability section.

### Token Format Policy

- [x] **FORMAT-01**: A server-wide `access_token_format` setting (default `:jwt`) controls the default token shape issued by the authorization-code, refresh, device, and CIBA paths. Operators can set this to `:opaque` to opt the entire deployment out of `at+jwt` issuance.
- [x] **FORMAT-02**: A per-client `access_token_format` override (`:jwt | :opaque | nil`) lets operators flip individual clients independently of the server default. Visible in the admin client-detail screen with a doclink to the tradeoff.

### Verifier Contract

- [x] **VERIFIER-01**: `Lockspire.Plug.VerifyToken` accepts only RFC 9068 `at+jwt` access tokens. Opaque tokens are explicitly rejected with `WWW-Authenticate: Bearer error="invalid_token", error_description="opaque tokens not accepted on this route"`, never silently accepted or silently mis-rejected.
- [x] **VERIFIER-02**: The plug enforces RFC 9068 §4 issuer pinning (`iss` matches `Lockspire.Config.issuer!()`) on every verified access token. Missing or wrong `iss` returns `invalid_token` with a distinct reason code.
- [x] **VERIFIER-03**: The plug enforces `typ: at+jwt` header on every verified access token (RFC 9068 §2.1, RFC 8725 §3.11). Tokens with a different `typ` (including missing or `JWT`) are rejected as `invalid_token` to defeat cross-JWT confusion.
- [x] **VERIFIER-04**: The plug requires `exp`, `iat`, and `sub` claims on every verified access token (RFC 9068 §2.2). Missing any of these is `invalid_token`.
- [x] **VERIFIER-05**: The plug emits `WWW-Authenticate` challenges whose `scheme` is derived from the request's authorization scheme and the token's binding type, not from the failure category. DPoP-bound failures emit `DPoP`; mTLS-bound failures emit `Bearer` with `MAC`-equivalent guidance; plain bearer failures emit `Bearer`. RFC 9449 §7.1 compliant.
- [x] **VERIFIER-06**: `audience:` (or `audiences:`) is effectively mandatory on the blessed pipeline. The plug raises from `init/1` when `enforce_audience: true` is set (the default in `priv/templates/lockspire.install/router.ex`) and no `audience:` is supplied, OR a `release_readiness_contract_test` clause asserts every shipped pipeline declares one. Cross-API token reuse closed.

### Audience Semantics

- [x] **AUD-01**: When `resource=<URI>` is present in a token request (RFC 8707), the minted `at+jwt`'s `aud` claim is `[resource]`. The `resource` parameter is propagated through the AC, refresh, device, and CIBA paths to the signer.
- [x] **AUD-02**: When `resource=` is absent on AC/refresh/device/CIBA paths, the minted `at+jwt`'s `aud` is `[client_id]` (back-compat with shipped RFC 8693 behaviour; no semantics change for existing callers).
- [x] **AUD-03**: When `resource=` is absent on the RFC 8693 token-exchange path, `aud` continues to be `client_id` (no change to shipped behaviour).

### Signer Module

- [x] **SIGNER-01**: A shared `Lockspire.Protocol.AccessTokenSigner` module owns RFC 9068 `at+jwt` signing. The signing block currently at `lib/lockspire/protocol/rfc8693_exchange.ex:317-361` is extracted into this module and called from the AC, refresh, device, CIBA, and RFC 8693 issuance paths. No duplicate signing logic remains.
- [x] **SIGNER-02**: The signer respects per-client and server-wide `access_token_format` policy and produces opaque tokens via the existing `Lockspire.Protocol.TokenFormatter` path when policy says `:opaque`. The format decision happens in one place.

### Sender Constraints (DPoP + mTLS) End-to-End Proof

- [x] **BIND-01**: A DPoP-bound `at+jwt` issued by the AC / refresh / device / CIBA paths carries `cnf.jkt` and is verified end-to-end through `Lockspire.Plug.VerifyToken` → `EnforceSenderConstraints` → `RequireToken`, returning a usable `%AccessToken{}` to the host controller. No new enforcer code; proof only.
- [x] **BIND-02**: An mTLS-bound `at+jwt` issued by the same paths carries `cnf["x5t#S256"]` and is verified end-to-end. No new enforcer code; proof only.
- [x] **BIND-03**: A pipeline missing `EnforceSenderConstraints` after `VerifyToken` either fails closed in `RequireToken` (when `binding_requirements` is non-nil) or is asserted-against by `release_readiness_contract_test`. Sender-constraint bypass via misordered pipeline is no longer reachable in the blessed path.

### Adoption Demo Proof

- [x] **DEMO-01**: The adoption demo (`examples/adoption_demo/`) runs an end-to-end auth-code flow that obtains a Lockspire-issued `at+jwt`, calls a host-owned protected route (e.g., `/api/billing/summary`), and asserts HTTP `200` with the token. The demo's existing `/userinfo` assertion against the stored opaque token stays (it correctly exercises the Lockspire-owned RS path).
- [x] **DEMO-02**: `scripts/demo/adoption_smoke.py` adds the `200-with-issued-token` assertion. The smoke proving only `401-on-anonymous` is no longer the sole RS-protection proof.
- [x] **DEMO-03**: The demo's router declares an explicit `audience:` on its protected pipeline matching the resource URI used in the token request.

### Canonical Recipe Content-Hashing

- [x] **RECIPE-01**: One canonical pipeline-declaration block lives in exactly four places — `docs/protect-phoenix-api-routes.md`, `examples/adoption_demo/lib/adoption_demo_web/router.ex`, `priv/templates/lockspire.install/router.ex`, and `scripts/demo/adoption_smoke.py` (referenced by comment) — and a `release_readiness_contract_test` clause fails if the content hash drifts between any two of them.

### Discovery Metadata

- [x] **DISCOVERY-01**: The OpenID Connect discovery document advertises `access_token_signing_alg_values_supported: ["RS256", "ES256", "PS256"]` whenever any path can mint `at+jwt` (which, after v1.27, is "always — by default"). Truthful with shipped behaviour.

### Generated-Host Scaffolding

- [x] **SCAFFOLD-01**: `priv/templates/lockspire.install/router.ex` gains the commented `:lockspire_protected_api` pipeline declaration mirroring the demo's blessed pipeline. New adopters get a working RS-protection scaffold without copy-paste from docs.
- [x] **SCAFFOLD-02**: `mix lockspire.install` does NOT ask the operator about token format. The JWT default is right; opting to opaque happens later via admin client management or config, not at install time. No new install-time decision.

### Adopter-Facing Docs

- [x] **DOCS-01**: `docs/protect-phoenix-api-routes.md` becomes the single authoritative protected-route page. States plainly: "Lockspire issues RFC 9068 `at+jwt` access tokens by default. `Lockspire.Plug.VerifyToken` accepts JWT bearer tokens for host Phoenix API routes. Lockspire-owned `/userinfo` and `/introspect` use stored opaque tokens; those are not interchangeable. To opt a client back to opaque, see the admin Client Detail page."
- [x] **DOCS-02**: `docs/supported-surface.md` records the explicit non-goals: no introspection-at-the-RS as the host-API seam, no auto-detection of token shape, no dual-verifier dispatcher, no RAR enforcement at the RS plug (RAR claims surface via `conn.assigns.access_token` for host-owned enforcement).

### Operator Telemetry

- [x] **TELEMETRY-01**: A `[:lockspire, :rs, :token_format]` telemetry event is emitted on every successful verification through `Lockspire.Plug.VerifyToken`, with `:jwt | :opaque-rejected` as a measurement and `client_id`, `audience`, and `binding_type` as metadata. Operators can see at a glance what flows through their plug.

### Migration & Backward Compatibility

- [x] **MIGRATE-01**: Existing clients (created before v1.27) whose `access_token_format` is `nil` inherit the new server default (`:jwt`). A migration guide in `docs/upgrading/v1.27.md` names this explicitly and shows the one-line config to opt the whole deployment back to opaque if needed.
- [x] **MIGRATE-02**: A `mix lockspire.doctor token_format` task (or extension of the existing doctor task) reports per-client format choices and flags any client where the inherited default has changed semantics. Diagnostic, not enforcement.

## Future Requirements

Deferred. Tracked but not in v1.27 roadmap.

### Cross-Process / Remote Lockspire

- **REMOTE-01**: A future milestone may add a `Lockspire.IntrospectionClient` for hosts that deploy Lockspire in a separate BEAM/process. Architecturally a thin `mode: :remote` follow-on over the shipped `POST /introspect`. Defer until adopter evidence justifies the embedded-only deployment constraint being lifted.

### Replay Store Durability for DPoP-at-RS

- **RS-DPoP-01**: The shipped `dpop_replay_store:` plug option (host-side) carries a known durability gap. Out of scope for v1.27 unless adopter evidence surfaces the issue in production.

### One-Token-Fits-Everywhere

- **UNIFIED-01**: Accepting `at+jwt` at `/userinfo` in addition to stored opaque tokens would allow adopters to use the same token shape everywhere. Defer as a DX nicety; today's split (JWT for host APIs, opaque for Lockspire-owned resources) is the canonically endorsed phantom-token pattern.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep into hosted-auth / CIAM / gateway productization that PROJECT.md forbids.

| Excluded | Reason |
|---|---|
| Introspection-at-the-RS as the host-API seam | Recreates gateway/CIAM productization the canon explicitly rejects; forces synchronous network/IPC round-trip for state the same BEAM already holds. Introspection stays an operator/tooling primitive. |
| Auto-detection of token shape inside `VerifyToken` | Documented ecosystem footgun (Ory oathkeeper #257 class, Spring Boot's startup exception when both validators configured). Adopters get an explicit, named contract instead. |
| Dual-verifier plug (Branch B) | Hides operator-visible complexity inside the library; violates "if it's a choice, make it visible" canon principle; doubles plug-internal surface for no canon-aligned gain. |
| RAR enforcement at the RS plug | RAR is host-owned. Plug surfaces `conn.assigns.access_token` with RAR claims; the host route does the enforcement. (Documented in DOCS-02.) |
| Cross-language SDK for token verification | RFC 9068 `at+jwt` is verifiable by any RFC-7515-conformant JWT library in any language; no Lockspire-shipped SDK needed. |
| Standalone introspection-based RS adapter for non-Phoenix hosts | Defer per `prompts/Embedding an OAuth-OIDC server in Phoenix...md`'s "lead with embedded, not headless" decision. |
| Theming / themeable error pages on the protected route | Host owns its 401/403 UX. Plug emits structured `WWW-Authenticate`; the host renders. |
| Lockspire-owned account-level RBAC at the RS | Authorization decisions beyond scope/audience/binding are host-owned per `prompts/Oauth server jtbd and domain.md` §4. |

## Traceability

Each REQ-ID maps to exactly one phase. Mapped 2026-05-27.

| Requirement | Phase | Status |
|-------------|-------|--------|
| RECIPE-01 | Phase 97 | Complete |
| DOCS-01 | Phase 97 | Complete |
| DOCS-02 | Phase 97 | Complete |
| VERIFIER-01 | Phase 98 | Complete |
| VERIFIER-02 | Phase 98 | Complete |
| VERIFIER-03 | Phase 98 | Complete |
| VERIFIER-04 | Phase 98 | Complete |
| VERIFIER-05 | Phase 98 | Complete |
| VERIFIER-06 | Phase 98 | Complete |
| SIGNER-01 | Phase 99 | Complete |
| SIGNER-02 | Phase 99 | Complete |
| FORMAT-01 | Phase 99 | Complete |
| FORMAT-02 | Phase 99 | Complete |
| AUD-01 | Phase 99 | Complete |
| AUD-02 | Phase 99 | Complete |
| AUD-03 | Phase 99 | Complete |
| DISCOVERY-01 | Phase 99 | Complete |
| BIND-01 | Phase 100 | Complete |
| BIND-02 | Phase 100 | Complete |
| BIND-03 | Phase 100 | Complete |
| DEMO-01 | Phase 101 | Complete |
| DEMO-02 | Phase 101 | Complete |
| DEMO-03 | Phase 101 | Complete |
| SCAFFOLD-01 | Phase 102 | Complete |
| SCAFFOLD-02 | Phase 102 | Complete |
| TELEMETRY-01 | Phase 102 | Complete |
| MIGRATE-01 | Phase 102 | Complete |
| MIGRATE-02 | Phase 102 | Complete |

**Coverage:**

- v1.27 requirements: 28 total
- Mapped to phases: 28
- Unmapped: 0

**Coverage by Phase:**

| Phase | REQ Count | Requirements |
|-------|-----------|--------------|
| Phase 97 — Contract + Docs First | 3 | RECIPE-01, DOCS-01, DOCS-02 |
| Phase 98 — Plug Hardening | 6 | VERIFIER-01, VERIFIER-02, VERIFIER-03, VERIFIER-04, VERIFIER-05, VERIFIER-06 |
| Phase 99 — Signer Extraction + JWT-Default Issuance | 8 | SIGNER-01, SIGNER-02, FORMAT-01, FORMAT-02, AUD-01, AUD-02, AUD-03, DISCOVERY-01 |
| Phase 100 — Sender-Constraint End-to-End Proof | 3 | BIND-01, BIND-02, BIND-03 |
| Phase 101 — Adoption-Demo Re-Wire | 3 | DEMO-01, DEMO-02, DEMO-03 |
| Phase 102 — Generated-Host Scaffolding + Telemetry + Migration | 5 | SCAFFOLD-01, SCAFFOLD-02, TELEMETRY-01, MIGRATE-01, MIGRATE-02 |
| **Total** | **28** | |

---
*Requirements defined: 2026-05-27*
*Traceability mapped: 2026-05-27*
*Design decision recorded as Key Decision in PROJECT.md: Branch A + JWT-default issuance*
