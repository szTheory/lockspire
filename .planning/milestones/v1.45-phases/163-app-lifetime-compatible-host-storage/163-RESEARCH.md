# Phase 163: App Lifetime & Compatible Host Storage - Research

**Researched:** 2026-10-20  
**Domain:** Elixir/Ecto storage, OAuth/OIDC request eligibility, PostgreSQL concurrency, packaged host migrations  
**Confidence:** HIGH for in-repo seams and locked semantics; MEDIUM for architecture details that must be exercised by Phase 163 runtime tests

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Eligibility and consumer coverage

- **D-01:** Use one narrow Lockspire app-eligibility decision with explicit consumer context and endpoint-owned error mapping. Keep generic storage fetches capable of returning expired/disabled rows; filtering them away hides state and breaks permitted management reads/deletes. Preserve configuration/storage failures as server errors, separate from invalid credentials.
- **D-02:** Apply current enabled-state and app-deadline checks to every applicable Phase 162 consumer, including public/private-key/mTLS clients. Authentication is a useful shared entry gate, but never the sole enforcement boundary. Deadline equality is expired; no pruning dependency or JWT skew grace.
- **D-03:** Check browser authorization before host login/consent handoff and again at resume, remembered consent and approval/code persistence. Recheck PAR use, device verification/approval, CIBA host approval and queued push issuance. Preserve validated-redirect trust, original state, existing polling/replay/grant-expiry errors, and host ownership.
- **D-04:** Online UserInfo and token exchange must inspect the current issuing app through the declared client adapter, before host claims/validation where applicable and at final durable issuance. RFC 8693 retains durable subject AND actor token identities and validates their issuing apps independently from the requester. Preserve introspection's owned-token restriction; invalid caller is 401, otherwise authorized inactive target is only active:false. Keep offline VerifyToken free of client-store lookups.
- **D-05:** Implement app-state management distinctions now: expired-enabled app permits valid-credential GET/DELETE, forbids PUT; disabled app blocks all self-management. Intake closure alone must not disable existing management. Do not conflate these app checks with finite management-token enforcement due in Phase 165, or allow this phase's foundations to revive/extend an app.

### Durable authority, clocks and token truth

- **D-06:** Final authorization/issuance operates on current locked client state and previously verified credential identity, not a client snapshot. Use stable client-ID ordering for multiple requester/subject/actor app locks, and one consistent client-before-grant/token ordering across relevant writers. Acquire all required blocking locks before capturing the final decision time; a later grant/request/token wait invalidates an earlier time sample.
- **D-07:** App rejection at code redemption must leave the code unconsumed and write no token. Current-client guards, grant consumption, token writes and atomic audits participate in one rollback authority. Apply intended mutable changes to current rows; do not restore old hashes, enabled flags or deadlines via stale whole-client replacements. This ordering foundation must be usable by later credential phases.
- **D-08:** Prefer one outer transaction with plain functions/with beneath it, retaining the existing supported transaction abstraction. Explicitly propagate errors into rollback. Ecto Repo.transaction returning {:error, reason} is not itself rollback; Repo.transact has different return semantics. Do not mechanically migrate every transaction API or swallow nested rollback errors.
- **D-09:** Preserve existing clock entry-point conventions while adapting them into explicit dependencies. Fix dropped clocks at ClientAuthentication and CIBA adaptation; avoid global clock services, per-consumer ambient callback discovery and public-option churn. Fresh time after lock waits is required; an ingress DateTime must not become permanent authority. SQL now()/CURRENT_TIMESTAMP and a waiting statement's statement_timestamp() cannot establish post-wait time.
- **D-10:** Compute effective access/refresh expiry once from the final decision time and min(ordinary deadline, finite app deadline), then derive durable expiry, access JWT exp and response expires_in from that result. Cover ordinary grants, refresh rotation, push and RFC 8693. Refuse zero-lifetime issuance at equality. Keep ID-token TTL and authorization-artifact TTL semantics selected in Phase 162.
- **D-11:** End locks before network calls, host callbacks that can perform remote work, delivery and response encoding. In particular, separate durable code/interaction transitions from JARM redirect construction, which can fetch remote JWKS. Do not solve locking by disabling supported response modes. Prepare expensive work outside locks only when current-state/fingerprint revalidation preserves the selected contract.

### Storage and legacy authority

- **D-12:** Persist lifetime_version plus nullable app/management deadlines and the existing secret deadline on the client aggregate. Migration establishes existing rows as explicit v0; constructors explicitly assign v1 to new clients. Missing/unknown domain version is invalid, never an implicit v0 fallback. Preserve historical advisory secret dates unchanged during schema expansion; only authoritative new dates use whole seconds.
- **D-13:** Keep legacy rows effectively unlimited, with no guessed deadline or policy backfill. Reads, ordinary metadata edits and enable/disable need not promote. Any existing credential-replacement path that promotes a legacy row must canonicalize unrelated historical deadlines to unlimited atomically under the current row, per Phase 162; never flip the version alone. Do not accidentally enforce historical secret dates while building app enforcement.
- **D-14:** Declare lifetime-contract version at the adapter boundary, owned by the adapter. Validate it in dependency adaptation and pass explicit typed support to consumers. Do not reuse the permissive capabilities-map default of :all as proof, or introduce a general capability framework. Exact callback/module/helper names remain planner discretion.
- **D-15:** Supported custom composition must explicitly share a transaction authority covering client current-row guards, grants/tokens and required audits. Independent backend callbacks do not prove atomicity. Reject unsupported composition/configuration with actionable host errors rather than unlimited fallback or a false credential error. No distributed coordinator or new runtime dependency.
- **D-16:** Add reusable adapter conformance fixtures that prove version/deadline round trips, current-row guarded writes, rollback and unsupported-state failure. Negative adapters must fail when omitting/unknown-declaring the contract, dropping version/deadlines, lacking guards or pretending unrelated stores share a transaction. Wire UserInfo and every relevant consumer to the declared adapter rather than a hardcoded Ecto repository.

