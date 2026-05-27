# Lockspire Roadmap

## Shipped Milestones

- [v1.26 Host Integration & Operator Boundary Hardening](milestones/v1.26-ROADMAP.md) — shipped 2026-05-27; phases 94-96; 3 plans; generated host scaffolding now shows a host-guarded admin-only mount, account/claims integration stays narrow and host-owned, first-client bootstrap guidance is clearer, and adopter docs now include a compact SaaS adoption recipe without adding protocol breadth.
- [v1.25 Support-Burden Reduction](milestones/v1.25-ROADMAP.md) — shipped 2026-05-26; phases 91-93; 9 plans; remote `jwks_uri` diagnostics, advanced-setup support truth, and regression proof now align across runtime, doctor, admin, and docs without broadening Lockspire's embedded-library scope.
- [v1.24 client_secret_jwt](milestones/v1.24-ROADMAP.md) — shipped 2026-05-25; phases 88-90; 9 plans; Lockspire now supports a narrow `client_secret_jwt` direct-client slice on the shipped Lockspire-owned endpoints with sealed verifier material, strict HS256/replay/audience posture, and truthful DCR/discovery/admin/docs support.
- [v1.23 DCR Logout Metadata](milestones/v1.23-ROADMAP.md) — shipped 2026-05-24; phases 85-87; 9 plans; self-service clients can now create, read, and replace Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening the current logout truth model.
- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) — shipped 2026-05-24; phases 82-84; 8 plans; automatic `DPoP-Nonce` challenge and retry support now covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.

## Active Milestone: v1.27 Phoenix Resource Server Token Acceptance

**Milestone branch:** `milestone/v1.27-phoenix-rs-token-acceptance`
**Started:** 2026-05-27
**Phase range:** 97-102 (continuing from v1.26 which ended at phase 96)

**Goal:** Make it obvious which Lockspire-issued token shape a host Phoenix API should accept, how that relates to `Lockspire.Plug.VerifyToken`, and what CI proof backs the blessed path — without conflating stored opaque access tokens with JWT bearer route-protection fixtures.

**Design decision (Branch A + JWT-default issuance):** `Lockspire.Plug.VerifyToken` narrows to RFC 9068 `at+jwt` only. Default access-token issuance flips from opaque to `at+jwt` for the authorization-code, refresh, device, and CIBA paths. Opaque tokens remain available as an explicit per-client opt-in and continue to back the Lockspire-owned `/userinfo` and `/introspect` endpoints. Recorded as Key Decision in PROJECT.md.

**Non-goals:** no introspection-at-the-RS as the host-API seam, no auto-detection of token shape inside `VerifyToken`, no dual-verifier plug (Branch B), no RAR enforcement at the RS plug (RAR claims surface via `conn.assigns.access_token` for host-owned enforcement), no hosted auth/CIAM, no service mesh / gateway productization, no SAML/LDAP, no certification-breadth chasing.

## Phases

**Phase Numbering:**
- Integer phases (97, 98, 99, 100, 101, 102): Planned milestone work
- Decimal phases (e.g., 98.1): Urgent insertions (marked with INSERTED) if needed mid-milestone

- [ ] **Phase 97: Contract + Docs First** — Single authoritative protected-route doc page anchors the implementation contract before any runtime change lands.
- [ ] **Phase 98: Plug Hardening** — `Lockspire.Plug.VerifyToken` narrows to RFC 9068 `at+jwt` only with full RFC 9068 / 8725 / 9449 compliance.
- [ ] **Phase 99: Signer Extraction + JWT-Default Issuance** — Shared `Protocol.AccessTokenSigner` lands; default access-token format flips to `:jwt` with per-client override and audience semantics.
- [ ] **Phase 100: Sender-Constraint End-to-End Proof** — DPoP-bound and mTLS-bound `at+jwt` traverse the blessed pipeline end-to-end; misordered-pipeline bypass is closed.
- [ ] **Phase 101: Adoption-Demo Re-Wire** — The demo smoke proves auth-code → `at+jwt` → `/api/billing/summary` → 200, not just 401-on-anonymous.
- [ ] **Phase 102: Generated-Host Scaffolding + Telemetry + Migration** — Install template mirrors the blessed pipeline; operator telemetry and migration guide land for the issuance-default flip.

