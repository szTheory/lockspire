---
phase: 57
plan: 01
subsystem: auth
tags: [oauth, oidc, rar, introspection, liveview, integration]
requires:
  - phase: 56
    provides: durable consent-grant authorization_details storage and consent_grant_id token linkage
provides:
  - grant-backed authorization_details in active introspection responses
  - structural RAR visibility in ConsentLive
  - phase57 golden-path verification and narrow FAPI RAR regressions
affects: [58-milestone-closure-and-discovery, introspection, consent, fapi]
tech-stack:
  added: []
  patterns: [active-only introspection enrichment, compact token grant lookup, structural consent proof]
key-files:
  created: [test/integration/phase57_rar_introspection_verification_e2e_test.exs]
  modified:
    [
      lib/lockspire/protocol/introspection.ex,
      lib/lockspire/web/controllers/introspection_controller.ex,
      lib/lockspire/web/live/consent_live.ex,
      test/lockspire/protocol/introspection_test.exs,
      test/lockspire/web/introspection_controller_test.exs,
      test/lockspire/web/live/consent_live_test.exs,
      test/integration/phase43_fapi_milestone_e2e_test.exs
    ]
key-decisions:
  - "Expose the full normalized granted authorization_details array from ConsentGrant only for active access and refresh token introspection."
  - "Keep consent rendering structural and host-owned by showing generic authorization_details data rather than type-specific UI hooks."
patterns-established:
  - "Introspection resolves RAR by reference through token.consent_grant_id instead of token-embedded JSON."
  - "RAR-aware FAPI verification stays narrow: direct authorize rejection under PAR-required posture and PAR-backed success."
requirements-completed: [RAR-04, V-01, V-02]
duration: 1h
completed: "2026-05-06"
---

# Phase 57 Plan 01 Summary

**Grant-backed RAR introspection now returns durable authorization details to active callers, the consent surface shows the same normalized payload structurally, and the golden path is proven end to end with narrow FAPI regressions.**

## Performance

- **Duration:** ~1h
- **Started:** 2026-05-06T15:45:00Z
- **Completed:** 2026-05-06T16:00:00Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added active-only `authorization_details` enrichment to introspection for both access and refresh tokens using `ConsentGrant` lookup by `consent_grant_id`.
- Kept the host seam narrow by wiring `consent_store` through the controller and surfacing only structural RAR data in `ConsentLive`.
- Added a new phase-level E2E proving PAR -> consent -> token issuance -> introspection, plus narrow Phase 43 regressions showing RAR still obeys PAR-required and exact redirect behavior.

## Task Commits

Each task was committed atomically, with TDD tasks using separate red/green commits where useful:

1. **Task 1: Add active-only grant-backed RAR introspection**
   - `b30c984` test(57-01): add failing rar introspection coverage
   - `75e7e99` feat(57-01): enrich active introspection with granted rar data
2. **Task 2: Surface structural RAR proof in the host-owned consent UI**
   - `07403b1` test(57-01): add consent rar visibility coverage
   - `a6b2bed` feat(57-01): surface structural rar data in consent live
3. **Task 3: Prove the golden RAR path and narrow FAPI regressions**
   - `1d6b089` test(57-01): add rar end-to-end verification

## Files Created/Modified

- `lib/lockspire/protocol/introspection.ex` - resolves active token RAR data through `consent_grant_id`.
- `lib/lockspire/web/controllers/introspection_controller.ex` - passes `consent_store: Repository` into protocol-owned introspection.
- `lib/lockspire/web/live/consent_live.ex` - exposes structural `authorization_details` visibility and derived type names.
- `test/lockspire/protocol/introspection_test.exs` - covers access-token enrichment, refresh-token enrichment, missing-grant fallback, and compact-by-reference semantics.
- `test/lockspire/web/introspection_controller_test.exs` - verifies HTTP introspection behavior for enriched and missing-grant paths.
- `test/lockspire/web/live/consent_live_test.exs` - proves the consent surface renders normalized RAR structure.
- `test/integration/phase57_rar_introspection_verification_e2e_test.exs` - golden-path proof from PAR through introspection and refresh rotation.
- `test/integration/phase43_fapi_milestone_e2e_test.exs` - narrow RAR-aware FAPI regressions.

## Decisions Made

- Followed the phase context: return the full normalized granted payload by default, without adding a new host-facing projection seam.
- Kept inactive introspection responses unchanged as exactly `active: false`.
- Reused existing PAR and consent helpers instead of expanding the integration matrix.

## Deviations from Plan

None. The plan was executed as written.

## Issues Encountered

- The original executor worker stalled before handing back a summary. The useful Task 1 and Task 2 commits were already present in the repo, so the remaining verification work was completed locally and validated directly.

## User Setup Required

None.

## Verification

- `mix test test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs --warnings-as-errors`
- `mix test test/lockspire/web/live/consent_live_test.exs --warnings-as-errors`
- `mix test test/integration/phase57_rar_introspection_verification_e2e_test.exs test/integration/phase43_fapi_milestone_e2e_test.exs --include integration --warnings-as-errors`

All three passed on 2026-05-06.

## Next Phase Readiness

- Phase 58 can build on truthful RAR introspection, consent-surface proof, and the new end-to-end verification base.
- No blockers were identified during Phase 57 execution.
