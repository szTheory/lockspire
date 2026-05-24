---
phase: 84-host-plug-pipeline-docs-and-milestone-closure
plan: 02
subsystem: docs
tags: [docs, dpop, phoenix, release]
requires:
  - phase: 84-host-plug-pipeline-docs-and-milestone-closure
    provides: exact shipped nonce-backed host-route contract
provides:
  - narrowed public docs for nonce-backed DPoP support
  - onboarding wording for the canonical optional host-route path
  - release-readiness assertions for the nonce retry contract
affects: [supported-surface, onboarding, release]
tech-stack:
  added: []
  patterns:
    - public support claims stay anchored to repo-native proof and narrow host-route language
key-files:
  created: []
  modified:
    - docs/supported-surface.md
    - docs/protect-phoenix-api-routes.md
    - docs/install-and-onboard.md
    - test/lockspire/release_readiness_contract_test.exs
key-decisions:
  - "Pinned the public DPoP claim to Lockspire-owned `/token`, Lockspire-owned protected resources, and host Phoenix API routes protected by the shipped plug pipeline."
  - "Strengthened release-contract assertions around `error=\"use_dpop_nonce\"`, `DPoP-Nonce`, and the canonical host-route guide link."
patterns-established:
  - "Docs describe the embedded-library host-route path as optional guidance, not a second product topology."
requirements-completed: [NONCE-TRUTH-01, NONCE-TRUTH-02]
duration: 10m
completed: 2026-05-24
---

# Phase 84 Plan 02: Docs Truth Summary

**The public support contract now states the shipped nonce-backed DPoP surface precisely and the release-readiness test fences that wording in repo-native assertions.**

## Performance

- **Duration:** 10m
- **Started:** 2026-05-24T15:15:00Z
- **Completed:** 2026-05-24T15:25:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Narrowed `docs/supported-surface.md` to the exact shipped DPoP nonce surfaces, including the canonical host-route anchor phrase.
- Clarified `docs/protect-phoenix-api-routes.md` so the nonce retry contract and host-owned authorization boundary are explicit together.
- Updated onboarding and release-readiness assertions so the protected-route guide remains the canonical optional host-route path.

## Task Commits

This run executed in a dirty working tree and did not create phase-specific commits.

## Files Created/Modified

- `docs/supported-surface.md` - exact shipped nonce-backed DPoP support language
- `docs/protect-phoenix-api-routes.md` - explicit `use_dpop_nonce` retry and host-owned boundary wording
- `docs/install-and-onboard.md` - canonical optional host-route path wording
- `test/lockspire/release_readiness_contract_test.exs` - stronger release-truth checks for nonce retry docs

## Decisions Made

- Kept support wording tied to repo-proof surfaces only, excluding generic gateway and third-party issuer middleware claims.
- Reinforced that Lockspire verifies protocol facts while the host still owns business authorization and tenant policy.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `84-03`; the generated-host E2E proof can now point at docs that match the actual shipped contract.

## Self-Check: PASSED

- `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs`

