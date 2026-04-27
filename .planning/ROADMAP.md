# Roadmap: Lockspire

## Shipped Milestones

- [x] **v1.4 milestone** - completed 2026-04-26 ([archive](milestones/v1.4-ROADMAP.md), [requirements](milestones/v1.4-REQUIREMENTS.md)); delivered the four-phase JAR and request-object milestone with all 18 plans complete, all 5 shipped JAR requirements closed, and JAR-04 preserved as deferred.
- [x] **v1.3 milestone** - completed 2026-04-24 ([archive](milestones/v1.3-ROADMAP.md), [requirements](milestones/v1.3-REQUIREMENTS.md)); delivered the four-phase PAR Policy milestone with all 8 plans complete, all 6 requirements closed, and consolidated integration proof for global/client/effective policy enforcement.
- [x] **v1.2 milestone** - completed 2026-04-24 ([archive](milestones/v1.2-ROADMAP.md), [requirements](milestones/v1.2-REQUIREMENTS.md), [audit](milestones/v1.2-MILESTONE-AUDIT.md)); delivered the three-phase PAR foundation milestone with all 8 plans complete, all 5 requirements closed, and the deferred Release Please runtime warning removed without widening the preview support contract.
- [x] **v1.1 milestone** - completed 2026-04-24 ([archive](milestones/v1.1-ROADMAP.md), [requirements](milestones/v1.1-REQUIREMENTS.md), [audit](milestones/v1.1-MILESTONE-AUDIT.md)); delivered the seven-phase release-hardening milestone with all 15 plans complete, all 9 v1.1 requirements closed, and protected release proof/traceability reconciled.
- [x] **v1.0 milestone** - completed 2026-04-23 ([archive](milestones/v1.0-ROADMAP.md)); delivered the six-phase embedded OAuth/OIDC provider scope with all 25 plans completed and 42 recorded tasks.

## Active Milestone

**v1.5 Dynamic Client Registration** — turn Lockspire from operator-tended into partner-buildable by adding RFC 7591/7592 dynamic client registration with operator policy controls, without widening the embedded-library shape.

**Granularity:** standard
**Phases:** 5 (Phase 25 — Phase 29; numbering continues from v1.4 close at Phase 24)
**Requirements:** 27 (DCR-01 — DCR-27), all mapped, no orphans.

### Phases

- [ ] **Phase 25: DCR Storage Skeleton, Domain Types, and Policy Resolver** - Land additive migrations, domain types for ServerPolicy/Client/InitialAccessToken, and the intersection-only `DcrPolicy` resolver with its discovery-binding invariant.
- [x] **Phase 26: Protocol Pipeline — RFC 7591 Intake and RFC 7592 Management Core** - Build HTTP-free protocol modules for intake validation, RAT/IAT issuance and atomic redemption, hash-at-rest, and tightened DCR-flavored audit attribution with telemetry redaction. (completed 2026-04-26)
- [ ] **Phase 27: HTTP Surface — Registration and Management Controllers** - Mount `POST /register` and `GET/PUT/DELETE /register/:client_id` with RFC 7591 §3.2.1 response shape, RAT auth, RAT rotation on PUT, and soft-disable on DELETE.
- [ ] **Phase 28: Operator Admin UI — DCR Policy, IAT Lifecycle, Provenance, RAT Rotation, Lifecycle Telemetry** - Ship `PoliciesLive.Dcr`, `IatLive.{Index,New}`, ClientsLive provenance + RAT-rotate, and the full DCR/IAT lifecycle telemetry surface.
- [x] **Phase 29: Truthful Discovery, SECURITY/Docs, and Milestone Closure** - Advertise `registration_endpoint` truthfully, bound SECURITY.md and `docs/dynamic-registration.md` to the shipped slice, and close v1.5 with an end-to-end scenario test and 100% traceability.

### Phase Details

