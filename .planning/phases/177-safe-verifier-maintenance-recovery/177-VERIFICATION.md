---
phase: 177-safe-verifier-maintenance-recovery
verified: 2026-10-26T04:44:53Z
status: passed
score: 47/47 must-haves verified
covered_files:
  - .planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-COMPATIBILITY.json
  - .planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTEXT.md
  - .planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-CONTRACT.md
  - .planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-FINAL-SOURCE.json
  - .planning/phases/175-accepted-baseline-verifier-compatibility-contract/175-POLICY-REVISION.md
  - .planning/phases/176-dedicated-verifier-custody-compatible-runtime/176-CONTEXT.md
  - .planning/phases/176-dedicated-verifier-custody-compatible-runtime/176-HANDOFF.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-01-PLAN.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-01-SUMMARY.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-02-PLAN.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-02-SUMMARY.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-03-PLAN.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-03-SUMMARY.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-04-PLAN.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-04-SUMMARY.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-05-PLAN.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-05-SUMMARY.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-06-PLAN.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-06-SUMMARY.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-07-PLAN.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-07-SUMMARY.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-08-PLAN.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-08-SUMMARY.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-09-PLAN.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-09-SUMMARY.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-CONTEXT.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-FINAL-GATES.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-HANDOFF.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-ISOLATION-FIX.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-RESEARCH.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-REVIEW-DISPOSITION.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-REVIEW-FIX.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-REVIEW-INITIAL.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-REVIEW.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-SECURITY-INITIAL.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-SECURITY-OPEN-REVIEW.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-SECURITY.md
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-SOURCE-ACCEPTANCE.json
  - .planning/phases/177-safe-verifier-maintenance-recovery/177-VALIDATION.md
  - docs/client-secret-jwt-host-guide.md
  - docs/client-secret-verifier-configuration.md
  - docs/supported-surface.md
  - lib/lockspire/admin/client_verifier_maintenance.ex
  - lib/lockspire/config.ex
  - lib/lockspire/domain/client.ex
  - lib/lockspire/security/client_secret_verifier.ex
  - lib/lockspire/security/client_secret_verifier/operation_context.ex
  - lib/lockspire/storage/client_verifier_maintenance.ex
  - lib/lockspire/storage/ecto/client_record.ex
  - lib/lockspire/storage/ecto/repository.ex
  - lib/lockspire/storage/ecto/repository/client_store.ex
  - lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex
  - lib/mix/tasks/lockspire.clients.verifier.rewrap.ex
  - test/integration/client_secret_verifier_maintenance_concurrency_test.exs
  - test/integration/client_secret_verifier_maintenance_disclosure_test.exs
  - test/integration/client_secret_verifier_maintenance_issuance_test.exs
  - test/integration/client_secret_verifier_maintenance_recovery_test.exs
  - test/integration/client_secret_verifier_maintenance_test.exs
  - test/integration/install_generator_test.exs
  - test/lockspire/admin/client_verifier_maintenance_test.exs
  - test/lockspire/compatibility_baseline_contract_test.exs
  - test/lockspire/config_client_secret_verifier_test.exs
  - test/lockspire/quality/proof_quality_baseline_test.exs
  - test/lockspire/security/client_secret_verifier_inspection_test.exs
  - test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs
  - test/lockspire/security/client_secret_verifier_maintenance_test.exs
  - test/lockspire/storage/client_verifier_maintenance_test.exs
  - test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs
  - test/support/architecture/public_compatibility_manifest.ex
  - test/support/client_verifier_maintenance_concurrency.ex
  - test/support/delegated_verifier_maintenance_store.ex
covered_digest: "v3:sha256:4c4b092c64b3975f86175181ac548c0152107fd5c86565e9da2305d35bf1cf88"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 23
  total: 23
  not_honored: []
unverified_prohibitions:
  - statement: "MUST NOT treat custody maintenance as authority to replace partner credentials or extend their authenticated lifetime."
    status: unverified
    flagged: true
    disposition: "non-authoritative autonomous flag; human review recommended"
  - statement: "MUST NOT turn a local complete custody check into permission to retire fleet or backup keys."
    status: unverified
    flagged: true
    disposition: "non-authoritative autonomous flag; human review recommended"
  - statement: "MUST NOT turn missing-key recovery into automatic partner-secret replacement without the existing authorized one-time handoff."
    status: unverified
    flagged: true
    disposition: "non-authoritative autonomous flag; human review recommended"
---

# Phase 177: Safe Verifier Maintenance & Recovery Verification Report

