# Phase 175: Accepted Baseline & Verifier Compatibility Contract - Context

**Gathered:** 2026-10-25 (assumptions mode; codebase analysis and primary-source research fan-out)
**Status:** Ready for Phase 175 planning; implementation entry and dependent Phase 176 planning remain gated

<domain>
## Phase Boundary

Establish a fresh accepted implementation baseline and freeze a finite verifier-custody and compatibility contract for VBASE-01 and VBASE-02. Qualify legacy age through actual persisted-client authentication/lifecycle callers, reconcile retained delivery and resource custody, and assign executable acceptance outcomes to Phases 176–178. This discussion does not run exact-main acceptance, implement the encryption runtime, establish adopter incidents, publish a package, or complete either requirement.

Phase 175 must resolve material policy/API/support questions before Phase 176 is planned. If qualification disproves the no-schema/no-new-dependency premise, revise GSD scope explicitly rather than expanding implementation silently. Preserve historical Phase 142/143 and immutable prior receipts.
</domain>

<decisions>
## Implementation Decisions

### Evidence, delivery lineage and ownership
- **D-01:** Adopt the coherent scoped recommendations from this discussion under the owner's explicit instruction to research through subagents and automatically follow the synthesized recommendations. Do not repeat technical preference questions already answered by repository evidence. This delegation does not turn unperformed qualification into a passing result or waive material scope-revision gates.
- **D-02:** Phase 175 preserves the already qualified entry-main receipt and separately binds its contract/qualification evidence to one exact candidate source that passes local checks. Candidate evidence is not accepted-main evidence. The final integrated source is accepted through the single v1.48 milestone PR after implementation, review, and verification are complete in Phase 178, using the existing helper rather than another acceptance mechanism. Do not create a separate Phase 175 PR or merge retained milestone ancestry; keep the entry receipt, candidate checks, and final integrated-main receipt distinct.
- **D-03:** Acceptance must bind synchronized HEAD/local main/refreshed remote main, full local contributor checks, the helper's matching canonical push-CI and no-publish Release graph, and explicit dispositions for the exact-mode warnings actually emitted. Preserve stdout receipt bytes, exit status, command, observation time and digest; keep annotations beside the receipt. Preserve failed attempts separately. Broad hygiene warnings belong in the separate custody record unless exact mode actually emits them. Record a final checkout-status observation beside the receipt as well.
- **D-04:** Reuse Phase 174 as historical evidence without restamping it. Record resource purpose, custodian (or explicitly unknown original owner), identity/unique-work disposition, blocker and next action. Retention is a valid disposition for historical worktrees, databases, demo data, containers, volumes and build artifacts; cleanup is not an acceptance objective. Package publication remains separate.

### Finite contract and qualification ownership
- **D-05:** Produce a finite ledger with stable case IDs, requirement, actual caller/source seam, client/lifecycle state, code/config/key/write stage, storage composition, operation, expected return/protocol result, permitted mutations, preserved fields, redaction expectation, proof owner/phase, evidence identity/status and blocking disposition. Expand meaningful boundaries into individual cases; avoid an unrestricted Cartesian product or a duplicate release/proof framework.
- **D-06:** Phase 175 owns baseline, actual-caller legacy qualification and the frozen contract. Phase 176 owns configuration/envelope/writer/reader/rollout behavior. Phase 177 owns maintenance, contention/rollback, status, recovery and disclosure proof. Phase 178 owns both existing packaged dependency pairs, declared adapter composition, focused reviews and delivery. These are acceptance owners, not speculative downstream task plans.

