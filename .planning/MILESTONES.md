# Milestones

## v1.27 Phoenix Resource Server Token Acceptance (Shipped: 2026-06-03)

**Phases completed:** 6 phases, 24 plans, 45 tasks

**Key accomplishments:**

- BIND-03 runtime fail-closed guard: binding_verified breadcrumb (D-01/D-02/D-03) closes RFC 9449 §7.2 sender-constraint bypass with 403 + binding-derived challenge, proven by 25 passing plug-unit tests
- BIND-03 contract test added asserting all four RECIPE-01 pipeline sites order VerifyToken→EnforceSenderConstraints→RequireToken via byte-offset comparison; A1 assumption confirmed: VerifyToken accepts list-valued aud (the signer's wire shape) without mitigation needed.
- BIND-01 (DPoP) + BIND-02 (mTLS) signer-minted at+jwt e2e proofs: AccessTokenSigner.issue/3 cnf carry-through survives the VerifyToken->EnforceSenderConstraints->RequireToken pipeline through the nonce-retry dance to 200, confirming Wave 1's binding_verified breadcrumb is wired end-to-end
- Replaced bare `audience: "billing-api"` with absolute URI `audience: "https://billing.acme-ledger.test"` byte-identically across all four RECIPE-01 hash-locked sites, closing the `valid_resource_uri?` rejection and audience-confusion vulnerability classes
- Wired resource=https://billing.acme-ledger.test into both the /authorize and /token requests via a single module-level constant, and added the mandatory GET /api/billing/summary Bearer-token round-trip asserting HTTP 200 — closing the half-proof gap and satisfying DEMO-01 and DEMO-02
- `[:lockspire, :rs, :token_format]` emitted via direct `:telemetry.execute/3` at two `VerifyToken` sites — `:jwt` (claims-sourced metadata) on verified `at+jwt`, literal `:"opaque-rejected"` (all-nil metadata) on the opaque-reject branch — proven by a TDD RED→GREEN capture test.
- Read-only `mix lockspire.doctor token_format` diagnostic that reports each client's effective access-token format using the signer's exact precedence and flags every `access_token_format: nil` client whose inherited default flipped to `:jwt`.
- Append 14 new D-06/D-07/D-09 substrings to the Phase 92 substring-contract helpers, landing the RED failure on `release_readiness_contract_test.exs:642` that Plans 02 and 03 will turn GREEN by editing the docs.
- Rewrote `docs/protect-phoenix-api-routes.md` with the D-06 contract sentence as the verbatim lead, the D-07 forward-reference caveat preceded by an HTML-comment sweep marker, BEGIN/END markers wrapping the canonical pipeline fenced block, and the two D-15 secondary fenced blocks collapsed to reference-to-canonical prose — making this the single authoritative protected-route page and the first of four canonical-block carrier sites for v1.27.
- Landed the v1.27 public-contract non-goals as a first-class H2 subsection in docs/supported-surface.md, and converted the saas-adoption-recipe pipeline restatement into a cross-link to the canonical contract page — closing the silent fifth-restatement drift class without touching any Phase 92 substring.
- Mirrored the Plan 02 canonical pipeline-declaration bytes into the three remaining RECIPE-01 sites — `examples/adoption_demo/lib/adoption_demo_web/router.ex` (raw Elixir, 2-space module-body indent), `priv/templates/lockspire.install/router.ex` (commented-out Elixir inside a heredoc, 4-space heredoc-interior indent, per D-10), and `scripts/demo/adoption_smoke.py` (Python-comment carrier inside `exercise_authorization_code`, 4-space function-body indent + `# ` per-line prefix per D-03 + D-14) — such that all four carrier files now extract to byte-identical canonical bytes (SHA-256 `c79c19d107294b9c56c071d4fc6004eae0735365d4783d4f4bb2216664e87172`) after D-02 normalization, completing the four-site ground truth that Plan 05's `release_readiness_contract_test` hash-compare clause will enforce.
- Closed the RECIPE-01 drift loop. `test/lockspire/release_readiness_contract_test.exs` now carries three new clauses that pairwise-compare SHA-256 hashes of the canonical pipeline interior across all four RECIPE-01 carrier sites, refute three-plug-name restatement in `docs/saas-adoption-recipe.md`, and refute within-file pipeline restatement in `docs/protect-phoenix-api-routes.md`. All three negative-path probes (drift, sanity-guard, EEx-tag) were executed-and-reverted with verbatim failure-message capture per WARNING #6 enforcement. `mix ci` exits 0 at phase end.
- Front-edge structural opaque-token rejection in `Lockspire.Plug.VerifyToken.verify_token/3`: any token that does not split into exactly three non-empty Base64URL segments by `.` short-circuits with a structured `:opaque_token_not_accepted` error and the RFC 6750 wire response `WWW-Authenticate: Bearer realm="Lockspire", error="invalid_token", error_description="opaque tokens not accepted on this route"`, ending the silent `:malformed` lumping that previously swallowed opaque tokens at `extract_kid/1`'s rescue clause.
- Add `enforce_audience: [type: :boolean, default: false]` to `Lockspire.Plug.VerifyToken`'s NimbleOptions schema with a new `init/1` raise when `enforce_audience: true` is set and neither `:audience` nor `:audiences` is supplied; propagate `enforce_audience: true` byte-identically across all four RECIPE-01 canonical-pipeline sites; and add a new `release_readiness_contract_test` clause that asserts each canonical block carries a non-empty `audience: "..."` on its `Lockspire.Plug.VerifyToken,` declaration. Closes VERIFIER-06 with both OR-clause mechanisms shipped for defense-in-depth.
- A single new `validate_rfc9068_compliance/2` step inside `Lockspire.Plug.VerifyToken` enforces the five RFC 9068 / RFC 8725 compliance rules (typ=at+jwt, iss=Lockspire.Config.issuer!/0, exp positive integer, iat positive integer, sub non-empty string) between `JOSE.JWT.verify_strict/3` success and `time_claims_valid?/1` / `apply_restrictions/2`. Each failure emits a distinct atom `reason_code` (`:invalid_typ`, `:invalid_issuer`, `:missing_exp`, `:missing_iat`, `:missing_sub`) through the D-04 structured error map shape with a distinct `error_description` naming the violated RFC clause. The verifier's `typ` comparison is intentionally case-insensitive and strips `application/` (D-03's forward-compatibility margin for Phase 99's signer extraction); a code comment names this asymmetry against the issuance-side `Lockspire.Protocol.DPoP.check_typ/1` precedent. The obsolete `# Missing exp is currently treated as valid` comment at line 366 is deleted as part of this plan.
- Add `challenge_for/2` to `Lockspire.Plug.VerifyToken` implementing the D-05 four-row mapping (cnf.jkt → :dpop, cnf.x5t#S256-only → :bearer, no-cnf + DPoP scheme → :dpop, otherwise → :bearer); replace the four hard-coded `challenge: :bearer` sites in error helpers (`invalid_audience_error/3`, `insufficient_scope_error/2`, `rfc9068_error/2` × 5 clauses, `opaque_token_error/1`) with derived values that thread through `verify_signature_and_claims/3` → `validate_rfc9068_compliance/3` → check helpers, plus `apply_restrictions/2` reading the scheme off the in-flight AccessToken struct; replace the hard-coded `challenge: :bearer` in `require_token.ex` `normalize_insufficient_scope_error/1` at line 113 with `Map.get(error, :challenge, :bearer)`; restructure `handle_insufficient_scope/2` to mirror `handle_invalid_token/2`'s challenge-aware routing so DPoP-bound scope failures emit `WWW-Authenticate: DPoP realm="..." error="insufficient_scope" ... algs="..."` via the existing `ProtectedResourceChallenge.put_dpop_challenge/2` (D-06 wire-up — no changes to that file). EnforceSenderConstraints is NOT modified.
- Runtime-editable server-wide `ServerPolicy.access_token_format` defaulting to `:jwt` plus a nullable per-client `Client.access_token_format` override, backed by a dual-table `:text` migration and `Admin.ServerPolicy.put_access_token_format/1`.
- Shared RFC 9068 `at+jwt` signer with one-place format resolution, list-vs-string `aud` carve-out, and `cnf` carry-through — assembled from the rfc8693 signing block and the SecurityProfile precedence shape, shipped TDD-first.
- The AC/device/CIBA mint seam now issues access tokens through `AccessTokenSigner.issue/3` (re-pointing the persisted hash to the signer's hash), and the device + CIBA grant paths gained net-new `resource`→`aud` validation so `resource=` yields `aud=[resource]` and absent `resource=` yields `aud=[client_id]`.
- Routed the refresh rotation path and the RFC 8693 token-exchange path through the shared `AccessTokenSigner`, fixed the refresh `sub` (rotated token had `account_id: nil`), and deleted the duplicated `at+jwt` signing block from `rfc8693_exchange.ex` so no signing logic survives outside the shared module (SC5).
- Per-client access_token_format override (inherit|jwt|opaque) on the admin client-detail edit form with a JWT-vs-opaque doclink, inherit->nil normalize plumbing, and global/override/effective SHOW rows with signer-aligned effective resolution.

---

## v1.26 Host Integration & Operator Boundary Hardening (Shipped + archived: 2026-05-27)

**Phases completed:** **3** (**94-96**), **3** plans, **5** requirements closed.

**Package posture:** `lockspire 1.2.0` now has a clearer first Phoenix SaaS adoption path: generated hosts can mount Lockspire's admin surface behind host-owned operator auth, wire account/claims resolution without broadening Lockspire's host seam, create a first client with copy-once secret guidance, and follow a compact SaaS adoption recipe.

**Key accomplishments:**

- Added `Lockspire.Web.AdminRouter` as the bounded admin-only router for hosts that want `/lockspire/admin` protected by their own operator-auth pipeline.
- Updated generated router and account-resolver scaffolding so host account lookup, stable subject claims, tenant policy, product authorization, and Sigra-specific wiring stay explicitly host-owned.
- Improved first-client CLI output with token endpoint auth truth and concrete next steps for proving authorization-code + PKCE.
- Added adopter-facing docs and release-readiness assertions that pin the host-owned account/operator boundary.

**Pre-close audit:** Formal milestone audit: [`.planning/milestones/v1.26-MILESTONE-AUDIT.md`](milestones/v1.26-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.26-ROADMAP.md`, `milestones/v1.26-REQUIREMENTS.md`, `milestones/v1.26-MILESTONE-AUDIT.md` · **Package release:** `lockspire 1.2.0`

---

## v1.25 Support-Burden Reduction (Shipped + archived: 2026-05-26)

**Phases completed:** **3** (**91-93**), **9** plans, **9** requirements closed.

**Package posture:** `lockspire 1.0.0` or higher now has one coherent advanced-setup support contract for remote `jwks_uri`, mTLS setup, logout propagation, and the shipped Phoenix protected-route pipeline, backed by repo-native proof and explicit support boundaries.

**Key accomplishments:**

- Added one shared remote-JWKS incident taxonomy plus a bounded-reactive rollover truth model for `private_key_jwt` and JARM consumers.
- Added `mix lockspire.doctor remote-jwks` and an admin Remote JWKS summary so runtime incidents can be diagnosed without source-diving and without widening install-time verification.
- Tightened the canonical mTLS, protected-route, and logout guidance so Lockspire-owned behavior versus host-owned or infrastructure-owned behavior is explicit and internally consistent.
- Added semantic release-contract proof and representative runtime regressions so advanced-setup docs, diagnostics, and behavior fail loudly if they drift apart.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.25-MILESTONE-AUDIT.md`](milestones/v1.25-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.25-ROADMAP.md`, `milestones/v1.25-REQUIREMENTS.md`, `milestones/v1.25-MILESTONE-AUDIT.md` · **Git tag:** `v1.25`

---

## v1.24 client_secret_jwt (Shipped + archived: 2026-05-25)

**Phases completed:** **3** (**88-90**), **9** plans, **7** requirements closed.

**Package posture:** `lockspire 1.0.0` or higher now supports a narrow `client_secret_jwt` direct-client authentication slice on shipped Lockspire-owned endpoints without widening Lockspire's higher-trust support claims.

**Key accomplishments:**

- Added shared direct-client JWT routing that resolves the attempted JWT method from stored client auth truth instead of implicitly treating every JWT assertion as `private_key_jwt`.
- Added sealed verifier material and strict HS256-only verification so `client_secret_jwt` can work without weakening the existing hashed-secret posture.
- Added repo-native proof for valid and invalid `client_secret_jwt` behavior across representative shipped direct-client surfaces, including replay, audience, algorithm, method-mismatch, and FAPI-denial cases.
- Aligned DCR, RFC 7592, discovery, admin/operator surfaces, support docs, and release-contract tests around one truthful narrow support boundary.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.24-MILESTONE-AUDIT.md`](milestones/v1.24-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.24-ROADMAP.md`, `milestones/v1.24-REQUIREMENTS.md`, `milestones/v1.24-MILESTONE-AUDIT.md` · **Git tag:** `v1.24`

---

## v1.23 DCR Logout Metadata (Shipped + archived: 2026-05-24)

**Phases completed:** **3** (**85-87**), **9** plans, **10** requirements closed.

**Package posture:** `lockspire 1.0.0` or higher now lets eligible self-service clients manage the existing logout propagation metadata through DCR and RFC 7592 without widening Lockspire's current logout support boundary.

**Key accomplishments:**

- Added DCR create-time validation, typed persistence, and truthful readback for `backchannel_logout_*` and `frontchannel_logout_*` metadata.
- Added RFC 7592 full-replace update semantics for the four logout metadata fields, including clear-on-omit behavior.
- Proved rotated registration access token truth, provenance retention, audit continuity, and negative-path contracts across protocol and controller seams.
- Aligned supported-surface, DCR lifecycle, operator, and maintainer release docs to one canonical logout support contract.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.23-MILESTONE-AUDIT.md`](milestones/v1.23-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.23-ROADMAP.md`, `milestones/v1.23-REQUIREMENTS.md`, `milestones/v1.23-MILESTONE-AUDIT.md` · **Git tag:** `v1.23`

---

## v1.21 Resource Server (API Protection) (Shipped + archived: 2026-05-23)

**Phases completed:** **3** (**79-81**), **9** plans, **10** requirements closed.

**Package posture:** `lockspire 1.0.0` or higher now includes first-class Phoenix API route protection for Lockspire-issued bearer, DPoP-bound, and MTLS-bound access tokens.

**Key accomplishments:**

- Added `Lockspire.Plug.VerifyToken` plus `%Lockspire.AccessToken{}` and `Lockspire.KeyCache` for fast, local JWT validation against Lockspire-issued keys.
- Added `Lockspire.Plug.EnforceSenderConstraints` so protected routes can enforce DPoP and MTLS confirmation claims without taking over the HTTP boundary.
- Kept `Lockspire.Plug.RequireToken` as the single strict transport boundary, with truthful `401 invalid_token` vs `403 insufficient_scope` semantics.
- Published and contract-tested the canonical Phoenix protected-route guide for `VerifyToken -> EnforceSenderConstraints -> RequireToken`.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.21-MILESTONE-AUDIT.md`](milestones/v1.21-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.21-ROADMAP.md`, `milestones/v1.21-REQUIREMENTS.md`, `milestones/v1.21-CONTEXT.md`, `milestones/v1.21-MILESTONE-AUDIT.md` · **Git tag:** `v1.21`

---

## v1.20 Mutual TLS (RFC 8705) (Shipped + archived: 2026-05-23)

**Phases completed:** **4** (**75-78**)

**Goal:** Implement Mutual TLS for client authentication and sender-constrained tokens, closing the remaining high-leverage trust gap for high-security domain integrations.

**Key capabilities:**

- Explicit certificate extraction via `Lockspire.MTLS.Extractor` behaviour (Cowboy native and Proxy headers).
- `tls_client_auth` and `self_signed_tls_client_auth` client authentication.
- `x5t#S256` certificate-bound access tokens.
- `mtls_endpoint_aliases` discovery metadata.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.20-MILESTONE-AUDIT.md`](milestones/v1.20-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.20-ROADMAP.md`, `milestones/v1.20-REQUIREMENTS.md`, `milestones/v1.20-MILESTONE-AUDIT.md` · **Git tag:** `v1.20`

---

## v1.19 FAPI 2.0 Message Signing (Shipped + archived: 2026-05-21)

**Phases completed:** **4** (**71-74**), **13** plans, **5** requirements closed.

**Package posture:** `lockspire 1.0.0` or higher now includes full support for the OpenID Connect FAPI 2.0 Message Signing Profile.

**Key accomplishments:**

- Implemented JARM (JWT Secured Authorization Response Mode) and Encrypted JARM.
- Implemented JWT introspection responses.
- Enforced strict FAPI 2.0 Message Signing security profile across all runtime flows.
- Provided canonical readiness signals and operator remediations in the LiveView admin interfaces.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.19-MILESTONE-AUDIT.md`](milestones/v1.19-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.19-ROADMAP.md`, `milestones/v1.19-REQUIREMENTS.md`, `milestones/v1.19-MILESTONE-AUDIT.md` · **Git tag:** `v1.19`

---

## v1.18 Post-Release Execution (Shipped + archived: 2026-05-07)

**Phases completed:** **1** (**70**), **1** plan, **1** requirement closed.

**Package posture:** Lockspire maintains its `1.0.0` GA release state with the addition of automated repo-native FAPI 2.0 conformance testing.

**Key accomplishments:**

- Integrated the official OpenID Foundation FAPI 2.0 Conformance Suite into the automated CI pipeline.
- Established a local testing lane for maintainers to run the conformance suite.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.18-MILESTONE-AUDIT.md`](milestones/v1.18-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.18-ROADMAP.md`, `milestones/v1.18-REQUIREMENTS.md`, `milestones/v1.18-MILESTONE-AUDIT.md` · **Git tag:** `v1.18`

---

## v1.17 1.0.0 GA Release Readiness (Shipped + archived: 2026-05-07)

**Phases completed:** **3** (**67-69**), **3** plans, **7** requirements closed.

**Package posture:** Lockspire 1.0.0 is officially released to Hex, with all execution verifiable.

**Key accomplishments:**

- Completed public release verification.
- Documented explicit durable records.

**Pre-close audit:** `audit-open` had 2 acknowledged deferred items. Formal milestone audit: [`.planning/milestones/v1.17-MILESTONE-AUDIT.md`](milestones/v1.17-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.17-ROADMAP.md`, `milestones/v1.17-REQUIREMENTS.md`, `milestones/v1.17-MILESTONE-AUDIT.md` · **Git tag:** `v1.17`

---

## v1.16 Embedded Adoption Hardening & Sigra Golden Path (Shipped + archived: 2026-05-07)

**Phases completed:** **4** (**63-66**), **13** plans, **11** requirements closed.

**Package posture:** `lockspire 1.0.0` now has one coherent repo-truth story across package metadata, changelog posture, protected release wiring, supported-surface docs, and release-readiness contract tests.

**Key accomplishments:**

- Added one canonical embedded install path with explicit Lockspire-managed versus host-owned seams, plus a manifest-backed `mix lockspire.upgrade`.
- Added `mix lockspire.verify` so host teams can catch router wiring, seam, config, and migration mistakes before runtime drift becomes support debt.
- Proved the Sigra companion path end to end through generated-host code, including unauthenticated `/authorize`, login bounce, interaction resume, consent, token exchange, and JWKS.
- Reconciled README, SECURITY, maintainer docs, changelog posture, package metadata, and release workflow wording around a single 1.0.0 support story.
- Retired the old external-suite conformance lane as historical non-claim audit context and anchored current trust claims to repo-native strictness and release-readiness proof.

**Pre-close audit:** `audit-open` had 2 acknowledged deferred items: historical `Phase 37: 37-VERIFICATION.md [gaps_found]` preserved as non-authoritative audit context, and seed `SEED-001-cut-next-real-release [dormant]` kept for the next milestone decision. Formal milestone audit: [`.planning/milestones/v1.16-MILESTONE-AUDIT.md`](milestones/v1.16-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.16-ROADMAP.md`, `milestones/v1.16-REQUIREMENTS.md`, `milestones/v1.16-MILESTONE-AUDIT.md` · **Git tag:** `v1.16`

---

## v1.14 Advanced Authorization & Resource Targetting (Shipped + archived: 2026-05-06)

**Phases completed:** **5** (**54-58**), **12** plans, **12** requirements closed.

**Package posture:** `lockspire 0.2.0` remains preview at archive time, but the shipped surface now includes OAuth 2.0 Resource Indicators (RFC 8707) and Rich Authorization Requests (RFC 9396).

**Key accomplishments:**

- Added Resource Indicators validation and audience downscoping across authorization-code and refresh-token exchanges.
- Added `authorization_details` intake on `/par` and `/authorize`, including durable PAR and interaction persistence.
- Added host-owned RAR validator behaviors, normalization, fingerprinting, durable consent-grant storage, and token-to-grant linkage.
- Added grant-backed RAR introspection, structural consent-surface proof, and narrow FAPI/PAR regression coverage.
- Published truthful discovery metadata and an executable host-owned RAR consent guide pinned by release-contract tests.

**Pre-close audit:** `audit-open` had 1 acknowledged deferred verification gap (`Phase 37: 37-VERIFICATION.md [gaps_found]`, recorded in `STATE.md`). Formal milestone audit: [`.planning/milestones/v1.14-MILESTONE-AUDIT.md`](milestones/v1.14-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.14-ROADMAP.md`, `milestones/v1.14-REQUIREMENTS.md`, `milestones/v1.14-MILESTONE-AUDIT.md` · **Git tag:** `v1.14`

---

## v1.13 OpenID Connect CIBA (Shipped + archived: 2026-05-05)

**Phases completed:** **3** (**51-53**), **8** plans, **7** requirements closed.

**Package posture:** `lockspire 1.0.0` or higher now includes full support for the OpenID Connect Client-Initiated Backchannel Authentication Flow (CIBA).

**Key accomplishments:**

- Implemented the `/bc-authorize` endpoint with robust validation and discovery metadata.
- Added the CIBA token grant type to `/token` with durable polling state enforcement.
- Support for Poll, Ping, and Push delivery modes using Oban for reliable, retriable webhook delivery.
- Established the `Lockspire.Host` Behaviour for delegating out-of-band notifications and user consent to the host application.
- Verified all flows with a comprehensive integration test suite covering asynchronous lifecycle events and background delivery.

**Pre-close audit:** Handled by `$gsd-complete-milestone`.

**Archives:** `milestones/v1.13-ROADMAP.md`, `milestones/v1.13-REQUIREMENTS.md` · **Git tag:** `milestone/v1.13`

---

## v1.12 Token Exchange (RFC 8693) (Shipped + archived: 2026-05-05)

**Phases completed:** **3** (**48-50**), **7** plans, **5** requirements closed.

**Package posture:** `lockspire 1.0.0` or higher now includes OAuth 2.0 Token Exchange for microservice patterns (Delegation and Impersonation).

**Key accomplishments:**

- Added parsing and durable storage of RFC 8693 Token Exchange requests, tracking token lineage via `grant_id`.
- Introduced the `Lockspire.TokenExchangeValidator` behaviour to give host apps explicit policy control over which clients and actors are allowed to perform exchanges.
- Enforced domain-specific delegation boundaries via `max_delegation_depth` configuration to prevent arbitrary recursive token bloat.
- Generated and verified `act` claims for nested delegation chains when `actor_token` is present.

**Pre-close audit:** Handled by `$gsd-complete-milestone`.

**Archives:** `milestones/v1.12-ROADMAP.md`, `milestones/v1.12-REQUIREMENTS.md` · **Git tag:** `v1.12`

---

## v1.11 1.0 GA Release — The Stabilization Epoch (Shipped + archived: 2026-05-05)

**Phases completed:** **4** (**44-47**), **6** requirements closed.

**Package posture:** Lockspire transitions from preview to 1.0 GA release. `release-please` is configured to publish `1.0.0`.

**Key accomplishments:**

- Fixed Dialyzer and strict typing constraints across the codebase.
- Standardized operator telemetry and LiveView seams.
- Completed comprehensive ExDoc `@moduledoc` and `@doc` coverage.
- Configured 1.0.0 GA posture in Release Please and scrubbed preview documentation.
- Project CI passes all `credo`, `dialyzer`, and `sobelow` checks.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.11-MILESTONE-AUDIT.md`](milestones/v1.11-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.11-ROADMAP.md`, `milestones/v1.11-REQUIREMENTS.md`, `milestones/v1.11-MILESTONE-AUDIT.md` · **Git tag:** `v1.11`

---

## v1.10 FAPI 2.0 Security Profile (Shipped + archived: 2026-05-03)

**Phases completed:** **3** (**41-43**), **18** plans, **6** requirements closed.

**Package posture:** `lockspire` now includes a FAPI 2.0 strict mode. When enabled, requests without PAR, without DPoP, or lacking compliant cryptography are strictly rejected.

**Key accomplishments:**

- Added `security_profile: :fapi_2_0_security` operator option (global and per-client).
- Implemented `FAPI20EnforcerPlug` boundary for zero-tolerance PAR and DPoP checking.
- Locked down cryptography to strictly `ES256` and `PS256` under the FAPI profile.
- Strict RFC 9207 `iss` emission on all authorization responses.
- Truthful discovery and security documentation reflecting the FAPI 2.0 claims.
- Provided `mix lockspire.oidf_conformance` preflight tooling for formal conformance suite execution.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.10-MILESTONE-AUDIT.md`](milestones/v1.10-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.10-ROADMAP.md`, `milestones/v1.10-REQUIREMENTS.md`, `milestones/v1.10-MILESTONE-AUDIT.md` · **Git tag:** `v1.10`

---

## v1.9 JAR Decryption (JWE Support) (Shipped + archived: 2026-04-29)

**Phases completed:** **1** (**40**), **0** plans, **2** requirements closed.

**Package posture:** `lockspire 0.2.0` remains preview. The shipped surface now includes nested JWE support for request objects.

**Key accomplishments:**

- Added RSA/EC encryption keypairs (`enc`) to `Storage.KeyStore` and JWKS endpoints.
- Implemented nested JWT validation (Sign-then-Encrypt) in `Protocol.Jar` using `JOSE.JWE` and `JOSE.JWS`.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.9-MILESTONE-AUDIT.md`](milestones/v1.9-MILESTONE-AUDIT.md) (`passed`).

**Archives:** `milestones/v1.9-ROADMAP.md`, `milestones/v1.9-REQUIREMENTS.md`, `milestones/v1.9-MILESTONE-AUDIT.md` · **Git tag:** `v1.9`

---

## v1.8 Session Management & Conformance (Shipped + archived: 2026-04-29)

**Phases completed:** **3** (**37-39**), **14** plans, **8** requirements closed (CONF-04 deferred).

**Package posture:** `lockspire 0.2.0` remains preview. The shipped surface now includes full RP-Initiated logout, automated back-channel and front-channel logout propagation, and strict protocol validation for auth_time and max_age.

**Key accomplishments:**

- Added strict protocol validation for integers and URL match exactness.
- EndSession endpoint implementation with generated host seams for RP-initiated logout.
- Back-channel logout implementation using Oban and HTTP request propagation.
- Front-channel logout rendering of invisible iframes based on relying party registration metadata.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.8-MILESTONE-AUDIT.md`](milestones/v1.8-MILESTONE-AUDIT.md) (`passed` with CONF-04 deferred).

**Archives:** `milestones/v1.8-ROADMAP.md`, `milestones/v1.8-REQUIREMENTS.md`, `milestones/v1.8-MILESTONE-AUDIT.md` · **Git tag:** `v1.8`

---

## v1.7 DPoP Core for Public and CLI Clients (Shipped: 2026-04-28)

**Phases completed:** **4** (**33-36**), **12** plans, **14** requirements closed.

**Package posture:** `lockspire 0.2.0` remains preview at archive time, but the shipped surface now includes the full repo-proven DPoP core on top of the earlier device-flow, PAR, JAR, and DCR work.

**Key accomplishments:**

- Added DPoP proof validation, replay protection, and thumbprint derivation for token binding.
- Implemented DPoP-aware authorization-code, refresh-token, and device-code exchanges without breaking the bearer default.
- Added DPoP enforcement on the Lockspire-owned `userinfo` endpoint and aligned discovery, docs, and operator/DCR configurations to the shipped slice.
- End-to-end proof and introspection behavior validate the truthful support claim.

**Pre-close audit:** Formal milestone archive handoff handled by `$gsd-complete-milestone`.

**Archives:** `milestones/v1.7-ROADMAP.md`, `milestones/v1.7-REQUIREMENTS.md` · **Git tag:** `v1.7`

---

## v1.6 Device Authorization Grant (Shipped + archived: 2026-04-28)

**Phases completed:** **3** (**30-32**), **10** plans, **9** requirements closed.

**Package posture:** `lockspire 0.2.0` remains preview at archive time, but the shipped surface now includes the full repo-proven Device Authorization Grant wedge on top of the earlier PAR, JAR, and DCR work.

**Key accomplishments:**

- Added the full Device Authorization Grant flow: mounted `POST /device/code`, durable hashed storage, Base20 user codes, and strict TTLs.
- Generated and documented the host-owned `/verify` seam with explicit anti-phishing behavior, CSRF-protected forms, and rate-limit guidance that stays on the host side.
- Added durable poll pacing, RFC 8628 continuation outcomes on `/token`, truthful discovery metadata, and generated-host end-to-end proof for `/device/code -> /verify -> /token`.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`.planning/milestones/v1.6-MILESTONE-AUDIT.md`](milestones/v1.6-MILESTONE-AUDIT.md) (`passed` with no requirement, integration, flow, or Nyquist gaps).

**Archives:** `milestones/v1.6-ROADMAP.md`, `milestones/v1.6-REQUIREMENTS.md`, `milestones/v1.6-MILESTONE-AUDIT.md` · **Git tag:** `v1.6`

---

## v1.5 Dynamic Client Registration (Shipped + archived: 2026-04-27)

**Phases completed:** **5** (**25-29**), **27** requirements mapped and closed.

**Key accomplishments:**

- Added full RFC 7591/7592 dynamic client registration lifecycle.
- Implemented operator policy controls and Initial Access Tokens.
- Truthful discovery and security documentation.

## v1.4 JAR and Request Objects (Shipped + archived: 2026-04-26)

**Phases completed:** **4** (**21-24**), **18** plans, **5** shipped requirements (**JAR-01**, **JAR-02**, **JAR-03**, **JAR-05**, **JAR-06**); **JAR-04** remains deferred.

**Package posture:** `lockspire 0.2.0` remains preview at archive time, but the shipped surface now includes the verified JAR request-object slice on top of the earlier PAR and PAR-policy work.

**Key accomplishments:**

- Added signed JAR request-object support with client-key signature validation and RFC 9101 claim checks.
- Integrated request objects into the existing authorization-code, PAR, and browser-boundary flow without widening the embedded-library shape.
- Published truthful JAR discovery and operator policy controls for the shipped request-object slice.
- Closed the milestone with explicit verification, validation, and traceability evidence while preserving JAR-04 as deferred.

**Pre-close audit:** `audit-open` clear. Formal milestone validation: [`.planning/phases/24-verification-and-milestone-closure/24-VALIDATION.md`](phases/24-verification-and-milestone-closure/24-VALIDATION.md) (`passed` with JAR-04 deferred and no boundary drift).

**Archives:** `milestones/v1.4-ROADMAP.md`, `milestones/v1.4-REQUIREMENTS.md` · **Git tag:** `v1.4`

---

## v1.2 PAR Foundation (Shipped + archived: 2026-04-24)

**Phases completed:** **3** (**14-16**), **8** plans, **5** requirements (**PAR-01**-**PAR-04**, **RELS-04**)

**Package posture:** `lockspire 0.2.0` remains preview at archive time, but the shipped surface now includes the narrow PAR wedge and a checked-in Release Please path on a supported runtime.

**Key accomplishments:**

- Added durable hash-only PAR intake plus a mounted `POST /par` endpoint that reuses existing client-auth and validation seams.
- Extended `/authorize` to consume Lockspire-issued PAR references with expiry, client binding, replay resistance, and unchanged auth-code + PKCE semantics.
- Locked discovery, docs, SECURITY wording, and repo-truth contract tests to the exact shipped PAR slice.
- Closed `PAR-04` traceability and removed the deferred Release Please Node 20 runtime warning by moving to a repo-controlled Node 24 composite action.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`milestones/v1.2-MILESTONE-AUDIT.md`](milestones/v1.2-MILESTONE-AUDIT.md) (`passed` with no requirement, integration, flow, or Nyquist gaps).

**Automation note:** `gsd-sdk query milestone.complete` remains unreliable, so the close again used manual `milestones/v1.2-*` artifacts, `ROADMAP.md` collapse, and `git rm .planning/REQUIREMENTS.md`.

**Archives:** `milestones/v1.2-ROADMAP.md`, `milestones/v1.2-REQUIREMENTS.md`, `milestones/v1.2-MILESTONE-AUDIT.md` · **Git tag:** `v1.2`

---

## v1.1 Release Hardening (Shipped + archived: 2026-04-24)

**Phases completed:** **7** (**07-13**), **15** plans, **9** requirements (**GATE-01**-**GATE-03**, **RELS-01**-**RELS-03**, **POST-01**-**POST-03**)

**Package posture:** `lockspire 0.2.0` exists at archive time; planning milestone complete, but public product posture remains preview rather than `1.0`.

**Key accomplishments:**

- Repo-truth QA and contributor gate recovery closed the maintained `mix qa`/`mix ci` drift and backfilled formal gate verification.
- Trusted release hardening locked the checked-in publish policy, maintainer guide, protected environment proof, and approved canonical run evidence.
- Preview-support docs and contract tests now keep public claims bounded to the implemented embedded-provider wedge while leaving PAR as the next milestone candidate only.
- Final verification and ledger-reconciliation phases closed the remaining audit handoff gaps without reopening release implementation.

**Pre-close audit:** `audit-open` clear. Formal milestone audit: [`milestones/v1.1-MILESTONE-AUDIT.md`](milestones/v1.1-MILESTONE-AUDIT.md) (`tech_debt` for Nyquist completeness gaps and the `release-please-action` Node.js 20 warning only).

**Automation note:** `gsd-sdk query milestone.complete` failed again (`version required for phases archive`), so the close used manual `milestones/v1.1-*` artifacts, `ROADMAP.md` collapse, and `git rm .planning/REQUIREMENTS.md`.

**Archives:** `milestones/v1.1-ROADMAP.md`, `milestones/v1.1-REQUIREMENTS.md`, `milestones/v1.1-MILESTONE-AUDIT.md` · **Git tag:** `v1.1`

---

## v1.0 Embedded OAuth/OIDC Provider Foundation (Shipped + archived: 2026-04-23)

**Phases completed:** **6** (**01-06**), **25** plans

**Archives:** `milestones/v1.0-ROADMAP.md`, `milestones/v1.0-REQUIREMENTS.md` · **Git tag:** `milestone/v1.0`