**Phase Goal:** Operator can inspect, rewrap and rotate verifier-key custody safely, and recover affected clients after key loss, without changing partner secrets or hiding failed work.
**Verified:** 2026-10-26T04:44:53Z
**Status:** passed
**Re-verification:** No — initial verification; no prior Phase 177 verification report existed.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---:|---|---|---|
| 1 | Maintainer can preview, apply, check and retry partial work; conflicts/failures remain distinct and requested completion fails when unmet, with accurate guidance and bare-Mix behavior. | VERIFIED | `Admin.ClientVerifierMaintenance.run/1` separates scan completion, progress and readiness; task tests execute dry-run/apply/check, failures, invalid options, Repo cleanup and existing Repo ownership. |
| 2 | Selected PostgreSQL authority, CAS, rollback and contention preserve verifier-only writes, audit atomicity, hashes, lifecycle and rotation fields; unsupported capability fails before access. | VERIFIED | Storage preflight and exact declaration validation; SQL row lock and compare-and-rewrap; independent-backend lock tests capture both backend PIDs and verify `pg_blocking_pids`; rollback/audit/field-preservation tests pass. |
| 3 | Status scans all stored rows and distinguishes material/custody states; no partial or local scan claims complete or fleet readiness. | VERIFIED | Inventory query has no active, expiry or auth-method filter, uses UTF-8 validation plus identical `COLLATE "C"` cursor/order semantics; Admin validates page shape/order and only a fresh nil-cursor full check can satisfy local custody readiness. |
| 4 | Operator can stage/read keys, activate writes, rewrap and retire old-key custody; key-loss clients can be recovered by restoring the original key or existing authorized rotation while JWT auth fails closed. | VERIFIED | Persisted recovery journey exercises reader-first staging, apply, fresh check, unknown-key reporting, original-key restoration and authorized rotation handoff; unaffected Basic/post auth and lifecycle checks remain active. |
| 5 | Success/failure diagnostics do not disclose verifier plaintext, key bytes or ciphertext; unrelated authentication, one-time handoff shape and owned protocol responses remain intact. | VERIFIED | Redaction, sensitive-query dual-channel suppression, safe error mapping and sentinel tests cover Logger, query telemetry, audit, reports, nested Inspect, task/API/protocol paths, pool/schema errors and a triggered-and-rolled-back audit insert. |
| 6 | D-01: Selected maintenance and lifetime declarations, transaction authority and all participants match before inventory or client access. | VERIFIED | `configured/0` checks the selected client store, lifetime contract, authority identity and exact participant map; spy tests reject before access. |
| 7 | D-02/D-08: Rewrap changes only native verifier custody while preserving partner secret/hash and every other stored field. | VERIFIED | Explicit `update_all` sets only verifier ciphertext; persisted test snapshots protected fields and authenticates the unchanged partner secret. |
| 8 | D-03: Exact retry is `already_current` without a second write/audit; stale changed material is `material_conflict`; caller sees changed only after outer commit. | VERIFIED | Repository callback has explicit equality branches; integration tests check repeat/audit count, stale conflict and report boundary; outer rollback tests leave both verifier and audit unchanged. |
| 9 | D-02/D-03: Replacement ciphertext and allowlisted audit commit together under the selected outer transaction. | VERIFIED | Callback requires an open transaction and validates exact audit values before locking; actual audit failure and forced outer rollback prove atomicity. |
| 10 | D-05: Current-key classification requires authenticated identity/purpose-bound material and hash agreement; forged headers/corruption cannot establish readiness. | VERIFIED | Shared AEAD/AAD decoder, hash check and reserved `LSCV` family path run before classification; unit and persisted tests cover tampering, unknown/malformed material, wrong identity and hash divergence. |
| 11 | D-06: Dedicated migrated rewrap preserves authenticated age discriminator/timestamps, even after expiry, while JWT authentication still rejects expired material. | VERIFIED | Custody decoder allows expired structurally valid migrated data, serializes original `signed_at_ms`/`deadline_ms`, and authentication retains strict expiry; unit and persisted equality/expired cases cover both paths. |
| 12 | D-07: Only finite authenticated legacy metadata with matching hash is promoted; aged, future, malformed, unsupported or unbounded data stays unchanged. | VERIFIED | Promotion calls the qualified legacy metadata reader and keeps the original deadline; rejected inputs and persisted rows remain unchanged in unit/integration tests. |
| 13 | D-08: Current-key data is a no-op; custody rewrap does not replace partner secret/hash or alter credential lifecycle authority. | VERIFIED | Current-key branch returns already-current; test asserts no update/audit and unchanged secret/hash/expiry/rotation fields. |
| 14 | D-09: Inventory includes every row and applies exclusive canonical UTF-8 byte order with page bounds 1–500 and default 100. | VERIFIED | SQL uses matching `COLLATE "C"` order and cursor comparison and confirms server encoding `UTF8`; PostgreSQL tests cover non-ASCII/adjacent IDs, boundaries and limits. |
| 15 | D-10: Legitimate public/no-secret clients count as inspected no-material, while missing expected material, orphan verifier or incoherent pairs require attention. | VERIFIED | `classify_material/3` distinguishes the public `:none` no-material case; missing/orphan statuses and fresh-check readiness are exercised with persisted fixtures. |
| 16 | D-11: Legacy/current/old-key/unknown/malformed/unreadable/expired-migrated/uninspected states are distinct, with safe authenticated metadata only. | VERIFIED | Authenticated inspection maps only allowlisted reason/action atoms and validated key IDs; hostile/header cases do not treat parsed IDs as proof; status tests verify classifications and report redaction. |
| 17 | D-12: Scan completion, committed progress and readiness are separate; resumed or malformed/incomplete traversal cannot establish readiness. | VERIFIED | Admin report tracks those fields separately, rejects invalid page order/cursor and fresh-check cursor, and tests interrupted progress, retry and incomplete inventory. |
| 18 | D-16/D-17: Preview/check are read-only, apply reports retained progress/failure truthfully, and details are bounded, safe and actionable. | VERIFIED | Read-only mode assertions, partial apply failure outcomes, capped details, encoded hostile IDs and fixed next actions are in Admin/task tests. |
| 19 | D-13: Host/release callers use a Mix-free core and the thin task defaults to apply with dry-run/check modes. | VERIFIED | Core is `Lockspire.Admin.ClientVerifierMaintenance.run/1`; Mix task calls the core through TaskError/RepoRunner; CLI subprocess tests exercise default/apply, preview and check. |
| 20 | D-14: Bare Mix resolves task-local verifier context and uncached signing-key exclusions without starting host supervision; Repo ownership and cleanup are preserved. | VERIFIED | OperationContext freshly resolves verifier and signing configuration without persistent-term writes; subprocess and RepoRunner tests prove temporary Repo cleanup and preservation of a running Repo/pool. |
| 21 | D-15: Running API/RPC uses immutable startup context; task-local work does not replace it or silently hot-reload the serving process. | VERIFIED | Admin defaults to startup snapshot and labels task-local context; config tests verify startup snapshot unchanged; docs distinguish release RPC from unbooted eval. |
| 22 | D-16: Invalid/exclusive args fail before DB access and every unmet requested completion/readiness outcome fails. | VERIFIED | Mix task validates original argv, duplicate flags, mode combinations, limit and cursor before Repo resolution; tests assert safe exit behavior; Admin returns error for failed check/apply. |
| 23 | D-22: Independent PostgreSQL transactions prove both maintenance/rotation lock orders with observed contender/blocker PIDs. | VERIFIED | Harness uses unboxed connections, explicit message barriers and `pg_blocking_pids(contender)` membership for the exact held backend; both rotation-first and maintenance-first tests pass. |
| 24 | D-02: Concurrent metadata edits and authorized secret rotation retain authoritative current fields while maintenance updates only verifier custody. | VERIFIED | Actual row lock/reload and exact CAS are exercised with before/after all-column snapshots and concurrent metadata and secret-rotation transactions. |
| 25 | D-03: Exact-repeat/overlap outcomes and failed or ambiguous commit results never masquerade as committed success. | VERIFIED | Repeat has one audit; randomized replacements conflict; provisional rollback leaves no state; simulated lost commit response fails and fresh complete scan reconciles. |
| 26 | D-22: Audit rejection, outer rollback and partial-run retry preserve committed progress without false success telemetry. | VERIFIED | Database-trigger and callback rollback tests assert unchanged ciphertext/no audit; partial progress survives and fresh retry converges; telemetry is emitted only after commit. |
| 27 | D-04: Real maintenance between JWT authentication and issuance invalidates prior verified identity, creates no successful grant/token effects, and requires a fresh JTI. | VERIFIED | Independent backend pauses after authentication/JTI and before current-row guard, commits actual maintenance, then asserts credential-changed response, absent issuance effects, consumed JTI and successful fresh-JTI retry. |
| 28 | D-18: Reader-first key activation, rewrap/retry and fresh local check are proved; fleet, backup and rollback obligations remain separate. | VERIFIED | Recovery test exercises staged old/new readers, explicit write activation, preview/apply/retry and fresh nil-cursor check; documentation clearly leaves fleet and backup evidence to host. |
| 29 | D-19: Missing/lost-key status identifies affected clients, JWT fails closed, and restoring the original key preserves partner credentials. | VERIFIED | Persisted recovery test checks unknown-key detail, unchanged secret/hash, no auth effects while missing key, then successful auth after original-key restoration. |
| 30 | D-19: Existing authorized rotation/reprovision recovers affected clients with one-time handoff and preserves unrelated methods/lifecycle. | VERIFIED | Test invokes `Admin.Clients.rotate_client_secret/2`, checks exact two-key result shape and new secret/hash, rejects old secret, accepts replacement, and confirms Basic/post, disabled and expiry controls. |
| 31 | D-20: Ecto/domain/nested result Inspect redacts stored credentials while preserving authorized one-time plaintext handoff maps. | VERIFIED | ClientRecord Ecto fields are redactable, Domain.Client and RegistrationResult Inspect exclusions compose, and contract tests assert exact public map shape and nested redaction. |
| 32 | D-20: Full-client SQL operations suppress both Logger and raw query telemetry when material is bound or returned. | VERIFIED | ClientStore routes sensitive read/write operations through Support, which sets `log: false` and `telemetry_event: nil`; capture tests include positive control and all changed full-client paths. |
| 33 | D-21: Sentinels stay out of Lockspire-owned success/failure diagnostics, query results/telemetry, audit, operator reports and protocol responses. | VERIFIED | Disclosure and inspection tests capture plaintext/key/ciphertext sentinels across successful operation, malformed material, HTTP invalid_client and nested results; a successful capture control verifies the observer sees a deliberately emitted sentinel. |
| 34 | D-21: Missing-schema/pool/connection/crypto/audit/hostile-identifier failures stay safe; success telemetry follows commit. | VERIFIED | Forced missing-schema and refused-pool paths return bounded errors; valid audit attrs reach a trigger that increments a unique sequence before raising, with `[1, true]` after rollback and no marker, row or verifier change. |
| 35 | D-17/D-18: Guidance describes local observation, full fresh check, reader-first activation and separate host retirement checks. | VERIFIED | Current configuration guide gives tested commands and reader-first sequence, says local checks are not fleet/backup/rollback proof, and advises a fresh check before retirement; guidance tests bind CLI/doc assertions. |
| 36 | D-15/D-19: Guidance distinguishes release RPC/startup context from unbooted eval and restoration from authorized replacement consequences. | VERIFIED | Guide and executable guidance tests describe immutable RPC snapshot and distinguish restoring key (same partner secret) from rotation (new one-time secret handoff). |
| 37 | D-23: Source requirements and stable Phase 175 cases are bound to observed commands/results without restamping earlier receipts. | VERIFIED | Source receipt names tested SHA, exact commands/counts/log hashes, six requirement mappings and stable cases; all 27 referenced output-log digests and 13 frozen 175 input digests independently matched. |
| 38 | D-23: Phase 177 source gate is distinct from package-installed pair/composition and final delivery/main acceptance assigned to Phase 178. | VERIFIED | Roadmap, source receipt and handoff keep those activities pending/out of scope; no package, delivery or main-acceptance claim appears in current source. |
| 39 | VUP-03/concurrency: interrupted or overlapping work retains committed progress; conflicts fail completion and fresh retry/check reconciles all material. | VERIFIED | Independent PostgreSQL partial-progress, overlap and lost-response tests inspect stored state and require fresh complete reconciliation. |
| 40 | VOPS-01/idempotency: repeating committed replacement returns already-current without another write or audit. | VERIFIED | Integration callback assertions compare ciphertext/updated_at and audit row count after exact repeat. |
| 41 | VOPS-01/concurrency: overlapping replacements may conflict; partial/interrupted run does not claim completion and a fresh scan reconciles. | VERIFIED | Randomized fresh-IV replacements serialize with stale contender conflict; Admin/test adapter injects incomplete pages and recovery performs full fresh scan. |
| 42 | VOPS-02/idempotency: repeated callback preserves hash/all other columns and does not duplicate audit. | VERIFIED | Ecto callback branch returns before update/audit for already-installed replacement; exact before/after persisted row and count assertions pass. |
| 43 | VOPS-02/concurrency: independent lock orders and metadata edits preserve authoritative state. | VERIFIED | Real PostgreSQL barrier suite observes blocker PIDs in both orders and verifies rotated hash/verifier/deadlines/timestamps and metadata after commits. |
| 44 | VOPS-03/adjacency: cursor equals an existing ID exclusively and adjacent bytewise IDs remain unique and separate. | VERIFIED | PostgreSQL page tests start after exact existing cursors, use adjacent case/dot/combining/non-ASCII IDs and assert every row once. |
| 45 | VOPS-03/empty: empty/singleton pages terminate correctly and legitimate no-material rows do not block readiness. | VERIFIED | Storage page terminal logic uses bounded lookahead; empty and singleton tests assert exact page result; Admin fresh-check covers public/no-secret client. |
| 46 | VOPS-03/ordering: bytewise traversal is stable and duplicate/out-of-order adapter rows fail completion. | VERIFIED | SQL applies the same C-collation expression to order and cursor; Admin tests reject duplicate/out-of-order page IDs and incomplete cursor shapes. |
| 47 | VOPS-03/readiness: rows across inactive/expired/non-JWT states and all persisted verifier material remain visible and unresolved material is not presented as ready. | VERIFIED | Inventory has no such row filters; recovery and inventory fixtures span inactive/expired/Basic/post/public clients and verify distinct outcomes. |

