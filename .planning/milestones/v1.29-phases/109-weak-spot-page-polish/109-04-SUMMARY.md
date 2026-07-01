---
phase: 109-weak-spot-page-polish
plan: 04
subsystem: ui
tags: [phoenix-liveview, admin-ui, dcr, initial-access-token, copy-once]
requires:
  - phase: 108-design-system-token-component-upgrade
    provides: Phase 108 task cards, resource rows, long-value, and copy-once secret panel primitives
provides:
  - DCR onboarding page with locked onboarding/policy vocabulary and IAT handoff CTAs
  - IAT inventory with Configure context, status metrics, long-value rows, and consequence-specific revocation copy
  - IAT mint page using shared copy-once secret panel and shown-once wording
affects: [phase-109, phase-110, admin-configure-ui]
tech-stack:
  added: []
  patterns: [AdminComponents.page_hero, AdminComponents.metric_grid, AdminComponents.resource_item, AdminComponents.long_value, AdminComponents.copy_once_secret_panel]
key-files:
  created: []
  modified:
    - lib/lockspire/web/live/admin/dcr_live/index.ex
    - lib/lockspire/web/live/admin/iat_live/index.ex
    - lib/lockspire/web/live/admin/iat_live/index.html.heex
    - lib/lockspire/web/live/admin/iat_live/new.html.heex
    - test/lockspire/web/live/admin/iat_live_test.exs
key-decisions:
  - "DCR onboarding names partner intake and IAT workflows; DCR policy remains issuer registration posture."
  - "IAT plaintext continues to live only in the existing iat_secret assign and is rendered only through copy_once_secret_panel immediately after mint."
patterns-established:
  - "DCR/IAT configure surfaces should separate onboarding actions from issuer policy posture."
  - "IAT inventory rows should expose status, creator, usage limit, expiration, and safe revoke consequence without exposing token hashes or plaintext."
requirements-completed: [CONFIG-02, OPS-03, OPS-04]
duration: 5 min
completed: 2026-06-04
---

# Phase 109 Plan 04: DCR Onboarding And IAT Summary

**DCR onboarding and initial access token workflows with locked vocabulary, inventory metrics, mobile-safe rows, and shared copy-once secret treatment**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-04T08:24:30Z
- **Completed:** 2026-06-04T08:27:45Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Updated `/admin/dcr` copy to use `DCR onboarding` for partner intake and `DCR policy` for issuer registration posture, with `Mint initial access token` and `Review initial access tokens` CTAs.
- Reworked `/admin/iats` around Configure context, active/used/expired/revoked/total metrics, resource rows, long-value creator/expiration/state context, and consequence-specific `Revoke initial access token` copy.
- Replaced the ad hoc IAT secret reveal on `/admin/iats/new` with `copy_once_secret_panel` and explicit copy-once/not-shown-again wording.
- Extended focused IAT tests for DCR vocabulary, inventory metrics, long values, revoke copy, copy-once rendering, and acknowledge-clears-plaintext behavior.

## Task Commits

1. **Task 1: Tighten DCR onboarding and IAT inventory context** - `b1a29b2` (feat)
2. **Task 2: Upgrade IAT minting to shared copy-once treatment** - `b1a29b2` (feat)

**Plan metadata:** pending summary commit

## Files Created/Modified

- `lib/lockspire/web/live/admin/dcr_live/index.ex` - Tightens DCR onboarding/policy vocabulary and IAT CTAs.
- `lib/lockspire/web/live/admin/iat_live/index.ex` - Adds IAT metrics, redacted handle, usage, and timestamp helpers.
- `lib/lockspire/web/live/admin/iat_live/index.html.heex` - Adds Configure hero, metrics, long-value rows, and stronger revoke copy.
- `lib/lockspire/web/live/admin/iat_live/new.html.heex` - Uses `copy_once_secret_panel` for minted IAT plaintext.
- `test/lockspire/web/live/admin/iat_live_test.exs` - Proves vocabulary, inventory rows, revoke copy, and copy-once lifecycle.

## Decisions Made

- Did not alter `mint`, `acknowledge_copy`, or `revoke` events and did not change IAT storage, hashing, expiration, or plaintext lifetime.
- Used actual minted plaintext returned by the test setup for inventory redaction proof to avoid false positives from static class/session text.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep.

## Issues Encountered

- Initial test assertions matched class names embedded in CSS rather than rendered panel presence. Adjusted tests to assert user-visible copy and the actual plaintext secret lifecycle.

## Verification

- `mix test test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` - passed, 16 tests, 0 failures.
- `MIX_ENV=test mix compile --warnings-as-errors` - passed.
- Source acceptance checks for DCR vocabulary, IAT inventory primitives, copy-once panel, shown-once copy, and preserved event/API seams - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 109-05. Configure onboarding now has the intended vocabulary and copy-once treatment for Phase 109 contract fencing.

---
*Phase: 109-weak-spot-page-polish*
*Completed: 2026-06-04*