#### Phase 25: DCR Storage Skeleton, Domain Types, and Policy Resolver
**Goal**: Operators have a durable, migrated DCR policy store, the domain layer carries `ServerPolicy` DCR fields, `Client` provenance fields, and `InitialAccessToken` (with `policy_overrides` JSONB), and `Lockspire.Protocol.DcrPolicy.resolve/3` produces an intersection-only effective policy that is bound at discovery via an invariant test.
**Depends on**: v1.4 close (Phase 24); no in-milestone dependencies.
**Requirements**: DCR-06, DCR-07, DCR-08, DCR-09, DCR-10
**Success Criteria** (what must be TRUE):
  1. Running migrations on a v1.4 database adds DCR fields to `lockspire_server_policies`, provenance + RAT/timestamp fields to `lockspire_clients` (existing rows backfilled to `:operator`), and a new `lockspire_initial_access_tokens` table with a `policy_overrides jsonb` column.
  2. `Lockspire.Domain.ServerPolicy` exposes a 3-mode `registration_policy` (`:disabled` default | `:initial_access_token` | `:open`) plus DCR allowlists (scopes, grant_types, response_types, redirect-URI hosts/schemes, `token_endpoint_auth_method`) and DCR defaults (client lifetime, `client_secret` expiry, RAT lifetime), all readable through `Admin.ServerPolicy`.
  3. `Lockspire.Protocol.DcrPolicy.resolve(server_policy, iat_overrides_or_nil, inbound_metadata)` returns an effective policy that is the intersection of all three inputs, never widens any field, and rejects metadata that exceeds an allowlist with a result tagged `invalid_client_metadata`.
  4. An invariant test asserts that the set of `token_endpoint_auth_method` values DCR accepts equals the intersection of `ServerPolicy.dcr_allowed_token_endpoint_auth_methods` and `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0` (and fails if either side drifts).
**Plans**: 8 plans
- [ ] 25-01-PLAN.md — Discovery `/0` accessor extraction (unblocks invariant test)
- [ ] 25-02-PLAN.md — Migration A: extend `lockspire_server_policies` with 10 DCR columns
- [ ] 25-03-PLAN.md — Migration B: create `lockspire_initial_access_tokens` with `unique_index([:token_hash])`
- [ ] 25-04-PLAN.md — Domain layer extensions (`ServerPolicy`, `Client`, new `InitialAccessToken`) + IAT fixture
- [ ] 25-05-PLAN.md — Migration C: extend `lockspire_clients` (FK to IAT) + record schema widening
- [ ] 25-06-PLAN.md — `Admin.ServerPolicy.{get,put}_dcr_policy/0,1` with read-merge-write preservation
- [ ] 25-07-PLAN.md — `Lockspire.Protocol.DcrPolicy.resolve/3` intersection-only resolver + unit tests
- [ ] 25-08-PLAN.md — Discovery-binding invariant test (D-19)

#### Phase 26: Protocol Pipeline — RFC 7591 Intake and RFC 7592 Management Core
**Goal**: All RFC 7591/7592 protocol behavior — intake validation, RAT/IAT issuance, atomic IAT redemption, hash-at-rest, and DCR-flavored audit attribution — is implemented as `Plug.Conn`-free protocol modules with telemetry redaction proven by test, ready for thin HTTP adapters.
**Depends on**: Phase 25
**Requirements**: DCR-02, DCR-03, DCR-04, DCR-11, DCR-22, DCR-23
**Success Criteria** (what must be TRUE):
  1. The intake validator rejects `jwks_uri` with `invalid_client_metadata` ("not supported in this slice"), rejects metadata where `jwks` and `jwks_uri` are both present, enforces RFC 7591 §2 `grant_types`/`response_types` coherence, and routes `redirect_uris` through `Lockspire.Clients.validate_redirect_uris/1` for exact-match parity with operator-created clients.
  2. Successful intake produces a persisted `Domain.Client` with `pkce_required: true` (the validator refuses any metadata that would lower PKCE for a DCR client) and issues `client_id`, a fresh `client_secret`, and a fresh `registration_access_token`; both secrets are SHA-256-with-salt hashed at rest via `Lockspire.Security.Policy` and the plaintext is returned to the caller exactly once.
  3. `Lockspire.Protocol.InitialAccessToken.redeem/1` is atomic — expired, revoked, or already-used IATs return `{:error, :invalid_token}` (mapped to `401 invalid_token` at the HTTP edge later), and successful redemption marks the IAT used in the same DB transaction with no observable race window.
  4. `Lockspire.Admin.Clients.actor_from_attrs/1` attributes DCR codepaths as `:dcr` or `:self_registered_client` (never falls through to `:operator`); a regression test fails if any DCR write emits an `:operator`-flavored audit event.
  5. Telemetry redaction tests prove that RAT plaintext, IAT plaintext, and `client_secret` plaintext never appear in any `[:lockspire, :dcr, ...]` or `[:lockspire, :iat, ...]` event payload, audit row, or log line emitted by the new pipeline.