### Host upgrade and operational proof

- **D-17:** Add one new packaged prefix-aware expansion migration through existing installer/checksum tools. Never alter shipped migration bytes or move existing host schema. Fresh generated installs and upgraded public/custom-prefix hosts must converge on equivalent lifetime storage. Use nullable deadlines and a constant v0 default; constructors still explicitly write v1.
- **D-18:** Treat additive/no-rewrite DDL as locking DDL. PostgreSQL 14 still takes ACCESS EXCLUSIVE; avoid extra scans/constraints without need. Provide a bounded operational procedure using existing tooling, explain lock acquisition/maintenance considerations and test supported shapes; do not promise a production duration or nonblocking migration.
- **D-19:** Preserve selected deploy order: expand schema while old code can run, stage the new build without serving, drain every old writer (web/admin/jobs/CLI), then cut over. Before first v1 write the old binary may use expanded schema; after authoritative writes it is not a safe protocol rollback. Retain schema/state and fix forward or use an enforcement-aware build. No activation daemon, permanent flag, mixed-version bridge or zero-downtime claim.
- **D-20:** Focused Phase 163 upgrade evidence must exercise real database expansion and pinned pre-lifetime/candidate builds in isolated processes using existing clean-room/package infrastructure where practical. A faithful legacy fixture is useful but does not alone prove old-binary compatibility. Prove representative old nil/past/future/stale dates remain unlimited, pre-v1 old read/write compatibility and preservation of v1 state/unsafe downgrade boundary. Do not run an old binary against authoritative traffic to claim safe post-v1 rollback.

### Verification, dependency discipline and scope

- **D-21:** Use deterministic injected clocks and real independent PostgreSQL sessions for races. Identify holder/contender backend PIDs and confirm the expected blocker with pg_blocking_pids before moving the clock/releasing the holder. Shared sandbox/allowed tasks reuse connections and are not independent transactions. Avoid sleeps as expiry evidence and global any-waiter counters; guarantee cleanup and bounded waits.
- **D-22:** Include before/equality/after, changed-policy/provenance, disabled-versus-expired, no-secret clients, queued/resumed work, stale preverified credential, and both client-lock AND later grant-lock waits. Assert durable artifact counts/state and rollback of failed audits/writes, not merely returned errors. Exercise opaque and signed token representations and every issuance route. Phase 166's final suite supplements these tests.
- **D-23:** Reuse OTP/Elixir/Ecto/PostgreSQL and existing test/install infrastructure. Add no dependency unless evidence establishes necessity. Keep repository facade delegation and explicit token dependency architecture intact. No new host account/recovery system, broad UI work, authorization feature or generic framework.
- **D-24:** Apply accurate host-facing storage/migration guidance with the code that establishes it; final cross-phase copy reconciliation stays Phase 166. Any changed admin text requires PRODUCT personas/vocabulary and retired-wording checks. Do not expose internal lifetime versions as product UI concepts or promise immediate offline revocation.

### the agent's Discretion

Choose narrow module/callback names, internal result types, plan slicing and test fixture organization within these constraints. Prefer a cohesive implementation over duplicate endpoint policy. Research may refine internal mechanics but cannot reopen Phase 162 semantics or weaken the guarantees to simplify storage.

### Deferred Ideas (OUT OF SCOPE)

- Phase 164: finite secret enforcement, wire secret metadata and atomic secret rotation under current policy.
- Phase 165: finite management token lifecycle, recovery and complete credential rotation behavior.
- Phase 166: full packaged end-to-end matrix, cross-phase security/redaction, required CI and final operator/public guidance reconciliation.
- New activation services, mixed-version zero-downtime bridge, app renewal, overlapping credentials, generic capability framework, distributed coordinator, admin redesign and new dependencies lack need within this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DCR-05 | A newly registered app stores and uses its effective lifetime according to the selected contract, with distinct disabled and expired behavior where the contract requires it. | Add app deadline and lifetime version to `Client`/`ClientRecord`; registration constructor snapshots app policy and explicitly sets v1; one eligibility function feeds all locked consumers and endpoint-owned errors. `[VERIFIED: .planning/REQUIREMENTS.md:21]` |
| DCR-06 | A host can rely on app expiry being checked consistently across applicable existing protocol paths, with issued tokens handled exactly as selected in DCR-03 and without depending on worker scheduling. | Consumer inventory and effective token expiry are defined in Phase 162 contract; route each online and delayed path through current adapter state and durable guarded issuance. `[VERIFIED: .planning/REQUIREMENTS.md:22]` |
| DCR-13 | An existing host can upgrade representative legacy registrations under the selected compatibility contract without deriving unapproved rejection deadlines from ambiguous historical dates. | New prefix-aware additive migration, v0 for existing rows, and whole-row legacy promotion on credential replacement; old dates remain advisory/unlimited. `[VERIFIED: .planning/REQUIREMENTS.md:23]` |
| DCR-14 | A fresh generated host and a host using custom client storage can satisfy the lifetime contract through documented schema and storage changes, with unsupported capabilities handled explicitly. | Extend packaged migration and adapter conformance contract; reject missing declaration/fields/transaction authority as server configuration failure. `[VERIFIED: .planning/REQUIREMENTS.md:24]` |
</phase_requirements>

## Summary

