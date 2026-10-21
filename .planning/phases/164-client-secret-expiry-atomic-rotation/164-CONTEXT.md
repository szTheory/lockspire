# Phase 164: Client-Secret Expiry & Atomic Rotation - Context

**Gathered:** 2026-10-20 (assumptions mode; delegated source analysis)
**Status:** Ready for planning
**Decision authority:** Carry forward the user's explicit instruction to research, synthesize a coherent recommendation bundle and automatically follow it. No separate confirmation response is claimed. These decisions apply the verified Phase 162 contract to current Phase 163 foundations; they do not reopen its semantics.

<domain>
## Phase Boundary

Deliver DCR-07, DCR-08 and DCR-09: truthful shared-secret expiry metadata, consistent Basic/post/secret-JWT enforcement, and atomic operator rotation under the selected lifetime policy. Phase 163 app enforcement and storage compatibility are implemented foundations. Management-token expiry/recovery remains Phase 165; final cross-phase host/security/guidance proof remains Phase 166. Preserve the embedded library and host-owned staff authorization.
</domain>

<decisions>
## Implementation Decisions

### Issuance policy and metadata
- **D-01:** Nil and zero secret duration mean unlimited; a positive integer means seconds from secret issuance. Store finite UTC whole-second deadlines and nil for unlimited. Use current policy for issuance/replacement only; never recompute existing credentials on policy edits or reads.
- **D-02:** Validate nil or integer 0..2_147_483_647 consistently at supported secret-policy write/use boundaries. Malformed policy or unsupported durable lifetime state is a configuration/server error, never unlimited or a misleading invalid credential response.
- **D-03:** Apply DCR secret defaults only to self-registered clients and their replacements. Direct/operator registrations retain their existing policy boundary. Use current registration provenance, not assumptions based on a shared struct.
- **D-04:** Registration and management responses report the effective current secret deadline as Unix seconds or 0 for unlimited, including legacy v0. Omit client_secret_expires_at for non-secret authentication methods; confidential does not imply shared-secret authentication. Preserve plaintext omission on reads/updates. Do not echo raw advisory dates as enforced deadlines.

### Authentication and final authority
- **D-05:** Share strict secret eligibility across client_secret_basic, client_secret_post and client_secret_jwt. A finite secret is eligible only while now < deadline; equality is expired, with no assertion-skew allowance. Preserve existing endpoint invalid_client/challenge mapping and non-disclosure of expiry details.
- **D-06:** Revalidate secret authority at final guarded issuance using current locked client state, verified credential identity and a fresh decision time after every required blocking client/grant/token lock. A request verified before expiry or committed rotation must not consume a code, rotate a refresh token or issue tokens afterward under stale authority. Preserve consistent lock ordering and rollback semantics.
- **D-07:** Secret-JWT algorithm, assertion expiry/claims and replay controls remain independently effective. Final guarded issuance rechecks credential eligibility/identity, not the already-consumed assertion JTI. Keep remote operations and response encoding outside locks.
- **D-08:** Secret expiry alone does not revoke or cap issued access/refresh tokens. Confidential refresh still requires current valid credentials. Do not gate exchange subject/actor token validity, online target-token checks or queued CIBA push solely on issuing-client secret expiry; distinguish requester authentication from issuing-app eligibility.
- **D-09:** Public/private-key/mTLS authentication does not acquire a secret-expiry gate, even if a direct confidential registration has dormant shared-secret material. No new authentication method or verifier encryption-key design is included.

### Rotation, legacy state and transactions
- **D-10:** Replacement hash, secret-JWT verifier, issuance timestamp, deadline, lifetime version and audit commit or roll back together against the current row. Establish the replacement deadline and audit time after blocking locks. No old-secret overlap after commit; a failed write/audit must not return successful plaintext delivery or leave partial credential state.
- **D-11:** V0 secret dates remain advisory until explicit replacement. Under the current-row lock, canonicalize all legacy deadlines to nil, set only the replacement secret deadline under current applicable policy, then promote to v1. V1 replacement preserves authoritative app and management-token deadlines. Never flip version alone, extend the app, restore a stale row, or revive old dates.
- **D-12:** Preserve host-authorized rotation behavior: no old-secret proof is required, and an expired secret can be replaced. Rotation never enables a disabled app or renews an expired app. Concurrent authorized operator commands serialize; only the last committed replacement remains current. Do not invent a new stale-command/CAS error contract or promise both returned secrets remain current.
- **D-13:** Preserve the existing public behavior around rotating dormant material for confidential non-secret methods, while keeping lifetime applicability and wire metadata method-aware. Changing that operator API policy is unnecessary for this phase.
- **D-14:** Extend the existing declared lifetime-aware adapter/shared transaction contract and its conformance tests. No new schema migration, general capability framework, expiry worker or runtime dependency is needed. Unsupported adapters must not silently discard replacement lifecycle fields or separate audit authority.

