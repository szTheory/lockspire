---
phase: 178-packaged-upgrade-proof-delivery-handoff
plan: "07"
subsystem: testing
tags: [installed-proof, redaction, postgres, exunit, python]
requires:
  - phase: 178-02
    provides: installed clean-room host, strict receipt contract, and delegated PostgreSQL proof seams
provides:
  - Installed disclosure receipts for success and forced crypto/storage failures on locked and floor dependency pairs
  - Owned-target source-test guard qualification and incident-preserving source verification record
affects: [178-08, 178-10, VPROOF-02]
actuals:
  tokens: 44464
  tasks: 2
  commits: 15
tech-stack:
  added: []
  patterns:
    - "Register sensitive sentinels before child output is processed; retain only fixed safe channel counts and outcomes."
    - "Run database-backed source checks only through a fresh database with witnessed creation, exact identity, and owned cleanup."
key-files:
  created:
    - scripts/acceptance/clean_room/verifier_disclosure.py
    - test/clean_room/provider_host/lib/clean_room_provider/verifier_disclosure.ex
    - test/acceptance/client_verifier_disclosure_test.py
    - scripts/ci/run_owned_source_tests.py
    - test/acceptance/owned_source_tests_test.py
  modified:
    - scripts/acceptance/clean_room/verifier_receipts.py
    - scripts/acceptance/clean_room/build_provider.py
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-07-PLAN.md
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-07-SHARED-TEST-DB-INCIDENT.md
key-decisions:
  - "Preserve the explicit one-time secret handoff for its caller while redacting nested inspection and diagnostic channels."
  - "Keep all disclosure receipts partial and VPROOF-02 pending until the remaining phase proof owners complete."
  - "Use the owned-target runner for source database tests; do not repair or clean the two incident databases from this plan."
patterns-established:
  - "Installed disclosure acceptance requires nonempty Logger and query captures, zero leak counts, and exact finite scenario IDs."
  - "Receipt revalidation binds dependency pair, delegated store, package source, installed tree, compiled package, host lock, and runtime."
requirements-completed: []
coverage:
  - id: D1
    description: "Installed success and forced-failure disclosure channels are captured safely on both dependency pairs."
    requirement: VPROOF-02
    verification:
      - kind: integration
        ref: "clean_room_verifier_upgrade.py --validate-receipts (four persisted receipt files, pair/store bound)"
        status: pass
      - kind: integration
        ref: "run_owned_source_tests.py --include integration test/integration/client_secret_verifier_maintenance_disclosure_test.exs test/lockspire/security/client_secret_verifier_inspection_test.exs"
        status: pass
    human_judgment: true
    rationale: "Independent security and source reviewers still need to decide final acceptability; this plan does not complete VPROOF-02."
duration: 95min+ (elapsed from first Plan 07 commit; active time unavailable)
completed: 2026-10-27
status: complete
plan_head_before: 5a006080b6ded022d15be5f327ab022f6a2f9b09
plan_head_after: 98e17ad976a9d1b6fa17e845b12c47bc390d68a2
---

# Phase 178 Plan 07: Installed Disclosure Diagnostics Summary

**Installed success and forced-failure disclosure evidence now covers both dependency pairs with nonempty owned-channel captures, zero recorded leaks, and preserved one-time secret handoff.**

## Performance

- **Elapsed span:** 95 minutes or more from the first Plan 07 commit through reconciliation; exact active time is unavailable because execution crossed sessions and incident investigations.
- **Started:** 2026-10-27T00:20:35Z (first Plan 07 RED commit; not asserted as the actual work start)
- **Completed:** 2026-10-27T01:55:52Z
- **Tasks:** 2
- **Files changed before this closeout:** 20 tracked files across Plan 07 implementation, source-guard qualification, incident records, and planning metadata. The new SUMMARY itself is excluded from the chars/4 actuals calculation.

## Accomplishments