## Phase Details

### Phase 97: Contract + Docs First
**Goal**: A single authoritative protected-route doc page exists and is content-hash-pinned across the four canonical locations before any implementation change lands, so the implementation honors a documented contract instead of a doc describing an accident.
**Depends on**: Nothing (first phase of v1.27, continues from v1.26 phase 96).
**Requirements**: RECIPE-01, DOCS-01, DOCS-02
**Success Criteria** (what must be TRUE):
  1. An adopter reading `docs/protect-phoenix-api-routes.md` finds one authoritative answer that names RFC 9068 `at+jwt` as the host-API protection shape, and explains that `/userinfo` and `/introspect` use stored opaque tokens which are not interchangeable.
  2. The same protected-route pipeline declaration block appears verbatim in exactly four locations — `docs/protect-phoenix-api-routes.md`, `examples/adoption_demo/lib/adoption_demo_web/router.ex`, `priv/templates/lockspire.install/router.ex`, and `scripts/demo/adoption_smoke.py` (as a referenced comment).
  3. `docs/supported-surface.md` plainly records the explicit non-goals (no introspection-at-the-RS as the host-API seam, no auto-detection of token shape, no dual-verifier dispatcher, no RAR enforcement at the RS plug).
  4. A `release_readiness_contract_test` clause fails loudly if the content hash of the canonical pipeline declaration drifts between any two of the four locations.
**Plans**: TBD

### Phase 98: Plug Hardening
**Goal**: `Lockspire.Plug.VerifyToken` accepts only RFC 9068 `at+jwt` access tokens and enforces RFC 9068 / RFC 8725 / RFC 9449 compliance rules that are currently missing, closing five of the seven critical pitfalls before any issuance change ships.
**Depends on**: Phase 97 (the doc contract names what the plug now enforces).
**Requirements**: VERIFIER-01, VERIFIER-02, VERIFIER-03, VERIFIER-04, VERIFIER-05, VERIFIER-06
**Success Criteria** (what must be TRUE):
  1. An adopter who sends an opaque token to a `Lockspire.Plug.VerifyToken`-protected route receives a distinct `WWW-Authenticate: Bearer error="invalid_token", error_description="opaque tokens not accepted on this route"` challenge — not a silent `:malformed` failure.
  2. An adopter who sends a JWT with a missing or wrong `iss`, a missing or non-`at+jwt` `typ`, or missing `exp`/`iat`/`sub` receives a 401 with a distinct reason code naming which RFC 9068 / RFC 8725 rule was violated.
  3. An adopter who sends a DPoP-bound access token through the plug and fails audience or scope checks receives a `WWW-Authenticate: DPoP ...` challenge (not `Bearer`), per RFC 9449 §7.1; mTLS-bound and plain-bearer failures emit the correct scheme for their binding type.
  4. An adopter mounting `Lockspire.Plug.VerifyToken` without an `audience:` option on a pipeline that declares `enforce_audience: true` (the install-template default) sees `init/1` raise — or, equivalently, `release_readiness_contract_test` asserts every shipped pipeline declares one, so cross-API token reuse is structurally closed.
**Plans**: TBD

