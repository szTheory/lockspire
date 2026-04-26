# Stack Research

**Project:** Lockspire
**Milestone:** v1.5 Dynamic Client Registration (RFC 7591/7592)
**Domain:** Embedded OAuth/OIDC provider — DCR intake + RFC 7592 management on existing Phoenix/Ecto/JOSE stack
**Researched:** 2026-04-25
**Confidence:** HIGH

## Headline

**Hand-roll v1.5 on the existing stack. No new runtime dependencies are required and none are recommended.** Every capability the v1.5 scope demands — JSON intake, metadata validation, registration_access_token issuance and rotation, policy enforcement, discovery advertisement, and admin UI — is already covered by libraries Lockspire ships with (`phoenix`, `phoenix_live_view`, `ecto_sql`, `jason`, `jose`, `:crypto`, `telemetry`). The only "stack" delta is a small set of internal modules and two Ecto migrations layered onto patterns Lockspire has already established for PAR (v1.2/v1.3) and JAR (v1.4).

This is the same conclusion v1.2 PAR research reached for the same reason: the embedded-library shape forbids adding dependencies that would force decisions onto host apps, and the protocol surface is small enough that hand-rolling on `Plug` + `Ecto` + `:crypto` is cheaper than integrating an external provider library.

There is no Elixir library on Hex.pm that implements an RFC 7591/7592 *authorization-server* registration endpoint as a drop-in seam. The only OAuth/OIDC provider library in the ecosystem that ships DCR is `boruta_auth`, which is a competitor product, not a component — adopting it would replace Lockspire, not augment it. Client-side libraries (`oidcc`) are irrelevant: they consume DCR endpoints, they don't expose them.

## Recommended Stack

### Core Technologies (already present — no changes)

| Technology | Current pinned version | Purpose for v1.5 | Why this is enough |
|---|---|---|---|
| `phoenix` | `~> 1.8.5` | Mounts `POST /register` and `GET/PUT/DELETE /register/:client_id` controllers in `Lockspire.Web.Router` next to `/par`, `/token`, `/authorize`. | RFC 7591/7592 are plain JSON-over-HTTPS endpoints with no transport quirks; Phoenix `Plug` pipeline + `Phoenix.Controller` handle them with the same shape used by `PushedAuthorizationRequestController`. |
| `phoenix_live_view` | `~> 1.1.28` | Adds DCR-specific surfaces to `Lockspire.Web.Live.Admin.ClientsLive.*` (provenance badge, registration-access-token rotation, self-registered filter, IAT issuance). | The admin UI for clients is already LiveView; DCR provenance is a column-and-action delta, not a new UI engine. Same pattern as the JAR policy LiveView shipped in v1.4. |
| `ecto_sql` + `postgrex` | `~> 3.13.5` / `>= 0.0.0` | Two thin migrations on `lockspire_clients` (`registration_access_token_hash`, `registration_client_uri`, `registered_via`, `initial_access_token_hash` lookup table) and a small `lockspire_initial_access_tokens` table. | Existing `ClientRecord` already stores all RFC 7591 metadata (`redirect_uris`, `allowed_grant_types`, `allowed_response_types`, `token_endpoint_auth_method`, `jwks`, `jwks_uri`, `logo_uri`, `tos_uri`, `policy_uri`, `contacts`, `metadata` jsonb). DCR is an *intake path* into a schema that already exists, not a new schema. |
| `jose` | `~> 1.11` | Validates `jwks` / `jwks_uri` content submitted in registration requests using the same JWK plumbing already used by JAR. | JOSE is already the project's JWS/JWK library; reusing it for inline-JWK registration validation keeps a single trust path. |
| `jason` | `~> 1.4` | Decodes `application/json` registration bodies and encodes RFC 7591 §3.2.1 success responses. | Lockspire already encodes/decodes JSON payloads (introspection, discovery, token, JAR claims). |
| `:crypto` (OTP) | n/a (stdlib) | Generates `client_id`, `client_secret`, `registration_access_token`, and `initial_access_token` random material; SHA-256-with-salt hashing for token-at-rest storage (matches `Lockspire.Security.Policy.hash_client_secret/1` and `hash_token/1`). | Lockspire already hashes client secrets via `:crypto.strong_rand_bytes/1` + `:crypto.hash(:sha256, salt <> secret)` in `Lockspire.Security.Policy`. Registration access tokens are bearer tokens, not passwords; SHA-256 with high-entropy random material is the standard treatment (same rationale used for refresh tokens and PAR `request_uri` storage). |
| `telemetry` + `opentelemetry_api` | `~> 1.3` / `~> 1.5` | Emits `:client_registered_dynamically`, `:client_registration_rejected`, `:registration_access_token_rotated`, `:client_self_deleted` events through `Lockspire.Observability`. | Existing audit/observability seams cover this; DCR is just additional event names. |
| `oban` | `~> 2.21` | (Optional) background job for `jwks_uri` re-fetch / sector_identifier_uri verification if the team chooses to defer those off the request path. | Already in the dep list; not strictly required for v1.5 since `jwks_uri` validation can happen synchronously on register/update. Use only if perf/availability data justifies it. |