### Credential identity and helper compatibility
- **D-07:** Dedicated persisted envelopes must bind the canonical persisted `client_id` and a verifier-specific purpose. Select the final client ID before material generation in direct registration and DCR; operator rotation uses the existing ID. Never use temporary identities or persist an identity-free dedicated fallback. Preserve coherent hash/verifier persistence and the existing one-time plaintext handoff on all credential-producing paths, including Basic/post clients that currently receive verifier material.
- **D-08:** Preserve the public zero-argument `rotate_secret_hash/0` return contract without newly requiring client identity or custody configuration: hash-only generation should not create discarded verifier material. Phase 175 must enumerate documented/exported material helpers, binary endpoint-secret overloads and explicit options, then freeze compatible behavior for legacy mode and clear failure for dedicated material calls missing identity. A genuinely necessary breaking public API change requires a recorded GSD revision before dependent planning.
- **D-09:** Preserve the current ciphertext-sensitive verified-credential fingerprint. If rewrap commits between JWT authentication and guarded issuance, retain fail-closed credential-change rejection, with no successful token/grant side effects. The assertion JTI may already be consumed; retry requires a new assertion/JTI. Do not remove ciphertext from the fingerprint, clear replay state or retry the same assertion to hide maintenance. Phase 177 must prove this race and the successful fresh-assertion retry using real PostgreSQL contention.
- **D-10:** Before promoting a row to dedicated/current-key custody, establish that the decrypted verifier agrees with the stored secret hash. Missing/invalid hash or divergent material is non-ready and remains unchanged with explicit recovery guidance. Do not add a per-request expensive hash check incidentally; this is a migration/check qualification boundary. Real secret rotation must continue invalidating stale credential authority.

### Purpose-specific configuration and strict representation
- **D-11:** Use existing OTP/Plug/Ecto primitives and a separate purpose-specific verifier configuration, independent of endpoint/session secrets and signing KEKs. Recommend one block with keys, selected write key, explicit legacy/dedicated write mode and explicit allow/reject legacy-read policy. The exact public names and accepted input grammar must be frozen in Phase 175's contract rather than improvised separately by later phases.
- **D-12:** Freeze these states: absent configuration with declared existing legacy compatibility; staged dedicated readers with legacy reads/writes; dedicated writes with legacy reads; dedicated writes with legacy rejection. Staging reader keys must not activate writes. Reader-only staging need not select a dedicated current write key; dedicated writing must. Legacy writes plus legacy rejection is contradictory. Invalid present configuration is never treated as absence or fallback.
- **D-13:** Qualify operation-local failure handling under SEC-02: malformed/missing verifier configuration must fail affected reads, verifier-producing writes and maintenance clearly and without disclosure, while existing unrelated supported authentication using hashes remains available. Do not copy signing configuration's raising boot path into a surprise whole-host outage. Startup/config diagnostics must make invalid custody visible; a process surviving invalid configuration must retain an invalid state, not silently become a legacy writer. Freeze exact typed internal results and their protocol/task mappings, including missing-key errors that the existing reader does not currently match.
- **D-14:** Prefer a resolved immutable runtime context per node until restart/redeploy. Task/diagnostic resolution must label its configuration observation and must not certify a different serving-node snapshot. No hot reload API or fleet coordinator is needed. Where explicit overrides are already supported, validate a complete context rather than partially merging keys/modes with ambient values. Keep legacy endpoint selection explicit at the integration boundary; do not add ambient application scanning to dedicated crypto.
- **D-15:** Enforce unique bounded key IDs and correctly decoded 32-byte keys, reject duplicate/unknown options and malformed encodings, and compare decoded bytes for duplicate keys and known configured cross-purpose reuse. Do not claim detection of arbitrary derived keys, unknown historic keys or remote-node reuse. Prefer matching existing safe key-input conventions over inventing another encoding dialect. Phase 175 freezes exact bounds after checking currently accepted caller inputs; proposed small limits are not existing guarantees.
- **D-16:** Use a distinct canonical ASCII text envelope, provisionally `LSCV1.<key_id>.<base64url_unpadded(payload)>`, with AES-256-GCM, a fresh 12-byte IV and exactly a 16-byte tag. Authenticate an unambiguous encoding of purpose, version/header/key ID and exact canonical client-ID bytes. Reserve the dedicated family marker: malformed/unknown dedicated input must never retry as legacy. Bound input before decoding, require canonical encoding and exact structural lengths, and reject unsupported versions, substitution and trailing payload data. Leave signing-envelope bytes and semantics unchanged. Phase 175 freezes exact bytes, authenticated inner metadata and compatible size limits before runtime planning; the example is a proposal until that qualification.