### Phase 99: Signer Extraction + JWT-Default Issuance
**Goal**: One shared `Lockspire.Protocol.AccessTokenSigner` owns RFC 9068 `at+jwt` issuance across the AC, refresh, device, CIBA, and RFC 8693 paths; the default access-token format flips from opaque to `:jwt`; per-client overrides and audience semantics are coherent and discoverable.
**Depends on**: Phase 97 (contract names this issuance path); Phase 98 (the hardened plug accepts what the new signer produces).
**Requirements**: SIGNER-01, SIGNER-02, FORMAT-01, FORMAT-02, AUD-01, AUD-02, AUD-03, DISCOVERY-01
**Success Criteria** (what must be TRUE):
  1. An operator running a freshly-deployed Lockspire (server-wide `access_token_format` left at default) sees the authorization-code, refresh, device, and CIBA paths mint RFC 9068 `at+jwt` access tokens — with no per-client configuration required.
  2. An operator visiting the admin client-detail screen for any client can read and change a per-client `access_token_format` override (`:jwt | :opaque | nil`) independently of the server default, alongside a doclink explaining the tradeoff.
  3. A client requesting a token with `resource=https://billing.example.com` receives an `at+jwt` whose `aud` claim is `["https://billing.example.com"]`; with `resource=` absent on AC/refresh/device/CIBA, `aud` is `[client_id]`; with `resource=` absent on RFC 8693 token-exchange, `aud` continues to be `client_id` (no shipped-behavior change).
  4. An adopter or developer reading `/.well-known/openid-configuration` sees `access_token_signing_alg_values_supported: ["RS256", "ES256", "PS256"]` published truthfully because issuance can mint `at+jwt` on every grant path.
  5. There is no duplicated `at+jwt` signing logic anywhere in the codebase — the signing block previously in `rfc8693_exchange.ex:317-361` is gone, and every issuance path calls into `Protocol.AccessTokenSigner`.
**Plans**: TBD
**UI hint**: yes

### Phase 100: Sender-Constraint End-to-End Proof
**Goal**: A DPoP-bound `at+jwt` and an mTLS-bound `at+jwt` both traverse the `VerifyToken → EnforceSenderConstraints → RequireToken` pipeline end-to-end producing a usable `%AccessToken{}` at the host controller, and a pipeline missing `EnforceSenderConstraints` after `VerifyToken` is no longer a silent bypass path.
**Depends on**: Phase 99 (DPoP/mTLS-bound `at+jwt` issuance from the new signer must exist before binding can be proven against it).
**Requirements**: BIND-01, BIND-02, BIND-03
**Success Criteria** (what must be TRUE):
  1. An adopter following the canonical pipeline who obtains a DPoP-bound `at+jwt` (carrying `cnf.jkt`) can call a host-owned protected route with a valid `DPoP:` proof and receive a 200 with `conn.assigns.access_token` populated.
  2. An adopter following the canonical pipeline who obtains an mTLS-bound `at+jwt` (carrying `cnf["x5t#S256"]`) can call a host-owned protected route presenting the bound client certificate and receive a 200 with `conn.assigns.access_token` populated.
  3. An adopter who builds a pipeline that omits `EnforceSenderConstraints` after `VerifyToken` either gets a fail-closed `403`/`401` from `RequireToken` when `binding_requirements` is non-nil, or a `release_readiness_contract_test` clause fires asserting the misorder cannot reach a shipped pipeline — sender-constraint bypass is no longer reachable via the blessed path.
**Plans**: TBD