**Score:** 47/47 truths verified (0 present, behavior-unverified).

### Decision Coverage

The decision-coverage verifier returned `total: 23`, `honored: 23`, `not_honored: []` for D-01–D-23. I also traced the decisions to the live service/storage/crypto/task paths and behavior-focused tests; this count is a warning-only coverage check, not the runtime evidence by itself.

| Decision | Source evidence | Status |
|---|---|---|
| D-01 | Selected client/lifetime/transaction/audit declarations and pre-access rejection tests | Honored |
| D-02 | Locked reload, exact CAS, ciphertext-only update and concurrent field-preservation tests | Honored |
| D-03 | Post-commit result, exact retry/conflict, rollback and uncertain-commit reconciliation tests | Honored |
| D-04 | Real maintenance/guarded-issuance/JTI race with no issuance side effects | Honored |
| D-05 | Authenticated AEAD/AAD/hash inspection and adversarial material tests | Honored |
| D-06 | Original age metadata preserved on expired migrated custody; auth still expires | Honored |
| D-07 | Finite authenticated legacy qualification and unchanged rejection cases | Honored |
| D-08 | Current-key no-op and partner secret/lifecycle preservation | Honored |
| D-09 | Full inventory, UTF-8 assertion, identical bytewise cursor/order and bounds | Honored |
| D-10 | no-material, missing-material and orphan distinctions | Honored |
| D-11 | Distinct safe status vocabulary; only authenticated key IDs appear | Honored |
| D-12 | Separate scan/progress/readiness and fresh nil-cursor check | Honored |
| D-13 | Mix-free Admin operation and focused verifier-only Mix task | Honored |
| D-14 | Bare operation-local key resolution and task-owned Repo lifecycle tests | Honored |
| D-15 | Immutable startup context, task-local label and RPC/eval guidance | Honored |
| D-16 | Read-only preview/check, failing incomplete apply/check, pre-DB argument validation | Honored |
| D-17 | Bounded encoded identity, fixed reasons, safe actions and report caps | Honored |
| D-18 | Reader-first activation and fresh check; fleet/backup/rollback kept host-owned | Honored |
| D-19 | Original-key restoration and authorized one-time replacement recovery | Honored |
| D-20 | Ecto/domain Inspect, both SQL diagnostic channels and safe error mapping | Honored |
| D-21 | Success and forced-failure sentinel matrix plus explicit host/server-log boundary | Honored |
| D-22 | Independent PostgreSQL connections, message barriers and observed blocker PIDs | Honored |
| D-23 | Frozen Phase 175 references and source/package/delivery evidence boundaries | Honored |

