# Phase 177: Safe Verifier Maintenance & Recovery - Context

**Gathered:** 2026-10-25 (assumptions mode; delegated research and recommendation synthesis)
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver safe verifier preview/apply/check, exhaustive redacted status, independent verifier-key rotation and key-loss recovery. Own VUP-03, VOPS-01–04 and VPROOF-01. Preserve partner credentials during custody-only maintenance and expose failed, conflicting, uncertain or uninspected work accurately.

Phase 176's runtime is verified. Reuse Phase 175's frozen optional maintenance capability, authority, format and approved lifetime policy. Phase 178 owns packaged journeys, final milestone review/delivery and integrated-main acceptance. This context is a design decision record, not execution or security proof.
</domain>

<decisions>
## Implementation Decisions

### Selected store and atomic maintenance
- **D-01:** Implement `Lockspire.Storage.ClientVerifierMaintenance` with the exact declarations and callback semantics in `175-CONTRACT.md`. Select the configured client store explicitly and validate its maintenance declaration, lifetime authority, selected transaction authority and client/transaction/audit participants before inventory reads or mutation. Missing or mismatched capability returns the frozen typed failure; there is no direct-Repository fallback.
- **D-02:** Process each candidate in a short transaction through the selected `TransactionStore`. The callback locks/reloads the current row, compares exact expected hash and verifier, changes only verifier ciphertext and appends one allowlisted audit event in that same outer transaction. Preserve every other persisted field, including `updated_at`, lifecycle deadlines, rotation timestamps, management material and concurrent unrelated metadata edits. Do not use ordinary client-update/secret-rotation changesets for maintenance.
- **D-03:** Report `:changed` only after outer commit. The frozen exact-replacement retry returns `:already_current` without another update/audit; changed material returns `:material_conflict`. Independently randomized overlapping rewraps may legitimately conflict. Retain committed progress across failures; retry by reading current state, without silently retrying stale authority. An indeterminate commit outcome fails completion and requires fresh reconciliation; never claim rollback merely because the caller lost its connection.
- **D-04:** Preserve ciphertext-sensitive guarded issuance: maintenance after JWT authentication invalidates the previously verified credential identity and prevents subsequent successful grant/token effects. A consumed JTI stays consumed; retry requires a fresh assertion/JTI. Prove the real maintenance race rather than reusing Phase 176's synthetic mutation as equivalent evidence.

### Authenticated custody and preserved eligibility
- **D-05:** Inspect/authenticate dedicated material and establish hash agreement before classifying it current or rewrappable. A current-looking key ID/header is insufficient. Malformed, unknown-version/key, tampered, cross-client/purpose, unsupported, future-timestamp or hash-divergent material cannot establish readiness; reserved dedicated prefixes never fall back to legacy.
- **D-06:** Dedicated-to-dedicated rewrap preserves the authenticated native/migrated discriminator and original migrated `signed_at_ms`/`deadline_ms` exactly, with a fresh IV. Authenticated, structurally valid dedicated migrated material remains eligible for custody-only rewrap after its deadline, with unchanged hash and metadata; authentication must still reject it afterward. Separate the internal authenticated custody decoder from authentication eligibility. Do not implement `open → ordinary seal`, expose plaintext, or add a public ignore-expiry switch. This clarifies maintenance semantics within the approved policy, not an extension of credential authority.
- **D-07:** Legacy promotion retains Phase 175/176's finite authenticated-age qualification and hash agreement. Aged, future, malformed, unreadable, nonpositive/infinite-age or unsupported legacy material remains unchanged and requires recovery. Do not use a timeless legacy decoder, reset age, or substitute current time. Preserve the existing distinction between migrated verifier expiry and independently enforced client/secret lifecycle expiry.
- **D-08:** A valid current-key row is inspected without rewriting it or adding an audit event. Rewrapping existing decryptable material changes encryption custody only: no partner secret replacement, hash regeneration, endpoint/session-secret change or signing-key change.

