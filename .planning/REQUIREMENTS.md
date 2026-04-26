# Requirements: Lockspire v1.5 — Dynamic Client Registration

**Defined:** 2026-04-26
**Milestone:** v1.5 Dynamic Client Registration (RFC 7591/7592)
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Milestone goal:** Turn Lockspire from operator-tended into partner-buildable by adding RFC 7591 dynamic client registration intake and RFC 7592 client configuration management with operator policy controls — without widening the embedded-library shape.

## v1.5 Requirements

Each requirement is atomic, testable, and traceable to a phase. Phase numbering continues from v1.4 (closed at Phase 24); v1.5 starts at Phase 25.

### Intake (POST /register)

- [ ] **DCR-01**: `POST /register` is mounted in the Lockspire router and accepts RFC 7591 client metadata as JSON, gated by the effective registration policy (`Lockspire.Protocol.DcrPolicy`).
- [ ] **DCR-02**: Intake validation rejects mutually-exclusive or incoherent metadata: `jwks_uri` is rejected with `invalid_client_metadata` ("not supported in this slice"); `jwks` and `jwks_uri` cannot both be present; `grant_types` and `response_types` must satisfy RFC 7591 §2 coherence; `redirect_uris` are validated through the existing `Lockspire.Clients.validate_redirect_uris/1` (exact-match parity with operator-created clients).
- [ ] **DCR-03**: Self-registered clients are PKCE-required by floor; the intake refuses any metadata that would lower PKCE for a DCR client, and the resulting `Domain.Client` row has `pkce_required: true`.
- [ ] **DCR-04**: Successful registration issues `client_id`, `client_secret`, and `registration_access_token`; `client_secret` and `registration_access_token` are hashed at rest using `Lockspire.Security.Policy` and returned in plaintext exactly once in the registration response.
- [ ] **DCR-05**: The success response conforms to RFC 7591 §3.2.1 including `client_id_issued_at`, `client_secret_expires_at`, and `registration_client_uri`.

### Operator Policy Controls

- [ ] **DCR-06**: `Lockspire.Domain.ServerPolicy` exposes a 3-mode `registration_policy` field (`:disabled` default | `:initial_access_token` | `:open`) with a singleton row in `lockspire_server_policies`.
- [ ] **DCR-07**: ServerPolicy DCR allowlists (scopes, grant_types, response_types, redirect-URI hosts/schemes, `token_endpoint_auth_method`) and DCR defaults (client lifetime, `client_secret` expiry, RAT lifetime) bind intake; metadata that exceeds an allowlist is rejected with `invalid_client_metadata`.
- [ ] **DCR-08**: `Lockspire.Protocol.DcrPolicy.resolve/3` produces an effective policy as the intersection of server, IAT, and inbound metadata; the resolver is intersection-only and never widens.
- [ ] **DCR-09**: The set of `token_endpoint_auth_method` values DCR will accept is the intersection of the ServerPolicy DCR allowlist and `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0`; an invariant test asserts this binding.

### Initial Access Tokens

- [ ] **DCR-10**: `Lockspire.Domain.InitialAccessToken` and the `lockspire_initial_access_tokens` table persist IATs with hash-at-rest, expiry, single-use default, and a nullable `policy_overrides` JSONB column.
- [ ] **DCR-11**: `Lockspire.Protocol.InitialAccessToken.redeem/1` is atomic; expired, revoked, or already-used IATs are rejected with `401 invalid_token`, and successful redemption marks the IAT used in the same transaction.
- [ ] **DCR-12**: Operators can mint and revoke IATs from the admin LiveView; IAT plaintext is shown copy-once at mint time only.

### RFC 7592 Management

- [ ] **DCR-13**: `GET /register/:client_id` is RAT-authenticated, URL-`client_id`-bound, and returns the current RFC 7591 metadata for self-registered clients only.
- [ ] **DCR-14**: `PUT /register/:client_id` is full-replace via the same validator as `POST /register`; on success it rotates `registration_access_token`, returns the new plaintext exactly once, and invalidates the prior RAT.
- [ ] **DCR-15**: `DELETE /register/:client_id` soft-disables the client via `Lockspire.Admin.Clients.disable_client_with_audit/4` with `disabled_by: "dcr_self_delete"`; the `client_id` cannot be reused for a future registration.

### Truthful Discovery

- [ ] **DCR-16**: `Lockspire.Protocol.Discovery.openid_configuration/0` advertises `registration_endpoint` if and only if the registration route is mounted AND `registration_policy != :disabled`.
- [ ] **DCR-17**: When `registration_policy = :disabled`, `POST /register` returns 404 (not 403); a contract test verifies discovery and runtime stay aligned across all three modes (`:disabled`, `:initial_access_token`, `:open`).

### Admin UI

- [ ] **DCR-18**: `Lockspire.Web.Live.Admin.PoliciesLive.Dcr` is the global DCR policy page, mirroring `PoliciesLive.Par` and `PoliciesLive.Jar` shape; it surfaces mode, allowlists, and defaults.
- [ ] **DCR-19**: `IatLive.Index` and `IatLive.New` cover IAT mint, list, and revoke; minted IATs display copy-once plaintext.
- [ ] **DCR-20**: `ClientsLive.Index` adds a provenance column and filter (`:operator_created` vs `:self_registered`); `ClientsLive.Show` adds a self-registered panel and a `:rotate_registration_access_token` live_action with operator confirmation.

### Telemetry & Audit