### Supporting Libraries

| Library | Decision | Rationale |
|---|---|---|
| **None** — no new runtime dep | **Do not add** | The v1.5 scope is fully covered by libraries already pinned. Adding any of the candidates below would either duplicate existing functionality (`ex_json_schema`, `argon2_elixir`) or import scope Lockspire has explicitly excluded (`boruta_auth`). |

### Internal Modules to Create (not dependencies — Lockspire-owned code)

| Module | Responsibility | Mirrors |
|---|---|---|
| `Lockspire.Protocol.DynamicRegistration` | Pure-function metadata validator: redirect URIs, grant/response types, auth method, scope subsetting, `jwks` xor `jwks_uri`, `software_id`/`software_version` echo, `client_name`/`logo_uri`/`tos_uri`/`policy_uri`/`contacts` normalization. Returns `{:ok, normalized_metadata}` or `{:error, [%{field:, reason:, detail:}]}`. | `Lockspire.Protocol.Par`, `Lockspire.Protocol.Jar` — same shape, same error contract. |
| `Lockspire.Protocol.DynamicRegistration.Policy` | Operator policy gate: scope/redirect-URI/grant-type/response-type/auth-method allowlists, default lifetimes, self-registration on/off, IAT requirement. Reads from a `Lockspire.Domain.RegistrationPolicy` (mirrors `Lockspire.Domain.ServerPolicy` with `par_policy`/`jar_policy`). | `Lockspire.Protocol.JarPolicy`, the v1.3 PAR policy module. |
| `Lockspire.Protocol.RegistrationAccessTokens` | Issue / hash / verify / rotate `registration_access_token`. SHA-256-with-salt at rest, opaque high-entropy bearer over the wire. | `Lockspire.Security.Policy.hash_client_secret/1`, refresh-token rotation. |
| `Lockspire.Protocol.InitialAccessTokens` | (Optional, gated by policy) issue/verify/revoke initial access tokens used to gate `POST /register`. | Same primitives as registration access tokens. |
| `Lockspire.Web.RegistrationController` | `create/2` (RFC 7591 §3.1), and `Lockspire.Web.RegistrationManagementController` for `show/2`, `update/2`, `delete/2` (RFC 7592 §2). Bearer auth via the existing `Lockspire.Protocol.ClientAuth` shape but bound to `registration_access_token`. | `Lockspire.Web.PushedAuthorizationRequestController`. |
| `Lockspire.Storage.Ecto.ClientRecord` (additive fields) | Add `registration_access_token_hash`, `registration_client_uri`, `registered_via :: Ecto.Enum [:operator, :dynamic]`, `software_id`, `software_version`, `software_statement` (nullable, will stay null in v1.5 since software statements are out of scope). | The same migration pattern used to add `par_policy` and `jar_policy`. |
| `Lockspire.Web.Live.Admin.PoliciesLive.Registration` | LiveView at `/admin/policies/registration` for the operator policy form. | `Lockspire.Web.Live.Admin.PoliciesLive.Par`, `Lockspire.Web.Live.Admin.PoliciesLive.Jar`. |

### Development Tools (already present — no changes)

| Tool | Purpose | Notes |
|---|---|---|
| `credo` `~> 1.7` | Lint / style gate via `mix qa`. | Already wired. |
| `dialyxir` `~> 1.4` | Type-spec gate via `mix qa`. | Already wired; new modules must carry `@spec`. |
| `ex_doc` `~> 0.38` | HexDocs build via `mix docs.verify`. | Add `docs/dynamic-registration.md` to `mix.exs` `extras`. |
| `lazy_html` | LiveView assertions in tests. | Already present, used by existing admin LiveView tests. |

