# Feature Research: v1.5 Dynamic Client Registration

**Project:** Lockspire
**Milestone:** v1.5 Dynamic Client Registration (RFC 7591/7592)
**Domain:** Embedded OAuth/OIDC provider — partner-buildable client registration
**Researched:** 2026-04-25
**Confidence:** HIGH on RFC surface (specs verified) and ecosystem patterns (Keycloak, Hydra, Curity, node-oidc-provider, Auth0 verified). MEDIUM on operator-policy granularity choices (judgement call shaped by competitor behavior).

## Domain Framing

DCR has two specs that travel together:

- **RFC 7591** — registration intake. `POST /register` accepts a JSON metadata document; the server returns a `client_id`, optional `client_secret`, optional `client_id_issued_at` / `client_secret_expires_at`, and (for 7592) a `registration_access_token` + `registration_client_uri`.
- **RFC 7592** — management. `GET`/`PUT`/`DELETE` on `registration_client_uri`, authenticated by the `registration_access_token` returned at registration time.

The honest framing for v1.5 is: **DCR is not a free-for-all developer signup.** It is a policy-bounded protocol seam that lets a partner program automate the client-creation step that today requires an operator. Real-world IdPs uniformly gate this (Auth0 ships off-by-default; Keycloak ships with no whitelisted hosts so anonymous registration is de-facto disabled; Hydra requires explicit enable; Curity templates everything off a parent client). Lockspire's wedge is to do the same — secure-default, narrow, operator-governed — natively in Phoenix.

## Feature Landscape

### Table Stakes (RFC-Conformance Floor)

These are non-negotiable for a credible v1 DCR slice. Missing any of these means partners cannot complete a real OAuth integration after registering, or the implementation does not honestly meet RFC 7591/7592.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `POST /register` intake of RFC 7591 client metadata | The whole point of the milestone | MEDIUM | Reuse existing `Lockspire.Domain.Client` schema; add provenance fields (registered_via, initial_access_token_id, registration_access_token_hash) |
| `redirect_uris` validation (array, exact-match enforcement, https except localhost) | RFC 7591 explicitly REQUIRES this for redirect-flow clients; existing auth-code path already exact-matches | LOW | Already enforced for operator-created clients — reuse the same validator |
| `token_endpoint_auth_method` honored (`client_secret_basic`, `client_secret_post`, `none`) | Without this, public vs confidential clients can't be expressed | LOW | Lockspire already supports these; just thread through registration |
| `grant_types` + `response_types` honored (default `authorization_code` + `code`) | RFC 7591 §2 default; partner clients won't work otherwise | LOW | Constrain to grants Lockspire ships (`authorization_code`, `refresh_token`); reject `password`/`implicit` |
| `scope` accepted as space-separated string and validated | Required for partners to ask for the right access | LOW | Reuse the scope validator already present in auth-code path |
| Server-issued `client_id` and `client_secret` (confidential clients) | Hydra, Keycloak, Auth0 all issue these server-side; clients MUST NOT pick them | LOW | Already the case for operator clients |
| `client_id_issued_at` in response | RFC 7591 OPTIONAL but every real impl returns it; cheap | LOW | Timestamp on creation |
| `client_secret_expires_at` in response | RFC 7591 REQUIRED if `client_secret` is issued — not optional | LOW | Use `0` (never expires) for v1.5 to match Lockspire's existing operator-secret semantics |
| `registration_access_token` issued at registration | RFC 7592 §2 requires this for the management endpoint to be reachable | MEDIUM | Hash-at-rest like `client_secret`; treat as bearer credential bound to one client |
| `registration_client_uri` in response | RFC 7592 §2 REQUIRED; tells the client where to manage itself | LOW | Stable URL pattern: `/register/{client_id}` |
| `GET /register/:client_id` (read current metadata) | RFC 7592 read; partners need this to verify state | LOW | Auth via `registration_access_token` only |
| `PUT /register/:client_id` (update metadata) | RFC 7592 update; partners need to rotate redirect URIs etc. | MEDIUM | Full-replace semantics per RFC 7592 §2.2; re-validate against operator policy |
| `DELETE /register/:client_id` (deregister) | RFC 7592 delete; partner self-service hygiene | LOW | Soft-delete or hard-delete consistent with existing admin Delete |
| Standard error codes (`invalid_redirect_uri`, `invalid_client_metadata`, `invalid_software_statement` not used, `unapproved_software_statement` not used) | RFC 7591 §3.2.2 / §3.2.3 conformance | LOW | Map validation failures to these codes verbatim |
| `registration_endpoint` advertised in `/.well-known/openid-configuration` | Discovery truth — clients won't auto-discover otherwise | LOW | Mirror the `pushed_authorization_request_endpoint` pattern from v1.2 |
| Hash-at-rest for `client_secret` and `registration_access_token` | Lockspire's secure-default posture; existing pattern | LOW | Reuse `Lockspire.Domain.Client` secret hashing |

