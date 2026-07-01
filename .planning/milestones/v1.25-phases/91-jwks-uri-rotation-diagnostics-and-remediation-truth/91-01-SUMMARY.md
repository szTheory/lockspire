---
phase: 91-jwks-uri-rotation-diagnostics-and-remediation-truth
plan: 01
subsystem: auth
tags: [jwks, oidc, diagnostics, telemetry, jarm, private_key_jwt]
requires: []
provides:
  - shared remote JWKS incident taxonomy for shipped jwks_uri consumers
  - bounded-reactive rollover posture facts and remediation guidance
  - unified telemetry metadata for private_key_jwt and JARM remote key failures
affects: [91-02, 91-03, support-truth, doctor-surfaces]
tech-stack:
  added: []
  patterns: [shared diagnostics mapper, bounded refresh telemetry metadata]
key-files:
  created:
    - lib/lockspire/diagnostics/remote_jwks.ex
    - test/lockspire/diagnostics/remote_jwks_test.exs
  modified:
    - lib/lockspire/jwks_fetcher.ex
    - lib/lockspire/observability.ex
    - lib/lockspire/protocol/client_auth/private_key_jwt.ex
    - lib/lockspire/protocol/jarm/client_key_resolver.ex
    - test/lockspire/jwks_fetcher_test.exs
    - test/lockspire/protocol/client_auth_test.exs
    - test/lockspire/protocol/jarm_test.exs
key-decisions:
  - "Remote jwks_uri failures normalize through one shared diagnostics module instead of protocol-local reason vocabularies."
  - "JARM keeps its existing return atoms and emits the shared remote-JWKS truth through telemetry metadata."
patterns-established:
  - "Remote JWKS incidents carry stable class plus safe stage/subreason facts."
  - "Bounded reactive rollover facts are emitted explicitly: one forced refresh, last-known-good preservation, and fail-closed current request behavior."
requirements-completed: [JWKS-01, JWKS-02]
duration: 9min
completed: 2026-05-25
---

# Phase 91 Plan 01: Codify Shared Remote-JWKS Runtime Diagnostics And Failure Taxonomy Summary

**Shared remote-JWKS diagnostics now classify fetch, invalid-document, key-unavailable, and signature-invalid incidents consistently across `private_key_jwt` and JARM.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-05-25T16:05:44Z
- **Completed:** 2026-05-25T16:14:49Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments
- Added `Lockspire.Diagnostics.RemoteJwks` as the authoritative mapper for the four stable remote-JWKS incident classes, bounded-reactive posture facts, and remediation text.
- Extended `private_key_jwt` failure handling so guarded fetch failures, post-refresh key unavailability, and post-refresh signature failures carry shared remote-JWKS metadata without changing the generic OAuth wire behavior.
- Brought JARM onto the same remote-key diagnostics contract through telemetry metadata while preserving current key-selection and protocol return semantics.

## Task Commits

1. **Task 1: Build the shared remote-JWKS diagnostics module and stable taxonomy** - `13064b7` (`feat`)
2. **Task 2: Normalize private_key_jwt remote-key failures through the shared model** - `93c71a5` (`feat`)
3. **Task 3: Bring JARM onto the same remote-key diagnostics contract** - `0fbd363` (`feat`)

## Files Created/Modified
- `lib/lockspire/diagnostics/remote_jwks.ex` - shared remote-JWKS incident struct, classifier helpers, metadata shape, and remediation guidance.
- `lib/lockspire/jwks_fetcher.ex` - safe fetch-error detail mapper used by the shared diagnostics layer.
- `lib/lockspire/observability.ex` - helper for merging normalized remote-JWKS incident metadata into telemetry/audit payloads.
- `lib/lockspire/protocol/client_auth/private_key_jwt.ex` - remote fetch and retry failures now emit shared remote-JWKS incident metadata while preserving generic `invalid_client` semantics.
- `lib/lockspire/protocol/jarm/client_key_resolver.ex` - JARM remote-key fetch and refresh misses now emit the same shared remote-JWKS vocabulary through telemetry.
- `test/lockspire/diagnostics/remote_jwks_test.exs` - direct proof for class mapping, posture facts, and remediation messages.
- `test/lockspire/jwks_fetcher_test.exs` - proof for the safe fetch-detail mapping used by incident classification.
- `test/lockspire/protocol/client_auth_test.exs` - proof for remote fetch failure, post-refresh key-unavailable, and post-refresh signature-invalid telemetry metadata.
- `test/lockspire/protocol/jarm_test.exs` - proof that JARM shares the same remote-JWKS taxonomy for fetch and refresh miss incidents.

## Decisions Made
- The shared diagnostics layer exposes exactly four stable operator-facing classes and keeps transport or cache specifics in safe metadata fields instead of multiplying top-level reason codes.
- `private_key_jwt` uses refreshed-key presence to distinguish `remote_jwks_key_unavailable` from `remote_jwks_signature_invalid`, so support truth reflects what Lockspire actually observed after the bounded refresh attempt.
- JARM emits the shared incident model via telemetry rather than widening its return contract, which keeps the current JARM protocol surface stable inside this plan.

## Deviations from Plan

### Execution Scope

- The workflow normally updates `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md`, but those files were outside the user-authorized write scope for this run.

---

**Total deviations:** 0 auto-fixed
**Impact on plan:** Runtime and test deliverables shipped as planned. Planning-state artifacts were intentionally left untouched to respect the explicit write boundary.

## Issues Encountered

- A verifier test initially passed through a cached key despite a mismatched JWT `kid`; the final proof was adjusted to use truly absent or wrong refreshed keys so the new remote-JWKS classifications match observed runtime behavior.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The repo now has one authoritative remote-JWKS incident model for future doctor, admin, and documentation surfaces.
- Phase `91-02` can consume the shared telemetry metadata and remediation copy without inferring remote-key state from protocol-local errors.

## Self-Check: PASSED

- Created files exist on disk.
- Task commits `13064b7`, `93c71a5`, and `0fbd363` exist in git history.
- Plan-level verification command passed.

---
*Phase: 91-jwks-uri-rotation-diagnostics-and-remediation-truth*
*Completed: 2026-05-25*