### Unresolved Flags and Prohibitions

The following remain visible and unresolved; they are not runtime passes or threats closed by this verification:

- **E-09 / VOPS-04:** unclassified edge; no deterministic category was supplied. The concrete VOPS-04 restoration and authorized-rotation behaviors above are tested, but I did not classify or dismiss the generic edge.
- **E-10 / VPROOF-01:** unclassified edge; no deterministic category was supplied. The owned diagnostic channels above have sentinel proof; the generic edge remains unclassified.
- **Three descriptorless prohibitions:** all three statements are retained in the frontmatter with `status: unverified`, `flagged: true`, and a non-authoritative autonomous disposition recommending human review. Code and tests exhibit the prohibited outcomes as avoided, but the original prohibition records have no verification-tier/evidence descriptors; I did not promote them to authoritative passes or invent an owner/approval.

These generic flags do not identify a distinct missing behavior in the current six source requirements and do not create a fabricated human-needed task. The report does not claim host fleet parity, quiescence, backup/rollback readiness, PostgreSQL server-log suppression, arbitrary-store support, package-installed dependency-pair/composed-adapter proof, publication, delivery, or accepted-main status. Phase 178 owns its documented package and delivery gates.

### Required Artifacts

All plan-declared artifacts passed existence and substantive checks (`verify.artifacts`: 21/21 across nine plans). The table records the behavior/code and wiring evidence traced manually because generic link matching cannot follow module aliases and callback dispatch.

