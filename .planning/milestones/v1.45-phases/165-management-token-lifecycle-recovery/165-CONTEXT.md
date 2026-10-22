# Phase 165: Management-Token Lifecycle & Recovery - Context

**Gathered:** 2026-10-21 (assumptions mode; inline source analysis)
**Status:** Ready for planning
**Decision authority:** The user selected “1” (proceed with the presented four-area recommendation bundle). The decisions below apply the verified Phase 162 contract to the implemented Phase 163–164 foundations. No implementation or planning completion is claimed.

<domain>
## Phase Boundary

Deliver DCR-10, DCR-11 and DCR-12: management-token issuance and expiry, registration read/update/delete eligibility, authorized host recovery, and atomic replacement under current-state authority. Reuse existing app/secret enforcement, lifetime storage and transaction infrastructure. Keep Lockspire embedded and staff authentication/authorization host-owned. Phase 166 owns final cross-phase packaged journeys, security/CI and complete guidance proof; publication remains separate.
</domain>

<decisions>
## Implementation Decisions

### Lifetime and response metadata
- **D-01:** Nil and zero management duration mean unlimited; a positive integer means seconds from token issuance or replacement. Snapshot policy at that event. GET, token lookup and policy edits do not renew existing credentials. Apply DCR defaults according to existing registration provenance, preserving the direct/operator-registration boundary.
- **D-02:** Validate nil or integer 0..2_147_483_647 at supported management-policy write/use boundaries. Malformed policy, missing adapter support and unsupported durable lifetime state are configuration/server failures, never unlimited fallback or misleading invalid-token errors.
- **D-03:** Store authoritative finite management deadlines as UTC whole seconds and nil for unlimited. Eligibility is strictly now < deadline, with equality expired and no JWT-skew allowance. Use explicit injectable clocks; capture the final decision time after required blocking locks/current-row reload, and use that time for checks, replacement dates and corresponding audit state.
- **D-04:** Add the selected server-owned response extensions lockspire_client_expires_at and lockspire_registration_access_token_expires_at to applicable registration/management responses. Each is numeric Unix seconds or 0 for effective unlimited, including legacy state. Describe them as Lockspire extensions, not RFC fields or access-token expires_in. GET returns neither plaintext management token nor client secret. PUT returns only its newly committed management token, preserving existing shared-secret disclosure rules.

### Management access and request validation
- **D-05:** Authorize GET, PUT and DELETE against the current token identity, URL/client binding, management deadline and operation-specific app state. Retain current-row/fingerprint checks; an earlier lookup or accepted snapshot is not continuing authority after replacement or disablement. Keep response encoding and remote work outside locks.
- **D-06:** A valid management token permits GET/DELETE for a naturally expired, enabled app; PUT is forbidden with 403 registration_expired. Explicit disablement rejects all self-management. Expired/replaced/wrong tokens cannot use the expired-app GET/DELETE exception. Closing registration intake alone must leave existing management available.
- **D-07:** Preserve non-disclosing protocol errors: missing Bearer credential gets 401 Bearer challenge without error detail; wrong, expired or replaced token, unknown app, URL mismatch or disabled-app credential gets 401 Bearer invalid_token. Storage/configuration failure stays a server failure. GET/PUT success is 200; DELETE success is 204.
- **D-08:** Complete the Phase 162 PUT contract: unchanged client_id must be present in the body and validated separately from the URL identity; mutable metadata follows replacement semantics. Reject registration_access_token, registration_client_uri, client_secret_expires_at and client_id_issued_at. If client_secret is included it must match current material and never requests rotation. Extension omission preserves server values; identical echoes are accepted; attempted changes return 400 invalid_client_metadata. Registration intake rejects client-supplied lifecycle extensions. A rotated response represents the new deadline even when a request echoed the prior deadline.
- **D-09:** Successful PUT rotates management hash/deadline immediately under current applicable policy and preserves app/secret deadlines. GET never rotates. No overlap or replay recovery with the old token: a lost successful PUT response requires authorized host recovery.

