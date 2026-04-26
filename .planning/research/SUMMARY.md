# Project Research Summary — v1.5 Dynamic Client Registration

**Project:** Lockspire
**Milestone:** v1.5 Dynamic Client Registration (RFC 7591/7592)
**Domain:** Embedded OAuth/OIDC authorization-server library — adding partner-buildable client registration to a provider that already ships PAR (v1.2/v1.3) and JAR (v1.4)
**Researched:** 2026-04-25
**Confidence:** HIGH

## Executive Summary

v1.5 turns Lockspire from operator-tended into partner-buildable by adding RFC 7591 intake (`POST /register`) and RFC 7592 management (`GET/PUT/DELETE /register/:client_id`) on top of the existing protocol core, storage layer, admin LiveView, and discovery surface. The dominant move is **not invention**: the four research files independently converge on copying the PAR/JAR shape (server-policy singleton + per-client/per-IAT narrowing + thin controller + admin LiveView page + truthful discovery + lifecycle audit) one more time, with provenance and a registration-access-token credential bolted onto the existing `lockspire_clients` row.

**The single highest-leverage finding is that v1.5 needs ZERO new runtime dependencies.** Every capability the milestone demands — JSON intake, RFC 7591 metadata validation, registration_access_token issuance and rotation, IAT lifecycle, policy enforcement, discovery advertisement, and admin UI — is already covered by libraries Lockspire ships with (`phoenix`, `phoenix_live_view`, `ecto_sql`, `jason`, `jose`, `:crypto`, `telemetry`, `oban` if needed). The only "stack" delta is internal Lockspire-owned modules and three additive Ecto migrations. There is no Hex.pm library that exposes RFC 7591/7592 as a drop-in seam without bringing its own protocol core (`boruta_auth` would replace Lockspire, not augment it; `oidcc` is the wrong side of the trust boundary). `mix.exs` should remain unchanged for v1.5.

The risk profile is dominated by **shape drift, not protocol mechanics**. DCR is the first endpoint that lets non-operators create durable trust state, so every weakness in policy enforcement, provenance attribution, audit coverage, and discovery truthfulness gets amplified beyond what PAR or JAR exposed. The three sharpest Lockspire-specific concerns: (1) `Lockspire.Admin.Clients.actor_from_attrs/1` defaults to `:operator` — a DCR call that fell through that default would log *false* operator provenance; (2) `token_endpoint_auth_methods_supported` in `Lockspire.Protocol.Discovery` is currently wider than what DCR can safely accept (the domain typespec admits `private_key_jwt` etc., but discovery is the truth source and DCR must bind to it); (3) the v1.4 JAR rule that `jar_policy: :required` requires inline `jwks` must not be silently broken by DCR accepting only `jwks_uri`. Mitigation: ship default-off, IAT-required as the recommended on-mode, hash-at-rest for both IATs and registration access tokens, allowlist intersection (never widen), provenance-aware audit from day one, and discovery gated on both route mount AND policy enabled.

## Key Findings

### Recommended Stack — hand-roll on existing stack; no new runtime deps.

Core technologies (already pinned, unchanged):
- `phoenix ~> 1.8.5` — mounts the four new routes + admin LiveView; same Plug shape as `PushedAuthorizationRequestController`
- `phoenix_live_view ~> 1.1.28` — provenance badges, RAT rotation, IAT mint/revoke; same pattern as v1.4 JAR LiveView
- `ecto_sql ~> 3.13.5` / `postgrex` — three additive migrations (DCR fields on `server_policies`, provenance + RAT/timestamp fields on `clients`, new `lockspire_initial_access_tokens` table); `ClientRecord` already stores all RFC 7591 metadata
- `jose ~> 1.11` — validates inline `jwks`
- `jason ~> 1.4` — RFC 7591 §3.2.1 JSON
- `:crypto` — random material + SHA-256-with-salt hashing matching `Lockspire.Security.Policy`
- `telemetry` + `opentelemetry_api` — DCR-lifecycle events through `Lockspire.Observability`
- `oban ~> 2.21` — optional for `jwks_uri` background fetch / abandoned-client cleanup; sync validation is correct for v1.5

