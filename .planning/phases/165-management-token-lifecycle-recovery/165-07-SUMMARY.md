---
phase: 165-management-token-lifecycle-recovery
plan: "07"
subsystem: auth
tags: [oauth, dcr, management-token, lifecycle, recovery, documentation, postgres]
requires:
  - phase: 165-management-token-lifecycle-recovery
    plan: "05"
    provides: PostgreSQL contention, replacement, and rollback evidence
  - phase: 165-management-token-lifecycle-recovery
    plan: "06"
    provides: Host-authorized recovery, one-time disclosure, and operator guidance
provides:
  - Consistent adopter, upgrade, operator, and supported-surface management-token lifecycle guidance
  - Source-backed guidance assertions and measured Phase 165 validation evidence
affects: [phase-166, dynamic-client-registration, management-token-lifecycle]
actuals:
  tokens: 7281
  tasks: 2
  commits: 3
  plan_head_before: c0bff7c54087a70c15b884ee21bf57ed99893079
  plan_head_after: 165849fd490643b52217751b22a5780ba07b7499
tech-stack:
  added: []
  patterns:
    - Guidance contracts assert behavior across canonical docs without whole-file snapshots.
    - Validation records distinguish observed positive PostgreSQL race evidence from full-suite failures and exclusions.
key-files:
  created:
    - .planning/phases/165-management-token-lifecycle-recovery/deferred-items.md
  modified:
    - docs/dynamic-registration.md
    - docs/upgrading/client-lifetimes.md
    - docs/operator-admin.md
    - docs/supported-surface.md
    - test/lockspire/client_lifetime_guidance_test.exs
    - .planning/phases/165-management-token-lifecycle-recovery/165-VALIDATION.md
key-decisions:
  - "Describe finite management-token expiry as an optional host policy, with blank/zero unlimited behavior, prospective policy, strict expiry, and no GET renewal."
  - "Document immediate no-overlap PUT replacement and host-only confirmed one-time recovery after a lost response; do not imply old-token replay recovers a committed response."
  - "Keep phase validation draft until independent security, code-review, and goal-backward verification are complete, even after the selected automated gates pass."
requirements-completed: [DCR-10, DCR-11, DCR-12]
coverage:
  - id: D1
    description: Adopter and operator guidance explains optional management-token expiry, required PUT identity, immediate replacement, and host-owned recovery.
    requirement: DCR-10
    verification:
      - kind: unit
        ref: test/lockspire/client_lifetime_guidance_test.exs — guidance and architecture batch, 15 tests, 0 failures
        status: pass
    human_judgment: false
  - id: D2
    description: Phase validation evidence records focused, fast-suite, and explicit PostgreSQL gate results with remaining audit limits.
    requirement: DCR-12
    verification:
      - kind: integration
        ref: 165-VALIDATION.md — explicit PostgreSQL batch 34/0, combined gate 21/0, corrected fast suite 2411/0
        status: pass
    human_judgment: true
    rationale: Selected automated gates pass; independent phase audits remain outstanding.
duration: 11min 12s
completed: 2026-10-21
status: complete
---

# Phase 165 Plan 07: Management Token Guidance and Validation Summary

**Optional app management-token expiry, immediate replacement, and host-owned lost-response recovery are documented with actual focused and PostgreSQL validation evidence.**

## Performance

- **Duration:** 11 min 12 sec
- **Started:** 2026-10-21T18:50:50Z
- **Completed:** 2026-10-21T19:02:02Z
- **Tasks:** 2
- **Files modified or created:** 7

## Accomplishments

- Updated dynamic-registration, upgrade, operator, and supported-surface guidance with the configured route prefix, required unchanged PUT `client_id`, forbidden and matching-secret rules, and numeric server-owned expiry extensions.
- Added executable 100 → 160/110/120 issuance and 125 → 165 recovery examples. Guidance explains unlimited blank/zero settings, strict expiry, prospective policy, GET non-renewal, app-state exceptions, immediate no-overlap replacement, lost-response consequences, and the existing confirmed one-time host recovery boundary.
- Extended source-backed guidance checks. The focused guidance and architecture batch passed 15 tests with zero failures.
- Ran the required explicit PostgreSQL race, rollback, adapter conformance, and promotion selection: 34 tests, zero failures. The initial fast suite found six failures; the corrective follow-up resolved them and reran the full suite at 2,411 tests, zero failures, 483 exclusions, and 6 skips.

## Task Commits

1. **Task 1 RED: Add management lifecycle guidance assertions** — `8955e11e` (`test`)
2. **Task 1 GREEN: Document management-token expiry and recovery** — `2fbd57a8` (`docs`)
3. **Task 2: Record lifecycle validation evidence** — `165849fd` (`docs`)

**Plan task commits measured from the persisted ledger:** 3, from `c0bff7c54087a70c15b884ee21bf57ed99893079` through `165849fd490643b52217751b22a5780ba07b7499`. The final summary/state metadata commit is separate.

## TDD Gate Compliance

- **RED:** Before the documentation changes, the new target guidance test failed on the missing `Lockspire.mount_path` requirement: 1 target test, 1 assertion failure, exit 2. The output showed an executed test assertion rather than compilation, load, or fixture failure.
- **RED evidence limit:** The default ExUnit console report is not accepted by the GSD RED evidence classifier. This is recorded as a semantic RED observation only; no classifier-approved RED is claimed.
- **GREEN:** The documentation was updated and the guidance plus architecture suites passed: 15 tests, 0 failures. No runtime implementation was needed.
- **REFACTOR:** No separate refactor was needed. Assertions were narrowed to source-backed wording while keeping behavior checks, and the test file was formatted.
- The task was documentation and contract-test only. The project `workflow.tdd_mode` setting was false; the test-first and separate test/documentation commits were still retained.

