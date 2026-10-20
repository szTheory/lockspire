# Phase 162: Lifetime Semantics & Upgrade Contract - Context

**Gathered:** 2026-10-20 (assumptions mode; delegated research and adversarial review)
**Status:** Ready for planning
**Decision authority:** The user requested breadth/depth research with subagents, synthesis of one coherent recommendation bundle, and automatic adoption of those recommendations. These are selected decisions under that direction, not a claim of a separate confirmation response. No implementation has begun.

<domain>
## Phase Boundary

Resolve DCR-02, DCR-03 and DCR-04: one selected lifetime matrix, endpoint/error inventory, management recovery contract, and existing-host/custom-store deployment contract. Phase 162 produces the design and acceptance contract; Phase 163–166 implementation plans remain gated on its completed verification. Reuse the completed Phase 153 audit. Keep Lockspire embedded, host accounts/sessions/staff authorization host-owned, existing security defaults intact, and dependency trees flat.
</domain>

<decisions>
## Implementation Decisions

### Policy, time and independent lifecycles

- **D-01:** For each of app lifetime, client-secret lifetime and app-management-token lifetime, unset/nil and duration zero mean unlimited. A positive integer means seconds from the relevant issuance event. There is no invented finite default and zero never means immediate expiration. Configuration duration semantics are a Lockspire choice; RFC 7591's wire timestamp zero is a separate rule.

| Lifetime | nil / 0 | Positive N | Renewal event |
|---|---|---|---|
| DCR app | Unlimited | Registration time + N | None in this milestone; create a new registration after expiry |
| Shared secret | Unlimited | Secret issuance time + N | Explicit secret rotation |
| App management token | Unlimited | Token issuance time + N | Successful management PUT or authorized host rotation |

- **D-02:** Capture effective policy at issuance. Later policy edits affect new registrations and replacement credentials only. Read/authentication never renews anything. PUT replaces mutable metadata and rotates the management token, preserving app and secret deadlines. Secret rotation preserves app and management-token deadlines. Host management-token recovery preserves app and secret deadlines. Enabling an app does not clear an expired deadline. No automatic app renewal, retrospective recomputation, or background deadline extension.
- **D-03:** Apply DCR defaults to DCR registrations and their replacement credentials, using existing registration provenance. Direct/operator registrations retain their existing policy boundary; sharing a client struct does not make them DCR registrations. Shared-secret policy is inapplicable when there is no shared secret, including public/private-key/mTLS methods.
- **D-04:** Accept nil or integers 0..2_147_483_647 at every supported policy write boundary. Reject malformed, negative or excessive values consistently, including programmatic writes. Corrupt policy or unsupported lifetime state fails as configuration/server error, never as unlimited or a misleading credential rejection.
- **D-05:** Persist authoritative deadlines as UTC whole seconds. A finite object is eligible strictly while `now < deadline`; equality is expired. No credential/app-expiry leeway borrowed from JWT assertion skew. Use the existing injectable clock, propagated to all consumers. For a guarded mutation, sample its effective decision time after any blocking lock/current-row reload; an ingress or transaction-start timestamp must not authorize a write after the deadline. One captured decision time establishes that operation's replacement dates and checks.

### App expiry, consumers and tokens

- **D-06:** App expiry is request-time eligibility, distinct from explicit disablement and deletion. Preserve registration, consent and audit history. Workers/pruners are not enforcement. All relevant consumers must check enabled state as well as the selected deadline, including clients without secrets. Recheck at authorization completion and token-producing persistence boundaries; a previously accepted request or queued worker is not continuing authority.
- **D-07:** Use this consumer inventory as the minimum implementation/proof checklist. Error details are governed by D-15–D-17.

