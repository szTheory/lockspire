---
phase: 164-client-secret-expiry-atomic-rotation
plan: "03"
subsystem: auth
tags: [oauth, oidc, secret-rotation, ecto, postgresql]

requires:
  - phase: 164-01
    provides: Shared client secret lifetime rules and current-row lifetime state
provides:
  - Operator secret replacement based on the current locked client row and current applicable DCR policy
  - Atomic replacement hash, verifier, rotation time, deadline, version, and audit behavior
  - Executed adapter conformance and legacy promotion/rollback coverage
affects: [164-04, 164-05, 164-06]

actuals:
  tokens: 10168
  tasks: 3
  commits: 4
commits: 4
plan_head_before: 525346d440d27d69cf8daab7ecf47e672be6c5d9
plan_head_after: f31f4096c7dea61608c7a1070ce7ea9c1b2ead0e

tech-stack:
  added: []
  patterns:
    - Deferred zero-argument clock sampled after current-row lock and applicable policy read
    - Adapter contract validation requires declared secret-replacement support

key-files:
  created:
    - test/integration/client_secret_lifetime_rotation_test.exs
    - .planning/phases/164-client-secret-expiry-atomic-rotation/164-03-01-red-evidence.json
  modified:
    - lib/lockspire/admin/clients.ex
    - lib/lockspire/client_lifecycle.ex
    - lib/lockspire/storage/client_store.ex
    - lib/lockspire/storage/client_lifetime.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/storage/ecto/repository/client_store.ex
    - test/lockspire/admin/clients_test.exs
    - test/lockspire/client_lifecycle_test.exs
    - test/lockspire/storage/client_lifetime_conformance_test.exs
    - test/lockspire/storage/client_lifetime_promotion_test.exs
    - test/lockspire/storage/client_lifetime_rollback_test.exs

key-decisions:
  - "Default rotation time is passed as a callback and sampled after the client row lock and current policy read; explicit DateTime callers remain supported."
  - "Only self-registered clients using a shared-secret authentication method receive the current DCR secret lifetime during replacement."
  - "V0 replacement clears all advisory deadlines before promotion; v1 replacement preserves app and management deadlines."

patterns-established:
  - "Lifecycle audit builders may derive event metadata from the committed replacement row."
  - "Secret replacement conformance exercises callbacks and detects adapters that drop lifecycle state."

requirements-completed: [DCR-09, DCR-07]

coverage:
  - id: D1
    description: "Operator replacement uses current locked provenance and policy with one deferred decision time for replacement and audit."
    requirement: DCR-09
    verification:
      - kind: integration
        ref: "test/integration/client_secret_lifetime_rotation_test.exs#operator rotation uses the current DCR policy and one deferred decision time"
        status: pass
    human_judgment: false
  - id: D2
    description: "Built-in and custom adapters execute the replacement contract, while missing, clock-ignoring, or lossy adapters fail conformance."
    requirement: DCR-09
    verification:
      - kind: integration
        ref: "test/lockspire/storage/client_lifetime_conformance_test.exs#built-in and custom adapters execute secret replacement with deferred time"
        status: pass
    human_judgment: false
  - id: D3
    description: "V0 advisory dates are canonicalized, v1 unrelated deadlines survive, operator recovery behavior is preserved, and write/audit failures roll back."
    verification:
      - kind: integration
        ref: "test/lockspire/storage/client_lifetime_promotion_test.exs#secret replacement canonicalizes every v0 historical deadline class"
        status: pass
      - kind: integration
        ref: "test/lockspire/storage/client_lifetime_rollback_test.exs#secret replacement write failure leaves the complete stored client unchanged"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-10-21
status: complete
---

# Phase 164 Plan 03: Atomic Client Secret Rotation Summary

**Operator rotation now commits the replacement credential lifecycle and audit from the current locked row, with its deadline derived from current DCR policy.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-10-21T14:17:12Z
- **Completed:** 2026-10-21T14:29:00Z
- **Tasks:** 3
- **Files modified:** 12 source and test files

## Accomplishments

- Default rotation calls defer `DateTime.utc_now/0` until after the Ecto adapter locks and reloads the current client row and reads applicable current policy. Explicit `rotated_at` DateTime inputs and existing exported function arities remain supported.
- Secret hash, protected JWT verifier, rotation timestamp, effective deadline, lifetime version, and required audit commit or roll back together. The audit event and success telemetry use the timestamp returned from the committed row; plaintext is returned only after the audit transaction succeeds.
- Adapter conformance now requires `rotate_client_secret/4` and executes built-in, custom, missing, clock-ignoring, and lossy adapter cases. Promotion tests cover nil, creation-time, past, future, and stale v0 dates; v1 app and management deadlines remain unchanged.
- Operator recovery tests preserve expired-secret replacement, disabled and expired app state, direct/operator policy boundaries, and dormant shared-secret material rotation for private-key clients.

## Task Commits

1. **Task 1: Rotate from the locked row using current policy and deferred time** - `fe447867` (feat)
2. **Task 2: Prove adapter transport and whole-row legacy canonicalization** - `e05e822b` (test)
3. **Task 3: Preserve operator policy and roll back failed secret delivery** - `3fc514d2` (test)
4. **Task 2 conformance follow-up: Reject adapters that ignore deferred clocks** - `f31f4096` (test)