**Plans**: 7 plans
- [x] 26-01-PLAN.md — Wave 0 foundations: promote `Lockspire.Clients.generate_client_id/0` to public, tighten `Lockspire.Admin.Clients.actor_from_attrs/1` to raise on missing actor.type (D-22), and create six Wave-0 stub test files
- [x] 26-02-PLAN.md — `Lockspire.Protocol.RegistrationAccessToken` (RAT primitives — generate / hash / verify, no side effects)
- [x] 26-03-PLAN.md — `Lockspire.Protocol.InitialAccessToken.redeem/1` + atomic `Repository.redeem_initial_access_token/2` with concurrent-redemption proof (DCR-11)
- [x] 26-04-PLAN.md — DCR test fixtures (`Lockspire.Test.Fixtures.DcrFixtures` — RFC 7591 metadata maps + `register_request/1` builder)
- [x] 26-05-PLAN.md — `Lockspire.Protocol.Registration.register/1` intake orchestrator with private validator pipeline (DCR-02, DCR-03, DCR-04)
- [x] 26-06-PLAN.md — `Lockspire.Protocol.RegistrationManagement` RFC 7592 read/update/delete + RAT rotation + `Repository.get_client_by_registration_access_token_hash/1`
- [x] 26-07-PLAN.md — Cross-cutting closing tests: DCR audit attribution regression sweep (DCR-22) + DCR telemetry redaction single-sweep (DCR-23, D-27, D-28)

#### Phase 27: HTTP Surface — Registration and Management Controllers
**Goal**: Partners can call the four DCR endpoints over HTTP — `POST /register` with policy gating, `GET /register/:client_id` with RAT authentication, `PUT /register/:client_id` with full-replace and RAT rotation, `DELETE /register/:client_id` with soft-disable — and the success body matches RFC 7591 §3.2.1 exactly.
**Depends on**: Phase 26
**Requirements**: DCR-01, DCR-05, DCR-13, DCR-14, DCR-15
**Success Criteria** (what must be TRUE):
  1. `POST /register` is mounted in `Lockspire.Web.Router`, accepts JSON RFC 7591 metadata, and is gated by the effective registration policy resolved through `Lockspire.Protocol.DcrPolicy` (closed when `registration_policy = :disabled`, IAT-required when `:initial_access_token`, anonymous when `:open`).
  2. The success response includes `client_id`, `client_secret`, `registration_access_token`, `client_id_issued_at`, `client_secret_expires_at`, `registration_client_uri`, and the echoed RFC 7591 metadata, matching §3.2.1 byte-for-byte at the JSON view layer.
  3. `GET /register/:client_id` is RAT-authenticated, URL-`client_id`-bound (the URL `client_id` and the RAT-bearing client must match in a single query), returns the current RFC 7591 metadata for self-registered clients only, and returns RFC 7592-shaped errors for invalid/expired/mismatched RATs.
  4. `PUT /register/:client_id` validates the full replacement through the same validator as `POST /register`, rotates `registration_access_token` on success, returns the new plaintext exactly once, and the prior RAT is rejected on the next call.
  5. `DELETE /register/:client_id` soft-disables the client via `Lockspire.Admin.Clients.disable_client_with_audit/4` with `disabled_by: "dcr_self_delete"`, and the same `client_id` cannot be reused for a future registration.
**Plans**: 2 plans
- [ ] 27-01-PLAN.md — Registration JSON Serialization
- [ ] 27-02-PLAN.md — Registration Controller & Router Integration
**UI hint**: yes