### Table Stakes (Operator Governance Floor)

Without these, DCR is a foot-gun. Every reference implementation that takes itself seriously ships these. Auth0's lack of granular controls is a known weakness, not a model.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Self-registration on/off (server policy) | Default-off matches Hydra, Keycloak (de-facto), Auth0 default; Lockspire's secure-default contract | LOW | Add `dcr_enabled` to `Lockspire.Domain.ServerPolicy` (mirror `par_required` shape) |
| Initial access token (IAT) requirement on/off | RFC 7591 §3 explicitly anticipates this; needed for any partner program with vetted partners | MEDIUM | Bearer token presented via `Authorization: Bearer …` on `POST /register`; one-time-use or N-use, with optional expiry |
| Operator can mint and revoke initial access tokens via admin UI | The IAT toggle is meaningless without a minting surface | MEDIUM | New admin LiveView `policies_live/dcr.ex` + table for IATs (similar in shape to operator-managed clients) |
| Redirect URI host allowlist (per server-policy) | Keycloak's "Trusted Hosts Policy" exists for exactly this reason — prevents arbitrary attacker-controlled callbacks | MEDIUM | Allow exact hosts and/or domain suffixes; default empty (= reject all) so misconfiguration fails closed |
| Scope allowlist (per server-policy) and default scopes | Without this, a partner can request scopes they shouldn't have; Curity calls this "default permissions" | LOW | Reuse existing scope catalog + add `dcr_allowed_scopes` policy field |
| `grant_types` allowlist (per server-policy) | Default to `authorization_code`+`refresh_token` only; reject `password`, `client_credentials` (until separately scoped), `implicit` | LOW | Defensive default — partners get the smallest viable surface |
| `response_types` allowlist | Same shape as grant_types; default `code` only | LOW | Cheap and prevents accidental implicit-flow registrations |
| `token_endpoint_auth_method` allowlist | Operators may want to forbid `none` (public clients) for their partner program | LOW | Default allow `client_secret_basic`, `client_secret_post`, `none`; operator can narrow |
| Default lifetimes for access/refresh tokens applied to DCR-created clients | Curity's "template client" pattern — registered clients inherit safe defaults | LOW | Already exists for operator-created clients; just don't expose token-lifetime fields in the registration intake |
| Reject silently-set forbidden fields | RFC 7591 §3.2.1 says server MAY substitute; we should reject (`invalid_client_metadata`) for safety, not silently mutate | LOW | Reject unknown or operator-restricted fields with explicit error; predictable beats clever |
| Per-client provenance in storage (`registered_via`, `initial_access_token_id`, `registered_at`) | Operators must be able to tell which clients are operator-created vs DCR-created at a glance | LOW | New columns on `clients` table; surface in admin index + show |
| Admin UI shows DCR-registered clients with provenance + revoke action | Without this, operators cannot govern what they cannot see | MEDIUM | Extend `clients_live/index.ex` and `clients_live/show.ex`; add filter "Origin: DCR/Operator" |
| Audit/telemetry events for register, read, update, delete | Lockspire's existing telemetry/audit posture; auditability is in Constraints | LOW | Follow existing telemetry naming (`[:lockspire, :registration, :create | :read | :update | :delete]`) |
| `registration_access_token` rotation on `PUT` (and optionally `GET`) | RFC 7592 §2 explicitly permits and recommends rotation on update | MEDIUM | Default: rotate on `PUT`, do not rotate on `GET` (matches Curity guidance and avoids surprising read-only clients) |
| `client_secret` rotation on `PUT` for confidential clients (operator-controlled policy) | RFC 7592 permits; Coder/issue-20370 calls out this gap as real | MEDIUM | Add a server-policy switch `dcr_rotate_client_secret_on_update` (default false to avoid breaking partners on every metadata edit) |
| Rate limiting on `POST /register` | Universally recommended security control; Descope/Curity/MCP guidance all flag DCR as spammable | MEDIUM | Plug-level token bucket keyed by IP and (if present) IAT id; configurable |
| Discovery wording stays narrow | Same posture as PAR/JAR; don't imply software statements, federation, or FAPI | LOW | Document in SECURITY.md and discovery-truth tests |