| Consumer | Selected behavior on app expiry |
|---|---|
| Authorization intake | Reject before host login/consent; never redirect to an unvalidated URL |
| Resume, remembered consent, approval | Recheck; no new code after expiry; safe denial only through an already validated redirect |
| PAR creation and PAR-backed authorization | Reject ineligible client at creation and again when used |
| Device authorization and device verification/approval | Reject creation; no approval after expiry; render an ineligible request safely |
| CIBA initiation, polling and push worker | Reject initiation/issuance; recheck current client at worker issuance, not a queued snapshot |
| Authorization-code redemption | Reject ineligible client; no token write or code consumption caused by this failure |
| Refresh, device/CIBA polling, all existing grant handlers | Reject ineligible client before issuing replacement tokens; preserve independent grant expiry/replay rules |
| RFC 8693 requesting client | Reject ineligible caller |
| RFC 8693 subject and actor tokens | Reject ineligible issuing-app token as invalid grant; do not check only requesting client |
| Introspection caller | Ineligible caller fails client authentication |
| Introspection target | Otherwise authorized observation reports only `active:false` for ineligible target; preserve current ownership restrictions |
| UserInfo | Ineligible issuing-app token fails before host account/claims resolution |
| Revocation | Ineligible caller fails authentication; eligible caller keeps non-disclosing success for unknown/already-invalid tokens; authorized host revocation remains available |
| Management GET/DELETE | Valid management credential may inspect/delete naturally expired, enabled app |
| Management PUT/self-rotation | Forbidden for expired app; cannot renew or revive it |
| Explicitly disabled app | Deny ordinary protocol access and all self-management, including GET/DELETE |
| Discovery/JWKS | Provider-level public surfaces unaffected |
| Host/RP sessions and account policy | Remain host/RP-owned; no promise of logout or account disablement |

- **D-08:** Cap newly issued access and refresh token expiry to the minimum of ordinary token expiry and finite app deadline. Persisted expiry, JWT `exp` and response `expires_in` must agree. Do not mint zero-lifetime tokens at equality. Recheck app eligibility when redeeming every online authorization artifact. Existing short TTLs for codes, PAR and device/CIBA requests remain; no requirement to cap all these artifacts. Preserve existing ID-token TTL/session semantics. This keeps the change focused while bounding planned app expiry for newly minted offline access tokens.
- **D-09:** Keep the local JWT verifier's offline shape. New signed `exp` can encode a planned deadline; already signed tokens cannot learn later disablement, policy or server-state changes. Existing legacy tokens keep their signed expiry, and introspection caches can be stale. Online Lockspire consumers enforce current issuing-app state. Document offline/cache limits; do not claim universal immediate revocation or host/RP session logout.
- **D-10:** Secret expiry gates Basic, post and secret-JWT authentication consistently; JWT assertion expiry, algorithm restrictions and replay protection remain independent. Secret expiry alone does not revoke already issued access/refresh tokens. A confidential refresh operation still requires a valid current client credential. Public/private-key/mTLS clients do not acquire a shared-secret expiry check.

### Management, recovery and wire metadata