### Phase 101: Adoption-Demo Re-Wire
**Goal**: The adoption demo executes an end-to-end auth-code → `at+jwt` → host-owned protected route → 200 round-trip in CI, replacing the current "401-on-anonymous" half-proof with executable adopter-facing evidence that the blessed path works.
**Depends on**: Phase 99 (issuance flip lets the demo obtain an `at+jwt` without per-client config); Phase 100 (binding proof is upstream of the demo's bound-token use cases).
**Requirements**: DEMO-01, DEMO-02, DEMO-03
**Success Criteria** (what must be TRUE):
  1. An adopter or contributor running the adoption demo locally observes the smoke complete an auth-code flow, obtain an `at+jwt`, call `/api/billing/summary` with that token, and assert HTTP 200 — alongside the preserved `/userinfo` assertion that exercises the stored-opaque path against the Lockspire-owned RS endpoint.
  2. CI's `Adoption Demo Smoke` job fails loudly if either of those round-trip assertions stops returning the expected outcome — the smoke is no longer satisfied by anonymous-401 alone.
  3. The demo's `:lockspire_protected_api` pipeline declares an explicit `audience:` matching the `resource=` URI used during the token request, so adopters who copy the demo do not inherit the audience-substitution bug-pattern.
**Plans**: TBD

### Phase 102: Generated-Host Scaffolding + Telemetry + Migration
**Goal**: The install template, operator telemetry, migration guide, and doctor task all reflect the now-proven blessed path so new adopters land on a working pipeline by default and existing adopters can migrate the issuance-default flip safely.
**Depends on**: Phase 101 (scaffolding mirrors what CI continuously proves; it does not lead).
**Requirements**: SCAFFOLD-01, SCAFFOLD-02, TELEMETRY-01, MIGRATE-01, MIGRATE-02
**Success Criteria** (what must be TRUE):
  1. A new adopter running `mix lockspire.install` is not asked about token format at install time; their generated `priv/templates/lockspire.install/router.ex` ships with a commented `:lockspire_protected_api` pipeline declaration matching the demo's blessed pipeline, ready to uncomment when they add their first protected API route.
  2. An operator running a Lockspire instance can subscribe to the `[:lockspire, :rs, :token_format]` telemetry event and see — on every successful verification through `Lockspire.Plug.VerifyToken` — a measurement of `:jwt | :opaque-rejected` plus metadata including `client_id`, `audience`, and `binding_type`.
  3. An operator upgrading from v1.26 to v1.27 finds `docs/upgrading/v1.27.md` explaining the default issuance flip, showing the one-line config to opt the whole deployment back to opaque if needed, and naming exactly which existing clients (those with `access_token_format: nil`) will inherit the new server default.
  4. An operator running `mix lockspire.doctor token_format` receives a diagnostic report of per-client format choices that flags every client where the inherited default has changed semantics — diagnostic, not enforcement.
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 97 → 98 → 99 → 100 → 101 → 102. Decimal phases (e.g., 98.1) may be inserted between integers if urgent work surfaces mid-milestone.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 97. Contract + Docs First | 0/TBD | Not started | - |
| 98. Plug Hardening | 0/TBD | Not started | - |
| 99. Signer Extraction + JWT-Default Issuance | 0/TBD | Not started | - |
| 100. Sender-Constraint End-to-End Proof | 0/TBD | Not started | - |
| 101. Adoption-Demo Re-Wire | 0/TBD | Not started | - |
| 102. Generated-Host Scaffolding + Telemetry + Migration | 0/TBD | Not started | - |

## Build-Order Rationale

The six-phase ordering is constrained by three hard dependencies and one soft one:

1. **Phase 97 must be first.** The canon is explicit that the protected-route doc is a contract the implementation honors, not a description of an accident. Writing the doc after the code makes the doc retro-fitted; writing it first means every subsequent phase has a stable target.

2. **Phase 98 precedes Phase 99 to avoid a window of incoherent issuance.** The plug-hardening pass (RFC 9068 / 8725 / 9449 compliance — `iss`, `typ: at+jwt`, mandatory `exp`/`iat`/`sub`, scheme-aware `WWW-Authenticate`, JWT-only rejection of opaque) is independent of how tokens are issued. Running it first means the hardened plug is already in place when Phase 99 starts minting `at+jwt` by default, so there is never a state where new-format tokens are issued against a not-yet-hardened verifier.

3. **Phase 99 must precede Phase 101.** The adoption demo's re-wire needs the new JWT-default issuance path to exist before it can prove auth-code → `at+jwt` → `/api/billing/summary` → 200.

4. **Phase 100 between 99 and 101 keeps the binding-bypass class closed before the demo locks in.** Sender-constraint proof depends on Phase 99's issuance path producing DPoP/mTLS-bound `at+jwt` correctly; the demo (Phase 101) then exercises that proof end-to-end against a host-owned route. Running Phase 100 before the demo means the canonical pipeline declaration the demo mirrors has already been proven safe against misordering.

5. **Phase 102 must be last.** Generated-host scaffolding mirrors what CI continuously proves, not what is aspirational. Install template, telemetry, migration guide, and doctor task all reflect the now-shipped contract; landing them before the demo proves end-to-end means the scaffold could outpace truth. Telemetry surfaces and the migration guide both depend on the issuance flip being live; the doctor task depends on the per-client policy surface being shipped (Phase 99).

Phase 97 (docs/contract) and Phase 98 (plug hardening) could in principle run in parallel — Phase 98 is branch-independent in the original research — but were sequenced for clarity in single-developer execution: write the contract once, then implement against it.
