---
phase: 18-authorization-path-enforcement
plan: 02
subsystem: auth
tags: [oauth, oidc, par, phoenix, integration, testing]
requires:
  - phase: 18-authorization-path-enforcement
    provides: required-PAR enforcement in AuthorizationRequest with redirect-safe versus browser-safe classification
provides:
  - browser-surface proof for trusted redirect rejection versus first-party required-PAR rejection
  - canonical integration proof that direct required-PAR authorize is blocked while PAR-backed auth-code plus PKCE still succeeds
  - end-to-end proof that optional-PAR clients keep the supported direct browser flow
affects: [18-01 protocol enforcement, authorize browser boundary, PAR end-to-end verification]
tech-stack:
  added: []
  patterns: [thin Phoenix controller proof, canonical PAR journey reuse, policy-driven redirect safety assertions]
key-files:
  created: [.planning/phases/18-authorization-path-enforcement/18-02-SUMMARY.md]
  modified:
    - test/lockspire/web/authorize_controller_test.exs
    - test/integration/phase15_par_authorization_e2e_test.exs
key-decisions:
  - "Keep browser proof at the controller surface by driving PAR policy through repository seams and asserting only redirects versus first-party HTML responses."
  - "Extend the existing Phase 15 PAR journey instead of cloning a second required-PAR integration suite."
patterns-established:
  - "Required-PAR direct authorize failures remain redirect-safe only when the callback is already trusted exactly."
  - "Client optional override under a required global policy preserves the supported direct auth-code plus PKCE path."
requirements-completed: [PARPOL-03]
duration: 8min
completed: 2026-04-24
---

# Phase 18 Plan 02: Authorization Path Enforcement Summary

**Browser-boundary and canonical integration proof for required-PAR rejection, PAR-backed success, and optional-PAR continuity**

## Performance

- **Duration:** 8 min
- **Completed:** 2026-04-24T17:21:02Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added focused controller proofs for redirect-safe required-PAR rejection, first-party rejection when redirect trust is absent, optional-PAR direct login handoff continuity, and unchanged required-PAR PAR-backed handoff behavior.
- Extended the canonical PAR end-to-end journey so the same required-PAR client first fails on direct `/authorize`, then succeeds through `/par -> /authorize -> /token`, while an optional client override still completes the direct browser flow.
- Kept all proof at the intended seams: controller assertions stay browser-visible only, and the integration proof reuses the Phase 15 journey rather than duplicating suites.

## Task Commits

1. **Task 1: Add browser-surface proof for required-PAR rejection and unchanged optional/PAR-backed flows** - `491dd2b` (`test`)
2. **Task 2: Extend the canonical integration journey for required-PAR rejection and success through PAR** - `0f80b94` (`test`)

## Verification

- `MIX_ENV=test mix test test/lockspire/web/authorize_controller_test.exs` — PASS
- `MIX_ENV=test mix test test/integration/phase15_par_authorization_e2e_test.exs` — PASS
- `MIX_ENV=test mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/web/authorize_controller_test.exs test/integration/phase15_par_authorization_e2e_test.exs` — PASS
- `MIX_ENV=test mix test.fast` — FAIL, but only on the pre-existing unrelated blocker:
  `Lockspire.ReleaseReadinessContractTest` still expects older `.planning/PROJECT.md` wording, specifically `"PAR is the default next protocol-expansion milestone after release hardening"`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Both TDD RED expansions passed immediately because Phase 18-01 had already landed the required-PAR runtime behavior; this plan therefore completed as proof-only coverage work.
- The repo-wide fast gate remains blocked by the previously documented release-readiness contract assertion against `.planning/PROJECT.md`, which is outside the owned Phase 18-02 files and unrelated to authorization-path runtime behavior.

## Known Stubs

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/18-authorization-path-enforcement/18-02-SUMMARY.md`.
- Task commits `491dd2b` and `0f80b94` exist in git history.