**Explicitly NOT adding:** `boruta_auth` (competing provider), `argon2_elixir` / `bcrypt_elixir` (wrong tool for random bearer tokens), `ex_json_schema` / `jsv` (RFC 7591 has cross-field constraints JSON Schema can't express), `hammer` (operator policy is the abuse-control story; revisit if/when fully-anonymous registration lands), software-statement libraries (out of scope).

**Internal modules to create:** `Lockspire.Protocol.{DynamicRegistration, RegistrationManagement, DcrPolicy, RegistrationAccessToken, InitialAccessToken}`, `Lockspire.Web.{RegistrationController, RegistrationManagementController, RegistrationJSON}`, `Lockspire.Admin.InitialAccessTokens`, `Lockspire.Web.Live.Admin.PoliciesLive.Dcr`, `Lockspire.Web.Live.Admin.IatLive.{Index,New}`, `Lockspire.Domain.InitialAccessToken`, plus extensions to `Domain.{Client, ServerPolicy}`, `Storage.Ecto.{ClientRecord, ServerPolicyRecord, Repository}`, `Admin.{Clients, ServerPolicy}`, `Protocol.Discovery`, and `Web.Router`.

### Expected Features

**Must have (P1, table stakes):**
- DCR-01 `POST /register` RFC 7591 intake
- DCR-02 operator policy controls (`registration_policy: :disabled | :initial_access_token | :open` plus allowlists, defaults) resolved through one effective-policy path
- DCR-03 IAT mint/revoke through admin LiveView, hashed at rest, single-use by default, with optional per-IAT policy_overrides
- DCR-04 RFC 7592 GET/PUT/DELETE with RAT auth, rotation on PUT, soft-disable on DELETE (reuses `disable_client_with_audit/4`)
- DCR-05 truthful discovery (`registration_endpoint` only when policy non-disabled)
- DCR-06 admin provenance + filter + revocation
- DCR-07 full DCR-lifecycle telemetry/audit
- DCR-08 milestone closure with executable proof

**Should have (P2, deferrable to v1.6):**
- `client_secret` rotation on PUT (default off)
- Per-IAT scope/redirect-host overrides
- Built-in rate limiting
- "Partner program" policy preset
- `mix lockspire.gen.initial_access_token`
- `jwks_uri` outbound fetch (gated by SSRF protections)

**Anti-features (explicitly NOT in v1.5):** software statements (RFC 7591 §2.3); external-IdP federation; FAPI bundles; JAR-04; `client_credentials` via DCR; public-client default; open-no-gate default; client-supplied `client_id` / `client_secret`; multi-tenant DCR.

### Architecture — PAR/JAR pattern applied a third time, plus IAT as a multi-row credential.

Self-registered clients are regular clients at the protocol layer (same `/authorize`, `/token`, `/par`, `/userinfo`, `/revoke`, `/introspect` paths); they differ only in (a) origin (`:provenance`), (b) extra credentials bound to the row (`registration_access_token_hash`, `registration_client_uri`), (c) RFC 7591 §3.2.1 timestamps. **No `SelfRegisteredClientRecord` schema** — provenance is one enum field on the existing `ClientRecord`.

**Major components:**
1. `Lockspire.Protocol.Registration` — RFC 7591 metadata pipeline; pre-filters with `DcrPolicy.Resolved`, then *delegates persistence to `Lockspire.Clients.register_client/1`* to avoid forking the validation surface
2. `Lockspire.Protocol.RegistrationManagement` — RFC 7592 read/update/delete; delegates writes to `Admin.Clients.{update_client, disable_client}` with `actor = {type: :self_registered_client, id: client_id}`
3. `Lockspire.Protocol.DcrPolicy` — three-way intersection resolver (server × IAT × inbound) mirroring `ParPolicy` / `JarPolicy`
4. RAT and IAT modules with hash-at-rest
5. Thin controllers mirroring `PushedAuthorizationRequestController`
6. Admin LiveView surfaces (`PoliciesLive.Dcr` mirrors PAR/JAR pages; `ClientsLive` gets provenance column + RAT-rotate live_action; new `IatLive`)
7. Extended `Discovery` gated on route AND policy

**Storage shape (additive only):**
- `lockspire_server_policies` — DCR policy fields
- `lockspire_clients` — `provenance` (backfilled `:operator`), `registration_access_token_hash`, `registration_client_uri`, `initial_access_token_id`, `client_id_issued_at`, `client_secret_expires_at`, `last_used_at`, `client_expires_at`
- `lockspire_initial_access_tokens` — new table with atomic `redeem_initial_access_token/1`

### Critical Pitfalls (top 5 of 15)

1. **Self-registration left wide open by default** — ship `:disabled` default, `:initial_access_token` recommended on-mode.
2. **RAT treated like a session cookie** — hash like `client_secret_hash`, return plaintext once, rotate only on update/delete, require URL-`client_id`-vs-token-hash binding in one query, redaction tests.
3. **SSRF via `jwks_uri` / `sector_identifier_uri` / `logo_uri`** — https-only, public-IP-only DNS check, body cap, short timeouts, no redirects, never fetch `logo_uri` / `tos_uri` / `policy_uri` server-side.
4. **Lockspire-specific:** `actor_from_attrs/1` defaulting to `:operator` would log *false* operator provenance — add provenance enum, update `actor_from_attrs/1` to require explicit `:dcr` actor on DCR paths, emit `[:lockspire, :client, :dcr_registered]` distinct from `:client_created`.
5. **Lockspire-specific:** `token_endpoint_auth_methods_supported` is wider than DCR should allow — discovery is the truth source, invariant test required.

Other critical pitfalls addressed in dedicated phases: `jwks` xor `jwks_uri` (key-confusion against JAR; v1.4 inline-JWKS invariant must hold); redirect-URI exact-match parity (route DCR through `Clients.validate_redirect_uris/1`); `grant_types` / `response_types` coherence; PKCE/PAR/JAR floor for DCR clients (`pkce_required: true` mandatory; `dcr_min_par_policy` / `dcr_min_jar_policy`); discovery untruth (three-mode contract test); allowlist enforcement (server-side intersect); audit lifecycle vocabulary; abandoned-client buildup (`last_used_at` / `client_expires_at` columns in Phase 1); RFC 7592 DELETE soft-disable; IAT leakage and constraint enforcement.

## Implications for Roadmap

Both `STACK.md` and `ARCHITECTURE.md` independently suggest a similar 4–5 phase scaffold; `PITFALLS.md` provides a pitfall-to-phase mapping that aligns with that scaffold. Continue numbering from **Phase 25** (v1.4 closed at Phase 24). The shape below assumes 5 phases; if scope tightens, Phase 28 and Phase 29 can fold together for 4 phases. Phase 25 cannot be split — the resolver depends on the schema.

**Phase 25: DCR storage skeleton, domain types, and policy resolver.**
*Rationale:* every later phase depends on storage + domain + resolver existing; doing them together avoids half-applied migrations and keeps the resolver unit-testable without HTTP.
*Delivers:* three migrations (with `:operator` backfill), extended `Domain.{Client, ServerPolicy}`, new `Domain.InitialAccessToken`, extended `Storage.Ecto.{ClientRecord, ServerPolicyRecord, Repository}`, new `InitialAccessTokenRecord`, `Lockspire.Protocol.DcrPolicy` resolver, `Admin.ServerPolicy.{get_dcr_policy/0, put_dcr_policy/1}`, audit/telemetry vocabulary defined.
*Avoids pitfalls:* 1, 8, 10, 11, 13.
*Research flag:* none — direct reuse of `add_jar_policy_*` migration patterns.

**Phase 26: Protocol pipeline — RFC 7591 intake + RFC 7592 management (no HTTP yet).**
*Rationale:* with storage and resolver in place, protocol modules can be built and unit-tested in isolation; this is where the highest density of pitfall-prevention tests lands.
*Delivers:* `Lockspire.Protocol.{InitialAccessToken, RegistrationAccessToken, Registration, RegistrationManagement}`, `Repository.{register_self_service_client, rotate_registration_access_token, delete_self_registered_client, redeem_initial_access_token}`.
*Avoids pitfalls:* 2, 4, 5, 6, 7, 8, 14, 15.
*Research flag:* light — re-read RFC 7591 §3.2.2 and RFC 7592 §2.1 against rfc-editor.org during planning.

**Phase 27: HTTP surface — controllers, routes, and JSON views.**
*Rationale:* with protocol modules unit-tested, HTTP adapters are thin; integration-test-heavy phase.
*Delivers:* `Lockspire.Web.{Registration, RegistrationManagement}Controller`, `Lockspire.Web.RegistrationJSON`, routes in `Lockspire.Web.Router`, `Plug.Conn` integration tests for happy + every §3.2.2 error code, SSRF protections wired into validator hooks.
*Avoids pitfall:* 3 (SSRF).
*Research flag:* none — direct mirror of `PushedAuthorizationRequestController`.

**Phase 28: Operator admin UI — policy page, IAT mint/revoke, provenance, RAT rotate.**
*Rationale:* "looks done but isn't" risk peaks here — provenance must be visible, IATs revocable, RAT rotation operator-attributed.
*Delivers:* `PoliciesLive.Dcr` (mirrors PAR/JAR), `IatLive.{Index, New}` (issue with copy-once display, list, revoke), extended `ClientsLive.{Index, Show}` (provenance column + filter; "Self-registered client" panel; `:rotate_registration_access_token` live_action), `Admin.InitialAccessTokens`, operator-attributed audit emission.
*Avoids pitfalls:* 10, 12, 13, 15.
*Research flag:* none — direct mirror of v1.4 JAR LiveView.

**Phase 29: Truthful discovery, SECURITY/docs, end-to-end closure.**
*Rationale:* shipped slice must be advertised honestly and described in SECURITY/docs; same shape as v1.2/v1.3/v1.4 closures.
*Delivers:* `Discovery` extension with three-mode contract test, SECURITY.md + `docs/operator-admin.md` updates with explicit non-goals and host-side rate-limit seam, `docs/dynamic-registration.md` added to `mix.exs` `extras`, end-to-end DCR scenario test, milestone closure record + traceability matrix.
*Avoids pitfall:* 9 (discovery untruth).
*Research flag:* none.

**Phase ordering rationale:** Storage → resolver → pipeline → HTTP → UI → discovery is the dependency-respecting order both `STACK.md` and `ARCHITECTURE.md` explicitly recommend. The resolver belongs in Phase 25 (with storage) so the migration and the type that reads it land together — no half-state. The pipeline (Phase 26) is HTTP-free so protocol modules can be unit-tested without `Plug.Conn` fixtures (same discipline as PAR's `Lockspire.Protocol.Par`). Discovery is last because it must reflect the *actual* policy shape and *actual* mounted routes — advertising before the controller exists is the "discovery lies" pitfall the milestone is trying to prevent. Provenance/audit fields must be in Phase 25 even though their UI is Phase 28, because audit must emit from Phase 26 onward.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Hex.pm versions verified same day; RFC surface authoritative; integration points cross-checked against repo. The "no new deps" conclusion is robust — every alternative (boruta_auth, ex_json_schema, jsv, argon2_elixir, hammer) was rejected with explicit reasoning. |
| Features | HIGH | RFC 7591/7592 verified; competitor matrix covers Auth0, Keycloak, Hydra, node-oidc-provider, Curity. MEDIUM on operator-policy granularity (judgement call shaped by Curity's template-client model). |
| Architecture | HIGH | Existing-codebase observations are direct (file paths, module structure verified against repo); RFC 7591/7592 verified. Build-order is dependency-respecting and explicit. |
| Pitfalls | HIGH | RFC sources authoritative; competitor pitfall sources diverse and recent (2024–2026). Lockspire-specific pitfalls (Pitfall 10 `actor_from_attrs/1` default; Pitfall 7 discovery-vs-typespec gap) are repository-truth-grounded. |

**Overall confidence:** HIGH

## Open Questions for the Requirements Pass

- **Default `registration_policy` mode:** three-mode enum (`:disabled | :initial_access_token | :open`) or two-state plus IAT-required boolean? **Recommended:** three-mode enum — cleaner discovery contract test, matches Hydra/Keycloak/Curity.
- **`DELETE /register/:client_id` semantics:** RFC 7592 §2.3 says MAY allow; research is unambiguous on soft-disable. **Recommended:** soft-disable with `disabled_by: "dcr_self_delete"`; hard-delete remains operator-only. State explicitly in requirements so it cannot be reinterpreted.
- **IAT `policy_overrides` in v1.5 or v1.6:** resolver shape is composable (can ship global-only and add IAT later). FEATURES.md lists per-IAT overrides as P2; PITFALLS.md Pitfall 15 argues IATs without per-IAT constraints are leakage-equivalent to admin tokens. **Recommended:** ship the schema column (`policy_overrides jsonb`) and three-way fan-in resolver in v1.5; UI surface as P2 (deferrable). Avoids v1.6 migration rush.
- **`jwks_uri` outbound fetch in v1.5 or v1.6:** FEATURES.md P3; PITFALLS.md Pitfall 3 is hard SSRF concern. **Recommended:** v1.5 accepts inline `jwks` only; reject `jwks_uri` with `invalid_client_metadata` and explicit "not supported in this slice" reason. Schema field stays nullable for future Oban-backed fetch path.
- **Rate limiting:** all three research files agree v1.5 should not add `hammer`. **Recommended:** the requirements doc must make explicit that `:open` mode is technically representable but documented in SECURITY.md as requiring host-app-side rate limiting before going live.

## Sources

**Primary (HIGH confidence):** RFC 7591 + 7592 verified against rfc-editor.org / datatracker.ietf.org; OpenID Connect DCR 1.0; OIDC Core 1.0 §5; Hex.pm verifications 2026-04-25 (argon2_elixir 4.1.3, hammer 7.3.0, jsv 0.18.3, ex_json_schema 0.11.2); internal repo files cross-checked file-by-file (`mix.exs`, `lib/lockspire/storage/ecto/client_record.ex`, `lib/lockspire/clients.ex`, `lib/lockspire/security/policy.ex`, `lib/lockspire/admin/clients.ex`, `lib/lockspire/admin/server_policy.ex`, `lib/lockspire/protocol/discovery.ex`, `lib/lockspire/protocol/{par_policy,jar_policy}.ex`, `lib/lockspire/web/router.ex`, `lib/lockspire/web/controllers/pushed_authorization_request_controller.ex`, `priv/repo/migrations/20260425221000_add_jar_policy_to_server_policies.exs`, `.planning/PROJECT.md`, `.planning/milestones/v1.3-REQUIREMENTS.md`).

**Secondary (MEDIUM confidence):** Auth0, Keycloak, Ory Hydra, node-oidc-provider, Curity, PingAM, Connect2id, Duende IdentityServer, OpenIddict; Descope, WorkOS, ScaleKit DCR primers; issue trackers (Keycloak #19513, #46037; Hydra #1616, #4060; OpenIddict #2404; Coder #20370; fastmcp #2460; MCP inspector #752; vscode #257415; cursor #110638).

**Tertiary (LOW confidence):** none flagged — no decisions in this summary rest on single-source claims.

---
*Research completed: 2026-04-25*
*Continuation phase numbering: starts at Phase 25 (v1.4 closed at Phase 24)*