Phase 163 should establish durable app lifetime as an explicit part of the client aggregate, then use one current-state eligibility decision at every Phase 162 consumer and final durable issuance boundary. The storage version distinguishes migrated legacy rows from newly authoritative rows: existing rows become v0 and remain effectively unlimited; new registration writes v1 even when the chosen lifetime is unlimited. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:60-67; .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:45-56]`

The key implementation hazard is stale authority. Existing Ecto replacement code takes a row lock but applies a caller-built replacement to the newly loaded record; it does not re-derive changes from current state. Promotion must therefore use the locked row, retain unrelated current fields, normalize the v0 app/management/secret deadlines to `nil`, set only the deadline belonging to the credential being replaced, and commit credential, version, deadline, and audit together. `[VERIFIED: lib/lockspire/storage/ecto/repository/client_store.ex:55-85; .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:69-75]`

**Primary recommendation:** Put lifetime version and deadlines on the existing client aggregate; declare and validate a narrow v1 adapter contract at dependency adaptation; enforce app eligibility from a locked current row with decision time sampled after all blocking locks; add one new prefix-aware packaged expansion migration; and prove legacy/candidate compatibility with real PostgreSQL and isolated package builds. Do not add dependencies or let v0 historical secret dates become enforcement inputs. `[VERIFIED: .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:45-66; .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:60-80]`

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| App lifetime persistence and legacy promotion | Database / Storage | API / Backend | The client row is the durable authority; protocol code supplies narrowly scoped intent and the current decision time. `[VERIFIED: lib/lockspire/storage/ecto/client_record.ex:12-106; lib/lockspire/storage/ecto/repository/client_store.ex:55-109]` |
| Request-time eligibility across OAuth/OIDC flows | API / Backend | Database / Storage | Protocol paths own endpoint-specific error mapping; the client adapter supplies current enabled/version/deadline state. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:21-48]` |
| Token expiry capped by app lifetime | API / Backend | Database / Storage | Issuance computes one final expiry and applies it to stored artifacts, signed claims, and response lifetime. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:48-51]` |
| Host migration delivery and prefix handling | Database / Storage | API / Backend | Packaged migration files expand host schema; install tooling checks content and copies missing migrations without overwriting host files. `[VERIFIED: lib/lockspire/install/migrations.ex:3-8,86-111; lib/lockspire/storage/ecto/migration.ex:24-69]` |
| Adapter compatibility and transaction authority | API / Backend | Database / Storage | Dependency adaptation rejects unsupported compositions before protocol execution; adapter implementation owns guarded writes and the shared atomicity boundary. `[VERIFIED: lib/lockspire/protocol/token_exchange/internal/dependencies.ex:58-64,131-150; .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:59-63]` |

## Project Constraints (from AGENTS.md)

- Keep Lockspire a separate embedded Phoenix/Elixir companion library, not a required standalone auth service or Sigra module.
- Preserve boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces; keep host account resolution, login, claims, branding, and product policy host-owned.
- Stay within the existing stack: Phoenix 1.8.5, LiveView 1.1.28, Ecto SQL 3.13.5, PostgreSQL 14+, Oban 2.21.x, OpenTelemetry 1.6.0. Bandit belongs to host/demo/clean-room projects, not Lockspire dependencies.
- Preserve PKCE S256, exact redirect matching, hashed secrets, short-lived single-use authorization codes, refresh rotation with family revocation on reuse, no implicit flow, no `alg=none`, and strong redaction.
- Before any admin copy change, read PRODUCT personas/vocabulary, use the mapped “UI says” term, add new concepts and retired wording in the same change, and describe actual behavior. `[VERIFIED: AGENTS.md:7-41]`

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / OTP | Project requires `~> 1.18`; selected active version is not configured in this shell | Domain decisions, adapter callbacks, transaction orchestration | Existing codebase and locked project stack; reuse current runtime. `[VERIFIED: mix.exs:1-20]` |
| Ecto SQL / Postgrex | Ecto SQL `~> 3.13.5`; Postgrex `>= 0.0.0` | Current-row locks, transactions, client schema, migration execution | Existing repository/storage boundary. `[VERIFIED: mix.exs:40-45; lib/lockspire/storage/ecto/repository/client_store.ex:65-82]` |
| PostgreSQL | 14+ | Durable client authority and independent-session lock evidence | Project-supported database; row locks and transaction timing semantics are central to the selected contract. `[VERIFIED: AGENTS.md:23-29; CITED: https://www.postgresql.org/docs/14/explicit-locking.html#LOCKING-ROWS; https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT]` |

### Supporting

| Library/tool | Version | Purpose | When to Use |
|--------------|---------|---------|-------------|
| Existing Mix migration installer/checksum manifest | in-repo | Deliver the new additive packaged migration and detect host collisions | Every fresh/generated or upgraded host migration proof. `[VERIFIED: lib/lockspire/install/migrations.ex:34-55,86-111]` |
| Existing clean-room package harness | in-repo | Build candidate package and host app in an isolated process | Candidate-package/host upgrade compatibility proof; extend it for pinned pre-lifetime package as needed. `[VERIFIED: scripts/acceptance/clean_room/build_provider.py:1-7,228-280; scripts/acceptance/clean_room/package_input.py:135-146]` |
| Existing Ecto SQL sandbox integration setup | in-repo | DB-backed focused tests and independent transaction sessions | Use independent sessions for races; shared sandbox connections are not evidence of real competing PostgreSQL transactions. `[CITED: https://raw.githubusercontent.com/elixir-ecto/ecto_sql/v3.13.5/lib/ecto/adapters/sql/sandbox.ex; VERIFIED: test/lockspire/storage/repository_concurrency_test.exs:16-23,45-70]` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit `lifetime_version` and deadline fields on the client aggregate | Infer legacy/current behavior from timestamps or current policy | Rejected by locked contract: timestamps are ambiguous, current policy is not an issuance snapshot, and missing/unknown version must fail closed. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:60-75]` |
| Declared adapter lifetime contract | Assume any custom callback set or `capabilities: :all` supports it | Rejected: existence of independent callbacks does not establish schema round trips, current-row guards, or shared atomicity. `[VERIFIED: lib/lockspire/protocol/token_exchange/internal/dependencies.ex:131-141; .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:59-63]` |

**Installation:** No new package installation. Reuse current Elixir/Ecto/PostgreSQL, installer, and test infrastructure. `[VERIFIED: .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:63-64; mix.exs:40-61]`

## Architecture Patterns

### System Architecture Diagram

```text
registration request + resolved DCR policy
                  |
                  v
     build client with app deadline + v1
                  |
                  v
        declared client adapter
                  |
      +-----------+------------------+
      |                              |
      v                              v
