---
phase: 165-management-token-lifecycle-recovery
plan: "06"
subsystem: auth
tags: [oauth, dcr, management-token, telemetry, liveview, redaction]
requires:
  - phase: 165-management-token-lifecycle-recovery
    plan: "05"
    provides: Serialized current-policy management-token replacement and persisted lifecycle guarantees
provides:
  - Correct operator attribution for host recovery telemetry while self-management remains self-attributed
  - Mounted one-time host recovery and public authority-boundary regression coverage
  - Accurate finite management-token policy, recovery and unlimited lifetime guidance
affects: [phase-166, DCR-11, DCR-12, admin-guidance]
actuals:
  tokens: 13757
  tasks: 3
  commits: 7
plan_head_before: a7cd3e7f2c8f75cd61ac4ee1e95b5e0ef558f678
plan_head_after: 85471a49a897a3a8d38b353a17a51482ab3c94a9
tech-stack:
  added: []
  patterns:
    - Explicit actor context on shared management-token rotation telemetry
    - Positive event-count assertions before scanning sensitive output channels
key-files:
  created:
    - test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs
    - .planning/phases/165-management-token-lifecycle-recovery/165-06-01-red-evidence.json
    - .planning/phases/165-management-token-lifecycle-recovery/165-06-02-red-evidence.json
    - .planning/phases/165-management-token-lifecycle-recovery/165-06-03-red-evidence.json
  modified:
    - lib/lockspire/protocol/registration_management.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - lib/lockspire/web/live/admin/policies_live/dcr.html.heex
    - lib/lockspire/web/live/admin/policies_live/dcr/lifetime_hint.ex
    - PRODUCT.md
    - test/lockspire/protocol/dcr_telemetry_redaction_test.exs
    - test/lockspire/protocol/dcr_audit_attribution_test.exs
    - test/lockspire/web/live/admin/policies_live/dcr/lifetime_hint_test.exs
    - test/lockspire/web/live/admin/policies_live/dcr_test.exs
key-decisions:
  - "Keep recovery on the existing host-mounted admin task; do not add staff authorization or a public recovery route to Lockspire."
  - "Blank and zero management-token lifetimes mean unlimited; positive policy applies to new or replaced tokens and does not change existing tokens."
requirements-completed: [DCR-11, DCR-12]
coverage:
  - id: D1
    description: Observed finite-token events have correct self and host actors and leak no sensitive material.
    requirement: DCR-11
    verification:
      - kind: integration
        ref: test/lockspire/protocol/dcr_telemetry_redaction_test.exs and test/lockspire/protocol/dcr_audit_attribution_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Confirmed mounted host recovery reveals a committed token once and preserves app lifecycle state.
    requirement: DCR-12
    verification:
      - kind: integration
        ref: test/lockspire/web/live/admin/clients_live/management_token_recovery_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Policy guidance explains unlimited and finite behavior, recovery, and retired wording contracts.
    verification:
      - kind: automated_ui
        ref: test/lockspire/web/live/admin/policies_live/dcr_test.exs and test/lockspire/web/live/admin/vocabulary_contract_test.exs
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-10-21
status: complete
---

# Phase 165 Plan 06: Management Token Lifecycle Recovery Summary

**Management recovery now reports the operator actor, proves one-time host rotation and redaction, and explains finite-token lockout and recovery accurately.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-10-21T18:38:00Z
- **Completed:** 2026-10-21T18:48:29Z
- **Tasks:** 3
- **Files modified:** 14, including three TDD evidence records

## Accomplishments

- Host recovery rotation telemetry and durable audit now identify the operator (`admin-ui`); self-managed replacement retains `self_registered_client` attribution. Regression tests require positive real event counts and scan telemetry, logs, public errors and durable audit for token material.
- A mounted recovery suite proves confirmation, one-time committed disclosure, acknowledgement/navigation clearing, failure behavior, disabled/expired lifecycle preservation, and that public management credentials cannot invoke host recovery.
- Admin guidance now explains unlimited blank/zero settings, prospective positive lifetimes, no retroactive changes, expiry lockout, provider-team recovery after access loss or a lost update response, and that rotating a token does not renew the app or its secret. Replaced wording is recorded in PRODUCT.md.

## Task Commits