### Legacy age is an explicit policy gate
- **D-17:** Qualify real persisted clients through the actual ClientAuth/lifecycle caller with fresh valid assertions and distinct JTIs. Cover usable fresh legacy, authentic aged legacy, finite age boundaries, future timestamp, malformed/wrong-key material, missing verifier, disabled/expired app, configured secret expiry before/equal/after decision time, and legacy-v0 unlimited-lifetime controls. Use the real salt/key and authenticated historical `signed_at` fixtures without changing production age options. Record exact source/dependency identities and durable side effects. Injected assertion/lifecycle time does not age Plug's wall-clock payload.
- **D-18:** Preserve the distinction between Plug 2.2.1 finite-age behavior (future timestamps invalid; expiry when deadline is strictly before its wall clock) and configured client/secret expiry (expired at equality). Never use `max_age: :infinity` as a compatibility shortcut: it also skips Plug's future-time check. A two-day-old fixture demonstrates dependency behavior through the caller, not an adopter outage.
- **D-19:** No resurrection and no silent extension of migrated legacy validity. A usable 23-hour-old row must not gain a new day or lose its age boundary merely by rewrap. Recommend retaining its original authenticated timestamp/deadline in the dedicated payload, alongside existing configured lifetime checks. High-level Plug decrypt does not expose that metadata; Phase 175 must qualify a narrowly pinned authenticated metadata reader using existing public lower-level APIs, or classify unsupported/unrecoverable rows explicitly. Do not decrypt unauthenticated terms, depend on private functions, rewrap opaque endpoint-encrypted bytes, or claim age preservation from unchanged expiry columns alone.
- **D-20:** **Material qualification gate:** Native dedicated storage-age semantics and supported historical payload shapes must receive an explicit recorded disposition in Phase 175 before Phase 176 planning. The recommended native design uses configured credential lifetime rather than perpetuating Plug's incidental one-day storage timer; migrated finite-age rows retain their original boundary. This recommendation is not silently locked as a security-policy change by this discussion. Qualify its effect on current callers/support and use an explicit GSD policy revision if required. If safe metadata extraction cannot be proved, or the proposed split cannot fit approved policy, stop dependent planning with one coherent revision recommendation. Authorized secret rotation/reprovision remains recovery; do not weaken reads to force migration success.

**D-20 owner disposition (2026-10-25):** The owner explicitly approved the recommended revision with the exact response “Approve the recommended revision.” The approved native semantics follow the configured client-secret lifetime, including `nil`/`0` and v0-unlimited clients remaining eligible beyond 24 hours while separately subject to client-app expiry. Migrated legacy credentials preserve their authenticated original finite deadline and the observed equality-valid/strict-after-expiry boundary. Unsupported future, malformed, tampered, wrong-key, unsupported-shape, and unbounded migration-age rows remain rejected unchanged, with authorized secret rotation/reprovision as recovery. Approval authorizes this policy disposition for qualification and planning; it does not authorize implementation, publication, deployment, or cleanup. The historical recommendation above remains intact. See [175-POLICY-REVISION.md](./175-POLICY-REVISION.md) for the exact approved scope and provenance.

