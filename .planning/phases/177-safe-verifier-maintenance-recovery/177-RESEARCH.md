# Phase 177: Safe Verifier Maintenance & Recovery - Research

**Researched:** 2026-10-25
**Domain:** Elixir OTP maintenance operations, verifier custody, PostgreSQL/Ecto transactions and disclosure controls
**Confidence:** HIGH for frozen contract and current code seams; MEDIUM for implementation approach pending executable Phase 177 proof

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Implement `Lockspire.Storage.ClientVerifierMaintenance` with the exact declarations and callback semantics in `175-CONTRACT.md`. Select the configured client store explicitly and validate its maintenance declaration, lifetime authority, selected transaction authority and client/transaction/audit participants before inventory reads or mutation. Missing or mismatched capability returns the frozen typed failure; there is no direct-Repository fallback.
- **D-02:** Process each candidate in a short transaction through the selected `TransactionStore`. The callback locks/reloads the current row, compares exact expected hash and verifier, changes only verifier ciphertext and appends one allowlisted audit event in that same outer transaction. Preserve every other persisted field, including `updated_at`, lifecycle deadlines, rotation timestamps, management material and concurrent unrelated metadata edits. Do not use ordinary client-update/secret-rotation changesets for maintenance.
- **D-03:** Report `:changed` only after outer commit. The frozen exact-replacement retry returns `:already_current` without another update/audit; changed material returns `:material_conflict`. Independently randomized overlapping rewraps may legitimately conflict. Retain committed progress across failures; retry by reading current state, without silently retrying stale authority. An indeterminate commit outcome fails completion and requires fresh reconciliation; never claim rollback merely because the caller lost its connection.
- **D-04:** Preserve ciphertext-sensitive guarded issuance: maintenance after JWT authentication invalidates the previously verified credential identity and prevents subsequent successful grant/token effects. A consumed JTI stays consumed; retry requires a fresh assertion/JTI. Prove the real maintenance race rather than reusing Phase 176's synthetic mutation as equivalent evidence.
- **D-05:** Inspect/authenticate dedicated material and establish hash agreement before classifying it current or rewrappable. A current-looking key ID/header is insufficient. Malformed, unknown-version/key, tampered, cross-client/purpose, unsupported, future-timestamp or hash-divergent material cannot establish readiness; reserved dedicated prefixes never fall back to legacy.
- **D-06:** Dedicated-to-dedicated rewrap preserves the authenticated native/migrated discriminator and original migrated `signed_at_ms`/`deadline_ms` exactly, with a fresh IV. Authenticated, structurally valid dedicated migrated material remains eligible for custody-only rewrap after its deadline, with unchanged hash and metadata; authentication must still reject it afterward. Separate the internal authenticated custody decoder from authentication eligibility. Do not implement `open → ordinary seal`, expose plaintext, or add a public ignore-expiry switch. This clarifies maintenance semantics within the approved policy, not an extension of credential authority.
- **D-07:** Legacy promotion retains Phase 175/176's finite authenticated-age qualification and hash agreement. Aged, future, malformed, unreadable, nonpositive/infinite-age or unsupported legacy material remains unchanged and requires recovery. Do not use a timeless legacy decoder, reset age, or substitute current time. Preserve the existing distinction between migrated verifier expiry and independently enforced client/secret lifecycle expiry.
- **D-08:** A valid current-key row is inspected without rewriting it or adding an audit event. Rewrapping existing decryptable material changes encryption custody only: no partner secret replacement, hash regeneration, endpoint/session-secret change or signing-key change.
- **D-09:** Inventory every persisted client row, including inactive, expired, non-JWT-method and no-verifier rows. Preserve the frozen exclusive canonical client-ID cursor, unsigned UTF-8 byte order and page contract (limits 1–500, default 100). Use identical explicit bytewise expressions in both comparison and ordering; for a UTF-8 PostgreSQL database, static `COLLATE "C"` satisfies that rule. Establish encoding assumptions explicitly or use consistent UTF-8 byte conversion. Do not inherit the host locale or signing maintenance's retired-row exemptions.
- **D-10:** Distinguish inspected legitimate absence of material from missing expected material. Public/no-secret clients with neither hash nor verifier are a valid no-material category and do not block custody retirement. A credential-bearing/JWT client missing expected material, an orphan verifier, or incoherent hash/verifier requires attention. Do not hide persisted ciphertext merely because the current authentication method does not consume it.
- **D-11:** Represent legacy/current/old-key/unknown/malformed/unreadable/uninspected states distinctly, with fixed safe reason codes and relevant authenticated safe key IDs. Distinguish custody readiness from authentication eligibility and expose expired migrated status without implying usability. An unauthenticated parsed header is never proof of key custody; avoid printing attacker-controlled diagnostic values without safe encoding.
- **D-12:** Scan completion, committed progress and requested readiness are separate report facts. Interrupted, malformed, duplicate/out-of-order, unreadable or incomplete inventory blocks readiness, as do unresolved required work/conflicts/failures. A resumed cursor is progress only. A readiness decision requires a fresh scan from nil after host-owned quiescence; cursor traversal is not a snapshot and a local check cannot establish quiescence, fleet key parity, backups or rollback safety. Page size bounds returned data/memory, not total database work or elapsed time.
- **D-13:** Provide one purpose-specific maintenance core callable from host code/release RPC without `Mix.*`, and one thin verifier-specific Mix task with the familiar default apply, `--dry-run` and `--check` modes. Use stable safe report semantics and tuple-returning expected failures. Do not overload signing-key maintenance with another custody domain, introduce Oban maintenance workers, or add dependencies.
- **D-14:** Bare Mix loads application/runtime configuration, resolves one validated operation-local verifier context plus known signing-key exclusions, then uses `RepoRunner`/`TaskError`. Preserve an already-running Repo/pool; start/stop only a task-owned Repo and clean up before rendering failure. Do not start the whole host to obtain caches. The bare task must not miss cross-purpose key reuse because signing configuration was never startup-cached.
- **D-15:** Running-node API/RPC uses the immutable startup context. A task-local context must never overwrite serving-node `persistent_term` or silently hot-reload keys from changed environment. Label whether the report observed task-local configuration or the serving node's startup context, without disclosing key material. Document release `rpc` versus an unbooted `eval` accurately.
- **D-16:** Preview is read-only and may succeed with eligible pending changes; it fails if inspection/eligibility is incomplete. Apply returns failure when requested work has unresolved conflicts, failures or uninspected remainder, while retaining committed progress. Check is read-only and succeeds only when a fresh complete inspection satisfies the current-key custody condition, including legitimate no-material rows. Successful apply alone is not permission to retire a key; run the separate fresh check and host deployment checks. Invalid/mutually exclusive arguments fail before database work.
- **D-17:** Reports expose bounded safe client identity, classifications, counts, fixed reasons and concrete next actions. Protect identifiers against terminal/control-character injection. Preserve actionable affected-client identification without returning full clients, hashes, plaintext, ciphertext, key bytes, raw errors or changesets. Prefer wording that states what was observed over an unexplained “ready.” Follow current `PRODUCT.md` and `brandbook/` over older aspirational prompts. This phase has no admin redesign; any necessary admin wording still obeys vocabulary/retired-wording contracts.
- **D-18:** Document and prove reader-first key rotation: distribute compatible readers and new read key to all nodes, deliberately activate the current write key, retain old read key, preview/apply/retry, obtain a fresh complete custody check after host-owned quiescence, then verify fleet/rollback/backup obligations separately before removing the old live read key. Removing a live key and destroying retained backups are different actions. Local tooling does not distribute keys or coordinate the fleet.
- **D-19:** Missing/lost-key recovery identifies affected clients and offers restoration of the valid original host-held key, or existing authorized secret rotation/reprovision under valid replacement configuration. Restoration preserves partner credentials; rotation replaces the partner secret and requires the existing secure one-time handoff. No key derivation, hash-to-secret reconstruction, automatic regeneration or fallback. Affected JWT authentication fails closed; unrelated supported methods and custody remain intact, with existing lifecycle/policy checks preserved.
- **D-20:** Cover new maintenance and existing material-bearing paths. Add idiomatic Ecto credential-field redaction and safe domain/nested result inspection. Mark queries that bind or return verifier material sensitive, including full-client fetch/list/lock/write paths. Suppress both SQL logging and raw query telemetry at the repository seam; `log: false` alone and struct redaction alone are insufficient. Map raw Postgrex/transaction errors before any formatting/inspection. Keep audit/reports/protocol outcomes allowlisted; success telemetry follows outer commit.
- **D-21:** Sentinel proof captures verifier plaintext, encryption-key bytes and ciphertext across success and forced crypto/runtime/task/storage failures: parameters/results, query telemetry, Logger/driver failures, nested schema/domain/registration/rotation inspection, audit, operator output and protocol responses. Include failed audit/outer rollback, malformed/unknown material, missing schema, connection/pool failures and hostile identifiers. `TaskError`'s caller-process logging wrapper alone is not proof. Document host-controlled instrumentation and PostgreSQL server logging boundaries without claiming Ecto options silence them or silently changing host logging policy.
- **D-22:** Use actual independent PostgreSQL transactions/connections, explicit barriers and observed contender/blocker relationships for contention proof; shared sandbox ownership is not equivalent. Cover rotation-first and maintenance-first lock order, concurrent unrelated edits, audit failure, outer rollback after provisional change, exact-repeat idempotence, partial-run convergence, bytewise page boundaries, authority mismatch before access, and maintenance versus guarded issuance/fresh-JTI retry. Avoid sleep-only or “some backend waited” assertions.
- **D-23:** Reuse stable Phase 175 acceptance IDs and preserve prior receipts/history. Phase 177 proves its source-level six requirements; Phase 178 retains package-installed supported dependency pairs, supported configured-store packaged composition, final review/delivery/main acceptance. Unsupported adapters fail explicitly; no arbitrary-store claim. Design choices and structural validators do not mark pending runtime evidence passed.