### Differentiators (Lockspire-Native Advantages)

These set Lockspire apart from "standard DCR endpoints bolted onto a generic server." They lean into the embedded-Phoenix shape and the operator-policy posture already established by PAR/JAR.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| LiveView admin surface for IAT minting + revocation + DCR client review | Operators stay in their existing Phoenix admin, not a separate console — matches v1.0 admin DX | MEDIUM | Mirror the `policies_live/par.ex` and `policies_live/jar.ex` shape |
| Per-client policy override hooks (mirror PAR per-client model) | Operators can "promote" a DCR client to a stricter posture without rebuilding it | LOW | Reuse the per-client policy column pattern from PAR-policy / JAR-policy |
| Truthful discovery + SECURITY doc co-evolution | Sets Lockspire apart from Auth0's "open registration" — operators can defend the slice in security review | LOW | Already the established pattern from v1.2/v1.3/v1.4 |
| End-to-end executable proof of the DCR slice (intake → admin visibility → discovery → audit) | Project-level Verification posture — partners and security reviewers can see the proof | MEDIUM | Same milestone-closure pattern as v1.4 |
| Sensible default policy preset ("partner program" preset) | A new operator can turn DCR on with one toggle and get a defensible starting posture | LOW | Bundles: IAT required, redirect host allowlist seeded from the host app's known partner domains, scopes restricted to a partner-safe subset, public clients disallowed |
| Provenance-aware client list in admin UI (DCR-origin badge, IAT used, registration timestamp) | Operators need glance-level governance, not log-diving | LOW | Cosmetic but high-value for operator confidence |
| `mix lockspire.gen.dcr_initial_access_token` (or admin-UI minting) with copy-once display | Mirrors how operators already create clients; Phoenix-native DX | LOW | One-time view in LiveView (like a fresh client_secret); never re-displayable |
| Telemetry that includes IAT id, redirect-URI rejection reasons, scope-filter outcomes | Makes DCR debuggable in production — operators won't otherwise know why a partner registration failed | LOW | Extend existing telemetry events |

### Anti-Features (Explicitly NOT in v1.5)

