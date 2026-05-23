---
phase: 81-scope-audience-restrictions-milestone-closure
plan: 03
subsystem: docs
tags: [docs, exdoc, release, phoenix, protected-routes]
requires:
  - phase: 81-scope-audience-restrictions-milestone-closure
    provides: Verified route-level scope/audience enforcement and generated-host protected-route proof
provides:
  - Canonical host Phoenix API route protection guide
  - Truthful supported-surface and onboarding claims for protected routes
  - Final verification artifact for milestone closure
affects: [supported-surface, install-dx, sigra-companion, release-readiness]
tech-stack:
  added: []
  patterns: [guide-backed support claim, docs-contract verification, phase verification artifact]
key-files:
  created: [docs/protect-phoenix-api-routes.md, .planning/phases/81-scope-audience-restrictions-milestone-closure/81-VERIFICATION.md]
  modified: [mix.exs, docs/ecosystem-overview.md, docs/install-and-onboard.md, docs/sigra-companion-host.md, docs/supported-surface.md, test/lockspire/release_readiness_contract_test.exs]
key-decisions:
  - "Expanded the support claim only to host Phoenix routes protected by the documented plug pipeline, not to generic gateway or third-party issuer middleware."
  - "Kept business authorization, tenant checks, and rate limiting explicitly host-owned in every new doc touchpoint."
patterns-established:
  - "New public support claims land with a dedicated guide, ExDoc inclusion, release-readiness assertions, and a phase verification report in the same plan."
requirements-completed: [VAL-DX-02, VAL-DX-03]
duration: 12min
completed: 2026-05-23
---

# Phase 81: Scope/Audience Restrictions & Milestone Closure Summary

**Lockspire now documents and contract-tests the shipped Phoenix protected-route pattern, and Phase 81 closes with a verification report backed by green docs and test gates.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-23T16:20:00+02:00
- **Completed:** 2026-05-23T16:32:00+02:00
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added `docs/protect-phoenix-api-routes.md` as the canonical guide for `VerifyToken -> EnforceSenderConstraints -> RequireToken`.
- Updated onboarding, Sigra companion, supported-surface, and ExDoc metadata so the public claim matches the repo-proven Phoenix protected-route slice.
- Added final milestone verification evidence in `81-VERIFICATION.md` using the actual `mix docs` and targeted phase-suite outputs.

## Task Commits

Each task was committed atomically where practical:

1. **Task 1: Add the canonical protected-route guide and wire it into ExDoc/onboarding docs** - pending code commit
2. **Task 2: Update release-readiness contract coverage for the protected-route support claim** - pending code commit
3. **Task 3: Record final verification evidence for milestone closure** - pending summary commit

## Files Created/Modified

- `docs/protect-phoenix-api-routes.md` - New integrator guide for route-level scopes, audience checks, DPoP, and host-ownership boundaries.
- `docs/supported-surface.md` - Expands the truthful protected-resource claim to the shipped Phoenix plug pipeline and keeps gateway/service-mesh surfaces out of scope.
- `docs/install-and-onboard.md` - Adds the protected-route guide and phase-81 integration proof to the canonical host path.
- `docs/sigra-companion-host.md` - Clarifies how a Sigra-backed host reuses the same protected-route guide without shifting business authorization into Lockspire.
- `mix.exs` - Adds the new guide to ExDoc extras/groups.
- `test/lockspire/release_readiness_contract_test.exs` - Pins the new protected-route support claim and guide references.
- `docs/ecosystem-overview.md` - Removes a broken dependency on an untracked JTBD guide so `mix docs --warnings-as-errors` stays green from a clean checkout.
- `.planning/phases/81-scope-audience-restrictions-milestone-closure/81-VERIFICATION.md` - Final milestone verification report with actual command outputs.

## Decisions Made

- Kept the public claim scoped to Lockspire-issued tokens on host Phoenix routes using the documented plug pipeline.
- Rejected any wording that would imply generic gateway middleware, service-mesh enforcement, or third-party issuer validation support.
- Treated docs warnings as part of the closure bar and removed the accidental dependency on the untracked JTBD draft before finalizing the phase.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `mix docs --warnings-as-errors` initially depended on an untracked JTBD draft**
- **Found during:** Task 1 verification
- **Issue:** `docs/ecosystem-overview.md` linked to `user-flows-jtbd.md`, which is present only as an untracked worktree file.
- **Fix:** Pointed the ecosystem overview back to the tracked install/onboard guide and removed the temporary ExDoc dependency on the untracked draft.
- **Files modified:** `docs/ecosystem-overview.md`, `mix.exs`
- **Verification:** `mix docs --warnings-as-errors`
- **Committed in:** pending code commit

## Issues Encountered

- Targeted test runs still emit an early `KeyCache` refresh error before the test repo is started. The release-readiness and final phase suites both completed green, so this remained non-blocking for Phase 81.

## User Setup Required

None.

## Next Phase Readiness

- Future docs or release claims about protected resources now have a canonical guide and a contract test to extend instead of inventing new language.
- The milestone can close against `81-VERIFICATION.md` without relying on prose-only support claims.
