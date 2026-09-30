---
phase: 140-bounded-operational-loose-end-triage
plan: "07"
subsystem: testing
tags: [phase-140, signing-key-fixture, token-exchange, audit]
requires:
  - phase: 140-06
    provides: Current Phase 140 gap-closure state and exact archived-candidate boundaries
provides:
  - JSON-encoded active signing-key fixture compatible with the production PrivateJwk decoder
  - Deterministic test isolation from older active signing keys
  - Focused Phase32, AuditWriter, and Phase81 verification for the repaired fixture
affects: [140-08, 140-09, release-proof]
actuals:
  tokens: 521
  tasks: 2
  commits: 2
  plan_head_before: 118c6446d8b0409c7abc2df9d7effc32ef0a92fe
tech-stack:
  added: []
  patterns:
    - "Persist test private JWKs as JSON, matching Admin.Keys.generate_key."
key-files:
  created:
    - .planning/phases/140-bounded-operational-loose-end-triage/140-07-SUMMARY.md
  modified:
    - test/support/seeding_helpers.ex
    - test/lockspire/audit/audit_writer_test.exs
key-decisions:
  - "Retire existing test signing-key rows inside the test transaction before seeding so the selected active key is the fresh fixture."
  - "Keep the four current selector identities distinct from the unnamed historical Phase32/AuditWriter groups."
requirements-completed: [LOOSE-03]
coverage:
  - id: D1
    description: "The shared fixture persists a fresh active RSA private JWK in the production-supported JSON representation, and current token exchange exercises it."
    requirement: LOOSE-03
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix test test/integration/phase32_device_flow_token_exchange_e2e_test.exs:59 test/integration/phase32_device_flow_token_exchange_e2e_test.exs:166"
        status: pass
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix test test/integration/phase32_device_flow_token_exchange_e2e_test.exs test/lockspire/audit/audit_writer_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Token redemption/replay and refresh reuse/revocation audit paths retain their behavioral assertions while signing succeeds."
    requirement: LOOSE-03
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix test test/lockspire/audit/audit_writer_test.exs:272 test/lockspire/audit/audit_writer_test.exs:306"
        status: pass
      - kind: integration
        ref: "Four exact Phase32/AuditWriter selectors combined: 4 tests, 0 failures."
        status: pass
    human_judgment: false
  - id: D3
    description: "Historical Phase32 and AuditWriter identities remain unnamed; current selectors are not mapped to archive records."
    requirement: LOOSE-03
    verification: []
    human_judgment: true
    rationale: "The archive provides grouped failure counts without historical names; preserving that source boundary requires judgment and no automated test asserts the historical identity claim."
duration: "~31 min"
completed: 2026-09-30
status: complete
---

# Phase 140 Plan 07: Signing Fixture Repair Summary

**Phase32 token exchange and AuditWriter tests now use a fresh active key encoded in the same JSON JWK format as production key generation.**

## Performance

- **Duration:** Approximately 31 min; start time was not captured at execution start.
- **Started:** Approximately 2026-09-30T23:24:00Z (2026-09-30 19:24 EDT; estimated from execution logs)
- **Completed:** 2026-09-30T23:54:24Z (last recorded verification)
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Changed the shared fixture to store private JWK JSON, matching the format emitted by `Admin.Keys.generate_key/1`.
- Made the helper retire old signing-key rows inside the test transaction before publishing the new active fixture. The repository selects active keys by insertion order; a pre-existing row had been selected ahead of the newly seeded key.
- Added an AuditWriter setup assertion that the fixture is the active key and decodes through `PrivateJwk.decode/1` and JOSE.
- Preserved the token redemption, replay, DPoP binding, refresh reuse, revocation, and audit-row assertions.
- Kept historical source limits explicit: the current selectors are present-day evidence, and the four historical Phase32/AuditWriter identities remain unavailable.

## Task Commits

1. **Task 1: Publish a fixture key in the accepted private-JWK format** - `893b6c5b` (fix)
2. **Task 2: Prove token-exchange and reuse audit paths with the same active fixture** - `098b6701` (test)

**Plan metadata:** to be recorded after this summary is self-checked.

## Files Created/Modified

- `test/support/seeding_helpers.ex` - Clears stale test signing-key rows in the current test transaction and serializes the fresh private JWK as JSON.
- `test/lockspire/audit/audit_writer_test.exs` - Asserts the selected active key is the newly seeded fixture and passes the production decode/JOSE conversion path.

## Decisions Made

- Matched test storage to the existing production generator format rather than changing production token signing.
- Retired only test-database signing-key rows through the test helper, keeping the published fixture active and preserving repository publication behavior.
- Did not assign names to the historical grouped Phase32/AuditWriter failures because their source records do not identify individual cases.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Prevent older active test keys from shadowing the fresh fixture**
- **Found during:** Task 1
- **Issue:** After changing the fixture bytes to JSON, the Phase32 selectors still selected an older active signing-key row because repository lookup orders active rows by insertion time.
- **Fix:** The test helper now deletes existing signing-key rows within the test transaction before publishing its fresh active RSA key; the private JWK is encoded with `Jason.encode!/1`.
- **Files modified:** `test/support/seeding_helpers.ex`
- **Verification:** Both exact Phase32 selectors pass; all three archived-candidate files pass.
- **Committed in:** `893b6c5b`

**Total deviations:** 1 auto-fixed (Rule 3 - blocking fixture selection).
**Impact on plan:** The additional fixture isolation was necessary to ensure tests use the exact active key they seed. No production signing behavior or protocol defaults changed.

## Issues Encountered

- The first test run could not start because dependencies were absent from the clean worktree. `mix deps.get` resolved the existing lockfile dependencies using a temporary Hex cache; no dependency or lockfile changes were made.
- ExUnit logs `Failed to refresh KeyCache: key storage unavailable` while sandbox-owned fixture rows are isolated from the cache process. The requested token and audit behaviors passed, and this existing async cache path was outside the planned fixture repair.
- `requirements.ready-ids` reported 0 of 1 requirement IDs ready because sibling Phase 140 plans also declare LOOSE-03. REQUIREMENTS.md was left unchanged for the shared-ID gate.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The active signing fixture and all four current selectors are verified.
- Plan 140-08 may proceed. The grouped historical Phase32/AuditWriter identities remain unknown, as required by the approved source-identity amendment.
- STATE.md and ROADMAP.md were not modified; the orchestrator owns those updates after merge.

---
*Phase: 140-bounded-operational-loose-end-triage*
*Completed: 2026-09-30*

## Self-Check: PASSED

- Summary and both task files exist.
- Task commits `893b6c5b` and `098b6701` are present in Git history.
- The four exact selectors and the three-file verification command passed.
- Requirements shared-ID readiness was blocked by unfinished sibling plans; no requirement or shared orchestrator state was changed.