### Store authority, preservation and truthful operations
- **D-21:** Support the built-in Ecto store and the declared existing shared-PostgreSQL delegating client/transaction adapter composition. Do not claim arbitrary backends. Direct registration/operator reads and configured DCR/rotation have asymmetric existing seams; enumerate them explicitly and prove the declared composition sees the same authoritative rows. No maintenance fallback to default Repo when the selected adapter is unsupported.
- **D-22:** Recommend an optional separately validated maintenance capability, leaving the existing lifetime contract unchanged. It must establish exhaustive bounded inventory with stable continuation/completion semantics, locked current-row authority, conditional verifier-only replacement and shared audit/transaction authority. Freeze public callback/capability/error semantics in Phase 175; ordinary internal module decomposition stays discretionary. Missing capability or mismatched authority fails before maintenance inspection/mutation rather than silently producing a partial default-store report.
- **D-23:** Under the selected transaction, use the row returned after lock wait, compare expected credential material, and never write ciphertext derived from stale unlocked material. Preserve every client field except verifier ciphertext, including hash, active state, metadata, management credentials, lifetime version/deadlines, rotation timestamps, `inserted_at` and `updated_at`; the atomic audit supplies the maintenance time. Separate actual secret rotation from custody maintenance. Conflicts, already-current results and failures are distinct. Audit failure must roll back ciphertext and successful-change audit together.
- **D-24:** Inventory all stored material, including Basic/post, inactive/expired clients, malformed and absent fields. Use bounded stable ordering rather than the ordinary name-sorted UI list. A restarted run may rescan from the beginning and skip verified current-key rows; no durable job platform is required. Partial scans, unreadable/unknown/mismatched rows and uninspected material cannot establish readiness. A database scan and local config do not certify fleet key parity, quiescence, backups or rollback safety.
- **D-25:** Freeze reader-first rollout: stage compatible code/read keys everywhere while retaining legacy writes; then explicitly activate dedicated writes. After any dedicated write, merely switching writes back does not permit old code. Retain compatible readers/keys for supported rollback; any old-code/data restoration needs separately proved compatibility. Later key retirement requires complete fresh inventory plus host-owned rollout/drain and backup/rollback disposition.
- **D-26:** Disclosure proof includes existing verifier-touching full-row reads/writes/locks, registration/DCR result structures, schema/domain Inspect, changesets, SQL diagnostics, raw query telemetry, logs, crypto/config errors, task reports, audits and protocol bodies. Use the existing sensitive-query mechanism for both logging and telemetry, plus appropriate schema/struct redaction and allowlisted errors. Neither `log: false` alone nor custom Inspect sanitizes raw telemetry/arbitrary maps. Sentinel proof must cover success and failure; do not publish sentinels/material in evidence.

### Agent's Discretion
- Choose concise qualification artifact filenames and fixture organization, reuse existing race/clean-room/helper patterns, and resolve routine implementation details within these contracts. Do not make every alternative a new dependency or reusable framework.
- Expand the finite case families in Specific Ideas into stable ledger rows, with a clear proof owner and blocker for each. No downstream implementation task count is prescribed.
- No UI redesign or new operator concept is selected. If later scoped copy changes are necessary, read `PRODUCT.md` first and use current `brandbook/` rather than the old prompt brand book.

### Folded Todos
No pending todos matched Phase 175.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and standing decisions
- `AGENTS.md`
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md` — VBASE-01/VBASE-02 and milestone boundaries.
- `.planning/ROADMAP.md` — Phase 175 acceptance and dependent-phase gates.
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/MILESTONE-GUIDE.txt`
- `.planning/DEVELOPMENT-TRAIN.md`
- `.planning/RELEASE-TRAIN.md`
- `.planning/research/v1.48-client-auth-key-isolation/BASELINE.md`
- `.planning/research/v1.48-client-auth-key-isolation/SUMMARY.md`
- `.planning/research/v1.48-client-auth-key-isolation/ARCHITECTURE.md`
- `.planning/research/v1.48-client-auth-key-isolation/STACK.md`
- `.planning/research/v1.48-client-auth-key-isolation/PITFALLS.md`
- `.planning/research/v1.48-client-auth-key-isolation/FEATURES.md`
- `docs/supported-surface.md`
- `docs/architecture.md`
- `docs/upgrading/signing-key-encryption.md`

