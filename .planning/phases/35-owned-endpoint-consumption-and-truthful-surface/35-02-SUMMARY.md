---
phase: 35-owned-endpoint-consumption-and-truthful-surface
plan: "02"
subsystem: auth
tags: [dpop, discovery, docs, oidc, phoenix]
requires:
  - phase: 35-owned-endpoint-consumption-and-truthful-surface
    provides: DPoP-aware userinfo enforcement and explicit bearer-vs-DPoP operator/client configuration
provides:
  - Truth-gated discovery publication of DPoP signing algorithms
  - Narrow supported-surface wording for the shipped DPoP slice
  - Release-readiness contract coverage for DPoP support-claim drift
affects: [36-01, 36-02, docs, discovery, release-contracts]
tech-stack:
  added: []
  patterns:
    - Discovery metadata is published only from mounted Lockspire-owned surface truth
    - Public support wording is pinned by executable contract tests
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/discovery.ex
    - test/lockspire/protocol/discovery_test.exs
    - test/lockspire/web/discovery_controller_test.exs
    - test/lockspire/release_readiness_contract_test.exs
    - docs/supported-surface.md
key-decisions:
  - "Publish dpop_signing_alg_values_supported only when both /token and Lockspire-owned /userinfo are mounted."
  - "Keep public DPoP claims narrow: token requests plus Lockspire-owned userinfo, with generic host protected-resource middleware still out of scope."
patterns-established:
  - "Discovery reads DPoP algorithm truth directly from Lockspire.Protocol.DPoP instead of duplicating constants."
  - "Release-readiness tests pin support-surface wording so docs cannot outrun repo-proven behavior."
requirements-completed: [DPoP-10]
duration: 5min
completed: 2026-04-28
---

# Phase 35 Plan 02: Owned Endpoint Consumption and Truthful Surface Summary

**Truth-gated DPoP discovery metadata and public support wording that stays inside the repo-proven owned-surface slice**

## Performance

- **Duration:** 5 min
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Discovery now publishes `dpop_signing_alg_values_supported` only when the mounted surface includes both `/token` and Lockspire-owned `/userinfo`.
- The published DPoP algorithm list comes directly from `Lockspire.Protocol.DPoP.signing_alg_values_supported/0`.
- Supported-surface docs and release-readiness tests now describe only the shipped DPoP slice: token requests plus Lockspire-owned `userinfo`, while bearer clients remain unchanged by default and generic host protected-resource middleware stays out of scope.

## Task Commits

1. **Task 1: Publish truth-gated DPoP discovery metadata from mounted owned-surface reality** - `460e41d` (test), `b0a1502` (feat)
2. **Task 2: Update the supported-surface contract and pin it with release-readiness tests** - `aa98158` (test), `820e903` (feat)

## Files Created/Modified
- `lib/lockspire/protocol/discovery.ex` - Gates DPoP metadata on mounted owned-surface truth and reuses the canonical DPoP algorithm export.
- `test/lockspire/protocol/discovery_test.exs` - Covers present/refute DPoP metadata behavior for token-plus-userinfo vs token-only route shapes.
- `test/lockspire/web/discovery_controller_test.exs` - Proves the HTTP discovery response mirrors the same DPoP metadata truth gate.
- `test/lockspire/release_readiness_contract_test.exs` - Pins narrow DPoP support wording in the release contract.
- `docs/supported-surface.md` - Documents the shipped DPoP slice and keeps broader protected-resource claims explicitly out of scope.

## Decisions Made
- Discovery truth now depends on route reality rather than static claims, so DPoP metadata appears only when the shipped Lockspire-owned surface can actually enforce it.
- Public docs stay intentionally narrow and are contract-tested to prevent overclaiming generic resource-server support.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced invalid `mix test ... -x` verification commands**
- **Found during:** Task 1 and Task 2 verification
- **Issue:** The plan's canned Mix commands use `-x`, which the current Mix version rejects before any tests run.
- **Fix:** Verified the same file-scoped suites with plain `mix test` invocations.
- **Files modified:** `.planning/phases/35-owned-endpoint-consumption-and-truthful-surface/35-02-SUMMARY.md`
- **Verification:** `MIX_ENV=test mix test.setup && MIX_ENV=test mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/release_readiness_contract_test.exs`
- **Committed in:** metadata closeout

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Verification remained fully automated and equivalent in scope. No product-surface scope change.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 36 can rely on truthful discovery metadata and support docs when extending end-to-end DPoP proof.
- The milestone now has aligned runtime enforcement, operator controls, and public claims for the shipped owned-surface DPoP slice.

## Self-Check: PASSED
- Found summary file on disk.
- Verified task commits `460e41d`, `b0a1502`, `aa98158`, and `820e903` in git history.
