# Phase 177: Safe Verifier Maintenance & Recovery - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md; this log preserves the analysis.

**Date:** 2026-10-25
**Phase:** 177-safe-verifier-maintenance-recovery
**Mode:** assumptions, delegated research/recommendation adoption
**Areas analyzed:** store authority/atomicity, age-preserving custody, exhaustive readiness, repo-safe tooling, operator recovery, disclosure

## User Direction

After invoking `$gsd-discuss-phase 177`, the owner supplied the fan-out boilerplate: use subagents, prefer reputable primary sources, compare pros/cons/footguns through relevant stakeholder lenses, account for `prompts/` with newer brandbook precedence, synthesize coherent recommendations, and “auto follow those.” They prefer small/flat dependencies and auditable local glue. This authorizes adoption of scoped engineering recommendations; no extra confirmation gate was imposed. No `--auto` command-line flag was invented.

## Assumptions Presented Through Analysis

| Assumption | Initial confidence | Evidence | Disposition |
|---|---|---|---|
| Selected optional authority and verifier-only update/audit must share outer transaction | Confident | 175-CONTRACT maintenance section; Ecto ClientStore and ClientLifetime | Retain frozen contract |
| Actual maintenance/issuance contention remains unproved by synthetic Phase 176 mutation | Confident | 176-CONTEXT D-13; guarded issuance integration test | Require real PostgreSQL proof |
| Dedicated rewrap must preserve authenticated age metadata and validate hash | Confident | ClientSecretVerifier open/seal difference; approved policy revision | Internal custody path |
| Elapsed dedicated migrated material can move keys without changing eligibility | Likely | Exhaustive expired-row scope; auth reader deadline enforcement | Selected after primary-source precedent |
| Legitimate public nil material must differ from broken expected material | Likely | Clients public material branch | Selected safe classification |
| Full fresh traversal and local config labels determine check meaning | Confident | Frozen page/readiness contract | Preserve explicit limits |
| Bare Mix needs operation-local config resolution | Likely | Config startup caches; RepoRunner; Mix task | Confirmed by Mix source/docs |
| Key loss requires restoration or authorized replacement with truthful consequence | Confident | Existing lifecycle/admin rotation; frozen contract | Preserve no fallback |
| Existing full-row/Inspect paths belong in disclosure proof | Confident | Support sensitive option; ClientRecord/Domain.Client/RegistrationResult | Include in phase scope |

## Alternatives and Synthesis

| Decision | Selected recommendation | Rejected alternative and cost |
|---|---|---|
| Expired dedicated custody | Authenticate and rewrap with original age metadata | Authentication reader reuse strands decryptable expired rows; ordinary reseal rejuvenates them |
| Legacy age | Preserve finite-age migration qualification | Timeless decoding violates approved policy |
| Nil material | Count valid no-secret absence; block missing expected material | All-nil failure strands normal public clients; all-nil success hides damaged JWT clients |
| Transactions | Short row transaction, lock/reload/material compare, atomic audit | Whole-scan/table locks extend disruption; blind updates lose concurrent rotation; SKIP LOCKED hides rows |
| Cursor | Same explicit bytewise predicate/order | Host locale can skip or misorder page boundaries; adding an index now lacks scale evidence |
| Tooling | One narrow callable core and verifier-specific task with three modes | Separate commands duplicate help/API; signing-task switches conflate custody; full app start launches unrelated workers |
| Config | Local bare-Mix snapshot; startup snapshot for release RPC | Cache mutation silently hot-reloads serving nodes; startup cache use before boot fails valid bare tasks |
| Disclosure | Query suppression, safe error projection and struct redaction together | Final-output sanitization/Inspect alone cannot protect raw SQL params/results/driver errors |
| Recovery | Restore valid key or explicitly replace credential | Silent regeneration breaks partners; no lost-key/secret reconstruction is possible |

## Corrections Made

No user corrections. Research refined the initially Likely assumptions into selected engineering defaults within the frozen scope. Expired dedicated rewrap does not relax authentication or legacy migration; no-material classification does not exempt any persisted ciphertext. No public support/API-policy revision was required.

## External Research

- PostgreSQL 14 applies expression collation to both comparisons and ordering; explicit `C` provides byte order on UTF-8 databases. Both cursor clauses must agree. [Collations](https://www.postgresql.org/docs/14/collation.html).
- READ COMMITTED locking reads wait and inspect the updated row, supporting locked comparison after concurrent rotation. Independent connections and lock barriers are needed for proof. [Isolation](https://www.postgresql.org/docs/14/transaction-iso.html).
- Exact Ecto SQL 3.13.5 source independently controls telemetry and Logger; telemetry includes raw parameters/results. [Source](https://github.com/elixir-ecto/ecto_sql/blob/v3.13.5/lib/ecto/adapters/sql.ex#L1265-L1354).
- Ecto 3.13.6 `update_all` does not automatically change timestamps; selected verifier-only updates fit the contract. [Source](https://github.com/elixir-ecto/ecto/blob/v3.13.6/lib/ecto/repo.ex).
- Postgrex 0.22.4 error formatting includes query/server detail; DBConnection 2.10.2 has an independent disconnection logging path. Query options alone are not comprehensive failure-disclosure proof. [Postgrex](https://github.com/elixir-ecto/postgrex/blob/v0.22.4/lib/postgrex/error.ex), [DBConnection](https://github.com/elixir-ecto/db_connection/blob/v2.10.2/lib/db_connection/connection.ex#L143-L164).
- MultiFernet rotation preserves original timestamp; pinned source authenticates/decrypts without applying TTL and reencrypts with that original timestamp. This is a custody precedent, not a proposed algorithm/dependency change. [Docs](https://cryptography.io/en/46.0.3/fernet/), [source](https://raw.githubusercontent.com/pyca/cryptography/46.0.3/src/cryptography/fernet.py).
- Vault separates rewrap from plaintext retrieval and per-item failures; old-key destruction is distinct from rotation/removal. [Rewrap](https://developer.hashicorp.com/vault/api-docs/secret/transit#rewrap-data), [trim](https://developer.hashicorp.com/vault/api-docs/secret/transit#trim-key).
- Mix app.config loads runtime configuration without host startup; release rpc operates on the running node. [App config](https://hexdocs.pm/mix/1.19.5/Mix.Tasks.App.Config.html), [release](https://hexdocs.pm/mix/1.19.5/Mix.Tasks.Release.html).
- PostgreSQL server parameter logging remains host controlled. [Logging](https://www.postgresql.org/docs/14/runtime-config-logging.html).

## Applied Lenses and Stop Condition

Security/cryptography, Elixir library architecture, Ecto/PostgreSQL concurrency, integrator DX, operator JTBD, SRE recovery, observability and adversarial verification all converge on the same scoped bundle. Relevant prompt guidance was considered; PRODUCT.md and brandbook/ remain authoritative for current language/identity. Visual design work is unnecessary for this CLI/API maintenance phase.

Further fan-out has diminishing returns: lock/rollback, mixed-state inspection, failure redaction and bare-Mix behavior need execution evidence. Phase 177 requirements remain pending until implemented and independently verified; Phase 178 package/delivery ownership is unchanged.