## Validation Results

- Focused guidance and architecture tests: **15 tests, 0 failures** in 0.20 seconds.
- Historical initial exact combined gate: **9 tests, 1 failure** in 0.06 seconds. The literal compatibility assertion omitted Phase 165 additive arities.
- Historical initial `mix test.fast`: **2,411 tests, 6 failures, 483 excluded, 6 skipped** in 139.4 seconds. See [deferred-items.md](./deferred-items.md) for preserved evidence and root causes.
- Corrected exact combined guidance, architecture, and compatibility gate: **21 tests, 0 failures**. Affected compatibility, singleton-policy, discovery, and LiveView assertions: **48 tests, 0 failures**. The recovery LiveView and private-key JWT environment-isolation run: **9 tests, 0 failures**.
- Corrected `mix test.fast`: **2 properties, 2,411 tests, 0 failures, 483 excluded, 6 skipped** in 134.0 seconds.
- Explicit selected PostgreSQL batch with `--include postgres_race`: **34 tests, 0 failures** in 1.0 second. The three independent race modules retain 24 verified blocker relationships from plan 165-05.
- The `mix test.fast` exclusions and skips are recorded but are not credited as race evidence. No package was installed.

## Corrective Regression Follow-up

After plan execution, the initial gate failures were resolved in two atomic test
commits: `f91a975a` declares the phase-approved `read/3`, `delete/3`, and
`rotate_registration_access_token/2` compatibility extensions, isolates the
singleton server-policy tests, seeds discovery's disabled-registration policy,
and updates the stale LiveView copy assertion. The follow-up full run exposed an
order-dependent mount-path leak from the recovery LiveView module; `0d2b0051`
restores the module's original application environment and rolls back each
test's sandbox transaction. These corrective fixes claim no additional TDD RED
evidence. Full root-cause and command details are in
[165-REGRESSION-FIX-SUMMARY.md](./165-REGRESSION-FIX-SUMMARY.md).

## Files Created/Modified

- `docs/dynamic-registration.md` — adopter lifecycle, required PUT identity, extension rules, sample requests, and recovery limits.
- `docs/upgrading/client-lifetimes.md` — v0 effective-unlimited semantics and custom-adapter lifecycle preservation.
- `docs/operator-admin.md` — host staff boundary, confirmation, one-time disclosure, and lockout tradeoff.
- `docs/supported-surface.md` — concise public contract for management-token lifecycle and recovery.
- `test/lockspire/client_lifetime_guidance_test.exs` — source-backed checks for the new guidance.
- `.planning/phases/165-management-token-lifecycle-recovery/165-VALIDATION.md` — task evidence and exact gate outcomes; remains draft.
- `.planning/phases/165-management-token-lifecycle-recovery/deferred-items.md` — out-of-scope existing full-suite failures.

## Decisions Made

- Finite expiry remains an optional host policy, not a universal RFC timeout. The docs state the partner lockout risk and preserve unlimited blank/zero behavior.
- A successful PUT immediately invalidates the previous token and discloses the replacement once. Recovery stays on the existing host-authorized, confirmed admin operation and never extends app or secret expiry.
- The evidence record remains draft with compliance flags false until independent security, code-review, and goal-backward verification complete. Phase 166 still owns final packaged cross-phase proof, final security/guidance audit, and umbrella-todo closure.

## Deviations from Plan

### Auto-fixed Issues

The phase owner authorized a post-plan corrective pass after validation found failures across earlier phase-owned tests. Root causes and fixes are recorded in the corrective follow-up section and `165-REGRESSION-FIX-SUMMARY.md`; no runtime protocol behavior or discovery output was changed.

## Issues Encountered

- The initial combined gate and full fast suite exposed compatibility, fixed-singleton test setup, stale copy, discovery policy setup, and application-environment isolation issues. Corrective focused, combined, PostgreSQL, and full-suite reruns now pass.
- The TDD RED output is semantically valid as a test assertion failure but was not machine-classified because the default ExUnit reporter is unsupported by the GSD checker.

## User Setup Required

None. The dedicated PostgreSQL validation database was already present and migrated; the tests reported `lockspire_phase165_validation` and reused it.

## Next Phase Readiness

Guidance and the selected automated Phase 165 gates are ready for independent security, code-review, and goal-backward verification. Keep Phase 165 in verification status until those audits complete. Phase 166 retains final integrated/package proof and umbrella-todo ownership.

## Self-Check: PASSED

- All declared deliverables, the validation record, and this summary exist.
- Task commits `8955e11e`, `2fbd57a8`, and `165849fd` are ancestors of HEAD.
- Corrective regression summary exists; corrective commits `f91a975a` and `0d2b0051` are ancestors of HEAD.
- Corrected combined, explicit PostgreSQL, and full fast-suite results are recorded in `165-VALIDATION.md`.
- No stubs or TODO/FIXME placeholders were found in the plan's docs or guidance test.
- `.planning/state.json` remains byte-for-byte equal to the supplied backup and has not been staged.

---
*Phase: 165-management-token-lifecycle-recovery*
*Completed: 2026-10-21*