These are commonly requested or assumed; including any of them would either widen the embedded-library shape, add CIAM-suite breadth, or import unbounded trust surfaces. The PROJECT.md milestone declaration already excludes the first three; the rest are reinforcing fences.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| RFC 7591 §2.3 software statements (signed JWT metadata assertions) | "Real ecosystems like Open Banking use them" | Requires importing trust-root management, JWT-issuer policy, and software-statement-revocation — none of which fit the embedded-library shape | Defer to a future "ecosystem-trust" milestone; ship IATs as the v1.5 trust seam |
| External-IdP federation as a registration-trust source | "Let our partner IdP vouch for the registering app" | Conflates DCR with federation; brings IdP discovery, key rotation, and trust-hub problems into the v1.5 surface | Stay narrow; partners present an IAT minted by the operator |
| FAPI policy bundles (FAPI-1 Advanced, FAPI 2.0) | Financial-grade callers may ask | Bundling FAPI is a separate certification project; mis-shipping a "FAPI mode" toggle is worse than not having it | Future certification milestone; explicitly disclaim in SECURITY.md |
| JAR-04 encrypted request objects | Bleeds in from v1.4 carryover | Out of v1.5 scope by design (PROJECT.md); encryption is a request-object concern, not a registration concern | Future JAR-encryption milestone |
| `client_credentials` grant via DCR | "We want machine-to-machine partners" | Self-registering machine clients with operator-default scopes is exactly the abuse case Curity warns about; M2M needs operator vetting | Operators can manually create M2M clients; v1.5 DCR allowlist excludes `client_credentials` by default |
| Public-client (`token_endpoint_auth_method=none`) registration enabled by default | "Mobile/SPA partners" | Public clients via DCR is a known abuse vector for token-grant escalation | Operators can opt in via the auth-method allowlist; default forbids `none` |
| Self-service password/MFA enrollment via DCR-registered clients | Conflates DCR with end-user auth | End-user auth belongs to Sigra/host app per PROJECT.md constraints | Out of scope, document explicitly |
| Theming/branding the registration intake response | "We want our error messages styled" | Registration is a JSON API per RFC 7591 §3.2; HTML branding is a category mistake | JSON only; SECURITY/docs explain the contract |
| Allowing client-supplied `client_id`/`client_secret` | Some legacy clients try this | RFC 7591 explicitly says these MUST be ignored if present; honoring them is a vulnerability (id-collision, secret-knowledge attacks) | Server-issued only, like Hydra/Keycloak/Auth0 |
| Open registration with no operator gate as the default | "Faster onboarding" | Auth0's known weakness; matches the abuse pattern Descope/Curity document | Default-off; require explicit `dcr_enabled` toggle and (recommended) IAT requirement |
| Software-statement-shaped "trust profiles" beyond IAT | "We want tiered partners" | Trust-tier modeling is a CIAM-suite concern | Per-IAT scope/redirect-host overrides could come later as a v1.5+ enhancement |
| Multi-tenant-aware DCR (registering into a specific tenant) | "We're multi-tenant" | Lockspire is single-realm by design; multi-tenant is a host-app concern (separate Lockspire instances or host-mediated routing) | Out of scope; document |

## Feature Dependencies

```
ServerPolicy (existing) ──extended with──> DCR policy fields
   ├──> dcr_enabled (on/off)
   ├──> dcr_require_initial_access_token
   ├──> dcr_allowed_redirect_hosts
   ├──> dcr_allowed_scopes
   ├──> dcr_allowed_grant_types
   ├──> dcr_allowed_response_types
   ├──> dcr_allowed_token_endpoint_auth_methods
   └──> dcr_rotate_client_secret_on_update

InitialAccessToken (NEW domain entity)
   ├──requires──> ServerPolicy (for the gate to matter)
   └──used by──> POST /register intake

POST /register (NEW endpoint)
   ├──requires──> ServerPolicy DCR fields
   ├──requires──> InitialAccessToken validation (when policy says required)
   ├──requires──> Existing scope/redirect-uri validators (reuse, do not fork)
   ├──requires──> Existing Client schema (extended with provenance fields)
   └──issues──> registration_access_token + registration_client_uri

GET/PUT/DELETE /register/:client_id (NEW endpoints)
   ├──requires──> POST /register (to have created the client and token)
   ├──requires──> registration_access_token validation
   └──reuses──> ServerPolicy validators (PUT re-runs intake validation)

Discovery (existing)
   └──advertises──> registration_endpoint when dcr_enabled is true

Admin LiveView (existing clients_live)
   ├──extended with──> provenance column + filter
   └──extended with──> rotate-registration-token action

Admin LiveView (NEW policies_live/dcr.ex)
   ├──requires──> ServerPolicy DCR fields
   └──requires──> InitialAccessToken management

Telemetry/Audit (existing)
   └──extended with──> [:lockspire, :registration, :*] events

Rate Limiting (NEW or reused)
   └──guards──> POST /register specifically (other endpoints are already gated by client_id)
```

### Dependency Notes