### Host recovery, legacy state and atomic replacement
- **D-10:** Reuse existing host-authorized management-token rotation and one-time plaintext display. Preserve the existing host permission boundary and confirmation handling; do not add Lockspire accounts, another recovery credential or a new privilege route. Client ID, setup token, expired token and client secret are not recovery authority.
- **D-11:** Recovery replaces management hash/deadline without enabling an app or changing app/secret deadlines. Recovery may replace lost/expired credentials, but an expired app still allows only GET/DELETE and a disabled app remains blocked. Recovery is not app renewal.
- **D-12:** Replacement hash, deadline, lifetime canonicalization, intended mutable metadata and required audit commit or roll back together on the current locked row. Reauthorize self-management after waiting and apply intended fields to current state; never restore stale secrets, active state or unrelated deadlines. Do not deliver successful plaintext after failed writes/audits.
- **D-13:** Preserve existing stale-snapshot rejection for competing management-token replacements, including host recovery. Two PUTs using the same old token have one winner; stale requests cannot retain or restore prior authority. Do not import Phase 164's different serialized secret-rotation behavior into management-token recovery or invent an overlapping-token guarantee. A host retry must use refreshed current state through the authorized path.
- **D-14:** Legacy v0 credentials remain effectively unlimited. On explicit management replacement, atomically canonicalize the current whole-row lifetime state: clear advisory app/secret/management dates, set only the new management deadline and promote to v1. Preserve hashes, identity, enabled state and unrelated metadata. V1 replacement preserves authoritative app/secret deadlines. No guessed backfill, eager fleet promotion or version-only update.
- **D-15:** Reuse the existing lifetime-aware adapter/shared transaction contract and persisted deadline field. Extend conformance coverage for management round trips, guarded mutation and audit rollback; adapters must not silently drop lifecycle fields or split transaction authority. No new migration, background expiry worker, runtime dependency or general capability framework is needed for this scope.

### Proof, attribution and guidance
- **D-16:** Focused proof accompanies implementation: nil/zero/positive issuance, before/equality/after expiry, changed policy, provenance, GET non-renewal, successful PUT/recovery, lost-response recovery, disabled/expired apps, intake closure, request-field rules, wire metadata and legacy promotion preserving unrelated credentials.
- **D-17:** Prove actual independent PostgreSQL transaction schedules with observable blockers and injected clocks: expiry during a client-lock wait, stale GET/PUT/DELETE after token replacement, competing PUT/recovery replacements, secret rotation and disablement racing management writes, and write/audit rollback. Assert durable state and one-winner outcomes, not only returned errors. Reuse existing helpers; sleeps and shared sandbox connections are not race proof.
- **D-18:** Exercise real finite-token use, expiry rejection, self-management replacement and authorized recovery in redaction tests. Require observed events. Audit/telemetry must distinguish host recovery from self-management and disclose no plaintext token, hash, shared secret or verifier material. Correct the existing self-management attribution on host recovery.
- **D-19:** Update affected guidance with executable behavior now, including recovery steps, no-overlap/lost-response consequences and the optional-finite-token lockout tradeoff. Final integrated guidance remains Phase 166. Read PRODUCT.md personas/vocabulary before changing admin text; use app management token, update retired wording/contracts when needed, and preserve the existing task flow without an admin redesign.

### Agent discretion

Choose narrow helper names, callback transport, clock plumbing, error types and focused plan/test organization within these decisions. Reuse ordinary Elixir functions, the repository facade and existing transaction seams. Preserve public APIs where practical; any minimal additive adaptation must satisfy existing compatibility and host-boundary contracts. Reopen only a demonstrated contradiction with the normative Phase 162 contract.

### Folded Todos