### Exhaustive status and honest readiness
- **D-09:** Inventory every persisted client row, including inactive, expired, non-JWT-method and no-verifier rows. Preserve the frozen exclusive canonical client-ID cursor, unsigned UTF-8 byte order and page contract (limits 1–500, default 100). Use identical explicit bytewise expressions in both comparison and ordering; for a UTF-8 PostgreSQL database, static `COLLATE "C"` satisfies that rule. Establish encoding assumptions explicitly or use consistent UTF-8 byte conversion. Do not inherit the host locale or signing maintenance's retired-row exemptions.
- **D-10:** Distinguish inspected legitimate absence of material from missing expected material. Public/no-secret clients with neither hash nor verifier are a valid no-material category and do not block custody retirement. A credential-bearing/JWT client missing expected material, an orphan verifier, or incoherent hash/verifier requires attention. Do not hide persisted ciphertext merely because the current authentication method does not consume it.
- **D-11:** Represent legacy/current/old-key/unknown/malformed/unreadable/uninspected states distinctly, with fixed safe reason codes and relevant authenticated safe key IDs. Distinguish custody readiness from authentication eligibility and expose expired migrated status without implying usability. An unauthenticated parsed header is never proof of key custody; avoid printing attacker-controlled diagnostic values without safe encoding.
- **D-12:** Scan completion, committed progress and requested readiness are separate report facts. Interrupted, malformed, duplicate/out-of-order, unreadable or incomplete inventory blocks readiness, as do unresolved required work/conflicts/failures. A resumed cursor is progress only. A readiness decision requires a fresh scan from nil after host-owned quiescence; cursor traversal is not a snapshot and a local check cannot establish quiescence, fleet key parity, backups or rollback safety. Page size bounds returned data/memory, not total database work or elapsed time.

### Consumer-facing tooling and configuration
- **D-13:** Provide one purpose-specific maintenance core callable from host code/release RPC without `Mix.*`, and one thin verifier-specific Mix task with the familiar default apply, `--dry-run` and `--check` modes. Use stable safe report semantics and tuple-returning expected failures. Do not overload signing-key maintenance with another custody domain, introduce Oban maintenance workers, or add dependencies.
- **D-14:** Bare Mix loads application/runtime configuration, resolves one validated operation-local verifier context plus known signing-key exclusions, then uses `RepoRunner`/`TaskError`. Preserve an already-running Repo/pool; start/stop only a task-owned Repo and clean up before rendering failure. Do not start the whole host to obtain caches. The bare task must not miss cross-purpose key reuse because signing configuration was never startup-cached.
- **D-15:** Running-node API/RPC uses the immutable startup context. A task-local context must never overwrite serving-node `persistent_term` or silently hot-reload keys from changed environment. Label whether the report observed task-local configuration or the serving node's startup context, without disclosing key material. Document release `rpc` versus an unbooted `eval` accurately.
- **D-16:** Preview is read-only and may succeed with eligible pending changes; it fails if inspection/eligibility is incomplete. Apply returns failure when requested work has unresolved conflicts, failures or uninspected remainder, while retaining committed progress. Check is read-only and succeeds only when a fresh complete inspection satisfies the current-key custody condition, including legitimate no-material rows. Successful apply alone is not permission to retire a key; run the separate fresh check and host deployment checks. Invalid/mutually exclusive arguments fail before database work.
- **D-17:** Reports expose bounded safe client identity, classifications, counts, fixed reasons and concrete next actions. Protect identifiers against terminal/control-character injection. Preserve actionable affected-client identification without returning full clients, hashes, plaintext, ciphertext, key bytes, raw errors or changesets. Prefer wording that states what was observed over an unexplained “ready.” Follow current `PRODUCT.md` and `brandbook/` over older aspirational prompts. This phase has no admin redesign; any necessary admin wording still obeys vocabulary/retired-wording contracts.