### Existing evidence and acceptance
- `.planning/milestones/v1.47-phases/174-packaged-proof-delivery-handoff/174-DELIVERY.md`
- `.planning/milestones/v1.47-phases/174-packaged-proof-delivery-handoff/174-CONTEXT.md`
- `.planning/phases/142-merge-the-corrected-main-baseline/142-CONTEXT.md`
- `.planning/phases/143-publish-and-verify-lockspire-1-5-1/143-CONTEXT.md`
- `scripts/maintainer/repo_hygiene_check.sh`

### Actual runtime/store seams
- `lib/lockspire/clients.ex`
- `lib/lockspire/client_lifecycle.ex`
- `lib/lockspire/protocol/registration.ex`
- `lib/lockspire/admin/clients.ex`
- `lib/lockspire/security/policy.ex`
- `lib/lockspire/protocol/client_auth/client_secret_jwt.ex`
- `lib/lockspire/protocol/client_auth.ex`
- `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex`
- `lib/lockspire/domain/client.ex`
- `lib/lockspire/storage/client_store.ex`
- `lib/lockspire/storage/transaction_store.ex`
- `lib/lockspire/storage/client_lifetime.ex`
- `lib/lockspire/storage/ecto/repository/client_store.ex`
- `lib/lockspire/storage/ecto/repository/support.ex`
- `lib/lockspire/security/key_encryption.ex`
- `lib/lockspire/security/key_encryption/key_set.ex`

### Applicable prompt corpus
- `prompts/README.md`
- `prompts/lockspire-elixir-oss-library-practices.md`
- `prompts/lockspire-ecto-token-and-audit-model.md`
- `prompts/lockspire-host-app-integration-seam.md`
- `prompts/lockspire-security-posture-and-threat-model.md`
- `prompts/lockspire-release-engineering-and-ci.md`
- `prompts/lockspire-release-readiness-and-conformance.md`
- `prompts/lockspire-telemetry-audit-and-introspection.md`

### Primary external sources
- Plug.Crypto 2.2.1: https://raw.githubusercontent.com/elixir-plug/plug_crypto/v2.2.1/lib/plug/crypto.ex
- OTP 27 AEAD: https://www.erlang.org/docs/27/apps/crypto/crypto.html#crypto_one_time_aead/7
- OTP 28 AEAD and tag warning: https://www.erlang.org/docs/28/apps/crypto/crypto.html#crypto_one_time_aead/7
- PostgreSQL 14 current-row/locking semantics: https://www.postgresql.org/docs/14/transaction-iso.html and https://www.postgresql.org/docs/14/explicit-locking.html
- Ecto 3.13.5 transaction/update semantics: https://hexdocs.pm/ecto/3.13.5/Ecto.Repo.html
- Ecto field redaction: https://hexdocs.pm/ecto/3.13.5/Ecto.Schema.html#module-redacting-fields
- Ecto SQL telemetry source: https://raw.githubusercontent.com/elixir-ecto/ecto_sql/v3.13.5/lib/ecto/adapters/sql.ex
- Elixir Inspect limits: https://hexdocs.pm/elixir/1.18.4/Inspect.html
- RFC 7523: https://www.rfc-editor.org/rfc/rfc7523.html#section-3
- OIDC client authentication: https://openid.net/specs/openid-connect-core-1_0.html#ClientAuthentication
- Timestamp-preserving rotation precedent: https://cryptography.io/en/latest/fernet/#cryptography.fernet.MultiFernet.rotate
- Transitional rollout precedent: https://api.rubyonrails.org/classes/ActiveSupport/MessageVerifiers.html
- Fallback-key retention precedent: https://docs.djangoproject.com/en/5.2/ref/settings/#secret-key-fallbacks
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The existing exact-main helper and Phase 174's evidence/custody pattern establish the baseline without another acceptance API.
- `Policy` is the legacy seal/unseal seam; Plug 2.2.1 source and the prior synthetic probe inform authentic historical fixtures. The probe alone does not prove production caller behavior.
- Signing `KeyEncryption`/`KeySet` provide AEAD/config patterns; their binary format, purpose and whole-boot behavior must not be copied indiscriminately.
- Existing lifetime locks, configured transaction authority and PostgreSQL race fixtures provide maintenance proof patterns.
- Repository `Support` already suppresses both log and telemetry for sensitive calls; many existing client calls still need coverage.

