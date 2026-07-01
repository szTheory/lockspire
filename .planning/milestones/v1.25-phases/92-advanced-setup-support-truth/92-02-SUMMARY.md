---
phase: 92-advanced-setup-support-truth
plan: 02
subsystem: documentation
tags: [protected-routes, logout, onboarding, dcr, operator-guidance]
requires: []
provides:
  - canonical protected-route setup story with explicit sender-constraint guidance
  - aligned onboarding, operator, and DCR logout wording around one asymmetric runtime truth
affects: [92-03, docs-supported-surface, release-contracts, admin-copy]
tech-stack:
  added: []
  patterns: [canonical-three-plug-pipeline, asymmetric-logout-truth, metadata-versus-redirect-separation]
key-files:
  created: []
  modified:
    - docs/protect-phoenix-api-routes.md
    - docs/install-and-onboard.md
    - docs/operator-admin.md
    - docs/dynamic-registration.md
key-decisions:
  - "The protected-route guide must treat `Lockspire.Plug.EnforceSenderConstraints` as part of the canonical shipped path even when current traffic is mostly bearer tokens."
  - "All logout-facing docs must describe `/end_session/complete` as the protocol-owned fork point and keep back-channel durable while front-channel remains best effort only."
patterns-established:
  - "Adjacent setup docs repeat the same protected-route and logout truth instead of inventing competing runtime boundaries."
  - "Logout propagation metadata stays explicitly separate from post-logout redirect URIs across onboarding, operator, and DCR surfaces."
requirements-completed: [GUIDE-02, GUIDE-03]
duration: 4min
completed: 2026-05-25
---

# Phase 92 Plan 02: Tighten Protected-Route And Logout Setup Truth Summary

**The protected-route guide, onboarding guide, operator guide, and DCR docs now describe one canonical route pipeline and one asymmetric logout runtime story.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-25T19:32:00Z
- **Completed:** 2026-05-25T19:35:09Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Tightened the protected-route guide so the canonical pipeline always includes `Lockspire.Plug.VerifyToken`, `Lockspire.Plug.EnforceSenderConstraints`, and `Lockspire.Plug.RequireToken`, and explained why sender-constraint enforcement stays mounted even before DPoP or mTLS-bound traffic becomes common.
- Preserved the exact failure contract in docs: invalid or audience-mismatched tokens remain `401 invalid_token`, under-scoped valid tokens remain `403 insufficient_scope`, and DPoP nonce retry remains `401 use_dpop_nonce` plus `DPoP-Nonce`.
- Aligned onboarding, operator, and DCR logout wording around the same runtime truth: the host clears its own browser session first, `/end_session/complete` becomes the protocol-owned fork point, back-channel delivery is durable through Oban and Req, front-channel cleanup is best effort only, and logout propagation metadata remains separate from post-logout redirect URIs.

## Task Commits

1. **Task 1: Make the protected-route guide teach the canonical shipped pipeline and failure contract** - `19447dc` (`docs`)
2. **Task 2: Align onboarding, operator, and DCR logout wording around one asymmetric truth model** - `7171f43` (`docs`)

## Verification

- `mix test test/integration/phase81_generated_host_route_protection_e2e_test.exs` - PASS
- `mix docs.verify` - PASS
- `mix test test/lockspire/release_readiness_contract_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs` - PASS
- `rg -n "Lockspire\\.Plug\\.VerifyToken|Lockspire\\.Plug\\.EnforceSenderConstraints|Lockspire\\.Plug\\.RequireToken|no-op for unconstrained bearer tokens|401 invalid_token|403 insufficient_scope|use_dpop_nonce" docs/protect-phoenix-api-routes.md` - PASS
- `rg -n "/end_session/complete|durable back-channel delivery through Oban and Req|Front-channel logout is best effort only|separate from post-logout redirect URIs|do not create a second logout system|best effort browser choreography only" docs/install-and-onboard.md docs/operator-admin.md docs/dynamic-registration.md` - PASS

## Files Created/Modified

- `docs/protect-phoenix-api-routes.md` - canonical three-plug route pipeline and explicit sender-constraint rationale
- `docs/install-and-onboard.md` - clearer `/end_session/complete` ownership split and durable back-channel wording
- `docs/operator-admin.md` - operator-facing logout truth now anchors on the same durable/best-effort split
- `docs/dynamic-registration.md` - DCR logout metadata wording now stays narrow and explicitly separate from post-logout redirect behavior

## Decisions Made

- The protected-route support claim remains narrow to Lockspire-issued token validation on host Phoenix routes through the shipped plug pipeline.
- Logout propagation wording stays asymmetric across all surfaces so no guide or workflow implies that front-channel browser cleanup proves remote success.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None.

## Known Stubs

None.

## Next Phase Readiness

- Plan `92-03` can now pin the reconciled protected-route and logout truth in `docs/supported-surface.md`, admin wording, release-readiness assertions, and the phase UAT artifact.

## Self-Check: PASSED

- Found `.planning/phases/92-advanced-setup-support-truth/92-02-SUMMARY.md`
- Verified task commits `19447dc` and `7171f43` in git history

---
*Phase: 92-advanced-setup-support-truth*
*Completed: 2026-05-25*