### the agent's Discretion

- Module/task names, safe internal report types, exact bounded output presentation, internal decoder factoring and deterministic test harness details, within the frozen public callback/security/support contract.
- Prefer small auditable local glue and existing OTP/Plug/Ecto primitives; no schema, dependency, algorithm or protocol expansion is selected.
- User delegated research, adversarial comparison, synthesis and adoption of coherent recommendations in the follow-up fan-out prompt. Resolve routine choices without another preference interview. Escalate only a demonstrated conflict with approved policy, public API/support boundary or phase scope.

### Deferred Ideas (OUT OF SCOPE)

- Phase 178 package-installed journeys on supported dependency pairs and configured composition, final audit/security/code review, CI/delivery and accepted-main handoff; package publication remains separate.
- Broad UI work, Storybook, KMS/Vault, fleet coordination/hot reload, generic secrets architecture, new schema/dependencies/algorithms/auth methods and automatic secret replacement remain outside scope.
- New maintenance indexes or scale machinery need measured evidence; byte-order query correctness is required now.
- UI quality remains the next substantial milestone with its completed Q1–Q10 interview preserved. OPS-03 and KEK-04 retain their evidence triggers.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VUP-03 | Host operator can introduce a new verifier key, rewrap existing material and retire an old key without changing partner secrets, endpoint/session secrets or signing-key custody. | Reader-first staging/activation/rewrap and separate fresh retirement check. |
| VOPS-01 | Maintainer can preview, apply and check verifier rewrap through repo-safe tooling that is idempotent, reports partial failures/conflicts and returns a failing outcome when the requested completion/readiness condition is not met. | Mix-free core, thin task, local context, RepoRunner and explicit report facts. |
| VOPS-02 | Host can rewrap through its supported client/transaction store without overwriting concurrent secret rotation or client updates; ciphertext and audit commit atomically while hashes, expiry, rotation timestamps and other client fields remain unchanged. | Frozen optional capability, authority preflight, lock/reload/CAS and real PostgreSQL proof. |
| VOPS-03 | Operator can inspect redacted status for all stored verifier material, including inactive/expired and non-JWT-method clients; unknown, malformed, unreadable or uninspected rows cannot be presented as ready, and local status does not claim fleet-wide configuration parity. | Bytewise cursor, authenticated classification, complete scan vs readiness. |
| VOPS-04 | Operator can identify affected clients after missing/lost-key failure and recover through restoring a valid key or the existing authorized secret-rotation/reprovision path, while affected JWT authentication fails closed and unrelated supported authentication remains intact. | Safe report IDs, fail-closed JWT and existing recovery seam. |
| VPROOF-01 | Security reviewer can verify that verifier plaintext, encryption keys and ciphertext stay out of logs, SQL diagnostics, telemetry, audit, operator reports and protocol responses across success and failure paths. | Inspect redaction, dual query-channel suppression, error mapping, sentinel tests. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Lockspire remains a separate embedded companion library; do not make it a Sigra module or required standalone service.
- Preserve strong boundaries between protocol core, storage, generators, Plug/Phoenix integration and LiveView/admin. Keep host-owned policy and UX outside this maintenance capability.
- Do not expand v1 into SAML, LDAP/AD federation, hosted auth or a full CIAM suite.
- Preserve project stack declarations: Phoenix 1.8.5, LiveView 1.1.28, Ecto SQL 3.13.5, PostgreSQL 14+, Oban 2.21.x and OpenTelemetry 1.6.0. This phase adds no dependency.
- Preserve secure defaults and isolate verifier custody changes from endpoint/session secrets and signing-key custody; redact credentials from operator and diagnostic surfaces.
- No admin UI redesign is in this phase. If any admin wording changes become necessary, read PRODUCT.md persona/vocabulary guidance, use its UI-says terms and maintain the retired-wording table.
- Keep phase decisions aligned with .planning/PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md and research/SUMMARY.md.