## Installation

No new packages. `mix.exs` should remain unchanged for v1.5.

If the team later decides to add an internal `mix lockspire.install --with-dcr` hint, that is a generator concern, not a dependency concern.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative | Why Not for Lockspire v1.5 |
|---|---|---|---|
| Hand-roll on `Plug` + `Ecto` + `:crypto` | `boruta_auth` (`malach-it/boruta_auth`) | Greenfield Phoenix app that wants a complete OAuth/OIDC provider drop-in *and* has no operator-UX requirements of its own. | Boruta is a *competing provider*, not a *component*. Lockspire already owns the protocol core, storage layer, admin UI, telemetry, and host-seam contract; importing Boruta would mean replacing those, not extending them. Contradicts the v1.0 architectural decision to keep "strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and operator UI." |
| Internal `Lockspire.Protocol.DynamicRegistration` validator | `ex_json_schema` `~> 0.11.2` (Dec 2025) | A project that wants Draft-7 JSON Schema validation for free-form payloads it doesn't own. | RFC 7591 metadata is a *closed, finite* set of fields with semantic constraints (redirect URI scheme rules, grant/response type pairings, `jwks` xor `jwks_uri`, scope subsetting against operator policy) that JSON Schema cannot express in one pass. Hand-rolled validation matches Lockspire's existing PAR/JAR validator shape and keeps the error-detail contract (`%{field:, reason:, detail:}`) consistent across the codebase. Adds a dep with no payoff. |
| Internal `Lockspire.Protocol.DynamicRegistration` validator | `jsv` `~> 0.18.3` (Apr 2026) | A project that wants Draft 2020-12 JSON Schema with compile-time schema modules. | Same reasoning as `ex_json_schema`, plus `jsv` is at `0.18.x` (still pre-1.0) and would import schema-DSL surface area Lockspire has no other use for. |
| `:crypto` SHA-256-with-salt for token hashing | `argon2_elixir` `~> 4.1.3` (Apr 2025) | Hashing *user-chosen passwords* where attackers can run offline cracking against low-entropy secrets. | `registration_access_token`, `client_secret`, and `initial_access_token` are 32-byte high-entropy values from `:crypto.strong_rand_bytes/1`. Argon2's memory-hardness is wasted on uniformly random 256-bit inputs — and adding a NIF-based password hasher would force every host app to compile Argon2 against its libc, which contradicts the "embedded library, easy install" posture. Keeps the same approach already taken for client secrets. |
| Sync validation of `jwks_uri` on register | `oban` background job for `jwks_uri` fetch | If `jwks_uri` fetches start dominating registration latency or producing flaky failures in production. | Premature for v1.5. Sync fetch is simpler, gives correct errors back to the registering client, and matches how JAR validates `jwks_uri` today. `oban` is already present if needed. |
| No new rate-limiting dep in v1.5 | `hammer` `~> 7.3.0` (Mar 2026) + `hammer-plug` | If self-registration goes live on the public internet without an IAT requirement and starts attracting registration spam. | Out of scope for v1.5. Operator policy already provides "self-registration off" and "require initial access token" knobs that solve the abuse vector without a new dep. If a future milestone opens fully-anonymous registration, revisit Hammer at that point. **Note:** Hammer is the right answer when needed — flagging it here so it isn't reinvented later. |

## What NOT to Use