- **DCR endpoints depend on ServerPolicy DCR fields:** the same effective-policy resolution pattern from PAR-policy / JAR-policy applies — one path, no admin/runtime drift. Per PARPOL-01/02 lessons, do not introduce a parallel resolution path.
- **`PUT /register/:client_id` re-runs the intake validator:** RFC 7592 §2.2 is full-replace semantics. The validator must be one function called from both `POST` and `PUT`, or operator policy will silently differ between create and update.
- **Admin UI provenance depends on storage provenance:** if `registered_via` is not on the `Client` record, the admin UI cannot honestly distinguish DCR vs operator-created clients. This is the cheapest, highest-leverage column in the milestone.
- **Discovery toggle depends on the policy switch:** if `dcr_enabled=false`, discovery MUST NOT advertise `registration_endpoint`. This mirrors how `pushed_authorization_request_endpoint` was added in v1.2.
- **Initial access tokens depend on a minting surface:** without a way to mint and revoke IATs, the IAT-required mode is unusable. The minting surface is a hard dependency, not a "nice to have."
- **Rate limiting is a soft dependency:** the slice is correct without it, but operationally indefensible. Ship at minimum a config-gated rate-limit plug; if Lockspire doesn't already pull in a rate-limit lib, this is the one place v1.5 may add a small dep.

## MVP Definition

### Launch With (v1.5 must-have)

These are required for the milestone to honestly close. Each maps to a `DCR-NN` requirement-shaped item the requirements doc can adopt.

- [ ] **DCR-01**: `POST /register` accepts RFC 7591 metadata and creates a Lockspire client constrained by operator policy, with server-issued `client_id`/`client_secret` and a `registration_access_token`.
- [ ] **DCR-02**: Operator policy controls (`dcr_enabled`, IAT requirement, redirect-URI host allowlist, scope allowlist, grant-type allowlist, response-type allowlist, token-endpoint-auth-method allowlist) are configurable via durable storage and resolved through one effective-policy path.
- [ ] **DCR-03**: Operators can mint and revoke initial access tokens through the existing Lockspire admin surface, and DCR intake honors the IAT requirement when policy is set.
- [ ] **DCR-04**: `GET`/`PUT`/`DELETE /register/:client_id` honor RFC 7592 with `registration_access_token` authentication and rotation on `PUT`.
- [ ] **DCR-05**: Discovery advertises `registration_endpoint` only when DCR is enabled, and SECURITY/docs describe only the shipped DCR slice (no software statements, no federation, no FAPI).
- [ ] **DCR-06**: Admin UI surfaces DCR-registered clients with provenance (origin, IAT used, registered_at) and a revocation path that disables the registration_access_token alongside the client.
- [ ] **DCR-07**: Telemetry and audit events cover register / read / update / delete, including rejection reasons (invalid redirect host, disallowed scope, missing IAT, etc.).
- [ ] **DCR-08**: Milestone closes with end-to-end executable proof: protocol tests for happy/negative paths, integration tests through the admin LiveView, and discovery-truth tests that fail if `registration_endpoint` advertisement drifts.

### Add After Validation (v1.5 nice-to-have, deferrable)

Implement if the must-have set lands ahead of schedule, otherwise carry to v1.6+. None of these are required for an honest v1 close.

- [ ] **DCR-NTH-01**: `client_secret` rotation on `PUT` controlled by a server-policy switch (default off).
- [ ] **DCR-NTH-02**: Per-IAT scope/redirect-host overrides (richer "trust tier" model on top of IAT).
- [ ] **DCR-NTH-03**: Built-in rate limiting on `POST /register` with operator-configurable thresholds and a Plug seam for host-app overrides.
- [ ] **DCR-NTH-04**: "Partner program" policy preset that flips the safest combination of toggles in one click in the admin UI.
- [ ] **DCR-NTH-05**: Mix task `mix lockspire.gen.initial_access_token` for operators who prefer CLI minting.
- [ ] **DCR-NTH-06**: `jwks` and `jwks_uri` honored on registration, gated behind the server-policy switches needed to make them safe (jwks_uri introduces an outbound-fetch surface).

### Future Consideration (v1.6+)