- **D-11:** Management tokens are unlimited by default, optionally finite by explicit host policy. GET is side-effect-free for lifecycle: never rotate or extend. Successful PUT rotates the management token immediately using current DCR policy; the previous token stops authorizing subsequent operations. No overlapping-secret/token feature. A lost PUT response is recovered through authorized host rotation, not replay with the invalidated token.
- **D-12:** Existing host staff authorization is the recovery authority; no new self-service recovery credential or Lockspire account system. Recovery atomically replaces management token and deadline, shows plaintext once through existing handling, and never enables an app or extends its deadline. An expired app may only be read/deleted even after recovery; a disabled app remains blocked. Neither client ID, setup token, expired token nor client secret proves recovery authority. Do not add an app-renewal workflow in this milestone.
- **D-13:** Registration intake `:disabled` prevents new registrations; it must not blanket-disable existing registration management. Apply selected management gates independently. This narrow correction makes finite-token recovery usable when intake has been closed; deliberate app disablement remains the containment action.
- **D-14:** Advertise actual effective deadlines. For a shared secret, standard `client_secret_expires_at` is Unix seconds or 0 for unlimited; omit it if no shared secret exists. Add documented server-owned Lockspire extensions `lockspire_client_expires_at` and `lockspire_registration_access_token_expires_at`, each numeric Unix seconds or 0 for unlimited, in applicable registration/management responses. The latter describes the currently represented management credential. GET never returns plaintext secrets or management token. Do not represent these extensions as RFC-standard fields or reuse access-token `expires_in` for them.
- **D-15:** Preserve RFC 7592 replacement semantics for mutable metadata. PUT includes unchanged `client_id`; standard server-owned fields `registration_access_token`, `registration_client_uri`, `client_secret_expires_at`, `client_id_issued_at` are prohibited. If `client_secret` is included it must match the current secret; it is not a rotation request. For the two new extension fields, identical echoes are accepted, omission preserves server values, attempted changes return 400 `invalid_client_metadata`. Separate these server-owned fields from mutable metadata so omission cannot clear deadlines. Apply this same non-client-authoritative treatment at registration intake: an inbound extension may not select or override its server-computed deadline; reject supplied lifecycle extension fields there as `invalid_client_metadata`.
- **D-16:** Use generic, non-disclosing errors. Management missing Bearer credential returns 401 Bearer challenge without error detail; expired/replaced/wrong token, unknown app or disabled-app credential returns 401 Bearer `invalid_token`. Valid management credential plus forbidden expired-app PUT returns 403 with the existing registration error envelope and a documented Lockspire `registration_expired` code; do not mislabel it `insufficient_scope` or an invalid token. This code is a local extension, not mandated by RFC 7592. GET/PUT success 200 and DELETE success 204.
- **D-17:** Client-authentication failures retain existing 401 `invalid_client` behavior; Basic requests include the matching challenge. RFC 6749 permits 401 for other client-auth failures; do not introduce an unrelated global 400/401 normalization. Introspection invalid caller is 401; authorized inactive target is 200 `{"active":false}`. Current introspection allows only owned tokens: rejecting an expired caller does not also produce an inactive response for that same request. UserInfo returns 401 Bearer `invalid_token`; valid caller with invalid code/refresh/exchange token returns `invalid_grant`. Authorization errors use local failure before a trusted redirect exists and existing `access_denied` plus original state once safe. Device/CIBA grant expiry retains its distinct `expired_token` condition. Preserve endpoint-specific challenges and avoid new disclosure of app/secret/token expiry reasons to unauthenticated callers.

### Legacy authority and custom storage

- **D-18:** All pre-upgrade app/credential lifetimes remain effectively unlimited in built-in enforcement. Historical secret dates were advisory and may be stale; do not infer deadlines from them, creation dates or today's policy. Effective responses report unlimited rather than a false enforced historical date. Host-owned stricter enforcement remains host-owned. Upgrade documentation must explicitly disclose this grandfathering and the required deliberate replacement for finite enforcement.
- **D-19:** Select one persisted `lifetime_version` (0 legacy, 1 authoritative) and nullable app/management deadlines, reusing the secret deadline field. New rows explicitly write v1; migration defaults existing rows to v0. Missing/unknown versions from a lifetime-aware custom adapter are errors, not implicit legacy. V1 nil is authoritative unlimited. No per-credential provenance matrix or general capability framework is required.
- **D-20:** Legacy promotion is an atomic whole-row canonicalization on the locked current row: preserve current identity, hashes, active state and unrelated metadata; normalize legacy app/secret/management deadlines to nil; establish the new deadline only for the credential being issued/replaced; then persist v1 with the operation. Never just flip version. Thus RAT-only rotation cannot make an old secret date enforceable. Ordinary reads, metadata edits without credential issuance, and enable/disable do not independently require promotion. Existing PUT does issue a replacement RAT and therefore applies this rule. No eager fleet backfill. A legacy app gains a finite app lifetime only by new registration; legacy secrets/RATs gain finite lifetimes through explicit replacement under current policy. Do not add a general adoption command in this milestone.
- **D-21:** Require a declared lifetime-aware client-store contract version, validated at the existing dependency/adapter boundary. It must round-trip version/deadlines, atomically replace credential material plus lifetime and audit, and support current-state guarded mutation/issuance. Unsupported adapters/missing schema/unknown row state fail closed as configuration/server failures. Never claim finite enforcement while silently dropping fields or falling back to legacy. Runtime callback probing inside token internals remains forbidden by architecture tests. Exact callback names/typed values are planner discretion, but the observable conformance obligations are locked.

