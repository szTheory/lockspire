---
phase: 43-end-to-end-fapi-validation
plan: 05
subsystem: docs
tags: [fapi, oidc, docs, security, release-posture]
requires:
  - phase: 41-fapi-2-0-profile-configuration
    provides: "Resolved FAPI 2.0 enforcement semantics and discovery truth boundaries"
  - phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep
    provides: "Canonical FAPI algorithm posture and pinned OIDF conformance lane references"
provides:
  - "Pinned public FAPI 2.0 claim language across SECURITY.md, README.md, and supported-surface docs"
  - "Explicit non-claims for OIDF certification and mTLS in the public preview contract"
  - "Plan 07-ready doc vocabulary for release-truth contract assertions"
affects: [release-readiness, public-docs, fapi-claims, plan-07-contract]
tech-stack:
  added: []
  patterns: [additive-doc-claims, pinned-string-vocabulary, truthful-preview-posture]
key-files:
  created:
    - .planning/phases/43-end-to-end-fapi-validation/43-05-truthful-claim-docs-SUMMARY.md
  modified:
    - SECURITY.md
    - README.md
    - docs/supported-surface.md
key-decisions:
  - "Public FAPI 2.0 claim wording stays additive inside existing supported/out-of-scope sections instead of rewriting preview posture copy."
  - "OIDF and mTLS remain explicit non-claims in every public doc so release posture cannot drift into certification overclaim."
patterns-established:
  - "Pinned doc vocabulary: the same claim strings should be reused verbatim by contract tests and public docs."
  - "Truth-in-docs edits for security posture stay additive and localized to existing support/out-of-scope blocks."
requirements-completed: [FAPI-05, FAPI-06]
duration: 18min
completed: 2026-05-03
---

# Phase 43 Plan 05: Truthful Claim Docs Summary

**Pinned FAPI 2.0 Security Profile claim language across the public docs, including explicit OIDF and mTLS non-claims for the preview contract**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-03T12:27:00Z
- **Completed:** 2026-05-03T12:45:37Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Added the full locked FAPI 2.0 claim vocabulary to `SECURITY.md`, including the new `## FAPI 2.0 posture` section.
- Extended `README.md` and `docs/supported-surface.md` additively so the public preview contract now names the enforced FAPI surfaces and the explicit non-claims.
- Verified that all pinned strings are present in every owned doc and that the literal word `certified` is absent.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add FAPI 2.0 claim bullets to SECURITY.md (D-19)** - `4ed6b1f` (docs)
2. **Task 2: Add FAPI 2.0 claim bullets to README.md (D-19)** - `20559cc` (docs)
3. **Task 3: Add FAPI 2.0 claim bullets to docs/supported-surface.md (D-19)** - `94176ff` (docs)

## Files Created/Modified

- `SECURITY.md` - Added additive FAPI enforcement bullets and a bounded FAPI 2.0 posture section.
- `README.md` - Added FAPI support bullets plus explicit OIDF and mTLS exclusions in the preview surface summary.
- `docs/supported-surface.md` - Added canonical supported-surface and out-of-scope FAPI claim bullets.
- `.planning/phases/43-end-to-end-fapi-validation/43-05-truthful-claim-docs-SUMMARY.md` - Execution summary for this plan.

## Decisions Made

- Public FAPI language stayed inside existing supported/in-scope and out-of-scope blocks to preserve the preview contract shape.
- Each doc now carries both positive enforcement claims and negative certification/mTLS non-claims so Plan 07 can pin a single shared vocabulary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used repo-local grep verification because `scripts/check_fapi_doc_strings.sh` is absent**
- **Found during:** Task 1 (Add FAPI 2.0 claim bullets to SECURITY.md)
- **Issue:** The plan's first verification command references `scripts/check_fapi_doc_strings.sh`, but that script does not exist in the repo.
- **Fix:** Replaced that missing-step check with direct `rg`/count verification for every pinned positive and negative string, then ran `mix test test/lockspire/release_readiness_contract_test.exs --color`.
- **Files modified:** None
- **Verification:** All string counts passed; release readiness test file passed with 14 tests and 0 failures.
- **Committed in:** N/A (verification-only deviation)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Verification still matched the plan's acceptance criteria exactly. No scope creep and no doc content drift.

## Issues Encountered

- `STATE.md` is still in a pre-execution Phase 43 shape (`Plan: 0 of 0`), so the normal `state advance-plan` handler is not safe for this single-plan execution pass.
- `STATE.md` also lacks a writable execution metrics table shape for `state record-metric`, so progress/session updates were recorded but the metric row could not be appended through the local GSD CLI.
- Concurrent work is modifying unrelated files in the tree; this plan intentionally left those changes untouched.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The three public docs now contain the locked FAPI 2.0 wording that Plan 07 can assert verbatim.
- Remaining Phase 43 work still needs to land before FAPI-05/FAPI-06 can be treated as fully closed at the milestone level.

## Self-Check: PASSED

---
*Phase: 43-end-to-end-fapi-validation*
*Completed: 2026-05-03*
