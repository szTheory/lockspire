---
phase: 165-management-token-lifecycle-recovery
plan: "04"
subsystem: auth
tags: [oauth, dcr, management-token, ecto, postgres]
requires:
  - phase: 162-lifetime-semantics-upgrade-contract
    provides: Current-policy, strict deadline, custom-store, rollback, and legacy promotion contract
  - phase: 165-03
    provides: Atomic management-token PUT and current-row replacement transport
provides:
  - Host-authorized management-token recovery with a policy-derived deadline and deferred decision time
  - Management replacement conformance and whole-row legacy promotion proof
  - Complete write/audit rollback evidence for PUT and host recovery
affects: [dynamic-client-registration, management-token-lifecycle, client-lifecycle, storage-adapters]
actuals:
  tokens: 9912
  tasks: 3
  commits: 3
  plan_head_before: 2aa0f837d5291eb1bd408fb098f6895956fe3983
  plan_head_after: b46741311365fa623c4e06e1b4c93cc1b561ebef
tech-stack:
  added: []
  patterns:
    - Host recovery reloads and locks current state, then applies only the intended management deadline and update time
    - Conformance tests invoke replacement callbacks and inspect persisted lifecycle state
    - Client and required audit write failures are injected with temporary PostgreSQL triggers
key-files:
  created:
    - test/integration/management_token_lifetime_recovery_test.exs
    - test/lockspire/storage/management_token_rollback_test.exs
  modified:
    - lib/lockspire/protocol/registration_management.ex
    - lib/lockspire/storage/ecto/repository/client_store.ex
    - test/lockspire/storage/client_lifetime_conformance_test.exs
    - test/lockspire/storage/client_lifetime_promotion_test.exs
    - test/lockspire/client_lifecycle_test.exs
key-decisions:
  - "Keep the existing host recovery permission and confirmation layer; use a refreshed current-row snapshot after a lost PUT response."
  - "Calculate replacement deadline and audit timestamp from one clock value sampled after the row lock and current policy resolution."
  - "Canonicalize v0 from the locked row and preserve v1 app and secret deadlines."
requirements-completed: [DCR-11, DCR-12]
coverage:
  - id: D1
    description: Host recovery replaces lost or expired management authority under current policy while preserving app and secret state.
    requirement: DCR-11
    verification:
      - kind: integration
        ref: test/integration/management_token_lifetime_recovery_test.exs
        status: pass
    human_judgment: true
    rationale: The descriptor-less recovery-authority prohibition remains flagged for independent downstream classification.
  - id: D2
    description: Built-in and conforming adapters preserve management lifecycle state and promote legacy rows atomically.
    requirement: DCR-12
    verification:
      - kind: integration
        ref: test/lockspire/storage/client_lifetime_conformance_test.exs
        status: pass
      - kind: integration
        ref: test/lockspire/storage/client_lifetime_promotion_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Failed client writes and required audit writes roll back management replacement without disclosing a successful credential.
    requirement: DCR-12
    verification:
      - kind: integration
        ref: test/lockspire/storage/management_token_rollback_test.exs
        status: pass
    human_judgment: false
patterns-established:
  - "Host recovery transports only the intended deadline and updated_at through the existing lifecycle callback."
  - "Unsupported durable lifetime state remains a server error instead of being reported as an invalid credential."
duration: 9min
completed: 2026-10-21
status: complete
---

# Phase 165 Plan 04: Management Recovery and Rollback Summary

**Host staff can replace lost or expired management authority under current policy, with adapter-backed lifecycle persistence and full rollback on client or audit failure.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-21T18:16:52Z
- **Completed:** 2026-10-21T18:25:54Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Extended the existing host rotation operation with optional deferred time. It locks and reloads current state, binds the request to the original identity and management hash, resolves current policy, and persists the intended deadline, update time, and audit together. It does not require an active app and does not enable a disabled app.
- Proved positive, nil, and zero policy behavior; lost PUT recovery; stale snapshot rejection and refreshed retry; old-token rejection; and expired-enabled versus disabled app behavior. Expired enabled apps can use a recovered token for GET and DELETE, while PUT remains blocked.
- Extended adapter conformance to execute management replacement callbacks and validate persisted hash, deadline, version, and preserved metadata. Added v0 whole-row promotion and v1 deadline-preservation coverage, plus controls for dropped lifecycle fields and mismatched transaction authority.
- Added PostgreSQL fault injection for client write and required audit failures across PUT and host recovery for both v0 and v1 rows. Every failed operation preserved the full client row and audit count. Added malformed-clock, malformed-policy, and unsupported-version server-error checks.

## Task Commits

1. **Task 1: Recover with current policy without renewing the app** — `be10dba5` (feat)
2. **Task 2: Exercise management adapters and whole-row legacy promotion** — `d47f8178` (test)
3. **Task 3: Roll back management writes and required audits before disclosure** — `b4674131` (fix)

**Measured plan commits:** 3, from `2aa0f837d5291eb1bd408fb098f6895956fe3983` through `b46741311365fa623c4e06e1b4c93cc1b561ebef`.

## Verification

- Recovery and PUT suites: **9 tests, 0 failures**.
- Adapter conformance and promotion suites: **22 tests, 0 failures**.
- Rollback and client lifecycle suites: **6 tests, 0 failures**.
- `mix format` and `git diff --check` passed for the changed Elixir files.

## TDD Gate Compliance

- Task 1's deadline assertion was run before the implementation and failed because host rotation stored no replacement deadline. The run showed the target assertion failure, but the ExUnit text report was not accepted by the machine RED-evidence classifier and no separate RED commit was created.
- Tasks 2 and 3 do not have machine-validated RED reports or separate RED commits. Task 3 did expose an unsupported-version error-classification failure before the fix. This is a documented TDD process gap; the final focused suites pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve server-error classification for unsupported durable lifetime state**
- **Found during:** Task 3 (Rollback management writes and required audits before disclosure)
- **Issue:** Host rotation and management replacement mapped an unknown lifetime version to `invalid_token`, concealing a storage/configuration failure as a bad credential.
- **Fix:** Preserve `invalid_lifetime_state` through the repository rollback and return a server error at the protocol boundary.
- **Files modified:** `lib/lockspire/storage/ecto/repository/client_store.ex`, `lib/lockspire/protocol/registration_management.ex`
- **Verification:** Unsupported-version and rollback assertions pass in the focused task 3 suite.
- **Committed in:** `b4674131`.

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** The correction preserves the selected fail-closed error contract without changing storage schema or public callback arities.

## Issues Encountered

- Database round trips normalize DateTime microsecond precision. Assertions compare instants with `DateTime.compare/2` rather than structural equality.
- Unsupported lifetime state was initially reported as `invalid_token`; corrected and reverified as a server error.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 05 can build independent-session race and contended rollback proof on the established host-recovery transaction and current-row lifecycle handling. The descriptor-less recovery-authority prohibition remains flagged for independent classification.

## Self-Check: PASSED

- All seven created or modified implementation/test files exist; no placeholder or stub patterns were found.
- The three measured task commits are ancestors of the recorded plan head.
- All three focused verification commands passed with nonzero test counts.
- The original unstaged `.planning/state.json` bytes remain preserved from `/private/tmp/lockspire-phase165-original-state.json`.

---
*Phase: 165-management-token-lifecycle-recovery*
*Completed: 2026-10-21*