## Summary

The maintenance API and storage adapter are new; LSCV1 crypto, client/transaction stores, authority declarations, RepoRunner/TaskError, signing re-encrypt task and guarded issuance seam already exist. Implement the frozen optional ClientVerifierMaintenance capability without direct Repository fallback. Preflight selected client/lifetime/transaction/audit authority before reads. Each apply item must lock and reload, CAS exact expected hash plus verifier, update only ciphertext and add allowlisted audit within the same selected outer transaction. Report changed only after commit. [VERIFIED: 175-CONTRACT.md; lib/lockspire/storage/client_store.ex:10-25; lib/lockspire/storage/transaction_store.ex:8-19]

Use a dedicated authenticated custody inspection/rewrap path. Existing open/4 enforces authentication age; ordinary seal creates native age metadata. Thus open then seal either blocks custody work on expired migrated values or resets authenticated metadata. Verify envelope identity/purpose and hash agreement, preserve native/migrated discriminator and exact migrated timestamps/deadline, and reseal with fresh IV. Keep authentication expiry unchanged. [VERIFIED: lib/lockspire/security/client_secret_verifier.ex:19-34,63-97,228-248,291-313]

Recommended plan shape: first trace one actual persisted rewrap from caller through selected capability/transaction/audit and issuance guard; establish contract/classifier and exact postcommit semantics with runtime evidence. Then add exhaustive inventory/status and bytewise paging; add task/runtime config and retry/report semantics; finish with lost-key recovery, sentinel disclosure closure, both contention lock orders, rollback and final focused/full suites. Independent PostgreSQL connections and explicit barriers are mandatory. No dependencies, schema/protocol change, or Phase 178 package proof.