| Artifact | Expected | Status | Evidence |
|---|---|---|---|
| `lib/lockspire/storage/client_verifier_maintenance.ex` | Optional capability, authority preflight and single-client operation | VERIFIED | Substantive typed callbacks; Repository implements behavior; Admin and task reach it through selected store. |
| `lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex` | Ecto bytewise inventory and locked verifier CAS/audit | VERIFIED | Real SQL query and explicit update; delegates are wired by Repository callbacks. |
| `test/integration/client_secret_verifier_maintenance_test.exs` | Persisted rewrap and preservation tracer | VERIFIED | 8 tests in corrected focused source evidence; current targeted subset also runs the file. |
| `lib/lockspire/security/client_secret_verifier.ex` | Authenticated custody inspection and age-preserving preparation | VERIFIED | AEAD/AAD parser is called by storage and Admin paths; security maintenance tests cover corruption/age. |
| `test/lockspire/security/client_secret_verifier_maintenance_test.exs` | Native/migrated/legacy and corruption proof | VERIFIED | Active tests exercise hash agreement, expiry and malformed/wrong-key inputs. |
| `lib/lockspire/admin/client_verifier_maintenance.ex` | Mix-free status, preview/apply/check and safe reports | VERIFIED | Selected inventory/rewrap calls feed report fields and CLI output; real DB pages are the source. |
| `test/lockspire/admin/client_verifier_maintenance_test.exs` | Readiness, status and partial-run proof | VERIFIED | Active tests run report modes and malformed/incomplete page cases. |
| `lib/lockspire/security/client_secret_verifier/operation_context.ex` | Task-local verifier context with signing exclusions | VERIFIED | Task calls resolver before Repo handling; Context validates a complete context. |
| `lib/mix/tasks/lockspire.clients.verifier.rewrap.ex` | Thin strict CLI with safe task lifecycle/output | VERIFIED | Task invokes Admin core through TaskError; tests execute subprocess and modes. |
| `test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` | Bare task, options, exits and Repo ownership | VERIFIED | Focused command executes this target; includes hostile argument and lifecycle assertions. |
| `test/support/client_verifier_maintenance_concurrency.ex` | Independent transaction barriers and observed blockers | VERIFIED | Called by the concurrency and guarded-issuance integration suites; uses independent backend PID queries. |
| `test/integration/client_secret_verifier_maintenance_concurrency_test.exs` | PostgreSQL lock, rollback, retry and convergence proof | VERIFIED | Current targeted run executes it; assertions verify stored results and blocker relationship. |
| `test/integration/client_secret_verifier_maintenance_issuance_test.exs` | Maintenance against guarded JWT issuance | VERIFIED | Current targeted run executes real issuance barrier and persisted side-effect assertions. |
| `test/integration/client_secret_verifier_maintenance_recovery_test.exs` | Key rollout, restoration and authorized rotation | VERIFIED | Current targeted run runs real persisted recovery/authentication journeys. |
| `test/lockspire/security/client_secret_verifier_inspection_test.exs` | Ecto/domain/nested Inspect and handoff compatibility | VERIFIED | Current targeted run executes public shape and sentinel assertions. |
| `test/integration/client_secret_verifier_maintenance_disclosure_test.exs` | Success/failure owned-channel sentinel capture | VERIFIED | Current targeted run executes 8 cases, including a sequence-witnessed triggered audit failure. |
| `test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs` | Executable CLI/API/documentation contract | VERIFIED | Current targeted run executes it; tests inspect actual task help, API and runbook conditions. |
| `docs/client-secret-verifier-configuration.md` | Operator key, task, rollout and recovery guide | VERIFIED | Linked from host guide and supported-surface page; guidance tests assert modes and boundaries. |
| `177-SOURCE-ACCEPTANCE.json` | Exact source, case, command and limit receipt | VERIFIED | JSON parsed; 27 recorded output digests match; tested source identity is present. |
| `177-HANDOFF.md` | Source result and Phase 178 boundary handoff | VERIFIED | Content agrees with six runtime outcomes, unresolved flags and source/package boundary. |