### Concurrency, deployment and rollback

- **D-22:** Reauthorize management mutations against current locked client, matching the presented management credential to current hash plus URL binding, enabled state and operation-specific app/token deadlines. Apply only intended mutable metadata to that current row. Never persist a whole stale snapshot that restores old secrets/deadlines/active state. Two PUTs using one old token have one winner. DELETE, self-rotation and operator recovery participate in the same current-state ordering. Credential hash, secret-JWT verifier where applicable, version, deadline and audit commit/rollback together.
- **D-23:** Token-producing mutations revalidate current app eligibility and the already-verified credential identity at the final guarded issuance/redemption boundary. Expensive verification may happen before locking, but a stale fingerprint cannot authorize new issuance after a committed disable/rotation. Define one consistent lock order with grant/token rows. Concurrent reads/auth checks may linearize at their successful current-state check; completed responses are not retrospectively invalidated. Do not hold locks through network calls/response rendering. Sample time after blocking waits (D-05), not PostgreSQL transaction-start `now()`.
- **D-24:** Add a new prefix-aware packaged migration; never alter previously shipped migration contents/checksums. Expand schema while old code runs, stage new code and upgraded adapters without serving ingress, drain/stop every old writer (web, admin, jobs, CLI), then cut over to new ingress. Activation means this cutover, not a new permanent distributed activation service. Mixed old/new serving traffic cannot claim enforcement. A brief maintenance cutover is the supported baseline; zero-downtime bridge-release deployment is deferred.
- **D-25:** Before any v1 write, old binaries remain compatible with the additive schema. After the first v1 write, old binaries may not serve protocol traffic: retain schema/state and fix forward or use an enforcement-aware rollback build. Do not reset versions/clear deadlines/drop columns to make downgrade appear safe. Validate migration lock duration operationally; nullable/constant additive columns do not mean lock-free DDL.

### Proof, language and responsibility

- **D-26:** Every implementation slice carries focused tests. Phase 166 adds cross-phase proof, real PostgreSQL races, fresh/legacy/custom-store packaged hosts, scoped security review and required CI. Reuse existing lock-barrier/race helpers and injected clocks; no sleeps or new time/locking library. Preserve PKCE, exact redirects, hashed secrets, code single-use, refresh-family reuse revocation and redaction.
- **D-27:** Observe actual exercised expiry/rotation/recovery events; a redaction sweep observing zero events cannot pass. Audit/telemetry distinguishes authorized host recovery from self-management and emits no plaintext credential/verifier/hash material. Correct existing false PUT-secret-rotation guidance when behavior is proven. Runtime/operator copy uses PRODUCT.md vocabulary, states expired vs disabled vs unknown accurately, and adds new concepts/retired phrases with their contract tests. No admin redesign or exposure of storage-version guts to support staff.

### Agent discretion

Exact helper modules, callback signatures, adapter declaration shape, column names for the two new deadlines, shared pure eligibility functions, lock ordering implementation, focused test organization and concise copy remain flexible within these decisions. Use ordinary Elixir data/functions, explicit dependencies and existing Ecto transactions. No new runtime dependency is justified by the research. Reopen only a demonstrated contradiction, not routine implementation preferences.

### Folded todos

The existing DCR lifetime todo is already approved milestone scope. Its semantics/compatibility portion informs Phase 162; implementation and final proof stay in Phases 163–166. Preserve `resolves_phase: 166` and keep the todo pending until verified. No duplicate audit or new capability is folded in.
</decisions>

<canonical_refs>
## Canonical References