**Plan metadata:** Included in the final summary, STATE, and ROADMAP commit.

## Files Created/Modified

- `lib/lockspire/admin/clients.ex` - Defers default rotation time and derives audit/telemetry time from the committed client.
- `lib/lockspire/client_lifecycle.ex` - Supports DateTime or clock inputs and builds audit events from the replacement result.
- `lib/lockspire/storage/client_store.ex` and `lib/lockspire/storage/client_lifetime.ex` - Declare deferred-time rotation and preserve ordinary use of lifetime-aware adapters that do not implement operator replacement.
- `lib/lockspire/storage/ecto/repository.ex` and `lib/lockspire/storage/ecto/repository/client_store.ex` - Load current policy after locking, calculate the effective deadline, and persist the full replacement lifecycle atomically.
- `test/integration/client_secret_lifetime_rotation_test.exs` - Exercises the real Admin.Clients replacement path, current DCR deadline, preserved v1 state, and matching audit time.
- `test/lockspire/admin/clients_test.exs`, `test/lockspire/client_lifecycle_test.exs`, and storage lifetime tests - Cover adapter conformance, legacy promotion, operator compatibility, and full rollback.
- `164-03-01-red-evidence.json` - Classifier-verified RED report for the deferred-time replacement behavior.

## Decisions Made

- Rotation policy is derived from the locked current row. Only self-registered clients using Basic, post, or secret JWT apply the current DCR secret duration; direct/operator and dormant non-secret rotations keep the unlimited boundary.
- A clock callback is the additive time transport. It is evaluated only after blocking row and policy reads; DateTime callers remain valid for deterministic integrations.
- V0 historical dates remain advisory until explicit replacement, when all three deadline fields are cleared before v1 promotion. V1 app and management deadlines are preserved.

## Verification

- Task 1: `mix test test/integration/client_secret_lifetime_rotation_test.exs test/lockspire/admin/clients_test.exs --max-failures 1 --timeout 55000` — **39 tests, 0 failures**.
- Task 2: `mix test test/lockspire/storage/client_lifetime_conformance_test.exs test/lockspire/storage/client_lifetime_promotion_test.exs test/lockspire/client_lifecycle_test.exs test/lockspire/compatibility_baseline_contract_test.exs --max-failures 1 --timeout 55000` — **27 tests, 0 failures**.
- Task 3: `mix test test/lockspire/admin/clients_test.exs test/lockspire/storage/client_lifetime_rollback_test.exs test/integration/client_secret_lifetime_rotation_test.exs --max-failures 1 --timeout 55000` — **51 tests, 0 failures**.
- Final plan-wide focused run after restoring the committed implementation and adding the clock-ignoring adapter case: rotation, admin, conformance, promotion, rollback, lifecycle, and compatibility files — **78 tests, 0 failures**.
- `gsd_run check tdd-red-evidence .planning/phases/164-client-secret-expiry-atomic-rotation/164-03-01-red-evidence.json --raw` — **RED_EVIDENCE_OK**. The target rotation assertion failed on the missing deferred decision time, then passed in the final focused run.

## New Symbols and Compatibility

- `ClientLifecycle.rotate_operator_secret/4` and the existing `Repository.rotate_client_secret/4` / `ClientStore.rotate_client_secret/4` accept either an explicit `DateTime` or a zero-argument clock function. No exported arity or result shape changed.
- `ClientLifetime.adapt/2` validates the Phase 163 lifetime declaration and guard callback. Secret replacement support is checked only when replacement is requested, so unrelated OAuth flows do not require operator-only storage behavior.

## Deviations from Plan

- A temporary ExUnit TAP formatter was used to produce classifier-compatible RED evidence, then removed. No lasting runtime or test dependency was added; implementation scope follows the plan.

## Issues Encountered

- The new integration test initially lacked a `TestRepo` setup. The fixture was corrected before the valid target RED run; no production change was required.

## Compatibility Follow-up

- Wave 2's full suite exposed that validating `rotate_client_secret/4` inside `ClientLifetime.adapt/2` rejected existing declared adapters used by token exchange, RFC 8693, and device flows. Rotation is now validated at the replacement boundary, while unsupported replacement still returns `:client_secret_rotation_unavailable` without entering the transaction.
- Focused adapter/token-exchange/RFC 8693/device/backchannel tests: **43 tests, 0 failures**.
- Supported full gate `mix test.fast`: **2 properties, 2,324 tests, 0 failures, 420 excluded, 6 skipped**.
- Follow-up implementation commit: `e715625f`.

## Known Limitations

- Independent PostgreSQL session serialization and observed lock-blocker races remain in plan 164-05. The full normal suite and cross-phase proof remain in plan 164-06.
- This plan does not close the complete Phase 164 DCR-07/08/09 proof or any Phase 165/166 requirements.

## Next Phase Readiness

- Plan 164-03 is ready for the next Phase 164 plan. Adapter and rotation behavior are focused-tested; independent-session races and full-suite verification remain outstanding.

---
*Phase: 164-client-secret-expiry-atomic-rotation*
*Completed: 2026-10-21*

## Self-Check: PASSED

All 14 listed artifacts exist, commits `fe447867`, `e05e822b`, `3fc514d2`, and `f31f4096` are ancestors of HEAD, and the changed implementation/test files contain no newly introduced TODO/FIXME/placeholder stubs.