### Key Link Verification

The generic key-link checker produced false negatives for callback/alias links (16 links were reported “Target not referenced in source”). I traced the calls, behavior declarations, repository delegates and tests directly; all 17 planned links are WIRED.

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `lib/lockspire/storage/client_verifier_maintenance.ex` | `lib/lockspire/storage/ecto/repository.ex` | selected capability inside selected transaction | WIRED | Generic service calls selected callbacks; Repository implements behavior. |
| `lib/lockspire/storage/ecto/repository.ex` | `lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex` | thin delegates | WIRED | Aliased implementation receives `repo()` for inventory and CAS. |
| `lib/lockspire/storage/client_verifier_maintenance.ex` | `lib/lockspire/security/client_secret_verifier.ex` | `prepare_rewrap/5` | WIRED | Real pre-transaction material preparation calls authenticated crypto. |
| `lib/lockspire/admin/client_verifier_maintenance.ex` | `lib/lockspire/storage/client_verifier_maintenance.ex` | selected pages and per-row committed operation | WIRED | Admin walks selected store and invokes `rewrap_client/2`. |
| `lib/lockspire/admin/client_verifier_maintenance.ex` | `lib/lockspire/security/client_secret_verifier.ex` | authenticated status inspection | WIRED | Classifier calls `inspect_custody/5` and only emits safe metadata. |
| `lib/mix/tasks/lockspire.clients.verifier.rewrap.ex` | `lib/lockspire/install/task_error.ex` | guarded Repo lifecycle | WIRED | `TaskError.run/2` wraps `RepoRunner` and returns before report rendering. |
| `lib/lockspire/security/client_secret_verifier/operation_context.ex` | `lib/lockspire/security/client_secret_verifier/context.ex` | complete validated local context | WIRED | Resolver calls `Context.resolve/2`; it does not mutate serving cache. |
| concurrency integration test | `lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex` | independent PostgreSQL callback | WIRED | Tests call the actual repository callback and inspect persisted rows/audit. |
| `lib/lockspire/storage/client_verifier_maintenance.ex` | selected `TransactionStore.transact/1` | commit boundary | WIRED | Calls the selected configured transaction store and rejects nested reporting transactions. |
| issuance integration test | `lib/lockspire/protocol/token_exchange/internal/client_authentication.ex` | ciphertext-sensitive verified identity | WIRED | Real token exchange reaches auth identity and later current-row guard around maintenance. |
| recovery integration test | `lib/lockspire/admin/clients.ex` | existing authorized secret rotation | WIRED | Invokes existing rotate path and asserts exact handoff shape and credential transition. |
| `lib/lockspire/storage/ecto/repository/client_store.ex` | `lib/lockspire/storage/ecto/repository/support.ex` | sensitive SQL options | WIRED | Full-client paths pass `sensitive: true`; Support disables logger and telemetry event. |
| `lib/lockspire/clients/registration_result.ex` | `lib/lockspire/domain/client.ex` | nested Inspect exclusions | WIRED | RegistrationResult embeds Domain.Client, whose credential fields are excluded. |
| Mix task | `lib/lockspire/admin/client_verifier_maintenance.ex` | mode invocation and report rendering | WIRED | Task invokes core with explicit context source then renders allowlisted report atoms. |
| configuration runbook | guidance contract test | executable command/mode assertions | WIRED | Test loads documented guidance and checks command and recovery boundaries. |
| `177-SOURCE-ACCEPTANCE.json` | Phase 175 compatibility ledger | stable acceptance IDs | WIRED | Receipt references all eight stable source cases without modifying frozen ledger. |
| `177-VALIDATION.md` | `177-SOURCE-ACCEPTANCE.json` | task results and evidence mapping | WIRED | Validation cites exact command results and source receipt. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Ecto inventory → Admin report | `ClientRecord`/`Client` page | Selected PostgreSQL repository query across all rows | Yes; persisted rows, bounded lookahead and canonical client IDs | FLOWING |
| Custody classifier | stored verifier/hash | Selected persisted client row → authenticated AEAD/AAD decoder and hash check | Yes; decoded secret stays internal; safe classification/metadata returned | FLOWING |
| Rewrap and audit | replacement ciphertext/outcome | Authenticated existing material plus validated current key → selected transaction callback/DB | Yes; verifier-only SQL update and audit share transaction | FLOWING |
| Task-local operation context | verifier/signing settings | Loaded Lockspire application config and fresh signing-key resolution | Yes; complete Context is threaded through inspect and apply, not mock cache data | FLOWING |
| CLI report | counts/details/outcome | Admin result sourced from actual page scan and row operations | Yes; bounded encoded identity and fixed atoms are rendered | FLOWING |
| Recovery/authentication | verifier, auth result, grant effects | Persisted rows and actual token/auth paths in PostgreSQL | Yes; tests query stored hash/verifier/JTI/token/audit effects | FLOWING |