### Rotation and recovery
- **D-18:** Document and prove reader-first key rotation: distribute compatible readers and new read key to all nodes, deliberately activate the current write key, retain old read key, preview/apply/retry, obtain a fresh complete custody check after host-owned quiescence, then verify fleet/rollback/backup obligations separately before removing the old live read key. Removing a live key and destroying retained backups are different actions. Local tooling does not distribute keys or coordinate the fleet.
- **D-19:** Missing/lost-key recovery identifies affected clients and offers restoration of the valid original host-held key, or existing authorized secret rotation/reprovision under valid replacement configuration. Restoration preserves partner credentials; rotation replaces the partner secret and requires the existing secure one-time handoff. No key derivation, hash-to-secret reconstruction, automatic regeneration or fallback. Affected JWT authentication fails closed; unrelated supported methods and custody remain intact, with existing lifecycle/policy checks preserved.

### Disclosure and executable evidence
- **D-20:** Cover new maintenance and existing material-bearing paths. Add idiomatic Ecto credential-field redaction and safe domain/nested result inspection. Mark queries that bind or return verifier material sensitive, including full-client fetch/list/lock/write paths. Suppress both SQL logging and raw query telemetry at the repository seam; `log: false` alone and struct redaction alone are insufficient. Map raw Postgrex/transaction errors before any formatting/inspection. Keep audit/reports/protocol outcomes allowlisted; success telemetry follows outer commit. Preserve existing public one-time plaintext-handoff map contracts; redact nested client credential fields without replacing those maps with structs.
- **D-21:** Sentinel proof captures verifier plaintext, encryption-key bytes and ciphertext across success and forced crypto/runtime/task/storage failures: parameters/results, query telemetry, Logger/driver failures, nested schema/domain/registration/rotation inspection, audit, operator output and protocol responses. Include failed audit/outer rollback, malformed/unknown material, missing schema, connection/pool failures and hostile identifiers. `TaskError`'s caller-process logging wrapper alone is not proof. Document host-controlled instrumentation and PostgreSQL server logging boundaries without claiming Ecto options silence them or silently changing host logging policy. The intentional authorized plaintext handoff is an explicit-secret return, not a library diagnostic: deliberate caller-owned inspection of that direct map is outside the generic Inspect sentinel. All Lockspire-owned diagnostic/report paths and nested client inspection remain covered; no public return-shape change is authorized.
- **D-22:** Use actual independent PostgreSQL transactions/connections, explicit barriers and observed contender/blocker relationships for contention proof; shared sandbox ownership is not equivalent. Cover rotation-first and maintenance-first lock order, concurrent unrelated edits, audit failure, outer rollback after provisional change, exact-repeat idempotence, partial-run convergence, bytewise page boundaries, authority mismatch before access, and maintenance versus guarded issuance/fresh-JTI retry. Avoid sleep-only or “some backend waited” assertions.
- **D-23:** Reuse stable Phase 175 acceptance IDs and preserve prior receipts/history. Phase 177 proves its source-level six requirements; Phase 178 retains package-installed supported dependency pairs, supported configured-store packaged composition, final review/delivery/main acceptance. Unsupported adapters fail explicitly; no arbitrary-store claim. Design choices and structural validators do not mark pending runtime evidence passed.

### Agent's Discretion
- Module/task names, safe internal report types, exact bounded output presentation, internal decoder factoring and deterministic test harness details, within the frozen public callback/security/support contract.
- Prefer small auditable local glue and existing OTP/Plug/Ecto primitives; no schema, dependency, algorithm or protocol expansion is selected.
- User delegated research, adversarial comparison, synthesis and adoption of coherent recommendations in the follow-up fan-out prompt. Resolve routine choices without another preference interview. Escalate only a demonstrated conflict with approved policy, public API/support boundary or phase scope.