1. **Task 1: Observe real finite-token events with correct actors and redaction** — `6abf5f1a` (test), `3970cf50` (feat).
2. **Task 2: Prove confirmed host recovery and one-time delivery** — `9a960da0` (test), `9ac05bf0` (feat), `d8adaa4f` (test refinement).
3. **Task 3: Explain enforced finite management policy in existing admin copy** — `4480cbde` (test), `85471a49` (feat).

## Files Created/Modified

- `lib/lockspire/protocol/registration_management.ex` — emits rotation telemetry with the correct host or self actor.
- `lib/lockspire/web/live/admin/clients_live/show.ex` — explains immediate invalidation, provider recovery and lifecycle consequences.
- `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` and `lib/lockspire/web/live/admin/policies_live/dcr/lifetime_hint.ex` — describe and preview enforced, unlimited and prospective lifetimes.
- `PRODUCT.md` — records retired copy so stale policy or rotation wording cannot return.
- Protocol, LiveView and vocabulary tests — cover redaction, actor attribution, host-only recovery, form accessibility and policy guidance.
- Three `165-06-0N-red-evidence.json` files — preserve verified RED reports for each TDD task.

## Decisions Made

- Retained the existing host-owned admin mount and confirmation flow. Lockspire does not add staff accounts or a public recovery route.
- Kept management-token expiry optional. Blank and zero mean no automatic expiry; a positive duration affects only newly issued or replaced tokens.

## TDD Gate Compliance

- All three `tdd="true"` tasks committed a failing target-test report before implementation. Each evidence record passed `gsd_run check tdd-red-evidence` with `RED_EVIDENCE_OK`.
- Final combined verification ran all task suites: **68 tests, 0 failures**. The task-specific policy/copy command also passed with **24 tests, 0 failures**.
- The combined suite covered telemetry/redaction, audit attribution, mounted recovery, existing client Show behavior, public router boundaries, duration hints, the vocabulary contract, and rendered DCR policy form.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replace stale telemetry event subscriptions in the regression test**
- **Found during:** Task 1.
- **Issue:** Existing redaction coverage subscribed to outdated flat event names, allowing assertions against an empty capture.
- **Fix:** Subscribed to the implemented nested DCR events and their audit mirrors; asserted positive observed counts before checking payloads.
- **Files modified:** `test/lockspire/protocol/dcr_telemetry_redaction_test.exs`.
- **Verification:** The protocol event and audit suites passed within the combined 68-test run.
- **Committed in:** `3970cf50`.

**2. [Rule 2 - Missing Critical] Show unlimited behavior in the management-token duration hint**
- **Found during:** Task 3.
- **Issue:** The field helper rendered blank or zero as an absent or `0 seconds` hint, contradicting the planned unlimited policy explanation.
- **Fix:** Extended the existing no-automatic-expiry hint behavior to management tokens and added blank/zero assertions.
- **Files modified:** `lib/lockspire/web/live/admin/policies_live/dcr/lifetime_hint.ex`, `test/lockspire/web/live/admin/policies_live/dcr/lifetime_hint_test.exs`.
- **Verification:** Duration and rendered policy tests passed.
- **Committed in:** `85471a49`.

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 2).
**Impact on plan:** Both corrections make the planned event and unlimited-lifetime assertions meaningful; no architecture or host boundary changed.

## Issues Encountered

- The TDD evidence classifier does not accept the default ExUnit console reporter. A temporary formatter outside the repository emitted actual ExUnit events as TAP; all three RED reports then passed the canonical classifier.
- The new copy initially invalidated an existing assertion for the previous policy summary. That assertion was updated to require the current guidance, and the complete focused suites passed.
- A first retired-wording row matched the new checkbox wording too broadly; the phrase entry was narrowed to the wording that was actually retired, then the vocabulary contract passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The management-token lifecycle and its host recovery behavior are covered end to end with truthful operator guidance. Phase 166 can build the broader integrated lifecycle guidance on these verified semantics.

## Self-Check: PASSED

- All files listed above exist, and all seven task commits are ancestors of HEAD.
- Plan commit count was measured from `plan_head_before` through `plan_head_after`; `.planning/state.json` was excluded from the plan diff and remains byte-for-byte equal to the supplied backup.

---
*Phase: 165-management-token-lifecycle-recovery*
*Completed: 2026-10-21*