prefix-aware host migration     durable client row
v0 for existing records         v1 for new registration
                                     |
protocol request / worker ----------+
      |                              |
      v                              v
adapted lifetime-capable       lock current client row(s)
client adapter                       |
      |                              v
      +--------------------> sample final time after all waits
                                     |
                                     v
                          eligible? + token/app cap
                            /                \
                           v                  v
                     endpoint error       guarded durable write
                                               |
                                    grants/tokens/audits share
                                     transaction authority
```

The diagram describes the ownership flow required by the locked contract; the final decision time is after every blocking lock acquisition, including a later grant/token lock. `[VERIFIED: .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:34-42; CITED: https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT]`

### Recommended Project Structure

Extend existing modules rather than introducing a new subsystem:

```text
lib/lockspire/domain/client.ex
lib/lockspire/client_metadata.ex
lib/lockspire/storage/client_store.ex
lib/lockspire/storage/ecto/client_record.ex
lib/lockspire/storage/ecto/repository/client_store.ex
lib/lockspire/protocol/token_exchange/internal/dependencies.ex
lib/lockspire/protocol/token_exchange/internal/legacy_options.ex
priv/repo/migrations/<new additive lifetime expansion>.exs
test/lockspire/storage/<lifetime adapter and concurrency tests>.exs
test/integration/<legacy and packaged upgrade journey>.exs
```

The last three filenames are proposed organization, not existing paths. Existing repository facade delegation is enforced by architecture tests and should remain the route to the Ecto-specific store. `[VERIFIED: test/lockspire/architecture_fitness_test.exs; lib/lockspire/storage/ecto/repository.ex:58-125]`

### Pattern 1: Versioned aggregate with explicit legacy promotion

**What:** Add lifetime state to the `Client` domain value and `ClientRecord`, and include each field in the record changeset plus `to_domain/1` mapping. The normative contract states: “Persist `lifetime_version` 0 (legacy) or 1 (authoritative), nullable `client_expires_at` and `registration_access_token_expires_at`, and reuse the existing secret expiry column.” It also states: “On v1, null means authoritative unlimited.” `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:68-70]`

**When to use:** Registration creates a new row; management or operator secret replacement promotes an eligible v0 row. Ordinary reads, metadata edits, enable/disable, and deletes do not promote. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:69-75]`

**Example (implementation sketch; names are planner discretion):**

```elixir
promoted = %{
  locked_current_client
  | lifetime_version: 1,
    client_expires_at: nil,
    client_secret_expires_at: nil,
    registration_access_token_expires_at: replacement_management_deadline
}
```

The exact field names and `1`/`nil` values are from the contract quote above. This sketch shows the management replacement case; secret rotation sets only `client_secret_expires_at` to its replacement deadline. Apply it to the currently locked/reloaded row, and write the replacement credential hash, verifier where applicable, and audit in the same transaction. It is not a proposed public API. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:68-75; lib/lockspire/storage/ecto/repository/client_store.ex:65-83]`

### Pattern 2: Adapter-owned contract, validated during adaptation

**What:** Declare the client store's lifetime contract version and transaction authority as explicit adapter metadata. Adapt and validate it once at the existing dependency seam, then pass typed support to consumers. Unknown/missing declarations or dropped version/deadline state are server configuration errors. `[VERIFIED: .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:59-63]`

**When to use:** All custom client store configurations and token-exchange compositions. The current capability map is permissive: `Map.get(dependencies.capabilities, field, :all)` treats omitted entries as `:all`, so it cannot stand in for lifetime contract proof. `[VERIFIED: lib/lockspire/protocol/token_exchange/internal/dependencies.ex:131-141]`

**Example (shape only):**

```elixir
adapted = validate_lifetime_contract(client_store, transaction_authority)
```

`validate_lifetime_contract/2` is illustrative, not a selected callback name. Keep exact module/callback/result names local to implementation. Conformance fixtures should include positive and deliberately negative adapters for missing/unknown declaration, omitted fields, missing guarded writes, rollback failure, and false cross-store transaction claims. `[VERIFIED: .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:60-64]`

### Pattern 3: Lock current client state, then take one final decision time

**What:** Order locks as selected by Phase 162: client rows by stable ID, then grant/request rows by stable kind and ID, then token/family rows by stable kind and ID. Only after every blocking lock and current client reload, call the injected clock once for eligibility and deadline calculation. SQL transaction/statement timestamps are not a substitute after waiting. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:75-79; CITED: https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT; https://www.postgresql.org/docs/14/transaction-iso.html]`

**When to use:** Token issuance, code redemption, refresh rotation, worker issuance, RFC 8693 subject/actor validation, management credential replacement and any operation whose durable side effect depends on app eligibility.

**Example (transaction sketch):**

```elixir
decision_time = injected_clock_after_all_locks()
eligible = decision_time < current_client.client_expires_at
```

The expression is only the finite-deadline branch; version 0 and v1 `nil` are treated as unlimited per the contract. Lock scopes end before network fetches, remote host callbacks, push delivery, or response/JARM encoding. Use the configured transaction abstraction; ensure error tuples reach its rollback path. `[VERIFIED: lib/lockspire/storage/ecto/repository/transaction_store.ex:4-22; .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:34-42]`

### Pattern 4: Additive packaged expansion migration

**What:** Add a new migration to packaged migration assets, using existing `Lockspire.Storage.Ecto.Migration` prefix helpers and installer checksum machinery. Do not modify shipped migration bytes. Keep deadlines nullable and the legacy version default constant. `[VERIFIED: .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:64-67; lib/lockspire/storage/ecto/migration.ex:24-69; lib/lockspire/install/migrations.ex:34-55,86-111]`