- [ ] **DCR-FUT-01**: Software statements (RFC 7591 §2.3) — defer until there's a concrete partner-trust use case.
- [ ] **DCR-FUT-02**: Federation-driven trust roots — defer until federation is its own milestone.
- [ ] **DCR-FUT-03**: FAPI policy bundles — defer; needs a certification milestone.
- [ ] **DCR-FUT-04**: `client_credentials` grant via DCR — only after a separate vetting story exists.
- [ ] **DCR-FUT-05**: Mutual-TLS-bound client authentication on registration — Open Banking pattern; out of v1.5 shape.
- [ ] **DCR-FUT-06**: Tenant-aware DCR — only if/when Lockspire grows multi-realm.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| `POST /register` intake | HIGH | MEDIUM | P1 |
| Server-policy DCR allowlists (redirects, scopes, grants, response_types, auth methods) | HIGH | LOW–MEDIUM | P1 |
| Initial access token model + admin minting/revoke | HIGH | MEDIUM | P1 |
| `GET`/`PUT`/`DELETE` 7592 management with token rotation | HIGH | MEDIUM | P1 |
| Discovery `registration_endpoint` toggle + SECURITY truth | HIGH | LOW | P1 |
| Admin UI provenance + revocation surface | HIGH | MEDIUM | P1 |
| Telemetry/audit coverage | MEDIUM | LOW | P1 |
| End-to-end milestone-closure proof | HIGH | MEDIUM | P1 |
| `client_secret` rotation on PUT (policy-gated) | MEDIUM | LOW | P2 |
| Rate limiting on `POST /register` | MEDIUM | MEDIUM | P2 |
| Partner-program policy preset | MEDIUM | LOW | P2 |
| Per-IAT overrides | MEDIUM | MEDIUM | P2 |
| `mix lockspire.gen.initial_access_token` | LOW | LOW | P3 |
| `jwks_uri` outbound-fetch support | MEDIUM | MEDIUM | P3 |
| Software statements | LOW (today) | HIGH | P3 |
| FAPI bundles | LOW (today) | HIGH | P3 |

**Priority key:**
- P1: Required for v1.5 close
- P2: Add if must-haves land early; otherwise carry forward
- P3: Defer; document as future

## Competitor Feature Analysis

| Feature | Auth0 | Keycloak | Hydra | node-oidc-provider | Curity | Our Approach |
|---------|-------|----------|-------|--------------------|--------|--------------|
| DCR default state | Off (toggle in tenant settings) | De-facto off (no trusted hosts seeded) | Off (config flag `dynamic_client_registration: enabled`) | Enabled but no IAT by default | Off (must enable DCR profile + map to template client) | **Off** by default; explicit policy toggle |
| Initial access token | Not supported (known gap) | Yes, optional | Implicit via admin-only/public-API split | First-class — IATs carry policy functions | Yes, one-time-use, dcr scope | **Yes**, optional but recommended; mintable from admin UI |
| Redirect URI host allowlist | Tenant ACL (network-level) | "Trusted Hosts Policy" with hosts/domains | Standard OAuth redirect rules | Custom policy function | Per-template-client constraints | **Yes**, per-server-policy + reusable per-client overrides |
| Scope allowlist | Default permissions on third-party APIs | Via realm scope mapping | Inherited global config | Custom policy function | Per-template-client | **Yes**, per-server-policy field |
| Grant/response-type allowlist | Limited | Yes (protocol mapper policy) | Inherited | Custom policy function | Per-template-client | **Yes**, per-server-policy field |
| `client_secret`/`registration_access_token` rotation on PUT | Limited | Limited | Limited (open issue 20370 in Coder reflects ecosystem gap) | Yes (configurable) | Yes | **Yes** — registration_access_token rotates on PUT by default; client_secret rotation is a policy toggle (default off to avoid breaking partners) |
| Provenance tracking in admin UI | Generic | Generic | Generic | N/A (no UI) | Yes, "registered via DCR" surfaced | **Yes**, first-class — origin badge, IAT used, registered_at |
| Software statements | Yes | Partial | No | Yes | Yes | **No** (out of scope) |
| Embedded-library shape | No (hosted) | No (separate service) | No (separate service) | Yes (Node lib) | No (product) | **Yes** — native Phoenix LiveView admin |

The takeaway is that **node-oidc-provider's policy-function model is the closest match philosophically** (narrow protocol core + extensibility), but Lockspire's wedge is to make those policies declarative server-policy fields instead of host-supplied callback functions. That keeps the embedded-library shape: operators configure through admin UI and durable storage; they don't write protocol code.

## Implementation Notes for Roadmap