| Avoid | Why | Use Instead |
|---|---|---|
| `boruta_auth` as a dependency | Replaces, rather than augments, Lockspire's protocol core, storage, and admin UI. Adopting it contradicts every v1.0 architectural decision. | Hand-roll `Lockspire.Protocol.DynamicRegistration` modules. |
| `oidcc` | Client-side OIDC library — it *consumes* DCR endpoints, it doesn't *expose* them. Wrong direction of trust. | N/A — Lockspire is the authorization server. |
| `argon2_elixir` / `bcrypt_elixir` for `registration_access_token` | Memory-hard password hashing is the wrong tool for hashing 256-bit random bearer tokens. Adds NIF compile burden to every host app. | `:crypto.hash(:sha256, salt <> token)` via the existing `Lockspire.Security.Policy` seam. |
| `ex_json_schema` / `jsv` for RFC 7591 metadata | RFC 7591 has cross-field constraints (`jwks` xor `jwks_uri`, grant/response coherence, scope subsetting against operator policy) that JSON Schema can't express cleanly. Splits the validator into two layers. | One pure-function validator, same shape as `Lockspire.Protocol.Par` / `Lockspire.Protocol.Jar`. |
| `hammer` *in v1.5* | Operator policy (self-registration on/off, IAT-required) already provides the abuse-control knobs the milestone needs. Adding Hammer expands install-time decisions for host apps. | Operator policy controls. Re-evaluate Hammer if/when fully-anonymous registration lands. |
| Software-statement signing libraries (any) | Software statements (RFC 7591 §2.3) are explicitly out of scope. Adding the dep now imports surface area no shipped feature uses. | N/A — leave the column nullable, document the field as not consumed. |
| External-IdP federation libraries (e.g., `assent`, `ueberauth`) | "External-IdP federation / initial access from upstream IdPs" is explicitly out of scope. | N/A. |

## Stack Patterns by Variant

