---
phase: 92-advanced-setup-support-truth
plan: 03
subsystem: documentation-and-proof
tags: [support-contract, admin-copy, release-contracts, uat, mtls, logout, protected-routes]
requires:
  - phase: 92-01
    provides: reconciled mTLS host and maintainer guidance
  - phase: 92-02
    provides: reconciled protected-route and logout setup truth
provides:
  - canonical advanced-setup support contract covering mTLS, protected routes, and logout propagation
  - admin wording aligned to the same advanced-setup truth contract
  - phase-local UAT evidence tying support-truth claims to executable proof
affects: [93-01, 93-02, support-truth, release-contracts, admin-copy]
tech-stack:
  added: []
  patterns: [canonical-contract-plus-derived-guides, admin-copy-matches-public-contract, phase-local-uat-evidence]
key-files:
  created:
    - .planning/phases/92-advanced-setup-support-truth/92-UAT.md
  modified:
    - docs/supported-surface.md
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - lib/lockspire/web/live/admin/clients_live/form_component.ex
    - test/lockspire/release_readiness_contract_test.exs
    - test/lockspire/web/live/admin/clients_live/show_test.exs
    - test/lockspire/admin/clients_test.exs
key-decisions:
  - "The canonical support contract now names the two shipped mTLS extraction patterns, the canonical three-plug protected-route pipeline, and the asymmetric logout truth in one place."
  - "Admin client detail and logout-propagation surfaces must repeat the same separation between propagation URIs and post-logout redirects rather than inventing a softer operator contract."
patterns-established:
  - "Advanced-setup support truth is enforced by a combined set of canonical-doc assertions, runtime proof, admin wording tests, and a phase-local UAT artifact."
  - "Public docs stay authoritative while admin surfaces and adjacent guides defer to that contract with consistent terminology."
requirements-completed: [TRUTH-01, TRUTH-02, GUIDE-01, GUIDE-02, GUIDE-03]
duration: 6min
completed: 2026-05-25
---

# Phase 92 Plan 03: Align Canonical Contract, Admin Wording, And Proof Summary

**Lockspire now has one canonical advanced-setup truth contract across public docs, admin wording, release-contract tests, and phase-local closure evidence.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-25T19:35:30Z
- **Completed:** 2026-05-25T19:41:20Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Updated `docs/supported-surface.md` so the canonical support contract explicitly covers the two shipped mTLS extraction patterns, the canonical `VerifyToken -> EnforceSenderConstraints -> RequireToken` host Phoenix route pipeline, and the durable back-channel plus best-effort front-channel logout truth.
- Tightened admin client-detail and logout-propagation copy so operator surfaces preserve the same support boundaries, including the `/end_session/complete` fork point, the separation between propagation URIs and post-logout redirects, and the existing remote-JWKS command hint.
- Added release-readiness, LiveView, and admin assertions plus a `92-UAT.md` artifact so future drift in docs or operator wording fails loudly and remains auditable.

## Task Commits

1. **Task 1: Update the canonical support contract for the reconciled advanced-setup story** - `bbe1a1d` (`docs`)
2. **Task 2: Align admin wording and operator proof to the canonical advanced-setup contract** - `711e819` (`test`)
3. **Task 3: Record the exact closure evidence for the support-truth phase** - `91689a6` (`docs`)

## Verification

- `mix docs.verify` - PASS
- `mix test test/lockspire/release_readiness_contract_test.exs` - PASS
- `mix test test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/admin/clients_test.exs` - PASS
- `mix test test/integration/phase81_generated_host_route_protection_e2e_test.exs` - PASS
- `mix test test/lockspire/release_readiness_contract_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/admin/clients_test.exs` - PASS
- `rg -q 'mix docs.verify' .planning/phases/92-advanced-setup-support-truth/92-UAT.md && rg -q 'test/lockspire/release_readiness_contract_test.exs' .planning/phases/92-advanced-setup-support-truth/92-UAT.md && rg -q 'test/integration/phase81_generated_host_route_protection_e2e_test.exs' .planning/phases/92-advanced-setup-support-truth/92-UAT.md && rg -q 'test/lockspire/web/live/admin/clients_live/show_test.exs' .planning/phases/92-advanced-setup-support-truth/92-UAT.md && rg -q 'test/lockspire/admin/clients_test.exs' .planning/phases/92-advanced-setup-support-truth/92-UAT.md` - PASS

## Files Created/Modified

- `docs/supported-surface.md` - canonical advanced-setup support contract for mTLS, protected routes, and logout propagation
- `lib/lockspire/web/live/admin/clients_live/show.ex` - operator-facing logout wording aligned with the canonical truth contract
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` - logout propagation edit help text now names the protocol fork point and durable/best-effort split
- `test/lockspire/release_readiness_contract_test.exs` - support-contract assertions pin the advanced-setup truth
- `test/lockspire/web/live/admin/clients_live/show_test.exs` - LiveView assertions pin admin logout wording and workflow help text
- `test/lockspire/admin/clients_test.exs` - admin-domain assertions preserve logout metadata boundary behavior
- `.planning/phases/92-advanced-setup-support-truth/92-UAT.md` - exact automated closure evidence for Phase 92

## Decisions Made

- The public support contract stays terse but explicit: adjacent guides and admin surfaces can elaborate, but they must not broaden the contract.
- Front-channel logout remains framed everywhere as best-effort browser cleanup, never as proof of remote RP logout completion.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- One new admin wording test initially used a front-channel logout URI on a disallowed origin. The test fixture was corrected to the client origin so the product's existing validation rule stayed intact.

## User Setup Required

None.

## Known Stubs

None.

## Next Phase Readiness

- Phase 93 can now treat the advanced-setup support contract as settled public truth and focus on broader regression fencing, negative-path verification, and milestone-close proof.

## Self-Check: PASSED

- Found `.planning/phases/92-advanced-setup-support-truth/92-UAT.md`
- Found `.planning/phases/92-advanced-setup-support-truth/92-03-SUMMARY.md`
- Verified task commits `bbe1a1d`, `711e819`, and `91689a6` in git history

---
*Phase: 92-advanced-setup-support-truth*
*Completed: 2026-05-25*