#### Phase 28: Operator Admin UI — DCR Policy, IAT Lifecycle, Provenance, RAT Rotation, Lifecycle Telemetry
**Goal**: Operators can configure DCR policy, mint and revoke initial access tokens with copy-once display, distinguish operator-created from self-registered clients, and rotate a self-registered client's RAT — and the full DCR + IAT lifecycle telemetry surface is wired across protocol, HTTP, and admin paths.
**Depends on**: Phase 27
**Requirements**: DCR-12, DCR-18, DCR-19, DCR-20, DCR-21
**Success Criteria** (what must be TRUE):
  1. `Lockspire.Web.Live.Admin.PoliciesLive.Dcr` exists, mirrors `PoliciesLive.Par` and `PoliciesLive.Jar` shape, and lets an operator view and edit the global registration mode, allowlists, and defaults.
  2. `IatLive.Index` lists active and revoked IATs and supports revocation, and `IatLive.New` mints an IAT, displays the plaintext copy-once with a never-shown-again warning, and persists only the hashed value.
  3. `ClientsLive.Index` shows a provenance column with a working filter that distinguishes `:operator_created` from `:self_registered`, and `ClientsLive.Show` renders a "Self-registered client" panel and a `:rotate_registration_access_token` live_action that requires operator confirmation before issuing a new RAT.
  4. The full DCR and IAT lifecycle is observable through telemetry: `[:lockspire, :dcr, ...]` events fire for register, read, update, delete, RAT-rotate, and unauthorized-management; `[:lockspire, :iat, ...]` events fire for mint, use, and revoke; an end-to-end scenario asserts every expected event name is observed.
**Plans**: TBD
**UI hint**: yes

#### Phase 29: Truthful Discovery, SECURITY/Docs, and Milestone Closure
**Goal**: Discovery advertises `registration_endpoint` truthfully across all three policy modes, the public documentation surface is bound to the actually shipped DCR slice, and v1.5 closes with an executable end-to-end DCR scenario and 100% requirement traceability.
**Depends on**: Phase 28
**Requirements**: DCR-16, DCR-17, DCR-24, DCR-25, DCR-26, DCR-27
**Success Criteria** (what must be TRUE):
  1. `Lockspire.Protocol.Discovery.openid_configuration/0` advertises `registration_endpoint` if and only if the registration route is mounted AND `registration_policy != :disabled`; in `:disabled` mode `POST /register` returns 404 (not 403), and a contract test asserts that discovery and runtime stay aligned across all three modes (`:disabled`, `:initial_access_token`, `:open`).
  2. SECURITY.md describes only the shipped DCR slice and explicitly lists software statements, external-IdP federation, FAPI bundles, JAR-04, `jwks_uri` outbound fetch, and built-in rate limiting as out of scope, while documenting the host-side rate-limit Plug seam as a host responsibility.
  3. `docs/dynamic-registration.md` exists, covers operator setup, IAT lifecycle, and partner integration shape, and is registered in `mix.exs` `:extras`.
  4. An executable end-to-end DCR scenario test exercises register → token issuance via the new client → `GET /register/:client_id` → `PUT` (RAT rotation) → DELETE → re-attempt-with-old-RAT (must fail) and passes in CI.
  5. The v1.5 closure record exists, `audit-open` is clean, and the REQUIREMENTS.md traceability matrix shows 27/27 DCR requirements mapped to phases with closing status.
**Plans**: 3 plans
- [x] 29-01-PLAN.md — Truthful Discovery Advertising and Alignment Contract Test
- [x] 29-02-PLAN.md — Update documentation surface and scope limits for DCR
- [x] 29-03-PLAN.md — Execute end-to-end scenario test and complete milestone closure

### Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 25. DCR Storage Skeleton, Domain Types, and Policy Resolver | 0/8 | Not started | - |
| 26. Protocol Pipeline — RFC 7591 Intake and RFC 7592 Management Core | 7/7 | Complete    | 2026-04-26 |
| 27. HTTP Surface — Registration and Management Controllers | 0/0 | Not started | - |
| 28. Operator Admin UI — DCR Policy, IAT Lifecycle, Provenance, RAT Rotation, Lifecycle Telemetry | 0/0 | Not started | - |
| 29. Truthful Discovery, SECURITY/Docs, and Milestone Closure | 3/3 | Complete    | 2026-04-27 |

## Reference

- Milestone archive: [`.planning/milestones/v1.4-ROADMAP.md`](milestones/v1.4-ROADMAP.md)
- Requirements archive: [`.planning/milestones/v1.4-REQUIREMENTS.md`](milestones/v1.4-REQUIREMENTS.md)
- Milestone ledger: [`.planning/MILESTONES.md`](MILESTONES.md)
- Sigra ecosystem note: [`.planning/ECOSYSTEM-SIGRA.md`](ECOSYSTEM-SIGRA.md)