No rendered/report value terminates in an empty hardcoded list or static-success fallback. The support adapter fixtures are test-only and do not supply the production inventory path.

### Behavioral Spot-Checks

The full contributor gate was not duplicated. I independently ran a focused behavior command against the exact current source tree and owned DB:

```sh
ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' LOCKSPIRE_TEST_DB_NAME=lockspire_phase177_20261026_owned MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_concurrency_test.exs test/integration/client_secret_verifier_maintenance_disclosure_test.exs test/integration/client_secret_verifier_maintenance_issuance_test.exs test/integration/client_secret_verifier_maintenance_recovery_test.exs test/integration/client_secret_verifier_maintenance_test.exs test/lockspire/admin/client_verifier_maintenance_test.exs test/lockspire/storage/client_verifier_maintenance_test.exs test/lockspire/security/client_secret_verifier_maintenance_test.exs test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs
```

| Behavior | Result | Status |
|---|---|---|
| Ten maintenance, concurrency, disclosure, issuance, recovery, core/store/Admin/security and Mix-task targets | 72 tests, 0 failures, exit 0; ExUnit 2.7s | PASS |
| Canonical source contributor gate (receipt log independently SHA-256 checked) | `mix ci`: exit 0, 2,414 tests/0 failures; boundary 15/0, fast 2 properties + 2,138/0 (6 skipped, 568 excluded), integration 261/0 (46 excluded), Credo 721 files/0; 265.625s | PASS (source receipt `tested_sha` 5e8cd65e6a45deee205c79a0f23592be68c0ffb8) |
| Prior Phase 175/176 regression command | One-shot normalized command over 29 unique targets: 188 tests/0 failures, exit 0; 3.147s | PASS (pre-verifier gate evidence) |
| Phase 177 exact corrected disclosure witness | Seed 81501: 8 tests/0 failures; audit trigger's sequence state `[1, true]` proves INSERT reached before rollback | PASS |

The 32 scoped implementation/test/doc paths are byte-identical between the tested source commit and current HEAD `596fdb8119eda4e779a44c2c9b1e2cdeca04df5e`; `git diff --quiet 5e8cd65e6a45deee205c79a0f23592be68c0ffb8 HEAD -- <32 files>` exited 0. The worktree was clean after the focused run. All 27 recorded source-acceptance output digests and all 13 frozen Phase 175 input hashes independently matched their recorded SHA-256 values.

### Probe Execution

No `scripts/*/tests/probe-*.sh` file or phase-declared probe path exists. The eight explicit E-01–E-08 predicates are behavior cases and have current source tests; they are not shell probe scripts. The two unclassified edges E-09 and E-10 remain unresolved and are not counted as executed probes or passes.

| Probe | Command | Result | Status |
|---|---|---|---|
| No declared shell probe | `rg --files scripts | rg 'probe-.*\\.sh$'` plus plan/summary probe-path scan | No probe paths found | N/A |

### Requirements Coverage

All six planned IDs match the six Phase 177 entries in `REQUIREMENTS.md`; no additional requirement is mapped to Phase 177 and no plan requirement is orphaned.