- [ ] **DCR-21**: DCR lifecycle telemetry events are emitted for the full register / read / update / delete / RAT-rotate / unauthorized-management surface and the IAT mint / use / revoke surface; event names are namespaced under `[:lockspire, :dcr, ...]` and `[:lockspire, :iat, ...]`.
- [x] **DCR-22
**: `Lockspire.Admin.Clients.actor_from_attrs/1` is tightened so DCR codepaths attribute `:dcr` or `:self_registered_client` actors and never fall through to the `:operator` default; an explicit test fails if a DCR write logs an `:operator`-flavored audit event.
- [x] **DCR-23
**: Telemetry redaction tests cover RAT, IAT, and `client_secret` plaintext — these values must never appear in telemetry payloads, audit rows, or log lines.

### SECURITY, Docs & Closure

- [ ] **DCR-24**: SECURITY.md is updated to describe only the shipped DCR slice; software statements, external-IdP federation, FAPI bundles, JAR-04, `jwks_uri` outbound fetch, and built-in rate limiting are explicitly listed as out of scope, and the host-side rate-limit Plug seam is documented as a host responsibility.
- [ ] **DCR-25**: `docs/dynamic-registration.md` is authored covering operator setup, IAT lifecycle, and partner integration shape, and is added to `mix.exs` `:extras`.
- [ ] **DCR-26**: An end-to-end DCR scenario test exercises register → token issuance via the new client → `GET /register/:client_id` → `PUT` (RAT rotation) → DELETE → re-attempt-with-old-RAT (must fail).
- [ ] **DCR-27**: Milestone v1.5 closes with a closure record, REQUIREMENTS.md traceability matrix at 100% coverage, and a clean `audit-open`.

## Future Requirements

Acknowledged but deferred to v1.6+. Tracked but not in v1.5 roadmap.

### DCR Hardening (v1.6+)

- **DCR-FUT-01**: `jwks_uri` outbound fetch with SSRF protections (https-only, public-IP-only DNS, body cap, no redirects, Oban-backed background fetch + cache).
- **DCR-FUT-02**: `client_secret` rotation on `PUT /register/:client_id` (default off, opt-in via DcrPolicy).
- **DCR-FUT-03**: Per-IAT `policy_overrides` admin UI surface (the schema column and resolver ship in v1.5; the UI lands later).
- **DCR-FUT-04**: Built-in rate limiting on `POST /register` (likely via `hammer 7.x`).
- **DCR-FUT-05**: "Partner program" policy preset for one-click DCR setup.
- **DCR-FUT-06**: `mix lockspire.gen.initial_access_token` task for CI/seed workflows.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep and to keep public support claims truthful.

| Feature | Reason |
|---------|--------|
| Software statements (RFC 7591 §2.3) | Adds a federated-trust surface that doesn't help the v1.5 partner-ecosystem wedge; would require trust-root management Lockspire has explicitly avoided. |
| External-IdP federation / initial access from upstream IdPs | Pulls Lockspire toward CIAM-suite breadth; out of band for the embedded-library product shape. |
| FAPI policy bundles | Distinct certification effort; v1.5 is the DCR wedge, not a profile-conformance milestone. |
| JAR-04 (encrypted request objects) | Already deferred from v1.4; remains deferred. |
| `client_credentials` grant via DCR | Self-registered service-to-service trust requires a different attribution model; defaulting it on would weaken provenance. |
| Public-client default (`token_endpoint_auth_method=none` by default) | Open-by-default public clients are the most common DCR-abuse pattern observed across IdPs; v1.5 ships secure-by-default. |
| Open-no-gate registration as default | All credible reference impls (Hydra, Keycloak, Curity) ship default-off; Auth0's open-by-design is the cautionary counter-example. |
| Client-supplied `client_id` / `client_secret` | Lockspire issues durable credentials; client-supplied identifiers break uniqueness, audit, and rotation guarantees. |
| Multi-tenant DCR | The host owns tenancy; DCR per-tenant is a host-app concern, not a Lockspire surface. |
| `jwks_uri` outbound fetch in v1.5 | Hard SSRF concern with the v1.5 risk budget; deferred to v1.6 with explicit guards (DCR-FUT-01). |
| Built-in rate limiting in v1.5 | Operator policy is the v1.5 abuse-control story; rate limiting belongs at the host-app Plug seam (documented in SECURITY.md) and may be revisited as DCR-FUT-04. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DCR-01 | Phase 27 | Pending |
| DCR-02 | Phase 26 | Pending |
| DCR-03 | Phase 26 | Pending |
| DCR-04 | Phase 26 | Pending |
| DCR-05 | Phase 27 | Pending |
| DCR-06 | Phase 25 | Pending |
| DCR-07 | Phase 25 | Pending |
| DCR-08 | Phase 25 | Pending |
| DCR-09 | Phase 25 | Pending |
| DCR-10 | Phase 25 | Pending |
| DCR-11 | Phase 26 | Pending |
| DCR-12 | Phase 28 | Pending |
| DCR-13 | Phase 27 | Pending |
| DCR-14 | Phase 27 | Pending |
| DCR-15 | Phase 27 | Pending |
| DCR-16 | Phase 29 | Pending |
| DCR-17 | Phase 29 | Pending |
| DCR-18 | Phase 28 | Pending |
| DCR-19 | Phase 28 | Pending |
| DCR-20 | Phase 28 | Pending |
| DCR-21 | Phase 28 | Pending |
| DCR-22 | Phase 26 | Pending |
| DCR-23 | Phase 26 | Pending |
| DCR-24 | Phase 29 | Pending |
| DCR-25 | Phase 29 | Pending |
| DCR-26 | Phase 29 | Pending |
| DCR-27 | Phase 29 | Pending |

**Coverage:**
- v1.5 requirements: 27 total
- Mapped to phases: 27
- Unmapped: 0

---
*Requirements defined: 2026-04-26*
*Last updated: 2026-04-26 at v1.5 roadmap definition (Phase 25 — Phase 29 mapped).*