**When to use:** Fresh installs, existing default schema hosts, and hosts using a custom schema prefix. The new migration plus generated schema must converge on the same client lifetime shape.

**Operational note:** PostgreSQL's fast default avoids a table rewrite in supported cases but `ALTER TABLE` still needs a strong table lock. Describe and test a bounded migration procedure; do not promise lock-free or duration-bounded production execution. `[CITED: https://www.postgresql.org/docs/14/sql-altertable.html]`

### Anti-Patterns to Avoid

- **Filter expired/disabled clients out of generic storage fetches:** state-sensitive callers need those records for authorized management read/delete and correct error mapping. `[VERIFIED: .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:20-27]`
- **Promote with a stale whole-client value:** the current Ecto method locks the database row but builds changes from the supplied replacement. Preserve current unrelated hashes, enabled state, and policy under lock. `[VERIFIED: lib/lockspire/storage/ecto/repository/client_store.ex:55-85]`
- **Flip v0 to v1 without normalizing all lifetime fields:** this would convert historical secret dates into unintended authority. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:60-75]`
- **Treat missing adapter metadata or `:all` as support:** fail closed with actionable server configuration errors. `[VERIFIED: lib/lockspire/protocol/token_exchange/internal/dependencies.ex:131-141]`
- **Use ingress time or SQL `now()` after lock waits:** this authorizes a request that reached equality while blocked. `[CITED: https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT; .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:34-42]`
- **Hold locks during remote work or JARM response construction:** persist and end the transaction first; build network-dependent responses afterward. `[VERIFIED: .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:42-44]`
- **Claim post-v1 rollback to a pre-lifetime binary:** old code cannot preserve new version/deadline authority. Drain all old writers before first v1 write; after that retain state and fix forward or use an enforcement-aware build. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:77-80]`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lock-safe transactions and rollback | Custom transaction coordinator or ad hoc adapter callback probing | Existing `TransactionStore` abstraction and an explicitly declared shared authority | Existing repository transaction adapter already handles returned errors by rollback; a composed custom adapter must prove common atomicity. `[VERIFIED: lib/lockspire/storage/ecto/repository/transaction_store.ex:4-22; .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:59-63]` |
| Prefix-aware packaged migrations | Hand-copy migration code or edit old migrations in place | `Lockspire.Storage.Ecto.Migration` helpers and `Lockspire.Install.Migrations` | Prefix behavior and checksum/no-overwrite preflight already exist. `[VERIFIED: lib/lockspire/storage/ecto/migration.ex:24-69; lib/lockspire/install/migrations.ex:34-55,86-111]` |
| Isolated package/host upgrade proof | A synthetic Ecto struct alone as compatibility proof | Existing clean-room package build and isolated host processes, extended to pin both pre-lifetime and candidate builds | Package root and host build seams exist; a fixture-only simulation cannot establish old binary behavior. `[VERIFIED: scripts/acceptance/clean_room/build_provider.py:228-280; .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:66-68]` |
| Race detection | Sleeps, global waiter counters, or shared sandbox transactions | Independent PostgreSQL sessions, backend PIDs, and `pg_blocking_pids` confirmation | Proves the intended lock wait rather than hoping scheduler timing produced it. `[VERIFIED: .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:68-71; CITED: https://www.postgresql.org/docs/14/functions-info.html#FUNCTIONS-INFO-SESSION-TABLE]` |

**Key insight:** A lifetime value is only authoritative when version, all relevant deadlines, the credential identity used for authorization, and the side effect are observed or changed under one declared transaction authority. A database migration or a callback list alone does not establish that authority. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:66-80]`

## Common Pitfalls

### Pitfall 1: New registration lacks an authoritative issuance snapshot

**What goes wrong:** New rows default to missing/legacy state or app expiry drifts from the DCR policy snapshot.  
**Why it happens:** `ClientMetadata.build_dcr_client/4` currently sets `client_id_issued_at` and secret expiry, but has no app expiry/version fields; it samples wall time internally. `[VERIFIED: lib/lockspire/client_metadata.ex:41-104]`  
**How to avoid:** Resolve DCR app lifetime with the existing policy resolver, pass an explicit registration clock into the construction/persistence seam, set `lifetime_version` to `1`, and store `nil` for unlimited or a whole-second UTC deadline for positive seconds. Use independent constructor paths for operator clients so DCR policy is not silently applied to direct registration. `[VERIFIED: lib/lockspire/protocol/dcr_policy.ex:62-74,128-137; .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:9-20]`  
**Warning signs:** New app without secret has no lifetime gate; changes to current DCR policy alter old registrations; persisted time contains subsecond precision.

### Pitfall 2: v0 promotion makes historical secret timestamps authoritative

**What goes wrong:** A legacy row with past/future/stale `client_secret_expires_at` unexpectedly starts rejecting clients when `lifetime_version` changes.  
**Why it happens:** Secret expiry is already present in the client aggregate and record; a naive promotion can preserve it as if it were a v1 policy snapshot. `[VERIFIED: lib/lockspire/domain/client.ex:73-80, lib/lockspire/storage/ecto/client_record.ex:87-95]`  
**How to avoid:** Under the client row lock, canonicalize unrelated v0 deadlines to `nil`, apply only the newly replaced credential's deadline, set version 1, update only intended fields on the current row, and append the audit in the same rollback authority. Existing secret verifiers/hash material remain unchanged for management-only promotion. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:69-75]`  
**Warning signs:** Promotion tests use only `nil` legacy dates; current hash/verifier/deadline is copied from the pre-lock domain snapshot; failure/audit rejection leaves version or a credential changed.

### Pitfall 3: Existing custom stores appear supported by permissive defaults