- Completed Task 178-07-01 with actual installed success on both locked and floor pairs. Each success receipt records registration/rotation/maintenance coverage, HTTP 200, a usable private one-time handoff, redacted nested inspection, safe CLI/audit projection, positive Logger and query capture counts, and zero leak counts.
- Completed Task 178-07-02 with malformed-crypto, unknown-key-crypto, and valid owned-storage-failure witnesses on both pairs. All six outcomes are strict-validated; captures are nonempty, leak counts are zero, crypto failures return the safe `invalid_client` HTTP 401 category, and storage failure remains a safe HTTP 200 maintenance report.
- Independently validated all four retained success/failure receipts using the common CLI, explicitly binding `--store delegated` and each actual `--pair`. This revalidated persisted evidence and did not restamp it at a newer source revision.
- Qualified the amended source check through the owned-target runner: 9 tests, 0 failures, 0 properties at source `dfe87c9fe747f6a925472b9396677ac9d4375d7a`. A separate selected-runtime Python acceptance run passed 144 tests, 0 failures; `git diff --check` passed.
- Reconciled source ownership after the guard run: files changed after `dfe87c9f` are planning records only. The disclosure integration tests and package source owners did not change after that qualified run, so no redundant database-backed source run was made.
- Kept the scope bounded to installed lab proof and source-test ownership. No Lockspire production API, protocol, schema, runtime dependency, or host logging policy changed.

## Installed receipt identity and channel results

The four validated files are under `.artifacts/phase178/disclosure-task2-locked-stage/locked-delegated/` and `.artifacts/phase178/disclosure-task2-floor/floor-delegated/`. Both pairs used package version `1.6.1`, candidate and harness source `b69cd685860f8084b3c1e6871cfef5168568cb45`, archive SHA-256 `8be113c5d8cd630ee9fefba3494aac2c236350589a5cd9e7c98600a11a8d1e91`, and vendor tree SHA-256 `2af2082226f0be0e47b1f761cb4e98dd526effc0f93800fbacacce1f3a46b243`. Runtime was Elixir 1.19.5 / OTP 28 / PostgreSQL 14.17.

| Pair | Phoenix / LiveView | Host lock SHA-256 | Compiled candidate SHA-256 | Cases validated |
| --- | --- | --- | --- | --- |
| Locked | 1.8.13 / 1.2.10 | `f77638eeed00fc0a7fa524219ad2fe0c0fd3c147b0436979b925bc4f236f4404` | `f878c01d16d1167ce8f694688b0cf726376f3078670e6cc5253ce2743224ad5f` | success 1/1; forced failures 3/3 |
| Floor | 1.8.5 / 1.1.28 | `74212156d931add8c5acae6ad67928d08951a6c698cc6f29fec88992af38a954` | `5beb97b38d9377eb1e6e7b44f3d46b89f180cffaee787cfb5e06eef4561b5fbe` | success 1/1; forced failures 3/3 |

For each pair, success captured three Logger events and five query events, with nonzero controls/operations and zero Logger, query, and output leaks. Each of the six forced-failure cases also has nonzero Logger/query events and zero leaks. The storage-failure case has observed operation events in both channels; the two crypto-failure cases each retain their own scenario-specific query-operation witnesses. The strict receipt contract enforces these counts and the full finite case IDs.

The two final `resource-state.json` files bind the actual run IDs, databases, and listener ports. Both records show child exit, confirmed process-group stop, listener stopped, database created by that run and later absent, and failure capture stage `complete`. The full hashes are `fb14cf4b300eb0a6f35adabf176acd02e7beb47eef5062ab84810adc9bae6518` (locked) and `891b4870292fe88af459849b93152c7c6bcb32de50c659106de5af491529372f` (floor). No raw child output, diagnostic tail, exception map, stack, or secret value is included here.

## Owned source-test guard qualification

All source database-backed checks for this plan use only `python3 scripts/ci/run_owned_source_tests.py` with explicit paths (or the fixed `--ci` mode). The source command was:

```sh
ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' python3 scripts/ci/run_owned_source_tests.py --include integration test/integration/client_secret_verifier_maintenance_disclosure_test.exs test/lockspire/security/client_secret_verifier_inspection_test.exs
```

It exited 0 with 9 tests, 0 failures, 0 properties. Its generated test database was `lockspire_owned_09bd3a10698c450b9beee80cf9748756`, OID `39074433`; creation and connected identity were witnessed, the effective test Repo was checked, child groups stopped, and final catalog absence was independently confirmed. The private source-pass manifest SHA-256 is `bca4eee39f4489ea623986eeab6806e6fd56c4bd1a47bc3f9d498ac540283e96`; stdout was 1,502 bytes with digest `c09f73e5eeace0b24c4573fdce02b9bd863dd0e2854d5c85c0240edf6e9ec229`.

Guard code/test source identities are: runner SHA-256 `17c5640b1ea0e1e4bb9227e28010e2c906492240e4dfb69507467a0f8a335dda`, test SHA-256 `4106e1aa1b64b106b148a07d94cdb16d57dc21387b7ded44cc220c037b05bbcf`, qualification fix commit `dfe87c9fe747f6a925472b9396677ac9d4375d7a`, and initial guard/test commit `aa3524ba135884ce5cbc7ab4a459015881166ec5`. The OID cast fix and guard tests do not alter Lockspire library behavior. The full contributor `--ci` path and installed final aggregate remain later-plan owners.

## Task and support commits

The measured range is 15 commits from plan base `5a006080b6ded022d15be5f327ab022f6a2f9b09` through `98e17ad976a9d1b6fa17e845b12c47bc390d68a2`:

1. `033327e0` — Task 01 RED disclosure fixture contract.
2. `e63f1231` — preserved initial incomplete-proof checkpoint.
3. `af3533cd` — recorded an unproved startup diagnostic lead.
4. `6bc87808` — additional RED contract distinguishing private handoff from diagnostics.
5. `fe427b46` — root audit of private transport and capture.
6. `94a04da4` — Task 01 installed success capture.
7. `76680438` — retained stopped-listener resource facts.
8. `be32048d` — Task 02 RED failure-disclosure contract.
9. `235acd6e` — Task 02 installed crypto/storage failure capture.
10. `4a62c149` — strict failure receipt scope fix.
11. `b69cd685` — bounded failure capture stage and final installed receipt source.
12. `b4db1651` — recorded both source database targeting incidents.
13. `aa3524ba` — added owned source-test runner and offline guard tests.
14. `dfe87c9f` — corrected PostgreSQL OID JSON typing in the guard.
15. `98e17ad9` — recorded successful guard qualification and amended remaining source-test instructions.

## Issues Encountered and Security Record