| Requirement | Source plans | Description | Status | Evidence |
|---|---|---|---|---|
| VUP-03 | 01, 02, 06, 08, 09 | Introduce/rewrap/retire verifier key without replacing partner secrets or other custody | SATISFIED for Phase 177 source scope | Persisted rewrap, recovery, restore/rotation, concurrency and fresh-check tests; local/fleet boundaries documented. |
| VOPS-01 | 03, 04, 05, 08, 09 | Repo-safe preview/apply/check, idempotence, partial errors and failing requested readiness | SATISFIED | Core/Admin, task, Repo lifecycle, partial retry and exact-repeat tests; focused run passed. |
| VOPS-02 | 01, 02, 05, 06, 09 | Selected-store CAS, transaction/audit atomicity and protected-field preservation | SATISFIED | PostgreSQL row lock/CAS, independent backend barriers, audit/outer rollback and rotation/metadata tests. |
| VOPS-03 | 02, 03, 04, 08, 09 | Redacted status for all rows and truthful local readiness | SATISFIED | Authenticated classifier, unfiltered inventory, bytewise pages, incomplete-row failure and fresh full check tests. |
| VOPS-04 | 06, 08, 09 | Lost-key client identification and authorized restore/replacement while JWT fails closed | SATISFIED for concrete source behavior; E-09 remains flagged | Recovery integration tests prove fail-closed JWT, original-key restore and existing one-time rotation; generic edge not classified. |
| VPROOF-01 | 07, 08, 09 | No verifier material in owned diagnostics, SQL channels, telemetry, audit, report or protocol output | SATISFIED for owned source channels; E-10 and prohibitions remain flagged | Success/failure sentinels, nested Inspect, real audit-trigger failure witness and query telemetry tests; host/server logging limits remain explicit. |

### Test Quality Audit

Requirement-linked tests have active, behavior/value-level assertions. The requested focused run executed the ten core targets above with no skipped cases in that command. No linked tests declare skip tags or `skip:` metadata. Test values are fixture inputs or direct persistence snapshots; no helper writes expected output by invoking the operation under test. The concurrency and audit-trigger assertions use PostgreSQL as an independent witness rather than suite counts alone.

| Test file | Linked requirements | Active in focused run/CI | Disabled | Circular | Assertion strength | Verdict |
|---|---|---|---|---|---|---|
| `test/integration/client_secret_verifier_maintenance_test.exs` | VUP-03, VOPS-02 | Yes | 0 | 0 | Behavioral/value | PASS |
| `test/lockspire/security/client_secret_verifier_maintenance_test.exs` | VUP-03, VOPS-02, VOPS-03 | Yes | 0 | 0 | Value/adversarial | PASS |
| `test/lockspire/storage/client_verifier_maintenance_test.exs` | VOPS-01, VOPS-02, VOPS-03 | Yes | 0 | 0 | PostgreSQL value/order | PASS |
| `test/lockspire/admin/client_verifier_maintenance_test.exs` | VOPS-01, VOPS-03 | Yes | 0 | 0 | Multi-step behavior | PASS |
| `test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` | VOPS-01, VOPS-03 | Yes | 0 | 0 | Subprocess/exit/ownership | PASS |
| `test/integration/client_secret_verifier_maintenance_concurrency_test.exs` | VUP-03, VOPS-01, VOPS-02 | Yes | 0 | 0 | Independent-backend behavioral | PASS |
| `test/integration/client_secret_verifier_maintenance_issuance_test.exs` | VUP-03, VOPS-02, VOPS-04 | Yes | 0 | 0 | Real issuance/JTI effects | PASS |
| `test/integration/client_secret_verifier_maintenance_recovery_test.exs` | VUP-03, VOPS-02, VOPS-04 | Yes | 0 | 0 | Persisted end-to-end recovery | PASS |
| `test/lockspire/security/client_secret_verifier_inspection_test.exs` | VPROOF-01 | Yes | 0 | 0 | Sentinel/public-shape | PASS |
| `test/integration/client_secret_verifier_maintenance_disclosure_test.exs` | VPROOF-01 and forced-error VOPS-01/03/04 | Yes | 0 | 0 | Captured sentinel/DB witness | PASS |
| `test/lockspire/security/client_secret_verifier_maintenance_guidance_test.exs` | VUP-03, VOPS-01/03/04, VPROOF-01 | Yes | 0 | 0 | Executable docs/CLI contract | PASS |

**Disabled tests on requirements:** 0. **Circular expected-value generators:** 0. **Insufficient assertion cases identified:** 0.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| None across the 32 changed source/test/doc paths | — | No unreferenced `TBD`/`FIXME`/`XXX`, TODO/HACK/PLACEHOLDER marker, stub, empty implementation or user-visible static fallback found | — | No blocker. |

### Human Verification Required

N/A — this is a backend/tooling foundation phase with no UI or real-time user surface. CLI modes, exit behavior, report fields and operator guidance have executable tests. Fleet parity, quiescence, backups, rollback readiness and host-controlled logging are expressly host responsibilities, not unverified local behaviors.

### Gaps Summary

No failed truth, missing/stub artifact, unwired link, unmet requirement or deterministic runtime gap was found. Current source is byte-identical to the exact source SHA that passed canonical CI; focused phase behavior tests passed independently. The earlier startup-cache fixture leak, audit-value validation weakness and disclosure-trigger fixture bypass are preserved as historical failures and have executable corrections. In particular, the current audit failure test proves the trigger ran via its sequence witness, so the old pre-validation bypass is not being inferred closed from a passing suite count.

E-09, E-10 and the three unverified prohibition flags remain explicitly preserved above. They do not identify a missing concrete source behavior under the six Phase 177 requirement contracts, and are not silently called passed or converted into hard human gates. Phase 178 package-installed/configured-store composition and final delivery/main acceptance are not claimed here.

---

_Verified: 2026-10-26T04:44:53Z_  
_Verifier: the agent (gsd-verifier)_