**What goes wrong:** A host's callback modules are present but omit the new fields, ignore guarded current-row identity, or write grants/tokens/audits to independent transaction systems; Lockspire nevertheless treats them as lifetime-safe.  
**Why it happens:** Current `Dependencies.capability_available?/2` defaults a missing capability map entry to `:all`. `[VERIFIED: lib/lockspire/protocol/token_exchange/internal/dependencies.ex:131-141]`  
**How to avoid:** Validate the adapter-owned lifetime contract version during dependency adaptation, route UserInfo and protocol consumers through that adapter, and require a shared transaction authority. Keep endpoint error mapping outside the generic storage adapter. `[VERIFIED: .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:20-22,59-63]`  
**Warning signs:** No negative adapter tests; a missing declaration becomes an unlimited fallback; `UserInfo` still fetches from a hardcoded Ecto repository.

### Pitfall 4: Code uses stale client state or samples time before later waits

**What goes wrong:** A request verified before expiry passes even though it waits for client or grant/token locks until the exact deadline; stale authorization also restores prior credential or enabled state.  
**Why it happens:** Pre-verification and ingress timestamps outlive their authority; Ecto lock wait/recheck behavior and transaction time are easy to conflate with actual post-wait time. `[CITED: https://www.postgresql.org/docs/14/transaction-iso.html; https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT]`  
**How to avoid:** Capture and retain verified credential identity/fingerprint, acquire all required locks in stable order, reload current client rows, then sample one injected time. Reject stale fingerprint and equality as expired; ensure all mutations are current-row deltas. `[VERIFIED: .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:34-42]`  
**Warning signs:** App lock race passes but later grant lock race is missing; shared sandbox task is claimed as independent session evidence; time is read once at ingress.

### Pitfall 5: Migration is treated as nonblocking or rollback-safe after v1 writes

**What goes wrong:** Deployment waits unexpectedly for a table lock, old writers remain active at cutover, or operators roll back to code that drops/preserves no authoritative v1 state.  
**Why it happens:** Additive DDL and a green unit test can imply weaker operational risks than PostgreSQL actually provides. `[CITED: https://www.postgresql.org/docs/14/sql-altertable.html]`  
**How to avoid:** Keep schema expansion separate, test public and custom prefixes, stage without ingress, drain web/admin/jobs/CLI writers, then cut over before any v1 write. Document lock acquisition and maintenance considerations without a universal duration claim. After the first v1 write, retain schema/data and fix forward or use an aware rollback binary. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:77-80]`  
**Warning signs:** Existing migration bytes change; migration uses unnecessary scans/constraints; an old binary is executed against authoritative traffic in compatibility proof.

## Runtime State Inventory

This is a storage/schema and compatibility change, not a rename/refactor. No old string rename is in scope. The runtime state being extended is the `lockspire_clients` row: Phase 162 requires existing records to be migration-versioned as v0, without rewriting historical `client_secret_expires_at`, and new registration to write v1 explicitly. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:66-70; priv/repo/migrations/20260427000020_extend_lockspire_clients_dcr.exs:4-27]`

## Code Examples

### App decision and expiry boundary

The contract defines equality as expired: `now < deadline` is eligible; `now == deadline` or later is ineligible. Its exact storage quote is “Persist `lifetime_version` 0 (legacy) or 1 (authoritative), nullable `client_expires_at` and `registration_access_token_expires_at`”; on v1, “null means authoritative unlimited.” Unknown/missing authoritative version is a server configuration error, not a credential rejection. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:9-16,68-70]`

```elixir
supported_version = client.lifetime_version in [0, 1]
eligible = client.active and
  (client.lifetime_version == 0 or
     (client.lifetime_version == 1 and
        (is_nil(client.client_expires_at) or now < client.client_expires_at)))
```

The version values and `nil` deadline are the quoted contract values above; `supported_version` must be required before using `eligible`, and every consumer maps the result into its selected OAuth/OIDC/registration behavior. Keep storage/configuration errors separate from credential failures. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:21-48,68-70]`

### Effective token expiry

Case C-TOK-01 states the exact values: `"at": 159`, `"app_deadline": 160`, `"ordinary_expiry": 3759`, `"stored_expiry": 160`, `"jwt_exp": 160`, `"expires_in": 1`; C-TOK-02 states `"at": 160`, `"issued": false`. Thus durable access expiry and JWT `exp` are 160, response `expires_in` is 1, refresh uses its own ordinary TTL capped at the same app deadline, and issuance at equality fails before code consumption or token writes. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CASES.json:605-621; .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:48-51]`

```elixir
effective_expiry = min(ordinary_expiry, finite_app_deadline)
stored_expiry = jwt_exp = effective_expiry
expires_in = effective_expiry - decision_time
```

This sketch omits DateTime units/serialization and the unlimited branch; an implementation should derive stored row expiry, JWT `exp`, and response `expires_in` from the same computed result, and refuse issuance when result is at or before decision time. Include opaque and signed token representations and every issuance route in tests. `[VERIFIED: .planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md:38-40,69-71]`

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit; Ecto SQL sandbox with PostgreSQL. `[VERIFIED: mix.exs:85-97; test/lockspire/storage/repository_concurrency_test.exs:1-23]` |
| Config file | `config/test.exs`; repo migration setup is available through the project's `test.setup` / `test.fast` aliases. `[VERIFIED: mix.exs:95-124; config/test.exs:1-35]` |
| Quick run command | `MIX_ENV=test mix test test/lockspire/<focused-file>.exs` (after the project's existing test database setup) |
| Full suite command | `MIX_ENV=test mix test.fast`; Phase 166 owns final cross-phase/package/security/CI proof. `[VERIFIED: mix.exs:95-109]` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DCR-05 | New DCR clients store v1 app deadline/unlimited state; boundary/equality and disabled state differ; public clients are covered. | unit + integration | `MIX_ENV=test mix test test/lockspire/protocol/registration_test.exs test/lockspire/protocol/<app-eligibility-test>.exs` | Registration tests exist; focused lifetime tests are Wave 0. |
| DCR-06 | Browser, PAR, device, CIBA, code, refresh, push, RFC 8693, UserInfo, introspection and revocation paths use current app state; durable access/refresh expiry is capped consistently. | integration + PostgreSQL | `MIX_ENV=test mix test test/integration/<app-lifetime-test>.exs` | New focused integration coverage is Wave 0; Phase 162 `C-APP-01..18`, `C-TOK-01..04` provide cases. |
| DCR-13 | Legacy nil/creation/past/future/stale secret dates remain unlimited; v0 promotion normalizes unrelated deadlines and atomically updates version/credential/audit; old package reads/writes before cutover. | DB integration + isolated package upgrade | `MIX_ENV=test mix test test/integration/<lifetime-upgrade-test>.exs` | New package upgrade test is Wave 0; existing install and clean-room harnesses are reusable. |
| DCR-14 | Fresh generated and custom-prefix storage roundtrip lifetime fields; valid custom adapter passes conformance; unsupported/missing/dropping adapters fail closed. | adapter conformance + generated host integration | `MIX_ENV=test mix test test/lockspire/storage/<lifetime-adapter-test>.exs test/integration/<lifetime-upgrade-test>.exs` | New conformance cases are Wave 0. |

The focused implementation proof belongs here. Phase 166 adds complete cross-phase package journeys and security/CI gates; do not let that ownership push basic runtime and upgrade evidence out of Phase 163. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:80-83]`