**If self-registration is operator-disabled (default off):**
- `POST /register` returns `403 access_denied` per RFC 7591 §3.2.2.
- `registration_endpoint` still appears in discovery (RFC 8414 doesn't carve it out conditionally), but operator docs must explain the registration is gated.
- IAT issuance UI in admin LiveView is the only entry point for new clients.
- This is the recommended *default* posture for v1.5.

**If self-registration is operator-enabled with required IAT:**
- `POST /register` requires `Authorization: Bearer <initial_access_token>`.
- IATs are operator-issued via admin LiveView, single-use, with optional max-uses and expiry.
- Same hashing seam as `registration_access_token` (SHA-256 with salt).

**If self-registration is operator-enabled without IAT (open registration):**
- Out of v1.5 default surface but technically representable. Documentation should warn this requires external rate limiting (Hammer or upstream WAF) before going live.
- Telemetry must be in place to detect abuse before this mode is recommended.

## Version Compatibility

| Package A | Compatible With | Notes |
|---|---|---|
| `phoenix ~> 1.8.5` | `phoenix_live_view ~> 1.1.28` | Already pinned together; LiveView 1.1.x supports Phoenix 1.7+ and 1.8+. No changes needed. |
| `ecto_sql ~> 3.13.5` | `postgrex >= 0.0.0` | Migrations for v1.5 are vanilla `add column` / new table — no Ecto 4 surface. |
| `jose ~> 1.11` | `jason ~> 1.4` | JOSE consumes Jason for JWK serialization; same versions already used by JAR validator. |
| `:crypto` (OTP) | OTP 26+ (matches Elixir 1.18 floor) | SHA-256, `strong_rand_bytes/1`, `hash_equals/2` (constant-time compare for hashes) all stable since OTP 22; safe under any OTP we'll support. |

## Integration Points with Existing Seams

| Existing seam | What v1.5 adds | Risk |
|---|---|---|
| `Lockspire.Web.Router` | Two route blocks: `post "/register"`, `get/put/delete "/register/:client_id"`, `live "/admin/policies/registration"`. | Low — same shape as `/par` and `/admin/policies/par`. |
| `Lockspire.Protocol.Discovery` | Add `registration_endpoint` to the metadata document. The endpoint must always advertise truthfully — if self-registration is off, the URL still resolves and returns a structured `403 access_denied`, matching the project's PAR-era discipline of "discovery describes only the shipped slice." | Low — discovery already advertises `pushed_authorization_request_endpoint` and `request_object_signing_alg_values_supported` conditionally. |
| `Lockspire.Storage.Ecto.ClientRecord` | New nullable columns; `to_domain/1` updated to carry them. Existing operator-created clients get `registered_via: :operator` via migration backfill. | Low — additive migration, mirrors the `par_policy` / `jar_policy` migrations. |
| `Lockspire.Admin.Clients` | New `register_dynamically/2` (called from controller, *not* from operator UI), `rotate_registration_access_token/2`, `delete_self_registered_client/2` paths with their own audit-event reason codes (`:dynamic_registration_succeeded`, `:registration_access_token_rotated`, `:client_self_deleted`). | Medium — must enforce that operator UI cannot edit `registration_access_token_hash` and that dynamic clients cannot escalate themselves out of policy bounds via PUT. |
| `Lockspire.Web.Live.Admin.ClientsLive.*` | Provenance badge (operator vs. dynamic), filter, "rotate registration access token" action on confidential dynamic clients, "issue initial access token" affordance on the policy LiveView. | Low — the LiveView already supports a multi-action `Show` page; this is an additive action. |
| `Lockspire.Domain.ServerPolicy` | New sibling: `Lockspire.Domain.RegistrationPolicy` with `self_registration_enabled?`, `require_initial_access_token?`, `allowed_grant_types`, `allowed_response_types`, `allowed_token_endpoint_auth_methods`, `allowed_scopes`, `allowed_redirect_uri_schemes`, `default_token_endpoint_auth_method`, `default_grant_types`. | Low — cleanly mirrors the existing `par_policy` / `jar_policy` server-policy approach. |
| `Lockspire.Observability` | New event names; no new transport. | Low. |
| `Lockspire.Protocol.ClientAuth` | A new authentication mode "registration access token bearer" lives *next to* — not inside — the existing token-endpoint client-auth mux. RAT auth is endpoint-bound to `/register/:client_id`; it must not authenticate against `/token`. | Medium — the boundary is important; tests must lock this in. |

## Sources

- **Hex.pm registry (verified 2026-04-25 against the candidate set):**
  - [argon2_elixir v4.1.3 (last published Apr 27, 2025)](https://hex.pm/packages/argon2_elixir) — verified for the "do we add a password hasher?" question. Answer: no; wrong tool for random bearer tokens.
  - [hammer v7.3.0 (last published Mar 31, 2026)](https://hex.pm/packages/hammer) — verified for rate-limiting deferral. Answer: not in v1.5; operator policy covers the abuse vector.
  - [jsv v0.18.3 (last published Apr 21, 2026)](https://hex.pm/packages/jsv) — verified as a JSON Schema option. Answer: no; cross-field constraints and pre-1.0 status argue against it.
  - [ex_json_schema v0.11.2 (last published Dec 16, 2025)](https://hex.pm/packages/ex_json_schema) — verified as a JSON Schema option. Answer: no; same reason as jsv plus Draft-7 only.
- **RFCs (authoritative protocol surface):**
  - [RFC 7591 — OAuth 2.0 Dynamic Client Registration Protocol](https://datatracker.ietf.org/doc/html/rfc7591)
  - [RFC 7592 — OAuth 2.0 Dynamic Client Registration Management Protocol](https://datatracker.ietf.org/doc/html/rfc7592)
- **Ecosystem libraries reviewed and rejected:**
  - [erlef/oidcc on GitHub](https://github.com/erlef/oidcc) — OIDC *client* library; wrong side of the trust boundary for Lockspire.
  - [malach-it/boruta_auth on GitHub](https://github.com/malach-it/boruta_auth) — competing OAuth/OIDC *provider* core; adopting it would replace Lockspire, not augment it.
  - [oauth.net Elixir code list](https://oauth.net/code/elixir/) — confirmed there is no Elixir authorization-server library on Hex.pm that exposes RFC 7591/7592 as a mountable component without bringing its own protocol core.
- **Internal repository inputs:**
  - `/Users/jon/projects/lockspire/.planning/PROJECT.md` — v1.5 scope, validated capabilities, out-of-scope list.
  - `/Users/jon/projects/lockspire/mix.exs` — current dependency pinning.
  - `/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/client_record.ex` — confirmed RFC 7591 metadata fields already present in the schema.
  - `/Users/jon/projects/lockspire/lib/lockspire/admin/clients.ex` — confirmed audit/observability/policy seams already exist for client CRUD.
  - `/Users/jon/projects/lockspire/lib/lockspire/web/router.ex` — confirmed mounting pattern for new endpoints and admin LiveView.
  - `/Users/jon/projects/lockspire/lib/lockspire/clients.ex` and `/Users/jon/projects/lockspire/lib/lockspire/security/policy.ex` — confirmed `:crypto` SHA-256-with-salt is the project's existing token-hashing approach.

---
*Stack research for: Lockspire v1.5 Dynamic Client Registration*
*Researched: 2026-04-25*
*Confidence: HIGH (Hex.pm versions verified same day; RFC surface authoritative; integration points cross-checked against repo source.)*
