---
phase: 169-install-and-upgrade-convergence
plan: "02"
subsystem: install-upgrade
tags: [upgrade, filesystem-transaction, phoenix, migration-safety]

requires:
  - phase: 169-install-and-upgrade-convergence
    provides: "169-01 native admin routing and host-owned deny-by-default authorization seam"
provides:
  - "Checksum-trusted v1.45 forward-only helpers upgrade to canonical native admin routes"
  - "Upgrade bootstraps an absent host-owned authorization seam as a create-only transaction artifact"
  - "Upgrade previews inspect recovery state without writing and preserve historical manifest inputs"
affects: [170, install, upgrade, generated-host]

actuals:
  tokens: 9319
  tasks: 2
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Manifest checksums, not historical filenames or release labels, authorize managed helper updates."
    - "Read-only recovery inspection must not create directories, recover journals, or stage bytes."
    - "Host-owned authorization artifacts are create-only and excluded from managed manifest ownership."

key-files:
  created:
    - test/support/fixtures/install_upgrade/v1_45_forward_router.ex.eex
    - test/support/fixtures/install_upgrade/README.md
    - .planning/phases/169-install-and-upgrade-convergence/169-02-task1-red-evidence.json
    - .planning/phases/169-install-and-upgrade-convergence/169-02-task2-red-evidence.json
  modified:
    - lib/lockspire/install/operation_plan.ex
    - lib/lockspire/install/file_transaction.ex
    - lib/mix/tasks/lockspire.upgrade.ex
    - test/integration/install_upgrade_test.exs
    - test/lockspire/install/file_transaction_test.exs

key-decisions:
  - "Preserve manifest-recorded web, scope, mount, storage, Oban, and FAPI inputs when corresponding CLI options are omitted."
  - "Keep preview refusal read-only when a pending or invalid transaction journal requires recovery."
  - "Keep concurrency claims bounded to stale-plan revalidation, exclusive creates, and interruption recovery; simultaneous writers and hostile same-user ancestor replacement remain unsupported."

requirements-completed: [HDX-02]
coverage:
  - id: D1
    description: "A checksum-tracked historical forward helper converts through the public upgrade task, compiles to canonical native admin routing, preserves host policy and recorded inputs, and repeats byte-identically."
    requirement: HDX-02
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/integration/install_upgrade_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Dry-run preserves complete host and transaction snapshots, refuses while recovery is pending, and stale or competing plans leave host bytes unchanged."
    requirement: HDX-02
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/integration/install_upgrade_test.exs test/lockspire/install/file_transaction_test.exs"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-10-23
status: complete
plan_head_before: 058a8365f53bcce279d0d67f2260fd3cea695baa
plan_head_after: 23b48783c2124a62d781bae747d128c6d07bd7c4
---

# Phase 169 Plan 02: Install and Upgrade Convergence Summary

**Checksum-verified v1.45 router helpers now converge on native admin routes while read-only previews preserve host files and interrupted transactions recover safely.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-10-23T21:31:47Z
- **Completed:** 2026-10-23T21:40:57Z
- **Tasks:** 2
- **Files modified:** 9, including two RED evidence records

## Accomplishments

- Added an exact historical router template fixture from annotated tag object `0f45d0c603c31d814cd9003848f6af508bb4e72c`, peeled commit `69c05922b880d1ee6e257e5a78f06a4e5755efcc`, package version `1.6.1`. The unrendered template SHA-256 is `7b1b73ec53d27641166306bce963fcb9e2d7d73ab2059598b9829b92971221c1`.
- Upgraded a manifest-checksum-tracked historical forward helper through `mix lockspire.upgrade`; compiled the rendered helper and host router, and verified the admin root resolves to `Lockspire.Web.Live.Admin.OverviewLive.Index`.
- Created the absent operator authorization seam only with an exclusive, expected-absent transaction operation. Existing customized seam and resolver bytes remain untouched, and the new seam stays out of `managed_files`.
- Preserved recorded host inputs when the CLI omits overrides, including compatibility with manifests omitting `migrations` and `with_fapi_smoke`. Duplicate or malformed managed entries, drift, missing files, and destination conflicts refuse before mutation.
- Added read-only recovery inspection and full-tree preview checks. A preview with pending recovery leaves journal, staging, host files, and bytes unchanged; normal retry recovers both newly written policy/helper artifacts before committing the manifest last.
- Added stale-plan and competing-plan regressions for destination appearance and managed-file edits. Simultaneous generator writers and hostile same-user ancestor replacement remain unsupported, as documented by `FileTransaction`.

