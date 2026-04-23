---
phase: 02-authorization-core
plan: 02
subsystem: auth
tags: [oauth, consent, pkce, ecto, telemetry]
requires:
  - phase: 02-authorization-core
    provides: validated authorize-request contract and safe /authorize error branching
provides:
  - durable interaction lifecycle state with transactional finalization
  - remembered-consent reuse policy with forced-consent bypass protection
  - hashed authorization-code issuance with redirect-safe approval and denial outcomes
affects: [02-03, 02-04, AUTH-02, AUTH-04, SECU-01, SECU-02]
tech-stack:
  added: []
  patterns:
    - protocol orchestration behind interaction, consent, and token store behaviours
    - transactional interaction finalization with hashed-at-rest authorization codes
    - redaction-first telemetry and audit emission for consent and code lifecycle changes
key-files:
  created:
    - lib/lockspire/protocol/authorization_flow.ex
    - lib/lockspire/protocol/consent_policy.ex
    - priv/repo/migrations/20260423020100_extend_authorization_core_state.exs
    - test/lockspire/protocol/authorization_flow_test.exs
  modified:
    - lib/lockspire/domain/interaction.ex
    - lib/lockspire/domain/token.ex
    - lib/lockspire/domain/consent_grant.ex
    - lib/lockspire/storage/interaction_store.ex
    - lib/lockspire/storage/consent_store.ex
    - lib/lockspire/storage/token_store.ex
    - lib/lockspire/storage/ecto/interaction_record.ex
    - lib/lockspire/storage/ecto/consent_grant_record.ex
    - lib/lockspire/storage/ecto/token_record.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/observability.ex
    - test/lockspire/storage/repository_test.exs
key-decisions:
  - "AuthorizationFlow accepts explicit subject context and store modules, keeping host account resolution and concrete Ecto repository coupling out of protocol decisions."
  - "Consent reuse is limited to remembered active grants whose scope set fully covers the validated request, and prompt=consent always forces an interactive path."
  - "Authorization codes remain opaque to clients but are hashed before persistence, with redirect_uri and PKCE challenge data stored durably for later redemption."
patterns-established:
  - "Every validated authorize request becomes a durable interaction record before login, consent, or code issuance decisions are exposed."
  - "Approval, denial, and consent reuse all converge through transactional interaction transitions plus observability events."
requirements-completed: [AUTH-02, AUTH-04]
duration: 11min
completed: 2026-04-23
---

# Phase 2 Plan 2: Authorization Core Summary

**Durable interaction state, remembered-consent reuse rules, and hashed authorization-code issuance behind store-bound protocol services**

## Performance

- **Duration:** 11 min
- **Started:** 2026-04-23T01:28:00Z
- **Completed:** 2026-04-23T01:38:40Z
- **Tasks:** 2
- **Files modified:** 16

## Accomplishments
- Extended the durable Phase 2 storage contract so interactions, consent grants, and authorization-code rows carry the lifecycle and PKCE state later web and token phases need.
- Added `Lockspire.Protocol.AuthorizationFlow` and `Lockspire.Protocol.ConsentPolicy` to decide login-required, consent-required, consent-reused, approved, and denied outcomes without touching host account resolution directly.
- Emitted audit and telemetry events for interaction, consent, and authorization-code lifecycle changes while redacting raw state and code material.

## Task Commits

Each task was committed atomically:

1. **Task 1: Complete the durable interaction, consent, and authorization-code contract** - `eeeed64` (test), `f6c6f7b` (feat)
2. **Task 2: Implement protocol orchestration, consent rules, and authorization-code issuance** - `bebbb69` (test), `0ccb8d8` (feat)

**Plan metadata:** pending

## Files Created/Modified
- `lib/lockspire/protocol/authorization_flow.ex` - Protocol-core orchestration for validated requests, consent decisions, approval or denial, and authorization-code issuance.
- `lib/lockspire/protocol/consent_policy.ex` - Pure remembered-consent reuse and forced-consent rules.
- `lib/lockspire/domain/interaction.ex` - Durable interaction lifecycle fields for pending, completed, denied, and expired paths.
- `lib/lockspire/domain/token.ex` - Authorization-code persistence fields for redirect URI, PKCE challenge material, issuance, and redemption markers.
- `lib/lockspire/domain/consent_grant.ex` - Explicit consent status, kind, and revocation metadata needed for reuse and review.
- `lib/lockspire/storage/ecto/repository.ex` - Transactional store helpers for interaction finalization, reusable-consent reads, and code redemption markers.
- `priv/repo/migrations/20260423020100_extend_authorization_core_state.exs` - Migration extending the Phase 2 durable state schema.
- `test/lockspire/storage/repository_test.exs` - Repository coverage for lifecycle transitions, reusable grants, and authorization-code persistence.
- `test/lockspire/protocol/authorization_flow_test.exs` - Protocol coverage for login handoff, consent reuse, approval, denial, expiry, and duplicate-finalization failures.

## Decisions Made

- Stored interaction lifecycle as explicit status plus timestamps instead of inferring flow state from nullable fields, which keeps resume and finalize decisions durable and auditable.
- Added a non-active interaction lookup to the store boundary so the protocol can distinguish expired interactions from already-finalized ones without reaching into Ecto directly.
- Persisted one-time approvals as explicit consent grants while limiting automatic reuse to remembered active grants only.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Expanded the durable consent and interaction boundary beyond the plan’s file list**
- **Found during:** Task 1 and Task 2
- **Issue:** The listed files did not include the domain consent struct or a non-active interaction lookup, but the plan required explicit consent status or kind metadata and precise expired-vs-finalized interaction handling.
- **Fix:** Extended `lib/lockspire/domain/consent_grant.ex` with status, kind, and revocation fields, and added `fetch_interaction/1` on the interaction store boundary with a repository implementation so protocol code could classify inactive interactions without concrete-repo access.
- **Files modified:** `lib/lockspire/domain/consent_grant.ex`, `lib/lockspire/storage/interaction_store.ex`, `lib/lockspire/storage/ecto/repository.ex`
- **Verification:** `mix test test/lockspire/storage/repository_test.exs`, `mix test test/lockspire/protocol/authorization_flow_test.exs`
- **Committed in:** `f6c6f7b`, `0ccb8d8`

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** The added boundary work was necessary for correctness and for keeping the protocol core behind the intended storage seam. No product-scope creep.

## Issues Encountered

- The first protocol negative-path test accidentally reused the remembered grant created earlier in the same test. The test was corrected to force consent on the denial and expiry branches so it measured the intended finalization behavior.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `02-03` can now replace the temporary authorize success JSON with real interaction, login, and consent delivery wiring against stable protocol outcomes and durable interaction records.
- `02-04` can redeem authorization codes using already-persisted redirect URI, subject, PKCE challenge, issuance time, and redemption markers instead of reopening schema design.

## Threat Flags

None.

## Self-Check: PASSED

- Verified `.planning/phases/02-authorization-core/02-02-SUMMARY.md` exists.
- Verified task commits `eeeed64`, `f6c6f7b`, `bebbb69`, and `0ccb8d8` exist in git history.
