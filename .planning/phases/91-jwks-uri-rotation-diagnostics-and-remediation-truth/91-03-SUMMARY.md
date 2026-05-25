---
phase: 91-jwks-uri-rotation-diagnostics-and-remediation-truth
plan: 03
subsystem: testing
tags: [jwks, private_key_jwt, docs, release-contract, integration]
requires:
  - phase: 91-01
    provides: shared remote JWKS diagnostics taxonomy and bounded-refresh runtime truth
  - phase: 91-02
    provides: doctor/admin support surfaces for remote JWKS incidents
provides:
  - canonical bounded reactive remote-jwks support wording
  - host remediation guidance and ownership split for remote jwks incidents
  - end-to-end proof and phase-local UAT evidence for the remote jwks support contract
affects: [92-01, 92-02, support-truth, release-contracts]
tech-stack:
  added: []
  patterns: [docs-and-tests lock support truth, phase-local uat artifact for automation evidence]
key-files:
  created:
    - .planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-UAT.md
  modified:
    - docs/supported-surface.md
    - docs/private-key-jwt-host-guide.md
    - docs/install-and-onboard.md
    - test/integration/phase62_private_key_jwt_e2e_test.exs
    - test/lockspire/release_readiness_contract_test.exs
key-decisions:
  - "The public support contract names remote jwks_uri rollover as bounded reactive support and explicitly excludes proactive readiness claims."
  - "The host guide teaches one remediation sequence that starts with doctor/admin diagnostics and treats inline jwks as a deliberate fallback only."
patterns-established:
  - "Remote jwks support wording is pinned in release-contract tests and backed by the existing phase 62 end-to-end flow."
  - "Install verification remains separate from runtime remote-key diagnosis across docs and proof."
requirements-completed: [JWKS-01, JWKS-02]
duration: 4min
completed: 2026-05-25
---

# Phase 91 Plan 03: Bounded Reactive Remote JWKS Support Truth Locked By Docs And Proof Summary

**Canonical support docs, host remediation guidance, and repo-native proof now agree on Lockspire's bounded reactive remote-`jwks_uri` rollover contract.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-25T16:27:00Z
- **Completed:** 2026-05-25T16:30:40Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added one terse canonical statement for bounded reactive remote-`jwks_uri` rollover support, including one forced refresh, last-known-good preservation, and explicit proactive non-claims.
- Reworked the `private_key_jwt` host guide and onboarding guide so runtime diagnosis, remediation order, ownership split, and doctor-vs-verify boundaries are explicit.
- Tightened the Phase 62 end-to-end proof to cover both remote rollover recovery and remote fail-closed `invalid_client` behavior, then recorded the closing automation in `91-UAT.md`.

## Task Commits

1. **Task 1: Update the canonical support contract for bounded reactive rollover truth** - `4882d12` (`docs`)
2. **Task 2: Tighten host guidance around diagnosis, remediation, and ownership split** - `c28b890` (`docs`)
3. **Task 3: Record and prove the remote-JWKS support story end to end** - `8dfbd53` (`test`)

## Verification

- `mix test test/lockspire/release_readiness_contract_test.exs` - PASS
- `mix docs.verify` - PASS
- `mix test test/integration/phase62_private_key_jwt_e2e_test.exs test/lockspire/release_readiness_contract_test.exs` - PASS
- `test -f .planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-UAT.md` - PASS
- `rg -n 'bounded reactive|publish the new key before first use|Inline \`jwks\` is a deliberate fallback|Lockspire owns:|The host team owns:|does not diagnose runtime remote-\`jwks_uri\` incidents|mix lockspire\\.doctor remote-jwks --client <client_id>' docs/supported-surface.md docs/private-key-jwt-host-guide.md docs/install-and-onboard.md` - PASS

## Files Created/Modified

- `docs/supported-surface.md` - canonical bounded reactive remote-JWKS support contract and proactive non-claims
- `docs/private-key-jwt-host-guide.md` - runtime diagnosis flow, remediation sequence, ownership split, and inline-`jwks` fallback posture
- `docs/install-and-onboard.md` - explicit install-verification versus runtime-diagnosis boundary
- `test/integration/phase62_private_key_jwt_e2e_test.exs` - remote rollover recovery plus remote fail-closed generic error proof
- `test/lockspire/release_readiness_contract_test.exs` - support-truth guardrails for canonical, host-guide, and onboarding wording
- `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-UAT.md` - exact automated closeout commands and expected evidence

## Decisions Made

- The canonical support contract stays terse while the host guide carries the full operator remediation sequence and ownership split.
- Remote fail-closed proof now uses the same `jwks_uri` client path as rollover recovery so the docs and executable behavior stay aligned on the exact advanced surface this phase targeted.

## Deviations from Plan

### Execution Scope

- The standard executor workflow would also update `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md`, but those files were outside the user-authorized write scope for this run.

### Blocking Input Gap

- **[Rule 3 - Blocking] Task 3 `read_first` referenced `.planning/phases/90-support-truth-and-milestone-closure/90-UAT.md`, but no Phase 90 UAT artifact exists in the repo.**
  - **Found during:** Task 3
  - **Issue:** The plan pointed to a non-existent prior UAT file for format/context.
  - **Fix:** Searched `.planning/phases/` for Phase 90 or any `*UAT.md` artifact, confirmed none exist, then created `91-UAT.md` directly from the current plan requirements and existing summary conventions.
  - **Files modified:** `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-UAT.md`
  - **Verification:** `test -f .planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-UAT.md`
  - **Committed in:** `8dfbd53`

---

**Total deviations:** 1 blocking input gap handled, 0 auto-fixed code defects
**Impact on plan:** No behavior or scope drift. The missing historical artifact only changed how the new UAT file format was derived.

## Issues Encountered

- The first remote fail-closed assertion undercounted fetch activity. The final proof reflects the actual runtime path: one cached read plus one forced refresh during the failing remote assertion.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Phase 92 can now treat the remote-JWKS support story as fixed public truth across docs, doctor/admin guidance, and executable proof.
- Future support-truth work has a reusable UAT artifact pattern for recording exact automation evidence inside the phase directory.

## Self-Check: PASSED

- Found `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-UAT.md`
- Found `.planning/phases/91-jwks-uri-rotation-diagnostics-and-remediation-truth/91-03-SUMMARY.md`
- Verified task commits `4882d12`, `c28b890`, and `8dfbd53` in git history

---
*Phase: 91-jwks-uri-rotation-diagnostics-and-remediation-truth*
*Completed: 2026-05-25*