## Task Commits

1. **Task 1 RED:** `e66de46e` — `test(169-02): add historical upgrade conversion regression`
2. **Task 1 GREEN:** `9842b286` — `feat(169-02): converge historical upgrades safely`
3. **Task 2 RED:** `635deda8` — `test(169-02): cover interrupted helper recovery`
4. **Task 2 GREEN:** `d8b46b02` — `feat(169-02): expose precise transaction interruption seam`
5. **Task 2 verification:** `23b48783` — `test(169-02): verify historical route and host preservation`

**Measured plan commits:** 5 (`058a8365f53bcce279d0d67f2260fd3cea695baa..23b48783c2124a62d781bae747d128c6d07bd7c4`).

## Verification

- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/integration/install_upgrade_test.exs` — **15 passed** after the Task 1 commit and tracer feedback gate.
- `ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/integration/install_upgrade_test.exs test/lockspire/install/file_transaction_test.exs` — **24 passed**.
- `git diff --check` — passed before commits.
- Both TDD RED records were accepted by `gsd_run check tdd-red-evidence` as `RED_EVIDENCE_OK`; the targeted assertions failed for the planned behavior.

## Decisions Made

- Upgrade planning preserves recorded inputs unless the adopter explicitly supplies an override. FAPI remains opt-in according to manifest history or an explicit CLI switch.
- Dry-run checks recovery status before building its immutable plan. Pending or invalid journal state yields safe retry guidance without invoking recovery.
- Transaction safety claims cover current expected-byte checks, exclusive creates, journal rollback, and retry. They do not promise coordination between simultaneous writers or native descriptor-relative containment against hostile same-user ancestor replacement.

## Deviations from Plan

### Verification adaptation

ExUnit's default text report is not accepted by the repository's TDD evidence classifier. For each RED run, a temporary test-only ExUnit formatter emitted TAP directly from the actual ExUnit test events. The TAP report was classified as `RED_EVIDENCE_OK`, the target assertion and failure were semantically checked, and the temporary formatter/test-helper change was removed before commit. No runtime dependency or permanent reporter was added.

**Total deviations:** 1 verification adaptation. **Impact:** TDD evidence remained machine-validated without changing project runtime or test dependencies.

## Issues Encountered

- The first RED test attempt exposed a wrong fixture-path assertion, which was changed to assert the intended missing-seam behavior directly before recording valid RED evidence.
- Compile/type warnings from unrelated existing modules remained outside this plan's scope.

## Known Stubs

None. The generated authorization seam intentionally denies access until the host implements its policy; this is the shipped security behavior, not a placeholder or missing data source.

## Next Phase Readiness

HDX-02 has executable conversion, ownership, preview, stale-plan, interruption, and retry coverage. Phase 170 retains packaged adoption, browser/socket transport, and exact supported-runtime proof.

---
*Phase: 169-install-and-upgrade-convergence*
*Completed: 2026-10-23*

## Self-Check: PASSED

- Historical fixture, provenance README, and both RED evidence records exist.
- All five task commits are ancestors of the current HEAD.
- `gsd_run check evaluation-scope --plan "169-02" --commits-only --raw` resolved this plan and found five commits on the current branch.
- Focused integration and transaction verification passed with 24 tests.