### Sampling Rate

- **Per task:** Run the focused ExUnit file(s) for the changed storage or protocol seam.
- **Per phase merge:** Run the relevant integration group and `mix test.fast`; run the isolated package upgrade journey for migration/adapter changes.
- **Phase gate:** No success claim from mocked expiry alone. Verify durable token/code/audit row counts and actual independent PostgreSQL blocking evidence.

### Wave 0 Gaps

- [ ] Focused app lifetime eligibility and endpoint-owned mapping tests covering equality, enabled/disabled, public and confidential clients.
- [ ] Client aggregate/record adapter conformance fixtures for round trips, version validation, current-row guards, rollback, unsupported declarations and shared transaction authority.
- [ ] PostgreSQL race helper that records holder/contender backend PIDs and verifies `pg_blocking_pids` before advancing the injected clock; cover both client lock and later grant/request/token wait.
- [ ] Packaged upgrade journey with new additive migration over real PostgreSQL, public and custom prefixes, an actual pinned pre-lifetime package plus candidate package in separate processes, v0 legacy dates, pre-v1 old read/write, and the post-v1 unsafe rollback boundary.
- [ ] Durable assertions for code remains unconsumed/token absent on expired code redemption, plus audit and credential/version/deadline rollback on failed write.

## Security Domain

The research protocol defaults security enforcement to enabled unless `.planning/config.json` explicitly sets `security_enforcement: false`; include the following review dimensions. Lifetime changes affect credential authorization and token issuance. `.planning/config.json` was read this session.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Keep credential proof distinct from current app eligibility; use constant existing hash/verification boundaries and retain endpoint-specific authentication errors. |
| V3 Session Management | no direct change | Host/RP sessions are explicitly unaffected; do not promise session logout or offline revocation. |
| V4 Access Control | yes | Enforce active/deadline at every applicable consumer and final durable issuance from current locked state, including public/private-key/mTLS clients. |
| V5 Input Validation | yes | Version and deadlines returned by a custom adapter must be schema/type validated; unknown state is a server configuration error. |
| V6 Cryptography | yes | Preserve existing credential hashing and encrypted secret-JWT verifier behavior; never put plaintext credentials/verifiers/hashes into audit or telemetry. |

### Known Threat Patterns for Elixir / Ecto / PostgreSQL

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stale preverified credential, app state, or lifetime snapshot authorizes after rotation/disable/expiry | Spoofing / Elevation | Re-lock, reload current row, compare verified credential identity, sample time after all blocking locks, and mutate current-row fields only. |
| Partial writes across client/grant/token/audit backends | Tampering / Repudiation | Require one declared transaction authority and test failures at each write/audit boundary for complete rollback. |
| Long-held client locks while doing remote JWKS, host callbacks, or push delivery | Denial of Service | Persist state first, end locks, then perform network/response work; revalidate fingerprints when work is prepared outside the transaction. |
| Legacy date ambiguity becomes expiry or malformed adapter state becomes unlimited | Elevation | Keep v0 effectively unlimited; reject missing/unknown version, retain historical advisory dates unchanged unless an atomic whole-row v0 promotion normalizes unrelated deadlines. |
| Migration lock contention or unsafe downgrade after authoritative v1 writes | Denial of Service / Tampering | Use additive prefix-aware migration, operationally validate lock acquisition, drain old writers before v1, and retain authoritative schema/data after cutover. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | Storage/integration and package upgrade evidence | ✓, accepting on local socket | 14.17 | None suitable for the required real race proof; plan execution should use it. |
| Elixir/Mix | Compile, migrations, and ExUnit | Binary shims found; no version selected | `elixir --version` and `mix --version` fail because asdf has no selected `.tool-versions` entry; available installed versions were listed by asdf | Select one installed version satisfying `mix.exs` `~> 1.18` for execution. |
| Python 3 | Existing clean-room acceptance harness | ✓ | 3.14.4 | — |
| Docker | Optional isolated service/container flows | ✓ | 29.5.2 | Existing local PostgreSQL can support focused DB tests; Docker availability does not replace package-process isolation. |