### Verification and host experience
- **D-15:** Prove nil/zero/positive issuance, strict boundary equality, microsecond/default-clock handling, policy edits, provenance, no-secret omission, legacy dates/promotion, all three secret-auth methods, independent JWT timing/replay and preservation of existing token validity. Focused tests accompany each implementation slice.
- **D-16:** Use deterministic independent PostgreSQL sessions with observable lock blockers and injected clocks for preverified-secret rotation races, expiry during client/later-grant waits, competing operator rotations, and audit/write rollback. Assert durable final state and no unintended code/token consumption; sleeps are not expiry proof.
- **D-17:** Exercise actual finite-secret rotation/authentication events in redaction checks; do not claim coverage from zero observed events. Preserve hashed storage and existing verifier protection, and never emit plaintext/hash/verifier material in audit, logs, telemetry or operator errors.
- **D-18:** Keep guidance accurate for changed behavior now; final cross-phase guidance remains Phase 166. Read PRODUCT.md before changing admin text and follow vocabulary/retired wording contracts. No admin redesign, new recovery credential, dependency or host responsibility is added.

### Agent discretion
Helper names, callback transport, explicit clock plumbing and focused test organization are implementation choices within these decisions. Prefer ordinary Elixir functions and existing transaction seams. Preserve public APIs unless a minimal additive change is necessary and explicitly checked against compatibility contracts.

### Folded Todos
The audit-dcr-default-lifetime-semantics todo is already milestone scope. Its shared-secret portion informs this phase; keep it pending with resolves_phase: 166. Do not close the umbrella todo or implement management-token lifecycle here.
</decisions>

<canonical_refs>
## Canonical References

Downstream agents MUST read these before planning or implementing.
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/METHODOLOGY.md` — scope, DCR-07/08/09 and reasoning lenses.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md`, `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CASES.json`, `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTEXT.md` — normative lifetime/upgrade contract and examples.
- `.planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md`, `.planning/phases/163-app-lifetime-compatible-host-storage/163-VERIFICATION.md` — implemented app, adapter, clock, transaction and legacy foundations.
- `.planning/research/dcr-lifetimes/SCOPE.md`, `.planning/research/dcr-lifetimes/SUMMARY.md`, `.planning/research/dcr-lifetimes/PITFALLS.md` — original scope/research; open choices there are resolved by Phase 162.
- `.planning/milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md` — historical audit, not current implementation truth.
- `PRODUCT.md`, `docs/upgrading/client-lifetimes.md`, `docs/dynamic-registration.md` — host/operator language and deployment contract (resolve current documentation paths before editing).
- RFC 7591 section 3.2.1: https://www.rfc-editor.org/rfc/rfc7591.html#section-3.2.1 — standard secret-expiry timestamp/zero/no-secret representation.
- RFC 7523: https://www.rfc-editor.org/rfc/rfc7523.html — independent JWT client authentication assertion controls.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/lockspire/domain/client.ex` — app eligibility, lifetime versions and credential replacement canonicalization; extend consistently for secret eligibility.
- `lib/lockspire/storage/client_lifetime.ex` and `lib/lockspire/storage/client_store.ex` — declared adapter, shared transaction authority and current-row credential callbacks.
- `lib/lockspire/storage/ecto/repository/client_store.ex` — locked secret hash/verifier replacement already exists; replacement lifetime currently hardcoded unlimited.
- `lib/lockspire/client_lifecycle.ex` and `lib/lockspire/storage/ecto/repository/transaction_store.ex` — outer atomic audit and explicit rollback on error tuples.

### Established Patterns
- `lib/lockspire/protocol/client_auth.ex` and `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` separate material authentication from app eligibility and assertion replay.
- `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex` binds verified method/material identity; `grant_persistence.ex` and `refresh_exchange.ex` have current-state/post-wait boundaries.
- Existing PostgreSQL client/grant wait tests observe actual blockers and include stale-secret fingerprint rejection.

### Integration Points
- `lib/lockspire/client_metadata.ex`, `lib/lockspire/protocol/dcr_policy.ex`, `lib/lockspire/storage/ecto/server_policy_record.ex` — current secret duration calculation/validation gaps.
- `lib/lockspire/web/registration_json.ex` — raw stored secret-date serialization needs effective method-aware representation.
- `lib/lockspire/admin/clients.ex` — rotation currently captures its time before lookup/lock; preserve its host authorization/public behavior while moving decision time to the guarded boundary.
- `lib/lockspire/protocol/registration.ex` already generates DCR shared material only for Basic/post/secret-JWT; direct `lib/lockspire/clients.ex` may generate dormant material for other confidential methods.
</code_context>

<specifics>
## Specific Ideas

Use security, protocol interoperability, Elixir/storage architecture, host DX and operational concurrency lenses. The current code supports the selected direction without a new dependency. Preserve serialized operator replacement instead of adding an unrequested CAS/409 API. The analyzer found no external research gap requiring a new semantic decision; planning research should still verify exact relevant standards when using them.
</specifics>

<deferred>
## Deferred Ideas

Management-token finite enforcement/recovery is Phase 165. Final cross-phase clean-room, security, CI and complete guidance proof is Phase 166. Dedicated secret-JWT encryption key SEC-01, secret overlap, app renewal, zero-downtime bridge, new operator concurrency APIs and new non-secret rotation prohibitions are outside this phase.

### Reviewed Todos (not folded)
No new capability folded. The existing lifetime umbrella todo stays pending until Phase 166.
</deferred>