The DCR lifetime umbrella is already approved milestone scope. Its management-token portion informs this phase; preserve the pending todo and resolves_phase: 166 until final cross-phase proof. No duplicate audit or new capability is folded in.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/METHODOLOGY.md` — scope, DCR-10/11/12, phase ownership and reasoning lenses.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md`, `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CASES.json`, `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md` — normative lifetime, request/wire/error, recovery, concurrency and legacy contract.
- `.planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md`, `.planning/phases/163-app-lifetime-compatible-host-storage/163-VERIFICATION.md` — implemented app-state gates, storage and current-row transaction foundations.
- `.planning/phases/164-client-secret-expiry-atomic-rotation/164-CONTEXT.md`, `.planning/phases/164-client-secret-expiry-atomic-rotation/164-VERIFICATION.md` — implemented independent secret lifecycle; preserve its behavior through management replacement.
- `.planning/research/dcr-lifetimes/SCOPE.md`, `.planning/research/dcr-lifetimes/SUMMARY.md`, `.planning/research/dcr-lifetimes/PITFALLS.md` — original scope and research; Phase 162 resolves earlier open choices.
- `.planning/milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md` — historical baseline audit, not current enforcement truth.
- `.planning/todos/pending/2026-10-13-audit-dcr-default-lifetime-semantics.md` — umbrella remains pending through Phase 166.
- `PRODUCT.md`, `docs/dynamic-registration.md`, `docs/upgrading/client-lifetimes.md`, `docs/operator-admin.md`, `docs/supported-surface.md` — vocabulary, operator recovery, host upgrade and public support contract.
- `prompts/lockspire-ecto-token-and-audit-model.md`, `prompts/lockspire-host-app-integration-seam.md`, `prompts/lockspire-security-posture-and-threat-model.md` — applicable background, subordinate to current source and normative contract.
- [RFC 7592 sections 2.2 and 5](https://www.rfc-editor.org/rfc/rfc7592.html) — PUT replacement/field rules and management-token expiry lockout rationale; rechecked 2026-10-21. Optional finite lifetime and host recovery are the selected Lockspire policy, not a universal RFC timeout.
- [RFC 6750 section 3](https://www.rfc-editor.org/rfc/rfc6750.html#section-3) — Bearer challenge/error distinctions.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/lockspire/domain/client.ex` provides app/secret eligibility, strict time handling and credential_lifetime_changes/3 for legacy canonicalization. Management state is already present on the domain aggregate.
- `lib/lockspire/storage/client_lifetime.ex`, `lib/lockspire/storage/client_store.ex` and `lib/lockspire/storage/ecto/client_record.ex` provide declared adapter/transaction authority, callback contracts and persisted lifecycle fields.
- `lib/lockspire/protocol/registration_access_token.ex` supplies random token generation, deterministic hash lookup and verification; preserve hashed storage.
- `lib/lockspire/client_lifecycle.ex` and `lib/lockspire/storage/ecto/repository/client_store.ex` supply current-row locking, intended metadata field selection and atomic audit patterns. Existing secret rotation supplies a reusable post-lock clock/current-policy pattern.

### Established Patterns
- `lib/lockspire/protocol/registration_management.ex` already rechecks current ID/hash/enabled state and app-state exceptions; it currently uses ambient wall time and has no management-deadline check.
- Existing management replacement callbacks use stale-hash comparison and canonicalize legacy state with a nil replacement deadline. Preserve the concurrency policy while calculating/enforcing actual replacement deadlines.
- Existing app integration tests prove closed intake and expired-app GET/DELETE exceptions. Keep endpoint errors distinct from unsupported durable state.
- PostgreSQL race helpers and DCR redaction tests already exist; observe actual matching events and target actual blocked backend sessions.

### Integration Points
- `lib/lockspire/client_metadata.ex` builds registrations without assigning management expiry; `lib/lockspire/protocol/dcr_policy.ex` carries its resolved duration but does not validate it alongside app/secret durations.
- `lib/lockspire/protocol/registration.ex` supplies issuance time and intake validation; `lib/lockspire/web/controllers/registration_controller.ex` merges route/request params and removes client_id before update validation. Preserve separate URL and body identity when completing the contract.
- `lib/lockspire/web/registration_json.ex` serializes effective secret expiry but omits both selected lifecycle extensions; ensure server-owned values cannot be overridden through metadata.
- `lib/lockspire/web/live/admin/clients_live/show.ex` already confirms host rotation and reveals plaintext once. `RegistrationManagement.rotate_registration_access_token/1` records an operator audit but emits self_registered_client rotation telemetry; align attribution without broadening host permissions.
- `test/lockspire/protocol/registration_management_test.exs`, `test/lockspire/web/controllers/registration_controller_test.exs`, `test/lockspire/web/registration_json_test.exs`, `test/integration/app_lifetime_management_test.exs`, `test/lockspire/storage/repository_concurrency_test.exs`, `test/lockspire/protocol/dcr_telemetry_redaction_test.exs` — extend focused behavior, durable ordering and redaction proof.
</code_context>

<specifics>
## Specific Ideas

- Reuse Phase 162's example: registration at 100 under app=60, secret=10 and management=20 gives deadlines 160/110/120. Management expiry at 120 blocks all self-management without changing the app or secret.
- Authorized recovery at 125 under management=40 produces management deadline 165 while app=160 and secret=110 remain. At app equality 160 the recovered credential may GET/DELETE but PUT gets 403; disabled state still blocks all self-management.
- A PUT waiting across its current token deadline fails after lock release and leaves metadata, hash, deadlines and audit unchanged. A replacement committed before another old-token request's current-state check invalidates that request.
- A lost successful PUT response is recovered through the existing authorized host rotation task. Preserve one-time delivery and state plainly that the previous token no longer works.
- Applied methodology lenses: assumption-first analysis, least-surprise host seam, research-first defaults, high-threshold escalation and one-shot recommendation bundles. Source analysis and the verified contract support the confirmed bundle without another product-policy choice.
</specifics>

<deferred>
## Deferred Ideas

- Phase 166: final cross-phase packaged host journeys, complete lifetime/security/redaction matrix, required CI and final integrated guidance proof; only that proof can close the lifetime umbrella todo.
- App renewal, overlapping credentials, new recovery credentials/accounts, a new adoption UI/CLI, mixed-version zero-downtime bridge, general capability frameworks, new dependencies, broad admin redesign and package publication remain outside this phase.

### Reviewed Todos (not closed)

The matching lifetime umbrella remains pending with resolves_phase: 166. No new capability was folded into scope.
</deferred>