### Folded Todos
None; todo matching returned zero pending todos.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and qualified policy
- `AGENTS.md`
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/MILESTONE-GUIDE.txt`
- `.planning/DEVELOPMENT-TRAIN.md`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTEXT.md`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTRACT.md`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-POLICY-REVISION.md`
- `.planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-COMPATIBILITY.json`
- `.planning/phases/176-dedicated-verifier-custody-compatible-runtime/176-CONTEXT.md`
- `.planning/phases/176-dedicated-verifier-custody-compatible-runtime/176-VERIFICATION.md`
- `.planning/phases/176-dedicated-verifier-custody-compatible-runtime/176-HANDOFF.md`
- `.planning/research/v1.48-client-auth-key-isolation/SUMMARY.md`
- `.planning/research/v1.48-client-auth-key-isolation/ARCHITECTURE.md`
- `.planning/research/v1.48-client-auth-key-isolation/PITFALLS.md`

### Runtime, storage and tooling
- `lib/lockspire/security/client_secret_verifier.ex`
- `lib/lockspire/security/client_secret_verifier/context.ex`
- `lib/lockspire/security/client_secret_verifier/legacy.ex`
- `lib/lockspire/config.ex`
- `lib/lockspire/application.ex`
- `lib/lockspire/clients.ex`
- `lib/lockspire/admin/clients.ex`
- `lib/lockspire/client_lifecycle.ex`
- `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex`
- `lib/lockspire/storage/client_store.ex`
- `lib/lockspire/storage/client_lifetime.ex`
- `lib/lockspire/storage/transaction_store.ex`
- `lib/lockspire/storage/ecto/repository/client_store.ex`
- `lib/lockspire/storage/ecto/repository/transaction_store.ex`
- `lib/lockspire/storage/ecto/repository/support.ex`
- `lib/lockspire/storage/ecto/client_record.ex`
- `lib/lockspire/domain/client.ex`
- `lib/lockspire/clients/registration_result.ex`
- `lib/lockspire/admin/keys/reencrypt.ex`
- `lib/mix/tasks/lockspire.keys.reencrypt.ex`
- `lib/lockspire/install/repo_runner.ex`
- `lib/lockspire/install/task_error.ex`
- `docs/client-secret-verifier-configuration.md`
- `docs/client-secret-jwt-host-guide.md`
- `docs/supported-surface.md`

### Proof precedents and consumer context
- `test/lockspire/storage/reencrypt_concurrency_test.exs`
- `test/integration/client_secret_verifier_guarded_issuance_test.exs`
- `test/integration/client_secret_jwt_legacy_age_test.exs`
- `test/clean_room/provider_host/lib/clean_room_provider/lifetime_client_store.ex`
- `PRODUCT.md`
- `brandbook/README.md`
- `prompts/README.md`
- `prompts/lockspire-elixir-oss-library-practices.md`
- `prompts/lockspire-ecto-token-and-audit-model.md`
- `prompts/lockspire-security-posture-and-threat-model.md`
- `prompts/lockspire-telemetry-audit-and-introspection.md`
- `prompts/lockspire-host-app-integration-seam.md`