- Preserve the intermittent locked-pair unknown-key post-capture failure from the staged retry. No causal fix was established; the follow-up changed only the bounded stage witness and a fresh attempt later produced the final pair receipts. The retained failed attempts remain distinct from the successful receipt; they were not rewritten or restamped.
- The first Plan 07 installed attempts failed at registration/maintenance stages. Their raw child output stayed private. The final validated captures do not erase those failures or the initial RED/checkpoint evidence.
- Three historical harness secret incidents remain part of the security record: Phase 178 Plan 03 retained raw JWT/code/PKCE material in an artifact that was later scrubbed; Plan 04 exposed a generated fixture secret in failed tool output; Plan 06 exposed a generated one-time secret in failed tool output. The scrub/containment actions do not erase these incidents.
- The earlier shared-target test command selected the default `lockspire_test`, ran 9 tests with 1 failure, and its failing test committed one generated fixture change before returning an aggregate error. Cleanup was attempted through that test's exact generated-client cleanup path, but there is no independent before/after row snapshot. Existing lifetime rows remain unqueried for manual repair and their full state is unknown.
- A separate create/migrate attempt omitted `MIX_ENV=test` and most likely targeted `lockspire_dev`; read-only inspection confirmed the two migration rows and column metadata. No pre-state snapshot exists, business rows were not queried, and no rollback, cleanup, repair, or unchanged-data claim is made. The intended test database is absent at the later catalog check; its earlier failed test-command lifecycle remains unexplained. Both database incidents remain open for independent disposition.
- The first owned-target guard run refused identity after PostgreSQL serialized the OID as a string. Root cleanup was limited to its exact generated name/OID after read-only verification; absence was confirmed. The subsequent bigint cast fixed that guard identity check. The successful source run used a separate witnessed database and its own exact cleanup. Neither guard event authorizes cleanup of shared or development storage.
- Host custom instrumentation and PostgreSQL server logging remain host-owned. This plan observed only the lab-owned Logger/query channels and does not claim to change or certify host/server logging policy.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added an owned-target source-test guard after database-targeting incidents.**
- **Found during:** Task 178-07-02 source verification.
- **Issue:** The two manually assembled source-test paths could not establish a safely owned test database; one command selected the shared/default target and another run omitted test environment selection.
- **Fix:** Added the dependency-free `run_owned_source_tests.py` with offline tests, forced test configuration, exact creation/identity checks, bounded child groups, and strict cleanup ownership. Amended remaining source verification commands to use explicit guarded invocation.
- **Files modified:** `scripts/ci/run_owned_source_tests.py`, `test/acceptance/owned_source_tests_test.py`, `.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-07-PLAN.md`, `178-09-PLAN.md`, `178-10-PLAN.md`, incident/guard records.
- **Verification:** Selected source integration 9/0, selected-runtime Python acceptance 144/0, common installed receipt validation 4/4.
- **Committed in:** `aa3524ba`, `dfe87c9f`, `98e17ad9`.

**2. [Rule 1 - Bug] Cast PostgreSQL database OID to numeric before guard identity serialization.**
- **Found during:** Owned-target guard live qualification.
- **Issue:** PostgreSQL JSON encoded the `oid` value as a string, which failed the guard's expected numeric identity contract and prevented source tests from proceeding.
- **Fix:** Cast the OID to bigint in the read-only identity query; exact owned cleanup for the first refused run was separately verified.
- **Files modified:** `scripts/ci/run_owned_source_tests.py`.
- **Verification:** The subsequent guarded source run bound OID `39074433`, passed 9/0, and independently confirmed its generated database absent.
- **Committed in:** `dfe87c9f`.

**Total deviations:** 2 (one Rule 3 and one Rule 1). They were required to keep database-backed source verification correctly owned; no production library behavior changed.

## Deferred Review and Phase Status

Plan 07's two tasks and their scoped proof artifacts are complete. Independent security/source review remains required. VPROOF-02 remains pending until the remaining Phase 178 proof owners pass. The wrong-target database incidents and historical secret incidents remain visible and unresolved; this summary does not certify database contents unchanged, authorize repair, or erase incident history. No remote writes, PR, merge, or publication occurred.

## Next Phase Readiness

Plan 08 may consume the validated partial disclosure receipts and the source guard. Independent reviewers still decide their acceptability; Plan 10 owns the full source contributor gate and final aggregate. Keep the exact remote-write boundary and separate merge/publication gates in force.

---
*Phase: 178-packaged-upgrade-proof-delivery-handoff*
*Completed: 2026-10-27*

## Self-Check: PASSED

- Summary and referenced source-pass and both pair receipt artifacts exist and are non-empty.
- All 15 measured commits from the documented Plan 07 base are ancestors of the current HEAD.
- The plan evaluation-scope resolver found 13 commits whose subjects are explicitly scoped to `178-07`; the two additional measured commits are the source-target guard and its qualification/follow-up ownership.
- All four persisted installed receipts passed the common validator with explicit pair and delegated-store bindings; the source manifest records the 9/0 guarded check.