### Established Patterns
- Exact identities and immutable receipt bytes distinguish historical, candidate, package and accepted-main evidence.
- Credentials have coherent hash/verifier writes and locked current-row checks; ciphertext participates in JWT authority identity.
- Client ID is currently selected after material generation in direct/DCR writers; hash-only generation unnecessarily seals discarded material.
- Legacy storage age, assertion age and configured app/secret deadlines are independent controls with different clocks and equality boundaries.
- Supported configured storage is a demonstrated shared-PostgreSQL delegation, not arbitrary datastore atomicity.

### Integration Points
- Three writer families, exported helpers and five supported direct-auth endpoint families must share the qualified custody contract.
- Existing token/grant guarded persistence and JTI consumption constrain rewrap retry semantics.
- Existing full-row SQL telemetry and unredacted nested client/result inspection constrain disclosure proof beyond new maintenance code.
</code_context>

<specifics>
## Specific Ideas

Minimum finite ledger families, expanded to stable rows during Phase 175:

| Family | Required distinctions | Proof owner |
|---|---|---|
| Baseline/custody | retained delta, fresh exact main, failed attempts, warning/resource disposition | 175 |
| Legacy/lifecycle | fresh, aged, future, boundary, malformed/wrong key, missing, expired/disabled, legacy-v0 | 175; regression 176 |
| Age transition | preserved migrated deadline, no rejuvenation, native policy disposition, unsupported historical shapes | 175 contract; 176/177 execution |
| Config/format | valid stages, absent/invalid/missing key, alias/reuse, tamper/version/size/identity/purpose, no legacy fallback | 176 |
| Writers/helpers | direct, DCR, rotation, hash-only and material helpers, coherent failure, final identity, secret handoff | 176 |
| Readers/protocol | token, introspection, revocation, device, CIBA; HS256/audience/JTI; PAR/FAPI controls | 176; package 178 |
| Rollout/rollback | old/new readers, stage keys, explicit activation, unsafe activation, pre/post-write rollback | 176; package 178 |
| Store/maintenance | declared authority/capability, unsupported zero fallback, exhaustive paging, interruption/idempotence | 177; configured package 178 |
| Races/rollback | secret rotation both orders, client edits, two rewraps, audit failure, JWT identity race/fresh retry | 177 PostgreSQL; integration 178 |
| Status/recovery | all methods/lifecycle states; absent/current/old/unknown/malformed/unreadable/uninspected; restore/rotate | 177; journey 178 |
| Disclosure | existing/new queries and structs, failures, tasks, protocol/audit/telemetry/log sentinels | 177; independent review 178 |
| Delivery | two packaged pairs, fresh/upgrade/mixed/key rotation/rejection/recovery, source identity, candidate/main distinction | 178 |

Compare alternatives where they change a real guarantee. MultiFernet's preserved timestamp and Rails' staged reader/writer transition are design precedents, not proposed dependencies. Prefer small local glue over abstractions; retain vetted cryptographic/framework primitives.
</specifics>

<deferred>
## Deferred Ideas

- Runtime implementation, rewrap tooling and package journeys remain Phases 176–178; their proof ownership is frozen here without prematurely implementing them.
- Public API breaks, broadened adapter support or changed native/legacy lifetime policy require the explicit qualification/revision gate above, not casual downstream discretion.
- KMS/Vault, hot reload/fleet coordination, durable migration-job infrastructure, generic secrets platforms, new algorithms/protocol methods, schema/signing-format changes and new dependencies are outside the approved recommendation.
- UI quality remains the next substantial milestone candidate with its completed interview preserved. No UI redesign, Storybook installation, broad grant concurrency redesign, old-worktree deletion or package publication is selected.

### Reviewed Todos (not folded)
None; no pending todo matched.
</deferred>