- **Reuse the PAR-policy and JAR-policy shape verbatim:** server-level fields in `Lockspire.Domain.ServerPolicy`, optional per-client overrides on `Lockspire.Domain.Client`, one effective-policy resolver, one admin LiveView per policy domain (`policies_live/dcr.ex`). The team already has muscle memory for this.
- **Provenance is the cheap win:** three columns on `clients` (`registered_via`, `initial_access_token_id`, `registered_at_via_dcr`) unlock most of the operator-confidence story.
- **One validator, two callers:** the metadata validator must be called from both `POST /register` and `PUT /register/:client_id` to avoid create/update drift (the PARPOL-01/02 lesson).
- **Discovery truth is a closure gate, not a checkbox:** v1.2/v1.3/v1.4 each had a discovery-truth requirement; v1.5 needs the same — `registration_endpoint` MUST appear iff `dcr_enabled` is true, and SECURITY.md MUST describe only the shipped slice.
- **Rate limiting is the one place v1.5 may justifiably add a dep** if Lockspire doesn't already have a token-bucket plug. If adding a dep is unwelcome, ship a minimal in-process token bucket and document the seam for hosts to override.
- **Anti-feature discipline:** software statements, federation, FAPI bundles, JAR-04, public-client-by-default, M2M-by-default — every one of these is a v1.5 scope-creep magnet. The requirements doc should restate them as explicit non-goals so phase planning can refuse them cleanly.

## Sources

- [RFC 7591 - OAuth 2.0 Dynamic Client Registration Protocol](https://datatracker.ietf.org/doc/html/rfc7591) — HIGH (spec)
- [RFC 7592 - OAuth 2.0 Dynamic Client Registration Management Protocol](https://datatracker.ietf.org/doc/html/rfc7592) — HIGH (spec)
- [Auth0 — Dynamic Client Registration](https://auth0.com/docs/get-started/applications/dynamic-client-registration) — HIGH
- [Auth0 Community — Initial Access Token gap](https://community.auth0.com/t/initial-access-token-for-dynamic-client-registration/85053) — MEDIUM (community confirmation of the known limitation)
- [Keycloak — Using the client registration service](https://www.keycloak.org/securing-apps/client-registration) — HIGH (Trusted Hosts + Protocol Mapper policies)
- [Keycloak Issue #19513 — Trusted Hosts behavior](https://github.com/keycloak/keycloak/issues/19513) — MEDIUM
- [Ory Hydra Issue #1616 — RFC 7591/7592 support](https://github.com/ory/hydra/issues/1616) — HIGH
- [Ory Hydra Issue #4060 — Optional access-token strategy for DCR](https://github.com/ory/hydra/issues/4060) — MEDIUM
- [node-oidc-provider docs (panva)](https://github.com/panva/node-oidc-provider/blob/main/docs/README.md) — HIGH (initial access tokens, registration policies)
- [Curity — Dynamic Client Registration overview](https://curity.io/resources/learn/openid-connect-understanding-dcr/) — HIGH
- [Curity — How to Manage Dynamic Client Registration](https://curity.io/resources/learn/dynamic-client-registration-management/) — HIGH
- [Curity — Using Dynamic Client Registration (template clients, IAT scope)](https://curity.io/resources/learn/using-dynamic-client-registration/) — HIGH
- [OpenIddict Issue #2404 — RFC 7591/7592 support](https://github.com/openiddict/openiddict-core/issues/2404) — MEDIUM (confirms even mature .NET stack treats DCR as a separate milestone)
- [Coder Issue #20370 — client secret rotation per RFC 7592](https://github.com/coder/coder/issues/20370) — MEDIUM (real-world operator pain point)
- [Descope — Tips to Harden OAuth DCR in MCP Servers](https://www.descope.com/blog/post/dcr-hardening-mcp) — MEDIUM
- [WorkOS — DCR in MCP](https://workos.com/blog/dynamic-client-registration-dcr-mcp-oauth) — MEDIUM
- [OpenID Connect Dynamic Client Registration 1.0](https://openid.net/specs/openid-connect-registration-1_0.html) — HIGH (spec — relationship to RFC 7591)

---
*Feature research for: Lockspire v1.5 Dynamic Client Registration*
*Researched: 2026-04-25*