### Primary-source rationale
- [PostgreSQL 14 collations](https://www.postgresql.org/docs/14/collation.html) — comparison and ordering must share bytewise semantics.
- [PostgreSQL 14 isolation](https://www.postgresql.org/docs/14/transaction-iso.html) — updated row after READ COMMITTED lock wait.
- [Ecto SQL 3.13.5 source](https://github.com/elixir-ecto/ecto_sql/blob/v3.13.5/lib/ecto/adapters/sql.ex#L1265-L1354) — independent query logging and raw telemetry channels.
- [Ecto 3.13.6 Repo source](https://github.com/elixir-ecto/ecto/blob/v3.13.6/lib/ecto/repo.ex) — verifier-only update and timestamp behavior.
- [Postgrex 0.22.4 error source](https://github.com/elixir-ecto/postgrex/blob/v0.22.4/lib/postgrex/error.ex) — raw diagnostics must not reach reports.
- [DBConnection 2.10.2 source](https://github.com/elixir-ecto/db_connection/blob/v2.10.2/lib/db_connection/connection.ex#L143-L164) — separate driver logging boundary.
- [Fernet 46.0.3](https://cryptography.io/en/46.0.3/fernet/) and [implementation](https://raw.githubusercontent.com/pyca/cryptography/46.0.3/src/cryptography/fernet.py) — timestamp-preserving custody rotation precedent; no dependency adoption.
- [Vault transit rewrap](https://developer.hashicorp.com/vault/api-docs/secret/transit#rewrap-data) — custody operation and per-item failures; no Vault integration.
- [Mix app.config](https://hexdocs.pm/mix/1.19.5/Mix.Tasks.App.Config.html) and [release](https://hexdocs.pm/mix/1.19.5/Mix.Tasks.Release.html) — runtime config versus startup and running-node RPC.
- [PostgreSQL 14 logging](https://www.postgresql.org/docs/14/runtime-config-logging.html) — host-controlled server logging boundary.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Signing `Reencrypt`, Mix task, `RepoRunner` and `TaskError` establish per-row transaction, post-commit events and resource ownership patterns. Reuse them selectively: signing retired-row exemptions and unpaged preview are unsuitable here.
- Existing dedicated verifier/legacy modules already authenticate format, bind identity/purpose, qualify legacy metadata and compare hash on migration preparation. A metadata-preserving dedicated maintenance path is still needed.
- `ClientLifetime` validates selected authority; the clean-room delegated store demonstrates the sole supported shared-PostgreSQL composition, not arbitrary custom stores.

### Established Patterns
- `Config.client_secret_verifier_context/0` depends on startup cache; signing forbidden bytes also depend on startup resolution. `app.config` alone does not populate either cache. Bare task resolution must remain local.
- `open/4` returns only secret and applies authentication expiry; ordinary `seal/3` creates native age data. Their composition cannot safely rewrap migrated material.
- Public client creation intentionally emits nil hash/verifier. Existing list ordering and filters cannot implement the exhaustive maintenance page contract.
- Full-client query paths and schema/domain/nested result inspection require disclosure hardening; safe final CLI strings alone do not close SQL/raw-result channels.

### Integration Points
- Add optional maintenance capability to selected Ecto client/transaction/audit composition; prove lock/reload/CAS and outer commit together.
- Connect custody inspection to safe reports and callable/Mix operations; retain existing authorized rotation for replacement recovery.
- Keep ciphertext fingerprint/replay behavior and endpoint/lifetime checks intact during maintenance races.
</code_context>

<specifics>
## Specific Ideas

- Owner requested broad/deep subagent research, reputable primary sources, adversarial tradeoffs, relevant prompt-corpus evidence, coherent one-shot defaults and automatic adoption; smaller flatter dependencies are preferred.
- Four scoped analyses covered existing code/assumptions, PostgreSQL/Ecto/concurrency, custody/recovery/security and Elixir/operator DX/disclosure. Stop further fan-out: remaining uncertainty requires executable implementation proof, not more preference questions.
- Methodology applied: assumption-first and research-first defaults, least-surprise host seam, high-threshold escalation and coherent recommendation bundles. These flagged bare-Mix cache dependence, expired dedicated custody semantics, legitimate no-material clients, locale-dependent cursors and pre-existing disclosure paths.
</specifics>

<deferred>
## Deferred Ideas

- Phase 178 package-installed journeys on supported dependency pairs and configured composition, final audit/security/code review, CI/delivery and accepted-main handoff; package publication remains separate.
- Broad UI work, Storybook, KMS/Vault, fleet coordination/hot reload, generic secrets architecture, new schema/dependencies/algorithms/auth methods and automatic secret replacement remain outside scope.
- New maintenance indexes or scale machinery need measured evidence; byte-order query correctness is required now.
- UI quality remains the next substantial milestone with its completed Q1–Q10 interview preserved. OPS-03 and KEK-04 retain their evidence triggers.

### Reviewed Todos (not folded)
None; no pending todo matched.
</deferred>