**Missing dependencies with no fallback:** None identified.  
**Missing dependencies with fallback:** Active Elixir/Mix selection must be configured before test/package tasks; at least Elixir 1.18 is required. `[VERIFIED: mix.exs:15-20]`

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Treat any existing credential date as an enforcement deadline | Versioned contract makes historical v0 dates advisory and only v1 deadlines authoritative | Selected in Phase 162 (2026-10-20) | No guessed expiry for pre-upgrade clients; new registrations have explicit lifetime state. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:60-70]` |
| Capture request time at ingress or rely on SQL transaction time | Capture injected decision time after current rows and all relevant locks | Selected in Phase 162 (2026-10-20) | Expiry at equality after lock waits is enforced consistently. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:9-16,75-79]` |
| Assume independent custom store callbacks compose safely | Explicit adapter lifetime declaration plus shared transaction authority and conformance | Selected in Phase 162 (2026-10-20) | Unsupported hosts fail as server configuration rather than receive false unlimited behavior. `[VERIFIED: .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:72-75]` |

**Deprecated/outdated:** None identified in library versions for this phase. Avoid interpreting the currently unused saved app/secret lifetime policy fields as proof of runtime enforcement; Phase 153 flagged this behavior gap and Phase 162 selected new semantics. `[VERIFIED: .planning/milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md; .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md:1-4]`

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `lifetime_version` and the selected adapter declaration can be threaded through current domain/storage and dependency seams without a public configuration API break. | Architecture Patterns | Could require a broader adapter migration or staged compatibility API; inspect all external adapter shapes before locking exact callbacks. |
| A2 | The existing clean-room package harness can execute old and candidate packages against isolated databases/processes with a small bounded extension. | Standard Stack / Validation Architecture | If not, Phase 163 needs another existing package test seam or a narrower executable proof; a synthetic fixture alone is insufficient. |
| A3 | For app-only issuance, the contract's effective expiry cap is implemented without pulling Phase 164 secret enforcement or Phase 165 management-token expiry into scope. | Code Examples | Scope may blur and falsely close later requirements. Keep ownership explicit in plans and acceptance cases. |

## Open Questions

1. **Exact adapter declaration shape:** The locked choice requires adapter-owned version and shared transaction authority but leaves names/types to implementation. Decide a narrow, typed shape during planning after tracing every host composition and do not reuse the permissive capabilities default.
2. **Exact packaging fixture shape for old/candidate proof:** The clean-room harness already builds a package from checkout. Planning must choose how to pin the pre-lifetime build/revision and keep two binaries isolated without using a checked-out source tree as proof of package behavior.
3. **Clock propagation point for registration:** `build_dcr_client/4` samples its own wall clock today. Thread a deterministic clock through the existing registration boundary without broad public-option churn, while preserving operator registration's existing lifetime policy boundary.

## Sources

### Primary (HIGH confidence)

- `.planning/phases/163-app-lifetime-compatible-host-storage/163-CONTEXT.md` — all locked implementation constraints, integration inventory, scope, and primary reference list.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md` — normative time, consumer, token, legacy, adapter, concurrency and deployment semantics.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CASES.json` — concrete boundary, adapter, race, upgrade and handoff cases; design examples only.
- `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` — DCR-05/06/13/14 text, phase goal, and four success criteria.
- `AGENTS.md` — embedded-library boundary, stack, security defaults and admin copy requirements.
- Current source read this session: `lib/lockspire/domain/client.ex`, `lib/lockspire/client_metadata.ex`, `lib/lockspire/storage/client_store.ex`, `lib/lockspire/storage/ecto/client_record.ex`, `lib/lockspire/storage/ecto/repository/client_store.ex`, `lib/lockspire/storage/ecto/repository/transaction_store.ex`, `lib/lockspire/storage/ecto/migration.ex`, `lib/lockspire/install/migrations.ex`, `lib/lockspire/protocol/token_exchange/internal/dependencies.ex`, `lib/lockspire/protocol/token_exchange/internal/legacy_options.ex`, `test/lockspire/storage/repository_concurrency_test.exs`, `test/lockspire/storage/repository_atomicity_test.exs`, `scripts/acceptance/clean_room/build_provider.py`, `scripts/acceptance/clean_room/package_input.py`, `mix.exs`, and `config/test.exs`.
- Ecto transaction semantics, Ecto SQL sandbox semantics, PostgreSQL 14 MVCC/row lock/time/DDL/session diagnostics, linked from Phase 163 context: [Ecto `Repo`](https://raw.githubusercontent.com/elixir-ecto/ecto/v3.13.6/lib/ecto/repo.ex), [Ecto SQL Sandbox](https://raw.githubusercontent.com/elixir-ecto/ecto_sql/v3.13.5/lib/ecto/adapters/sql/sandbox.ex), [PostgreSQL transaction isolation](https://www.postgresql.org/docs/14/transaction-iso.html), [row and table locks](https://www.postgresql.org/docs/14/explicit-locking.html#LOCKING-ROWS), [date/time functions](https://www.postgresql.org/docs/14/functions-datetime.html#FUNCTIONS-DATETIME-CURRENT), [ALTER TABLE](https://www.postgresql.org/docs/14/sql-altertable.html), [session information functions](https://www.postgresql.org/docs/14/functions-info.html#FUNCTIONS-INFO-SESSION-TABLE).

### Secondary (MEDIUM confidence)

- `.planning/milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md` — completed baseline behavior audit to avoid repeating; current source and Phase 162 contract take precedence.
- `.planning/research/dcr-lifetimes/SCOPE.md` and `.planning/research/dcr-lifetimes/SUMMARY.md` — milestone scope and prior research context.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — read current `mix.exs`, project instructions, and local PostgreSQL/clean-room harness configuration.
- Architecture: HIGH — traced existing client domain, record mapping, repository facade, transactional client store, dependency adapter, and migration tooling; required runtime composition still needs Phase 163 proof.
- Pitfalls: HIGH — locked contract and current source show the stale whole-row replacement, permissive adapter default, missing lifetime fields, and transaction/time requirements.

**Research date:** 2026-10-20  
**Valid until:** 2026-11-19 for storage patterns; re-check PostgreSQL/Ecto behavior if supported major/minor versions change.