Downstream agents MUST read these before planning or implementing.

- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md` (DCR-02–19), `.planning/ROADMAP.md` (162–166), `.planning/METHODOLOGY.md` — scope, sequencing and reasoning lenses.
- `.planning/research/dcr-lifetimes/SCOPE.md`, `.planning/research/dcr-lifetimes/SUMMARY.md`, `.planning/research/dcr-lifetimes/ARCHITECTURE.md`, `.planning/research/dcr-lifetimes/PITFALLS.md` — prior scope/research; open choices there are selected here.
- `.planning/milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md` — completed audit, reused rather than repeated.
- `.planning/todos/pending/2026-10-13-audit-dcr-default-lifetime-semantics.md` — unresolved umbrella, final proof owner 166.
- `PRODUCT.md`, `docs/supported-surface.md`, `docs/dynamic-registration.md` — canonical product language/support boundary; current DCR guide needs the identified truth correction.
- `prompts/lockspire-elixir-oss-library-practices.md`, `prompts/lockspire-ecto-token-and-audit-model.md`, `prompts/lockspire-security-posture-and-threat-model.md`, `prompts/lockspire-host-app-integration-seam.md` — applicable prep corpus, subordinate to current product/source truth. Current brand guidance remains `prompts/lockspire_brand_book.md`; this is not a visual redesign.
- [RFC 7591 §3.2.1](https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1) — standard secret metadata vs local duration choices.
- [RFC 7592](https://www.rfc-editor.org/rfc/rfc7592.html) §§2,5 — Experimental management protocol, replacement rules, forbidden operations, lockout rationale.
- [RFC 6749 §5.2](https://www.rfc-editor.org/rfc/rfc6749.html#section-5.2), [§4.1.2.1](https://www.rfc-editor.org/rfc/rfc6749.html#section-4.1.2.1), [RFC 6750 §3](https://www.rfc-editor.org/rfc/rfc6750.html#section-3) — endpoint errors/challenges and redirect safety.
- [RFC 7662 §§2,4](https://www.rfc-editor.org/rfc/rfc7662.html), [RFC 7009 §3](https://www.rfc-editor.org/rfc/rfc7009.html#section-3), [OIDC Core §2](https://openid.net/specs/openid-connect-core-1_0.html#IDToken) — online/offline limits and ID-token/session distinction.
- [PostgreSQL 14 row locking](https://www.postgresql.org/docs/14/explicit-locking.html#LOCKING-ROWS), [current time functions](https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT), [adding columns](https://www.postgresql.org/docs/14/ddl-alter.html#DDL-ALTER-ADDING-A-COLUMN), [Ecto 3.13.5 locking](https://ecto.hexdocs.pm/3.13.5/Ecto.Query.html#lock/3), [transactions](https://ecto.hexdocs.pm/3.13.5/Ecto.Repo.html#transact/2) — implementation constraints, not a dependency upgrade.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets and patterns

- `lib/lockspire/protocol/dcr_policy.ex` copies the three nullable policy values; `lib/lockspire/client_metadata.ex` currently creates misleading nil/zero secret dates and preserves stale lifecycle state across replacement.
- `lib/lockspire/domain/client.ex`, `lib/lockspire/storage/ecto/client_record.ex`, `lib/lockspire/storage/client_store.ex`, `lib/lockspire/storage/ecto/repository/client_store.ex` own domain/round trips/lifecycle writes. Current row locks do not reauthorize the caller's credential or make stale full replacements safe.
- `lib/lockspire/client_lifecycle.ex`, `lib/lockspire/protocol/registration_management.ex`, `lib/lockspire/admin/clients.ex` own transaction/audit/rotation workflows. Existing host-authorized token recovery is reusable; attribution needs correction.
- `lib/lockspire/protocol/client_auth.ex` currently checks method/credential without universal enabled-state enforcement. `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` independently enforces assertion timing/replay; preserve that protection.
- `lib/lockspire/protocol/token_exchange/internal/dependencies.ex` and `lib/lockspire/protocol/token_exchange/internal/legacy_options.ex` are explicit dependency adaptation seams; `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex` currently loses the request clock. Architecture tests prohibit ambient runtime discovery inside token internals.

### Integration points

- Authorization intake/resume/approval; PAR; device verification; CIBA polling/push; token grant handlers; RFC8693 subject/actor validation; introspection and UserInfo require the D-07 inventory.
- `lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex`, `lib/lockspire/protocol/token_exchange/internal/token_issuer.ex`, `lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex` currently derive JWT/response lifetimes separately from persisted expiry: all three must use selected effective token lifetime.
- `lib/lockspire/plug/verify_token.ex` remains an offline verifier; no hidden client-store dependency.
- `lib/lockspire/web/controllers/registration_controller.ex` currently gates every action on intake enablement. `lib/lockspire/web/registration_json.ex` currently emits expiry even without a secret and floors microsecond dates.
- `lib/lockspire/install/migrations.ex` and `lib/lockspire/storage/ecto/migration.ex` provide additive/prefix-aware packaged migration patterns.
- `test/lockspire/storage/repository_concurrency_test.exs`, `test/lockspire/storage/reencrypt_concurrency_test.exs` provide real committed transaction/lock-barrier patterns. `test/lockspire/protocol/dcr_telemetry_redaction_test.exs` has a vacuous event-observation seam; exercise real events. Clean-room host infrastructure supplies install/upgrade proof.
</code_context>

<specifics>
## Specific Ideas and Acceptance Examples

1. At T=100, register with app=60, secret=10, management=20: deadlines 160/110/120. Secret valid immediately before 110 and invalid at 110; app checks remain independent. Nil/zero alternatives advertise 0, never 100.
2. Change policy at 105: all existing deadlines unchanged. Secret rotation at 107 uses new secret policy; PUT at 108 replaces management token under current management policy. Neither moves app deadline 160. Access/refresh issued at 159 expire no later than 160; at 160 issuance fails.
3. Give management token a deadline beyond 160: at app expiry, valid token GET/DELETE succeeds, PUT is 403. If token expires first, host recovery replaces it without extending the app. Disabled app denies all self-management. Intake closed alone does not block management.
4. Legacy rows with nil, creation-time, past, future or stale-after-rotation secret dates all preserve existing acceptance. RAT-only replacement promotes v1 and normalizes old secret expiry to unlimited without changing secret hash. Secret replacement then establishes its own explicit deadline. Historical finite app policy is not backfilled.
5. Two PUTs with one old token have one winner. PUT cannot restore a secret rotated concurrently or active state after disable. Issuance waiting on a lock across expiry fails after reload. Audit/write failure preserves old hashes, dates, version and state.
6. A custom adapter that drops deadline/version state fails conformance; it cannot advertise finite expiry and later authenticate indefinitely. Existing generated hosts apply the new migration with configured prefixes. No old serving writer remains at activation; post-v1 rollback cannot use an expiry-unaware binary.

The user prefers another small copy/paste over another dependency, coherent researched defaults over option menus, and automated proof over repetitive manual approval. Use applicable product/security/architect/Elixir/Ecto/distributed-systems/SRE/partner/support lenses; unrelated rendering/graphics lenses add no value here.
</specifics>

<deferred>
## Deferred Ideas

- Zero-downtime mixed-version bridge release, dual-secret/token overlap, automatic renewal, a new credential-adoption UI/CLI, and generic capability/activation frameworks are outside this milestone's selected minimum.
- Broad admin redesign, account/session ownership changes, new federation/grants, new runtime dependencies, unrelated security-key work and package publication remain outside Phase 162.
- Phases 163–165 implement the selected lifecycles; Phase 166 proves full journeys and updates public/operator truth. Capturing context does not finish Phase 162 or close DCR-02–04; its design deliverables still need planned execution and verification.

### Reviewed todos

The matching DCR umbrella is retained pending final Phase 166 proof, as described above. No other todo was folded.
</deferred>