**Primary recommendation:** one purpose-specific Mix-free core over the declared capability, plus a thin task; require fresh complete authenticated inspection for readiness.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Verifier custody decode/rewrap | API / Backend | — | Authenticates format, AAD, hash agreement and preserved metadata. |
| Inventory/CAS/audit | Database / Storage | API / Backend | Selected adapter owns cursor, lock, verifier-only write and atomic audit. |
| Preview/apply/check report | API / Backend | Database / Storage | Core coordinates safe report and derives readiness from committed/inventory evidence. |
| Mix task and bare Repo lifecycle | API / Backend | — | Thin task delegates to core and RepoRunner/TaskError. |
| Running RPC vs bare-Mix context | API / Backend | Host operations | Serving node uses immutable startup snapshot; bare task uses local config without mutating persistent_term. |
| Fleet rotation and key-loss recovery | API / Backend | Host operations | Local rewrap/recovery path is Lockspire scope; distribution/quiescence/backup/rollback are host duties. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / OTP | 1.19.5 / OTP 28.5 | OTP, Mix task, :crypto and concurrency tests | Proven project runtime. Source declares `elixir: "~> 1.18"` and no new runtime is needed. [VERIFIED: mix.exs:9-16,43-75; local runtime probe] |
| Ecto SQL | 3.13.5 declared | SQL, row locks, transaction and Repo options | Existing adapter; source says `{:ecto_sql, "~> 3.13.5"}`. [VERIFIED: mix.exs:50-76] |
| PostgreSQL | 14+ | Contention, atomic audit, bytewise keyset inventory | Existing project support. PG docs say collation controls ordering and comparison; READ COMMITTED locking requires reload/CAS after wait. [CITED: PostgreSQL 14 collation](https://www.postgresql.org/docs/14/collation.html), [transaction isolation](https://www.postgresql.org/docs/14/transaction-iso.html) |
| Erlang :crypto AES-256-GCM | Existing implementation | Authenticated envelope custody operation | Existing LSCV1; do not add crypto package or format. [VERIFIED: lib/lockspire/security/client_secret_verifier.ex:8-17,26-34] |

### Supporting

| Module | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ClientStore / TransactionStore | Internal v1 | Selected store, lifetime and transaction authority | Preflight optional capability and wrap each per-row mutation. |
| RepoRunner / TaskError | Internal | Preserve running Repo; safely manage temporary Repo/task failures | Reuse under new thin Mix task. |
| Ecto Query/PostgreSQL locks | Existing | Exclusive bytewise page and row CAS | Use identical explicit bytewise collation in comparison and order. |
| ExUnit and PostgreSQL | Existing | Unit and persisted integration | Separate pure classifier assertions from independent connection proof. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Maintenance capability | Ordinary update/rotation callback | Ordinary changesets own hashes, expiry and timestamps, so cannot implement verifier-only CAS/audit. |
| Selected TransactionStore | Direct Repository call | Bypasses selected supported composition and authority validation. |
| Custody decoder | open/4 then seal | Enforces auth deadline and resets migrated metadata. |
| Per-row transactions | One transaction across whole scan | Long locks and broad rollback; loses committed partial progress. |
| Bytewise cursor | UI list/offset paging | Filtered/name order differs; locale semantics can omit/repeat IDs. |
| Host checks | Fleet worker/KMS | New dependencies/scope; cannot derive fleet state locally. |

**Installation:** None. No external package is needed.

**Package Legitimacy Audit:** Not applicable.

## Architecture Patterns

### System Architecture Diagram

    Release RPC ─→ immutable serving-node context ─┐
    Bare Mix ─→ app.config + validated local context ─┤
                                                    ↓
    Core: validate args → selected capability/authority → operation mode
       ├─ preview/check → full page scan → authenticated classify/hash check → safe report
       └─ apply → page → selected transaction → lock/reload → exact CAS
                                      → ciphertext-only update + audit → commit → changed event
                                                    ↓
    fresh full check → host-owned quiescence/fleet/backup/rollback checks → retire live old key

### Recommended Project Structure

    lib/lockspire/storage/client_verifier_maintenance.ex
    lib/lockspire/admin/client_verifier_maintenance.ex
    lib/lockspire/security/client_secret_verifier/maintenance.ex
    lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex
    lib/mix/tasks/lockspire.clients.verifier.rewrap.ex
    test/lockspire/security/client_secret_verifier_maintenance_test.exs
    test/lockspire/storage/client_verifier_maintenance_test.exs
    test/lockspire/admin/client_verifier_maintenance_test.exs
    test/integration/client_secret_verifier_maintenance_test.exs
    test/integration/client_secret_verifier_maintenance_disclosure_test.exs
    test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs

Names are discretionary. Keep crypto, storage, operation/report and task boundaries distinct.

### Pattern 1: Capability preflight and per-row atomic write

Preflight selected client/lifetime/transaction/audit contract before page access. For each row use selected TransactionStore to lock/reload, exact-compare expected hash and ciphertext, update only verifier ciphertext and append allowlisted audit. Map changed only after outer commit. Exact outcomes in 175-CONTRACT are `:changed`, `:already_current`, `:material_conflict`. Existing ordinary rotation writes hash, verifier, rotation time and timestamps, so is not reusable. [VERIFIED: 175-CONTRACT.md; lib/lockspire/storage/ecto/repository/client_store.ex:186-227; client_record.ex:301-315]

### Pattern 2: Shared authenticated custody classifier

All rows, even inactive, expired, public/no-secret or non-JWT rows, pass one classifier. Authenticate AEAD/client/purpose, verify hash agreement, then distinguish legitimate no material; eligible legacy; current/old key; expired migrated custody; unknown; malformed/tampered; hash-divergent; unreadable; or missing expected data. Keep authentication eligibility and custody readiness separate. Existing open applies age; migrated sealing stores its own timestamps. [VERIFIED: lib/lockspire/security/client_secret_verifier.ex:63-97,228-248,291-313]

### Pattern 3: Separate completion, progress, readiness

Track scan completion, committed apply work, and requested readiness independently. A fresh check starts from nil cursor. Any incomplete/uninspected/error/conflict state blocks a requested complete outcome. Cursor continuation is not a snapshot, and local status does not imply fleet parity.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Envelope or key derivation | New algorithm/dependency/plaintext side path | LSCV1 plus internal authenticated metadata-preserving operation | Format/AAD and crypto constraints frozen. |
| Transaction authority | Direct Repo or callback heuristic | Declared capability + selected lifetime/transaction authority validation | Callback existence does not prove same rollback domain. |
| Secret recovery | Hash reversal/automatic replacement | Restore valid original key or authorized rotation/reprovision | Partner secret not recoverable from hash; existing one-time handoff applies. |
| Fleet readiness | Local coordinator | Fresh local check plus host deployment checks | One node cannot attest fleet, backup or rollback. |
| Disclosure | Struct redaction/process log level alone | Safe Inspect + sensitive query Logger/telemetry + error mapping + sentinels | Query telemetry and connection-process logging are independent. |

**Key insight:** Security depends on the full authenticated read → locked compare → atomic ciphertext/audit commit → redacted evidence path, not just safe CLI prose.

## Common Pitfalls

1. **Using auth decoder as custody decoder.** open/4 rejects expired migrated data and seal/3 resets its age classification. Separate authenticated custody parsing from auth eligibility. Warning: open then ordinary seal.
2. **Reporting before outer commit.** Nested success may roll back or be indeterminate. Emit changed/success telemetry after selected outer transaction; uncertain connection loss requires reconciliation, not rollback claims.
3. **Stale or broad writes.** Reusing inventory row or rotation changeset overwrites concurrent updates and changes deadlines/timestamps. Lock/reload, exact CAS and verifier-only write. Assert unrelated fields byte/value-equal.
4. **Header-only readiness.** Parsed key id is attacker-controlled until AEAD and hash verification succeeds.
5. **Mismatched pagination collation.** PostgreSQL applies collation to both ordering and comparison. Apply identical explicit bytewise expression to cursor and ORDER BY; test non-ASCII boundary. [CITED: https://www.postgresql.org/docs/14/collation.html]
6. **Cursor-as-snapshot/fleet proof.** Separate scan completion, committed progress and readiness; fresh nil-cursor check after host quiescence; host owns parity/backups/rollback.
7. **One-channel redaction.** log false, TaskError or Struct Inspect is not enough. Suppress logger+telemetry, redact Ecto/domain/nested Inspect, map raw DB errors before formatting, test sentinels; document host/DB logging.
8. **Key-loss auto-rotation.** Restoration preserves partner secret; otherwise use authorized rotation and one-time handoff. Affected JWT stays fail-closed.

## Code Examples

Existing selected transaction callback contract (verbatim):

    @callback transaction_authority() :: %{
                required(:identity) => term(),
                required(:participants) => %{required(atom()) => module()}
              }
    @callback transact((-> term())) :: {:ok, term()} | {:error, store_error()}
    @callback rollback(store_error()) :: no_return()

Source: [VERIFIED: lib/lockspire/storage/transaction_store.ex:8-19]. Maintenance callbacks remain the separate frozen declarations from 175-CONTRACT.

Existing sensitive query seam (verbatim):

    def repo_options(opts `\\` []) do
      opts
      |> Keyword.drop([:sensitive])
      |> maybe_disable_sensitive_logging(opts)
      |> Keyword.merge(Lockspire.Storage.Ecto.Prefix.prefix_opts())
    end
    defp maybe_disable_sensitive_logging(options, opts) do
      if Keyword.get(opts, :sensitive, false) do
        options |> Keyword.put(:log, false) |> Keyword.put(:telemetry_event, nil)
      else
        options
      end
    end

Source: [VERIFIED: lib/lockspire/storage/ecto/repository/support.ex:32-49]. Suppress both channels on every query binding/returning verifier bytes.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Legacy verifier implicit Plug age | Dedicated LSCV1; native policy follows configured secret lifetime, migrated retains original deadline | Phases 175–176 | Separate custody from auth expiry. |
| Signing-key scan/exemptions | Exhaustive client inventory and legitimate no-material distinction | Phase 177 | Do not reuse signing semantics uncritically. |
| Synthetic mutation race | Actual PostgreSQL maintenance race | Phase 177 | Needs independent transactions and fresh-JTI proof. |
| log false as total suppression | Query Logger and telemetry are separate | Ecto SQL 3.13.5 | Suppress and test both. [CITED: https://github.com/elixir-ecto/ecto_sql/blob/v3.13.5/lib/ecto/adapters/sql.ex#L1265-L1354] |

**Deprecated/outdated:** open then seal for custody; UI list/signing scan for verifier inventory; task log level as sole disclosure control.

## Runtime State Inventory

Not a rename/refactor/migration phase.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Build and ExUnit | Yes | 1.19.5 | Proven asdf prefix. |
| Erlang/OTP | Runtime/:crypto | Yes | 28.5 | None. |
| PostgreSQL | Persisted contention/rollback | Yes | pg_isready: /tmp:5432 accepting connections | None for contention proof. |
| psql | Test DB setup | Yes | 14.17 | Project Mix setup. |

No test command was run during research. Proven command prefix:

    ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration <focused files>

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit; SQL Sandbox for normal tests, tagged PostgreSQL integration for persisted proof |
| Config file | config/test.exs; test/test_helper.exs; test.setup alias |
| Quick run command | ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/security/client_secret_verifier_test.exs |
| Focused integration | ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_test.exs |
| Full integration | ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test.integration |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VUP-03 | Stage/activate/rewrap/retirement boundary | Integration/docs | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_test.exs` | No — add |
| VOPS-01 | Modes, args, exit outcomes, Repo lifecycle and local config | Unit + Mix task | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/admin/client_verifier_maintenance_test.exs test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` | No — add |
| VOPS-02 | Authority, CAS, field preservation, atomic audit, lock orders | PostgreSQL integration | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_test.exs` | No — add |
| VOPS-03 | Every row class, bytewise boundaries, completeness/readiness | Unit + integration | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/storage/client_verifier_maintenance_test.exs` | No — add |
| VOPS-04 | Key loss, restoration/rotation, JWT fail-closed, unrelated auth | Integration | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_test.exs` | No — add |
| VPROOF-01 | Sentinels absent in Logger/telemetry/errors/Inspect/audit/task/protocol | Unit + integration | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_disclosure_test.exs` | No — add |

### Sampling Rate

- **Per task commit:** Focused classifier/store/task unit tests.
- **Per wave merge:** PostgreSQL integration and independent-connection cases for that wave.
- **Phase gate:** Full integration plus existing verifier config/envelope/guarded-issuance regressions. Package-installed pairs stay Phase 178.

### Wave 0 Gaps

- [ ] test/lockspire/security/client_secret_verifier_maintenance_test.exs — authenticated custody, age preservation, expired migrated rewrap, legacy age/hash.
- [ ] test/lockspire/storage/client_verifier_maintenance_test.exs — authority preflight, typed capability, page bounds/order.
- [ ] test/lockspire/admin/client_verifier_maintenance_test.exs — mode/report semantics and retry convergence.
- [ ] test/integration/client_secret_verifier_maintenance_test.exs — actual DB barriers, both lock orders, audit failure/outer rollback, concurrent edits, pages, issuance race.
- [ ] test/integration/client_secret_verifier_maintenance_disclosure_test.exs — sentinels at Logger/telemetry, crypto/storage/task, nested Inspect/audit/protocol.
- [ ] test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs — args, exits, config/signing exclusion and Repo handling.
- Existing precedents: test/lockspire/storage/reencrypt_concurrency_test.exs, test/integration/client_secret_verifier_guarded_issuance_test.exs, test/lockspire/install/task_error_test.exs and repo_runner_test.exs. These do not prove new maintenance behavior.

## Security Domain

Use the configured ASVS L1 security gate. The areas below are descriptive review lenses, not a numbered ASVS-version mapping; consult the selected official standard before asserting control identifiers. [CITED: https://asvs.owasp.org/]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| Authentication | Yes | Fail closed for affected JWT verifier; unrelated methods continue. |
| Session management | No direct path | Preserve endpoint/session secrets and immutable runtime context. |
| Access control | Yes | Operate through selected declared client/transaction/audit authority only. |
| Validation, sanitization and encoding | Yes | Validate task modes/cursors/limits and safely encode bounded client IDs. |
| Stored cryptography | Yes | Preserve existing AEAD/AAD and fresh IV; never expose plaintext or derive keys. |
| Error handling and logging | Yes | Map raw DB/crypto errors to fixed safe reasons; test Logger/telemetry sentinels. |
| Data protection | Yes | Keep plaintext, key bytes, hashes and ciphertext out of reports, audit and diagnostics. |
| Configuration | Yes | Keep task-local config isolated from immutable serving-node startup context. |

### Threats

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stale page overwrites secret rotation | Tampering | Lock/reload, exact CAS. |
| Ciphertext/key in SQL channels | Information Disclosure | Sensitive queries disable Logger and telemetry, sentinel capture. |
| Raw DB exception leaks query/host | Information Disclosure | Fixed mapping before format/inspect. |
| Forged header looks current | Spoofing | AEAD + identity/purpose + hash verification first. |
| Locale pagination omits IDs | False readiness | Same bytewise cursor and order expression. |
| Partial scan reported ready | Repudiation | Independent completion/progress/readiness. |
| Rewrap races issuance | Replay / denial of service | Preserve ciphertext guard; no side effects; fresh JTI. |

## Sources

### Primary

- 175-CONTRACT.md — exact maintenance callbacks, outcomes, format and policy premises.
- 175-POLICY-REVISION.md — approved native/migrated age.
- 177-CONTEXT.md — D-01–D-23.
- 176-VERIFICATION.md and 176-HANDOFF.md — Phase 176 verified behavior and Phase 177 ownership.
- Opened code sources: client_secret_verifier.ex, legacy.ex, client_store.ex, transaction_store.ex, client_lifetime.ex, repository client_store/support, repo_runner.ex, task_error.ex.
- Test precedents: storage/reencrypt_concurrency_test.exs and integration/client_secret_verifier_guarded_issuance_test.exs.

### Official documentation

- [PostgreSQL 14 collation](https://www.postgresql.org/docs/14/collation.html) — comparison and ordering use collation.
- [PostgreSQL 14 transaction isolation](https://www.postgresql.org/docs/14/transaction-iso.html) — READ COMMITTED row-lock update behavior.
- [Ecto SQL 3.13.5 source](https://github.com/elixir-ecto/ecto_sql/blob/v3.13.5/lib/ecto/adapters/sql.ex#L1265-L1354) — Logger and telemetry query channels.
- [Postgrex 0.22.4 source](https://github.com/elixir-ecto/postgrex/blob/v0.22.4/lib/postgrex/error.ex) — raw formatted errors include diagnostics/query.
- [DBConnection 2.10.2 source](https://github.com/elixir-ecto/db_connection/blob/v2.10.2/lib/db_connection/connection.ex#L143-L164) — connection process logging boundary.
- [Mix app.config 1.19.5](https://hexdocs.pm/mix/1.19.5/Mix.Tasks.App.Config.html), [Mix release 1.19.5](https://hexdocs.pm/mix/1.19.5/Mix.Tasks.Release.html) — configuration/RPC boundary.
- [PostgreSQL 14 logging](https://www.postgresql.org/docs/14/runtime-config-logging.html) — DB server logging is host controlled.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Source-level proof is Phase 177's implementation gate; package-installed/configured-store journey is Phase 178. | Validation Architecture | Could miss a required supported-store test; preserve D-23 boundary in plans. |

## Open Questions

1. **Exact module/task/report names.** Contract callbacks and semantics are fixed; names/report internals are discretion. Recommend Mix-free core, separate internal custody decoder, adapter implementation and thin task; export only what host RPC needs.
2. **Independent DB capacity at execution.** Current PostgreSQL probe accepts connections, but Phase 176 had local pool limits. Keep real barrier proof mandatory; constrain pool/workers and report missing evidence if blocked.
3. **Host driver/server logging.** Lockspire suppresses its Ecto channels, not all host instrumentation. Document boundary without altering host-global logging.

## Metadata

**Confidence breakdown:** Stack HIGH (mix.exs/runtime read); architecture HIGH (contracts/source read, runtime behavior pending); pitfalls HIGH (phase decisions and primary docs); environment HIGH for probe moment only.

**Research date:** 2026-10-25
**Valid until:** 2026-11-24 for stable architecture; reprobe runtime before execution.
